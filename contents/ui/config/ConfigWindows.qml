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
    property string cfg_windowGroupingMode: "application"
    property alias cfg_maxDynamicTaskGroups: maxDynamicTaskGroupsSpin.value
    readonly property bool interactiveCursorEnabled: !!Plasmoid.configuration.globalMouseCursor
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool verticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int contentWidthHint: layoutMetrics.contentWidth
    readonly property int selectorWidthHint: layoutMetrics.selectorWidth
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
        syncComboValue(groupingModeCombo, page.cfg_windowGroupingMode)
    }

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
        // qmllint enable unqualified

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

    }
}
