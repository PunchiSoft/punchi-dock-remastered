// SPDX-License-Identifier: GPL-2.0-or-later

#include "systemdiscovery.h"
#include "desktoplauncherresolver.h"

#include <KOSRelease>

#include <QCoreApplication>
#include <QDebug>
#include <QFile>
#include <QFileInfo>
#include <QSet>
#include <QTemporaryDir>
#include <QVariantList>
#include <QVariantMap>

#include <cstdlib>
#include <iostream>
#include <unistd.h>

namespace
{
bool writeFile(const QString &path, const QByteArray &contents, bool executable = false)
{
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly) || file.write(contents) != contents.size()) {
        return false;
    }
    file.close();

    if (!executable) {
        return true;
    }
    return QFile::setPermissions(path, QFileDevice::ReadOwner | QFileDevice::WriteOwner
            | QFileDevice::ExeOwner | QFileDevice::ReadGroup | QFileDevice::ReadOther);
}

bool createSymbolicLink(const QString &target, const QString &linkPath)
{
    const QByteArray encodedTarget = QFile::encodeName(target);
    const QByteArray encodedLinkPath = QFile::encodeName(linkPath);
    return ::symlink(encodedTarget.constData(), encodedLinkPath.constData()) == 0;
}

bool validateFolderDesktopLaunchers()
{
    QTemporaryDir directory;
    if (!directory.isValid()) {
        std::cerr << "Could not create the folder launcher test directory.\n";
        return false;
    }

    const QByteArray desktopContents = QByteArrayLiteral(
        "[Desktop Entry]\n"
        "Type=Application\n"
        "Name=Punchi Folder Launcher\n"
        "Icon=system-run\n"
        "Exec=/bin/true\n"
        "TryExec=/bin/true\n");
    const QString launcherPath = directory.filePath(QStringLiteral("custom.desktop"));
    const QString absoluteLinkPath = directory.filePath(QStringLiteral("absolute.desktop"));
    const QString relativeLinkPath = directory.filePath(QStringLiteral("relative.desktop"));
    const QString chainedLinkPath = directory.filePath(QStringLiteral("chained.desktop"));
    const QString brokenLinkPath = directory.filePath(QStringLiteral("broken.desktop"));
    const QString textPath = directory.filePath(QStringLiteral("document.txt"));
    const QString textLinkPath = directory.filePath(QStringLiteral("document-link.desktop"));
    const QString untrustedPath = directory.filePath(QStringLiteral("untrusted.desktop"));

    if (!writeFile(launcherPath, desktopContents, true)
        || !createSymbolicLink(launcherPath, absoluteLinkPath)
        || !createSymbolicLink(QStringLiteral("custom.desktop"), relativeLinkPath)
        || !createSymbolicLink(QStringLiteral("relative.desktop"), chainedLinkPath)
        || !createSymbolicLink(QStringLiteral("missing.desktop"), brokenLinkPath)
        || !writeFile(textPath, QByteArrayLiteral("not a launcher\n"))
        || !createSymbolicLink(textPath, textLinkPath)
        || !writeFile(untrustedPath, desktopContents)) {
        std::cerr << "Could not create the folder launcher test fixtures.\n";
        return false;
    }

    const QStringList validLaunchers = {
        launcherPath,
        absoluteLinkPath,
        relativeLinkPath,
        chainedLinkPath,
    };
    for (const QString &path : validLaunchers) {
        const DesktopLauncherResolver::Resolution launcher
            = DesktopLauncherResolver::resolveLocalFile(path);
        if (!launcher || launcher.service->name() != QLatin1String("Punchi Folder Launcher")
            || launcher.service->icon() != QLatin1String("system-run")
            || launcher.canonicalPath != QFileInfo(launcherPath).canonicalFilePath()) {
            std::cerr << "A valid desktop launcher was not resolved: "
                      << path.toStdString() << '\n';
            return false;
        }
    }

    const QStringList rejectedLaunchers = {
        brokenLinkPath,
        textLinkPath,
        untrustedPath,
        QStringLiteral("https://example.invalid/remote.desktop"),
    };
    for (const QString &path : rejectedLaunchers) {
        if (DesktopLauncherResolver::resolveLocalFile(path)) {
            std::cerr << "An unsafe desktop launcher was accepted: "
                      << path.toStdString() << '\n';
            return false;
        }
    }

    return true;
}

bool validateApplications(const QVariantList &applications, qsizetype maximumCount)
{
    if (applications.size() > maximumCount) {
        qCritical() << "Application discovery exceeded its result limit:" << applications.size();
        return false;
    }

    QSet<QString> storageIds;
    for (const QVariant &application : applications) {
        const QVariantMap values = application.toMap();
        const QString storageId = values.value(QStringLiteral("storageId")).toString();
        const QString name = values.value(QStringLiteral("name")).toString();
        if (storageId.isEmpty() || name.isEmpty()) {
            qCritical() << "Application discovery returned an incomplete entry:" << values;
            return false;
        }
        if (storageIds.contains(storageId)) {
            qCritical() << "Application discovery returned a duplicate storage ID:" << storageId;
            return false;
        }
        storageIds.insert(storageId);
    }

    return true;
}
}

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    SystemDiscovery discovery;
    bool passed = true;
    int applicationResponseCount = 0;
    int catalogResponseCount = 0;
    QVariantList lastApplicationResponse;
    QVariantList genericAllApplications;
    QVariantList catalogApplications;

    if (discovery.distributionName().trimmed().isEmpty()) {
        qCritical() << "System discovery did not expose the distribution name.";
        passed = false;
    }
    if (discovery.distributionLogo() != KOSRelease().logo().trimmed()) {
        qCritical() << "System discovery did not expose the distribution logo.";
        passed = false;
    }
    passed = validateFolderDesktopLaunchers() && passed;

    QObject::connect(&discovery, &SystemDiscovery::applicationsReady,
                     [&passed, &applicationResponseCount, &lastApplicationResponse](const QVariantList &applications) {
        ++applicationResponseCount;
        lastApplicationResponse = applications;
        passed = validateApplications(applications, 80) && passed;
    });
    QObject::connect(&discovery, &SystemDiscovery::applicationCatalogReady,
                     [&passed, &catalogResponseCount, &catalogApplications](const QVariantList &applications) {
        ++catalogResponseCount;
        catalogApplications = applications;
        passed = validateApplications(applications, 1024) && passed;
    });

    const QStringList categories = {
        QString(),
        QStringLiteral("All"),
        QStringLiteral("Network"),
        QStringLiteral("AudioVideo"),
        QStringLiteral("Development"),
        QStringLiteral("Game"),
    };
    for (const QString &category : categories) {
        discovery.requestApplications(category);
        if (category == QLatin1String("All")) {
            genericAllApplications = lastApplicationResponse;
        }
    }
    if (applicationResponseCount != categories.size()) {
        qCritical() << "Application discovery did not answer every request:"
                    << applicationResponseCount << "of" << categories.size();
        passed = false;
    }
    if (catalogResponseCount != 0) {
        qCritical() << "A generic request unexpectedly emitted the PunchiMenu catalog signal.";
        passed = false;
    }

    const int genericCountBeforeCatalog = applicationResponseCount;
    discovery.requestApplicationCatalog();
    if (catalogResponseCount != 1 || applicationResponseCount != genericCountBeforeCatalog) {
        qCritical() << "The PunchiMenu catalog request did not use its dedicated signal.";
        passed = false;
    }

    QSet<QString> catalogStorageIds;
    for (const QVariant &application : catalogApplications) {
        catalogStorageIds.insert(application.toMap()
            .value(QStringLiteral("storageId")).toString());
    }
    for (const QVariant &application : genericAllApplications) {
        const QString storageId = application.toMap()
            .value(QStringLiteral("storageId")).toString();
        if (!catalogStorageIds.contains(storageId)) {
            qCritical() << "The complete catalog omitted a generic application:" << storageId;
            passed = false;
        }
    }

    bool launchFinished = false;
    bool launchFailed = false;
    bool operationFailed = false;
    QObject::connect(&discovery, &SystemDiscovery::applicationLaunchFinished,
                     [&launchFinished, &launchFailed](bool succeeded, const QString &message) {
        launchFinished = true;
        launchFailed = !succeeded && !message.isEmpty();
    });
    QObject::connect(&discovery, &SystemDiscovery::operationFailed,
                     [&operationFailed](const QString &operation, const QString &message) {
        operationFailed = operation == QStringLiteral("launch") && !message.isEmpty();
    });

    discovery.launchApplication(QStringLiteral("org.punchi.missing-application-8f2c9e7d.desktop"));
    if (!launchFinished || !launchFailed || !operationFailed) {
        qCritical() << "A missing application did not report a complete launch failure.";
        passed = false;
    }

    const QVariantMap invalidResolution = discovery.resolveApplication({}, {}, {});
    if (invalidResolution.value(QStringLiteral("status")).toString() != QLatin1String("invalid")
        || invalidResolution.value(QStringLiteral("resolved")).toBool()) {
        qCritical() << "An empty application identity was not rejected.";
        passed = false;
    }

    const QVariantMap missingResolution = discovery.resolveApplication(
        QStringLiteral("org.punchi.missing-application-8f2c9e7d.desktop"), {}, {});
    if (missingResolution.value(QStringLiteral("status")).toString() != QLatin1String("not-found")
        || missingResolution.value(QStringLiteral("resolved")).toBool()) {
        qCritical() << "A missing application identity was not reported deterministically.";
        passed = false;
    }

    return passed ? EXIT_SUCCESS : EXIT_FAILURE;
}
