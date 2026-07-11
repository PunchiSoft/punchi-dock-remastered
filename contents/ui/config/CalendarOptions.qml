import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: root

    property var controller
    property string calendarDisplayModeValue: "text"
    property var clockColorControl: calendarTextColor
    property alias calendarFormatControl: calendarFormatCombo
    property alias calendarBackgroundColorControl: calendarBackgroundColor
    property alias calendarAccentColorControl: calendarAccentColor
    property alias calendarBorderColorControl: calendarBorderColor
    property alias calendarRadiusControl: calendarRadius

    spacing: Kirigami.Units.smallSpacing

    GridLayout {
        Layout.fillWidth: true
        Layout.columnSpan: 2
        enabled: controller.selectedIndex >= 0
        columns: 2
        columnSpacing: Kirigami.Units.smallSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        Controls.Label {
            text: i18n("Format:")
            opacity: 0.75
        }

        Controls.ComboBox {
            id: calendarFormatCombo
            Layout.fillWidth: true
            editable: true
            model: [
                "HH:mm",
                "HH:mm:ss",
                "hh:mm AP",
                "dd/MM/yyyy",
                "dd/MM/yyyy HH:mm",
                "ddd dd MMM - HH:mm",
                "dddd, d MMMM yyyy"
            ]
            onAccepted: controller.applyItemForm()
            onActivated: function(index) {
                if (index >= 0 && index < model.length) {
                    editText = model[index]
                }
                controller.applyItemForm()
            }
        }

        Controls.Label {
            text: i18n("Text color:")
            opacity: 0.75
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                onClicked: controller.openTimedColorDialog("text")

                contentItem: Rectangle {
                    anchors.centerIn: parent
                    width: Kirigami.Units.gridUnit * 1.35
                    height: width
                    radius: 4
                    color: root.clockColorControl.text.length > 0 ? root.clockColorControl.text : Kirigami.Theme.textColor
                    border.width: 1
                    border.color: Kirigami.Theme.textColor
                    opacity: root.clockColorControl.text.length > 0 ? 1 : 0.55
                }
            }

            Controls.TextField {
                id: calendarTextColor
                Layout.fillWidth: true
                placeholderText: i18n("Use Plasma color")
                onEditingFinished: {
                    controller.applyItemForm()
                }
            }

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                icon.name: "edit-reset-symbolic"
                display: Controls.AbstractButton.IconOnly
                enabled: root.clockColorControl.text.length > 0
                onClicked: {
                    root.clockColorControl.text = ""
                    controller.applyItemForm()
                }

                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: i18n("Plasma theme")
            }
        }

        Controls.Label {
            text: i18n("Background:")
            opacity: 0.75
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                onClicked: controller.openTimedColorDialog("calendarBackground")

                contentItem: Rectangle {
                    anchors.centerIn: parent
                    width: Kirigami.Units.gridUnit * 1.35
                    height: width
                    radius: 4
                    color: calendarBackgroundColor.text.length > 0 ? calendarBackgroundColor.text : Kirigami.Theme.backgroundColor
                    border.width: 1
                    border.color: Kirigami.Theme.textColor
                    opacity: calendarBackgroundColor.text.length > 0 ? 1 : 0.55
                }
            }

            Controls.TextField {
                id: calendarBackgroundColor
                Layout.fillWidth: true
                placeholderText: i18n("Use Plasma color")
                onEditingFinished: controller.applyItemForm()
            }

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                icon.name: "edit-reset-symbolic"
                display: Controls.AbstractButton.IconOnly
                enabled: calendarBackgroundColor.text.length > 0
                onClicked: {
                    calendarBackgroundColor.text = ""
                    controller.applyItemForm()
                }

                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: i18n("Plasma theme")
            }
        }

        Controls.Label {
            text: i18n("Header:")
            opacity: 0.75
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                onClicked: controller.openTimedColorDialog("calendarAccent")

                contentItem: Rectangle {
                    anchors.centerIn: parent
                    width: Kirigami.Units.gridUnit * 1.35
                    height: width
                    radius: 4
                    color: calendarAccentColor.text.length > 0 ? calendarAccentColor.text : Kirigami.Theme.highlightColor
                    border.width: 1
                    border.color: Kirigami.Theme.textColor
                    opacity: calendarAccentColor.text.length > 0 ? 1 : 0.55
                }
            }

            Controls.TextField {
                id: calendarAccentColor
                Layout.fillWidth: true
                placeholderText: i18n("Use Plasma color")
                onEditingFinished: controller.applyItemForm()
            }

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                icon.name: "edit-reset-symbolic"
                display: Controls.AbstractButton.IconOnly
                enabled: calendarAccentColor.text.length > 0
                onClicked: {
                    calendarAccentColor.text = ""
                    controller.applyItemForm()
                }

                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: i18n("Plasma theme")
            }
        }

        Controls.Label {
            text: i18n("Border:")
            opacity: 0.75
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                onClicked: controller.openTimedColorDialog("calendarBorder")

                contentItem: Rectangle {
                    anchors.centerIn: parent
                    width: Kirigami.Units.gridUnit * 1.35
                    height: width
                    radius: 4
                    color: calendarBorderColor.text.length > 0 ? calendarBorderColor.text : "transparent"
                    border.width: 1
                    border.color: Kirigami.Theme.textColor
                    opacity: calendarBorderColor.text.length > 0 ? 1 : 0.55
                }
            }

            Controls.TextField {
                id: calendarBorderColor
                Layout.fillWidth: true
                placeholderText: i18n("None")
                onEditingFinished: controller.applyItemForm()
            }

            Controls.Button {
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                icon.name: "edit-reset-symbolic"
                display: Controls.AbstractButton.IconOnly
                enabled: calendarBorderColor.text.length > 0
                onClicked: {
                    calendarBorderColor.text = ""
                    controller.applyItemForm()
                }

                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: i18n("Plasma theme")
            }
        }

        Controls.Label {
            text: i18n("Radius:")
            opacity: 0.75
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Controls.SpinBox {
                id: calendarRadius
                Layout.fillWidth: true
                from: 0
                to: 48
                textFromValue: function(value) {
                    return value === 0 ? i18n("Automatic") : value + " px"
                }
                valueFromText: function(text) {
                    return text === i18n("Automatic") ? 0 : Number.fromLocaleString(Qt.locale(), text.replace("px", ""))
                }
                onValueModified: controller.applyItemForm()
            }
        }
    }
}
