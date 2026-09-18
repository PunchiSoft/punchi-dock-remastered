// SPDX-License-Identifier: GPL-3.0-or-later

#include "panelrevealadapter.h"

#include <Plasma/Applet>
#include <Plasma/Containment>
#include <Plasma/Plasma>
#include <PlasmaQuick/AppletQuickItem>

#include <QQuickItem>
#include <QQuickWindow>

PanelRevealAdapter::PanelRevealAdapter(QObject *parent)
    : QObject(parent)
{
}

PanelRevealAdapter::~PanelRevealAdapter()
{
    // A page can be destroyed while its dialog is still open, so the reveal must
    // never outlive the object that requested it.
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
}

bool PanelRevealAdapter::revealing() const
{
    return m_revealing;
}

bool PanelRevealAdapter::beginReveal()
{
    auto *applet = qobject_cast<Plasma::Applet *>(m_applet.data());
    Plasma::Containment *const containment = applet ? applet->containment() : nullptr;
    if (!containment) {
        return false;
    }

    // The panel hosting this dock is the window of its live representation item,
    // the same object the dock reads for its panel metrics. A dock placed on the
    // desktop has no panel window, so there is nothing to reveal there.
    QQuickWindow *panelWindow = nullptr;
    if (auto *item = PlasmaQuick::AppletQuickItem::itemForApplet(applet)) {
        QQuickWindow *const window = item->window();
        if (window && window->property("visibilityMode").isValid()) {
            panelWindow = window;
        }
    }
    if (!panelWindow) {
        return false;
    }

    if (!m_revealing) {
        m_containment = containment;
        m_previousStatus = static_cast<int>(containment->status());
        const auto previousStatus = containment->status();
        const bool statusAlreadyPinsPanel = previousStatus >= Plasma::Types::NeedsAttentionStatus
            && previousStatus != Plasma::Types::HiddenStatus;
        m_statusChangedByAdapter = !statusAlreadyPinsPanel;
        m_revealing = true;
        Q_EMIT revealingChanged();

        if (m_statusChangedByAdapter) {
            // PanelView::refreshStatus reveals immediately and
            // PanelView::restoreAutoHide keeps the panel visible for as long as
            // the containment has an attention status.
            containment->setStatus(Plasma::Types::NeedsAttentionStatus);
        }
    }

    return true;
}

void PanelRevealAdapter::endReveal()
{
    if (!m_revealing) {
        return;
    }

    if (auto *containment = qobject_cast<Plasma::Containment *>(m_containment.data())) {
        // Do not overwrite a status changed by another Plasma component while
        // the editor was open. Only restore the value owned by this adapter.
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
