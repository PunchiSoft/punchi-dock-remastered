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
    property string cfg_windowMinimizeEffect: "none"
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
