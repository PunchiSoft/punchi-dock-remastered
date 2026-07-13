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
    property bool actionsVisible: false
    readonly property bool containsMouse: popupHover.hovered

    implicitWidth: actionsVisible ? actionsPage.implicitWidth : previewPage.implicitWidth
    implicitHeight: actionsVisible ? actionsPage.implicitHeight : previewPage.implicitHeight
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
        actionsVisible = true
    }

    function showPreviews() {
        actionsVisible = false
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
            enabled: Kirigami.Units.longDuration > 1
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutCubic
            }
        }

        TaskWindowsPopup {
            id: previewPage
            x: 0
            width: root.width
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
            itemName: root.actionItemName
            actions: root.actions
            maxVisibleRows: root.maxVisibleActionRows
            embedded: true

            onActionTriggered: action => root.actionTriggered(action)
            onCloseRequested: root.showPreviews()
        }
    }

}
