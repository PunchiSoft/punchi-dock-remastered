import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: root

    property var controller
    readonly property string separatorAppearanceSourceValue:
        String(separatorAppearanceSourceCombo.currentValue || "theme")
    readonly property bool itemAppearanceSelected:
        separatorAppearanceSourceValue === "item"
    readonly property string separatorStyleValue: String(separatorStyleCombo.currentValue || "")
    readonly property real separatorThicknessValue: separatorThicknessSlider.value
    readonly property real separatorLengthRatioValue: separatorLengthRatioSlider.value
    readonly property real separatorOpacityValue: separatorOpacitySlider.value
    readonly property bool separatorGlowEnabled: separatorGlowCheckBox.checked

    function setSeparatorAppearanceSourceValue(value) {
        separatorAppearanceSourceCombo.currentIndex = Math.max(0,
            separatorAppearanceSourceCombo.indexOfValue(
                value === "item" ? "item" : "theme"))
    }

    function setSeparatorStyleValue(value) {
        separatorStyleCombo.currentIndex = Math.max(0,
            separatorStyleCombo.indexOfValue(value || "line"))
    }

    function setSeparatorThicknessValue(value) {
        if (!separatorThicknessSlider.pressed && separatorThicknessSlider.value !== value) {
            separatorThicknessSlider.value = value
        }
    }

    function setSeparatorLengthRatioValue(value) {
        if (!separatorLengthRatioSlider.pressed && separatorLengthRatioSlider.value !== value) {
            separatorLengthRatioSlider.value = value
        }
    }

    function setSeparatorOpacityValue(value) {
        if (!separatorOpacitySlider.pressed && separatorOpacitySlider.value !== value) {
            separatorOpacitySlider.value = value
        }
    }

    function setSeparatorGlowEnabled(enabled) {
        separatorGlowCheckBox.checked = enabled === true
    }

    spacing: Kirigami.Units.smallSpacing

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Kirigami.Units.smallSpacing

        Controls.Label {
            text: i18n("Appearance:") // qmllint disable unqualified
            opacity: 0.75
        }

        Controls.ComboBox {
            id: separatorAppearanceSourceCombo
            objectName: "separatorAppearanceSourceCombo"
            Layout.fillWidth: true
            textRole: "text"
            valueRole: "value"
            model: [
                { "text": i18n("Dock theme"), "value": "theme" }, // qmllint disable unqualified
                { "text": i18n("This separator"), "value": "item" } // qmllint disable unqualified
            ]
            onActivated: {
                if (root.controller && root.controller.applyItemForm) {
                    root.controller.applyItemForm()
                }
            }
            Accessible.name: i18n("Separator appearance source") // qmllint disable unqualified
        }
    }

    Kirigami.InlineMessage {
        Layout.fillWidth: true
        type: Kirigami.MessageType.Information
        visible: true
        // qmllint disable unqualified
        text: root.itemAppearanceSelected
            ? i18n("Separators help group items on your dock. Shape, size, and glow adapt automatically to your Plasma theme.")
            : i18n("The dock theme controls this separator. Choose This separator to edit its appearance here.")
        // qmllint enable unqualified
    }

    // qmllint disable unqualified
    GridLayout {
        objectName: "separatorAppearanceControls"
        Layout.fillWidth: true
        enabled: root.itemAppearanceSelected
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
                { "text": i18n("Rounded pill"), "value": "capsule" },
                { "text": i18n("Star"), "value": "star" },
                { "text": i18nc("@item:inlistbox Separator shape", "Diamond"), "value": "diamond" },
                { "text": i18nc("@item:inlistbox Separator shape", "Ring"), "value": "ring" },
                { "text": i18nc("@item:inlistbox Separator shape", "Double line"), "value": "doubleLine" },
                { "text": i18nc("@item:inlistbox Separator shape", "Chevron"), "value": "chevron" }
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
