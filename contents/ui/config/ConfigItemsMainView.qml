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

    function positionAtIndex(index) {
        itemListEditor.positionAtIndex(index)
    }

    function showStatus(text, type) {
        statusLabel.text = text
        statusLabel.type = type
    }

    function clearStatus() {
        statusLabel.text = ""
    }

    width: Math.max(0, parent.width - Kirigami.Units.smallSpacing * 2)
    height: Math.max(0, parent.height - Kirigami.Units.smallSpacing * 2)
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Kirigami.Units.smallSpacing

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            spacing: Kirigami.Units.largeSpacing

            ColumnLayout {
                Layout.fillWidth: false
                Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                Layout.alignment: Qt.AlignTop
                spacing: Kirigami.Units.smallSpacing

                AddItemPalette {
                    controller: root.controller
                    onAddRequested: function(type) {
                        root.controller.addItem(type)
                    }
                }

                Controls.Label {
                    Layout.fillWidth: true
                    text: i18n("Items to add")
                    opacity: 0.88
                    horizontalAlignment: Text.AlignHCenter
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize
                    font.bold: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: Kirigami.Units.smallSpacing

                DockItemListEditor {
                    id: itemListEditor
                    controller: root.controller
                    itemModel: root.itemModel
                }

                Controls.Label {
                    Layout.fillWidth: true
                    text: i18n("Items in Dock")
                    opacity: 0.88
                    horizontalAlignment: Text.AlignHCenter
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize
                    font.bold: true
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
