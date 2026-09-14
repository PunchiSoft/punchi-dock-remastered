// SPDX-License-Identifier: GPL-3.0-or-later

#include "panelinputregionsynchronizer.h"

#include <QRegion>
#include <QTimer>

#include <utility>

PanelInputRegionSynchronizer::PanelInputRegionSynchronizer(QObject *parent)
    : QObject(parent)
{
}

QQuickWindow *PanelInputRegionSynchronizer::panelWindow() const
{
    return m_panelWindow;
}

void PanelInputRegionSynchronizer::setPanelWindow(QQuickWindow *window)
{
    if (m_panelWindow == window) {
        return;
    }

    for (const auto &connection : std::as_const(m_windowConnections)) {
        disconnect(connection);
    }
    m_windowConnections.clear();
    m_panelWindow = window;

    if (window) {
        m_windowConnections.append(connect(window, &QQuickWindow::widthChanged,
            this, &PanelInputRegionSynchronizer::scheduleSynchronization));
        m_windowConnections.append(connect(window, &QQuickWindow::heightChanged,
            this, &PanelInputRegionSynchronizer::scheduleSynchronization));
        m_windowConnections.append(connect(window, &QObject::destroyed, this, [this]() {
            m_panelWindow = nullptr;
            m_windowConnections.clear();
            m_synchronizationScheduled = false;
            Q_EMIT panelWindowChanged();
        }));
    }

    Q_EMIT panelWindowChanged();
    scheduleSynchronization();
}

bool PanelInputRegionSynchronizer::isEnabled() const
{
    return m_enabled;
}

void PanelInputRegionSynchronizer::setEnabled(bool enabled)
{
    if (m_enabled == enabled) {
        return;
    }
    m_enabled = enabled;
    Q_EMIT enabledChanged();
    scheduleSynchronization();
}

bool PanelInputRegionSynchronizer::isVerticalPanel() const
{
    return m_verticalPanel;
}

void PanelInputRegionSynchronizer::setVerticalPanel(bool verticalPanel)
{
    if (m_verticalPanel == verticalPanel) {
        return;
    }
    m_verticalPanel = verticalPanel;
    Q_EMIT verticalPanelChanged();
    scheduleSynchronization();
}

void PanelInputRegionSynchronizer::scheduleSynchronization()
{
    if (m_synchronizationScheduled) {
        return;
    }

    m_synchronizationScheduled = true;
    QTimer::singleShot(0, this, [this]() {
        m_synchronizationScheduled = false;
        synchronizeInputRegion();
    });
}

void PanelInputRegionSynchronizer::synchronizeInputRegion()
{
    if (!m_enabled || !m_panelWindow) {
        return;
    }

    const QSize windowSize = m_panelWindow->size();
    const QRegion currentMask = m_panelWindow->mask();
    if (windowSize.isEmpty() || currentMask.isEmpty()
        || currentMask.rectCount() != 1) {
        return;
    }

    const QRect currentBounds = currentMask.boundingRect();
    QRect synchronizedBounds;
    if (m_verticalPanel) {
        synchronizedBounds = QRect(currentBounds.x(), 0,
            currentBounds.width(), windowSize.height());
    } else {
        synchronizedBounds = QRect(0, currentBounds.y(),
            windowSize.width(), currentBounds.height());
    }
    synchronizedBounds = synchronizedBounds.intersected(
        QRect(QPoint(0, 0), windowSize));

    if (!synchronizedBounds.isEmpty()
        && synchronizedBounds != currentBounds) {
        m_panelWindow->setMask(QRegion(synchronizedBounds));
    }
}
