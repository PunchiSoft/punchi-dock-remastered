// SPDX-License-Identifier: GPL-3.0-or-later

#include "mediaartworkresolver.h"

#include <QRegularExpression>
#include <QUrl>
#include <QUrlQuery>

namespace
{
bool isSupportedYoutubeHost(const QString &host)
{
    return host == QLatin1String("youtube.com")
        || host == QLatin1String("www.youtube.com")
        || host == QLatin1String("m.youtube.com")
        || host == QLatin1String("music.youtube.com")
        || host == QLatin1String("youtube-nocookie.com")
        || host == QLatin1String("www.youtube-nocookie.com");
}

bool isValidVideoId(const QString &videoId)
{
    static const QRegularExpression pattern(QStringLiteral("^[A-Za-z0-9_-]{11}$"));
    return pattern.match(videoId).hasMatch();
}
}

QString MediaArtworkResolver::youtubeThumbnailUrl(const QString &mediaUrl)
{
    const QUrl url(mediaUrl.trimmed());
    if (!url.isValid() || url.scheme() != QLatin1String("https")
        || (url.port() != -1 && url.port() != 443)) {
        return {};
    }

    const QString host = url.host().toLower();
    QString videoId;
    const QStringList pathSegments =
        url.path(QUrl::FullyDecoded).split(QLatin1Char('/'), Qt::SkipEmptyParts);

    if (host == QLatin1String("youtu.be")) {
        if (pathSegments.size() == 1) {
            videoId = pathSegments.constFirst();
        }
    } else if (isSupportedYoutubeHost(host)) {
        if (url.path() == QLatin1String("/watch")) {
            videoId = QUrlQuery(url).queryItemValue(QStringLiteral("v"), QUrl::FullyDecoded);
        } else if (pathSegments.size() == 2
                   && (pathSegments.constFirst() == QLatin1String("shorts")
                       || pathSegments.constFirst() == QLatin1String("embed")
                       || pathSegments.constFirst() == QLatin1String("live"))) {
            videoId = pathSegments.constLast();
        }
    }

    if (!isValidVideoId(videoId)) {
        return {};
    }

    return QStringLiteral("https://i.ytimg.com/vi/%1/hqdefault.jpg").arg(videoId);
}

QString MediaArtworkResolver::mediaIdentityKey(const QString &service,
                                                const QString &title,
                                                const QString &artist,
                                                const QString &mediaUrl)
{
    const QString normalizedTitle = title.trimmed();
    const QString normalizedArtist = artist.trimmed();
    const QString normalizedMediaUrl = mediaUrl.trimmed();
    if (normalizedTitle.isEmpty() && normalizedArtist.isEmpty() && normalizedMediaUrl.isEmpty()) {
        return {};
    }

    constexpr QChar separator(0x001f);
    return service.trimmed() + separator + normalizedMediaUrl + separator + normalizedTitle
        + separator + normalizedArtist;
}

QString MediaArtworkResolver::stabilizedArtworkUrl(const QString &mprisArtworkUrl,
                                                    const QString &mediaUrl,
                                                    const QString &mediaIdentity,
                                                    const QString &previousMediaIdentity,
                                                    const QString &previousArtworkUrl)
{
    if (!mediaIdentity.isEmpty() && mediaIdentity == previousMediaIdentity
        && !previousArtworkUrl.isEmpty()) {
        return previousArtworkUrl;
    }

    const QString providedArtwork = mprisArtworkUrl.trimmed();
    if (!providedArtwork.isEmpty()) {
        return providedArtwork;
    }

    return youtubeThumbnailUrl(mediaUrl);
}
