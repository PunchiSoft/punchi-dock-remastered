import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import "components"

KCM.SimpleKCM {
    id: page
    implicitWidth: layoutMetrics.pageImplicitWidth

    ConfigLayoutMetrics {
        id: layoutMetrics
        availableWidth: page.width
    }

    property alias cfg_showLabels: showLabelsCheck.checked
    property string cfg_indicatorType: "line"
    property string cfg_indicatorPosition: "bottom"
    property alias cfg_indicatorOpacity: indicatorOpacitySlider.value
    property alias cfg_indicatorThickness: indicatorThicknessSlider.value

    readonly property bool interactiveCursorEnabled: !!Plasmoid.configuration.globalMouseCursor
    readonly property bool indicatorPositionApplicable: cfg_indicatorType !== "ring"
        && cfg_indicatorType !== "none"
    readonly property int contentWidthHint: layoutMetrics.contentWidth
    readonly property int selectorWidthHint: layoutMetrics.selectorWidth
    readonly property var indicatorTypeOptions: [
        { "text": i18n("Line"), "value": "line" },
        { "text": i18n("Dot"), "value": "dot" },
        { "text": i18n("Ring"), "value": "ring" },
        { "text": i18n("Rounded square"), "value": "square" },
        { "text": i18n("None"), "value": "none" }
    ]
    readonly property var indicatorPositionOptions: [
        { "text": i18n("Bottom"), "value": "bottom" },
        { "text": i18n("Top"), "value": "top" }
    ]

    component SectionTitle: Kirigami.Heading {
        Layout.fillWidth: true
        level: 3
        leftPadding: 0
    }

    function syncComboValue(combo, value) {
        if (!combo) {
            return
        }

        const resolvedIndex = Math.max(0, combo.indexOfValue(value))
        if (combo.currentIndex !== resolvedIndex) {
            combo.currentIndex = resolvedIndex
        }
    }

    function syncIndicatorSelectors() {
        syncComboValue(indicatorTypeCombo, page.cfg_indicatorType)
        syncComboValue(indicatorPositionCombo, page.cfg_indicatorPosition)
    }

    onCfg_indicatorTypeChanged: syncIndicatorSelectors()
    onCfg_indicatorPositionChanged: syncIndicatorSelectors()
    Component.onCompleted: syncIndicatorSelectors()

    Kirigami.FormLayout {

        SectionTitle {
            Kirigami.FormData.isSection: true
            text: i18n("Labels")
        }

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
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }

        SectionTitle {
            Kirigami.FormData.isSection: true
            text: i18n("Indicator")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Indicator shape:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.ComboBox {
                id: indicatorTypeCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.indicatorTypeOptions
                onActivated: {
                    if (page.cfg_indicatorType !== currentValue) {
                        page.cfg_indicatorType = currentValue
                    }
                }

                ConfigCursorBehavior {
                    active: page.interactiveCursorEnabled
                }
            }
        }

        Controls.Label {
            text: page.cfg_indicatorType === "none"
                ? i18n("Disables the active-window indicator entirely.")
                : page.cfg_indicatorType === "ring"
                    ? i18n("The ring surrounds the icon, so it does not use a top or bottom position.")
                    : i18n("Line, dot and rounded square can be placed at the top or bottom edge of the icon.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Indicator position:")
            Layout.maximumWidth: page.contentWidthHint
            visible: page.indicatorPositionApplicable

            Controls.ComboBox {
                id: indicatorPositionCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.indicatorPositionOptions
                onActivated: {
                    if (page.cfg_indicatorPosition !== currentValue) {
                        page.cfg_indicatorPosition = currentValue
                    }
                }

                ConfigCursorBehavior {
                    active: page.interactiveCursorEnabled
                }
            }
        }

        Controls.Label {
            visible: !page.indicatorPositionApplicable
            text: i18n("Position is not used with the current indicator shape.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Indicator opacity:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.Slider {
                id: indicatorOpacitySlider
                from: 0
                to: 100
                stepSize: 5
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 64

                ConfigCursorBehavior {
                    active: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: Math.round(indicatorOpacitySlider.value) + "%"
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 56
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Indicator size:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.Slider {
                id: indicatorThicknessSlider
                from: 2
                to: 10
                stepSize: 1
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 64

                ConfigCursorBehavior {
                    active: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: Math.round(indicatorThicknessSlider.value) + " px"
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 56
            }
        }
    }
}
