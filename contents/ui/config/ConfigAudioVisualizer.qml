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

    property alias cfg_audioSpectrumEnabled: audioSpectrumCheck.checked
    property alias cfg_audioSpectrumIntensity: audioSpectrumIntensitySlider.value
    property alias cfg_audioSpectrumUsePlasmaTheme: audioSpectrumPlasmaThemeCheck.checked
    property int cfg_audioSpectrumBarCount: 12
    property string cfg_audioSpectrumStyle: "edge"
    property string cfg_audioSpectrumBackgroundMode: "plasma"
    property string cfg_audioSpectrumOrigin: "bottom"
    property string cfg_audioSpectrumFlow: "none"

    readonly property bool interactiveCursorEnabled:
        !!Plasmoid.configuration.globalMouseCursor
    readonly property bool audioSpectrumUsesAbstractElements:
        page.cfg_audioSpectrumStyle === "cloud"
        || page.cfg_audioSpectrumStyle === "particles"
    readonly property int contentWidthHint: layoutMetrics.contentWidth
    readonly property int selectorWidthHint: layoutMetrics.selectorWidth

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

    function syncComboValue(combo, value) {
        if (!combo) {
            return
        }

        const resolvedIndex = Math.max(0, combo.indexOfValue(value))
        if (combo.currentIndex !== resolvedIndex) {
            combo.currentIndex = resolvedIndex
        }
    }

    function syncAudioSpectrumSelectors() {
        syncComboValue(audioSpectrumBarCountCombo,
            page.cfg_audioSpectrumBarCount)
        syncComboValue(audioSpectrumStyleCombo, page.cfg_audioSpectrumStyle)
        syncComboValue(audioSpectrumBackgroundCombo,
            page.cfg_audioSpectrumBackgroundMode)
        syncComboValue(audioSpectrumOriginCombo, page.cfg_audioSpectrumOrigin)
        syncComboValue(audioSpectrumFlowCombo, page.cfg_audioSpectrumFlow)
    }

    onCfg_audioSpectrumBarCountChanged: syncAudioSpectrumSelectors()
    onCfg_audioSpectrumStyleChanged: syncAudioSpectrumSelectors()
    onCfg_audioSpectrumBackgroundModeChanged: syncAudioSpectrumSelectors()
    onCfg_audioSpectrumOriginChanged: syncAudioSpectrumSelectors()
    onCfg_audioSpectrumFlowChanged: syncAudioSpectrumSelectors()
    Component.onCompleted: syncAudioSpectrumSelectors()

    // qmllint disable unqualified
    Kirigami.FormLayout {
        Controls.CheckBox {
            id: audioSpectrumCheck
            Kirigami.FormData.label: i18n("Visualizer:")
            text: i18n("Enable the audio visualizer")

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
                Accessible.name: i18n("Audio visualizer dock background")
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
            enabled: audioSpectrumCheck.checked
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
                Accessible.name: i18n("Audio visualizer intensity")

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
            enabled: audioSpectrumCheck.checked
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
                Accessible.name: page.audioSpectrumUsesAbstractElements
                    ? i18n("Audio visualizer density")
                    : i18n("Number of audio visualizer bars")
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
                Accessible.name: i18n("Audio visualizer style")
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
                Accessible.name: i18n("Audio visualizer rhythmic movement")
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
                && ["edge", "capsules", "pixel", "particles"].indexOf(
                    page.cfg_audioSpectrumStyle) >= 0

            Controls.ComboBox {
                id: audioSpectrumOriginCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.audioSpectrumOriginOptions
                Accessible.name: i18n("Audio visualizer edge direction")
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
    }
    // qmllint enable unqualified
}
