// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QIdentityProxyModel>
#include <QVariantMap>
#include <qqmlregistration.h>

namespace KActivities { class Consumer; }

// Adapts the public Activities Stats model without owning a second history.
class RecentApplicationsAdapter : public QIdentityProxyModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(bool available READ available NOTIFY availabilityChanged)

public:
    enum Role { StorageIdRole = Qt::UserRole + 100, NameRole, IconRole };
    explicit RecentApplicationsAdapter(QObject *parent = nullptr);
    [[nodiscard]] bool enabled() const;
    void setEnabled(bool enabled);
    [[nodiscard]] bool available() const;
    [[nodiscard]] QHash<int, QByteArray> roleNames() const override;
    [[nodiscard]] QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

    // Resolves application resources only. Never interprets history as commands.
    [[nodiscard]] static QVariantMap resolveResource(const QString &resource);
    Q_INVOKABLE void recordAccess(const QString &storageId);

Q_SIGNALS:
    void enabledChanged();
    void availabilityChanged();

private:
    bool m_enabled = false;
    KActivities::Consumer *m_consumer = nullptr;
    void updateSource();
    mutable QHash<QString, QVariantMap> m_applications;
};
