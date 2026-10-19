// SPDX-License-Identifier: GPL-3.0-or-later
#include "foldernavigationmodel.h"
#include "desktoplauncherresolver.h"
#include "folderentryicon.h"

#include <KIO/ListJob>
#include <KIO/UDSEntry>
#include <KJob>
#include <QCollator>
#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QMimeDatabase>
#include <QUrl>

#include <algorithm>

namespace {
constexpr int MaximumEntries = 80;
QString localDirectory(const QString &input)
{
    QString path = input.trimmed();
    if (path.isEmpty()) { return {}; }
    if (path == QLatin1String("~")) {
        path = QDir::homePath();
    } else if (path.startsWith(QLatin1String("~/"))) {
        path = QDir::homePath() + path.mid(1);
    } else if (path.startsWith(QLatin1String("file:"))) {
        const QUrl url(path);
        if (!url.isLocalFile() || !url.host().isEmpty()) { return {}; }
        path = url.toLocalFile();
    } else if (path.contains(QLatin1String("://"))) {
        return {};
    }
    if (!QDir::isAbsolutePath(path)) { path = QDir::home().filePath(path); }
    const QFileInfo info(path);
    return info.isDir() ? info.canonicalFilePath() : QString();
}
}

FolderNavigationModel::FolderNavigationModel(QObject *parent) : QAbstractListModel(parent) {}
FolderNavigationModel::~FolderNavigationModel() { cancel(); }
int FolderNavigationModel::rowCount(const QModelIndex &parent) const { return parent.isValid() ? 0 : count(); }
QVariant FolderNavigationModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.column() != 0 || index.row() < 0 || index.row() >= count()) { return {}; }
    return role == Qt::UserRole + 1 ? QVariant(m_entries.at(index.row()).row) : QVariant();
}
QHash<int, QByteArray> FolderNavigationModel::roleNames() const { return {{Qt::UserRole + 1, "modelData"}}; }
QVariantMap FolderNavigationModel::get(int row) const { return row >= 0 && row < count() ? m_entries.at(row).row : QVariantMap(); }

QString FolderNavigationModel::boundedDirectory(const QString &input) const
{
    // Resolve symlinks on every request, rather than trusting a cached icon or URL.
    if (m_rootDirectory.isEmpty() || localDirectory(m_rootPath) != m_rootDirectory) { return {}; }
    const QString target = localDirectory(input);
    if (target.isEmpty()) { return {}; }
    const QString relative = QDir(m_rootDirectory).relativeFilePath(target);
    if (relative == QLatin1String("..") || relative.startsWith(QLatin1String("../"))
        || QDir::isAbsolutePath(relative)) { return {}; }
    const int levels = relative == QLatin1String(".") ? 0 : relative.split(QLatin1Char('/'), Qt::SkipEmptyParts).size();
    return levels <= maximumDepth() ? target : QString();
}

int FolderNavigationModel::depth() const
{
    const QString directory = QUrl(m_location).toLocalFile();
    if (directory.isEmpty() || m_rootDirectory.isEmpty()) { return 0; }
    const QString relative = QDir(m_rootDirectory).relativeFilePath(directory);
    return relative == QLatin1String(".") ? 0 : relative.split(QLatin1Char('/'), Qt::SkipEmptyParts).size();
}

QString FolderNavigationModel::directoryTarget(const QVariantMap &entry) const
{
    if (!entry.value(QStringLiteral("isDirectory")).toBool() || depth() >= maximumDepth()) { return {}; }
    const QString target = boundedDirectory(entry.value(QStringLiteral("url")).toString());
    const QString current = QUrl(m_location).toLocalFile();
    return target.isEmpty() || target == current || current.startsWith(target + QLatin1Char('/')) ? QString() : QUrl::fromLocalFile(target).toString();
}

void FolderNavigationModel::cancel()
{
    ++m_generation;
    if (m_job) {
        auto *job = m_job.data();
        m_job.clear();
        disconnect(job, nullptr, this, nullptr);
        job->kill(KJob::Quietly);
    }
    m_pendingEntries.clear();
    m_loading = false;
}
void FolderNavigationModel::clear()
{
    m_pendingEntries.clear();
    const bool hadEntries = !m_entries.isEmpty();
    beginResetModel();
    m_entries.clear();
    endResetModel();
    if (hadEntries) { Q_EMIT countChanged(); }
}
void FolderNavigationModel::setRootPath(const QString &path)
{
    if (m_rootPath == path) { return; }
    cancel();
    m_rootPath = path;
    m_rootDirectory = localDirectory(path);
    m_location = m_rootDirectory.isEmpty() ? QString() : QUrl::fromLocalFile(m_rootDirectory).toString();
    Q_EMIT rootPathChanged();
    Q_EMIT locationChanged();
    reload();
}
void FolderNavigationModel::setLocation(const QString &input)
{
    const QString directory = boundedDirectory(input);
    if (directory.isEmpty()) { return; }
    const QString url = QUrl::fromLocalFile(directory).toString();
    if (url == m_location) { return; }
    m_location = url;
    Q_EMIT locationChanged();
    reload();
}
void FolderNavigationModel::setEnabled(bool enabled)
{
    if (m_enabled == enabled) { return; }
    m_enabled = enabled;
    Q_EMIT enabledChanged();
    reload();
}
void FolderNavigationModel::setSortMode(const QString &mode)
{
    const QString normalized = mode == QLatin1String("name") || mode == QLatin1String("size")
            || mode == QLatin1String("modified") || mode == QLatin1String("created")
            || mode == QLatin1String("kind")
        ? mode : QStringLiteral("modified");
    if (m_sortMode == normalized) { return; }
    m_sortMode = normalized;
    Q_EMIT sortModeChanged();
    if (!m_entries.isEmpty()) {
        beginResetModel();
        sortEntries(m_entries);
        endResetModel();
    }
}
void FolderNavigationModel::sortEntries(QList<Entry> &entries)
{
    if (entries.size() < 2) { return; }
    QCollator collator;
    collator.setNumericMode(true);
    collator.setCaseSensitivity(Qt::CaseInsensitive);
    const QString mode = m_sortMode;
    std::stable_sort(entries.begin(), entries.end(), [&](const Entry &left, const Entry &right) {
        if (mode == QLatin1String("size")) {
            if (left.size != right.size) { return left.size > right.size; }
        } else if (mode == QLatin1String("modified")) {
            if (left.modified != right.modified) { return left.modified > right.modified; }
        } else if (mode == QLatin1String("created")) {
            if (left.created != right.created) { return left.created > right.created; }
        } else if (mode == QLatin1String("kind")) {
            const int typeOrder = collator.compare(left.mimeType, right.mimeType);
            if (typeOrder != 0) { return typeOrder < 0; }
        }
        return collator.compare(left.name, right.name) < 0;
    });
}
void FolderNavigationModel::reload()
{
    cancel();
    clear();
    m_error.clear();
    const QString directory = boundedDirectory(m_location);
    if (!m_enabled || directory.isEmpty()) { Q_EMIT stateChanged(); return; }
    m_loading = true;
    const quint64 generation = m_generation;
    auto *job = KIO::listDir(QUrl::fromLocalFile(directory), KIO::HideProgressInfo);
    m_job = job;
    Q_EMIT stateChanged();
    connect(job, &KIO::ListJob::entries, this, [this, generation, directory](KIO::Job *, const KIO::UDSEntryList &batch) {
        if (generation != m_generation || boundedDirectory(m_location) != directory) { return; }
        for (const auto &entry : batch) {
            if (m_pendingEntries.size() >= MaximumEntries) { break; }
            const QString name = entry.stringValue(KIO::UDSEntry::UDS_NAME);
            if (name.isEmpty() || name == QLatin1String(".") || name == QLatin1String("..")
                || name.contains(QLatin1Char('/')) || name.startsWith(QLatin1Char('.'))
                || entry.numberValue(KIO::UDSEntry::UDS_HIDDEN, 0) != 0) { continue; }
            const QString url = QUrl::fromLocalFile(QDir(directory).filePath(name)).toString();
            const bool isDirectory = entry.isDir();
            QString title = entry.stringValue(KIO::UDSEntry::UDS_DISPLAY_NAME);
            QString icon = entry.stringValue(KIO::UDSEntry::UDS_ICON_NAME);
            QString storageId;
            if (!isDirectory && name.endsWith(QLatin1String(".desktop"), Qt::CaseInsensitive)) {
                const auto launcher = DesktopLauncherResolver::resolveLocalFile(QUrl(url).toLocalFile());
                if (launcher.service) {
                    if (!launcher.service->name().isEmpty()) { title = launcher.service->name(); }
                    if (!launcher.service->icon().isEmpty()) { icon = launcher.service->icon(); }
                    const auto registered = KService::serviceByDesktopPath(launcher.canonicalPath);
                    if (registered && registered->isApplication()) { storageId = registered->storageId(); }
                } else if (icon.isEmpty()) { icon = QStringLiteral("application-x-desktop"); }
            }
            if (icon.isEmpty()) { icon = FolderEntryIcon::resolve(entry, QUrl(url)); }
            QVariantMap row{
                {QStringLiteral("type"), QStringLiteral("app")},
                {QStringLiteral("name"), title.isEmpty() ? name : title},
                {QStringLiteral("icon"), icon},
                {QStringLiteral("url"), url},
                {QStringLiteral("isDirectory"), isDirectory},
                {QStringLiteral("description"), url}
            };
            if (!storageId.isEmpty()) { row.insert(QStringLiteral("storageId"), storageId); }
            row.insert(QStringLiteral("navigable"), !directoryTarget(row).isEmpty());

            Entry pending;
            pending.row = row;
            pending.name = title.isEmpty() ? name : title;
            pending.size = entry.numberValue(KIO::UDSEntry::UDS_SIZE, 0);
            const qint64 modifiedSeconds = entry.numberValue(KIO::UDSEntry::UDS_MODIFICATION_TIME, 0);
            pending.modified = modifiedSeconds > 0
                ? QDateTime::fromSecsSinceEpoch(modifiedSeconds) : QDateTime();
            const qint64 createdSeconds = entry.numberValue(KIO::UDSEntry::UDS_CREATION_TIME, 0);
            pending.created = createdSeconds > 0
                ? QDateTime::fromSecsSinceEpoch(createdSeconds) : QDateTime();
            pending.mimeType = entry.stringValue(KIO::UDSEntry::UDS_MIME_TYPE);
            if (pending.mimeType.isEmpty()) {
                if (isDirectory) {
                    pending.mimeType = QStringLiteral("inode/directory");
                } else {
                    // KIO does not always include UDS_MIME_TYPE in a directory
                    // listing. Extension matching keeps kind sorting cheap and
                    // deterministic without reading file contents.
                    const QMimeType mime = QMimeDatabase().mimeTypeForFile(
                        QDir(directory).filePath(name),
                        QMimeDatabase::MatchExtension);
                    pending.mimeType = mime.isValid()
                        ? mime.name() : QStringLiteral("application/octet-stream");
                }
            }
            m_pendingEntries.append(pending);
        }
    });
    connect(job, &KIO::ListJob::redirection, this, [this, generation](KIO::Job *, const QUrl &) {
        // The browser is deliberately local; never follow protocol redirects.
        if (generation == m_generation) { cancel(); clear(); Q_EMIT stateChanged(); }
    });
    connect(job, &KJob::result, this, [this, job, generation]() {
        if (generation != m_generation) { return; }
        m_job.clear();
        if (job->error()) {
            m_pendingEntries.clear();
            m_error = job->errorString();
        } else if (!m_pendingEntries.isEmpty()) {
            sortEntries(m_pendingEntries);
            const int first = m_entries.size();
            beginInsertRows({}, first, first + m_pendingEntries.size() - 1);
            m_entries.append(m_pendingEntries);
            m_pendingEntries.clear();
            endInsertRows();
            Q_EMIT countChanged();
        }
        m_loading = false;
        Q_EMIT stateChanged();
    });
}
