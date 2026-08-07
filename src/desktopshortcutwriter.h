// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QString>
#include <QVariantMap>

namespace DesktopShortcutWriter
{
QVariantMap create(const QString &sourcePath, const QString &desktopDirectory);
}
