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
    property alias cfg_windowPreviewScale: previewScaleSlider.value
    property string cfg_windowGroupingMode: "application"
    property alias cfg_maxDynamicTaskGroups: maxDynamicTaskGroupsSpin.value
    property alias cfg_maxPopupRows: maxPopupRowsSpin.value
    property string cfg_panelLengthMode: "content"
    readonly property bool interactiveCursorEnabled: !!Plasmoid.configuration.globalMouseCursor
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool verticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int contentWidthHint: Math.max(340,
        Math.min(620, width - (Kirigami.Units.gridUnit * 6)))
    readonly property int selectorWidthHint: Math.max(220,
        Math.min(360, contentWidthHint - (Kirigami.Units.gridUnit * 8)))
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
    readonly property var previewStyleOptions: [
        { "text": i18n("Window thumbnail"), "value": "thumbnail" },
        { "text": i18n("Icon card only"), "value": "card" }
    ]
    readonly property var groupingModeOptions: [
        { "text": i18n("Group by application"), "value": "application" },
        { "text": i18n("Show each window"), "value": "window" }
    ]
    readonly property var panelLengthOptions: [
        { "text": i18n("Fit content"), "value": "content" },
        { "text": i18n("Fill panel edge"), "value": "fill" }
    ]

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
        syncComboValue(groupingModeCombo, page.cfg_windowGroupingMode)
        syncComboValue(panelLengthModeCombo, page.cfg_panelLengthMode)
    }

    onCfg_windowPreviewStyleChanged: syncSelectors()
    onCfg_windowGroupingModeChanged: syncSelectors()
    onCfg_panelLengthModeChanged: syncSelectors()
    Component.onCompleted: syncSelectors()

    Kirigami.FormLayout {
        wideMode: true

        Kirigami.InlineMessage {
            visible: page.verticalPanel
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            type: Kirigami.MessageType.Information
            text: i18n("Vertical panels remain supported, but advanced visual tuning is currently focused on horizontal panels.")
        }

        SectionTitle {
            Kirigami.FormData.isSection: true
            text: i18n("Task visibility")
        }

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
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: Kirigami.Units.largeSpacing
            color: Kirigami.Theme.disabledTextColor
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
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: Kirigami.Units.largeSpacing
            color: Kirigami.Theme.disabledTextColor
            enabled: showActiveTasksCheck.checked
        }

        SectionTitle {
            Kirigami.FormData.isSection: true
            text: i18n("Previews")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Preview popup:")
            enabled: showActiveTasksCheck.checked
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
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: Kirigami.Units.largeSpacing
            color: Kirigami.Theme.disabledTextColor
            enabled: showActiveTasksCheck.checked
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Preview size:")
            enabled: showActiveTasksCheck.checked
            Layout.maximumWidth: page.contentWidthHint

            Controls.Slider {
                id: previewScaleSlider
                from: 0.5
                to: 2.0
                stepSize: 0.05
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 64

                ConfigCursorBehavior {
                    active: page.interactiveCursorEnabled
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
            text: i18n("Scales the default size of window thumbnails and preview cards without stretching their aspect ratio.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: Kirigami.Units.largeSpacing
            color: Kirigami.Theme.disabledTextColor
            enabled: showActiveTasksCheck.checked
        }

        SectionTitle {
            Kirigami.FormData.isSection: true
            text: i18n("Grouping and limits")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Window behavior:")
            enabled: showActiveTasksCheck.checked
            Layout.maximumWidth: page.contentWidthHint

            Controls.ComboBox {
                id: groupingModeCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.groupingModeOptions
                onActivated: {
                    if (page.cfg_windowGroupingMode !== currentValue) {
                        page.cfg_windowGroupingMode = currentValue
                    }
                }

                ConfigCursorBehavior {
                    active: page.interactiveCursorEnabled
                }
            }
        }

        Controls.Label {
            text: page.cfg_windowGroupingMode === "application"
                ? i18n("Dynamic task entries share one dock item per application, while pinned launchers keep their current grouped behavior.")
                : i18n("Each dynamic window gets its own dock item, while pinned launchers still accumulate their matching windows by application.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: Kirigami.Units.largeSpacing
            color: Kirigami.Theme.disabledTextColor
            enabled: showActiveTasksCheck.checked
        }

        Controls.SpinBox {
            id: maxDynamicTaskGroupsSpin
            Kirigami.FormData.label: i18n("Dynamic groups:")
            from: 1
            to: 20
            enabled: showActiveTasksCheck.checked
            Layout.preferredWidth: page.selectorWidthHint

            ConfigCursorBehavior {
                active: page.interactiveCursorEnabled
            }
        }

        Controls.Label {
            text: i18n("Extra groups remain available from an overflow item in the dock.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: Kirigami.Units.largeSpacing
            color: Kirigami.Theme.disabledTextColor
            enabled: showActiveTasksCheck.checked
        }

        Controls.SpinBox {
            id: maxPopupRowsSpin
            Kirigami.FormData.label: i18n("Popup rows:")
            from: 1
            to: 8
            enabled: showActiveTasksCheck.checked
            Layout.preferredWidth: page.selectorWidthHint

            ConfigCursorBehavior {
                active: page.interactiveCursorEnabled
            }
        }

        Controls.Label {
            text: i18n("Limits visible popup rows; additional entries remain accessible by scrolling.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: Kirigami.Units.largeSpacing
            color: Kirigami.Theme.disabledTextColor
            enabled: showActiveTasksCheck.checked
        }

        SectionTitle {
            Kirigami.FormData.isSection: true
            visible: page.inPanel
            text: i18n("Panel integration")
        }

        RowLayout {
            visible: page.inPanel && page.panelSeemsToFillEdge
            Kirigami.FormData.label: i18n("Panel length:")
            Layout.maximumWidth: page.contentWidthHint

            Controls.ComboBox {
                id: panelLengthModeCombo
                Layout.preferredWidth: page.selectorWidthHint
                Layout.maximumWidth: page.selectorWidthHint
                textRole: "text"
                valueRole: "value"
                model: page.panelLengthOptions
                onActivated: {
                    if (page.cfg_panelLengthMode !== currentValue) {
                        page.cfg_panelLengthMode = currentValue
                    }
                }

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
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: Kirigami.Units.largeSpacing
            color: Kirigami.Theme.disabledTextColor
        }

        Controls.Label {
            visible: page.inPanel && !page.panelSeemsToFillEdge
            text: i18n("The panel fill option appears only when the current Plasma panel seems to span the full screen edge.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: Kirigami.Units.largeSpacing
            color: Kirigami.Theme.disabledTextColor
        }
    }
}
