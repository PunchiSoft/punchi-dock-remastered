import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
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
    property alias cfg_audioSpectrumEnabled: audioSpectrumCheck.checked
    property alias cfg_audioSpectrumIntensity: audioSpectrumIntensitySlider.value
    property alias cfg_audioSpectrumUsePlasmaTheme: audioSpectrumPlasmaThemeCheck.checked
    property int cfg_audioSpectrumBarCount: 12
    property string cfg_audioSpectrumStyle: "edge"
    property string cfg_audioSpectrumBackgroundMode: "plasma"
    property string cfg_audioSpectrumOrigin: "bottom"
    property string cfg_audioSpectrumFlow: "none"

    readonly property bool interactiveCursorEnabled: !!Plasmoid.configuration.globalMouseCursor
    readonly property bool indicatorPositionApplicable: cfg_indicatorType !== "ring"
        && cfg_indicatorType !== "none"
    readonly property bool audioSpectrumUsesAbstractElements: cfg_audioSpectrumStyle === "cloud"
        || cfg_audioSpectrumStyle === "particles"
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
    // qmllint disable unqualified
    readonly property var audioSpectrumBarCountOptions: [
        { "text": i18n("8 bars"), "value": 8 },
        { "text": i18n("12 bars"), "value": 12 },
        { "text": i18n("16 bars"), "value": 16 },
        { "text": i18n("24 bars"), "value": 24 },
        { "text": i18n("32 bars"), "value": 32 },
        { "text": i18n("48 bars"), "value": 48 }
    ]
    readonly property var audioSpectrumDensityOptions: [
        { "text": "8", "value": 8 },
        { "text": "12", "value": 12 },
        { "text": "16", "value": 16 },
        { "text": "24", "value": 24 },
        { "text": "32", "value": 32 },
        { "text": "48", "value": 48 }
    ]
    readonly property var audioSpectrumStyleOptions: [
        { "text": i18n("From the edge"), "value": "edge" },
        { "text": i18n("Centered wave"), "value": "centered" },
        { "text": i18n("Floating capsules"), "value": "capsules" },
        { "text": i18n("Pixel spectrum"), "value": "pixel" },
        { "text": i18n("Luminous cloud"), "value": "cloud" },
        { "text": i18n("Reactive particles"), "value": "particles" }
    ]
    readonly property var audioSpectrumBackgroundOptions: [
        { "text": i18n("Over the Plasma background"), "value": "plasma" },
        { "text": i18n("Spectrum only, without background"), "value": "spectrumOnly" }
    ]
    readonly property var audioSpectrumOriginOptions: [
        { "text": i18n("Bottom to top"), "value": "bottom" },
        { "text": i18n("Top to bottom"), "value": "top" }
    ]
    readonly property var audioSpectrumFlowOptions: [
        { "text": i18n("No movement"), "value": "none" },
        { "text": i18n("Flow to the left"), "value": "left" },
        { "text": i18n("Flow to the right"), "value": "right" }
    ]
    // qmllint enable unqualified

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

    function syncAudioSpectrumSelectors() {
        syncComboValue(audioSpectrumBarCountCombo, page.cfg_audioSpectrumBarCount)
        syncComboValue(audioSpectrumStyleCombo, page.cfg_audioSpectrumStyle)
        syncComboValue(audioSpectrumBackgroundCombo, page.cfg_audioSpectrumBackgroundMode)
        syncComboValue(audioSpectrumOriginCombo, page.cfg_audioSpectrumOrigin)
        syncComboValue(audioSpectrumFlowCombo, page.cfg_audioSpectrumFlow)
    }

    onCfg_indicatorTypeChanged: syncIndicatorSelectors()
    onCfg_indicatorPositionChanged: syncIndicatorSelectors()
    onCfg_audioSpectrumBarCountChanged: syncAudioSpectrumSelectors()
    onCfg_audioSpectrumStyleChanged: syncAudioSpectrumSelectors()
    onCfg_audioSpectrumBackgroundModeChanged: syncAudioSpectrumSelectors()
    onCfg_audioSpectrumOriginChanged: syncAudioSpectrumSelectors()
    onCfg_audioSpectrumFlowChanged: syncAudioSpectrumSelectors()
    Component.onCompleted: {
        syncIndicatorSelectors()
        syncAudioSpectrumSelectors()
    }

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
                cursorEnabled: page.interactiveCursorEnabled
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

        // qmllint disable unqualified
        Controls.CheckBox {
            id: audioSpectrumCheck
            Kirigami.FormData.isSection: true
            text: i18n("Audio visualizer")
            font.bold: true

            ConfigCursorBehavior {
                cursorEnabled: page.interactiveCursorEnabled
            }
        }

        Kirigami.InlineMessage {
            visible: true
            type: Kirigami.MessageType.Warning
            text: i18n("Privacy notice: Punchi Dock monitors the system output mix only while the audio visualizer is enabled. It does not select the microphone, record or store audio samples, or send audio over the network. Plasma may still show a recording indicator because output monitoring uses an input audio stream.")
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Dock background:")
            Layout.maximumWidth: page.contentWidthHint
            enabled: audioSpectrumCheck.checked

            Controls.ComboBox {
                id: audioSpectrumBackgroundCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.audioSpectrumBackgroundOptions
                onActivated: {
                    if (page.cfg_audioSpectrumBackgroundMode !== currentValue) {
                        page.cfg_audioSpectrumBackgroundMode = currentValue
                    }
                }

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                }
            }
        }

        Controls.Label {
            text: page.cfg_audioSpectrumBackgroundMode === "spectrumOnly"
                ? i18n("In floating mode, only the spectrum and dock items remain visible. A Plasma panel keeps its own background.")
                : i18n("The spectrum is drawn over the Plasma-themed dock background.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Visualizer intensity:")
            Layout.maximumWidth: page.contentWidthHint
            enabled: audioSpectrumCheck.checked

            Controls.Slider {
                id: audioSpectrumIntensitySlider
                from: 10
                to: 60
                stepSize: 5
                snapMode: Controls.Slider.SnapAlways
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 64

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: Math.round(audioSpectrumIntensitySlider.value) + "%"
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 56
            }
        }

        Controls.CheckBox {
            id: audioSpectrumPlasmaThemeCheck
            Kirigami.FormData.label: i18n("EQ theme:")
            text: i18n("Use Plasma theme colors")
            enabled: audioSpectrumCheck.checked

            ConfigCursorBehavior {
                cursorEnabled: page.interactiveCursorEnabled
            }
        }

        Controls.Label {
            text: audioSpectrumPlasmaThemeCheck.checked
                ? i18n("Visualizer elements use Plasma's highlight color.")
                : i18n("Visualizer elements use dynamic colors that react to each frequency level.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }

        RowLayout {
            Kirigami.FormData.label: page.audioSpectrumUsesAbstractElements
                ? i18n("Visual density:")
                : i18n("Number of bars:")
            Layout.maximumWidth: page.contentWidthHint
            enabled: audioSpectrumCheck.checked

            Controls.ComboBox {
                id: audioSpectrumBarCountCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.audioSpectrumUsesAbstractElements
                    ? page.audioSpectrumDensityOptions
                    : page.audioSpectrumBarCountOptions
                onActivated: {
                    if (page.cfg_audioSpectrumBarCount !== currentValue) {
                        page.cfg_audioSpectrumBarCount = currentValue
                    }
                }

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Visualizer style:")
            Layout.maximumWidth: page.contentWidthHint
            enabled: audioSpectrumCheck.checked

            Controls.ComboBox {
                id: audioSpectrumStyleCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.audioSpectrumStyleOptions
                onActivated: {
                    if (page.cfg_audioSpectrumStyle !== currentValue) {
                        page.cfg_audioSpectrumStyle = currentValue
                    }
                }

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Rhythmic movement:")
            Layout.maximumWidth: page.contentWidthHint
            enabled: audioSpectrumCheck.checked

            Controls.ComboBox {
                id: audioSpectrumFlowCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.audioSpectrumFlowOptions
                onActivated: {
                    if (page.cfg_audioSpectrumFlow !== currentValue) {
                        page.cfg_audioSpectrumFlow = currentValue
                    }
                }

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Edge direction:")
            Layout.maximumWidth: page.contentWidthHint
            enabled: audioSpectrumCheck.checked
                && ["edge", "capsules", "pixel", "particles"].indexOf(page.cfg_audioSpectrumStyle) >= 0

            Controls.ComboBox {
                id: audioSpectrumOriginCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.audioSpectrumOriginOptions
                onActivated: {
                    if (page.cfg_audioSpectrumOrigin !== currentValue) {
                        page.cfg_audioSpectrumOrigin = currentValue
                    }
                }

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                }
            }
        }
        // qmllint enable unqualified

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
                    cursorEnabled: page.interactiveCursorEnabled
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
                    cursorEnabled: page.interactiveCursorEnabled
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
                    cursorEnabled: page.interactiveCursorEnabled
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
                    cursorEnabled: page.interactiveCursorEnabled
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
