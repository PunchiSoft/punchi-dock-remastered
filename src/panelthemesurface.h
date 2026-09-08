// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QPointer>
#include <QQuickItem>
#include <QQuickWindow>
#include <qqmlregistration.h>

// A decorative item hosted behind the panel root. It never participates in
// applet layout or writes panel size, padding, masks, focus or window flags.
class PanelThemeSurface : public QQuickItem
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QQuickWindow *panelWindow READ panelWindow WRITE setPanelWindow NOTIFY panelWindowChanged)
    Q_PROPERTY(bool requested READ requested WRITE setRequested NOTIFY requestedChanged)
    Q_PROPERTY(bool hosting READ hosting NOTIFY hostingChanged)
    Q_PROPERTY(QQuickItem *contentReference READ contentReference WRITE setContentReference NOTIFY contentReferenceChanged)
    Q_PROPERTY(QRectF contentGeometry READ contentGeometry NOTIFY contentGeometryChanged)

public:
    explicit PanelThemeSurface(QQuickItem *parent = nullptr);
    ~PanelThemeSurface() override;
    QQuickWindow *panelWindow() const { return m_panelWindow; }
    void setPanelWindow(QQuickWindow *window);
    bool requested() const { return m_requested; }
    void setRequested(bool requested);
    bool hosting() const { return m_hosting; }
    QQuickItem *contentReference() const { return m_contentReference; }
    void setContentReference(QQuickItem *item);
    QRectF contentGeometry() const;

Q_SIGNALS:
    void panelWindowChanged();
    void requestedChanged();
    void hostingChanged();
    void contentReferenceChanged();
    void contentGeometryChanged();

private Q_SLOTS:
    void updateHost();

private:
    static void updateAllHosts();
    void observeRoot(QQuickItem *root);
    void observeContent();
    void setHosting(bool hosting);
    QPointer<QQuickWindow> m_panelWindow;
    QPointer<QQuickItem> m_panelRoot;
    QPointer<QQuickItem> m_contentReference;
    QList<QMetaObject::Connection> m_contentConnections;
    QList<QMetaObject::Connection> m_windowConnections;
    QList<QMetaObject::Connection> m_rootConnections;
    bool m_requested = false;
    bool m_hosting = false;
    bool m_updating = false;
};
