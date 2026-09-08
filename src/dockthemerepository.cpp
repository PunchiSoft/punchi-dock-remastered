// SPDX-License-Identifier: GPL-3.0-or-later

#include "dockthemerepository.h"

#include "dockthemevalidator.h"

#include <KLocalizedString>
#include <KJob>

#include <QCryptographicHash>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QRegularExpression>
#include <QSaveFile>
#include <QStandardPaths>

#include <algorithm>
#include <utility>

namespace
{
QList<QPointer<DockThemeRepository>> repositories;

constexpr auto TranslationDomain = "plasma_applet_org.kde.plasma.punchi-dock-remastered";
constexpr int maximumDirectoryThemeCount = 256;
constexpr int maximumDirectoryThemeScanCount = maximumDirectoryThemeCount + 1;

bool isValidThemeId(const QString &themeId)
{
    static const QRegularExpression themeIdPattern(QStringLiteral("^[0-9a-f]{16}$"));
    return themeIdPattern.match(themeId).hasMatch();
}

QString safeThemeDirectoryName(const QString &name)
{
    QString result;
    bool previousWasSeparator = false;
    const QString normalizedName = name.normalized(QString::NormalizationForm_D);

    for (const QChar character : normalizedName) {
        if (character.category() == QChar::Mark_NonSpacing) {
            continue;
        }
        if (character.isLetterOrNumber()) {
            result.append(character.toLower());
            previousWasSeparator = false;
        } else if (!result.isEmpty() && !previousWasSeparator) {
            result.append(QLatin1Char('-'));
            previousWasSeparator = true;
        }
    }

    while (result.endsWith(QLatin1Char('-'))) {
        result.chop(1);
    }
    if (result.isEmpty()) {
        return QStringLiteral("unnamed-theme");
    }
    return result.left(96);
}

QFileInfoList managedThemeFiles(const QString &directoryPath)
{
    QFileInfoList themeFiles;
    const QFileInfo directoryInfo(directoryPath);
    const QFileInfo parentDirectoryInfo(directoryInfo.absolutePath());
    if (!directoryInfo.exists() || !directoryInfo.isDir()
        || directoryInfo.isSymLink() || parentDirectoryInfo.isSymLink()) {
        return themeFiles;
    }

    QDirIterator iterator(
        directoryPath,
        {QStringLiteral("*.json")},
        QDir::Files | QDir::Readable | QDir::NoDotAndDotDot,
        QDirIterator::Subdirectories);
    while (iterator.hasNext()) {
        const QFileInfo themeInfo = iterator.nextFileInfo();
        if (!themeInfo.isSymLink()) {
            themeFiles.append(themeInfo);
        }
    }

    std::sort(themeFiles.begin(), themeFiles.end(),
        [](const QFileInfo &left, const QFileInfo &right) {
            return left.absoluteFilePath() < right.absoluteFilePath();
        });
    return themeFiles;
}
}

DockThemeRepository::DockThemeRepository(QObject *parent)
    : QObject(parent)
{
    repositories.append(this);
    refreshThemes();
}

DockThemeRepository::~DockThemeRepository()
{
    if (m_trashJob) {
        m_trashJob->kill(KJob::Quietly);
    }
    if (m_removalBusy) {
        refreshPeerRepositories();
    }
    repositories.removeAll(QPointer<DockThemeRepository>(this));
}

void DockThemeRepository::refreshPeerRepositories()
{
    const QString rootPath = m_removalRoot;
    for (const auto &repository : std::as_const(repositories)) {
        if (!repository || repository == this
            || QFileInfo(repository->themesDirectoryPath()).absoluteFilePath() != rootPath) {
            continue;
        }
        QMetaObject::invokeMethod(repository, [repository, rootPath]() {
            if (!repository
                || QFileInfo(repository->themesDirectoryPath()).absoluteFilePath() != rootPath) {
                return;
            }
            repository->refreshThemes();
            if (!repository->m_themeId.isEmpty()) {
                repository->loadTheme(repository->m_themeId);
            }
        }, Qt::QueuedConnection);
    }
}

QString DockThemeRepository::themeId() const
{
    return m_themeId;
}

void DockThemeRepository::setThemeId(const QString &themeId)
{
    const QString normalizedThemeId = themeId.trimmed().toLower();
    if (m_themeId == normalizedThemeId) {
        return;
    }

    m_themeId = normalizedThemeId;
    Q_EMIT themeIdChanged();

    if (m_themeId.isEmpty()) {
        clearTheme();
        clearError();
        return;
    }

    loadTheme(m_themeId);
}

QVariantMap DockThemeRepository::theme() const
{
    return m_theme;
}

bool DockThemeRepository::valid() const
{
    return !m_theme.isEmpty();
}

QString DockThemeRepository::themeName() const
{
    return m_theme.value(QStringLiteral("metadata")).toMap().value(QStringLiteral("name")).toString();
}

QString DockThemeRepository::errorCode() const
{
    return m_errorCode;
}

QVariantList DockThemeRepository::availableThemes() const
{
    return m_availableThemes;
}

bool DockThemeRepository::customThemeDirectoryEnabled() const
{
    return m_customThemeDirectoryEnabled;
}

void DockThemeRepository::setCustomThemeDirectoryEnabled(bool enabled)
{
    if (m_customThemeDirectoryEnabled == enabled) {
        return;
    }

    cancelRemoval();
    m_customThemeDirectoryEnabled = enabled;
    Q_EMIT customThemeDirectoryEnabledChanged();

    refreshThemes();
    if (!m_themeId.isEmpty()) {
        loadTheme(m_themeId);
    }
}

QString DockThemeRepository::customThemeDirectory() const
{
    return m_customThemeDirectory;
}

void DockThemeRepository::setCustomThemeDirectory(const QString &directory)
{
    QString normalized = directory.trimmed();
    if (normalized.startsWith(QLatin1String("file://"))) {
        normalized = QUrl(normalized).toLocalFile();
    }
    if (!normalized.isEmpty()) {
        normalized = QDir::cleanPath(normalized);
    }
    if (m_customThemeDirectory == normalized) {
        return;
    }

    cancelRemoval();
    m_customThemeDirectory = normalized;
    Q_EMIT customThemeDirectoryChanged();

    if (m_customThemeDirectoryEnabled) {
        refreshThemes();
        if (!m_themeId.isEmpty()) {
            loadTheme(m_themeId);
        }
    }
}

QString DockThemeRepository::customThemeDirectoryDisplayName() const
{
    if (m_customThemeDirectory.trimmed().isEmpty()) {
        return {};
    }
    const QString cleanPath = QDir::cleanPath(m_customThemeDirectory.trimmed());
    const QFileInfo info(cleanPath);
    const QString folderName = info.fileName();
    if (folderName.isEmpty()) {
        return cleanPath;
    }
    return QStringLiteral(".../%1").arg(folderName);
}

QString DockThemeRepository::importTheme(const QUrl &sourceUrl)
{
    clearError();

    const QString targetRootPath = themesDirectoryPath();
    if (targetRootPath.isEmpty()) {
        setErrorCode(QStringLiteral("storageUnavailable"));
        return {};
    }
    const QFileInfo targetRootInfo(targetRootPath);
    if (targetRootInfo.exists() && !targetRootInfo.isWritable()) {
        setErrorCode(QStringLiteral("readOnlyDirectory"));
        return {};
    }

    if (!sourceUrl.isValid() || !sourceUrl.isLocalFile()) {
        setErrorCode(QStringLiteral("invalidSource"));
        return {};
    }

    const QFileInfo sourceInfo(sourceUrl.toLocalFile());
    if (!sourceInfo.exists() || !sourceInfo.isFile() || !sourceInfo.isReadable()) {
        setErrorCode(QStringLiteral("unreadableFile"));
        return {};
    }
    if (sourceInfo.size() <= 0) {
        setErrorCode(QStringLiteral("emptyFile"));
        return {};
    }
    if (sourceInfo.size() > DockThemeValidator::maximumFileSize) {
        setErrorCode(QStringLiteral("fileTooLarge"));
        return {};
    }

    QFile sourceFile(sourceInfo.absoluteFilePath());
    if (!sourceFile.open(QIODevice::ReadOnly)) {
        setErrorCode(QStringLiteral("unreadableFile"));
        return {};
    }

    const QByteArray sourceData = sourceFile.read(DockThemeValidator::maximumFileSize + 1);
    const DockThemeValidator::Result result = DockThemeValidator::validate(sourceData);
    if (!result.ok) {
        setErrorCode(result.errorCode);
        return {};
    }

    const QString importedThemeId = storeTheme(result.theme);
    if (importedThemeId.isEmpty()) {
        return {};
    }

    if (m_themeId == importedThemeId) {
        loadTheme(importedThemeId);
    } else {
        setThemeId(importedThemeId);
    }
    refreshThemes();
    return importedThemeId;
}

QVariantMap DockThemeRepository::importThemeDirectory(const QUrl &sourceDirectoryUrl)
{
    clearError();

    QVariantMap importResult{
        {QStringLiteral("candidateCount"), 0},
        {QStringLiteral("importedCount"), 0},
        {QStringLiteral("duplicateCount"), 0},
        {QStringLiteral("rejectedCount"), 0},
        {QStringLiteral("truncatedCount"), 0},
        {QStringLiteral("scanLimitReached"), false},
        {QStringLiteral("selectedThemeId"), QString()},
    };

    const QString targetRootPath = themesDirectoryPath();
    if (targetRootPath.isEmpty()) {
        setErrorCode(QStringLiteral("storageUnavailable"));
        return importResult;
    }
    const QFileInfo targetRootInfo(targetRootPath);
    if (targetRootInfo.exists() && !targetRootInfo.isWritable()) {
        setErrorCode(QStringLiteral("readOnlyDirectory"));
        return importResult;
    }

    if (!sourceDirectoryUrl.isValid() || !sourceDirectoryUrl.isLocalFile()) {
        setErrorCode(QStringLiteral("invalidDirectory"));
        return importResult;
    }

    const QFileInfo sourceDirectoryInfo(sourceDirectoryUrl.toLocalFile());
    if (!sourceDirectoryInfo.exists()
        || !sourceDirectoryInfo.isDir()
        || !sourceDirectoryInfo.isReadable()) {
        setErrorCode(QStringLiteral("unreadableDirectory"));
        return importResult;
    }

    QFileInfoList themeFiles;
    bool scanLimitReached = false;
    QDirIterator sourceIterator(
        sourceDirectoryInfo.absoluteFilePath(),
        QDir::Files | QDir::NoDotAndDotDot,
        QDirIterator::Subdirectories);
    while (sourceIterator.hasNext()) {
        const QFileInfo sourceInfo = sourceIterator.nextFileInfo();
        if (sourceInfo.suffix().compare(
                QLatin1String("json"), Qt::CaseInsensitive) == 0) {
            themeFiles.append(sourceInfo);
            if (themeFiles.size() >= maximumDirectoryThemeScanCount) {
                scanLimitReached = true;
                break;
            }
        }
    }
    std::sort(themeFiles.begin(), themeFiles.end(),
        [](const QFileInfo &left, const QFileInfo &right) {
            return left.absoluteFilePath() < right.absoluteFilePath();
        });

    importResult[QStringLiteral("candidateCount")] = themeFiles.size();
    if (themeFiles.size() > maximumDirectoryThemeCount) {
        importResult[QStringLiteral("truncatedCount")] =
            themeFiles.size() - maximumDirectoryThemeCount;
        themeFiles = themeFiles.mid(0, maximumDirectoryThemeCount);
    }
    importResult[QStringLiteral("scanLimitReached")] = scanLimitReached;

    int importedCount = 0;
    int duplicateCount = 0;
    int rejectedCount = 0;
    QString selectedThemeId;

    for (const QFileInfo &sourceInfo : themeFiles) {
        if (sourceInfo.isSymLink()
            || !sourceInfo.isReadable()
            || sourceInfo.size() <= 0
            || sourceInfo.size() > DockThemeValidator::maximumFileSize) {
            ++rejectedCount;
            continue;
        }

        QFile sourceFile(sourceInfo.absoluteFilePath());
        if (!sourceFile.open(QIODevice::ReadOnly)) {
            ++rejectedCount;
            continue;
        }

        const DockThemeValidator::Result validationResult =
            DockThemeValidator::validate(
                sourceFile.read(DockThemeValidator::maximumFileSize + 1));
        if (!validationResult.ok) {
            ++rejectedCount;
            continue;
        }

        bool created = false;
        const QString themeId = storeTheme(validationResult.theme, &created);
        if (themeId.isEmpty()) {
            break;
        }

        if (selectedThemeId.isEmpty()) {
            selectedThemeId = themeId;
        }
        if (created) {
            ++importedCount;
        } else {
            ++duplicateCount;
        }
    }

    importResult[QStringLiteral("importedCount")] = importedCount;
    importResult[QStringLiteral("duplicateCount")] = duplicateCount;
    importResult[QStringLiteral("rejectedCount")] = rejectedCount;
    importResult[QStringLiteral("selectedThemeId")] = selectedThemeId;
    refreshThemes();
    return importResult;
}

void DockThemeRepository::refreshThemes()
{
    QVariantList availableThemes;
    const QFileInfoList themeFiles = managedThemeFiles(themesDirectoryPath());

    for (const QFileInfo &themeInfo : themeFiles) {
        if (themeInfo.isSymLink()
            || themeInfo.size() <= 0
            || themeInfo.size() > DockThemeValidator::maximumFileSize) {
            continue;
        }

        const QString themeId = themeInfo.completeBaseName().toLower();
        if (!isValidThemeId(themeId)) {
            continue;
        }

        QFile themeFile(themeInfo.absoluteFilePath());
        if (!themeFile.open(QIODevice::ReadOnly)) {
            continue;
        }

        const DockThemeValidator::Result result = DockThemeValidator::validate(
            themeFile.read(DockThemeValidator::maximumFileSize + 1));
        if (!result.ok) {
            continue;
        }

        const QVariantMap metadata = result.theme.value(
            QStringLiteral("metadata")).toMap();
        const QString renderer = result.theme.value(
            QStringLiteral("renderer")).toString();
        const QString themeName = metadata.value(QStringLiteral("name")).toString();
        availableThemes.append(QVariantMap{
            {QStringLiteral("id"), themeId},
            {QStringLiteral("name"), themeName},
            {QStringLiteral("displayName"), QStringLiteral("%1 · %2").arg(
                themeName,
                renderer == QLatin1String("shelf")
                    ? QStringLiteral("2.5D")
                    : renderer == QLatin1String("shaped")
                        ? i18nd(TranslationDomain, "Shaped")
                        : QStringLiteral("2D"))},
            {QStringLiteral("renderer"), renderer},
            {QStringLiteral("version"), metadata.value(QStringLiteral("version"))},
        });
    }

    std::sort(availableThemes.begin(), availableThemes.end(),
        [](const QVariant &leftValue, const QVariant &rightValue) {
            const QVariantMap left = leftValue.toMap();
            const QVariantMap right = rightValue.toMap();
            const int nameComparison = QString::localeAwareCompare(
                left.value(QStringLiteral("name")).toString(),
                right.value(QStringLiteral("name")).toString());
            if (nameComparison != 0) {
                return nameComparison < 0;
            }
            return left.value(QStringLiteral("id")).toString()
                < right.value(QStringLiteral("id")).toString();
        });

    if (m_availableThemes == availableThemes) {
        return;
    }

    m_availableThemes = availableThemes;
    Q_EMIT themesChanged();
}

void DockThemeRepository::clearError()
{
    setErrorCode({});
}

QString DockThemeRepository::storeTheme(const QVariantMap &theme, bool *created)
{
    const QString rootPath = themesDirectoryPath();
    if (rootPath.isEmpty()) {
        setErrorCode(QStringLiteral("storageUnavailable"));
        return {};
    }
    const QFileInfo rootInfo(rootPath);
    if (rootInfo.exists() && !rootInfo.isWritable()) {
        setErrorCode(QStringLiteral("readOnlyDirectory"));
        return {};
    }

    const QByteArray normalizedData =
        QJsonDocument::fromVariant(theme).toJson(QJsonDocument::Indented);
    const QString importedThemeId = QString::fromLatin1(
        QCryptographicHash::hash(
            normalizedData, QCryptographicHash::Sha256).toHex().left(16));

    const QString existingThemePath = managedThemeFilePath(importedThemeId);
    if (!existingThemePath.isEmpty()) {
        QFile existingFile(existingThemePath);
        if (existingFile.open(QIODevice::ReadOnly)
            && existingFile.readAll() == normalizedData) {
            if (created) {
                *created = false;
            }
            return importedThemeId;
        }
        setErrorCode(QStringLiteral("writeFailed"));
        return {};
    }

    const QString directoryPath = managedThemeDirectoryPath(theme);
    if (directoryPath.isEmpty()) {
        setErrorCode(QStringLiteral("storageUnavailable"));
        return {};
    }

    const QString destinationPath = QDir(directoryPath).filePath(
        importedThemeId + QStringLiteral(".json"));

    QSaveFile destinationFile(destinationPath);
    if (!destinationFile.open(QIODevice::WriteOnly | QIODevice::Truncate)
        || destinationFile.write(normalizedData) != normalizedData.size()
        || !destinationFile.commit()) {
        setErrorCode(QStringLiteral("writeFailed"));
        return {};
    }

    if (created) {
        *created = true;
    }
    return importedThemeId;
}

QString DockThemeRepository::managedThemeFilePath(const QString &themeId) const
{
    if (!isValidThemeId(themeId)) {
        return {};
    }

    const QFileInfoList themeFiles = managedThemeFiles(themesDirectoryPath());
    for (const QFileInfo &themeInfo : themeFiles) {
        if (themeInfo.completeBaseName().toLower() == themeId) {
            return themeInfo.absoluteFilePath();
        }
    }
    return {};
}

QString DockThemeRepository::managedThemeDirectoryPath(const QVariantMap &theme) const
{
    const QString rootPath = themesDirectoryPath();
    if (rootPath.isEmpty()) {
        return {};
    }

    const QFileInfo rootInfo(rootPath);
    const QString applicationDataPath = rootInfo.absolutePath();
    if (!QDir().mkpath(applicationDataPath)) {
        return {};
    }
    const QFileInfo applicationDataInfo(applicationDataPath);
    if (!applicationDataInfo.isDir() || applicationDataInfo.isSymLink()) {
        return {};
    }

    if (rootInfo.exists()) {
        if (!rootInfo.isDir() || rootInfo.isSymLink()) {
            return {};
        }
    } else if (!QDir(applicationDataPath).mkdir(rootInfo.fileName())) {
        return {};
    }

    const QString renderer = theme.value(QStringLiteral("renderer")).toString();
    const QString rendererDirectory = renderer == QLatin1String("shelf")
        ? QStringLiteral("2.5d")
        : renderer == QLatin1String("shaped")
            ? QStringLiteral("shaped")
            : QStringLiteral("2d");
    const QString themeName = theme.value(QStringLiteral("metadata")).toMap()
        .value(QStringLiteral("name")).toString();
    const QStringList directoryParts{
        rendererDirectory,
        safeThemeDirectoryName(themeName),
    };

    QString currentPath = rootPath;
    for (const QString &directoryPart : directoryParts) {
        const QString childPath = QDir(currentPath).filePath(directoryPart);
        const QFileInfo childInfo(childPath);
        if (childInfo.exists()) {
            if (!childInfo.isDir() || childInfo.isSymLink()) {
                return {};
            }
        } else if (!QDir(currentPath).mkdir(directoryPart)) {
            return {};
        }
        currentPath = childPath;
    }
    return currentPath;
}

bool DockThemeRepository::loadTheme(const QString &themeId)
{
    clearTheme();
    clearError();

    if (!isValidThemeId(themeId)) {
        setErrorCode(QStringLiteral("invalidThemeId"));
        return false;
    }

    const QString themeFilePath = managedThemeFilePath(themeId);
    QFile themeFile(themeFilePath);
    if (!themeFile.open(QIODevice::ReadOnly)) {
        setErrorCode(QStringLiteral("themeNotFound"));
        return false;
    }

    const QByteArray themeData = themeFile.read(DockThemeValidator::maximumFileSize + 1);
    const DockThemeValidator::Result result = DockThemeValidator::validate(themeData);
    if (!result.ok) {
        setErrorCode(result.errorCode);
        return false;
    }

    m_theme = result.theme;
    Q_EMIT themeChanged();
    return true;
}

void DockThemeRepository::clearTheme()
{
    if (m_theme.isEmpty()) {
        return;
    }

    m_theme.clear();
    Q_EMIT themeChanged();
}

void DockThemeRepository::setErrorCode(const QString &errorCode)
{
    if (m_errorCode == errorCode) {
        return;
    }

    m_errorCode = errorCode;
    Q_EMIT errorCodeChanged();
}

QString DockThemeRepository::themesDirectoryPath() const
{
    if (m_customThemeDirectoryEnabled && !m_customThemeDirectory.trimmed().isEmpty()) {
        const QString candidate = QDir::cleanPath(m_customThemeDirectory.trimmed());
        const QFileInfo info(candidate);
        const QFileInfo parentInfo(info.absolutePath());
        if (!info.exists() || !info.isDir() || info.isSymLink() || parentInfo.isSymLink()) {
            return {};
        }
        return candidate;
    }

    const QString dataRoot = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
    if (dataRoot.isEmpty()) {
        return {};
    }
    return QDir(dataRoot).filePath(QStringLiteral("punchi-dock-remastered/themes"));
}
