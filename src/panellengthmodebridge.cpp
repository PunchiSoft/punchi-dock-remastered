// SPDX-License-Identifier: GPL-3.0-or-later

#include "panellengthmodebridge.h"

#include <QHash>
#include <QList>
#include <QPointer>

namespace
{
QHash<uint, int> reportedModes;
QList<QPointer<PanelLengthModeBridge>> bridges;

void notifyBridges(uint containmentId)
{
    for (auto it = bridges.begin(); it != bridges.end();) {
        if (it->isNull()) {
            it = bridges.erase(it);
            continue;
        }
        if ((*it)->containmentId() == containmentId) {
            (*it)->notifyPanelLengthModeChanged();
        }
        ++it;
    }
}
}

PanelLengthModeBridge::PanelLengthModeBridge(QObject *parent)
    : QObject(parent)
{
    bridges.append(this);
}

PanelLengthModeBridge::~PanelLengthModeBridge()
{
    bridges.removeAll(QPointer<PanelLengthModeBridge>(this));
}

uint PanelLengthModeBridge::containmentId() const
{
    return m_containmentId;
}

void PanelLengthModeBridge::setContainmentId(uint containmentId)
{
    if (m_containmentId == containmentId) {
        return;
    }
    m_containmentId = containmentId;
    Q_EMIT containmentIdChanged();
    Q_EMIT panelLengthModeChanged();
}

int PanelLengthModeBridge::panelLengthMode() const
{
    return reportedModes.value(m_containmentId, -1);
}

bool PanelLengthModeBridge::fillAvailable() const
{
    return panelLengthMode() == 0;
}

int PanelLengthModeBridge::reportedPanelLengthMode() const
{
    return m_reportedPanelLengthMode;
}

void PanelLengthModeBridge::setReportedPanelLengthMode(int panelLengthMode)
{
    if (m_reportedPanelLengthMode == panelLengthMode) {
        return;
    }
    m_reportedPanelLengthMode = panelLengthMode;
    if (m_containmentId == 0 || reportedModes.value(m_containmentId, -1) == panelLengthMode) {
        return;
    }
    reportedModes.insert(m_containmentId, panelLengthMode);
    notifyBridges(m_containmentId);
}

void PanelLengthModeBridge::notifyPanelLengthModeChanged()
{
    Q_EMIT panelLengthModeChanged();
}
