// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QList>
#include <QString>

namespace MprisPlayerSelection
{
enum class Mode {
    Application,
    ActivePlayer,
};

struct Candidate {
    QString service;
    QString desktopEntry;
    QString identity;
    QString playbackStatus;
    bool canControl = false;
};

QString selectService(const QList<Candidate> &candidates,
                      Mode mode,
                      const QString &applicationId,
                      const QString &currentService);
}
