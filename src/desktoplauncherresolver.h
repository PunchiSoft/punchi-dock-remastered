// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <KService>

#include <QString>

namespace DesktopLauncherResolver
{
struct Resolution
{
    KService::Ptr service;
    QString canonicalPath;

    explicit operator bool() const
    {
        return service && !canonicalPath.isEmpty();
    }
};

Resolution resolveLocalFile(const QString &sourcePath);
}
