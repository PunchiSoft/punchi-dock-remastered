import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: root

    property var controller
    property alias separatorStyleControl: separatorStyleCombo
    property alias separatorThicknessControl: separatorThicknessSlider
    property alias separatorLengthRatioControl: separatorLengthRatioSlider
    property alias separatorOpacityControl: separatorOpacitySlider
    property alias separatorGlowControl: separatorGlowCheckBox

    spacing: Kirigami.Units.smallSpacing

    Kirigami.InlineMessage {
        Layout.fillWidth: true
        type: Kirigami.MessageType.Information
        visible: true
        text: i18n("Separators help group items on your dock. Shape, size, and glow adapt automatically to your Plasma theme.")
    }

    // qmllint disable unqualified
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Kirigami.Units.smallSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        Controls.Label {
            text: i18n("Shape:")
            opacity: 0.75
        }

        Controls.ComboBox {
            id: separatorStyleCombo
            Layout.fillWidth: true
            textRole: "text"
            valueRole: "value"
            model: [
                { "text": i18n("Line"), "value": "line" },
                { "text": i18n("Circle"), "value": "dot" },
                { "text": i18n("Square"), "value": "square" },
                { "text": i18n("Rounded pill"), "value": "pill" },
                { "text": i18n("Star"), "value": "star" }
            ]
            onActivated: {
                if (controller && controller.applyItemForm) {
                    controller.applyItemForm()
                }
            }
        }

        Controls.Label {
            text: i18n("Thickness:")
            opacity: 0.75
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Controls.Slider {
                id: separatorThicknessSlider
                Layout.fillWidth: true
                from: 1
                to: 16
                stepSize: 1
                snapMode: Controls.Slider.SnapAlways
                onMoved: {
                    if (controller && controller.applyItemForm) {
                        controller.applyItemForm()
                    }
                }
                onValueChanged: {
                    if (controller && !controller.syncing && controller.applyItemForm) {
                        controller.applyItemForm()
                    }
                }
                Accessible.name: i18n("Separator thickness")
            }

            Controls.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 2.8
                horizontalAlignment: Text.AlignRight
                text: Math.round(separatorThicknessSlider.value) + " px"
                opacity: 0.75
            }
        }

        Controls.Label {
            text: i18n("Length:")
            opacity: 0.75
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Controls.Slider {
                id: separatorLengthRatioSlider
                Layout.fillWidth: true
                from: 0.20
                to: 1.00
                stepSize: 0.05
                snapMode: Controls.Slider.SnapAlways
                onMoved: {
                    if (controller && controller.applyItemForm) {
                        controller.applyItemForm()
                    }
                }
                onValueChanged: {
                    if (controller && !controller.syncing && controller.applyItemForm) {
                        controller.applyItemForm()
                    }
                }
                Accessible.name: i18n("Separator length ratio")
            }

            Controls.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 2.8
                horizontalAlignment: Text.AlignRight
                text: Math.round(separatorLengthRatioSlider.value * 100) + "%"
                opacity: 0.75
            }
        }

        Controls.Label {
            text: i18n("Opacity:")
            opacity: 0.75
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Controls.Slider {
                id: separatorOpacitySlider
                Layout.fillWidth: true
                from: 0.10
                to: 1.00
                stepSize: 0.05
                snapMode: Controls.Slider.SnapAlways
                onMoved: {
                    if (controller && controller.applyItemForm) {
                        controller.applyItemForm()
                    }
                }
                onValueChanged: {
                    if (controller && !controller.syncing && controller.applyItemForm) {
                        controller.applyItemForm()
                    }
                }
                Accessible.name: i18n("Separator opacity")
            }

            Controls.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 2.8
                horizontalAlignment: Text.AlignRight
                text: Math.round(separatorOpacitySlider.value * 100) + "%"
                opacity: 0.75
            }
        }

        Controls.CheckBox {
            id: separatorGlowCheckBox
            Layout.columnSpan: 2
            text: i18n("Enable subtle glow effect")
            onToggled: {
                if (controller && controller.applyItemForm) {
                    controller.applyItemForm()
                }
            }
            Accessible.name: i18n("Enable separator glow effect")
        }
    }
    // qmllint enable unqualified
}
