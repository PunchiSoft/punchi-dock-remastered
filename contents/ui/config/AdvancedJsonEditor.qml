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
            if (!root.controller.syncing && !root.controller.loadingFromDisk && root.active) {
                if (root.controller.advancedJsonChanged) {
                    root.controller.advancedJsonChanged(text)
                } else {
                    root.controller.cfg_dockItemsJson = text
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true

        Controls.Button {
            HoverHandler { cursorShape: Qt.PointingHandCursor }
            text: i18n("Validate") // qmllint disable unqualified
            icon.name: "dialog-ok-apply-symbolic"
            onClicked: root.controller.validateJson()
        }

        Controls.Button {
            HoverHandler { cursorShape: Qt.PointingHandCursor }
            text: i18n("Format") // qmllint disable unqualified
            icon.name: "format-indent-more-symbolic"
            onClicked: {
                if (root.controller.validateJson()) {
                    root.controller.setItems(JSON.parse(editor.text))
                }
            }
        }
    }
}
