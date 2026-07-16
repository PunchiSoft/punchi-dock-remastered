// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QByteArray>
#include <QString>
#include <QVariantMap>

namespace DockThemeValidator
{
inline constexpr qsizetype maximumFileSize = 64 * 1024;

struct Result {
    bool ok = false;
    QVariantMap theme;
    QString errorCode;
};

Result validate(const QByteArray &data);
}
