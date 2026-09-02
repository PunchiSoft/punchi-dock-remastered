// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtTest
import "../contents/ui/components/controlcenter/ControlCenterLayoutMetrics.js" as LayoutMetrics
import "../contents/ui/components/controlcenter" as ControlCenter

TestCase {
    id: testCase

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

    Component {
        id: floatingGeometryComponent

        ControlCenter.ControlCenterFloatingGeometry {}
    }

    function test_floatingGeometryMatchesFullscreenRail() {
        const geometry = createTemporaryObject(
            floatingGeometryComponent, testCase, {
                "screenGeometry": Qt.rect(0, 0, 1920, 1080),
                "availableScreenRect": Qt.rect(0, 0, 1920, 1080),
                "gridUnit": 18
            })
        verify(geometry !== null)
        compare(geometry.contentWidth, 640)
        compare(geometry.contentHeight, 972)
        compare(geometry.positionFor(
            geometry.contentWidth, geometry.contentHeight),
            Qt.point(1226, 54))
    }

    function test_floatingGeometryUsesActiveScreenAndAvailableArea() {
        const geometry = createTemporaryObject(
            floatingGeometryComponent, testCase, {
                "screenGeometry": Qt.rect(1920, 0, 2560, 1440),
                "availableScreenRect": Qt.rect(0, 40, 2560, 1400),
                "gridUnit": 18
            })
        verify(geometry !== null)
        compare(geometry.contentWidth, 756)
        compare(geometry.contentHeight, 1292)
        compare(geometry.positionFor(
            geometry.contentWidth, geometry.contentHeight),
            Qt.point(3670, 94))
    }

    function test_floatingGeometryShrinksOnlyWhenNecessary() {
        const geometry = createTemporaryObject(
            floatingGeometryComponent, testCase, {
                "screenGeometry": Qt.rect(0, 0, 500, 640),
                "availableScreenRect": Qt.rect(0, 0, 500, 640),
                "gridUnit": 18
            })
        verify(geometry !== null)
        compare(geometry.contentWidth, 392)
        compare(geometry.contentHeight, 532)
        compare(geometry.positionFor(
            geometry.contentWidth, geometry.contentHeight),
            Qt.point(54, 54))
    }
}
