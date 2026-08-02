// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <qqmlregistration.h>

class SessionManagement;

class SessionActionsController : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool canLogout READ canLogout NOTIFY capabilitiesChanged)
    Q_PROPERTY(bool canReboot READ canReboot NOTIFY capabilitiesChanged)
    Q_PROPERTY(bool canShutdown READ canShutdown NOTIFY capabilitiesChanged)

public:
    explicit SessionActionsController(QObject *parent = nullptr);
    ~SessionActionsController() override;

    [[nodiscard]] bool canLogout() const;
    [[nodiscard]] bool canReboot() const;
    [[nodiscard]] bool canShutdown() const;

    Q_INVOKABLE void requestLogout();
    Q_INVOKABLE void requestReboot();
    Q_INVOKABLE void requestShutdown();

Q_SIGNALS:
    void capabilitiesChanged();

private:
    SessionManagement *m_sessionManagement = nullptr;
};
