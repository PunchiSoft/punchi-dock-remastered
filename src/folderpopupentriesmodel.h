// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QAbstractListModel>
#include <QPointer>
#include <QVariantList>
#include <qqmlregistration.h>
#include <utility>

// Adapt native directory rows without copying them. The final action belongs
// to the presentation model, never to the directory or persistent contents.
class FolderPopupEntriesModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QAbstractItemModel *sourceModel READ sourceModel WRITE setSourceModel NOTIFY sourceModelChanged)
    Q_PROPERTY(QVariantList entries READ entries WRITE setEntries NOTIFY entriesChanged)
    Q_PROPERTY(bool appendOpenLocation READ appendOpenLocation WRITE setAppendOpenLocation NOTIFY appendOpenLocationChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
public:
    explicit FolderPopupEntriesModel(QObject *parent = nullptr) : QAbstractListModel(parent) {}
    int count() const { return sourceCount() + (m_appendOpenLocation ? 1 : 0); }
    int rowCount(const QModelIndex &parent = {}) const override { return parent.isValid() ? 0 : count(); }
    QHash<int, QByteArray> roleNames() const override { return {{Qt::UserRole + 1, "modelData"}}; }
    QVariant data(const QModelIndex &index, int role) const override
    {
        if (!index.isValid() || index.column() != 0 || index.row() < 0
                || index.row() >= count() || role != Qt::UserRole + 1) {
            return {};
        }
        if (m_appendOpenLocation && index.row() == sourceCount()) {
            return QVariantMap{{QStringLiteral("_punchiOpenLocationAction"), true}};
        }
        return m_sourceModel
            ? m_sourceModel->data(m_sourceModel->index(index.row(), 0), m_sourceRole)
            : m_entries.at(index.row());
    }
    QAbstractItemModel *sourceModel() const { return m_sourceModel.data(); }
    QVariantList entries() const { return m_entries; }
    bool appendOpenLocation() const { return m_appendOpenLocation; }
    void setSourceModel(QAbstractItemModel *source)
    {
        if (m_sourceModel == source) { return; }
        beginResetModel();
        for (const auto &connection : std::as_const(m_connections)) { disconnect(connection); }
        m_connections.clear();
        m_sourceModel = source;
        m_sourceRole = -1;
        if (source) {
            const auto roles = source->roleNames();
            for (auto it = roles.cbegin(); it != roles.cend(); ++it) {
                if (it.value() == "modelData") { m_sourceRole = it.key(); break; }
            }
            m_connections.append(connect(source, &QAbstractItemModel::modelAboutToBeReset, this, [this] { beginResetModel(); }));
            m_connections.append(connect(source, &QAbstractItemModel::modelReset, this, [this] { endResetModel(); Q_EMIT countChanged(); }));
            m_connections.append(connect(source, &QAbstractItemModel::rowsAboutToBeInserted, this,
                [this](const QModelIndex &, int first, int last) { beginInsertRows({}, first, last); }));
            m_connections.append(connect(source, &QAbstractItemModel::rowsInserted, this,
                [this] { endInsertRows(); Q_EMIT countChanged(); }));
            m_connections.append(connect(source, &QAbstractItemModel::rowsAboutToBeRemoved, this,
                [this](const QModelIndex &, int first, int last) { beginRemoveRows({}, first, last); }));
            m_connections.append(connect(source, &QAbstractItemModel::rowsRemoved, this,
                [this] { endRemoveRows(); Q_EMIT countChanged(); }));
            m_connections.append(connect(source, &QAbstractItemModel::dataChanged, this, [this](const QModelIndex &first, const QModelIndex &last) {
                Q_EMIT dataChanged(index(first.row(), 0), index(last.row(), 0), {Qt::UserRole + 1});
            }));
            m_connections.append(connect(source, &QObject::destroyed, this, [this] {
                beginResetModel();
                m_sourceModel = nullptr;
                endResetModel();
                Q_EMIT sourceModelChanged();
                Q_EMIT countChanged();
            }));
        }
        endResetModel();
        Q_EMIT sourceModelChanged();
        Q_EMIT countChanged();
    }
    void setEntries(const QVariantList &entries)
    {
        if (m_entries == entries) { return; }
        beginResetModel();
        m_entries = entries;
        endResetModel();
        Q_EMIT entriesChanged();
        Q_EMIT countChanged();
    }
    void setAppendOpenLocation(bool append)
    {
        if (m_appendOpenLocation == append) { return; }
        const int last = sourceCount();
        if (append) { beginInsertRows({}, last, last); }
        else { beginRemoveRows({}, last, last); }
        m_appendOpenLocation = append;
        if (append) { endInsertRows(); }
        else { endRemoveRows(); }
        Q_EMIT appendOpenLocationChanged();
        Q_EMIT countChanged();
    }
Q_SIGNALS:
    void sourceModelChanged();
    void entriesChanged();
    void appendOpenLocationChanged();
    void countChanged();
private:
    int sourceCount() const { return m_sourceModel ? m_sourceModel->rowCount() : m_entries.size(); }
    QPointer<QAbstractItemModel> m_sourceModel;
    QList<QMetaObject::Connection> m_connections;
    QVariantList m_entries;
    int m_sourceRole = -1;
    bool m_appendOpenLocation = false;
};
