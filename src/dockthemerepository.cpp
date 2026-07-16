// SPDX-License-Identifier: GPL-3.0-or-later

#include "dockthemerepository.h"

#include "dockthemevalidator.h"

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

namespace
{
constexpr int maximumDirectoryThemeCount = 256;

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
    refreshThemes();
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

QString DockThemeRepository::importTheme(const QUrl &sourceUrl)
{
    clearError();

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
        {QStringLiteral("selectedThemeId"), QString()},
    };

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
    QDirIterator sourceIterator(
        sourceDirectoryInfo.absoluteFilePath(),
        QDir::Files | QDir::NoDotAndDotDot,
        QDirIterator::Subdirectories);
    while (sourceIterator.hasNext()) {
        const QFileInfo sourceInfo = sourceIterator.nextFileInfo();
        if (sourceInfo.suffix().compare(
                QLatin1String("json"), Qt::CaseInsensitive) == 0) {
            themeFiles.append(sourceInfo);
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

bool DockThemeRepository::removeTheme(const QString &themeId)
{
    clearError();

    const QString normalizedThemeId = themeId.trimmed().toLower();
    if (!isValidThemeId(normalizedThemeId)) {
        setErrorCode(QStringLiteral("invalidThemeId"));
        return false;
    }

    const QString themeFilePath = managedThemeFilePath(normalizedThemeId);
    if (themeFilePath.isEmpty()) {
        setErrorCode(QStringLiteral("themeNotFound"));
        return false;
    }

    const QFileInfo themeInfo(themeFilePath);
    if (themeInfo.isSymLink() || !themeInfo.isFile()
        || themeInfo.completeBaseName().toLower() != normalizedThemeId
        || !QFile::remove(themeFilePath)) {
        setErrorCode(QStringLiteral("removeFailed"));
        return false;
    }

    removeEmptyThemeDirectories(themeFilePath);

    if (m_themeId == normalizedThemeId) {
        m_themeId.clear();
        Q_EMIT themeIdChanged();
        clearTheme();
    }

    refreshThemes();
    return true;
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

void DockThemeRepository::removeEmptyThemeDirectories(const QString &filePath)
{
    const QString rootPath = QDir::cleanPath(themesDirectoryPath());
    QString directoryPath = QFileInfo(filePath).absolutePath();

    while (directoryPath.startsWith(rootPath + QLatin1Char('/'))
        && directoryPath != rootPath) {
        const QFileInfo directoryInfo(directoryPath);
        if (directoryInfo.isSymLink()) {
            return;
        }

        QDir directory(directoryPath);
        if (!directory.entryList(
                QDir::AllEntries | QDir::NoDotAndDotDot).isEmpty()) {
            return;
        }

        const QString parentPath = directoryInfo.absolutePath();
        if (!QDir(parentPath).rmdir(directoryInfo.fileName())) {
            return;
        }
        directoryPath = parentPath;
    }
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
    const QString dataRoot = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
    if (dataRoot.isEmpty()) {
        return {};
    }
    return QDir(dataRoot).filePath(QStringLiteral("punchi-dock-remastered/themes"));
}
