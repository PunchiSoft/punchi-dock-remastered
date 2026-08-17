import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

RowLayout {
    id: root

    property var controller

    Layout.fillWidth: true

    Controls.Label {
        id: configFileLabel
        Layout.fillWidth: true
        text: i18n("Configuration file") // qmllint disable unqualified
        elide: Text.ElideMiddle
        opacity: 0.75

        Controls.ToolTip.visible: configFileMouseArea.containsMouse
        Controls.ToolTip.text: i18n("Dock Items Configuration") // qmllint disable unqualified
        Controls.ToolTip.delay: Kirigami.Units.toolTipDelay

        MouseArea {
            id: configFileMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }

    Controls.Button {
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        text: i18n("Import...") // qmllint disable unqualified
        icon.name: "document-import-symbolic"
        onClicked: root.controller.importJsonRequested()
    }

    Controls.Button {
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        text: i18n("Default") // qmllint disable unqualified
        icon.name: "edit-reset-symbolic"
        onClicked: root.controller.prepareDefaultItems()
    }

    Controls.Button {
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        text: i18n("Clean") // qmllint disable unqualified
        icon.name: "edit-clear-symbolic"
        onClicked: root.controller.cleanItemsFile()
    }

    Controls.Button {
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        text: i18n("Export...") // qmllint disable unqualified
        icon.name: "document-export-symbolic"
        onClicked: root.controller.exportJsonRequested()
    }
}
