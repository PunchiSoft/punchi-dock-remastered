// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QString>
#include <qqmlregistration.h>

class QAction;

class PunchiMenuShortcutController : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(uint instanceId READ instanceId WRITE setInstanceId NOTIFY instanceIdChanged)
    Q_PROPERTY(QString configuredShortcut READ configuredShortcut WRITE setConfiguredShortcut NOTIFY configuredShortcutChanged)
    Q_PROPERTY(QString activeShortcut READ activeShortcut NOTIFY activeShortcutChanged)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(bool registered READ registered NOTIFY registeredChanged)

public:
    explicit PunchiMenuShortcutController(QObject *parent = nullptr);
    ~PunchiMenuShortcutController() override;

    uint instanceId() const;
    void setInstanceId(uint instanceId);

    QString configuredShortcut() const;
    void setConfiguredShortcut(const QString &shortcut);

    QString activeShortcut() const;

    bool enabled() const;
    void setEnabled(bool enabled);

    bool registered() const;

Q_SIGNALS:
    void instanceIdChanged();
    void configuredShortcutChanged();
    void activeShortcutChanged();
    void enabledChanged();
    void registeredChanged();
    void activated();
    void shortcutRegistrationFailed(const QString &requestedShortcut);

private:
    void initializeAction();
    void applyConfiguredShortcut();
    void updateRegistered(bool registered);

    QAction *m_action = nullptr;
    uint m_instanceId = 0;
    QString m_configuredShortcut;
    QString m_activeShortcut;
    bool m_enabled = true;
    bool m_registered = false;
};
