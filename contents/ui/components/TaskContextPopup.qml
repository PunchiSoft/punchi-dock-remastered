import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property string appName: ""
    property var windows: []
    property string previewStyle: "card"
    property real previewScale: 1.0
    property bool automaticPopupRadius: true
    property int popupRadius: 4
    property int popupDirection: Qt.BottomEdge
    property bool inPanel: false
    property int maxVisibleRows: 4
    property int maximumAvailableHeight: 640
    property string actionItemName: ""
    property var actions: []
    property int maxVisibleActionRows: 6
    property int transitionSpeedPercent: 100
    property bool actionsVisible: false
    property real preservedPreviewWidth: 0
    property real preservedPreviewHeight: 0
    readonly property bool containsMouse: popupHover.hovered
    readonly property bool preservingPreviewSize: actionsVisible
        && preservedPreviewWidth > 0
        && preservedPreviewHeight > 0
    readonly property int transitionDuration: Kirigami.Units.longDuration > 1
        ? Math.round(Kirigami.Units.longDuration * 100
            / Math.max(10, Math.min(200, transitionSpeedPercent)))
        : 0

    implicitWidth: preservingPreviewSize ? preservedPreviewWidth : previewPage.implicitWidth
    implicitHeight: preservingPreviewSize ? preservedPreviewHeight : previewPage.implicitHeight
    width: implicitWidth
    height: implicitHeight
    clip: true

    signal activateRequested(int taskRow)
    signal presentWindowRequested(int taskRow)
    signal minimizeWindowRequested(int taskRow)
    signal maximizeWindowRequested(int taskRow)
    signal closeWindowRequested(int taskRow)
    signal actionTriggered(var action)
    signal closeRequested()

    function showActions() {
        if (actionsVisible) {
            return
        }
        preservedPreviewWidth = Math.max(1, width)
        preservedPreviewHeight = Math.max(1, height)
        actionsVisible = true
    }

    function showPreviews() {
        actionsVisible = false
        preservedPreviewWidth = 0
        preservedPreviewHeight = 0
    }

    HoverHandler {
        id: popupHover
    }

    Item {
        id: pageStrip
        width: root.width * 2
        height: root.height
        x: root.actionsVisible ? -root.width : 0

        Behavior on x {
            enabled: root.transitionDuration > 0
            NumberAnimation {
                duration: root.transitionDuration
                easing.type: Easing.InOutCubic
            }
        }

        TaskWindowsPopup {
            id: previewPage
            x: 0
            width: root.width
            height: root.height
            visible: !root.actionsVisible || pageStrip.x > -root.width
            appName: root.appName
            windows: root.windows
            previewStyle: root.previewStyle
            previewScale: root.previewScale
            automaticPopupRadius: root.automaticPopupRadius
            popupRadius: root.popupRadius
            popupDirection: root.popupDirection
            inPanel: root.inPanel
            maxVisibleRows: root.maxVisibleRows
            maximumAvailableHeight: root.maximumAvailableHeight

            onActivateRequested: taskRow => root.activateRequested(taskRow)
            onPresentWindowRequested: taskRow => root.presentWindowRequested(taskRow)
            onMinimizeWindowRequested: taskRow => root.minimizeWindowRequested(taskRow)
            onMaximizeWindowRequested: taskRow => root.maximizeWindowRequested(taskRow)
            onCloseWindowRequested: taskRow => root.closeWindowRequested(taskRow)
            onCloseRequested: root.closeRequested()
        }

        AppActionsPopup {
            id: actionsPage
            x: root.width
            width: root.width
            height: root.height
            itemName: root.actionItemName
            actions: root.actions
            maxVisibleRows: root.maxVisibleActionRows
            embedded: true

            onActionTriggered: action => root.actionTriggered(action)
            onCloseRequested: root.showPreviews()
        }
    }

}
