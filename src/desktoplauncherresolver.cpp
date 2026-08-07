// SPDX-License-Identifier: GPL-3.0-or-later

#include "desktoplauncherresolver.h"

#include <KDesktopFile>

#include <QFileInfo>

namespace
{
constexpr qint64 maximumDesktopLauncherSize = 1024 * 1024;
}

DesktopLauncherResolver::Resolution DesktopLauncherResolver::resolveLocalFile(const QString &sourcePath)
{
    if (!sourcePath.endsWith(QLatin1String(".desktop"), Qt::CaseInsensitive)) {
        return {};
    }

    const QFileInfo sourceInfo(sourcePath);
    const QString canonicalPath = sourceInfo.canonicalFilePath();
    if (!sourceInfo.exists() || !sourceInfo.isFile() || canonicalPath.isEmpty()
        || !canonicalPath.endsWith(QLatin1String(".desktop"), Qt::CaseInsensitive)) {
        return {};
    }

    const QFileInfo targetInfo(canonicalPath);
    if (!targetInfo.exists() || !targetInfo.isFile() || targetInfo.size() <= 0
        || targetInfo.size() > maximumDesktopLauncherSize
        || !KDesktopFile::isAuthorizedDesktopFile(canonicalPath)) {
        return {};
    }

    const KService::Ptr service(new KService(canonicalPath));
    if (!service->isValid() || !service->isApplication() || service->exec().trimmed().isEmpty()) {
        return {};
    }

    return {service, canonicalPath};
}
