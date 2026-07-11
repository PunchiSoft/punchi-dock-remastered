// SPDX-License-Identifier: GPL-3.0-or-later

#include "trashintegration.h"

#include <KDirWatch>
#include <KIO/DeleteJob>
#include <KIO/ListJob>
#include <KIO/OpenUrlJob>
#include <KIO/UDSEntry>

#include <QDir>
#include <QFileInfoList>
#include <QStandardPaths>
#include <QUrl>

namespace
{
QString trashFilesPath()
{
    const QString dataHome = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
    return QDir(dataHome).filePath(QStringLiteral("Trash/files"));
}

QString trashInfoPath()
{
    const QString dataHome = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
    return QDir(dataHome).filePath(QStringLiteral("Trash/info"));
}
}

TrashIntegration::TrashIntegration(QObject *parent)
    : QObject(parent)
    , m_watch(new KDirWatch(this))
{
    watchPaths();

    connect(m_watch, &KDirWatch::dirty, this, [this](const QString &) {
        refresh();
    });
    connect(m_watch, &KDirWatch::created, this, [this](const QString &) {
        watchPaths();
        refresh();
    });
    connect(m_watch, &KDirWatch::deleted, this, [this](const QString &) {
        watchPaths();
        refresh();
    });

    refresh();
}

TrashIntegration::~TrashIntegration() = default;

bool TrashIntegration::hasItems() const
{
    return m_hasItems;
}

void TrashIntegration::refresh()
{
    const QDir dir(trashFilesPath());
    const QFileInfoList entries = dir.entryInfoList(QDir::NoDotAndDotDot | QDir::AllEntries | QDir::Hidden | QDir::System);
    setHasItems(!entries.isEmpty());
}

void TrashIntegration::openTrash()
{
    auto *job = new KIO::OpenUrlJob(QUrl(QStringLiteral("trash:/")), QString(), this);
    job->setUiDelegate(nullptr);
    connect(job, &KJob::result, this, [this, job]() {
        if (job->error()) {
            Q_EMIT operationFailed(QStringLiteral("openTrash"), job->errorString());
        }
    });
    job->start();
}

void TrashIntegration::emptyTrash()
{
    auto *listJob = KIO::listDir(QUrl(QStringLiteral("trash:/")), KIO::HideProgressInfo);
    auto *urls = new QList<QUrl>;

    connect(listJob, &KIO::ListJob::entries, this, [urls](KIO::Job *, const KIO::UDSEntryList &batch) {
        for (const KIO::UDSEntry &entry : batch) {
            const QString name = entry.stringValue(KIO::UDSEntry::UDS_NAME);
            if (name.isEmpty() || name == QLatin1String(".") || name == QLatin1String("..")) {
                continue;
            }

            const QString entryUrl = entry.stringValue(KIO::UDSEntry::UDS_URL);
            if (!entryUrl.isEmpty()) {
                urls->append(QUrl(entryUrl));
                continue;
            }

            QUrl fallback(QStringLiteral("trash:/"));
            fallback.setPath(QStringLiteral("/") + name);
            urls->append(fallback);
        }
    });

    connect(listJob, &KJob::result, this, [this, listJob, urls]() {
        if (listJob->error()) {
            Q_EMIT operationFailed(QStringLiteral("emptyTrash"), listJob->errorString());
            delete urls;
            return;
        }

        if (urls->isEmpty()) {
            setHasItems(false);
            delete urls;
            return;
        }

        auto *deleteJob = KIO::del(*urls, KIO::HideProgressInfo);
        deleteJob->setUiDelegate(nullptr);
        connect(deleteJob, &KJob::result, this, [this, deleteJob]() {
            if (deleteJob->error()) {
                Q_EMIT operationFailed(QStringLiteral("emptyTrash"), deleteJob->errorString());
                return;
            }
            refresh();
        });
        delete urls;
    });
}

void TrashIntegration::setHasItems(bool hasItems)
{
    if (m_hasItems == hasItems) {
        return;
    }

    m_hasItems = hasItems;
    Q_EMIT stateChanged(m_hasItems);
}

void TrashIntegration::watchPaths()
{
    const QString filesPath = trashFilesPath();
    const QString infoPath = trashInfoPath();

    if (!m_watch->contains(filesPath)) {
        m_watch->addDir(filesPath, KDirWatch::WatchFiles);
    }
    if (!m_watch->contains(infoPath)) {
        m_watch->addDir(infoPath, KDirWatch::WatchFiles);
    }
}
