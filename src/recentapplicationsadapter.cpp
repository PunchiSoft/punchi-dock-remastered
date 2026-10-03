// SPDX-License-Identifier: GPL-3.0-or-later

#include "recentapplicationsadapter.h"

#include <KService>
#include <KSycoca>
#include <PlasmaActivities/Consumer>
#include <PlasmaActivities/ResourceInstance>
#include <PlasmaActivities/Stats/ResultModel>
#include <PlasmaActivities/Stats/Terms>
#include <QUrl>

RecentApplicationsAdapter::RecentApplicationsAdapter(QObject *parent)
    : QIdentityProxyModel(parent)
{
    connect(KSycoca::self(), &KSycoca::databaseChanged, this, [this]() {
        m_applications.clear();
        if (rowCount() > 0) {
            Q_EMIT dataChanged(index(0, 0), index(rowCount() - 1, 0), {StorageIdRole, NameRole, IconRole});
        }
    });
}

bool RecentApplicationsAdapter::enabled() const
{
    return m_enabled;
}

void RecentApplicationsAdapter::setEnabled(bool enabled)
{
    if (m_enabled == enabled) {
        return;
    }
    m_enabled = enabled;
    if (enabled) {
        m_consumer = new KActivities::Consumer(this);
        connect(m_consumer, &KActivities::Consumer::serviceStatusChanged, this, [this]() {
            updateSource();
            Q_EMIT availabilityChanged();
        });
        connect(m_consumer, &KActivities::Consumer::currentActivityChanged, this, &RecentApplicationsAdapter::updateSource);
    } else if (m_consumer) {
        disconnect(m_consumer, nullptr, this, nullptr);
        m_consumer->deleteLater();
        m_consumer = nullptr;
    }
    updateSource();
    Q_EMIT enabledChanged();
    Q_EMIT availabilityChanged();
}

bool RecentApplicationsAdapter::available() const
{
    return m_enabled && m_consumer && m_consumer->serviceStatus() == KActivities::Consumer::Running;
}

void RecentApplicationsAdapter::updateSource()
{
    m_applications.clear();
    QAbstractItemModel *previous = sourceModel();
    setSourceModel(nullptr);
    if (previous && previous->parent() == this) {
        previous->deleteLater();
    }
    // Do not ask Stats to open a nonexistent database when its service is
    // absent. Service recovery and activity changes rebuild this source.
    if (available()) {
        using namespace KActivities::Stats;
        using namespace KActivities::Stats::Terms;
        // Fetch candidates, not just three: pinned/open/invalid entries are
        // removed by the selection proxy before applying its visible limit.
        const auto query = UsedResources | RecentlyUsedFirst | Agent::any()
            | Activity::current() | Type::any() | Url::startsWith(QStringLiteral("applications:")) | Limit(128);
        setSourceModel(new ResultModel(query, this));
        while (sourceModel()->canFetchMore({}) && sourceModel()->rowCount() < 128) {
            const int previousCount = sourceModel()->rowCount();
            sourceModel()->fetchMore({});
            if (sourceModel()->rowCount() <= previousCount) {
                break;
            }
        }
    }
}

QHash<int, QByteArray> RecentApplicationsAdapter::roleNames() const
{
    return {{StorageIdRole, "storageId"}, {NameRole, "name"}, {IconRole, "icon"}};
}

QVariantMap RecentApplicationsAdapter::resolveResource(const QString &resource)
{
    const QString prefix = QStringLiteral("applications:");
    if (!resource.startsWith(prefix) || resource.size() > 512) {
        return {};
    }
    const QString id = resource.mid(prefix.size());
    if (id.isEmpty()) {
        return {};
    }
    for (const QChar ch : id) {
        if (ch.isSpace() || ch.category() == QChar::Other_Control || ch.category() == QChar::Other_Format
            || ch == QLatin1Char('/') || ch == QLatin1Char('\\') || ch == QLatin1Char(':')) {
            return {};
        }
    }
    KService::Ptr service = KService::serviceByStorageId(id);
    if (!service && !id.endsWith(QLatin1String(".desktop"))) {
        service = KService::serviceByDesktopName(id);
    }
    if (!service || !service->isValid() || !service->isApplication() || service->noDisplay()
        || service->isDeleted() || service->exec().trimmed().isEmpty()) {
        return {};
    }
    return {{QStringLiteral("storageId"), service->storageId()},
            {QStringLiteral("name"), service->name()},
            {QStringLiteral("icon"), service->icon()}};
}

QVariant RecentApplicationsAdapter::data(const QModelIndex &item, int role) const
{
    if (!item.isValid() || item.model() != this || !sourceModel()) {
        return {};
    }
    const QString resource = mapToSource(item).data(KActivities::Stats::ResultModel::ResourceRole).toString();
    if (!m_applications.contains(resource)) {
        if (m_applications.size() >= 256) {
            m_applications.clear();
        }
        m_applications.insert(resource, resolveResource(resource));
    }
    const QVariantMap app = m_applications.value(resource);
    switch (role) {
    case StorageIdRole: return app.value(QStringLiteral("storageId"));
    case NameRole:
    case Qt::DisplayRole: return app.value(QStringLiteral("name"));
    case IconRole: return app.value(QStringLiteral("icon"));
    default: return {};
    }
}

void RecentApplicationsAdapter::recordAccess(const QString &storageId)
{
    if (!available()) {
        return;
    }
    const QVariantMap app = resolveResource(QStringLiteral("applications:") + storageId);
    if (!app.isEmpty()) {
        KActivities::ResourceInstance::notifyAccessed(
            QUrl(QStringLiteral("applications:") + app.value(QStringLiteral("storageId")).toString()),
            QStringLiteral("org.kde.plasma.punchi-dock-remastered"));
    }
}
