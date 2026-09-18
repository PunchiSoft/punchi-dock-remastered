// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QPointer>
#include <qqmlregistration.h>

// Reveals the panel that hosts the dock while its items configuration is open.
//
// PanelView treats a containment that needs attention as a request to reveal the
// panel and suspend auto-hide. The adapter applies that public status only for
// the lifetime of the editor and restores the previous status afterwards. It
// deliberately avoids userConfiguring, which belongs to KDE's panel edit mode,
// and never rewrites the panel visibility preference.
class PanelRevealAdapter : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QObject *applet READ applet WRITE setApplet NOTIFY appletChanged)
    Q_PROPERTY(bool revealing READ revealing NOTIFY revealingChanged)

public:
    explicit PanelRevealAdapter(QObject *parent = nullptr);
    ~PanelRevealAdapter() override;

    [[nodiscard]] QObject *applet() const;
    void setApplet(QObject *applet);
    [[nodiscard]] bool revealing() const;

    Q_INVOKABLE bool beginReveal();
    Q_INVOKABLE void endReveal();

Q_SIGNALS:
    void appletChanged();
    void revealingChanged();

private:
    QPointer<QObject> m_applet;
    QPointer<QObject> m_containment;
    int m_previousStatus = 0;
    bool m_statusChangedByAdapter = false;
    bool m_revealing = false;
};
