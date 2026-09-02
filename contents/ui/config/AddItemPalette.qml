import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami


ColumnLayout {
    id: root

    // Translation helpers and controller delegates are supplied by the QML context.
    // qmllint disable unqualified

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
            { "type": "punchimenu", "title": i18n("PunchiMenu"), "description": i18n("Open application menu & carousel"), "icon": "start-here-kde" },
            { "type": "control-center", "title": i18n("Control Center"), "description": i18n("Open system controls and notifications"), "icon": "preferences-system" },
            { "type": "app", "title": i18n("Dock item"), "description": i18n("Add an app or container item"), "icon": "application-x-executable" },
            { "type": "dynamic-applications", "title": i18n("Open applications"), "description": i18n("Choose where open apps appear"), "icon": "window-duplicate" },
            { "type": "note", "title": i18n("Note"), "description": i18n("Write a quick editable note"), "icon": "knotes" },
            { "type": "separator", "title": i18n("Separator"), "description": i18n("Add a visual separator"), "icon": "draw-line" },
            { "type": "spacer", "title": i18n("Spacer"), "description": i18n("Add empty space between items"), "icon": "distribute-horizontal-x" },
            { "type": "calendar", "title": i18n("Calendar/Clock"), "description": i18n("Show date information"), "icon": "x-office-calendar" },
            { "type": "media", "title": i18n("Media player"), "description": i18n("Automatically select the active player"), "icon": "emblem-music-symbolic" },
            { "type": "trash", "title": i18n("Trash"), "description": i18n("Open or empty the trash"), "icon": "user-trash" }
        ]

        delegate: Controls.ItemDelegate {
            HoverHandler { cursorShape: Qt.PointingHandCursor }

            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.8
            Layout.minimumHeight: Layout.preferredHeight
            Layout.maximumHeight: Layout.preferredHeight
            enabled: (modelData.type !== "media" || !root.controller.hasItemType("media"))
                && (modelData.type !== "punchimenu" || !root.controller.hasItemType("punchimenu"))
                && (modelData.type !== "control-center"
                    || !root.controller.hasItemType("control-center"))
                && (modelData.type !== "dynamic-applications"
                    || !root.controller.hasItemType("dynamic-applications"))
            onClicked: root.addRequested(modelData.type)
            Accessible.name: modelData.title
            Accessible.description: modelData.description

            contentItem: RowLayout {
                id: itemRow

                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    Layout.alignment: Qt.AlignVCenter
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
                        maximumLineCount: 1
                        wrapMode: Text.NoWrap
                        elide: Text.ElideRight
                    }

                    Controls.Label {
                        Layout.fillWidth: true
                        text: modelData.description
                        opacity: 0.68
                        maximumLineCount: 1
                        wrapMode: Text.NoWrap
                        elide: Text.ElideRight
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                    }
                }
            }

            Controls.ToolTip.visible: hovered
            Controls.ToolTip.text: {
                if (enabled) {
                    return modelData.description
                }
                if (modelData.type === "punchimenu") {
                    return i18n("Only one PunchiMenu item can be added.")
                }
                if (modelData.type === "dynamic-applications") {
                    return i18n("Only one open applications item can be added.")
                }
                if (modelData.type === "control-center") {
                    return i18n("Only one Control Center item can be added.")
                }
                return i18n("Only one media player item can be added.")
            }
        }
    }
}
// qmllint enable unqualified
