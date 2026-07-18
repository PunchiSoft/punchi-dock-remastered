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

    property alias cfg_showActiveTasks: showActiveTasksCheck.checked
    property alias cfg_showTasksCurrentDesktopOnly: currentDesktopOnlyCheck.checked
    property string cfg_windowPreviewStyle: "card"
    property alias cfg_windowPreviewScale: previewScaleSlider.value
    property alias cfg_mediaControlsOnHover: mediaControlsOnHoverCheck.checked
    property alias cfg_taskPopupRadiusAuto: taskPopupRadiusAutoCheck.checked
    property alias cfg_taskPopupRadius: taskPopupRadiusSlider.value
    property string cfg_windowGroupingMode: "application"
    property alias cfg_maxDynamicTaskGroups: maxDynamicTaskGroupsSpin.value
    property alias cfg_maxPopupRows: maxPopupRowsSpin.value
    readonly property bool interactiveCursorEnabled: !!Plasmoid.configuration.globalMouseCursor
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool verticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int contentWidthHint: layoutMetrics.contentWidth
    readonly property int selectorWidthHint: layoutMetrics.selectorWidth
    readonly property var previewStyleOptions: [
        { "text": i18n("Cards (recommended)"), "value": "card" },
        { "text": i18n("Window previews"), "value": "thumbnail" },
        { "text": i18n("None"), "value": "none" }
    ]
    readonly property var groupingModeOptions: [
        { "text": i18n("Group by application"), "value": "application" },
        { "text": i18n("Show each window"), "value": "window" }
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
    }

    onCfg_windowPreviewStyleChanged: syncSelectors()
    onCfg_windowGroupingModeChanged: syncSelectors()
    Component.onCompleted: syncSelectors()

    Kirigami.FormLayout {

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

        // qmllint disable unqualified
        Controls.CheckBox {
            id: showActiveTasksCheck
            Kirigami.FormData.label: i18n("Tasks:")
            text: i18n("Show active windows in the dock")

            ConfigCursorBehavior {
                cursorEnabled: page.interactiveCursorEnabled
            }
        }

        Controls.Label {
            text: i18n("Pinned launchers can act as task entries when their application is already open.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
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
            Accessible.name: i18n("Maximum dynamic groups shown in the dock")

            ConfigCursorBehavior {
                cursorEnabled: page.interactiveCursorEnabled
            }
        }

        Controls.Label {
            text: i18n("This manual limit applies in floating and compact modes. While Fill free panel space is active, Punchi Dock automatically uses the available panel capacity. Additional groups remain available from the overflow item.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
            enabled: showActiveTasksCheck.checked
        }

        Controls.CheckBox {
            id: currentDesktopOnlyCheck
            Kirigami.FormData.label: i18n("Scope:")
            text: i18n("Show only windows from the current virtual desktop")
            enabled: showActiveTasksCheck.checked

            ConfigCursorBehavior {
                cursorEnabled: page.interactiveCursorEnabled
            }
        }

        Controls.Label {
            text: currentDesktopOnlyCheck.checked
                ? i18n("Only tasks on the current desktop will appear.")
                : i18n("Tasks from all virtual desktops can appear.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
            enabled: showActiveTasksCheck.checked
        }

        SectionTitle {
            Kirigami.FormData.isSection: true
            text: i18n("Previews")
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
        // qmllint enable unqualified

        RowLayout {
            Kirigami.FormData.label: i18n("Preview size:")
            enabled: page.cfg_windowPreviewStyle !== "none"
            Layout.maximumWidth: page.contentWidthHint

            Controls.Slider {
                id: previewScaleSlider
                from: 0.5
                to: 2.0
                stepSize: 0.05
                Layout.fillWidth: true
                Layout.preferredWidth: page.contentWidthHint - 64

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
            text: i18n("Scales the default size of window thumbnails and preview cards without stretching their aspect ratio.")
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
            enabled: page.cfg_windowPreviewStyle !== "none" && !taskPopupRadiusAutoCheck.checked
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
            visible: page.cfg_windowPreviewStyle !== "none" && !taskPopupRadiusAutoCheck.checked
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            type: Kirigami.MessageType.Information
            text: i18n("Manual mode starts from 4 px and adjusts the internal preview card and thumbnail corners while preserving Plasma's native popup blur and shadow.")
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
                    cursorEnabled: page.interactiveCursorEnabled
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
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
            enabled: showActiveTasksCheck.checked
        }

        Controls.SpinBox {
            id: maxPopupRowsSpin
            Kirigami.FormData.label: i18n("Popup rows:")
            from: 1
            to: 8
            enabled: page.cfg_windowPreviewStyle !== "none"
            Layout.preferredWidth: page.selectorWidthHint

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
}
