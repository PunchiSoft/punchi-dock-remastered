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

    property string cfg_windowPreviewStyle: "card"
    // Persist the geometric factor so existing 1.5 configurations become the
    // normalized 1.0 user-facing size without a migration.
    property real cfg_windowPreviewScale: 1.5
    property string cfg_windowPreviewInfoMode: "full"
    property alias cfg_windowPreviewTextShadowsEnabled: windowPreviewTextShadowsCheck.checked
    property alias cfg_mediaControlsOnHover: mediaControlsOnHoverCheck.checked
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

    function syncSelectors() {
        syncComboValue(previewStyleCombo, page.cfg_windowPreviewStyle)
        syncComboValue(previewInfoCombo, page.cfg_windowPreviewInfoMode)
    }

    onCfg_windowPreviewStyleChanged: syncSelectors()
    onCfg_windowPreviewInfoModeChanged: syncSelectors()
    Component.onCompleted: syncSelectors()

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
                onActivated: {
                    if (page.cfg_windowPreviewStyle !== currentValue) {
                        page.cfg_windowPreviewStyle = currentValue
                    }
                }

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                }
            }
        }

        Controls.Label {
            text: page.cfg_windowPreviewStyle === "thumbnail"
                ? i18n("Window selectors and hover previews use live thumbnails when the compositor can provide them.")
                : (page.cfg_windowPreviewStyle === "card"
                    ? i18n("Window selectors and hover previews use cards with the app icon and no live window content.")
                    : i18n("Active applications do not show hover previews or grouped-window popups."))
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }

        Controls.CheckBox {
            id: mediaControlsOnHoverCheck
            Kirigami.FormData.label: i18n("Media players:")
            text: i18n("Show media controls on hover when available")

            ConfigCursorBehavior {
                cursorEnabled: page.interactiveCursorEnabled
            }
        }

        Controls.Label {
            text: i18n("For MPRIS-compatible applications, replaces the window preview with artwork, playback controls, and volume. Right-click shows compact media controls above the application actions.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
            enabled: mediaControlsOnHoverCheck.checked
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Preview size:")
            enabled: page.cfg_windowPreviewStyle !== "none"
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
                Accessible.name: i18n("Window preview size")

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: previewScaleSlider.value.toFixed(2) + "x"
                font.bold: true
                Layout.preferredWidth: 54
            }
        }

        Controls.Label {
            text: i18n("1.00x uses the recommended base size. Larger previews keep their aspect ratio and remain limited by the available screen space.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
            enabled: page.cfg_windowPreviewStyle !== "none"
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Preview information:")
            enabled: page.cfg_windowPreviewStyle !== "none"
            Layout.maximumWidth: page.contentWidthHint

            Controls.ComboBox {
                id: previewInfoCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.previewInfoOptions
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
            enabled: page.cfg_windowPreviewStyle !== "none"
        }

        Controls.CheckBox {
            id: windowPreviewTextShadowsCheck
            Kirigami.FormData.label: i18n("Text shadows:")
            text: i18n("Show subtle shadows on window preview text")
            enabled: page.cfg_windowPreviewStyle !== "none"
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
            enabled: page.cfg_windowPreviewStyle !== "none"
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
            enabled: page.cfg_windowPreviewStyle !== "none"
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
