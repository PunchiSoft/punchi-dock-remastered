// SPDX-License-Identifier: GPL-3.0-or-later

#include "trashintegration.h"

#include <KDirWatch>
#include <KIO/EmptyTrashJob>
#include <KIO/OpenUrlJob>
#include <KNotificationJobUiDelegate>

#include <QDir>
#include <QFileInfoList>
#include <QStandardPaths>
#include <QUrl>

#include <algorithm>
#include <limits>

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

bool TrashIntegration::emptying() const
{
    return m_operationState == QLatin1String("emptying");
}

QString TrashIntegration::operationState() const
{
    return m_operationState;
}

int TrashIntegration::progressPercent() const
{
    return m_progressPercent;
}

bool TrashIntegration::progressDeterminate() const
{
    return m_progressDeterminate;
}

int TrashIntegration::processedItems() const
{
    return m_processedItems;
}

int TrashIntegration::totalItems() const
{
    return m_totalItems;
}

QString TrashIntegration::errorMessage() const
{
    return m_errorMessage;
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
    if (emptying() || m_emptyTrashJob) {
        return;
    }

    resetProgress();
    setOperationState(QStringLiteral("emptying"));

    auto *job = KIO::emptyTrash();
    m_emptyTrashJob = job;
    job->setUiDelegate(new KNotificationJobUiDelegate(KJobUiDelegate::AutoErrorHandlingEnabled));

    connect(job, &KJob::percentChanged, this, [this](KJob *progressJob, unsigned long percent) {
        syncProgress(progressJob);
        if (percent == 0 && !m_progressDeterminate) {
            return;
        }
        m_progressPercent = std::clamp(static_cast<int>(percent), 0, 100);
        m_progressDeterminate = true;
        Q_EMIT progressChanged();
    });
    connect(job, &KJob::totalAmountChanged, this, [this](KJob *progressJob, KJob::Unit, qulonglong) {
        syncProgress(progressJob);
    });
    connect(job, &KJob::processedAmountChanged, this, [this](KJob *progressJob, KJob::Unit, qulonglong) {
        syncProgress(progressJob);
    });
    connect(job, &KJob::result, this, [this, job]() {
        m_emptyTrashJob = nullptr;
        if (job->error()) {
            setOperationState(QStringLiteral("failed"), job->errorString());
            Q_EMIT operationFailed(QStringLiteral("emptyTrash"), job->errorString());
            return;
        }

        m_progressPercent = 100;
        m_progressDeterminate = true;
        Q_EMIT progressChanged();
        setHasItems(false);
        setOperationState(QStringLiteral("succeeded"));
        Q_EMIT operationSucceeded(QStringLiteral("emptyTrash"));
    });
}

void TrashIntegration::resetOperationState()
{
    if (emptying()) {
        return;
    }

    resetProgress();
    setOperationState(QStringLiteral("idle"));
}

void TrashIntegration::setHasItems(bool hasItems)
{
    if (m_hasItems == hasItems) {
        return;
    }

    m_hasItems = hasItems;
    Q_EMIT stateChanged(m_hasItems);
}

void TrashIntegration::setOperationState(const QString &state, const QString &errorMessage)
{
    if (m_operationState == state && m_errorMessage == errorMessage) {
        return;
    }

    m_operationState = state;
    m_errorMessage = errorMessage;
    Q_EMIT operationStateChanged();
}

void TrashIntegration::resetProgress()
{
    const bool changed = m_progressPercent != -1 || m_processedItems != 0
        || m_totalItems != 0 || m_progressDeterminate;
    m_progressPercent = -1;
    m_processedItems = 0;
    m_totalItems = 0;
    m_progressDeterminate = false;
    if (changed) {
        Q_EMIT progressChanged();
    }
}

void TrashIntegration::syncProgress(KJob *job)
{
    if (!job) {
        return;
    }

    qulonglong total = job->totalAmount(KJob::Items);
    qulonglong processed = job->processedAmount(KJob::Items);
    if (total == 0) {
        total = job->totalAmount(KJob::Files) + job->totalAmount(KJob::Directories);
        processed = job->processedAmount(KJob::Files) + job->processedAmount(KJob::Directories);
    }

    const auto maximumInt = static_cast<qulonglong>(std::numeric_limits<int>::max());
    const int nextTotal = static_cast<int>(std::min(total, maximumInt));
    const int nextProcessed = static_cast<int>(std::min(processed, maximumInt));
    const bool nextDeterminate = nextTotal > 0;
    const int nextPercent = nextDeterminate
        ? std::clamp(static_cast<int>((static_cast<double>(processed) * 100.0)
            / static_cast<double>(total)), 0, 100)
        : m_progressPercent;

    if (m_totalItems == nextTotal && m_processedItems == nextProcessed
        && m_progressDeterminate == nextDeterminate && m_progressPercent == nextPercent) {
        return;
    }

    m_totalItems = nextTotal;
    m_processedItems = nextProcessed;
    m_progressDeterminate = nextDeterminate;
    m_progressPercent = nextPercent;
    Q_EMIT progressChanged();
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
