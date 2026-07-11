import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import ".."

Controls.Dialog {
    id: timedDialog

    property var controller
    property alias itemNameControl: itemName
    property alias timedItemWidthControl: timedItemWidth
    property alias timedTextScaleControl: timedTextScale
    property alias calendarItemHeightControl: calendarItemHeight
    property alias calendarFormatControl: calendarOptions.calendarFormatControl
    property var calendarBackgroundColorControl
    property var calendarAccentColorControl
    property var calendarBorderColorControl
    property var calendarRadiusControl
    modal: true
    title: controller.selectedConfigureTitle()
    standardButtons: Controls.Dialog.Close
    width: Math.min(controller.width - Kirigami.Units.largeSpacing * 2, Kirigami.Units.gridUnit * 42)
    height: Math.min(controller.height - Kirigami.Units.largeSpacing * 2, timedDialogContent.implicitHeight + Kirigami.Units.gridUnit * 8)

    ColumnLayout {
        id: timedDialogContent
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.smallSpacing

            Controls.Label {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                text: i18n("Name:")
                horizontalAlignment: Text.AlignLeft
                opacity: 0.75
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Controls.TextField {
                    id: itemName
                    Layout.fillWidth: true
                    enabled: controller.selectedIndex >= 0
                    onEditingFinished: controller.applyItemForm()
                }
            }

            Controls.Label {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                visible: controller.selectedItemType === "calendar"
                text: i18n("Item size:")
                horizontalAlignment: Text.AlignLeft
                opacity: 0.75
            }

            RowLayout {
                Layout.fillWidth: true
                visible: controller.selectedItemType === "calendar"
                enabled: controller.selectedIndex >= 0
                spacing: Kirigami.Units.smallSpacing

                Controls.Label {
                    visible: controller.selectedItemType === "calendar"
                    text: i18n("Width:")
                    opacity: 0.75
                }

                Controls.SpinBox {
                    id: timedItemWidth
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                    enabled: controller.selectedIndex >= 0
                    from: 0
                    to: 600
                    stepSize: 10
                    textFromValue: function(value) {
                        return value === 0 ? i18n("Automatic") : value + " px"
                    }
                    valueFromText: function(text) {
                        return text === i18n("Automatic") ? 0 : Number.fromLocaleString(Qt.locale(), text.replace("px", ""))
                    }
                    onValueModified: controller.applyItemForm()

                    Controls.ToolTip.visible: hovered
                    Controls.ToolTip.text: i18n("Item width:")
                }

                Controls.Label {
                    visible: controller.selectedItemType === "calendar"
                    text: i18n("Height:")
                    opacity: 0.75
                }

                Controls.SpinBox {
                    id: calendarItemHeight
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                    visible: controller.selectedItemType === "calendar"
                    enabled: controller.selectedIndex >= 0
                    from: 0
                    to: 600
                    stepSize: 10
                    textFromValue: function(value) {
                        return value === 0 ? i18n("Automatic") : value + " px"
                    }
                    valueFromText: function(text) {
                        return text === i18n("Automatic") ? 0 : Number.fromLocaleString(Qt.locale(), text.replace("px", ""))
                    }
                    onValueModified: controller.applyItemForm()

                    Controls.ToolTip.visible: hovered
                    Controls.ToolTip.text: i18n("Item height:")
                }
            }

            Controls.Label {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                visible: controller.selectedItemType === "calendar"
                text: i18n("Text scale:")
                horizontalAlignment: Text.AlignLeft
                opacity: 0.75
            }

            RowLayout {
                Layout.fillWidth: true
                visible: controller.selectedItemType === "calendar"
                enabled: controller.selectedIndex >= 0
                spacing: Kirigami.Units.smallSpacing

                Controls.Slider {
                    id: timedTextScale
                    Layout.fillWidth: true
                    from: 0.75
                    to: 1.8
                    stepSize: 0.05
                    snapMode: Controls.Slider.SnapAlways
                    onMoved: controller.applyItemForm()
                    onValueChanged: {
                        if (!controller.syncing) {
                            controller.applyItemForm()
                        }
                    }
                }

                Controls.Label {
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 2.6
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(timedTextScale.value * 100) + "%"
                    opacity: 0.75
                }
            }

            CalendarOptions {
                id: calendarOptions
                Layout.fillWidth: true
                Layout.columnSpan: 2
                controller: timedDialog.controller
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
        }
    }
    Component.onCompleted: {
        calendarBackgroundColorControl = calendarOptions.calendarBackgroundColorControl
        calendarAccentColorControl = calendarOptions.calendarAccentColorControl
        calendarBorderColorControl = calendarOptions.calendarBorderColorControl
        calendarRadiusControl = calendarOptions.calendarRadiusControl
    }
}
