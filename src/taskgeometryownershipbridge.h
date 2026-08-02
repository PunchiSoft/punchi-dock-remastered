// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <qqmlregistration.h>

class TaskGeometryOwnershipBridge : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(uint instanceId READ instanceId WRITE setInstanceId NOTIFY instanceIdChanged)
    Q_PROPERTY(bool panel READ panel WRITE setPanel NOTIFY panelChanged)
    Q_PROPERTY(bool eligible READ eligible WRITE setEligible NOTIFY eligibleChanged)
    Q_PROPERTY(bool ownsTaskGeometry READ ownsTaskGeometry NOTIFY ownsTaskGeometryChanged)

public:
    explicit TaskGeometryOwnershipBridge(QObject *parent = nullptr);
    ~TaskGeometryOwnershipBridge() override;

    uint instanceId() const;
    void setInstanceId(uint instanceId);

    bool panel() const;
    void setPanel(bool panel);

    bool eligible() const;
    void setEligible(bool eligible);

    bool ownsTaskGeometry() const;
    void updateOwnership(bool ownsTaskGeometry);
    quint64 registrationOrder() const;

Q_SIGNALS:
    void instanceIdChanged();
    void panelChanged();
    void eligibleChanged();
    void ownsTaskGeometryChanged();

private:
    uint m_instanceId = 0;
    bool m_panel = false;
    bool m_eligible = true;
    bool m_ownsTaskGeometry = false;
    quint64 m_registrationOrder = 0;

};
