import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: root

    property var controller
    property bool active: false
    property alias text: editor.text

    function selectAll() {
        editor.selectAll()
    }

    function copy() {
        editor.copy()
    }

    spacing: Kirigami.Units.smallSpacing

    Controls.TextArea {
        id: editor
        Layout.fillWidth: true
        Layout.fillHeight: true
        wrapMode: TextEdit.NoWrap
        textFormat: TextEdit.PlainText
        font.family: "monospace"
        selectByMouse: true
        persistentSelection: true
        onTextChanged: {
            if (!controller.syncing && !controller.loadingFromDisk && root.active) {
                if (controller.advancedJsonChanged) {
                    controller.advancedJsonChanged(text)
                } else {
                    controller.cfg_dockItemsJson = text
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true

        Controls.Button {
            HoverHandler { cursorShape: Qt.PointingHandCursor }
            text: i18n("Validate")
            icon.name: "dialog-ok-apply-symbolic"
            onClicked: controller.validateJson()
        }

        Controls.Button {
            HoverHandler { cursorShape: Qt.PointingHandCursor }
            text: i18n("Format")
            icon.name: "format-indent-more-symbolic"
            onClicked: {
                if (controller.validateJson()) {
                    controller.setItems(JSON.parse(editor.text))
                }
            }
        }
    }
}
