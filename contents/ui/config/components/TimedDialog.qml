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
    property alias calendarTimeTextScaleControl: calendarOptions.calendarTimeTextScaleControl
    property alias calendarDateTextScaleControl: calendarOptions.calendarDateTextScaleControl
    property alias calendarTextShadowsControl: calendarOptions.calendarTextShadowsControl
    property alias calendarShowWeekNumbersControl: calendarOptions.calendarShowWeekNumbersControl
    property alias calendarPopupScaleControl: calendarOptions.calendarPopupScaleControl
    property var calendarTextColorControl
    property var calendarBackgroundColorControl
    property var calendarAccentColorControl
    property var calendarBorderColorControl
    property var calendarRadiusControl
    modal: true
    title: timedDialog.controller.selectedConfigureTitle()
    standardButtons: Controls.Dialog.Close
    width: Math.min(timedDialog.controller.width - Kirigami.Units.largeSpacing * 2, Kirigami.Units.gridUnit * 42)
    height: Math.min(timedDialog.controller.height - Kirigami.Units.largeSpacing * 2, timedDialogContent.implicitHeight + Kirigami.Units.gridUnit * 8)

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
                text: i18n("Name:") // qmllint disable unqualified
                horizontalAlignment: Text.AlignLeft
                opacity: 0.75
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Controls.TextField {
                    id: itemName
                    Layout.fillWidth: true
                    enabled: timedDialog.controller.selectedIndex >= 0
                    onEditingFinished: timedDialog.controller.applyItemForm()
                }
            }

            Controls.Label {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                visible: timedDialog.controller.selectedItemType === "clock"
                text: i18n("Item width:") // qmllint disable unqualified
                horizontalAlignment: Text.AlignLeft
                opacity: 0.75
            }

            RowLayout {
                Layout.fillWidth: true
                visible: timedDialog.controller.selectedItemType === "clock"
                enabled: timedDialog.controller.selectedIndex >= 0
                spacing: Kirigami.Units.smallSpacing

                Controls.Label {
                    visible: timedDialog.controller.selectedItemType === "clock"
                    text: i18n("Width:") // qmllint disable unqualified
                    opacity: 0.75
                }

                Controls.SpinBox {
                    id: timedItemWidth
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                    enabled: timedDialog.controller.selectedIndex >= 0
                    from: 0
                    to: 600
                    stepSize: 10
                    textFromValue: function(value) {
                        return value === 0 ? i18n("Automatic") : value + " px" // qmllint disable unqualified
                    }
                    valueFromText: function(text) {
                        return text === i18n("Automatic") ? 0 : Number.fromLocaleString(Qt.locale(), text.replace("px", "")) // qmllint disable unqualified
                    }
                    onValueModified: timedDialog.controller.applyItemForm()

                    Controls.ToolTip.visible: hovered
                    Controls.ToolTip.text: i18n("Item width:") // qmllint disable unqualified
                }

                Controls.Label {
                    visible: false
                    text: i18n("Height:") // qmllint disable unqualified
                    opacity: 0.75
                }

                Controls.SpinBox {
                    id: calendarItemHeight
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                    visible: false
                    enabled: timedDialog.controller.selectedIndex >= 0
                    from: 0
                    to: 600
                    stepSize: 10
                    textFromValue: function(value) {
                        return value === 0 ? i18n("Automatic") : value + " px" // qmllint disable unqualified
                    }
                    valueFromText: function(text) {
                        return text === i18n("Automatic") ? 0 : Number.fromLocaleString(Qt.locale(), text.replace("px", "")) // qmllint disable unqualified
                    }
                    onValueModified: timedDialog.controller.applyItemForm()

                    Controls.ToolTip.visible: hovered
                    Controls.ToolTip.text: i18n("Item height:") // qmllint disable unqualified
                }
            }

            Controls.Label {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                visible: false
                text: i18n("Text scale:") // qmllint disable unqualified
                horizontalAlignment: Text.AlignLeft
                opacity: 0.75
            }

            RowLayout {
                Layout.fillWidth: true
                visible: false
                enabled: timedDialog.controller.selectedIndex >= 0
                spacing: Kirigami.Units.smallSpacing

                Controls.Slider {
                    id: timedTextScale
                    Layout.fillWidth: true
                    from: 0.75
                    to: 1.8
                    stepSize: 0.05
                    snapMode: Controls.Slider.SnapAlways
                    onMoved: timedDialog.controller.applyItemForm()
                    onValueChanged: {
                        if (!timedDialog.controller.syncing) {
                            timedDialog.controller.applyItemForm()
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
        calendarTextColorControl = calendarOptions.calendarTextColorControl
        calendarBackgroundColorControl = calendarOptions.calendarBackgroundColorControl
        calendarAccentColorControl = calendarOptions.calendarAccentColorControl
        calendarBorderColorControl = calendarOptions.calendarBorderColorControl
        calendarRadiusControl = calendarOptions.calendarRadiusControl
    }
}
