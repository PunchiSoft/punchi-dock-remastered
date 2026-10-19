import QtQuick
import org.kde.kirigami as Kirigami

// Plasma injects translation functions into the applet context.
// qmllint disable unqualified
Item {
    id: root

    // The trash workflow is rendered over a widgets/background popup surface.
    // Keep its complete menu and confirmation flow on the Window palette.
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    property string operationState: "idle"
    property int progressPercent: -1
    property bool progressDeterminate: false
    property int processedItems: 0
    property int totalItems: 0
    property string errorMessage: ""
    property int transitionSpeedPercent: 100
    property int menuWidth: 360
    property int menuRowHeight: 46
    property int menuIconSize: 26
    property bool canEmptyTrash: false
    property int maximumAvailableWidth: 752
    property int maximumAvailableHeight: 640
    property real surfaceMarginLeft: Kirigami.Units.smallSpacing
    property real surfaceMarginTop: Kirigami.Units.smallSpacing
    property real surfaceMarginRight: Kirigami.Units.smallSpacing
    property real surfaceMarginBottom: Kirigami.Units.smallSpacing
    property bool menuTextShadowsEnabled: false
    property real surfaceWidth: targetSurfaceWidth
    property real surfaceHeight: targetSurfaceHeight
    readonly property int effectiveRowHeight: Math.max(32, Math.min(64,
        Number(menuRowHeight || 46)))
    readonly property int effectiveIconSize: Math.max(16, Math.min(40,
        Number(menuIconSize || 26)))
    readonly property real effectiveSurfaceMarginLeft: Math.max(0,
        Number.isFinite(Number(surfaceMarginLeft))
            ? Number(surfaceMarginLeft) : Kirigami.Units.smallSpacing)
    readonly property real effectiveSurfaceMarginTop: Math.max(0,
        Number.isFinite(Number(surfaceMarginTop))
            ? Number(surfaceMarginTop) : Kirigami.Units.smallSpacing)
    readonly property real effectiveSurfaceMarginRight: Math.max(0,
        Number.isFinite(Number(surfaceMarginRight))
            ? Number(surfaceMarginRight) : Kirigami.Units.smallSpacing)
    readonly property real effectiveSurfaceMarginBottom: Math.max(0,
        Number.isFinite(Number(surfaceMarginBottom))
            ? Number(surfaceMarginBottom) : Kirigami.Units.smallSpacing)
    readonly property int transitionDuration: Kirigami.Units.longDuration > 1
        ? Math.round(Kirigami.Units.longDuration * 100
            / Math.max(10, Math.min(200, transitionSpeedPercent)))
        : 0
    readonly property real targetSurfaceWidth: Math.max(240,
        Math.min(520, Number(maximumAvailableWidth || 752),
            Math.max(300, Number(menuWidth || 360))))
    readonly property real targetBodyHeight: menuPage.implicitHeight
    readonly property real desiredSurfaceHeight: effectiveSurfaceMarginTop
        + targetBodyHeight + effectiveSurfaceMarginBottom
    readonly property real targetSurfaceHeight: Math.max(effectiveRowHeight,
        Math.min(Number(maximumAvailableHeight || 640), desiredSurfaceHeight))

    implicitWidth: surfaceWidth
    implicitHeight: surfaceHeight
    width: implicitWidth
    height: implicitHeight
    clip: true

    signal openTrashRequested()
    signal emptyTrashRequested()
    signal closeRequested()

    function showMenu(focusFirstAction) {
        if (focusFirstAction === undefined || focusFirstAction) {
            Qt.callLater(menuPage.focusFirstAction)
        } else {
            Qt.callLater(menuPage.clearActionFocus)
        }
    }

    Behavior on surfaceWidth {
        NumberAnimation {
            duration: root.transitionDuration
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on surfaceHeight {
        NumberAnimation {
            duration: root.transitionDuration
            easing.type: Easing.InOutCubic
        }
    }


    TrashMenuPopup {
        id: menuPage
        x: root.effectiveSurfaceMarginLeft
        y: root.effectiveSurfaceMarginTop
        width: Math.max(0, root.width
            - root.effectiveSurfaceMarginLeft
            - root.effectiveSurfaceMarginRight)
        height: Math.max(0, root.height - y
            - root.effectiveSurfaceMarginBottom)
        rowHeight: root.effectiveRowHeight
        iconSize: root.effectiveIconSize
        textShadowsEnabled: root.menuTextShadowsEnabled
        canEmptyTrash: root.canEmptyTrash

        onOpenTrashClicked: root.openTrashRequested()
        onEmptyTrashClicked: root.emptyTrashRequested()
    }
}
// qmllint enable unqualified
