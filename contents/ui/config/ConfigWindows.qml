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
    property alias cfg_showRecentApplications: showRecentApplicationsCheck.checked
    property alias cfg_recentApplicationsCount: recentApplicationsCountSpin.value
    property string cfg_recentApplicationsMode: "container"
    property string cfg_recentApplicationsContainerLayout: "grid"
    readonly property var recentModeOptions: [
        { "text": i18nc("@option:recent-applications", "Icons"), "value": "inline" }, // qmllint disable unqualified
        { "text": i18nc("@option:recent-applications", "Container"), "value": "container" } // qmllint disable unqualified
    ]
    readonly property var recentContainerLayoutOptions: [
        { "text": i18nc("@item:inlistbox Folder popup layout", "Grid"), "value": "grid" }, // qmllint disable unqualified
        { "text": i18nc("@item:inlistbox Folder popup layout", "List"), "value": "list" }, // qmllint disable unqualified
        { "text": i18nc("@item:inlistbox Folder popup layout", "Detailed"), "value": "detailed" }, // qmllint disable unqualified
        { "text": i18nc("@item:inlistbox Folder popup layout", "Fan"), "value": "fan" } // qmllint disable unqualified
    ]
    property alias cfg_maxDynamicTaskGroups: maxDynamicTaskGroupsSpin.value
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool verticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int contentWidthHint: layoutMetrics.contentWidth
    readonly property int selectorWidthHint: layoutMetrics.selectorWidth
    readonly property var groupingModeOptions: [
        { "text": i18n("Group by application"), "value": "application" }, // qmllint disable unqualified
        { "text": i18n("Show each window"), "value": "window" } // qmllint disable unqualified
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
        syncComboValue(recentModeCombo, page.cfg_recentApplicationsMode)
        syncComboValue(recentContainerLayoutCombo, page.cfg_recentApplicationsContainerLayout)
    }

    onCfg_windowGroupingModeChanged: syncSelectors()
    onCfg_recentApplicationsModeChanged: syncSelectors()
    onCfg_recentApplicationsContainerLayoutChanged: syncSelectors()
    Component.onCompleted: syncSelectors()

    Kirigami.FormLayout {
        SectionTitle {
            Kirigami.FormData.isSection: true
            text: i18nc("@title:group", "Recent applications") // qmllint disable unqualified
        }
        Controls.CheckBox {
            id: showRecentApplicationsCheck
            objectName: "showRecentApplicationsCheck"
            text: i18nc("@option:check", "Show recent applications") // qmllint disable unqualified
            checked: true
        }
        Controls.ComboBox {
            id: recentModeCombo
            objectName: "recentApplicationsModeCombo"
            Kirigami.FormData.label: i18nc("@label:listbox", "Presentation:") // qmllint disable unqualified
            Accessible.name: i18nc("@label:listbox", "Recent applications presentation") // qmllint disable unqualified
            enabled: showRecentApplicationsCheck.checked
            Layout.preferredWidth: page.selectorWidthHint
            textRole: "text"
            valueRole: "value"
            model: page.recentModeOptions
            onActivated: function(index) {
                const option = page.recentModeOptions[index]
                if (option) { page.cfg_recentApplicationsMode = option.value }
            }
        }
        Controls.SpinBox {
            id: recentApplicationsCountSpin
            objectName: "recentApplicationsCountSpin"
            Kirigami.FormData.label: i18nc("@label:spinbox", "Applications to show:") // qmllint disable unqualified
            Accessible.name: i18nc("@label:spinbox", "Applications to show:") // qmllint disable unqualified
            enabled: showRecentApplicationsCheck.checked
            from: 1
            to: 20
            value: 3
            editable: true
            activeFocusOnTab: true
            Layout.preferredWidth: page.selectorWidthHint
            Layout.maximumWidth: page.selectorWidthHint
        }
        Controls.ComboBox {
            id: recentContainerLayoutCombo
            objectName: "recentApplicationsContainerLayoutCombo"
            Kirigami.FormData.label: i18nc("@label:listbox", "Container view:") // qmllint disable unqualified
            Accessible.name: i18nc("@label:listbox", "Recent applications container view") // qmllint disable unqualified
            enabled: showRecentApplicationsCheck.checked
                && page.cfg_recentApplicationsMode === "container"
            Layout.preferredWidth: page.selectorWidthHint
            Layout.maximumWidth: page.selectorWidthHint
            textRole: "text"
            valueRole: "value"
            model: page.recentContainerLayoutOptions
            onActivated: function(index) {
                const option = page.recentContainerLayoutOptions[index]
                if (option) { page.cfg_recentApplicationsContainerLayout = option.value }
            }
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true }

        SectionTitle {
            Kirigami.FormData.isSection: true
            text: i18n("Task visibility") // qmllint disable unqualified
        }

        // qmllint disable unqualified
        Controls.CheckBox {
            id: showActiveTasksCheck
            Kirigami.FormData.label: i18n("Tasks:")
            text: i18n("Show active windows in the dock")

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

        }

        Controls.Label {
            text: i18n("Limits the number of dynamic task groups shown directly in the dock. Additional groups that exceed this limit or available space remain accessible from the overflow item.")
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

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
        }
        SectionTitle {
            Kirigami.FormData.isSection: true
            text: i18n("Grouping and limits") // qmllint disable unqualified
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Window behavior:") // qmllint disable unqualified
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

            }
        }

        Controls.Label {
            text: page.cfg_windowGroupingMode === "application"
                ? i18n("Dynamic task entries share one dock item per application, while pinned launchers keep their current grouped behavior.") // qmllint disable unqualified
                : i18n("Each dynamic window gets its own dock item, while pinned launchers still accumulate their matching windows by application.") // qmllint disable unqualified
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: page.contentWidthHint
            leftPadding: layoutMetrics.helperIndent
            color: Kirigami.Theme.disabledTextColor
            enabled: showActiveTasksCheck.checked
        }

    }
}
