import QtQuick
import org.kde.plasma.core as PlasmaCore

Item {
    id: root

    property Item sourceAnchor: null
    property GuardedPopupDialog popup: null
    property int gap: 0
    property int location: PlasmaCore.Types.BottomEdge
    property bool preserveHorizontalAnchorCenter: false
    property bool preserveVerticalAnchorCenter: false
    // Keeps an internal visual origin aligned with the launcher while Plasma
    // continues positioning the popup through its native visualParent.
    property real horizontalAnchorOffset: 0
    property Item targetSurface: null
    property real targetTranslationX: 0
    property real targetTranslationY: 0

    readonly property PopupAnchorMetrics anchorMetrics: PopupAnchorMetrics {}
    readonly property bool centerHorizontally: root.preserveHorizontalAnchorCenter
        && (root.location === PlasmaCore.Types.TopEdge
            || root.location === PlasmaCore.Types.BottomEdge)
    readonly property bool centerVertically: root.preserveVerticalAnchorCenter
        && (root.location === PlasmaCore.Types.LeftEdge
            || root.location === PlasmaCore.Types.RightEdge)
    readonly property real safeHorizontalAnchorOffset:
        Number.isFinite(Number(root.horizontalAnchorOffset))
            ? Number(root.horizontalAnchorOffset) : 0
    readonly property real popupWidth: root.popup
        ? Math.max(root.popup.width,
            root.popup.sizingItem ? root.popup.sizingItem.width : 0) : 0
    readonly property real popupHeight: root.popup
        ? Math.max(root.popup.height,
            root.popup.sizingItem ? root.popup.sizingItem.height : 0) : 0

    // The launcher and popup live in separate windows. Observe both window
    // positions and the actual transform chain before mapping between them.
    readonly property point sourceCenterInTarget: {
        if (!root.sourceAnchor || !root.targetSurface
                || !root.sourceAnchor.Window.window || !root.targetSurface.Window.window) {
            return Qt.point(NaN, NaN)
        }
        let geometryState = root.sourceGeometry.x + root.sourceGeometry.y
            + root.sourceGeometry.width + root.sourceGeometry.height
            + root.targetTranslationX + root.targetTranslationY
            + root.sourceAnchor.Window.window.x + root.sourceAnchor.Window.window.y
            + root.targetSurface.Window.window.x + root.targetSurface.Window.window.y
        for (let item = root.targetSurface; item; item = item.parent) {
            geometryState += item.x + item.y + item.width + item.height
                + item.scale + item.rotation + item.transformOrigin
        }
        if (!Number.isFinite(geometryState)) {
            return Qt.point(NaN, NaN)
        }
        return root.sourceAnchor.mapToItem(root.targetSurface,
            Qt.point(root.sourceAnchor.width / 2, root.sourceAnchor.height / 2))
    }

    // Map into the window content item so the extra distance stays in logical
    // units even when the launcher or one of its ancestors is scaled.
    parent: root.sourceAnchor ? root.sourceAnchor.Window.contentItem : null
    visible: false
    Accessible.ignored: true

    readonly property rect sourceGeometry: {
        if (!root.sourceAnchor || !root.parent) {
            return Qt.rect(0, 0, 0, 0)
        }
        // Mapping alone does not subscribe to ancestor geometry changes.
        let geometryState = 0
        for (let item = root.sourceAnchor; item; item = item.parent) {
            geometryState += item.x + item.y + item.width + item.height
                + item.scale + item.rotation + item.transformOrigin
        }
        if (!Number.isFinite(geometryState)) {
            return Qt.rect(0, 0, 0, 0)
        }
        return root.sourceAnchor.mapToItem(root.parent,
            Qt.rect(0, 0, root.sourceAnchor.width, root.sourceAnchor.height))
    }
    readonly property int safeGap: Math.max(0, root.gap)

    x: root.sourceGeometry.x - (root.width - root.sourceGeometry.width) / 2
        + (root.centerHorizontally ? root.safeHorizontalAnchorOffset : 0)
        + (root.location === PlasmaCore.Types.LeftEdge
        ? root.safeGap : root.location === PlasmaCore.Types.RightEdge
            ? -root.safeGap : 0)
    y: root.sourceGeometry.y - (root.height - root.sourceGeometry.height) / 2
        + (root.location === PlasmaCore.Types.TopEdge
        ? root.safeGap : root.location === PlasmaCore.Types.BottomEdge
            ? -root.safeGap : 0)
    width: root.centerHorizontally
        ? root.anchorMetrics.centeredExtent(root.sourceGeometry.width, root.popupWidth)
        : root.sourceGeometry.width
    height: root.centerVertically
        ? root.anchorMetrics.centeredExtent(root.sourceGeometry.height, root.popupHeight)
        : root.sourceGeometry.height

    function refreshAnchor() {
        if (!root.popup) {
            return
        }
        if (!root.sourceAnchor || !root.parent) {
            root.popup.visualParent = null
            if (root.popup.visible || root.popup.preparingToShow) {
                root.popup.closeSafely()
            }
            return
        }
        // Dialog::setVisualParent recalculates placement; moving the same
        // visualParent does not. Reassign without hiding or resizing the popup.
        root.popup.visualParent = null
        root.popup.visualParent = root.safeGap > 0 || root.centerHorizontally || root.centerVertically
            ? root : root.sourceAnchor
    }

    function scheduleRefresh() {
        Qt.callLater(root.refreshAnchor)
    }

    onSourceAnchorChanged: root.scheduleRefresh()
    onPopupChanged: root.scheduleRefresh()
    onParentChanged: root.scheduleRefresh()
    onXChanged: root.scheduleRefresh()
    onYChanged: root.scheduleRefresh()
    onWidthChanged: root.scheduleRefresh()
    onHeightChanged: root.scheduleRefresh()
    onSafeGapChanged: root.scheduleRefresh()
    onLocationChanged: root.scheduleRefresh()
    onCenterHorizontallyChanged: root.scheduleRefresh()
    onCenterVerticallyChanged: root.scheduleRefresh()
    onHorizontalAnchorOffsetChanged: root.scheduleRefresh()

    Connections {
        target: root.popup
        function onVisibleChanged() {
            if (root.popup.visible) {
                root.scheduleRefresh()
            }
        }
    }
}
