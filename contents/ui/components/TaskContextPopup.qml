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
    property int maxVisibleRows: 4
    property int maximumAvailableWidth: 752
    property int maximumAvailableHeight: 640
    property string actionItemName: ""
    property var actions: []
    property int maxVisibleActionRows: 6
    property int transitionSpeedPercent: 100
    property bool transitionsEnabled: true
    property bool previewsEnabled: true
    property bool returnToMedia: false
    property bool actionsVisible: false
    property real mediaActionsRevealProgress: actionsVisible ? 1 : 0
    property real preservedPreviewWidth: 0
    property real preservedPreviewHeight: 0
    readonly property bool containsMouse: popupHover.hovered
    readonly property bool preservingPreviewSize: actionsVisible
        && preservedPreviewWidth > 0
        && preservedPreviewHeight > 0
    readonly property bool mediaActionsComposed: returnToMedia
        && (actionsVisible || mediaActionsRevealProgress > 0.001)
    readonly property int transitionDuration: transitionsEnabled && Kirigami.Units.longDuration > 1
        ? Math.round(Kirigami.Units.longDuration * 100
            / Math.max(10, Math.min(200, transitionSpeedPercent)))
        : 0

    implicitWidth: preservingPreviewSize
        ? preservedPreviewWidth
        : (mediaActionsComposed || actionsVisible
            ? actionsPage.implicitWidth
            : previewPage.implicitWidth)
    implicitHeight: preservingPreviewSize
        ? preservedPreviewHeight
        : (mediaActionsComposed || actionsVisible
            ? actionsPage.implicitHeight
            : previewPage.implicitHeight)
    width: implicitWidth
    height: implicitHeight
    clip: true

    signal activateRequested(int taskRow)
    signal presentWindowRequested(int taskRow)
    signal minimizeWindowRequested(int taskRow)
    signal maximizeWindowRequested(int taskRow)
    signal closeWindowRequested(int taskRow)
    signal actionTriggered(var action)

    function showActions(preservePreviewSize) {
        if (actionsVisible) {
            return
        }
        const shouldPreservePreviewSize = preservePreviewSize !== false
        preservedPreviewWidth = shouldPreservePreviewSize ? Math.max(1, width) : 0
        preservedPreviewHeight = shouldPreservePreviewSize ? Math.max(1, height) : 0
        actionsVisible = true
    }

    function showPreviews() {
        actionsVisible = false
        preservedPreviewWidth = 0
        preservedPreviewHeight = 0
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
        width: root.width * 2
        height: root.height
        x: root.returnToMedia ? 0 : (root.actionsVisible ? -root.width : 0)

        Behavior on x {
            enabled: !root.returnToMedia && root.transitionDuration > 0
            NumberAnimation {
                duration: root.transitionDuration
                easing.type: Easing.InOutCubic
            }
        }

        WindowPreviewSurface {
            id: previewPage
            x: 0
            width: root.width
            height: root.height
            visible: root.previewsEnabled
                && !root.mediaActionsComposed
                && (!root.actionsVisible || pageStrip.x > -root.width)
            enabled: visible
            taskControllerRef: root.taskControllerRef
            taskRevision: root.taskRevision
            applicationId: root.applicationId
            windowUuids: root.windowUuids
            fallbackWindows: root.previewsEnabled ? root.windows : []
            previewStyle: root.previewStyle
            previewScale: root.previewScale
            previewInfoMode: root.previewInfoMode
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
            x: root.returnToMedia ? 0 : root.width
            width: root.width
            height: root.height
            opacity: root.returnToMedia
                ? Math.max(0, Math.min(1, root.mediaActionsRevealProgress))
                : 1
            scale: root.returnToMedia
                ? 0.985 + (0.015 * Math.max(0,
                    Math.min(1, root.mediaActionsRevealProgress)))
                : 1
            transformOrigin: Item.Top
            visible: root.returnToMedia ? root.mediaActionsComposed : true
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
            embedded: true
            returnToMedia: root.returnToMedia

            onActionTriggered: action => root.actionTriggered(action)
            onCloseRequested: root.showPreviews()
        }
    }

}
