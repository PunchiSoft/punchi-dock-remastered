import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Item {
    id: root

    property int rowHeight: 46
    property int iconSize: 26
    readonly property int effectiveRowHeight: Math.max(32, Math.min(64,
        Number(rowHeight || 46)))
    readonly property int effectiveIconSize: Math.max(16, Math.min(40,
        Number(iconSize || 26)))

    implicitWidth: 300
    implicitHeight: actionColumn.implicitHeight

    signal openTrashClicked()
    signal emptyTrashClicked()

    function focusFirstAction() {
        openOption.forceActiveFocus(Qt.TabFocusReason)
    }

    function clearActionFocus() {
        root.forceActiveFocus(Qt.MouseFocusReason)
    }

    ColumnLayout {
        id: actionColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Kirigami.Units.smallSpacing

        Controls.ItemDelegate {
            id: openOption
            Layout.fillWidth: true
            Layout.preferredHeight: root.effectiveRowHeight
            text: i18n("Open trash")
            icon.name: "folder-open"
            icon.width: root.effectiveIconSize
            icon.height: root.effectiveIconSize
            Accessible.description: i18n("Open the trash folder in the file manager")
            onClicked: root.openTrashClicked()
        }

        Controls.ItemDelegate {
            id: emptyOption
            Layout.fillWidth: true
            Layout.preferredHeight: root.effectiveRowHeight
            text: i18n("Empty trash")
            icon.name: "trash-empty"
            icon.width: root.effectiveIconSize
            icon.height: root.effectiveIconSize
            icon.color: Kirigami.Theme.negativeTextColor
            Accessible.description: i18n("Permanently remove all items from the trash")
            onClicked: root.emptyTrashClicked()
        }
    }
}
