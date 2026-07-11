import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami


ColumnLayout {
    id: root

    property var controller
    signal addRequested(string type)

    Layout.fillWidth: false
    Layout.preferredWidth: Kirigami.Units.gridUnit * 16
    Layout.minimumWidth: Kirigami.Units.gridUnit * 12
    Layout.preferredHeight: controller.itemsColumnBodyHeight
    Layout.maximumHeight: controller.itemsColumnBodyHeight
    Layout.alignment: Qt.AlignLeft | Qt.AlignTop
    spacing: Kirigami.Units.smallSpacing

    Repeater {
        model: [
            { "type": "app", "title": i18n("Dock item"), "description": i18n("Add an app or container item"), "icon": "application-x-executable" },
            { "type": "note", "title": i18n("Note"), "description": i18n("Write a quick editable note"), "icon": "knotes" },
            { "type": "separator", "title": i18n("Separator"), "description": i18n("Add a visual separator"), "icon": "draw-line" },
            { "type": "spacer", "title": i18n("Spacer"), "description": i18n("Add empty space between items"), "icon": "distribute-horizontal-x" },
            { "type": "calendar", "title": i18n("Calendar/Clock"), "description": i18n("Show date information"), "icon": "x-office-calendar" },
            { "type": "trash", "title": i18n("Trash"), "description": i18n("Open or empty the trash"), "icon": "user-trash" }
        ]

        delegate: Controls.ItemDelegate {
            HoverHandler { cursorShape: Qt.PointingHandCursor }

            Layout.fillWidth: true
            height: Math.max(Kirigami.Units.gridUnit * 3.4, itemRow.implicitHeight + Kirigami.Units.smallSpacing * 2)
            onClicked: root.addRequested(modelData.type)

            contentItem: RowLayout {
                id: itemRow

                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    Layout.alignment: Qt.AlignTop
                    source: modelData.icon
                    isMask: String(modelData.icon).indexOf("-symbolic") >= 0
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    Controls.Label {
                        Layout.fillWidth: true
                        text: modelData.title
                        elide: Text.ElideRight
                    }

                    Controls.Label {
                        Layout.fillWidth: true
                        text: modelData.description
                        opacity: 0.68
                        wrapMode: Text.WordWrap
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                    }
                }
            }

            Controls.ToolTip.visible: hovered
            Controls.ToolTip.text: modelData.title
        }
    }
}
