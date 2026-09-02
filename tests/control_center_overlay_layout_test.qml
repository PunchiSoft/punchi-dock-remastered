// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtTest
import "../contents/ui/components/controlcenter/ControlCenterLayoutMetrics.js" as LayoutMetrics

TestCase {
    name: "ControlCenterOverlayLayout"

    function init() {
        failOnWarning(/.?/)
    }

    function test_availableGeometryUsesKUnits() {
        const gridUnit = 18
        compare(LayoutMetrics.edgeMargin(gridUnit), 54)
        compare(LayoutMetrics.minimumRailWidth(gridUnit), 540)
        compare(LayoutMetrics.maximumRailWidth(gridUnit), 756)
        compare(LayoutMetrics.targetRailWidth(1920), 640)
        compare(LayoutMetrics.availableWidth(1920, gridUnit), 640)
        compare(LayoutMetrics.availableWidth(1440, gridUnit), 540)
        compare(LayoutMetrics.availableHeight(900, gridUnit), 792)

        compare(LayoutMetrics.availableWidth(760, gridUnit), 540)
        compare(LayoutMetrics.availableWidth(500, gridUnit), 392)
        compare(LayoutMetrics.availableHeight(640, gridUnit), 532)
        compare(LayoutMetrics.availableWidth(80, gridUnit), 0)
        compare(LayoutMetrics.availableHeight(80, gridUnit), 0)
    }
}
