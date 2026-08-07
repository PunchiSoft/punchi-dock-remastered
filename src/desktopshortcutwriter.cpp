// SPDX-License-Identifier: GPL-3.0-or-later

#include "desktopshortcutwriter.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSaveFile>

namespace
{
QVariantMap result(const QString &status, bool success = false)
{
    return {
        {QStringLiteral("status"), status},
        {QStringLiteral("success"), success},
    };
}
}

QVariantMap DesktopShortcutWriter::create(const QString &sourcePath, const QString &desktopDirectory)
{
    constexpr qint64 maximumDesktopFileSize = 1024 * 1024;
    const QFileInfo sourceInfo(sourcePath);
    if (!sourceInfo.exists() || !sourceInfo.isFile() || sourceInfo.isSymLink()
        || sourceInfo.canonicalFilePath().isEmpty() || sourceInfo.size() > maximumDesktopFileSize) {
        return result(QStringLiteral("invalid-source"));
    }

    QDir destinationDirectory(desktopDirectory);
    if (desktopDirectory.trimmed().isEmpty() || !destinationDirectory.mkpath(QStringLiteral("."))) {
        return result(QStringLiteral("desktop-unavailable"));
    }

    const QString canonicalDesktopDirectory = QFileInfo(destinationDirectory.absolutePath()).canonicalFilePath();
    if (canonicalDesktopDirectory.isEmpty()) {
        return result(QStringLiteral("desktop-unavailable"));
    }
    destinationDirectory.setPath(canonicalDesktopDirectory);

    const QString targetPath = destinationDirectory.filePath(sourceInfo.fileName());
    const QFileInfo targetInfo(targetPath);
    if (targetInfo.exists() || targetInfo.isSymLink()) {
        return result(QStringLiteral("already-exists"));
    }
    if (targetInfo.absolutePath() != canonicalDesktopDirectory) {
        return result(QStringLiteral("invalid-target"));
    }

    QFile sourceFile(sourceInfo.canonicalFilePath());
    if (!sourceFile.open(QIODevice::ReadOnly)) {
        return result(QStringLiteral("read-failed"));
    }

    QSaveFile destinationFile(targetPath);
    destinationFile.setDirectWriteFallback(false);
    if (!destinationFile.open(QIODevice::WriteOnly)) {
        return result(QStringLiteral("write-failed"));
    }

    const QByteArray contents = sourceFile.readAll();
    if (contents.size() != sourceInfo.size() || destinationFile.write(contents) != contents.size()) {
        destinationFile.cancelWriting();
        return result(QStringLiteral("write-failed"));
    }

    const QFileDevice::Permissions permissions = QFileDevice::ReadOwner | QFileDevice::WriteOwner
        | QFileDevice::ExeOwner | QFileDevice::ReadGroup | QFileDevice::ReadOther;
    if (!destinationFile.setPermissions(permissions)) {
        destinationFile.cancelWriting();
        return result(QStringLiteral("permissions-failed"));
    }
    if (!destinationFile.commit()) {
        return result(QStringLiteral("write-failed"));
    }

    return result(QStringLiteral("created"), true);
}
