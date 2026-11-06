// SPDX-License-Identifier: GPL-2.0-or-later
#pragma once

#include <QDir>
#include <QStandardPaths>
#include <QString>

// Standard locations a Dock item may store instead of an absolute path.
//
// A shipped container has to name a folder that exists on every machine, and
// the user directories are localized (Descargas, Téléchargements, …). Storing a
// token keeps the shipped item portable: the runtime resolves it against the
// session, so the folder moves with the user's XDG configuration.
namespace PunchiPath {

inline QString standardTokenPath(const QString &token)
{
    const QString value = token.trimmed().toLower();
    if (value == QLatin1String("xdg:download") || value == QLatin1String("xdg:downloads")) {
        return QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    }
    if (value == QLatin1String("xdg:desktop")) {
        return QStandardPaths::writableLocation(QStandardPaths::DesktopLocation);
    }
    if (value == QLatin1String("xdg:documents")) {
        return QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    }
    if (value == QLatin1String("xdg:pictures")) {
        return QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
    }
    if (value == QLatin1String("xdg:music")) {
        return QStandardPaths::writableLocation(QStandardPaths::MusicLocation);
    }
    if (value == QLatin1String("xdg:videos")) {
        return QStandardPaths::writableLocation(QStandardPaths::MoviesLocation);
    }
    if (value == QLatin1String("xdg:home")) {
        return QDir::homePath();
    }
    return {};
}

// Expands a leading tilde and the XDG tokens. Any other value is returned
// trimmed, unchanged, so the caller keeps applying its own validation.
inline QString expandUserPath(const QString &input)
{
    const QString trimmed = input.trimmed();
    if (trimmed.isEmpty()) {
        return {};
    }
    const QString tokenPath = standardTokenPath(trimmed);
    if (!tokenPath.isEmpty()) {
        return tokenPath;
    }
    if (trimmed == QLatin1String("~")) {
        return QDir::homePath();
    }
    if (trimmed.startsWith(QLatin1String("~/"))) {
        return QDir::homePath() + trimmed.mid(1);
    }
    return trimmed;
}

} // namespace PunchiPath
