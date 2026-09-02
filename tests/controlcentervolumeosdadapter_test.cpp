// SPDX-License-Identifier: GPL-2.0-or-later

#include "controlcentervolumeosdadapter.h"

#include <KConfigGroup>

#include <QSignalSpy>
#include <QTemporaryDir>
#include <QTest>

class ControlCenterVolumeOsdAdapterTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void defaultsToVisible();
    void togglesOnlyVolumeOsd();
    void refreshesExternalChanges();
};

void ControlCenterVolumeOsdAdapterTest::defaultsToVisible()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());
    const auto config = KSharedConfig::openConfig(
        directory.filePath(QStringLiteral("plasmaparc")), KConfig::SimpleConfig);

    ControlCenterVolumeOsdAdapter adapter(config);

    QVERIFY(adapter.osdVisible());
    QVERIFY(adapter.writable());
}

void ControlCenterVolumeOsdAdapterTest::togglesOnlyVolumeOsd()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());
    const auto config = KSharedConfig::openConfig(
        directory.filePath(QStringLiteral("plasmaparc")), KConfig::SimpleConfig);
    KConfigGroup group(config, QStringLiteral("General"));
    group.writeEntry("MuteOsd", true);
    QVERIFY(group.sync());

    ControlCenterVolumeOsdAdapter adapter(config);
    QSignalSpy stateSpy(&adapter, &ControlCenterVolumeOsdAdapter::stateChanged);

    QVERIFY(adapter.toggleOsd());
    QVERIFY(!adapter.osdVisible());
    QCOMPARE(stateSpy.count(), 1);

    config->reparseConfiguration();
    const KConfigGroup persistedGroup(config, QStringLiteral("General"));
    QCOMPARE(persistedGroup.readEntry("VolumeOsd", true), false);
    QCOMPARE(persistedGroup.readEntry("MuteOsd", false), true);
}

void ControlCenterVolumeOsdAdapterTest::refreshesExternalChanges()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());
    const QString configPath = directory.filePath(QStringLiteral("plasmaparc"));
    const auto config = KSharedConfig::openConfig(configPath, KConfig::SimpleConfig);
    ControlCenterVolumeOsdAdapter adapter(config);
    QSignalSpy stateSpy(&adapter, &ControlCenterVolumeOsdAdapter::stateChanged);

    const auto externalConfig = KSharedConfig::openConfig(configPath, KConfig::SimpleConfig);
    KConfigGroup externalGroup(externalConfig, QStringLiteral("General"));
    externalGroup.writeEntry("VolumeOsd", false, KConfig::Notify);
    QVERIFY(externalGroup.sync());

    adapter.refresh();

    QVERIFY(!adapter.osdVisible());
    QCOMPARE(stateSpy.count(), 1);
}

QTEST_GUILESS_MAIN(ControlCenterVolumeOsdAdapterTest)

#include "controlcentervolumeosdadapter_test.moc"
