// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <Plasma/Theme>

#include <QObject>
#include <qqmlregistration.h>

class ThemeIntegration : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool adaptiveTransparencyEnabled READ adaptiveTransparencyEnabled NOTIFY adaptiveTransparencyEnabledChanged)

public:
    explicit ThemeIntegration(QObject *parent = nullptr);

    bool adaptiveTransparencyEnabled() const;

Q_SIGNALS:
    void adaptiveTransparencyEnabledChanged();

private:
    Plasma::Theme m_theme;
};
