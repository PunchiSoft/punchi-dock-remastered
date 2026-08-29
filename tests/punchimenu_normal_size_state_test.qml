// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtTest
import "../contents/ui/components/punchimenu" as PunchiMenu

TestCase {
    id: testCase

    name: "PunchiMenuNormalSizeState"
    when: windowShown

    PunchiMenu.PunchiMenuNormalSizeState {
        id: sizeState

        configuredWidthPercent: 55
        configuredHeightPercent: 65
        screenWidth: 1920
        screenHeight: 1080
        availableWidth: 1920
        availableHeight: 1040
        screenMargin: 36
        contentMargin: 12
        minimumContentWidth: 396
        minimumContentHeight: 288
    }

    function init() {
        failOnWarning(/.?/)
        sizeState.configuredWidthPercent = 55
        sizeState.configuredHeightPercent = 65
        sizeState.screenWidth = 1920
        sizeState.screenHeight = 1080
        sizeState.availableWidth = 1920
        sizeState.availableHeight = 1040
        sizeState.screenMargin = 36
        sizeState.contentMargin = 12
        sizeState.minimumContentWidth = 396
        sizeState.minimumContentHeight = 288
        sizeState.applyConfiguredDimensions()
    }

    function test_usesActiveMonitorInsteadOfVirtualDesktopWidth() {
        compare(sizeState.appliedContentWidth, 1056)
        compare(sizeState.appliedContentHeight, 702)
        verify(sizeState.appliedContentWidth < 1920)
    }

    function test_configurationChangesRemainDeferredUntilReopen() {
        const openedWidth = sizeState.appliedContentWidth
        const openedHeight = sizeState.appliedContentHeight

        sizeState.configuredWidthPercent = 90
        sizeState.configuredHeightPercent = 90

        compare(sizeState.appliedContentWidth, openedWidth)
        compare(sizeState.appliedContentHeight, openedHeight)

        sizeState.applyConfiguredDimensions()
        compare(sizeState.appliedContentWidth, 1728)
        compare(sizeState.appliedContentHeight, 972)
    }

    function test_availableAreaCapsContentAndMinimums() {
        sizeState.configuredWidthPercent = 90
        sizeState.screenWidth = 1920
        sizeState.availableWidth = 900
        sizeState.applyConfiguredDimensions()
        compare(sizeState.appliedContentWidth, 840)

        sizeState.screenWidth = 300
        sizeState.availableWidth = 280
        sizeState.applyConfiguredDimensions()
        compare(sizeState.appliedContentWidth, 220)
    }

    function test_screenChangesRemainDeferredUntilReopen() {
        const openedWidth = sizeState.appliedContentWidth
        sizeState.screenWidth = 2560
        sizeState.availableWidth = 2560
        compare(sizeState.appliedContentWidth, openedWidth)

        sizeState.applyConfiguredDimensions()
        compare(sizeState.appliedContentWidth, 1408)
    }
}
