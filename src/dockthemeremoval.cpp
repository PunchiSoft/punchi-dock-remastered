// SPDX-License-Identifier: GPL-3.0-or-later

#include "dockthemerepository.h"
#include "dockthemevalidator.h"

#include <KIO/CopyJob>
#include <KJob>
#include <QCryptographicHash>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QTimer>

#include <algorithm>
#include <utility>
#include <sys/stat.h>

namespace
{
QVariantMap removalEntry(const QString &path, const QString &root)
{
    const QFileInfo info(path);
    static const QRegularExpression idPattern(QStringLiteral("^[0-9a-fA-F]{16}$"));
    // Canonical equality rejects linked ancestors as well as a linked file.
    if (!info.isFile() || info.isSymLink() || info.canonicalFilePath() != info.absoluteFilePath()
        || !info.absoluteFilePath().startsWith(root + QLatin1Char('/'))
        || !idPattern.match(info.completeBaseName()).hasMatch()
        || info.size() <= 0 || info.size() > DockThemeValidator::maximumFileSize) {
        return {};
    }
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        return {};
    }
    const QByteArray data = file.read(DockThemeValidator::maximumFileSize + 1);
    if (!DockThemeValidator::validate(data).ok) {
        return {};
    }
    struct stat identity {};
    if (::fstat(file.handle(), &identity) != 0) {
        return {};
    }
    return {
        {QStringLiteral("path"), info.absoluteFilePath()},
        {QStringLiteral("id"), info.completeBaseName().toLower()},
        {QStringLiteral("hash"), QCryptographicHash::hash(data, QCryptographicHash::Sha256)},
        {QStringLiteral("device"), qulonglong(identity.st_dev)},
        {QStringLiteral("inode"), qulonglong(identity.st_ino)},
        {QStringLiteral("modifiedSeconds"), qlonglong(identity.st_mtim.tv_sec)},
        {QStringLiteral("modifiedNanoseconds"), qlonglong(identity.st_mtim.tv_nsec)},
    };
}
}

bool DockThemeRepository::removalBusy() const
{
    return m_removalBusy;
}

QVariantList DockThemeRepository::removalInventory() const
{
    QVariantList result;
    const QFileInfo root(themesDirectoryPath());
    if (!root.isDir() || root.isSymLink() || root.canonicalFilePath() != root.absoluteFilePath()) {
        return result;
    }
    QDirIterator iterator(root.absoluteFilePath(), {QStringLiteral("*.json")},
        QDir::Files | QDir::Readable | QDir::NoSymLinks, QDirIterator::Subdirectories);
    while (iterator.hasNext()) {
        const QVariantMap entry = removalEntry(iterator.next(), root.absoluteFilePath());
        if (!entry.isEmpty()) {
            result.append(entry);
        }
    }
    std::sort(result.begin(), result.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap().value(QStringLiteral("path")).toString()
            < b.toMap().value(QStringLiteral("path")).toString();
    });
    return result;
}

QVariantMap DockThemeRepository::prepareRemoval(const QString &themeId)
{
    if (m_removalBusy) {
        return {};
    }
    cancelRemoval();
    clearError();
    refreshThemes();
    m_pendingInventory = removalInventory();
    m_removalRoot = QFileInfo(themesDirectoryPath()).absoluteFilePath();
    for (const QVariant &entry : std::as_const(m_pendingInventory)) {
        if (themeId.isEmpty() || entry.toMap().value(QStringLiteral("id")).toString() == themeId) {
            m_pendingRemoval.append(entry);
        }
    }
    // A duplicate ID cannot identify one selected theme unambiguously.
    if (m_pendingRemoval.isEmpty() || (!themeId.isEmpty() && m_pendingRemoval.size() != 1)) {
        cancelRemoval();
        setErrorCode(QStringLiteral("removalChanged"));
        return {};
    }
    return {{QStringLiteral("count"), m_pendingRemoval.size()},
        {QStringLiteral("directory"), m_removalRoot}};
}

void DockThemeRepository::cancelRemoval()
{
    if (!m_removalBusy) {
        m_pendingInventory.clear();
        m_pendingRemoval.clear();
        m_removalRoot.clear();
    }
}

bool DockThemeRepository::confirmRemoval()
{
    if (m_removalBusy) {
        return false;
    }
    if (m_pendingRemoval.isEmpty()
        || QFileInfo(themesDirectoryPath()).absoluteFilePath() != m_removalRoot
        || removalInventory() != m_pendingInventory) {
        cancelRemoval();
        refreshThemes();
        setErrorCode(QStringLiteral("removalChanged"));
        return false;
    }
    clearError();
    m_removalIndex = m_movedCount = m_failedCount = 0;
    m_removalBusy = true;
    Q_EMIT removalBusyChanged();
    QTimer::singleShot(0, this, &DockThemeRepository::trashNextTheme);
    return true;
}

KJob *DockThemeRepository::createTrashJob(const QUrl &url)
{
    // KIO resolves the appropriate Trash for each filesystem. Never fall back
    // to QFile::remove or KIO::del when trashing is unavailable.
    auto *job = KIO::trash(url, KIO::HideProgressInfo);
    job->setUiDelegate(nullptr);
    return job;
}

void DockThemeRepository::trashNextTheme()
{
    if (m_removalIndex >= m_pendingRemoval.size()) {
        finishRemoval();
        return;
    }
    const QVariantMap entry = m_pendingRemoval.at(m_removalIndex++).toMap();
    const QString path = entry.value(QStringLiteral("path")).toString();
    if (QFileInfo(themesDirectoryPath()).absoluteFilePath() != m_removalRoot
        || removalEntry(path, m_removalRoot) != entry) {
        ++m_failedCount;
        QTimer::singleShot(0, this, &DockThemeRepository::trashNextTheme);
        return;
    }
    m_trashJob = createTrashJob(QUrl::fromLocalFile(path));
    if (!m_trashJob) {
        ++m_failedCount;
        QTimer::singleShot(0, this, &DockThemeRepository::trashNextTheme);
        return;
    }
    connect(m_trashJob, &KJob::result, this, [this](KJob *job) {
        if (job->error()) {
            ++m_failedCount;
        } else {
            ++m_movedCount;
        }
        m_trashJob = nullptr;
        QTimer::singleShot(0, this, &DockThemeRepository::trashNextTheme);
    });
}

void DockThemeRepository::finishRemoval()
{
    refreshThemes();
    if (!m_themeId.isEmpty() && !loadTheme(m_themeId)) {
        m_themeId.clear();
        Q_EMIT themeIdChanged();
    }
    clearError();
    refreshPeerRepositories();
    m_removalBusy = false;
    cancelRemoval();
    Q_EMIT removalBusyChanged();
    Q_EMIT removalFinished(m_movedCount, m_failedCount);
}
