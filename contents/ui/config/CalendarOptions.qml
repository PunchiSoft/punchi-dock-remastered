import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: root

    property var controller
    property string calendarDisplayModeValue: "text"
    property var clockColorControl: calendarTextColor
    property alias calendarTextColorControl: calendarTextColor
    property alias calendarFormatControl: calendarFormatCombo
    property alias calendarTimeTextScaleControl: calendarTimeTextScale
    property alias calendarDateTextScaleControl: calendarDateTextScale
    property alias calendarShowWeekNumbersControl: calendarShowWeekNumbers
    property alias calendarPopupScaleControl: calendarPopupScale
    property var calendarBackgroundColorControl: null
    property var calendarAccentColorControl: null
    property var calendarBorderColorControl: null
    property var calendarRadiusControl: null

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
            text: i18n("Time text scale:")
            opacity: 0.75
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Controls.Slider {
                id: calendarTimeTextScale
                Layout.fillWidth: true
                from: 0.75
                to: 2.0
                stepSize: 0.05
                snapMode: Controls.Slider.SnapAlways
                enabled: controller.selectedIndex >= 0
                onMoved: controller.applyItemForm()
                onValueChanged: {
                    if (!controller.syncing) {
                        controller.applyItemForm()
                    }
                }
                Accessible.name: i18n("Time text scale")
            }

            Controls.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 2.8
                horizontalAlignment: Text.AlignRight
                text: Math.round(calendarTimeTextScale.value * 100) + "%"
                opacity: 0.75
            }
        }

        Controls.Label {
            text: i18n("Date text scale:")
            opacity: 0.75
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Controls.Slider {
                id: calendarDateTextScale
                Layout.fillWidth: true
                from: 0.75
                to: 2.0
                stepSize: 0.05
                snapMode: Controls.Slider.SnapAlways
                enabled: controller.selectedIndex >= 0
                onMoved: controller.applyItemForm()
                onValueChanged: {
                    if (!controller.syncing) {
                        controller.applyItemForm()
                    }
                }
                Accessible.name: i18n("Date text scale")
            }

            Controls.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 2.8
                horizontalAlignment: Text.AlignRight
                text: Math.round(calendarDateTextScale.value * 100) + "%"
                opacity: 0.75
            }
        }

        Controls.CheckBox {
            id: calendarShowWeekNumbers
            Layout.columnSpan: 2
            text: i18n("Show week numbers")
            enabled: controller.selectedIndex >= 0
            onToggled: controller.applyItemForm()
            Accessible.name: i18n("Show calendar week numbers")
        }

        Controls.Label {
            text: i18n("Popup scale:")
            opacity: 0.75
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Controls.Slider {
                id: calendarPopupScale
                Layout.fillWidth: true
                from: 0.5
                to: 3.0
                stepSize: 0.05
                snapMode: Controls.Slider.SnapAlways
                enabled: controller.selectedIndex >= 0
                onMoved: controller.applyItemForm()
                onValueChanged: {
                    if (!controller.syncing) {
                        controller.applyItemForm()
                    }
                }
                Accessible.name: i18n("Calendar popup scale")
            }

            Controls.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 2.8
                horizontalAlignment: Text.AlignRight
                text: (Math.round(calendarPopupScale.value * 100) / 100) + "x"
                opacity: 0.75
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
    }
}
