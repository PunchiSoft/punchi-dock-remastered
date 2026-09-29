import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import "code/itemNotes.js" as ItemNotes

ColumnLayout {
    id: root

    property var controller
    property var itemModel
    property var statusHideTimer
    property alias statusText: statusLabel.text
    readonly property string selectedNoteType: {
        if (!controller) {
            return ""
        }
        const index = Number(controller.selectedIndex)
        const sourceItems = controller.items
        if (!Number.isInteger(index) || index < 0 || !sourceItems
                || index >= sourceItems.length) {
            return ""
        }
        const selectedItem = sourceItems[index]
        return selectedItem ? String(selectedItem.type || "app") : ""
    }

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
                // The column hugs its own toolbar: the row of five actions is the
                // widest thing this panel needs, and it is measured in its compact
                // state. The labelled add button alone would need 344 px in German
                // and 310 px in Spanish, so keeping the label would widen the column
                // and leave a hole in the toolbar of the shorter languages; the
                // label stays in the tooltip and in the accessible name instead.
                // Every remaining pixel goes to the configuration panel.
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                Layout.minimumWidth: Kirigami.Units.gridUnit * 16
                Layout.maximumWidth: Kirigami.Units.gridUnit * 16
                onAddItemRequested: root.addItemRequested()
            }

            // Right column. It keeps the same Controls.Frame surface as the dock
            // item list so both columns read as equals, and it hosts the note of
            // the selected type. It must stay a note: no editor panel, no
            // configuration write and no second copy of the list.
            Controls.Frame {
                objectName: "itemConfigurationReservedArea"
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: Kirigami.Units.gridUnit * 12

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    Controls.Label {
                        objectName: "itemTypeNote"

                        Layout.fillWidth: true
                        // A Label refuses to shrink below its implicit width by
                        // default, so the whole sentence would stay on one line and
                        // overflow the column. The floor at zero is what lets the
                        // layout narrow the label and the wrap below do its job.
                        Layout.minimumWidth: 0
                        Layout.maximumWidth: Kirigami.Units.gridUnit * 40
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        // The note reads the item behind the selected row directly.
                        // Do not route it through the editor's selectedItemType
                        // cache: that state can lag behind the list selection. The
                        // text is read through a function, which keeps a language
                        // change reachable, and it arrives as styled text because
                        // only its short label is bold: the sentence continues in
                        // normal weight and must still wrap as one paragraph.
                        text: ItemNotes.noteFor(root.selectedNoteType)
                        visible: text.length > 0
                        // The tags that mark the label must not be announced, so the
                        // accessible name carries the words without their markup.
                        Accessible.name: ItemNotes.plainText(text)
                        textFormat: Text.StyledText
                        wrapMode: Text.WordWrap
                    }
                }
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
