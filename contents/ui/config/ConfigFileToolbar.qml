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
        text: i18n("Configuration file")
        elide: Text.ElideMiddle
        opacity: 0.75

        Controls.ToolTip.visible: configFileMouseArea.containsMouse
        Controls.ToolTip.text: i18n("Dock Items Configuration")
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
        text: i18n("Import...")
        icon.name: "document-import-symbolic"
        onClicked: controller.importJsonRequested()
    }

    Controls.Button {
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        text: i18n("Default")
        icon.name: "edit-reset-symbolic"
        onClicked: controller.prepareDefaultItems()
    }

    Controls.Button {
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        text: i18n("Clean")
        icon.name: "edit-clear-symbolic"
        onClicked: controller.cleanItemsFile()
    }

    Controls.Button {
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        text: i18n("Export...")
        icon.name: "document-export-symbolic"
        onClicked: controller.exportJsonRequested()
    }
}
