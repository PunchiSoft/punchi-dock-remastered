// SPDX-License-Identifier: GPL-3.0-or-later

#include "themeintegration.h"

ThemeIntegration::ThemeIntegration(QObject *parent)
    : QObject(parent)
{
    connect(&m_theme, &Plasma::Theme::themeChanged, this, &ThemeIntegration::adaptiveTransparencyEnabledChanged);
}

bool ThemeIntegration::adaptiveTransparencyEnabled() const
{
    return m_theme.adaptiveTransparencyEnabled();
}
