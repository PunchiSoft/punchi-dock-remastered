import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import "components"

KCM.SimpleKCM {
    id: page

    property string cfg_hoverAnimation: "wave"
    property string cfg_clickEffect: "none"
    property alias cfg_globalMouseCursor: globalMouseCursorCheck.checked

    Kirigami.FormLayout {
        RowLayout {
            Kirigami.FormData.label: i18n("Hover animation:")

            Controls.ComboBox {
                id: hoverAnimationCombo
                textRole: "text"
                valueRole: "value"
                model: [
                    { "text": i18n("None"), "value": "none" },
                    { "text": i18n("Wave"), "value": "wave" },
                    { "text": i18n("Single"), "value": "single" },
                    { "text": i18n("Paragraph"), "value": "paragraph" }
                ]
                currentIndex: Math.max(0, indexOfValue(page.cfg_hoverAnimation))
                Layout.fillWidth: true
                onActivated: page.cfg_hoverAnimation = currentValue

                ConfigCursorBehavior {
                    active: page.cfg_globalMouseCursor
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Click effect:")

            Controls.ComboBox {
                id: clickEffectCombo
                textRole: "text"
                valueRole: "value"
                model: [
                    { "text": i18n("None"), "value": "none" },
                    { "text": i18n("Pulse"), "value": "pulse" },
                    { "text": i18n("Press"), "value": "press" },
                    { "text": i18n("Bounce"), "value": "bounce" }
                ]
                currentIndex: Math.max(0, indexOfValue(page.cfg_clickEffect))
                Layout.fillWidth: true
                onActivated: page.cfg_clickEffect = currentValue

                ConfigCursorBehavior {
                    active: page.cfg_globalMouseCursor
                }
            }
        }

        Controls.CheckBox {
            id: globalMouseCursorCheck
            Kirigami.FormData.label: i18n("Settings cursor:")
            text: i18n("Use interactive cursors in the settings window")

            ConfigCursorBehavior {
                active: page.cfg_globalMouseCursor
            }
        }

        Controls.Label {
            text: i18n("When enabled, text fields use an I-beam cursor while sliders, buttons and selectors use an interactive pointer.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            color: Kirigami.Theme.disabledTextColor
        }
    }
}
