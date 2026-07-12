// SPDX-License-Identifier: GPL-3.0-or-later

#include "dockruntimeservice.h"

#include <QDir>
#include <QProcess>
#include <QSaveFile>
#include <QStandardPaths>

DockRuntimeService::DockRuntimeService(QObject *parent)
    : QObject(parent)
{
}

bool DockRuntimeService::persistDockItemsJson(const QString &json)
{
    const QString configRoot = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation);
    if (configRoot.isEmpty()) {
        Q_EMIT operationFailed(QStringLiteral("persist"), tr("The configuration directory is unavailable."));
        return false;
    }

    QDir configDirectory(configRoot);
    if (!configDirectory.mkpath(QStringLiteral("punchi-dock-remastered"))) {
        Q_EMIT operationFailed(QStringLiteral("persist"), tr("The configuration directory could not be created."));
        return false;
    }

    const QString filePath = configDirectory.filePath(QStringLiteral("punchi-dock-remastered/dock_items.json"));
    QSaveFile file(filePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        Q_EMIT operationFailed(QStringLiteral("persist"), file.errorString());
        return false;
    }

    const QByteArray data = (json.trimmed().isEmpty() ? QStringLiteral("[]") : json).toUtf8();
    if (file.write(data) != data.size() || !file.commit()) {
        Q_EMIT operationFailed(QStringLiteral("persist"), file.errorString());
        return false;
    }

    return true;
}

bool DockRuntimeService::launchCommand(const QString &command)
{
    const QString normalizedCommand = command.trimmed();
    if (normalizedCommand.isEmpty()) {
        return false;
    }

    if (!QProcess::startDetached(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), normalizedCommand})) {
        Q_EMIT operationFailed(QStringLiteral("launch"), tr("The command could not be started."));
        return false;
    }

    return true;
}
