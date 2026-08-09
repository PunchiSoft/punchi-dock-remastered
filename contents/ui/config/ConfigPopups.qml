import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "components"

Item {
    id: page
    implicitWidth: layoutMetrics.pageImplicitWidth
    implicitHeight: popupColumn.implicitHeight

    ConfigLayoutMetrics {
        id: layoutMetrics
        availableWidth: page.width
    }

    property string previewStyle: "card"
    property real cfg_windowPreviewScale: 1.5
    property alias cfg_windowPreviewBackgroundOpacityPercent: previewBackgroundOpacitySlider.value
    property string cfg_windowPreviewFrameSize: "thin"
    property string cfg_windowPreviewInfoMode: "full"
    property string mediaControlsMode: "none"
    property alias cfg_windowPreviewTextShadowsEnabled: windowPreviewTextShadowsCheck.checked
    property alias cfg_maxPopupRows: maxPopupRowsSpin.value
    property alias cfg_windowPreviewAnimation: windowPreviewAnimationSettings.animationStyle
    property alias cfg_windowPreviewAnimationSpeedPercent: windowPreviewAnimationSettings.animationSpeedPercent
    property alias cfg_windowPreviewAnimationIntensity: windowPreviewAnimationSettings.animationIntensityPercent

    readonly property bool interactiveCursorEnabled:
        !!Plasmoid.configuration.globalMouseCursor
    readonly property int contentWidthHint: layoutMetrics.contentWidth
    readonly property int selectorWidthHint: layoutMetrics.selectorWidth
    // qmllint disable unqualified
    readonly property var previewStyleOptions: [
        { "text": i18n("Cards (recommended)"), "value": "card" },
        { "text": i18n("Window previews"), "value": "thumbnail" },
        { "text": i18n("None"), "value": "none" }
    ]
    // qmllint enable unqualified
    // qmllint disable unqualified
    readonly property var previewInfoOptions: [
        { "text": i18nc("@item:inlistbox Window preview information", "Icon and text"), "value": "full" },
        { "text": i18nc("@item:inlistbox Window preview information", "Icon only"), "value": "icon" },
        { "text": i18nc("@item:inlistbox Window preview information", "Hidden"), "value": "none" }
    ]
    readonly property var previewFrameSizeOptions: [
        { "text": i18nc("@item:inlistbox Window preview background frame", "Thin"), "value": "thin" },
        { "text": i18nc("@item:inlistbox Window preview background frame", "Medium"), "value": "medium" },
        { "text": i18nc("@item:inlistbox Window preview background frame", "Wide"), "value": "wide" }
    ]
    readonly property var mediaControlsModeOptions: {
        const options = [
            { "text": i18nc("@item:inlistbox Media player hover mode", "Replace preview with media card"), "value": "card" },
            { "text": i18nc("@item:inlistbox Media player hover mode", "Replace preview with full cover media card"), "value": "fullCard" }
        ]
        if (previewStyle !== "none") {
            options.push({
                "text": i18nc("@item:inlistbox Media player hover mode", "Show media card below window previews"),
                "value": "overlay"
            })
        }
        options.push({
            "text": i18nc("@item:inlistbox Media player hover mode", "Disabled"), "value": "none"
        })
        return options
    }
    // qmllint enable unqualified
    component SectionTitle: Kirigami.Heading {
        Layout.fillWidth: true
        level: 3
        leftPadding: 0
    }

    signal previewStyleSelected(string style)
    signal mediaControlsModeSelected(string mode)

    function syncComboValue(combo, value) {
        if (!combo || combo.count <= 0) {
            return
        }

        const index = combo.indexOfValue(value)
        if (index >= 0 && combo.currentIndex !== index) {
            combo.currentIndex = index
        }
    }

    function syncSelectors() {
        syncComboValue(previewStyleCombo, page.previewStyle)
        syncComboValue(previewFrameSizeCombo, page.cfg_windowPreviewFrameSize)
        syncComboValue(previewInfoCombo, page.cfg_windowPreviewInfoMode)
        syncComboValue(mediaControlsModeCombo, page.mediaControlsMode)
    }

    function scheduleSelectorSync() {
        Qt.callLater(function() {
            page.syncSelectors()
        })
    }

    onPreviewStyleChanged: scheduleSelectorSync()
    onCfg_windowPreviewFrameSizeChanged: scheduleSelectorSync()
    onCfg_windowPreviewInfoModeChanged: scheduleSelectorSync()
    onMediaControlsModeChanged: scheduleSelectorSync()
    Component.onCompleted: scheduleSelectorSync()

    ColumnLayout {
        id: popupColumn
        anchors.fill: parent
        spacing: 0

        // qmllint disable unqualified
        Kirigami.FormLayout {
            id: popupForm
            Layout.fillWidth: true

        SectionTitle {
            Kirigami.FormData.isSection: true
            text: i18n("Window previews")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Preview popup:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.ComboBox {
                id: previewStyleCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.previewStyleOptions
                onCountChanged: page.scheduleSelectorSync()
                onActivated: {
                    if (page.previewStyle !== currentValue) {
                        page.previewStyleSelected(currentValue)
                    }
                }

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                }
            }
        }

        Controls.Label {
            text: page.previewStyle === "thumbnail"
                ? i18n("Window selectors and hover previews use live thumbnails when the compositor can provide them.")
                : (page.previewStyle === "card"
                    ? i18n("Window selectors and hover previews use cards with the app icon and no live window content.")
                    : i18n("Active applications do not show hover previews or grouped-window popups."))
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Media players:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.ComboBox {
                id: mediaControlsModeCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.mediaControlsModeOptions
                onCountChanged: page.scheduleSelectorSync()
                onActivated: {
                    if (page.mediaControlsMode !== currentValue) {
                        page.mediaControlsModeSelected(currentValue)
                    }
                }

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                }
            }
        }

        Controls.Label {
            text: page.mediaControlsMode === "overlay"
                ? i18n("For MPRIS-compatible applications, displays media playback controls below the window preview list.")
                : (page.mediaControlsMode === "fullCard"
                    ? i18n("For MPRIS-compatible applications, replaces the window preview with a full cover background media card.")
                    : (page.mediaControlsMode === "card"
                        ? i18n("For MPRIS-compatible applications, replaces the window preview with artwork, playback controls, and volume card.")
                        : i18n("Media applications behave like standard windows without showing media controls on hover.")))
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Preview scale:")
            enabled: page.previewStyle !== "none"
            Layout.maximumWidth: page.contentWidthHint

            Controls.Slider {
                id: previewScaleSlider
                from: 1.0
                to: 3.0
                stepSize: 0.05
                value: Math.max(from, Math.min(to,
                    Number(page.cfg_windowPreviewScale || 1.5) / 1.5))
                onMoved: page.cfg_windowPreviewScale = value * 1.5
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 64
                Accessible.name: i18n("Window preview scale")
                Accessible.description: i18n("Adjusts the window preview scale between 100 and 300 percent.")

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: i18n("%1%", Math.round(previewScaleSlider.value * 100))
                font.bold: true
                Layout.preferredWidth: 54
            }
        }

        Controls.Label {
            text: i18n("100 percent uses the recommended base size. Larger previews keep their aspect ratio and remain limited by the available screen space.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
            enabled: page.previewStyle !== "none"
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Background opacity:")
            enabled: page.previewStyle !== "none"
            Layout.maximumWidth: page.contentWidthHint

            Controls.Slider {
                id: previewBackgroundOpacitySlider
                from: 50
                to: 100
                stepSize: 5
                snapMode: Controls.Slider.SnapAlways
                value: 75
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 64
                Accessible.name: i18n("Window preview background opacity")
                Accessible.description: i18n("Only the popup background changes; thumbnails, window content, controls and text remain fully opaque.")

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: i18n("%1%", Math.round(previewBackgroundOpacitySlider.value))
                font.bold: true
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 54
            }
        }

        Controls.Label {
            text: i18n("Only the popup background changes; thumbnails, window content, controls and text remain fully opaque.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
            enabled: page.previewStyle !== "none"
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Background frame:")
            enabled: page.previewStyle !== "none"
            Layout.maximumWidth: page.contentWidthHint

            Controls.ComboBox {
                id: previewFrameSizeCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.previewFrameSizeOptions
                onCountChanged: page.scheduleSelectorSync()
                Accessible.name: i18n("Window preview background frame")
                Accessible.description: i18n("Controls the themed space around window previews without changing their size.")
                onActivated: {
                    if (page.cfg_windowPreviewFrameSize !== currentValue) {
                        page.cfg_windowPreviewFrameSize = currentValue
                    }
                }

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                }
            }
        }

        Controls.Label {
            text: i18n("Controls the themed space around window previews without changing their size.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
            enabled: page.previewStyle !== "none"
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Preview information:")
            enabled: page.previewStyle !== "none"
            Layout.maximumWidth: page.contentWidthHint

            Controls.ComboBox {
                id: previewInfoCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.previewInfoOptions
                onCountChanged: page.scheduleSelectorSync()
                Accessible.name: i18n("Window preview information")
                onActivated: {
                    if (page.cfg_windowPreviewInfoMode !== currentValue) {
                        page.cfg_windowPreviewInfoMode = currentValue
                    }
                }

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                }
            }
        }

        Controls.Label {
            text: i18n("Choose whether window previews show the app icon with window details, only the icon, or no information overlay.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
            enabled: page.previewStyle !== "none"
        }

        Controls.CheckBox {
            id: windowPreviewTextShadowsCheck
            Kirigami.FormData.label: i18n("Text shadows:")
            text: i18n("Show subtle shadows on window preview text")
            enabled: page.previewStyle !== "none"
            Accessible.description: i18n("Applies to window titles, window details and overflow group labels.")

            ConfigCursorBehavior {
                cursorEnabled: page.interactiveCursorEnabled
            }
        }

        Controls.SpinBox {
            id: maxPopupRowsSpin
            Kirigami.FormData.label: i18n("Popup rows:")
            from: 1
            to: 8
            enabled: page.previewStyle !== "none"
            Layout.preferredWidth: page.selectorWidthHint
            Accessible.name: i18n("Maximum visible popup rows")

            ConfigCursorBehavior {
                cursorEnabled: page.interactiveCursorEnabled
            }
        }

        Controls.Label {
            text: i18n("Limits visible popup rows; additional entries remain accessible by scrolling.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
            enabled: page.previewStyle !== "none"
        }

        }
        // qmllint enable unqualified

        PopupAnimationSettings {
            id: windowPreviewAnimationSettings
            Layout.fillWidth: true
            // qmllint disable unqualified
            sectionTitle: i18n("Window preview animation")
            // qmllint enable unqualified
            animationStyle: "slide"
            animationSpeedPercent: 100
            animationIntensityPercent: 100
            contentWidthHint: page.contentWidthHint
            selectorWidthHint: page.selectorWidthHint
            interactiveCursorEnabled: page.interactiveCursorEnabled
        }
    }
}
