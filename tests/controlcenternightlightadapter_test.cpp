// SPDX-License-Identifier: GPL-2.0-or-later

#include "controlcenternightlightadapter.h"

#include <QTest>

class ControlCenterNightLightAdapterTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void mapsTemperatureToStrength();
    void mapsStrengthToOfficialTemperatureSteps();
};

void ControlCenterNightLightAdapterTest::mapsTemperatureToStrength()
{
    QCOMPARE(ControlCenterNightLightAdapter::strengthForTemperature(6500), 0);
    QCOMPARE(ControlCenterNightLightAdapter::strengthForTemperature(4500), 36);
    QCOMPARE(ControlCenterNightLightAdapter::strengthForTemperature(1000), 100);
    QCOMPARE(ControlCenterNightLightAdapter::strengthForTemperature(7000), 0);
    QCOMPARE(ControlCenterNightLightAdapter::strengthForTemperature(500), 100);
}

void ControlCenterNightLightAdapterTest::mapsStrengthToOfficialTemperatureSteps()
{
    QCOMPARE(ControlCenterNightLightAdapter::temperatureForStrength(0), 6500);
    QCOMPARE(ControlCenterNightLightAdapter::temperatureForStrength(36), 4500);
    QCOMPARE(ControlCenterNightLightAdapter::temperatureForStrength(100), 1000);
    QCOMPARE(ControlCenterNightLightAdapter::temperatureForStrength(-10), 6500);
    QCOMPARE(ControlCenterNightLightAdapter::temperatureForStrength(110), 1000);
}

QTEST_GUILESS_MAIN(ControlCenterNightLightAdapterTest)

#include "controlcenternightlightadapter_test.moc"
