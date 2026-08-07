// SPDX-License-Identifier: GPL-3.0-or-later

#include "blurbehindcontroller.h"

#include <KWindowEffects>
#include <QEvent>
#include <QPlatformSurfaceEvent>
#include <QRegion>
#include <QTimer>
#include <QWindow>

BlurBehindController::BlurBehindController(QObject *parent)
    : QObject(parent)
{
    refreshAvailability();
}

BlurBehindController::~BlurBehindController()
{
    disableOnCurrentWindow();
}

QObject *BlurBehindController::window() const
{
    return m_window;
}

void BlurBehindController::setWindow(QObject *windowObject)
{
    QWindow *window = qobject_cast<QWindow *>(windowObject);
    if (m_window == window) {
        return;
    }

    disableOnCurrentWindow();
    if (m_window) {
        m_window->removeEventFilter(this);
        disconnect(m_window, nullptr, this, nullptr);
    }

    m_window = window;
    if (m_window) {
        m_window->installEventFilter(this);
        connect(m_window, &QWindow::visibleChanged, this, [this]() {
            apply();
            if (m_window && m_window->isVisible()) {
                QTimer::singleShot(0, this, [this]() {
                    apply();
                });
            }
        });
        connect(m_window, &QObject::destroyed, this, [this]() {
            m_window = nullptr;
            updateActive(false);
            Q_EMIT windowChanged();
        });
    }

    Q_EMIT windowChanged();
    apply();
}

bool BlurBehindController::eventFilter(QObject *watched, QEvent *event)
{
    if (watched == m_window &&
        (event->type() == QEvent::Expose ||
         (event->type() == QEvent::PlatformSurface &&
          static_cast<QPlatformSurfaceEvent *>(event)->surfaceEventType() == QPlatformSurfaceEvent::SurfaceCreated))) {
        QTimer::singleShot(0, this, &BlurBehindController::reapply);
    }
    return QObject::eventFilter(watched, event);
}

QRect BlurBehindController::region() const
{
    return m_region;
}

void BlurBehindController::setRegion(const QRect &region)
{
    if (m_region == region) {
        return;
    }
    m_region = region;
    Q_EMIT regionChanged();
    apply();
}

bool BlurBehindController::fullWindow() const
{
    return m_fullWindow;
}

void BlurBehindController::setFullWindow(bool fullWindow)
{
    if (m_fullWindow == fullWindow) {
        return;
    }
    m_fullWindow = fullWindow;
    Q_EMIT fullWindowChanged();
    apply();
}

bool BlurBehindController::enabled() const
{
    return m_enabled;
}

void BlurBehindController::setEnabled(bool enabled)
{
    if (m_enabled == enabled) {
        return;
    }
    m_enabled = enabled;
    Q_EMIT enabledChanged();
    apply();
}

bool BlurBehindController::available() const
{
    return m_available;
}

bool BlurBehindController::active() const
{
    return m_active;
}

void BlurBehindController::reapply()
{
    apply();
}

void BlurBehindController::apply()
{
    refreshAvailability();

    const bool hasRegion = m_fullWindow || (m_region.isValid() && !m_region.isEmpty());
    const bool shouldEnable = m_window && m_available && m_enabled && hasRegion;
    if (!m_window) {
        updateActive(false);
        return;
    }

    const QRegion requestedRegion = m_fullWindow ? QRegion() : QRegion(m_region);
    KWindowEffects::enableBlurBehind(m_window, shouldEnable, shouldEnable ? requestedRegion : QRegion());
    updateActive(shouldEnable);
}

void BlurBehindController::refreshAvailability()
{
    const bool available = KWindowEffects::isEffectAvailable(KWindowEffects::BlurBehind);
    if (m_available == available) {
        return;
    }
    m_available = available;
    Q_EMIT availableChanged();
}

void BlurBehindController::disableOnCurrentWindow()
{
    if (m_window && m_active) {
        KWindowEffects::enableBlurBehind(m_window, false);
    }
    updateActive(false);
}

void BlurBehindController::updateActive(bool active)
{
    if (m_active == active) {
        return;
    }
    m_active = active;
    Q_EMIT activeChanged();
}
