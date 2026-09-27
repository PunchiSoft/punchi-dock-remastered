// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QPointer>
#include <QQuickWindow>
#include <qqmlregistration.h>

// Keeps an auto-hidden panel visible while this applet is being configured.
//
// The adapter leases the containment attention status and restores it only
// while it still owns the temporary value. QML declares the request; all
// Plasma coordination and rollback remain isolated here.
class PanelRevealAdapter : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QObject *applet READ applet WRITE setApplet NOTIFY appletChanged)
    Q_PROPERTY(QQuickWindow *panelWindow READ panelWindow WRITE setPanelWindow NOTIFY panelWindowChanged)
    Q_PROPERTY(bool requested READ requested WRITE setRequested NOTIFY requestedChanged)
    Q_PROPERTY(bool revealing READ revealing NOTIFY revealingChanged)

public:
    explicit PanelRevealAdapter(QObject *parent = nullptr);
    ~PanelRevealAdapter() override;

    [[nodiscard]] QObject *applet() const;
    void setApplet(QObject *applet);

    [[nodiscard]] QQuickWindow *panelWindow() const;
    void setPanelWindow(QQuickWindow *panelWindow);

    [[nodiscard]] bool requested() const;
    void setRequested(bool requested);

    [[nodiscard]] bool revealing() const;

Q_SIGNALS:
    void appletChanged();
    void panelWindowChanged();
    void requestedChanged();
    void revealingChanged();

private:
    bool beginReveal();
    void endReveal();
    void synchronizeRequest();

    QPointer<QObject> m_applet;
    QPointer<QQuickWindow> m_panelWindow;
    QPointer<QObject> m_containment;
    int m_previousStatus = 0;
    bool m_requested = false;
    bool m_statusChangedByAdapter = false;
    bool m_revealing = false;
};
