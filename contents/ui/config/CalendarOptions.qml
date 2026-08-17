import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import "components"

ColumnLayout {
    id: root

    QtObject {
        id: calendarTextColor

        property string text: ""
    }

    property var controller
    property string calendarDisplayModeValue: "text"
    property var clockColorControl: calendarTextColor
    property alias calendarTextColorControl: calendarTextColor
    property alias calendarFormatControl: calendarFormatCombo
    property alias calendarTimeTextScaleControl: calendarTimeTextScale
    property alias calendarDateTextScaleControl: calendarDateTextScale
    property alias calendarTextShadowsControl: calendarTextShadows
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
        enabled: root.controller.selectedIndex >= 0
        columns: 2
        columnSpacing: Kirigami.Units.smallSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        Controls.Label {
            text: i18n("Format:") // qmllint disable unqualified
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
            onAccepted: root.controller.applyItemForm()
            onActivated: function(index) {
                if (index >= 0 && index < model.length) {
                    editText = model[index]
                }
                root.controller.applyItemForm()
            }
        }

        Controls.Label {
            text: i18n("Time text scale:") // qmllint disable unqualified
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
                enabled: root.controller.selectedIndex >= 0
                onMoved: root.controller.applyItemForm()
                onValueChanged: {
                    if (!root.controller.syncing) {
                        root.controller.applyItemForm()
                    }
                }
                Accessible.name: i18n("Time text scale") // qmllint disable unqualified
            }

            Controls.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 2.8
                horizontalAlignment: Text.AlignRight
                text: Math.round(calendarTimeTextScale.value * 100) + "%"
                opacity: 0.75
            }
        }

        Controls.Label {
            text: i18n("Date text scale:") // qmllint disable unqualified
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
                enabled: root.controller.selectedIndex >= 0
                onMoved: root.controller.applyItemForm()
                onValueChanged: {
                    if (!root.controller.syncing) {
                        root.controller.applyItemForm()
                    }
                }
                Accessible.name: i18n("Date text scale") // qmllint disable unqualified
            }

            Controls.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 2.8
                horizontalAlignment: Text.AlignRight
                text: Math.round(calendarDateTextScale.value * 100) + "%"
                opacity: 0.75
            }
        }

        Controls.CheckBox {
            id: calendarTextShadows
            Layout.columnSpan: 2
            text: i18n("Show shadows on clock and date text") // qmllint disable unqualified
            visible: root.controller.selectedItemType === "calendar"
            enabled: root.controller.selectedIndex >= 0
            onToggled: root.controller.applyItemForm()
        }

        Controls.CheckBox {
            id: calendarShowWeekNumbers
            Layout.columnSpan: 2
            text: i18n("Show week numbers") // qmllint disable unqualified
            enabled: root.controller.selectedIndex >= 0
            onToggled: root.controller.applyItemForm()
            Accessible.name: i18n("Show calendar week numbers") // qmllint disable unqualified
        }

        Controls.Label {
            text: i18n("Popup scale:") // qmllint disable unqualified
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
                enabled: root.controller.selectedIndex >= 0
                onMoved: root.controller.applyItemForm()
                onValueChanged: {
                    if (!root.controller.syncing) {
                        root.controller.applyItemForm()
                    }
                }
                // qmllint disable unqualified
                Accessible.name: i18n("Calendar popup scale")
                Accessible.description: i18n("Adjusts the calendar popup scale between 50 and 300 percent.")
                // qmllint enable unqualified
            }

            Controls.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 2.8
                horizontalAlignment: Text.AlignRight
                text: Math.round(calendarPopupScale.value * 100) + "%"
                opacity: 0.75
            }
        }

        Controls.Label {
            text: i18n("Text color:") // qmllint disable unqualified
            opacity: 0.75
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            ColorModeControl {
                Layout.fillWidth: true
                customColor: root.clockColorControl.text
                fallbackColor: Kirigami.Theme.textColor
                onColorRequested: root.controller.openTimedColorDialog("text")
                onThemeRequested: {
                    root.clockColorControl.text = ""
                    root.controller.applyItemForm()
                }
            }
        }
    }
}
