// SPDX-License-Identifier: GPL-3.0-or-later

#include "mediaartworkresolver.h"

#include <array>
#include <iostream>

namespace
{
struct TestCase {
    const char *name;
    const char *mediaUrl;
    const char *expected;
};
}

int main()
{
    constexpr auto thumbnail = "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg";
    const std::array tests = {
        TestCase{"watch URL", "https://www.youtube.com/watch?v=dQw4w9WgXcQ", thumbnail},
        TestCase{"watch URL with playlist",
                 "https://youtube.com/watch?list=RDtest&v=dQw4w9WgXcQ&start_radio=1",
                 thumbnail},
        TestCase{"mobile URL", "https://m.youtube.com/watch?v=dQw4w9WgXcQ", thumbnail},
        TestCase{"music URL", "https://music.youtube.com/watch?v=dQw4w9WgXcQ", thumbnail},
        TestCase{"short URL", "https://youtu.be/dQw4w9WgXcQ?t=12", thumbnail},
        TestCase{"shorts URL", "https://www.youtube.com/shorts/dQw4w9WgXcQ", thumbnail},
        TestCase{"embed URL", "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ", thumbnail},
        TestCase{"live URL", "https://www.youtube.com/live/dQw4w9WgXcQ", thumbnail},
        TestCase{"HTTP rejected", "http://www.youtube.com/watch?v=dQw4w9WgXcQ", ""},
        TestCase{"unexpected port rejected", "https://www.youtube.com:444/watch?v=dQw4w9WgXcQ", ""},
        TestCase{"lookalike host rejected", "https://youtube.com.example.org/watch?v=dQw4w9WgXcQ", ""},
        TestCase{"userinfo host rejected", "https://youtube.com@invalid.example/watch?v=dQw4w9WgXcQ", ""},
        TestCase{"invalid ID rejected", "https://www.youtube.com/watch?v=../../secret", ""},
        TestCase{"long ID rejected", "https://www.youtube.com/watch?v=dQw4w9WgXcQextra", ""},
        TestCase{"missing ID rejected", "https://www.youtube.com/watch?list=RDtest", ""},
        TestCase{"unrelated URL rejected", "https://example.org/watch?v=dQw4w9WgXcQ", ""},
    };

    bool passed = true;
    for (const TestCase &test : tests) {
        const QString result =
            MediaArtworkResolver::youtubeThumbnailUrl(QString::fromUtf8(test.mediaUrl));
        if (result != QString::fromUtf8(test.expected)) {
            std::cerr << "FAILED: " << test.name << '\n';
            passed = false;
        }
    }

    const QString service = QStringLiteral("org.mpris.MediaPlayer2.firefox.instance_test");
    const QString mediaUrl = QStringLiteral("https://music.youtube.com/");
    const QString identity = MediaArtworkResolver::mediaIdentityKey(
        service,
        QStringLiteral("Song title"),
        QStringLiteral("Artist"),
        mediaUrl);
    const QString mprisArtwork = QStringLiteral("file:///tmp/firefox-artwork.png");

    const auto expectEqual = [&passed](const char *name,
                                       const QString &actual,
                                       const QString &expected) {
        if (actual != expected) {
            std::cerr << "FAILED: " << name << '\n';
            passed = false;
        }
    };

    expectEqual("MPRIS artwork has priority",
                MediaArtworkResolver::stabilizedArtworkUrl(
                    mprisArtwork, mediaUrl, identity, QString(), QString()),
                mprisArtwork);
    expectEqual("same media retains artwork after partial update",
                MediaArtworkResolver::stabilizedArtworkUrl(
                    QString(), mediaUrl, identity, identity, mprisArtwork),
                mprisArtwork);
    expectEqual("same media ignores replacement artwork URL churn",
                MediaArtworkResolver::stabilizedArtworkUrl(
                    QStringLiteral("file:///tmp/new-artwork.png"),
                    mediaUrl,
                    identity,
                    identity,
                    mprisArtwork),
                mprisArtwork);
    expectEqual("same media accepts its first available artwork",
                MediaArtworkResolver::stabilizedArtworkUrl(
                    mprisArtwork, mediaUrl, identity, identity, QString()),
                mprisArtwork);

    const QString nextYoutubeUrl =
        QStringLiteral("https://www.youtube.com/watch?v=dQw4w9WgXcQ");
    const QString nextIdentity = MediaArtworkResolver::mediaIdentityKey(
        service,
        QStringLiteral("Next video"),
        QStringLiteral("Next channel"),
        nextYoutubeUrl);
    expectEqual("new YouTube media uses its own fallback",
                MediaArtworkResolver::stabilizedArtworkUrl(
                    QString(), nextYoutubeUrl, nextIdentity, identity, mprisArtwork),
                QString::fromUtf8(thumbnail));
    expectEqual("new generic media never inherits previous artwork",
                MediaArtworkResolver::stabilizedArtworkUrl(
                    QString(), mediaUrl, nextIdentity, identity, mprisArtwork),
                QString());
    expectEqual("empty metadata never retains artwork",
                MediaArtworkResolver::stabilizedArtworkUrl(
                    QString(), QString(), QString(), identity, mprisArtwork),
                QString());

    return passed ? 0 : 1;
}
