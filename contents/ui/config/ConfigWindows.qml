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

    property alias cfg_showActiveTasks: showActiveTasksCheck.checked
    property alias cfg_showTasksCurrentDesktopOnly: currentDesktopOnlyCheck.checked
    property string cfg_windowPreviewStyle: "thumbnail"
    property string cfg_panelLengthMode: "content"
    readonly property bool interactiveCursorEnabled: !!Plasmoid.configuration.globalMouseCursor
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool verticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool panelSeemsToFillEdge: {
        try {
            var containment = Plasmoid.containment
            if (!containment || !containment.availableScreenRect) {
                return false
            }
            if (verticalPanel) {
                return containment.height >= containment.availableScreenRect.height * 0.92
            }
            return containment.width >= containment.availableScreenRect.width * 0.92
        } catch (error) {
            return false
        }
    }

    Kirigami.FormLayout {
        Controls.CheckBox {
            id: showActiveTasksCheck
            Kirigami.FormData.label: i18n("Tasks:")
            text: i18n("Show active windows in the dock")

            ConfigCursorBehavior {
                active: page.interactiveCursorEnabled
            }
        }

        Controls.Label {
            text: i18n("Pinned launchers can act as task entries when their application is already open.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            enabled: showActiveTasksCheck.checked
        }

        Controls.CheckBox {
            id: currentDesktopOnlyCheck
            Kirigami.FormData.label: i18n("Scope:")
            text: i18n("Show only windows from the current virtual desktop")
            enabled: showActiveTasksCheck.checked

            ConfigCursorBehavior {
                active: page.interactiveCursorEnabled
            }
        }

        Controls.Label {
            text: currentDesktopOnlyCheck.checked
                ? i18n("Only tasks on the current desktop will appear.")
                : i18n("Tasks from all virtual desktops can appear.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            enabled: showActiveTasksCheck.checked
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Preview popup:")
            enabled: showActiveTasksCheck.checked

            Controls.ComboBox {
                id: previewStyleCombo
                Layout.fillWidth: true
                textRole: "text"
                valueRole: "value"
                model: [
                    { "text": i18n("Window thumbnail"), "value": "thumbnail" },
                    { "text": i18n("Icon card only"), "value": "card" }
                ]
                currentIndex: Math.max(0, indexOfValue(page.cfg_windowPreviewStyle))
                onActivated: page.cfg_windowPreviewStyle = currentValue

                ConfigCursorBehavior {
                    active: page.interactiveCursorEnabled
                }
            }
        }

        Controls.Label {
            text: page.cfg_windowPreviewStyle === "thumbnail"
                ? i18n("Window selectors and hover previews use live thumbnails when the compositor can provide them.")
                : i18n("Window selectors and hover previews keep the preview-card layout but always show the app icon.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            enabled: showActiveTasksCheck.checked
        }

        RowLayout {
            visible: page.inPanel && page.panelSeemsToFillEdge
            Kirigami.FormData.label: i18n("Panel length:")

            Controls.ComboBox {
                id: panelLengthModeCombo
                Layout.fillWidth: true
                textRole: "text"
                valueRole: "value"
                model: [
                    { "text": i18n("Fit content"), "value": "content" },
                    { "text": i18n("Fill panel edge"), "value": "fill" }
                ]
                currentIndex: Math.max(0, indexOfValue(page.cfg_panelLengthMode))
                onActivated: page.cfg_panelLengthMode = currentValue

                ConfigCursorBehavior {
                    active: page.interactiveCursorEnabled
                }
            }
        }

        Controls.Label {
            visible: page.inPanel && page.panelSeemsToFillEdge
            text: i18n("When the Plasma panel already fills the full edge, the dock can either keep its compact width or stretch across that edge.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Controls.Label {
            visible: page.inPanel && !page.panelSeemsToFillEdge
            text: i18n("The panel fill option appears only when the current Plasma panel seems to span the full screen edge.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            color: Kirigami.Theme.disabledTextColor
        }
    }
}
