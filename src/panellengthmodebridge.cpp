// SPDX-License-Identifier: GPL-3.0-or-later

#include "panellengthmodebridge.h"

#include <QHash>
#include <QList>
#include <QPointer>

namespace
{
QHash<uint, int> reportedModes;
QHash<uint, int> reportedFloatingModes;
QHash<uint, int> reportedVisibilityModes;
QHash<uint, int> reportedAlignments;
QHash<uint, int> reportedThicknesses;
QHash<uint, int> reportedOpacityModes;
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
            (*it)->notifyPanelFloatingModeChanged();
            (*it)->notifyPanelVisibilityModeChanged();
            (*it)->notifyPanelAlignmentChanged();
            (*it)->notifyPanelThicknessChanged();
            (*it)->notifyPanelOpacityModeChanged();
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
    Q_EMIT panelFloatingModeChanged();
    Q_EMIT panelVisibilityModeChanged();
    Q_EMIT panelAlignmentChanged();
    Q_EMIT panelThicknessChanged();
    Q_EMIT panelOpacityModeChanged();
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

int PanelLengthModeBridge::panelFloatingMode() const
{
    return reportedFloatingModes.value(m_containmentId, -1);
}

int PanelLengthModeBridge::reportedPanelFloatingMode() const
{
    return m_reportedPanelFloatingMode;
}

void PanelLengthModeBridge::setReportedPanelFloatingMode(int floatingMode)
{
    if (m_reportedPanelFloatingMode == floatingMode) {
        return;
    }
    m_reportedPanelFloatingMode = floatingMode;
    if (m_containmentId == 0 || reportedFloatingModes.value(m_containmentId, -1) == floatingMode) {
        return;
    }
    reportedFloatingModes.insert(m_containmentId, floatingMode);
    notifyBridges(m_containmentId);
}

int PanelLengthModeBridge::panelVisibilityMode() const
{
    return reportedVisibilityModes.value(m_containmentId, -1);
}

int PanelLengthModeBridge::reportedPanelVisibilityMode() const
{
    return m_reportedPanelVisibilityMode;
}

void PanelLengthModeBridge::setReportedPanelVisibilityMode(int visibilityMode)
{
    if (m_reportedPanelVisibilityMode == visibilityMode) {
        return;
    }
    m_reportedPanelVisibilityMode = visibilityMode;
    if (m_containmentId == 0 || reportedVisibilityModes.value(m_containmentId, -1) == visibilityMode) {
        return;
    }
    reportedVisibilityModes.insert(m_containmentId, visibilityMode);
    notifyBridges(m_containmentId);
}

void PanelLengthModeBridge::notifyPanelLengthModeChanged()
{
    Q_EMIT panelLengthModeChanged();
}

void PanelLengthModeBridge::notifyPanelFloatingModeChanged()
{
    Q_EMIT panelFloatingModeChanged();
}

void PanelLengthModeBridge::notifyPanelVisibilityModeChanged()
{
    Q_EMIT panelVisibilityModeChanged();
}

int PanelLengthModeBridge::panelAlignment() const
{
    return reportedAlignments.value(m_containmentId, -1);
}

int PanelLengthModeBridge::reportedPanelAlignment() const
{
    return m_reportedPanelAlignment;
}

void PanelLengthModeBridge::setReportedPanelAlignment(int alignment)
{
    if (m_reportedPanelAlignment == alignment) {
        return;
    }
    m_reportedPanelAlignment = alignment;
    if (m_containmentId == 0 || reportedAlignments.value(m_containmentId, -1) == alignment) {
        return;
    }
    reportedAlignments.insert(m_containmentId, alignment);
    notifyBridges(m_containmentId);
}

void PanelLengthModeBridge::notifyPanelAlignmentChanged()
{
    Q_EMIT panelAlignmentChanged();
}

int PanelLengthModeBridge::panelThickness() const
{
    return reportedThicknesses.value(m_containmentId, 0);
}

int PanelLengthModeBridge::reportedPanelThickness() const
{
    return m_reportedPanelThickness;
}

void PanelLengthModeBridge::setReportedPanelThickness(int thickness)
{
    if (m_reportedPanelThickness == thickness) {
        return;
    }
    m_reportedPanelThickness = thickness;
    if (m_containmentId == 0 || reportedThicknesses.value(m_containmentId, 0) == thickness) {
        return;
    }
    reportedThicknesses.insert(m_containmentId, thickness);
    notifyBridges(m_containmentId);
}

void PanelLengthModeBridge::notifyPanelThicknessChanged()
{
    Q_EMIT panelThicknessChanged();
}

int PanelLengthModeBridge::panelOpacityMode() const
{
    return reportedOpacityModes.value(m_containmentId, -1);
}

int PanelLengthModeBridge::reportedPanelOpacityMode() const
{
    return m_reportedPanelOpacityMode;
}

void PanelLengthModeBridge::setReportedPanelOpacityMode(int opacityMode)
{
    if (m_reportedPanelOpacityMode == opacityMode) {
        return;
    }
    m_reportedPanelOpacityMode = opacityMode;
    if (m_containmentId == 0 || reportedOpacityModes.value(m_containmentId, -1) == opacityMode) {
        return;
    }
    reportedOpacityModes.insert(m_containmentId, opacityMode);
    notifyBridges(m_containmentId);
}

void PanelLengthModeBridge::notifyPanelOpacityModeChanged()
{
    Q_EMIT panelOpacityModeChanged();
}
