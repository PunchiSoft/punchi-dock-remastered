import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import "components"

KCM.SimpleKCM {
    id: page

    property alias cfg_showLabels: showLabelsCheck.checked
    property string cfg_indicatorType: "line"
    property string cfg_indicatorPosition: "bottom"
    property alias cfg_indicatorOpacity: indicatorOpacitySlider.value
    property alias cfg_indicatorThickness: indicatorThicknessSlider.value

    readonly property bool interactiveCursorEnabled: !!Plasmoid.configuration.globalMouseCursor

    Kirigami.FormLayout {
        Controls.CheckBox {
            id: showLabelsCheck
            Kirigami.FormData.label: i18n("Labels:")
            text: i18n("Show item names in the dock")

            ConfigCursorBehavior {
                active: page.interactiveCursorEnabled
            }
        }

        Controls.Label {
            text: i18n("Labels use a compact single-line style so the dock can remain readable without turning every item into a large card.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            color: Kirigami.Theme.disabledTextColor
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Indicator shape:")

            Controls.ComboBox {
                id: indicatorTypeCombo
                Layout.fillWidth: true
                textRole: "text"
                valueRole: "value"
                model: [
                    { "text": i18n("Line"), "value": "line" },
                    { "text": i18n("Dot"), "value": "dot" },
                    { "text": i18n("Ring"), "value": "ring" },
                    { "text": i18n("Rounded square"), "value": "square" },
                    { "text": i18n("None"), "value": "none" }
                ]
                currentIndex: Math.max(0, indexOfValue(page.cfg_indicatorType))
                onActivated: page.cfg_indicatorType = currentValue

                ConfigCursorBehavior {
                    active: page.interactiveCursorEnabled
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Indicator position:")

            Controls.ComboBox {
                id: indicatorPositionCombo
                Layout.fillWidth: true
                textRole: "text"
                valueRole: "value"
                model: [
                    { "text": i18n("Bottom"), "value": "bottom" },
                    { "text": i18n("Top"), "value": "top" }
                ]
                currentIndex: Math.max(0, indexOfValue(page.cfg_indicatorPosition))
                onActivated: page.cfg_indicatorPosition = currentValue
                enabled: page.cfg_indicatorType !== "ring" && page.cfg_indicatorType !== "none"

                ConfigCursorBehavior {
                    active: page.interactiveCursorEnabled
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Indicator opacity:")

            Controls.Slider {
                id: indicatorOpacitySlider
                from: 0
                to: 100
                stepSize: 5
                Layout.fillWidth: true

                ConfigCursorBehavior {
                    active: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: Math.round(indicatorOpacitySlider.value) + "%"
                Layout.preferredWidth: 52
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Indicator size:")

            Controls.Slider {
                id: indicatorThicknessSlider
                from: 2
                to: 10
                stepSize: 1
                Layout.fillWidth: true

                ConfigCursorBehavior {
                    active: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: Math.round(indicatorThicknessSlider.value) + " px"
                Layout.preferredWidth: 52
            }
        }
    }
}
