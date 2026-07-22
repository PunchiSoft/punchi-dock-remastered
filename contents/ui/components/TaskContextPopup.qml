import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property var windows: []
    property var taskControllerRef: null
    property int taskRevision: 0
    property string applicationId: ""
    property var windowUuids: []
    property string previewStyle: "card"
    property real previewScale: 1.5
    property string previewInfoMode: "full"
    property bool windowPreviewTextShadowsEnabled: true
    property bool menuTextShadowsEnabled: true
    property int maxVisibleRows: 4
    property int maximumAvailableWidth: 752
    property int maximumAvailableHeight: 640
    property string actionItemName: ""
    property var actions: []
    property int maxVisibleActionRows: 6
    property int actionRowHeight: 46
    property int actionIconSize: 26
    property int actionMenuWidth: 360
    property string transitionDirection: "fromRight"
    property int transitionSpeedPercent: 100
    property bool transitionsEnabled: true
    property bool previewsEnabled: true
    property bool returnToMedia: false
    property bool actionsVisible: false
    property real pageTransitionProgress: actionsVisible ? 1 : 0
    property real mediaActionsRevealProgress: actionsVisible ? 1 : 0
    readonly property bool previewsAllowed: previewStyle !== "none"
    readonly property bool previewSurfaceVisible: previewsAllowed && previewsEnabled
    readonly property bool containsMouse: popupHover.hovered
    readonly property bool mediaActionsComposed: returnToMedia
        && (actionsVisible || mediaActionsRevealProgress > 0.001)
    readonly property bool morphOnlyTransition: transitionDirection === "morphOnly"
    readonly property real previewOffsetX: {
        if (returnToMedia || morphOnlyTransition) {
            return 0
        }
        if (transitionDirection === "fromLeft") {
            return width * pageTransitionProgress
        }
        if (transitionDirection === "fromRight") {
            return -width * pageTransitionProgress
        }
        return 0
    }
    readonly property real previewOffsetY: {
        if (returnToMedia || morphOnlyTransition) {
            return 0
        }
        if (transitionDirection === "fromTop") {
            return height * pageTransitionProgress
        }
        if (transitionDirection === "fromBottom") {
            return -height * pageTransitionProgress
        }
        return 0
    }
    readonly property real actionsOffsetX: {
        if (returnToMedia || morphOnlyTransition) {
            return 0
        }
        if (transitionDirection === "fromLeft") {
            return -width * (1 - pageTransitionProgress)
        }
        if (transitionDirection === "fromRight") {
            return width * (1 - pageTransitionProgress)
        }
        return 0
    }
    readonly property real actionsOffsetY: {
        if (returnToMedia || morphOnlyTransition) {
            return 0
        }
        if (transitionDirection === "fromTop") {
            return -height * (1 - pageTransitionProgress)
        }
        if (transitionDirection === "fromBottom") {
            return height * (1 - pageTransitionProgress)
        }
        return 0
    }
    readonly property int transitionDuration: transitionsEnabled && Kirigami.Units.longDuration > 1
        ? Math.round(Kirigami.Units.longDuration * 100
            / Math.max(10, Math.min(200, transitionSpeedPercent)))
        : 0

    implicitWidth: mediaActionsComposed || actionsVisible
        ? actionsPage.implicitWidth
        : (previewSurfaceVisible ? previewPage.implicitWidth : 0)
    implicitHeight: mediaActionsComposed || actionsVisible
        ? actionsPage.implicitHeight
        : (previewSurfaceVisible ? previewPage.implicitHeight : 0)
    width: implicitWidth
    height: implicitHeight
    clip: true

    signal activateRequested(int taskRow)
    signal presentWindowRequested(int taskRow)
    signal minimizeWindowRequested(int taskRow)
    signal maximizeWindowRequested(int taskRow)
    signal closeWindowRequested(int taskRow)
    signal actionTriggered(var action)

    function showActions() {
        if (actionsVisible) {
            return
        }
        actionsVisible = true
    }

    function showPreviews() {
        actionsVisible = false
    }

    Behavior on pageTransitionProgress {
        NumberAnimation {
            duration: root.transitionDuration
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on mediaActionsRevealProgress {
        NumberAnimation {
            duration: root.transitionDuration
            easing.type: root.actionsVisible ? Easing.OutBack : Easing.InOutCubic
            easing.overshoot: 0.55
        }
    }

    HoverHandler {
        id: popupHover
    }

    Item {
        id: pageStrip
        width: root.width
        height: root.height

        WindowPreviewSurface {
            id: previewPage
            x: root.previewOffsetX
            y: root.previewOffsetY
            width: root.width
            height: root.height
            visible: root.previewSurfaceVisible
                && !root.mediaActionsComposed
                && (!root.actionsVisible || root.pageTransitionProgress < 0.999)
            enabled: visible
            opacity: root.morphOnlyTransition
                ? 1 - root.pageTransitionProgress
                : 1
            taskControllerRef: root.taskControllerRef
            taskRevision: root.taskRevision
            applicationId: root.applicationId
            windowUuids: root.windowUuids
            fallbackWindows: root.previewSurfaceVisible ? root.windows : []
            previewStyle: root.previewStyle
            previewScale: root.previewScale
            previewInfoMode: root.previewInfoMode
            textShadowsEnabled: root.windowPreviewTextShadowsEnabled
            maxVisibleRows: root.maxVisibleRows
            maximumAvailableWidth: root.maximumAvailableWidth
            maximumAvailableHeight: root.maximumAvailableHeight

            onActivateRequested: taskRow => root.activateRequested(taskRow)
            onPresentWindowRequested: taskRow => root.presentWindowRequested(taskRow)
            onMinimizeWindowRequested: taskRow => root.minimizeWindowRequested(taskRow)
            onMaximizeWindowRequested: taskRow => root.maximizeWindowRequested(taskRow)
            onCloseWindowRequested: taskRow => root.closeWindowRequested(taskRow)
        }

        AppActionsPopup {
            id: actionsPage
            x: root.actionsOffsetX
            y: root.actionsOffsetY
            width: root.width
            height: root.height
            opacity: root.returnToMedia
                ? Math.max(0, Math.min(1, root.mediaActionsRevealProgress))
                : (root.morphOnlyTransition ? root.pageTransitionProgress : 1)
            scale: root.returnToMedia
                ? 0.985 + (0.015 * Math.max(0,
                    Math.min(1, root.mediaActionsRevealProgress)))
                : 1
            transformOrigin: Item.Top
            visible: root.returnToMedia
                ? root.mediaActionsComposed
                : (root.actionsVisible || root.pageTransitionProgress > 0.001)
            enabled: visible
            transform: Translate {
                y: root.returnToMedia
                    ? Kirigami.Units.smallSpacing
                        * (1 - Math.max(0, Math.min(1,
                            root.mediaActionsRevealProgress)))
                    : 0
            }
            itemName: root.actionItemName
            actions: root.actions
            maxVisibleRows: root.maxVisibleActionRows
            rowHeight: root.actionRowHeight
            iconSize: root.actionIconSize
            targetWidth: root.actionMenuWidth
            maximumAvailableWidth: root.maximumAvailableWidth
            maximumAvailableHeight: root.maximumAvailableHeight
            embedded: true
            returnToMedia: root.returnToMedia
            textShadowsEnabled: root.menuTextShadowsEnabled

            onActionTriggered: action => root.actionTriggered(action)
            onCloseRequested: root.showPreviews()
        }
    }

}
