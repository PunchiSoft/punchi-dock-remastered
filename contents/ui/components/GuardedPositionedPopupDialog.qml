import QtQuick
import org.kde.plasma.core as PlasmaCore
import "punchimenu"

GuardedPopupDialog {
    id: root

    property Item placementAnchor: null
    property bool inPanel: false
    property int panelLocation: PlasmaCore.Types.BottomEdge
    property rect availableScreenRect: Qt.rect(0, 0, 1, 1)
    property rect screenGeometry: Qt.rect(0, 0, 1, 1)
    property var floatingDockAnchor: null
    property var panelWindow: null
    property real panelThickness: 0
    property int popupGap: 0
    property var surfaceFrame: null
    property var floatingDockSurfaceFrame: null
    readonly property rect effectivePopupGeometry:
        root.popupEffectiveWindowRect()

    readonly property PunchiMenuNormalPlacement placementController:
        PunchiMenuNormalPlacement {
            inPanel: root.inPanel
            placementMode: "anchored"
            panelLocation: root.panelLocation
            availableScreenRect: root.availableScreenRect
            screenGeometry: root.screenGeometry
            itemAnchor: root.placementAnchor
            floatingDockAnchor: root.floatingDockAnchor
            panelWindow: root.panelWindow
            panelThickness: root.panelThickness
            menuWidth: root.width
            menuHeight: root.height
            panelGap: root.popupGap
            floatingGap: root.popupGap
            screenInset: root.popupGap
            themeFrameLeftMargin: root.popupFrameMargin("left")
            themeFrameTopMargin: root.popupFrameMargin("top")
            themeFrameRightMargin: root.popupFrameMargin("right")
            themeFrameBottomMargin: root.popupFrameMargin("bottom")
            surfaceFrameLeftMargin: root.dockSurfaceFrameInset("left")
            surfaceFrameTopMargin: root.dockSurfaceFrameInset("top")
            surfaceFrameRightMargin: root.dockSurfaceFrameInset("right")
            surfaceFrameBottomMargin: root.dockSurfaceFrameInset("bottom")
        }
    readonly property point targetPosition:
        root.placementController.calculatePosition()

    visualParent: null
    location: PlasmaCore.Types.Floating

    function surfaceFrameInset(side) {
        if (!root.surfaceFrame
                || typeof root.surfaceFrame.backgroundFrameInset
                    !== "function") {
            return 0
        }
        return root.surfaceFrame.backgroundFrameInset(side)
    }

    function popupEffectiveWindowRect() {
        if (!root.surfaceFrame
                || typeof root.surfaceFrame.effectiveBackgroundWindowRect
                    !== "function") {
            return Qt.rect(0, 0, 0, 0)
        }
        return root.surfaceFrame.effectiveBackgroundWindowRect()
    }

    function popupFrameMargin(side) {
        const geometry = root.effectivePopupGeometry
        if (geometry.width <= 0 || geometry.height <= 0) {
            return root.surfaceFrameInset(side)
        }
        if (side === "left") {
            return Math.max(0, geometry.x)
        }
        if (side === "top") {
            return Math.max(0, geometry.y)
        }
        if (side === "right") {
            return Math.max(0, root.width - geometry.x - geometry.width)
        }
        return Math.max(0, root.height - geometry.y - geometry.height)
    }

    function dockSurfaceFrameInset(side) {
        if (root.inPanel || !root.floatingDockSurfaceFrame
                || typeof root.floatingDockSurfaceFrame.backgroundFrameInset
                    !== "function") {
            return 0
        }
        return root.floatingDockSurfaceFrame.backgroundFrameInset(side)
    }

    function positionAtAnchor() {
        if (!root.placementController) {
            return
        }
        root.x = root.targetPosition.x
        root.y = root.targetPosition.y
    }

    function scheduleReposition() {
        if (root.visible) {
            Qt.callLater(root.positionAtAnchor)
        }
    }

    onTargetPositionChanged: root.scheduleReposition()
    onWidthChanged: root.scheduleReposition()
    onHeightChanged: root.scheduleReposition()
    onVisibleChanged: {
        if (root.visible) {
            root.scheduleReposition()
        }
    }
}
