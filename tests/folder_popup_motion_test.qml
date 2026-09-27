// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase

    name: "FolderPopupMotion"
    when: windowShown
    width: 640
    height: 480

    Components.FolderPopup {
        id: folderPopup
        anchors.centerIn: parent
        animationStyle: "scale"
        animationIntensityPercent: 100
        popupDirection: Qt.BottomEdge
        revealProgress: 1
        folderItem: ({
            name: "Test folder",
            apps: [
                {name: "One", icon: "folder", command: "one"},
                {name: "Two", icon: "folder", command: "two"},
                {name: "Three", icon: "folder", command: "three"}
            ]
        })
    }

    function delegateAt(index) {
        let delegate = null
        tryVerify(function() {
            delegate = findChild(folderPopup,
                "folderPopupDelegate-" + index)
            return delegate !== null
        })
        return delegate
    }

    function fuzzyCompare(actual, expected, message) {
        verify(Math.abs(actual - expected) < 0.001,
            message + ": actual=" + actual + " expected=" + expected)
    }

    function init() {
        failOnWarning(/.?/)
        folderPopup.folderItem = ({
            name: "Test folder",
            apps: [
                {name: "One", icon: "folder", command: "one"},
                {name: "Two", icon: "folder", command: "two"},
                {name: "Three", icon: "folder", command: "three"}
            ]
        })
        folderPopup.layoutMode = "grid"
        folderPopup.animationStyle = "scale"
        folderPopup.animationIntensityPercent = 100
        folderPopup.popupDirection = Qt.BottomEdge
        folderPopup.revealProgress = 1
        folderPopup.profileShowLabels = true
        wait(0)
    }

    function test_noneAlwaysUsesTheSettledState() {
        folderPopup.animationStyle = "none"
        folderPopup.revealProgress = 0
        const delegate = delegateAt(0)

        compare(folderPopup.revealMotionEnabled, false)
        compare(delegate.opacity, 1)
        compare(delegate.scale, 1)
        compare(delegate.revealOffsetX, 0)
        compare(delegate.revealOffsetY, 0)
    }

    function test_gridUsesSubtleScaleWithoutRowTranslation() {
        if (!folderPopup.motionEnabled) {
            skip("The active Plasma animation preference disables motion")
        }
        folderPopup.layoutMode = "grid"
        folderPopup.animationStyle = "scale"
        folderPopup.revealProgress = 0
        const gridView = findChild(folderPopup, "folderPopupGridView")
        verify(gridView !== null)
        compare(gridView.count, 3)
        verify(gridView.height > 0)
        const delegate = delegateAt(0)

        compare(delegate.opacity, 1)
        fuzzyCompare(delegate.scale, 0.96,
            "Grid reveal must use the subtle configured scale")
        compare(delegate.revealOffsetX, 0)
        compare(delegate.revealOffsetY, 0)

        folderPopup.revealProgress = 1
        fuzzyCompare(delegate.scale, 1,
            "Grid reveal must reach the settled scale")
    }

    function test_listAndDetailedKeepTextAtNativeScale() {
        if (!folderPopup.motionEnabled) {
            skip("The active Plasma animation preference disables motion")
        }
        const modes = ["list", "detailed"]
        for (let index = 0; index < modes.length; index++) {
            folderPopup.layoutMode = modes[index]
            folderPopup.animationStyle = "scale"
            folderPopup.revealProgress = 0
            wait(0)
            const delegate = delegateAt(0)

            compare(delegate.scale, 1,
                modes[index] + " must not scale text during reveal")
            fuzzyCompare(delegate.opacity, 0.72,
                modes[index] + " must use a restrained opacity reveal")
        }
    }

    function test_slideFollowsThePopupEdge() {
        if (!folderPopup.motionEnabled) {
            skip("The active Plasma animation preference disables motion")
        }
        folderPopup.layoutMode = "list"
        folderPopup.animationStyle = "slide"
        folderPopup.revealProgress = 0
        const delegate = delegateAt(0)

        compare(delegate.revealOffsetX, 0)
        compare(delegate.revealOffsetY, -folderPopup.revealDistance)

        folderPopup.popupDirection = Qt.LeftEdge
        compare(delegate.revealOffsetX, folderPopup.revealDistance)
        compare(delegate.revealOffsetY, 0)

        folderPopup.revealProgress = 1
        compare(delegate.revealOffsetX, 0)
        compare(delegate.revealOffsetY, 0)
    }

    function test_modelAndModeCanBeRecreated() {
        folderPopup.folderItem = ({name: "Empty", apps: []})
        wait(0)
        verify(findChild(folderPopup, "folderPopupDelegate-0") === null)

        folderPopup.layoutMode = "detailed"
        folderPopup.folderItem = ({
            name: "Recreated",
            apps: [{name: "Restored", icon: "folder", command: "restored"}]
        })
        const delegate = delegateAt(0)
        verify(delegate !== null)
        compare(delegate.scale, 1)
    }

    function test_fanUsesTheDedicatedScrollableView() {
        folderPopup.layoutMode = "fan"
        folderPopup.revealProgress = 0
        wait(0)

        const fanView = findChild(folderPopup, "folderFanView")
        verify(fanView !== null)
        const fanDelegate = findChild(folderPopup, "folderFanDelegate-0")
        verify(fanDelegate !== null)
        const fanContent = findChild(folderPopup,
            "folderFanRowContent-0")
        verify(fanContent !== null)
        if (folderPopup.motionEnabled) {
            // The fan unfolds from the dock icon: a light opacity and a light
            // scale support the travel and both settle exactly on the plain
            // interactive appearance, so text is never left scaled.
            verify(fanDelegate.opacity > 0.5 && fanDelegate.opacity < 1,
                "Fan reveal must start from a readable opacity")
            verify(fanContent.scale >= 0.88 && fanContent.scale < 1,
                "Fan reveal must start from a light scale, never from zero")

            folderPopup.revealProgress = 1
            wait(0)
            fuzzyCompare(fanDelegate.opacity, 1,
                "A settled fan item must be fully opaque")
            fuzzyCompare(fanContent.scale, 1,
                "A settled fan item must keep native text scale")
        } else {
            compare(fanDelegate.opacity, 1)
            compare(fanContent.scale, 1)
        }
    }

    function test_fanWithoutLabelsCollapsesUnusedWidth() {
        folderPopup.layoutMode = "fan"
        folderPopup.profileShowLabels = true
        const labelledWidth = folderPopup.implicitWidth

        folderPopup.profileShowLabels = false
        verify(folderPopup.implicitWidth < labelledWidth)
        verify(folderPopup.implicitWidth
            >= folderPopup.effectiveIconSize + folderPopup.classicMargin * 2)
    }

    function test_fanRemovesDialogChromeAndKeepsTheVisualOrigin() {
        folderPopup.layoutMode = "fan"
        folderPopup.showHeaderLabel = true
        wait(0)

        compare(folderPopup.effectiveShowHeaderLabel, false)
        verify(folderPopup.fanOriginIconCenterX
            > folderPopup.implicitWidth / 2)
    }
}
