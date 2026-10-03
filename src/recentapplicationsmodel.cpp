// SPDX-License-Identifier: GPL-3.0-or-later

#include "recentapplicationsmodel.h"

#include <algorithm>

RecentApplicationsModel::RecentApplicationsModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
    connect(this, &QAbstractItemModel::rowsInserted, this, &RecentApplicationsModel::itemsChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &RecentApplicationsModel::itemsChanged);
    connect(this, &QAbstractItemModel::rowsMoved, this, &RecentApplicationsModel::itemsChanged);
    connect(this, &QAbstractItemModel::modelReset, this, &RecentApplicationsModel::itemsChanged);
    connect(this, &QAbstractItemModel::layoutChanged, this, &RecentApplicationsModel::itemsChanged);
    connect(this, &QAbstractItemModel::dataChanged, this, &RecentApplicationsModel::itemsChanged);
}

void RecentApplicationsModel::setSourceModel(QAbstractItemModel *model)
{
    if (model == sourceModel()) {
        return;
    }
    for (const auto &connection : std::as_const(m_sourceConnections)) {
        disconnect(connection);
    }
    m_sourceConnections.clear();
    QSortFilterProxyModel::setSourceModel(model);
    if (model) {
        // A removal, move or identity change can admit a previously hidden
        // candidate. Re-evaluate all rows before applying the visible limit.
        m_sourceConnections = {
            connect(model, &QAbstractItemModel::rowsInserted, this, &RecentApplicationsModel::refreshSelection),
            connect(model, &QAbstractItemModel::rowsRemoved, this, &RecentApplicationsModel::refreshSelection),
            connect(model, &QAbstractItemModel::rowsMoved, this, &RecentApplicationsModel::refreshSelection),
            connect(model, &QAbstractItemModel::layoutChanged, this, &RecentApplicationsModel::refreshSelection),
            connect(model, &QAbstractItemModel::modelReset, this, &RecentApplicationsModel::refreshSelection),
            connect(model, &QAbstractItemModel::dataChanged, this, &RecentApplicationsModel::refreshSelection),
        };
    }
    refreshSelection();
}

int RecentApplicationsModel::recentItemRole() const
{
    int role = Qt::UserRole;
    const auto roles = QSortFilterProxyModel::roleNames();
    for (auto it = roles.cbegin(); it != roles.cend(); ++it) {
        role = std::max(role, it.key());
    }
    return role + 1;
}

QHash<int, QByteArray> RecentApplicationsModel::roleNames() const
{
    auto roles = QSortFilterProxyModel::roleNames();
    roles.insert(recentItemRole(), QByteArrayLiteral("recentItem"));
    return roles;
}

QVariant RecentApplicationsModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.model() != this || index.column() != 0) {
        return {};
    }
    if (role == recentItemRole()) {
        return get(index.row());
    }
    return QSortFilterProxyModel::data(index, role);
}

bool RecentApplicationsModel::enabled() const
{
    return m_enabled;
}

void RecentApplicationsModel::setEnabled(bool enabled)
{
    if (m_enabled == enabled) {
        return;
    }
    m_enabled = enabled;
    refreshSelection();
    Q_EMIT enabledChanged();
}

int RecentApplicationsModel::maximumItems() const
{
    return m_maximumItems;
}

void RecentApplicationsModel::setMaximumItems(int maximumItems)
{
    const int bounded = std::clamp(maximumItems, 1, MaximumItems);
    if (m_maximumItems == bounded) {
        return;
    }
    m_maximumItems = bounded;
    refreshSelection();
    Q_EMIT maximumItemsChanged();
}

QStringList RecentApplicationsModel::excludedStorageIds() const
{
    return m_excludedStorageIds;
}

void RecentApplicationsModel::setExcludedStorageIds(const QStringList &storageIds)
{
    if (m_excludedStorageIds == storageIds) {
        return;
    }
    m_excludedStorageIds = storageIds;
    m_excludedIdentities.clear();
    for (const QString &storageId : storageIds) {
        const QString key = identityKey(storageId);
        if (!key.isEmpty()) {
            m_excludedIdentities.insert(key);
        }
    }
    refreshSelection();
    Q_EMIT excludedStorageIdsChanged();
}

int RecentApplicationsModel::count() const
{
    return rowCount();
}

QVariantList RecentApplicationsModel::items() const
{
    QVariantList result;
    for (int row = 0; row < count(); ++row) {
        result.append(get(row));
    }
    return result;
}

QVariantMap RecentApplicationsModel::get(int row) const
{
    if (!sourceModel() || row < 0 || row >= count()) {
        return {};
    }
    const QModelIndex sourceIndex = mapToSource(index(row, 0));
    const auto roles = sourceModel()->roleNames();
    const auto value = [&](const QByteArray &name) {
        const int role = roles.key(name, -1);
        return role < 0 ? QVariant{} : sourceModel()->data(sourceIndex, role);
    };
    const QString storageId = value(QByteArrayLiteral("storageId")).toString();
    const QString key = identityKey(storageId);
    if (key.isEmpty()) {
        return {};
    }
    return {
        {QStringLiteral("type"), QStringLiteral("app")},
        {QStringLiteral("entryRole"), QStringLiteral("recent")},
        {QStringLiteral("key"), QString(QStringLiteral("recent:") + storageId)},
        {QStringLiteral("storageId"), storageId},
        {QStringLiteral("appId"), key},
        {QStringLiteral("launcherUrl"), QString(QStringLiteral("applications:") + storageId)},
        {QStringLiteral("name"), value(QByteArrayLiteral("name"))},
        {QStringLiteral("icon"), value(QByteArrayLiteral("icon"))},
    };
}

QString RecentApplicationsModel::identityKey(const QString &storageId)
{
    QString key = storageId.trimmed();
    if (key.startsWith(QLatin1String("applications:"))) {
        key.remove(0, 13);
    }
    if (key.isEmpty() || key.size() > 512) {
        return {};
    }
    for (const QChar character : key) {
        if (character.isSpace() || character.category() == QChar::Other_Control
            || character.category() == QChar::Other_Format
            || character == QLatin1Char('/') || character == QLatin1Char('\\')
            || character == QLatin1Char(':')) {
            return {};
        }
    }
    if (key.endsWith(QLatin1String(".desktop"))) {
        key.chop(8);
    }
    return key;
}

QString RecentApplicationsModel::sourceIdentity(int row) const
{
    if (!sourceModel()) {
        return {};
    }
    const int role = sourceModel()->roleNames().key(QByteArrayLiteral("storageId"), -1);
    if (role < 0) {
        return {};
    }
    const QVariant value = sourceModel()->data(sourceModel()->index(row, 0), role);
    return value.metaType().id() == QMetaType::QString
        ? identityKey(value.toString()) : QString{};
}

bool RecentApplicationsModel::filterAcceptsRow(int row, const QModelIndex &parent) const
{
    if (!m_enabled || parent.isValid()) {
        return false;
    }
    const QString key = sourceIdentity(row);
    if (key.isEmpty() || m_excludedIdentities.contains(key)) {
        return false;
    }
    QSet<QString> accepted;
    for (int candidate = 0; candidate < row; ++candidate) {
        const QString previousKey = sourceIdentity(candidate);
        if (!previousKey.isEmpty() && !m_excludedIdentities.contains(previousKey)) {
            accepted.insert(previousKey);
            if (previousKey == key || accepted.size() >= m_maximumItems) {
                return false;
            }
        }
    }
    return true;
}

void RecentApplicationsModel::refreshSelection()
{
    // Keep the declared Qt 6.6 path while using the non-deprecated API on new Qt.
#if QT_VERSION >= QT_VERSION_CHECK(6, 10, 0)
    beginFilterChange();
    endFilterChange(QSortFilterProxyModel::Direction::Rows);
#else
    invalidateFilter();
#endif
    Q_EMIT itemsChanged();
}
