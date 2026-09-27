// SPDX-License-Identifier: GPL-3.0-or-later

#include "panelrevealadapter.h"

#include <Plasma/Applet>
#include <Plasma/Containment>
#include <Plasma/Plasma>

#include <QQuickWindow>

PanelRevealAdapter::PanelRevealAdapter(QObject *parent)
    : QObject(parent)
{
}

PanelRevealAdapter::~PanelRevealAdapter()
{
    endReveal();
}

QObject *PanelRevealAdapter::applet() const
{
    return m_applet.data();
}

void PanelRevealAdapter::setApplet(QObject *applet)
{
    if (m_applet == applet) {
        return;
    }

    endReveal();
    m_applet = applet;
    Q_EMIT appletChanged();
    synchronizeRequest();
}

QQuickWindow *PanelRevealAdapter::panelWindow() const
{
    return m_panelWindow.data();
}

void PanelRevealAdapter::setPanelWindow(QQuickWindow *panelWindow)
{
    if (m_panelWindow == panelWindow) {
        return;
    }

    endReveal();
    m_panelWindow = panelWindow;
    Q_EMIT panelWindowChanged();
    synchronizeRequest();
}

bool PanelRevealAdapter::requested() const
{
    return m_requested;
}

void PanelRevealAdapter::setRequested(bool requested)
{
    if (m_requested == requested) {
        return;
    }

    m_requested = requested;
    Q_EMIT requestedChanged();
    synchronizeRequest();
}

bool PanelRevealAdapter::revealing() const
{
    return m_revealing;
}

bool PanelRevealAdapter::beginReveal()
{
    if (m_revealing) {
        return true;
    }

    auto *applet = qobject_cast<Plasma::Applet *>(m_applet.data());
    Plasma::Containment *const containment = applet ? applet->containment() : nullptr;
    QQuickWindow *const window = m_panelWindow.data();
    if (!containment || !window || !window->property("visibilityMode").isValid()) {
        return false;
    }

    m_containment = containment;
    m_previousStatus = static_cast<int>(containment->status());
    const auto previousStatus = containment->status();
    const bool statusAlreadyPinsPanel = previousStatus >= Plasma::Types::NeedsAttentionStatus
        && previousStatus != Plasma::Types::HiddenStatus;
    m_statusChangedByAdapter = !statusAlreadyPinsPanel;
    m_revealing = true;
    Q_EMIT revealingChanged();

    if (m_statusChangedByAdapter) {
        containment->setStatus(Plasma::Types::NeedsAttentionStatus);
    }

    return true;
}

void PanelRevealAdapter::endReveal()
{
    if (!m_revealing) {
        return;
    }

    if (auto *containment = qobject_cast<Plasma::Containment *>(m_containment.data())) {
        if (m_statusChangedByAdapter
            && containment->status() == Plasma::Types::NeedsAttentionStatus) {
            containment->setStatus(
                static_cast<Plasma::Types::ItemStatus>(m_previousStatus));
        }
    }

    m_revealing = false;
    m_previousStatus = static_cast<int>(Plasma::Types::UnknownStatus);
    m_statusChangedByAdapter = false;
    m_containment = nullptr;
    Q_EMIT revealingChanged();
}

void PanelRevealAdapter::synchronizeRequest()
{
    if (m_requested) {
        beginReveal();
    } else {
        endReveal();
    }
}
