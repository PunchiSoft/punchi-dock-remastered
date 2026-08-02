// SPDX-License-Identifier: GPL-3.0-or-later

#include "taskgeometryownershipbridge.h"

#include <QList>
#include <QPointer>
#include <limits>

namespace
{
QList<QPointer<TaskGeometryOwnershipBridge>> bridges;
quint64 nextRegistrationOrder = 0;

quint64 effectiveInstanceId(const TaskGeometryOwnershipBridge *bridge)
{
    return bridge->instanceId() == 0
        ? std::numeric_limits<quint64>::max()
        : bridge->instanceId();
}

bool precedes(const TaskGeometryOwnershipBridge *candidate,
              const TaskGeometryOwnershipBridge *current)
{
    if (candidate->panel() != current->panel()) {
        return candidate->panel();
    }

    const quint64 candidateId = effectiveInstanceId(candidate);
    const quint64 currentId = effectiveInstanceId(current);
    if (candidateId != currentId) {
        return candidateId < currentId;
    }

    return candidate->registrationOrder() < current->registrationOrder();
}
}

void reevaluateTaskGeometryOwnership()
{
    TaskGeometryOwnershipBridge *owner = nullptr;

    for (auto it = bridges.begin(); it != bridges.end();) {
        if (it->isNull()) {
            it = bridges.erase(it);
            continue;
        }

        TaskGeometryOwnershipBridge *candidate = it->data();
        if (candidate->eligible() && (!owner || precedes(candidate, owner))) {
            owner = candidate;
        }
        ++it;
    }

    for (const QPointer<TaskGeometryOwnershipBridge> &bridge : std::as_const(bridges)) {
        if (bridge) {
            bridge->updateOwnership(bridge == owner);
        }
    }
}

TaskGeometryOwnershipBridge::TaskGeometryOwnershipBridge(QObject *parent)
    : QObject(parent)
    , m_registrationOrder(++nextRegistrationOrder)
{
    bridges.append(this);
    reevaluateTaskGeometryOwnership();
}

TaskGeometryOwnershipBridge::~TaskGeometryOwnershipBridge()
{
    bridges.removeAll(QPointer<TaskGeometryOwnershipBridge>(this));
    reevaluateTaskGeometryOwnership();
}

uint TaskGeometryOwnershipBridge::instanceId() const
{
    return m_instanceId;
}

void TaskGeometryOwnershipBridge::setInstanceId(uint instanceId)
{
    if (m_instanceId == instanceId) {
        return;
    }
    m_instanceId = instanceId;
    Q_EMIT instanceIdChanged();
    reevaluateTaskGeometryOwnership();
}

bool TaskGeometryOwnershipBridge::panel() const
{
    return m_panel;
}

void TaskGeometryOwnershipBridge::setPanel(bool panel)
{
    if (m_panel == panel) {
        return;
    }
    m_panel = panel;
    Q_EMIT panelChanged();
    reevaluateTaskGeometryOwnership();
}

bool TaskGeometryOwnershipBridge::eligible() const
{
    return m_eligible;
}

void TaskGeometryOwnershipBridge::setEligible(bool eligible)
{
    if (m_eligible == eligible) {
        return;
    }
    m_eligible = eligible;
    Q_EMIT eligibleChanged();
    reevaluateTaskGeometryOwnership();
}

bool TaskGeometryOwnershipBridge::ownsTaskGeometry() const
{
    return m_ownsTaskGeometry;
}

void TaskGeometryOwnershipBridge::updateOwnership(bool ownsTaskGeometry)
{
    if (m_ownsTaskGeometry == ownsTaskGeometry) {
        return;
    }
    m_ownsTaskGeometry = ownsTaskGeometry;
    Q_EMIT ownsTaskGeometryChanged();
}

quint64 TaskGeometryOwnershipBridge::registrationOrder() const
{
    return m_registrationOrder;
}
