import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import "components"

KCM.SimpleKCM {
    id: page
    implicitWidth: layoutMetrics.pageImplicitWidth

    ConfigLayoutMetrics {
        id: layoutMetrics
        availableWidth: page.width
    }

    property string cfg_hoverAnimation: "wave"
    property alias cfg_hoverScale: hoverScaleSlider.value
    property string cfg_clickEffect: "none"
    property string cfg_windowMinimizeEffect: "none"
    property alias cfg_dockMotionSpeedPercent: dockMotionSpeedSlider.value
    property alias cfg_globalMouseCursor: globalMouseCursorCheck.checked
    property alias cfg_enableAppDragAndDrop: enableAppDragAndDropCheck.checked
    readonly property int contentWidthHint: layoutMetrics.contentWidth
    readonly property int selectorWidthHint: layoutMetrics.selectorWidth
    readonly property bool inPanel:
        Plasmoid.formFactor === PlasmaCore.Types.Horizontal
        || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int hoverEnlargementPercent:
        Math.round((hoverScaleSlider.value - 1.0) * 100)
    readonly property bool hoverEnlargementDisabled:
        hoverEnlargementPercent <= 0
    readonly property bool hoverEnlargementMayBeClipped:
        inPanel && hoverEnlargementPercent >= 100
    readonly property var hoverAnimationOptions: [
        { "text": i18n("None"), "value": "none" },
        { "text": i18n("Wave"), "value": "wave" },
        { "text": i18n("Single"), "value": "single" },
        { "text": i18n("Axis zoom"), "value": "axisZoom" },
        { "text": i18n("Pulse"), "value": "selectionPulse" }
    ]
    readonly property var clickEffectOptions: [
        { "text": i18n("None"), "value": "none" },
        { "text": i18n("Pulse"), "value": "pulse" },
        { "text": i18n("Press"), "value": "press" },
        { "text": i18n("Bounce"), "value": "bounce" }
    ]
    // qmllint disable unqualified
    readonly property var windowMinimizeEffectOptions: [
        { "text": i18n("None"), "value": "none" },
        { "text": i18n("Slow bounce"), "value": "slowBounce" },
        { "text": i18n("Lateral ripple"), "value": "lateralRipple" }
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
        if (page.cfg_hoverAnimation === "paragraph") {
            page.cfg_hoverAnimation = "selectionPulse"
            return
        }
        syncComboValue(hoverAnimationCombo, page.cfg_hoverAnimation)
        syncComboValue(clickEffectCombo, page.cfg_clickEffect)
        syncComboValue(windowMinimizeEffectCombo, page.cfg_windowMinimizeEffect)
    }

    onCfg_hoverAnimationChanged: syncMouseSelectors()
    onCfg_clickEffectChanged: syncMouseSelectors()
    onCfg_windowMinimizeEffectChanged: syncMouseSelectors()
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
            // Plasma injects i18n through KLocalizedContext at runtime.
            // qmllint disable unqualified
            Kirigami.FormData.label: i18n("Hover enlargement:")
            // qmllint enable unqualified
            Layout.maximumWidth: page.contentWidthHint

            Controls.Slider {
                id: hoverScaleSlider
                from: 1.0
                to: 2.0
                stepSize: 0.05
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 60
                // qmllint disable unqualified
                Accessible.name: i18n("Hover enlargement")
                Accessible.description: i18n("Adjusts additional hover enlargement between 0 and 100 percent.")
                // qmllint enable unqualified

                ConfigCursorBehavior {
                    cursorEnabled: page.cfg_globalMouseCursor
                    role: "slider"
                }
            }

            Controls.Label {
                // qmllint disable unqualified
                text: i18n("%1%", page.hoverEnlargementPercent)
                // qmllint enable unqualified
                font.bold: true
                Layout.preferredWidth: 50
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            visible: page.hoverEnlargementDisabled
                || page.hoverEnlargementMayBeClipped
            type: Kirigami.MessageType.Warning
            // qmllint disable unqualified
            text: page.hoverEnlargementDisabled
                ? i18n("At 0%, the hover enlargement animation is disabled.")
                : i18n("At 100%, hover enlargement may be clipped by the space and margins available in the Plasma panel. Floating mode is not affected.")
            // qmllint enable unqualified
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Dock motion speed:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.Slider {
                id: dockMotionSpeedSlider
                from: 50
                to: 150
                stepSize: 25
                snapMode: Controls.Slider.SnapAlways
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 64
                Accessible.name: i18n("Dock motion speed")
                Accessible.description: i18n("Controls how quickly dock items enter, move, and resize. It does not change popup or menu animations.")

                ConfigCursorBehavior {
                    cursorEnabled: page.cfg_globalMouseCursor
                    role: "slider"
                }
            }

            Controls.Label {
                text: i18n("%1%", Math.round(dockMotionSpeedSlider.value))
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 56
            }
        }

        Controls.Label {
            text: i18n("100% preserves the current timing. Lower values are slower and higher values are faster.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
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
            Kirigami.FormData.label: i18n("Window minimize effect:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.ComboBox {
                id: windowMinimizeEffectCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.windowMinimizeEffectOptions
                onActivated: {
                    if (page.cfg_windowMinimizeEffect !== currentValue) {
                        page.cfg_windowMinimizeEffect = currentValue
                    }
                }

                ConfigCursorBehavior {
                    cursorEnabled: page.cfg_globalMouseCursor
                }
            }
        }

        Controls.Label {
            text: i18n("Animates the matching dock item when a window is minimized. Lateral ripple also moves the nearest items.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }
        // qmllint enable unqualified

        // qmllint disable unqualified
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
        // qmllint enable unqualified

        // qmllint disable unqualified
        Controls.CheckBox {
            id: enableAppDragAndDropCheck
            Kirigami.FormData.label: i18n("Application file drop:")
            text: i18n("Enable file drag and drop onto application icons")
            Layout.maximumWidth: page.contentWidthHint

            ConfigCursorBehavior {
                cursorEnabled: page.cfg_globalMouseCursor
            }
        }

        Controls.Label {
            text: i18n("When disabled, application icons ignore dragged files. The Trash can still receive files.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
        }
        // qmllint enable unqualified

    }
}
