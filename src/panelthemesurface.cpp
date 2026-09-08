// SPDX-License-Identifier: GPL-3.0-or-later
#include "panelthemesurface.h"

#include <QMetaProperty>
#include <QScopedValueRollback>
#include <QTimer>

#include <cmath>
#include <utility>

namespace
{
QList<QPointer<PanelThemeSurface>> surfaces;
constexpr const char *marginNames[] = {
    "leftShadowMargin", "topShadowMargin", "rightShadowMargin", "bottomShadowMargin"
};

bool supportsPanelContract(QQuickItem *item)
{
    if (!item || item->metaObject()->indexOfProperty("panelMask") < 0) {
        return false;
    }
    for (const char *name : marginNames) {
        const int index = item->metaObject()->indexOfProperty(name);
        if (index < 0 || !item->metaObject()->property(index).hasNotifySignal()) {
            return false;
        }
    }
    return true;
}
}

PanelThemeSurface::PanelThemeSurface(QQuickItem *parent) : QQuickItem(parent)
{
    surfaces.append(this);
    setVisible(false);
    setEnabled(false);
    setAcceptedMouseButtons(Qt::NoButton);
    setAcceptHoverEvents(false);
    connect(this, &QQuickItem::parentChanged, this, &PanelThemeSurface::updateHost);
    connect(this, &QQuickItem::xChanged, this, &PanelThemeSurface::contentGeometryChanged);
    connect(this, &QQuickItem::yChanged, this, &PanelThemeSurface::contentGeometryChanged);
    connect(this, &PanelThemeSurface::hostingChanged, this, &PanelThemeSurface::contentGeometryChanged);
}

PanelThemeSurface::~PanelThemeSurface()
{
    for (const auto &connection : std::as_const(m_contentConnections)) {
        disconnect(connection);
    }
    for (const auto &connection : std::as_const(m_rootConnections)) {
        disconnect(connection);
    }
    for (const auto &connection : std::as_const(m_windowConnections)) {
        disconnect(connection);
    }
    surfaces.removeAll(QPointer<PanelThemeSurface>(this));
    // Re-evaluate conflicts after this surface has left the scene graph.
    for (const auto &surface : std::as_const(surfaces)) {
        if (surface) {
            QTimer::singleShot(0, surface, &PanelThemeSurface::updateHost);
        }
    }
}

void PanelThemeSurface::setContentReference(QQuickItem *item)
{
    if (m_contentReference == item) {
        return;
    }
    m_contentReference = item;
    observeContent();
    Q_EMIT contentReferenceChanged();
}

QRectF PanelThemeSurface::contentGeometry() const
{
    if (!m_hosting || !m_contentReference || !window()
        || m_contentReference->window() != window()) {
        return {};
    }
    return m_contentReference->mapRectToItem(this,
        QRectF(0, 0, m_contentReference->width(), m_contentReference->height()));
}

void PanelThemeSurface::observeContent()
{
    for (const auto &connection : std::as_const(m_contentConnections)) {
        disconnect(connection);
    }
    m_contentConnections.clear();
    // Observe the whole visual ancestry: containment movement is independent
    // of the resting row's local coordinates. No per-frame polling is needed.
    for (auto *item = m_contentReference.data(); item; item = item->parentItem()) {
        for (auto signal : {&QQuickItem::xChanged, &QQuickItem::yChanged,
                 &QQuickItem::widthChanged, &QQuickItem::heightChanged,
                 &QQuickItem::scaleChanged, &QQuickItem::rotationChanged}) {
            m_contentConnections.append(connect(item, signal,
                this, &PanelThemeSurface::contentGeometryChanged));
        }
        m_contentConnections.append(connect(item, &QQuickItem::transformOriginChanged,
            this, &PanelThemeSurface::contentGeometryChanged));
        m_contentConnections.append(connect(item, &QQuickItem::windowChanged,
            this, &PanelThemeSurface::contentGeometryChanged));
        m_contentConnections.append(connect(item, &QQuickItem::parentChanged,
            this, &PanelThemeSurface::observeContent));
    }
    if (m_contentReference) {
        m_contentConnections.append(connect(m_contentReference, &QObject::destroyed, this, [this]() {
            m_contentReference = nullptr;
            observeContent();
            Q_EMIT contentReferenceChanged();
        }));
    }
    Q_EMIT contentGeometryChanged();
}

void PanelThemeSurface::setPanelWindow(QQuickWindow *window)
{
    if (m_panelWindow == window) {
        return;
    }
    for (const auto &connection : std::as_const(m_windowConnections)) {
        disconnect(connection);
    }
    m_windowConnections.clear();
    observeRoot(nullptr);
    m_panelWindow = window;
    if (window) {
        m_windowConnections.append(connect(window->contentItem(), &QQuickItem::childrenChanged,
            this, &PanelThemeSurface::updateHost));
        m_windowConnections.append(connect(window, &QObject::destroyed, this, [this]() {
            m_panelWindow = nullptr;
            observeRoot(nullptr);
            setHosting(false);
        }));
    }
    Q_EMIT panelWindowChanged();
    updateAllHosts();
}

void PanelThemeSurface::setRequested(bool requested)
{
    if (m_requested == requested) {
        return;
    }
    m_requested = requested;
    Q_EMIT requestedChanged();
    updateAllHosts();
}

void PanelThemeSurface::updateAllHosts()
{
    const auto snapshot = surfaces;
    for (const auto &surface : snapshot) {
        if (surface) {
            surface->updateHost();
        }
    }
}

void PanelThemeSurface::observeRoot(QQuickItem *root)
{
    if (m_panelRoot == root) {
        return;
    }
    for (const auto &connection : std::as_const(m_rootConnections)) {
        disconnect(connection);
    }
    m_rootConnections.clear();
    m_panelRoot = root;
    if (!root) {
        return;
    }
    const auto slot = metaObject()->method(metaObject()->indexOfSlot("updateHost()"));
    for (const char *name : marginNames) {
        const auto property = root->metaObject()->property(root->metaObject()->indexOfProperty(name));
        m_rootConnections.append(connect(root, property.notifySignal(), this, slot));
    }
    for (auto signal : {&QQuickItem::xChanged, &QQuickItem::yChanged,
             &QQuickItem::widthChanged, &QQuickItem::heightChanged,
             &QQuickItem::scaleChanged, &QQuickItem::rotationChanged, &QQuickItem::zChanged}) {
        m_rootConnections.append(connect(root, signal, this, &PanelThemeSurface::updateHost));
    }
    m_rootConnections.append(connect(root, &QQuickItem::transformOriginChanged,
        this, &PanelThemeSurface::updateHost));
    m_rootConnections.append(connect(root, &QObject::destroyed, this, [this]() {
        m_panelRoot = nullptr;
        setHosting(false);
        QTimer::singleShot(0, this, &PanelThemeSurface::updateHost);
    }));
}

void PanelThemeSurface::setHosting(bool hosting)
{
    setVisible(hosting);
    if (m_hosting != hosting) {
        m_hosting = hosting;
        Q_EMIT hostingChanged();
    }
}

void PanelThemeSurface::updateHost()
{
    if (m_updating) {
        return;
    }
    QScopedValueRollback<bool> guard(m_updating, true);
    if (!m_requested || !m_panelWindow || !m_panelWindow->contentItem()) {
        setHosting(false);
        return;
    }
    int candidates = 0;
    for (const auto &surface : std::as_const(surfaces)) {
        candidates += surface && surface->requested() && surface->panelWindow() == m_panelWindow;
    }
    if (candidates != 1) {
        setHosting(false);
        return;
    }
    QQuickItem *root = nullptr;
    for (auto *child : m_panelWindow->contentItem()->childItems()) {
        if (child != this && supportsPanelContract(child)) {
            if (root) {
                setHosting(false);
                return;
            }
            root = child;
        }
    }
    observeRoot(root);
    if (!root) {
        setHosting(false);
        return;
    }
    qreal margins[4];
    for (int index = 0; index < 4; ++index) {
        bool ok = false;
        margins[index] = root->property(marginNames[index]).toDouble(&ok);
        if (!ok || !std::isfinite(margins[index])) {
            setHosting(false);
            return;
        }
    }
    // Panel.qml defines these as the signed distance from its rectangle to
    // floatingTranslucentItem. They already include floating/attached motion.
    const QRectF local(-margins[0], -margins[1],
        root->width() + margins[0] + margins[2],
        root->height() + margins[1] + margins[3]);
    const QRectF mapped = root->mapRectToItem(m_panelWindow->contentItem(), local);
    if (!mapped.isValid() || !std::isfinite(mapped.x()) || !std::isfinite(mapped.y())
        || !std::isfinite(mapped.width()) || !std::isfinite(mapped.height())) {
        setHosting(false);
        return;
    }
    setParentItem(m_panelWindow->contentItem());
    setZ(root->z() - 1);
    setPosition(mapped.topLeft());
    setSize(mapped.size());
    setHosting(true);
}
