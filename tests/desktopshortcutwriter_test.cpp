// SPDX-License-Identifier: GPL-2.0-or-later

#include "desktopshortcutwriter.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTemporaryDir>

#include <cstdlib>

namespace
{
bool writeFile(const QString &path, const QByteArray &contents)
{
    QFile file(path);
    return file.open(QIODevice::WriteOnly) && file.write(contents) == contents.size();
}

bool expectStatus(const QVariantMap &result, const QString &status, bool success)
{
    return result.value(QStringLiteral("status")).toString() == status
        && result.value(QStringLiteral("success")).toBool() == success;
}
}

int main()
{
    QTemporaryDir temporaryDirectory;
    if (!temporaryDirectory.isValid()) {
        return EXIT_FAILURE;
    }

    const QString sourceDirectory = temporaryDirectory.filePath(QStringLiteral("applications"));
    const QString desktopDirectory = temporaryDirectory.filePath(QStringLiteral("Desktop"));
    if (!QDir().mkpath(sourceDirectory)) {
        return EXIT_FAILURE;
    }

    const QByteArray desktopContents = QByteArrayLiteral(
        "[Desktop Entry]\nType=Application\nName=Punchi Test\nExec=true\n");
    const QString sourcePath = QDir(sourceDirectory).filePath(QStringLiteral("org.punchi.test.desktop"));
    if (!writeFile(sourcePath, desktopContents)) {
        return EXIT_FAILURE;
    }

    const QVariantMap created = DesktopShortcutWriter::create(sourcePath, desktopDirectory);
    if (!expectStatus(created, QStringLiteral("created"), true)) {
        return EXIT_FAILURE;
    }

    const QString targetPath = QDir(desktopDirectory).filePath(QFileInfo(sourcePath).fileName());
    QFile targetFile(targetPath);
    if (!targetFile.open(QIODevice::ReadOnly) || targetFile.readAll() != desktopContents) {
        return EXIT_FAILURE;
    }
    const QFileDevice::Permissions permissions = QFileInfo(targetPath).permissions();
    if (!(permissions & QFileDevice::ExeOwner) || (permissions & QFileDevice::ExeGroup)
        || (permissions & QFileDevice::ExeOther)) {
        return EXIT_FAILURE;
    }

    const QVariantMap collision = DesktopShortcutWriter::create(sourcePath, desktopDirectory);
    if (!expectStatus(collision, QStringLiteral("already-exists"), false)) {
        return EXIT_FAILURE;
    }
    targetFile.close();
    if (!targetFile.open(QIODevice::ReadOnly) || targetFile.readAll() != desktopContents) {
        return EXIT_FAILURE;
    }

    const QVariantMap missing = DesktopShortcutWriter::create(
        QDir(sourceDirectory).filePath(QStringLiteral("missing.desktop")), desktopDirectory);
    if (!expectStatus(missing, QStringLiteral("invalid-source"), false)) {
        return EXIT_FAILURE;
    }

    const QString linkedSource = QDir(sourceDirectory).filePath(QStringLiteral("linked.desktop"));
    if (QFile::link(sourcePath, linkedSource)) {
        const QVariantMap linked = DesktopShortcutWriter::create(linkedSource, desktopDirectory);
        if (!expectStatus(linked, QStringLiteral("invalid-source"), false)) {
            return EXIT_FAILURE;
        }
    }

    return EXIT_SUCCESS;
}
