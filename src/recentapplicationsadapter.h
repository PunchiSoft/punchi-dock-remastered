// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QIdentityProxyModel>
#include <QString>
#include <QVariantMap>
#include <qqmlregistration.h>

namespace KActivities { class Consumer; }
class QFileSystemWatcher;

// Adapts the public Activities Stats model without owning a second history.
class RecentApplicationsAdapter : public QIdentityProxyModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(bool available READ available NOTIFY availabilityChanged)
    Q_PROPERTY(bool trackingEnabled READ trackingEnabled NOTIFY trackingEnabledChanged)

public:
    enum Role { StorageIdRole = Qt::UserRole + 100, NameRole, IconRole };
    explicit RecentApplicationsAdapter(QObject *parent = nullptr);
    [[nodiscard]] bool enabled() const;
    void setEnabled(bool enabled);
    [[nodiscard]] bool available() const;
    // KDE can be configured to remember no application at all, which leaves the
    // history empty regardless of the dock's own visibility switch.
    [[nodiscard]] bool trackingEnabled() const;
    [[nodiscard]] QHash<int, QByteArray> roleNames() const override;
    [[nodiscard]] QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

    // Resolves application resources only. Never interprets history as commands.
    [[nodiscard]] static QVariantMap resolveResource(const QString &resource);
    Q_INVOKABLE void recordAccess(const QString &storageId);
    // Writes the two public states: remember all applications or none. KDE's
    // per-application allow/block lists are preserved.
    Q_INVOKABLE bool setTrackingEnabled(bool enabled);
    // Opens KDE's Recent Files module, which owns the remaining preferences.
    Q_INVOKABLE bool openTrackingSettings();

Q_SIGNALS:
    void enabledChanged();
    void availabilityChanged();
    void trackingEnabledChanged();

private:
    bool m_enabled = false;
    bool m_trackingEnabled = true;
    QString m_trackingConfigPath;
    QFileSystemWatcher *m_trackingWatcher = nullptr;
    KActivities::Consumer *m_consumer = nullptr;
    void updateSource();
    void watchTrackingConfiguration();
    void reloadTracking();
    mutable QHash<QString, QVariantMap> m_applications;
};
