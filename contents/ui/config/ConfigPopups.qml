import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "components"

Item {
    id: page
    implicitWidth: layoutMetrics.pageImplicitWidth
    implicitHeight: popupForm.implicitHeight

    ConfigLayoutMetrics {
        id: layoutMetrics
        availableWidth: page.width
    }

    property string cfg_windowPreviewStyle: "card"
    // Persist the geometric factor so existing 1.5 configurations become the
    // normalized 1.0 user-facing size without a migration.
    property real cfg_windowPreviewScale: 1.5
    property alias cfg_mediaControlsOnHover: mediaControlsOnHoverCheck.checked
    property alias cfg_taskPopupRadiusAuto: taskPopupRadiusAutoCheck.checked
    property alias cfg_taskPopupRadius: taskPopupRadiusSlider.value
    property alias cfg_maxPopupRows: maxPopupRowsSpin.value
    property string cfg_popupAnimation: "scale"
    // Kept so existing configurations can still be loaded by the KCM.
    property string cfg_popupAnimationSpeed: "normal"
    property alias cfg_popupAnimationSpeedPercent: popupAnimationSpeedSlider.value
    property alias cfg_popupAnimationIntensity: popupAnimationIntensitySlider.value

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
    readonly property var popupAnimationOptions: [
        { "text": i18n("Subtle scale (default)"), "value": "scale" },
        { "text": i18n("Bounce"), "value": "bounce" },
        { "text": i18n("Fade"), "value": "fade" },
        { "text": i18n("Slide from the dock"), "value": "slide" },
        { "text": i18n("None"), "value": "none" }
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
        syncComboValue(popupAnimationCombo, page.cfg_popupAnimation)
    }

    onCfg_windowPreviewStyleChanged: syncSelectors()
    onCfg_popupAnimationChanged: syncSelectors()
    Component.onCompleted: syncSelectors()

    // qmllint disable unqualified
    Kirigami.FormLayout {
        id: popupForm
        width: page.width

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
            text: i18n("For MPRIS-compatible applications, replaces the window preview with artwork, playback controls, and volume. Right-click actions remain separate.")
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

        Controls.CheckBox {
            id: taskPopupRadiusAutoCheck
            Kirigami.FormData.label: i18n("Preview corners:")
            text: i18n("Automatic (recommended 4 px)")
            enabled: page.cfg_windowPreviewStyle !== "none"

            ConfigCursorBehavior {
                cursorEnabled: page.interactiveCursorEnabled
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Preview radius:")
            enabled: page.cfg_windowPreviewStyle !== "none"
                && !taskPopupRadiusAutoCheck.checked
            Layout.maximumWidth: page.contentWidthHint

            Controls.Slider {
                id: taskPopupRadiusSlider
                from: 4
                to: 32
                stepSize: 1
                snapMode: Controls.Slider.SnapAlways
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 64
                Accessible.name: i18n("Window preview card corner radius")

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: i18n("%1 px", Math.round(taskPopupRadiusSlider.value))
                font.bold: true
                Layout.preferredWidth: 54
            }
        }

        Kirigami.InlineMessage {
            visible: page.cfg_windowPreviewStyle !== "none"
                && !taskPopupRadiusAutoCheck.checked
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            type: Kirigami.MessageType.Information
            text: i18n("Manual mode starts from 4 px and adjusts the internal preview card and thumbnail corners while preserving Plasma's native popup blur and shadow.")
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

        SectionTitle {
            Kirigami.FormData.isSection: true
            text: i18n("Opening animation")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Popup animation:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.ComboBox {
                id: popupAnimationCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.popupAnimationOptions
                onActivated: {
                    if (page.cfg_popupAnimation !== currentValue) {
                        page.cfg_popupAnimation = currentValue
                    }
                }

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Popup speed:")
            Layout.maximumWidth: page.contentWidthHint
            enabled: page.cfg_popupAnimation !== "none"

            Controls.Slider {
                id: popupAnimationSpeedSlider
                from: 10
                to: 200
                value: 100
                stepSize: 5
                snapMode: Controls.Slider.SnapAlways
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 64
                Accessible.name: i18n("Popup animation speed")

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: i18n("%1%", Math.round(popupAnimationSpeedSlider.value))
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 56
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Popup intensity:")
            Layout.maximumWidth: page.contentWidthHint
            enabled: page.cfg_popupAnimation !== "none"

            Controls.Slider {
                id: popupAnimationIntensitySlider
                from: 10
                to: 200
                value: 100
                stepSize: 5
                snapMode: Controls.Slider.SnapAlways
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 64
                Accessible.name: i18n("Popup animation intensity")

                ConfigCursorBehavior {
                    cursorEnabled: page.interactiveCursorEnabled
                    role: "slider"
                }
            }

            Controls.Label {
                text: i18n("%1%", Math.round(popupAnimationIntensitySlider.value))
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 56
            }
        }

        Controls.Label {
            text: i18n("Lower speed values make opening slower. Intensity controls scale, distance, fade and bounce strength. Plasma keeps native control of positioning, focus, blur, shadow and closing.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }
    }
    // qmllint enable unqualified
}
