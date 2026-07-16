import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property string operationState: "idle"
    property int progressPercent: -1
    property bool progressDeterminate: false
    property int processedItems: 0
    property int totalItems: 0
    property string errorMessage: ""
    property int transitionSpeedPercent: 100
    property bool confirmationVisible: false
    readonly property int transitionDuration: Kirigami.Units.longDuration > 1
        ? Math.round(Kirigami.Units.longDuration * 100
            / Math.max(10, Math.min(200, transitionSpeedPercent)))
        : 0

    implicitWidth: Math.max(menuPage.implicitWidth, confirmationPage.implicitWidth)
    implicitHeight: Math.max(menuPage.implicitHeight, confirmationPage.implicitHeight)
    width: implicitWidth
    height: implicitHeight
    clip: true

    signal openTrashRequested()
    signal emptyTrashRequested()
    signal closeRequested()

    function showMenu(focusFirstAction) {
        if (operationState === "emptying") {
            return
        }
        confirmationVisible = false
        if (focusFirstAction === undefined || focusFirstAction) {
            Qt.callLater(menuPage.focusFirstAction)
        } else {
            Qt.callLater(menuPage.clearActionFocus)
        }
    }

    function showConfirmation() {
        confirmationVisible = true
        Qt.callLater(confirmationPage.focusPrimaryAction)
    }

    Item {
        id: pageStrip
        width: root.width * 2
        height: root.height
        x: root.confirmationVisible ? -root.width : 0

        Behavior on x {
            enabled: root.transitionDuration > 0

            NumberAnimation {
                duration: root.transitionDuration
                easing.type: Easing.InOutCubic
            }
        }

        TrashMenuPopup {
            id: menuPage
            x: 0
            width: root.width
            height: root.height
            enabled: !root.confirmationVisible
            visible: !root.confirmationVisible || pageStrip.x > -root.width

            onOpenTrashClicked: root.openTrashRequested()
            onEmptyTrashClicked: root.showConfirmation()
            onCloseRequested: root.closeRequested()
        }

        ConfirmTrashEmptyPopup {
            id: confirmationPage
            x: root.width
            width: root.width
            height: root.height
            enabled: root.confirmationVisible
            visible: root.confirmationVisible || pageStrip.x < 0
            operationState: root.operationState
            progressPercent: root.progressPercent
            progressDeterminate: root.progressDeterminate
            processedItems: root.processedItems
            totalItems: root.totalItems
            errorMessage: root.errorMessage

            onConfirmRequested: root.emptyTrashRequested()
            onCancelRequested: root.showMenu()
            onDismissRequested: root.closeRequested()
        }
    }
}
