// SPDX-License-Identifier: GPL-3.0-or-later

#include "mprisplayerselection.h"

#include <iostream>

namespace
{
using Candidate = MprisPlayerSelection::Candidate;

bool expectService(const char *name,
                   const QList<Candidate> &candidates,
                   MprisPlayerSelection::Mode mode,
                   const QString &applicationId,
                   const QString &currentService,
                   const QString &expected)
{
    const QString actual = MprisPlayerSelection::selectService(
        candidates, mode, applicationId, currentService);
    if (actual == expected) {
        return true;
    }
    std::cerr << "FAILED: " << name << '\n';
    return false;
}
}

int main()
{
    const Candidate spotify{
        QStringLiteral("org.mpris.MediaPlayer2.spotify"),
        QStringLiteral("spotify"),
        QStringLiteral("Spotify"),
        QStringLiteral("Paused"),
        true,
    };
    const Candidate browser{
        QStringLiteral("org.mpris.MediaPlayer2.firefox.instance1"),
        QStringLiteral("firefox"),
        QStringLiteral("Firefox"),
        QStringLiteral("Playing"),
        true,
    };
    const Candidate stopped{
        QStringLiteral("org.mpris.MediaPlayer2.vlc"),
        QStringLiteral("vlc"),
        QStringLiteral("VLC media player"),
        QStringLiteral("Stopped"),
        true,
    };
    const Candidate elisa{
        QStringLiteral("org.mpris.MediaPlayer2.elisa"),
        QStringLiteral("org.kde.elisa"),
        QStringLiteral("Elisa"),
        QStringLiteral("Stopped"),
        true,
    };
    const Candidate dragonPlayer{
        QStringLiteral("org.mpris.MediaPlayer2.org.kde.dragonplayer"),
        QStringLiteral("org.kde.dragonplayer"),
        QStringLiteral("Dragon Player"),
        QStringLiteral("Stopped"),
        true,
    };

    bool passed = true;
    passed &= expectService("playing player wins automatic selection",
                            {spotify, browser, stopped},
                            MprisPlayerSelection::Mode::ActivePlayer,
                            QString(),
                            spotify.service,
                            browser.service);
    passed &= expectService("paused player wins over stopped player",
                            {spotify, stopped},
                            MprisPlayerSelection::Mode::ActivePlayer,
                            QString(),
                            QString(),
                            spotify.service);
    passed &= expectService("current player remains stable within equal status",
                            {spotify,
                             Candidate{QStringLiteral("org.mpris.MediaPlayer2.other"),
                                       QStringLiteral("other"),
                                       QStringLiteral("Other"),
                                       QStringLiteral("Paused"),
                                       true}},
                            MprisPlayerSelection::Mode::ActivePlayer,
                            QString(),
                            spotify.service,
                            spotify.service);
    passed &= expectService("application selection ignores another playing app",
                            {spotify, browser},
                            MprisPlayerSelection::Mode::Application,
                            QStringLiteral("spotify.desktop"),
                            QString(),
                            spotify.service);
    passed &= expectService("application selection supports normalized identity",
                            {browser},
                            MprisPlayerSelection::Mode::Application,
                            QStringLiteral("org.mozilla.firefox"),
                            QString(),
                            browser.service);
    passed &= expectService("application selection supports short desktop token",
                            {stopped},
                            MprisPlayerSelection::Mode::Application,
                            QStringLiteral("org.videolan.VLC.desktop"),
                            QString(),
                            stopped.service);
    passed &= expectService("unmatched application has no player",
                            {spotify, browser},
                            MprisPlayerSelection::Mode::Application,
                            QStringLiteral("org.kde.konsole"),
                            QString(),
                            QString());
    passed &= expectService("shared KDE namespace does not match another application",
                            {elisa, dragonPlayer},
                            MprisPlayerSelection::Mode::Application,
                            QStringLiteral("org.kde.kate"),
                            elisa.service,
                            QString());
    passed &= expectService("full KDE desktop identity selects its own player",
                            {elisa, dragonPlayer},
                            MprisPlayerSelection::Mode::Application,
                            QStringLiteral("org.kde.elisa.desktop"),
                            QString(),
                            elisa.service);
    passed &= expectService("short KDE identity selects its own player",
                            {elisa, dragonPlayer},
                            MprisPlayerSelection::Mode::Application,
                            QStringLiteral("dragonplayer"),
                            QString(),
                            dragonPlayer.service);
    passed &= expectService("KDE player identity remains a valid fallback",
                            {Candidate{elisa.service,
                                       QString(),
                                       QStringLiteral("Elisa"),
                                       QStringLiteral("Stopped"),
                                       true}},
                            MprisPlayerSelection::Mode::Application,
                            QStringLiteral("org.kde.elisa"),
                            QString(),
                            elisa.service);
    passed &= expectService("empty automatic candidate list has no player",
                            {},
                            MprisPlayerSelection::Mode::ActivePlayer,
                            QString(),
                            QString(),
                            QString());

    return passed ? 0 : 1;
}
