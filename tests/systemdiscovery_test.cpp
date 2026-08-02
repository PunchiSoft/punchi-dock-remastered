// SPDX-License-Identifier: GPL-2.0-or-later

#include "systemdiscovery.h"

#include <QCoreApplication>
#include <QDebug>
#include <QSet>
#include <QVariantList>
#include <QVariantMap>

#include <cstdlib>

namespace
{
bool validateApplications(const QVariantList &applications)
{
    if (applications.size() > 80) {
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

    QObject::connect(&discovery, &SystemDiscovery::applicationsReady,
                     [&passed, &applicationResponseCount](const QVariantList &applications) {
        ++applicationResponseCount;
        passed = validateApplications(applications) && passed;
    });

    const QStringList categories = {
        QString(),
        QStringLiteral("Network"),
        QStringLiteral("AudioVideo"),
        QStringLiteral("Development"),
        QStringLiteral("Game"),
    };
    for (const QString &category : categories) {
        discovery.requestApplications(category);
    }
    if (applicationResponseCount != categories.size()) {
        qCritical() << "Application discovery did not answer every request:"
                    << applicationResponseCount << "of" << categories.size();
        passed = false;
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

    return passed ? EXIT_SUCCESS : EXIT_FAILURE;
}
