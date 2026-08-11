// SPDX-License-Identifier: GPL-3.0-or-later

#include "trashintegration.h"

#include "dropurlpolicy.h"

#include <KCoreDirLister>
#include <KFileItem>
#include <KIO/CopyJob>
#include <KIO/EmptyTrashJob>
#include <KIO/OpenUrlJob>
#include <KNotificationJobUiDelegate>

#include <QMetaObject>
#include <QUrl>

#include <algorithm>
#include <limits>
#include <utility>

namespace
{
QUrl trashUrl()
{
    return QUrl(QStringLiteral("trash:/"));
}
}

TrashIntegration::TrashIntegration(QObject *parent)
    : QObject(parent)
    , m_trashLister(new KCoreDirLister(this))
{
    m_trashLister->setAutoErrorHandlingEnabled(false);
    m_trashLister->setAutoUpdate(true);

    connect(m_trashLister, &KCoreDirLister::clear, this, [this]() {
        m_pendingTrashItems.clear();
        m_rebuildingTrashItems = true;
    });
    connect(m_trashLister, &KCoreDirLister::itemsAdded, this,
            [this](const QUrl &, const KFileItemList &items) {
        QSet<QUrl> &listedItems = m_rebuildingTrashItems
            ? m_pendingTrashItems : m_listedTrashItems;
        for (const KFileItem &item : items) {
            listedItems.insert(item.url());
        }
        if (!m_rebuildingTrashItems) {
            setHasItems(!m_listedTrashItems.isEmpty());
        }
    });
    connect(m_trashLister, &KCoreDirLister::itemsDeleted, this,
            [this](const KFileItemList &items) {
        QSet<QUrl> &listedItems = m_rebuildingTrashItems
            ? m_pendingTrashItems : m_listedTrashItems;
        for (const KFileItem &item : items) {
            listedItems.remove(item.url());
        }
        if (!m_rebuildingTrashItems) {
            setHasItems(!m_listedTrashItems.isEmpty());
        }
    });
    connect(m_trashLister, &KCoreDirLister::completed,
            this, &TrashIntegration::finishTrashListing);
    connect(m_trashLister, &KCoreDirLister::canceled,
            this, &TrashIntegration::cancelTrashListing);
    connect(m_trashLister, &KCoreDirLister::jobError, this,
            [this](KIO::Job *) {
        cancelTrashListing();
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
    if (!m_trashLister) {
        return;
    }

    const QUrl url = trashUrl();
    if (m_trashLister->url() != url) {
        m_trashLister->openUrl(url);
        return;
    }
    if (!m_trashLister->isFinished()) {
        m_refreshPending = true;
        return;
    }
    m_trashLister->updateDirectory(url);
}

void TrashIntegration::openTrash()
{
    auto *job = new KIO::OpenUrlJob(trashUrl(), QString(), this);
    job->setUiDelegate(nullptr);
    connect(job, &KJob::result, this, [this, job]() {
        if (job->error()) {
            Q_EMIT operationFailed(QStringLiteral("openTrash"), job->errorString());
        }
    });
    job->start();
}

void TrashIntegration::trashUrls(const QVariantList &urls)
{
    const DropUrlPolicy::Result validation = DropUrlPolicy::validate(urls);
    if (!validation.accepted()) {
        Q_EMIT operationFailed(QStringLiteral("trashUrls"), validation.errorCode);
        return;
    }

    auto *job = KIO::trash(validation.urls, KIO::HideProgressInfo);
    job->setUiDelegate(nullptr);
    connect(job, &KJob::result, this, [this, job]() {
        if (job->error()) {
            Q_EMIT operationFailed(QStringLiteral("trashUrls"), job->errorString());
            return;
        }
        refresh();
    });
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

void TrashIntegration::finishTrashListing()
{
    if (m_rebuildingTrashItems) {
        m_listedTrashItems = std::move(m_pendingTrashItems);
        m_pendingTrashItems.clear();
        m_rebuildingTrashItems = false;
    }
    setHasItems(!m_listedTrashItems.isEmpty());
    schedulePendingRefresh();
}

void TrashIntegration::cancelTrashListing()
{
    if (m_rebuildingTrashItems) {
        m_pendingTrashItems.clear();
        m_rebuildingTrashItems = false;
    }
    schedulePendingRefresh();
}

void TrashIntegration::schedulePendingRefresh()
{
    if (!std::exchange(m_refreshPending, false)) {
        return;
    }
    QMetaObject::invokeMethod(this, &TrashIntegration::refresh,
                              Qt::QueuedConnection);
}
