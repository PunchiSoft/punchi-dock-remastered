// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Window
import QtTest
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "../contents/ui/components"

TestCase {
    id: testCase
    name: "VerticalPopupAnchor"
    when: windowShown
    width: 600
    height: 600

    Item {
        id: launcherParent
        x: 80
        y: 200
        width: 80
        height: 400
        transform: Translate { id: launcherTranslation }
        readonly property real mappedGeometryRevision: launcherTranslation.y
        Item { id: launcher; x: 8; y: 20; width: 48; height: 48 }
    }
    GuardedPopupDialog {
        id: popup
        hideOnWindowDeactivate: false
        location: spacing.location
        mainItem: PopupAnimatedContent {
            id: animation
            popupVisible: popup.visible
            animationStyle: "none"
            ContextSurfaceStack {
                id: surface
                showMedia: false
                contentGeometryTransitionsEnabled: false
                drawContentBackground: folder.layoutMode !== "fan"
                edgeTailEnabled: folder.layoutMode !== "fan"
                integratedBalloonSurface: true
                edgeTailLocation: spacing.location
                constrainEdgeTailTip: !edgeTailHorizontal
                edgeTailTipOffset: !edgeTailHorizontal ? spacing.sourceCenterInTarget.y : NaN
                FolderPopup {
                    id: folder
                    folderItem: ({name: "Fixture", apps: [
                        {name: "One", icon: "folder"}, {name: "Two", icon: "folder"},
                        {name: "Three", icon: "folder"}, {name: "Four", icon: "folder"}
                    ]})
                    popupDirection: spacing.location === PlasmaCore.Types.LeftEdge
                        ? Qt.RightEdge : Qt.LeftEdge
                }
            }
        }
    }
    NativePopupSpacing {
        id: spacing
        sourceAnchor: launcher
        popup: popup
        targetSurface: surface
        targetTranslationX: animation.contentTranslationX
        targetTranslationY: animation.contentTranslationY
        preserveHorizontalAnchorCenter: true
        preserveVerticalAnchorCenter: true
        location: PlasmaCore.Types.LeftEdge
    }
    FolderPopupTail {
        id: constrainedTail
        width: 20
        height: 300
        location: Qt.LeftEdge
        constrainTip: true
        anchorExtent: 48
        frameInsetTop: 7
        frameInsetBottom: 11
    }

    function init() {
        nativePopupTestSupport.allowNativePopupPlatformWarnings()
        failOnWarning(/.?/)
        popup.closeSafely()
        spacing.sourceAnchor = launcher
        spacing.preserveVerticalAnchorCenter = true
        spacing.location = PlasmaCore.Types.LeftEdge
        spacing.gap = 0
        launcherParent.scale = 1
        launcherTranslation.y = 0
        folder.layoutMode = "grid"
        folder.profileScale = 1
        constrainedTail.tipOffset = NaN
        spacing.targetSurface = surface
    }
    function cleanup() { popup.closeSafely() }
    function placeLauncher(offset) {
        const globalX = spacing.location === PlasmaCore.Types.RightEdge
            ? testCase.Screen.virtualX + testCase.Screen.width - 160
            : testCase.Screen.virtualX + 160
        const point = launcherParent.mapFromGlobal(globalX,
            testCase.Screen.virtualY + testCase.Screen.height / 2 + offset)
        launcher.x = point.x - launcher.width / 2
        launcher.y = point.y - launcher.height / 2
        spacing.refreshAnchor()
    }
    function verifyAlignment() {
        tryVerify(function() {
            const center = launcher.mapToGlobal(launcher.width / 2, launcher.height / 2)
            return Math.abs(popup.y + popup.height / 2 - center.y) <= 2
        }, 2000, "Vertical popup must stay centered on its launcher, not the screen")
    }
    function test_verticalCenter_data() {
        const rows = []
        for (const edge of [PlasmaCore.Types.LeftEdge, PlasmaCore.Types.RightEdge]) {
            for (const view of ["grid", "list", "detailed", "fan"]) {
                for (const offset of [-50, 50]) {
                    rows.push({tag: edge + "-" + view + "-" + offset, edge: edge, view: view, offset: offset})
                }
            }
        }
        return rows
    }
    function test_verticalCenter(data) {
        spacing.location = data.edge
        folder.layoutMode = data.view
        placeLauncher(data.offset)
        popup.openSafely()
        tryCompare(popup, "visible", true)
        verifyAlignment()
        compare(popup.visualParent, spacing)
        const oldX = popup.x
        spacing.gap = 12
        tryCompare(popup, "x", oldX + (data.edge === PlasmaCore.Types.LeftEdge ? 12 : -12))
        verifyAlignment()
        launcher.y += 20
        verifyAlignment()
        folder.profileScale = 1.15
        verifyAlignment()
        folder.layoutMode = "list"
        verifyAlignment()
        if (surface.edgeTailPresent) {
            const mapped = launcher.mapToItem(surface, launcher.width / 2, launcher.height / 2)
            fuzzyCompare(surface.edgeTailTipOffset, mapped.y, 0.1)
            const renderedBalloon = findChild(surface, "integratedBalloonSurface")
            verify(renderedBalloon, "The integrated balloon must be present for the pointer check")
            fuzzyCompare(renderedBalloon.tailBaseScale * renderedBalloon.tailHeight * 2,
                Kirigami.Units.gridUnit * 2 * 0.55, 0.1)
            fuzzyCompare(renderedBalloon.y + renderedBalloon.pointerCenter, mapped.y, 0.1)
            const iconCenterGlobalY = launcher.mapToGlobal(
                launcher.width / 2, launcher.height / 2).y
            const pointerGlobalY = surface.mapToGlobal(0,
                renderedBalloon.y + renderedBalloon.pointerCenter).y
            verify(Math.abs(pointerGlobalY - iconCenterGlobalY) <= 1,
                "The drawn pointer must reach the launcher center in global screen coordinates")
        }
        popup.closeSafely()
        popup.openSafely()
        tryCompare(popup, "visible", true)
        verifyAlignment()
    }
    function test_nativeSnapControlAndProtection() {
        placeLauncher(15)
        spacing.preserveVerticalAnchorCenter = false
        spacing.refreshAnchor()
        popup.openSafely()
        tryCompare(popup, "visible", true)
        tryVerify(function() {
            const center = launcher.mapToGlobal(launcher.width / 2, launcher.height / 2).y
            return Math.abs(popup.y + popup.height / 2 - center) > 10
        }, 2000, "Unprotected popup must reproduce the screen-center snap")
        popup.closeSafely()
        spacing.preserveVerticalAnchorCenter = true
        spacing.refreshAnchor()
        popup.openSafely()
        tryCompare(popup, "visible", true)
        verifyAlignment()
    }
    function test_screenEdgeClamping_data() {
        const rows = []
        for (const edge of [PlasmaCore.Types.LeftEdge, PlasmaCore.Types.RightEdge]) {
            for (const view of ["grid", "list", "detailed"]) {
                for (const end of [-1, 1]) {
                    rows.push({tag: edge + "-" + view + "-" + end, edge: edge, view: view, end: end})
                }
            }
        }
        return rows
    }
    function test_screenEdgeClamping(data) {
        spacing.location = data.edge
        folder.layoutMode = data.view
        placeLauncher(data.end * (testCase.Screen.height / 2 - 20))
        popup.openSafely()
        tryCompare(popup, "visible", true)
        tryVerify(function() {
            return popup.y >= testCase.Screen.virtualY
                && popup.y + popup.height <= testCase.Screen.virtualY + testCase.Screen.height
        })
        verify(surface.edgeTailPresent)
        tryVerify(function() {
            const mapped = launcher.mapToItem(surface, launcher.width / 2, launcher.height / 2)
            return Math.abs(surface.edgeTailTipOffset - mapped.y) < 0.1
        })
        const renderedBalloon = findChild(surface, "integratedBalloonSurface")
        verify(renderedBalloon, "The integrated balloon must be present during screen clamping")
        const mappedCenterY = launcher.mapToItem(surface,
            launcher.width / 2, launcher.height / 2).y
        const minimumPointerY = renderedBalloon.radius + renderedBalloon.tailHeight
        const maximumPointerY = surface.height - minimumPointerY
        if (mappedCenterY >= minimumPointerY && mappedCenterY <= maximumPointerY) {
            const iconCenterGlobalY = launcher.mapToGlobal(
                launcher.width / 2, launcher.height / 2).y
            const pointerGlobalY = surface.mapToGlobal(0,
                renderedBalloon.y + renderedBalloon.pointerCenter).y
            verify(Math.abs(pointerGlobalY - iconCenterGlobalY) <= 1,
                "A clamped popup must still point at anchors within the safe tail range")
        }
        verify(surface.constrainEdgeTailTip)
        verify(data.end < 0 ? surface.edgeTailTipOffset < surface.height / 2
            : surface.edgeTailTipOffset > surface.height / 2)
    }
    function test_tailFollowsWindowAndTransformInsteadOfSurfaceCenter() {
        placeLauncher(50)
        launcherParent.scale = 1.25
        popup.openSafely()
        tryCompare(popup, "visible", true)
        verifyAlignment()
        wait(50)
        const previous = surface.edgeTailTipOffset
        popup.y += 40
        tryVerify(function() {
            const moved = launcher.mapToItem(surface, launcher.width / 2, launcher.height / 2)
            return Math.abs(surface.edgeTailTipOffset - moved.y) < 0.1
        })
        verify(Math.abs(surface.edgeTailTipOffset - previous) > 1,
            "The tail must react to the popup window's changed position")
        const renderedBalloon = findChild(surface, "integratedBalloonSurface")
        verify(renderedBalloon)
        tryVerify(function() {
            const iconCenterGlobalY = launcher.mapToGlobal(
                launcher.width / 2, launcher.height / 2).y
            const pointerGlobalY = surface.mapToGlobal(0,
                renderedBalloon.y + renderedBalloon.pointerCenter).y
            return Math.abs(pointerGlobalY - iconCenterGlobalY) <= 1
        }, 2000, "The drawn pointer must stay on the icon when the popup window moves")
        animation.transformSurfaceItem.scale = 0.85
        tryVerify(function() {
            const mapped = launcher.mapToItem(surface, launcher.width / 2, launcher.height / 2)
            return Math.abs(surface.edgeTailTipOffset - mapped.y) < 0.1
        })
        animation.transformSurfaceItem.scale = 1
        spacing.sourceAnchor = null
        tryCompare(popup, "visible", false)
        verify(isNaN(spacing.sourceCenterInTarget.y))
    }
    function test_capturedAnchorTracksLiveVerticalIconTransform() {
        placeLauncher(50)
        spacing.captureSourceGeometry()
        popup.openSafely()
        tryCompare(popup, "visible", true)
        verifyAlignment()

        const renderedBalloon = findChild(surface, "integratedBalloonSurface")
        verify(renderedBalloon)
        const previousGlobalY = launcher.mapToGlobal(
            launcher.width / 2, launcher.height / 2).y
        launcherTranslation.y += 24
        tryVerify(function() {
            const iconCenterGlobalY = launcher.mapToGlobal(
                launcher.width / 2, launcher.height / 2).y
            const pointerGlobalY = surface.mapToGlobal(0,
                renderedBalloon.y + renderedBalloon.pointerCenter).y
            return Math.abs(pointerGlobalY - iconCenterGlobalY) <= 1
                && Math.abs(iconCenterGlobalY - previousGlobalY) >= 20
        }, 2000, "The captured anchor must follow the live vertical icon transform")
    }
    function test_tailBaseDoesNotFollowIconMagnification() {
        placeLauncher(25)
        popup.openSafely()
        tryCompare(popup, "visible", true)
        const renderedBalloon = findChild(surface, "integratedBalloonSurface")
        verify(renderedBalloon)
        const initialBase = renderedBalloon.tailBaseScale
            * renderedBalloon.tailHeight * 2

        launcherParent.scale = 1.35
        tryVerify(function() {
            const iconCenterGlobalY = launcher.mapToGlobal(
                launcher.width / 2, launcher.height / 2).y
            const pointerGlobalY = surface.mapToGlobal(0,
                renderedBalloon.y + renderedBalloon.pointerCenter).y
            return Math.abs(pointerGlobalY - iconCenterGlobalY) <= 1
        })
        fuzzyCompare(renderedBalloon.tailBaseScale * renderedBalloon.tailHeight * 2,
            initialBase, 0.1)
        fuzzyCompare(initialBase, Kirigami.Units.gridUnit * 2 * 0.55, 0.1)
    }
    function test_tailStaysClearOfFrameEnds() {
        constrainedTail.tipOffset = -100
        verify(constrainedTail.tipPosition >= constrainedTail.frameInsetTop + constrainedTail.halfBase)
        constrainedTail.tipOffset = 500
        verify(constrainedTail.tipPosition <= constrainedTail.height - constrainedTail.frameInsetBottom - constrainedTail.halfBase)
        constrainedTail.tipOffset = 150
        compare(constrainedTail.tipPosition, 150)
        constrainedTail.tipOffset = NaN
        compare(constrainedTail.tipPosition, constrainedTail.height / 2)
    }
}
