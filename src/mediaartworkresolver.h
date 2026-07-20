// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QString>

namespace MediaArtworkResolver
{
QString youtubeThumbnailUrl(const QString &mediaUrl);
QString mediaIdentityKey(const QString &service,
                         const QString &title,
                         const QString &artist,
                         const QString &mediaUrl);
QString stabilizedArtworkUrl(const QString &mprisArtworkUrl,
                             const QString &mediaUrl,
                             const QString &mediaIdentity,
                             const QString &previousMediaIdentity,
                             const QString &previousArtworkUrl);
}
