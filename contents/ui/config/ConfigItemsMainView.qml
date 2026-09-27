import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: root

    property var controller
    property var itemModel
    property var statusHideTimer
    property alias statusText: statusLabel.text
    property alias statusType: statusLabel.type

    signal addItemRequested()

    function positionAtIndex(index) {
        itemListEditor.positionAtIndex(index)
    }

    function focusItemAtIndex(index) {
        itemListEditor.focusAtIndex(index)
    }

    function focusAddItemButton() {
        itemListEditor.focusAddItemButton()
    }

    function showStatus(text, type) {
        statusLabel.text = text
        statusLabel.type = type
    }

    function clearStatus() {
        statusLabel.text = ""
    }

    // The configuration dialog already provides the page margins, so the view
    // fills its content area instead of adding a second inset.
    anchors.fill: parent
    spacing: Kirigami.Units.smallSpacing

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing

            DockItemListEditor {
                id: itemListEditor
                objectName: "dockItemListEditor"
                controller: root.controller
                itemModel: root.itemModel
                // The add action now belongs to this collection toolbar. Keep a
                // wider preferred column for its labelled state, but allow the
                // toolbar to compact before taking the reserved panel's floor.
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                Layout.minimumWidth: Kirigami.Units.gridUnit * 16
                Layout.maximumWidth: Kirigami.Units.gridUnit * 20
                onAddItemRequested: root.addItemRequested()
            }

            // Reserved right column, deliberately empty: it keeps the same
            // Controls.Frame surface as the dock item list so both columns read
            // as equals. It holds no item editor, links to nothing and writes no
            // configuration; the content of this column is still undecided.
            Controls.Frame {
                objectName: "itemConfigurationReservedArea"
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: Kirigami.Units.gridUnit * 12
            }
        }

        Kirigami.InlineMessage {
            id: statusLabel
            Layout.fillWidth: true
            visible: text.length > 0
            text: ""
            onTextChanged: {
                if (text.length > 0 && type !== Kirigami.MessageType.Error) {
                    root.statusHideTimer.restart()
                } else {
                    root.statusHideTimer.stop()
                }
            }
            onTypeChanged: {
                if (text.length > 0 && type !== Kirigami.MessageType.Error) {
                    root.statusHideTimer.restart()
                } else {
                    root.statusHideTimer.stop()
                }
            }
        }
    }
}
