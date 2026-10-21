// SPDX-License-Identifier: GPL-3.0-or-later

#include "recentapplicationsadapter.h"

#include <KConfig>
#include <KConfigGroup>
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QSignalSpy>
#include <QStandardPaths>
#include <QTest>

namespace {
constexpr auto ScoringGroup = "Plugin-org.kde.ActivityManager.Resources.Scoring";
constexpr auto WhatToRemember = "what-to-remember";
constexpr auto AllowedApplications = "allowed-applications";
constexpr auto BlockedApplications = "blocked-applications";

QString configurationPath()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)
        + QStringLiteral("/kactivitymanagerd-pluginsrc");
}

QString configurationValue(const QString &key)
{
    const KConfig config(QStringLiteral("kactivitymanagerd-pluginsrc"));
    const KConfigGroup group(&config, QString::fromLatin1(ScoringGroup));
    return group.readEntry(key, QString());
}

void writeConfiguration(const QString &whatToRemember)
{
    QFile file(configurationPath());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        return;
    }
    const QByteArray content = QByteArrayLiteral("[") + ScoringGroup + QByteArrayLiteral("]\n")
        + WhatToRemember + QByteArrayLiteral("=") + whatToRemember.toUtf8() + QByteArrayLiteral("\n")
        + AllowedApplications + QByteArrayLiteral("=org.example.Allowed.desktop\n")
        + BlockedApplications + QByteArrayLiteral("=org.example.Blocked.desktop\n");
    file.write(content);
    file.close();
}
}

class RecentApplicationsTrackingTest : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void init()
    {
        QTest::failOnWarning();
        QFile::remove(configurationPath());
    }
    void trackingDefaultsToEnabledWithoutConfigurationFile()
    {
        RecentApplicationsAdapter adapter;
        QCOMPARE(adapter.trackingEnabled(), true);
    }
    void trackingReadsTheNoApplicationsState()
    {
        writeConfiguration(QStringLiteral("2"));
        RecentApplicationsAdapter adapter;
        QCOMPARE(adapter.trackingEnabled(), false);
    }
    void trackingWritesBothPublicStatesAndKeepsApplicationLists()
    {
        writeConfiguration(QStringLiteral("1"));
        RecentApplicationsAdapter adapter;
        // KDE's middle state (specific applications) reads as enabled; the
        // first gesture publishes one of the two supported states.
        QCOMPARE(adapter.trackingEnabled(), true);
        QSignalSpy changed(&adapter, &RecentApplicationsAdapter::trackingEnabledChanged);

        QVERIFY(adapter.setTrackingEnabled(false));
        QCOMPARE(adapter.trackingEnabled(), false);
        QCOMPARE(changed.count(), 1);
        QCOMPARE(configurationValue(QString::fromLatin1(WhatToRemember)), QStringLiteral("2"));
        QCOMPARE(configurationValue(QString::fromLatin1(AllowedApplications)), QStringLiteral("org.example.Allowed.desktop"));
        QCOMPARE(configurationValue(QString::fromLatin1(BlockedApplications)), QStringLiteral("org.example.Blocked.desktop"));

        QVERIFY(adapter.setTrackingEnabled(true));
        QCOMPARE(adapter.trackingEnabled(), true);
        QCOMPARE(changed.count(), 2);
        QCOMPARE(configurationValue(QString::fromLatin1(WhatToRemember)), QStringLiteral("0"));
        QCOMPARE(configurationValue(QString::fromLatin1(AllowedApplications)), QStringLiteral("org.example.Allowed.desktop"));
        QCOMPARE(configurationValue(QString::fromLatin1(BlockedApplications)), QStringLiteral("org.example.Blocked.desktop"));
    }
    void trackingFollowsExternalRewrite()
    {
        writeConfiguration(QStringLiteral("0"));
        RecentApplicationsAdapter adapter;
        QCOMPARE(adapter.trackingEnabled(), true);
        QSignalSpy changed(&adapter, &RecentApplicationsAdapter::trackingEnabledChanged);

        writeConfiguration(QStringLiteral("2"));
        QTRY_COMPARE_WITH_TIMEOUT(adapter.trackingEnabled(), false, 5000);
        QCOMPARE(changed.count(), 1);
    }
};

int main(int argc, char **argv)
{
    const QString root = QFile::decodeName(qgetenv("PUNCHI_TEST_ENVIRONMENT_ROOT"));
    if (root.isEmpty() || !QDir(root).exists()) {
        return 1;
    }
    for (const auto &variable : {"XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME", "XDG_RUNTIME_DIR"}) {
        const QString path = root + QLatin1Char('/') + QString::fromLatin1(variable);
        if (!QDir().mkpath(path)) {
            return 1;
        }
        if (!QFile::setPermissions(path, QFile::ReadOwner | QFile::WriteOwner | QFile::ExeOwner)) {
            return 1;
        }
        qputenv(variable, QFile::encodeName(path));
    }
    qputenv("XDG_DATA_DIRS", QFile::encodeName(root + QStringLiteral("/XDG_DATA_HOME")));
    qputenv("XDG_CONFIG_DIRS", QFile::encodeName(root + QStringLiteral("/XDG_CONFIG_HOME")));
    QCoreApplication application(argc, argv);
    RecentApplicationsTrackingTest test;
    return QTest::qExec(&test, argc, argv);
}

#include "recentapplications_tracking_test.moc"
