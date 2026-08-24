// SPDX-License-Identifier: GPL-3.0-or-later

#include "blurbehindcontroller.h"

#include <KWindowEffects>
#include <algorithm>
#include <cmath>
#include <limits>
#include <QEvent>
#include <QPlatformSurfaceEvent>
#include <QRegion>
#include <QTimer>
#include <QVariant>
#include <QWindow>

namespace
{
bool readInset(QObject *insetObject, const char *propertyName, int &value)
{
    if (!insetObject) {
        return false;
    }

    bool converted = false;
    const double requestedValue = insetObject->property(propertyName).toDouble(&converted);
    if (!converted || !std::isfinite(requestedValue) || requestedValue < 0
        || requestedValue > std::numeric_limits<int>::max()) {
        return false;
    }

    value = qRound(requestedValue);
    return true;
}

bool maskSourceInsets(QObject *maskSource, QMargins &insets)
{
    QObject *insetObject = maskSource
        ? maskSource->property("inset").value<QObject *>()
        : nullptr;
    int left = 0;
    int top = 0;
    int right = 0;
    int bottom = 0;
    if (!readInset(insetObject, "left", left)
        || !readInset(insetObject, "top", top)
        || !readInset(insetObject, "right", right)
        || !readInset(insetObject, "bottom", bottom)) {
        return false;
    }

    insets = QMargins(left, top, right, bottom);
    return true;
}
}

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
    if (watched == m_window
        && (event->type() == QEvent::Expose
            || (event->type() == QEvent::PlatformSurface
                && static_cast<QPlatformSurfaceEvent *>(event)->surfaceEventType()
                    == QPlatformSurfaceEvent::SurfaceCreated))) {
        reapply();
    }
    return QObject::eventFilter(watched, event);
}

QObject *BlurBehindController::maskSource() const
{
    return m_maskSource;
}

void BlurBehindController::setMaskSource(QObject *maskSource)
{
    if (m_maskSource == maskSource) {
        return;
    }

    if (m_maskSource) {
        disconnect(m_maskSource, nullptr, this, nullptr);
    }
    if (m_maskInsetSource) {
        disconnect(m_maskInsetSource, nullptr, this, nullptr);
    }
    m_maskSource = maskSource;
    m_maskInsetSource = nullptr;
    invalidateMaskCache();
    if (m_maskSource) {
        if (m_maskSource->metaObject()->indexOfSignal("maskChanged()") >= 0) {
            connect(m_maskSource, SIGNAL(maskChanged()), this, SLOT(reapply()));
        }
        m_maskInsetSource = m_maskSource->property("inset").value<QObject *>();
        if (m_maskInsetSource
            && m_maskInsetSource->metaObject()->indexOfSignal("marginsChanged()") >= 0) {
            connect(m_maskInsetSource, SIGNAL(marginsChanged()), this, SLOT(reapply()));
        }
        connect(m_maskSource, &QObject::destroyed, this, [this]() {
            if (m_maskInsetSource) {
                disconnect(m_maskInsetSource, nullptr, this, nullptr);
            }
            m_maskSource = nullptr;
            m_maskInsetSource = nullptr;
            invalidateMaskCache();
            Q_EMIT maskSourceChanged();
            apply();
        });
    }

    Q_EMIT maskSourceChanged();
    apply();
}

bool BlurBehindController::useMaskSourceInsets() const
{
    return m_useMaskSourceInsets;
}

void BlurBehindController::setUseMaskSourceInsets(bool useMaskSourceInsets)
{
    if (m_useMaskSourceInsets == useMaskSourceInsets) {
        return;
    }
    m_useMaskSourceInsets = useMaskSourceInsets;
    Q_EMIT useMaskSourceInsetsChanged();
    apply();
}

QPoint BlurBehindController::maskOffset() const
{
    return m_maskOffset;
}

void BlurBehindController::setMaskOffset(const QPoint &maskOffset)
{
    if (m_maskOffset == maskOffset) {
        return;
    }
    m_maskOffset = maskOffset;
    Q_EMIT maskOffsetChanged();
    apply();
}

QRect BlurBehindController::maskClipRect() const
{
    return m_maskClipRect;
}

void BlurBehindController::setMaskClipRect(const QRect &maskClipRect)
{
    if (m_maskClipRect == maskClipRect) {
        return;
    }
    m_maskClipRect = maskClipRect;
    Q_EMIT maskClipRectChanged();
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
    invalidateMaskCache();
    if (m_reapplyScheduled) {
        return;
    }

    m_reapplyScheduled = true;
    QTimer::singleShot(0, this, [this]() {
        m_reapplyScheduled = false;
        apply();
    });
}

void BlurBehindController::invalidateMaskCache()
{
    m_maskCacheValid = false;
    m_cachedSourceMask = QRegion();
    m_cachedContractedMask = QRegion();
    m_cachedInsets = QMargins();
}

QRegion BlurBehindController::contractMaskToInsets(
    const QRegion &sourceMask,
    const QMargins &insets)
{
    if (sourceMask.isEmpty()) {
        return QRegion();
    }

    const int left = std::max(0, insets.left());
    const int top = std::max(0, insets.top());
    const int right = std::max(0, insets.right());
    const int bottom = std::max(0, insets.bottom());
    const QRect sourceBounds = sourceMask.boundingRect();
    if (qint64(left) + right >= sourceBounds.width()
        || qint64(top) + bottom >= sourceBounds.height()) {
        return QRegion();
    }

    const int radialInset = std::min({left, top, right, bottom});
    QRegion contractedMask = sourceMask;
    if (radialInset > 0) {
        const QRegion radialSource = contractedMask;
        const qint64 squaredRadius = qint64(radialInset) * radialInset;
        for (int y = -radialInset; y <= radialInset; ++y) {
            for (int x = -radialInset; x <= radialInset; ++x) {
                if (qint64(x) * x + qint64(y) * y > squaredRadius
                    || (x == 0 && y == 0)) {
                    continue;
                }
                contractedMask &= radialSource.translated(x, y);
                if (contractedMask.isEmpty()) {
                    return QRegion();
                }
            }
        }
    }

    const int residualLeft = left - radialInset;
    const int residualTop = top - radialInset;
    const int residualRight = right - radialInset;
    const int residualBottom = bottom - radialInset;
    if (residualLeft == 0 && residualTop == 0
        && residualRight == 0 && residualBottom == 0) {
        return contractedMask;
    }

    const auto erodeDirection = [&contractedMask](int count, int xStep, int yStep) {
        for (int step = 0; step < count; ++step) {
            contractedMask &= contractedMask.translated(xStep, yStep);
            if (contractedMask.isEmpty()) {
                return false;
            }
        }
        return true;
    };
    if (!erodeDirection(residualLeft, 1, 0)
        || !erodeDirection(residualRight, -1, 0)
        || !erodeDirection(residualTop, 0, 1)
        || !erodeDirection(residualBottom, 0, -1)) {
        return QRegion();
    }
    return contractedMask;
}

void BlurBehindController::apply()
{
    refreshAvailability();

    QRegion sourceMask = m_maskSource
        ? m_maskSource->property("mask").value<QRegion>()
        : QRegion();
    if (m_useMaskSourceInsets && !sourceMask.isEmpty()) {
        QMargins sourceInsets;
        if (maskSourceInsets(m_maskSource, sourceInsets)) {
            if (!m_maskCacheValid || m_cachedSourceMask != sourceMask
                || m_cachedInsets != sourceInsets) {
                m_cachedSourceMask = sourceMask;
                m_cachedInsets = sourceInsets;
                m_cachedContractedMask = contractMaskToInsets(sourceMask, sourceInsets);
                m_maskCacheValid = true;
            }
            sourceMask = m_cachedContractedMask;
        }
    }
    const bool hasRegion = m_fullWindow || !sourceMask.isEmpty();
    const bool shouldEnable = m_window && m_available && m_enabled && hasRegion;
    if (!m_window) {
        updateActive(false);
        return;
    }

    QRegion requestedRegion = m_fullWindow
        ? QRegion()
        : sourceMask.translated(m_maskOffset);
    if (!m_fullWindow && m_maskClipRect.isValid()
        && !m_maskClipRect.isEmpty()) {
        requestedRegion &= QRegion(m_maskClipRect);
    }
    KWindowEffects::enableBlurBehind(
        m_window,
        shouldEnable,
        shouldEnable ? requestedRegion : QRegion());
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
