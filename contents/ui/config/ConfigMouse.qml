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

    property string cfg_hoverAnimation: "wave"
    property string cfg_clickEffect: "none"
    property string cfg_popupAnimation: "scale"
    // Kept so existing configurations can still be loaded by the KCM.
    property string cfg_popupAnimationSpeed: "normal"
    property alias cfg_popupAnimationSpeedPercent: popupAnimationSpeedSlider.value
    property alias cfg_popupAnimationIntensity: popupAnimationIntensitySlider.value
    property alias cfg_contextMenuTransitionSpeed: contextMenuTransitionSpeedSlider.value
    property alias cfg_globalMouseCursor: globalMouseCursorCheck.checked
    readonly property int contentWidthHint: layoutMetrics.contentWidth
    readonly property int selectorWidthHint: layoutMetrics.selectorWidth
    readonly property var hoverAnimationOptions: [
        { "text": i18n("None"), "value": "none" },
        { "text": i18n("Wave"), "value": "wave" },
        { "text": i18n("Single"), "value": "single" },
        { "text": i18n("Paragraph"), "value": "paragraph" }
    ]
    readonly property var clickEffectOptions: [
        { "text": i18n("None"), "value": "none" },
        { "text": i18n("Pulse"), "value": "pulse" },
        { "text": i18n("Press"), "value": "press" },
        { "text": i18n("Bounce"), "value": "bounce" }
    ]
    // qmllint disable unqualified
    readonly property var popupAnimationOptions: [
        { "text": i18n("Subtle scale (default)"), "value": "scale" },
        { "text": i18n("Bounce"), "value": "bounce" },
        { "text": i18n("Fade"), "value": "fade" },
        { "text": i18n("Slide from the dock"), "value": "slide" },
        { "text": i18n("None"), "value": "none" }
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

    function syncMouseSelectors() {
        syncComboValue(hoverAnimationCombo, page.cfg_hoverAnimation)
        syncComboValue(clickEffectCombo, page.cfg_clickEffect)
        syncComboValue(popupAnimationCombo, page.cfg_popupAnimation)
    }

    onCfg_hoverAnimationChanged: syncMouseSelectors()
    onCfg_clickEffectChanged: syncMouseSelectors()
    onCfg_popupAnimationChanged: syncMouseSelectors()
    Component.onCompleted: syncMouseSelectors()

    Kirigami.FormLayout {
        RowLayout {
            Kirigami.FormData.label: i18n("Hover animation:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.ComboBox {
                id: hoverAnimationCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.hoverAnimationOptions
                onActivated: {
                    if (page.cfg_hoverAnimation !== currentValue) {
                        page.cfg_hoverAnimation = currentValue
                    }
                }

                ConfigCursorBehavior {
                    cursorEnabled: page.cfg_globalMouseCursor
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Click effect:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.ComboBox {
                id: clickEffectCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.clickEffectOptions
                onActivated: {
                    if (page.cfg_clickEffect !== currentValue) {
                        page.cfg_clickEffect = currentValue
                    }
                }

                ConfigCursorBehavior {
                    cursorEnabled: page.cfg_globalMouseCursor
                }
            }
        }

        // qmllint disable unqualified
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
                    cursorEnabled: page.cfg_globalMouseCursor
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
                    cursorEnabled: page.cfg_globalMouseCursor
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
                    cursorEnabled: page.cfg_globalMouseCursor
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

        RowLayout {
            Kirigami.FormData.label: i18n("Menu transition speed:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.Slider {
                id: contextMenuTransitionSpeedSlider
                from: 10
                to: 200
                value: 100
                stepSize: 5
                snapMode: Controls.Slider.SnapAlways
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 64
                Accessible.name: i18n("Preview to context menu transition speed")

                ConfigCursorBehavior {
                    cursorEnabled: page.cfg_globalMouseCursor
                    role: "slider"
                }
            }

            Controls.Label {
                text: i18n("%1%", Math.round(contextMenuTransitionSpeedSlider.value))
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 56
            }
        }

        Controls.Label {
            text: i18n("Lower values make the preview-to-menu movement gentler; higher values make it faster. 100% follows the Plasma theme duration.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }
        // qmllint enable unqualified

        Controls.CheckBox {
            id: globalMouseCursorCheck
            Kirigami.FormData.label: i18n("Settings cursor:")
            text: i18n("Use interactive cursors in the settings window")
            Layout.maximumWidth: page.contentWidthHint

            ConfigCursorBehavior {
                cursorEnabled: page.cfg_globalMouseCursor
            }
        }

        Controls.Label {
            text: i18n("When enabled, text fields use an I-beam cursor while sliders, buttons and selectors use an interactive pointer.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }
    }
}
