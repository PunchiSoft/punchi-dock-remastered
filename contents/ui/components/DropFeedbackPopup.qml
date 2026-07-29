import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

PlasmaCore.Dialog {
    id: root

    property string message: ""

    type: PlasmaCore.Dialog.Tooltip
    flags: Qt.ToolTip | Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus
    visible: feedbackTimer.running && root.visualParent !== null

    function presentFeedback(targetItem, text) {
        if (!targetItem || String(text || "").length === 0) {
            return
        }
        root.visualParent = targetItem
        root.message = String(text)
        feedbackTimer.restart()
    }

    function dismissFeedback() {
        feedbackTimer.stop()
        root.visualParent = null
        root.message = ""
    }

    mainItem: RowLayout {
        spacing: Kirigami.Units.smallSpacing
        Accessible.role: Accessible.AlertMessage
        Accessible.name: root.message

        Timer {
            id: feedbackTimer
            interval: 3500
            repeat: false
        }

        Kirigami.Icon {
            source: "dialog-warning-symbolic"
            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
        }

        Controls.Label {
            text: root.message
            wrapMode: Text.Wrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
        }
    }
}
