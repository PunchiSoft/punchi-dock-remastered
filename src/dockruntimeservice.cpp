// SPDX-License-Identifier: GPL-3.0-or-later

#include "dockruntimeservice.h"

#include <KLocalizedString>

#include <QDir>
#include <QFileInfo>
#include <QProcess>
#include <QRegularExpression>
#include <QSaveFile>
#include <QStandardPaths>
#include <QUrl>

namespace
{
constexpr auto TranslationDomain = "plasma_applet_org.kde.plasma.punchi-dock-remastered";

QString sanitizedInstanceId(QString instanceId)
{
    instanceId = instanceId.trimmed();
    instanceId.replace(QRegularExpression(QStringLiteral("[^A-Za-z0-9_.-]")), QStringLiteral("_"));
    if (instanceId.isEmpty() || instanceId == QLatin1String("undefined") || instanceId == QLatin1String("null")) {
        return QStringLiteral("default");
    }
    return instanceId;
}

QString dockItemsFileNameForInstance(const QString &instanceId)
{
    const QString normalizedInstanceId = sanitizedInstanceId(instanceId);
    if (normalizedInstanceId == QLatin1String("default")) {
        return QStringLiteral("dock_items.json");
    }
    return QStringLiteral("dock_items_%1.json").arg(normalizedInstanceId);
}
}

DockRuntimeService::DockRuntimeService(QObject *parent)
    : QObject(parent)
{
}

bool DockRuntimeService::persistDockItemsJson(const QString &json, const QString &instanceId)
{
    const QString configRoot = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation);
    if (configRoot.isEmpty()) {
        Q_EMIT operationFailed(QStringLiteral("persist"), i18nd(TranslationDomain, "The configuration directory is unavailable."));
        return false;
    }

    QDir configDirectory(configRoot);
    if (!configDirectory.mkpath(QStringLiteral("punchi-dock"))) {
        Q_EMIT operationFailed(QStringLiteral("persist"), i18nd(TranslationDomain, "The configuration directory could not be created."));
        return false;
    }

    const QString filePath = configDirectory.filePath(QStringLiteral("punchi-dock/%1").arg(dockItemsFileNameForInstance(instanceId)));
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
        Q_EMIT operationFailed(QStringLiteral("launch"), i18nd(TranslationDomain, "The command could not be started."));
        return false;
    }

    return true;
}

bool DockRuntimeService::playSound(const QString &soundPath, const QString &eventId)
{
    QString localPath = soundPath.trimmed();
    const QUrl soundUrl(localPath);
    if (soundUrl.isLocalFile()) {
        localPath = soundUrl.toLocalFile();
    }

    if (!localPath.isEmpty() && QFileInfo::exists(localPath)) {
        const QStringList players = {QStringLiteral("paplay"), QStringLiteral("pw-play")};
        for (const QString &player : players) {
            const QString executable = QStandardPaths::findExecutable(player);
            if (!executable.isEmpty() && QProcess::startDetached(executable, {localPath})) {
                return true;
            }
        }
    }

    const QString normalizedEventId = eventId.trimmed();
    const QString canberraExecutable = QStandardPaths::findExecutable(QStringLiteral("canberra-gtk-play"));
    if (!normalizedEventId.isEmpty() && !canberraExecutable.isEmpty()
        && QProcess::startDetached(canberraExecutable,
            {QStringLiteral("-i"), normalizedEventId, QStringLiteral("-d"), QStringLiteral("Punchi Dock")})) {
        return true;
    }

    Q_EMIT operationFailed(QStringLiteral("playSound"), i18nd(TranslationDomain, "No sound player or usable sound was found."));
    return false;
}
