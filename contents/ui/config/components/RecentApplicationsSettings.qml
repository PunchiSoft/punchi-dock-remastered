import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: root

    required property int selectorWidth
    required property int contentWidth
    property alias showApplications: showRecentApplicationsSwitch.checked
    property alias maximumApplications: recentApplicationsCountSpin.value
    property string presentationMode: "container"
    property string containerLayout: "fan"

    readonly property var modeOptions: [
        { "text": i18nc("@option:recent-applications", "Icons"), "value": "inline" }, // qmllint disable unqualified
        { "text": i18nc("@option:recent-applications", "Container"), "value": "container" } // qmllint disable unqualified
    ]
    readonly property var layoutOptions: [
        { "text": i18nc("@item:inlistbox Folder popup layout", "Grid"), "value": "grid" }, // qmllint disable unqualified
        { "text": i18nc("@item:inlistbox Folder popup layout", "List"), "value": "list" }, // qmllint disable unqualified
        { "text": i18nc("@item:inlistbox Folder popup layout", "Detailed"), "value": "detailed" }, // qmllint disable unqualified
        { "text": i18nc("@item:inlistbox Folder popup layout", "Fan"), "value": "fan" } // qmllint disable unqualified
    ]

    function syncComboValue(combo, value) {
        const resolvedIndex = Math.max(0, combo.indexOfValue(value))
        if (combo.currentIndex !== resolvedIndex) {
            combo.currentIndex = resolvedIndex
        }
    }

    function syncSelectors() {
        syncComboValue(recentModeCombo, root.presentationMode)
        syncComboValue(recentContainerLayoutCombo, root.containerLayout)
    }

    onPresentationModeChanged: syncSelectors()
    onContainerLayoutChanged: syncSelectors()
    Component.onCompleted: syncSelectors()

    Kirigami.Heading {
        Kirigami.FormData.isSection: true
        Layout.fillWidth: true
        level: 3
        leftPadding: 0
        text: i18nc("@title:group", "Recent applications") // qmllint disable unqualified
    }

    Controls.Switch {
        id: showRecentApplicationsSwitch
        objectName: "showRecentApplicationsSwitch"
        text: i18nc("@option:check", "Show recent applications") // qmllint disable unqualified
        Accessible.name: showRecentApplicationsSwitch.text
        checked: true
        activeFocusOnTab: true
        Layout.maximumWidth: root.contentWidth
    }

    Controls.ComboBox {
        id: recentModeCombo
        objectName: "recentApplicationsModeCombo"
        Kirigami.FormData.label: i18nc("@label:listbox", "Presentation:") // qmllint disable unqualified
        Accessible.name: i18nc("@label:listbox", "Recent applications presentation") // qmllint disable unqualified
        enabled: showRecentApplicationsSwitch.checked
        Layout.preferredWidth: root.selectorWidth
        Layout.maximumWidth: root.selectorWidth
        textRole: "text"
        valueRole: "value"
        model: root.modeOptions
        onActivated: function(index) {
            const option = root.modeOptions[index]
            if (option) { root.presentationMode = option.value }
        }
    }

    Controls.SpinBox {
        id: recentApplicationsCountSpin
        objectName: "recentApplicationsCountSpin"
        Kirigami.FormData.label: i18nc("@label:spinbox", "Applications to show:") // qmllint disable unqualified
        Accessible.name: i18nc("@label:spinbox", "Applications to show:") // qmllint disable unqualified
        enabled: showRecentApplicationsSwitch.checked
        from: 1
        to: 20
        value: 5
        editable: true
        activeFocusOnTab: true
        Layout.preferredWidth: root.selectorWidth
        Layout.maximumWidth: root.selectorWidth
    }

    Controls.ComboBox {
        id: recentContainerLayoutCombo
        objectName: "recentApplicationsContainerLayoutCombo"
        Kirigami.FormData.label: i18nc("@label:listbox", "Container view:") // qmllint disable unqualified
        Accessible.name: i18nc("@label:listbox", "Recent applications container view") // qmllint disable unqualified
        enabled: showRecentApplicationsSwitch.checked && root.presentationMode === "container"
        Layout.preferredWidth: root.selectorWidth
        Layout.maximumWidth: root.selectorWidth
        textRole: "text"
        valueRole: "value"
        model: root.layoutOptions
        onActivated: function(index) {
            const option = root.layoutOptions[index]
            if (option) { root.containerLayout = option.value }
        }
    }
}
