// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QPointer>
#include <QQuickWindow>
#include <qqmlregistration.h>

class PanelInputRegionSynchronizer : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QQuickWindow *panelWindow READ panelWindow WRITE setPanelWindow NOTIFY panelWindowChanged)
    Q_PROPERTY(bool enabled READ isEnabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(bool verticalPanel READ isVerticalPanel WRITE setVerticalPanel NOTIFY verticalPanelChanged)

public:
    explicit PanelInputRegionSynchronizer(QObject *parent = nullptr);

    QQuickWindow *panelWindow() const;
    void setPanelWindow(QQuickWindow *window);

    bool isEnabled() const;
    void setEnabled(bool enabled);

    bool isVerticalPanel() const;
    void setVerticalPanel(bool verticalPanel);

Q_SIGNALS:
    void panelWindowChanged();
    void enabledChanged();
    void verticalPanelChanged();

private:
    void scheduleSynchronization();
    void synchronizeInputRegion();

    QPointer<QQuickWindow> m_panelWindow;
    QList<QMetaObject::Connection> m_windowConnections;
    bool m_enabled = false;
    bool m_verticalPanel = false;
    bool m_synchronizationScheduled = false;
};
