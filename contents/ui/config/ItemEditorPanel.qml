import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami


GridLayout {
    id: root

    property string selectedItemType: "app"
    property alias appNameText: appName.text
    property alias appAliasText: appAlias.text
    property alias appDescriptionText: appDescription.text
    property alias appIconText: appIconName.text
    property alias appCommandText: appCommand.text
    readonly property string itemModeValue: itemMode.currentValue || "app"
    property alias itemModeIndex: itemMode.currentIndex
    readonly property string containerLayoutValue: containerLayout.currentValue || "grid"
    property alias containerLayoutIndex: containerLayout.currentIndex
    property alias containerShowLabelsChecked: folderShowLabels.checked
    property alias radialBackgroundChecked: radialBackground.checked
    property alias radialIconSlotsChecked: radialIconSlots.checked
    property alias radialDistanceValue: radialDistance.value
    property alias fanCenterDistanceValue: fanCenterDistance.value
    property alias spacerSizeValue: spacerSize.value
    readonly property string containerSourceValue: containerSource.currentValue || "manual"
    property alias containerSourceIndex: containerSource.currentIndex
    property alias containerPathText: containerPath.text
    readonly property string containerCategoryValue: containerCategory.currentValue || "Development"
    property alias containerCategoryIndex: containerCategory.currentIndex

    property string nameLabel: "Name:"
    property string aliasLabel: "Alias:"
    property string descLabel: "Description:"
    property string aliasPlaceholder: "Press Enter to search..."
    property string itemTypeLabel: "Type:"
    property string launchAppText: "Launch app"
    property string containerText: "Container"
    property string viewLabel: "View:"
    property string gridText: "Grid"
    property string listText: "List"
    property string detailedText: "Detailed"
    property string radialText: "Radial"
    property string fanText: "Fan"
    property string showContainerLabelsText: "Show labels"
    property string radialBackgroundText: "Show radial background"
    property string radialIconSlotsText: "Show icon circles"
    property string radialDistanceLabel: "Radial distance:"
    property string fanCenterDistanceLabel: "Fan spread:"
    property string noteText: "Note"
    property string separatorText: "Separator"
    property string spacerText: "Spacer"
    property string containerSourceLabel: "Content:"
    property string manualContainerText: "Manual"
    property string folderContainerText: "Folder"
    property string categoryContainerText: "Application category"
    property string folderPathLabel: "Folder:"
    property string categoryLabel: "Category:"
    property string refreshContentText: "Load content"
    property string iconLabel: "Icon:"
    property string commandLabel: "Command:"
    property string spacerSizeLabel: "Spacer size:"
    property string chooseIconText: "Choose icon"

    signal formChanged()
    signal itemModeChanged(string mode)
    signal containerLayoutChanged(string layout)
    signal containerSourceChanged(string source)
    signal containerCategoryChanged(string category)
    signal folderPickerRequested()
    signal containerRefreshRequested()
    signal appCommandEdited()
    signal autofillRequested(string alias)
    signal iconPickerRequested(string target)

    function sourceIndexFor(value) {
        return Math.max(0, containerSource.indexOfValue(value || "manual"))
    }

    function categoryIndexFor(value) {
        return Math.max(0, containerCategory.indexOfValue(value || "Development"))
    }

    function layoutIndexFor(value) {
        return Math.max(0, containerLayout.indexOfValue(value || "grid"))
    }

    function iconPreview(value, fallback) {
        var text = String(value || "")
        return text.length > 0 ? text : fallback
    }

    Layout.fillWidth: true
    columns: 2
    columnSpacing: Kirigami.Units.smallSpacing
    rowSpacing: Kirigami.Units.smallSpacing

    Controls.Label {
        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        text: root.itemTypeLabel
        horizontalAlignment: Text.AlignLeft
        opacity: 0.75
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Controls.ComboBox {
            id: itemMode
            Layout.fillWidth: true
            enabled: root.selectedItemType === "app" || root.selectedItemType === "folder" || root.selectedItemType === "note" || root.selectedItemType === "separator" || root.selectedItemType === "spacer"
            textRole: "text"
            valueRole: "value"
            model: [
                { "text": root.launchAppText, "value": "app" },
                { "text": root.containerText, "value": "container" },
                { "text": root.noteText, "value": "note" },
                { "text": root.separatorText, "value": "separator" },
                { "text": root.spacerText, "value": "spacer" }
            ]
            onActivated: root.itemModeChanged(currentValue)
        }

        Controls.Label {
            visible: root.itemModeValue === "container"
            text: root.viewLabel
            opacity: 0.75
            verticalAlignment: Text.AlignVCenter
        }

        Controls.ComboBox {
            id: containerLayout
            Layout.preferredWidth: Kirigami.Units.gridUnit * 8
            visible: root.itemModeValue === "container"
            enabled: root.selectedItemType === "folder"
            textRole: "text"
            valueRole: "value"
            model: [
                { "text": root.gridText, "value": "grid" },
                { "text": root.listText, "value": "list" },
                { "text": root.detailedText, "value": "detailed" },
                { "text": root.radialText, "value": "radial" },
                { "text": root.fanText, "value": "fan" }
            ]
            onActivated: root.containerLayoutChanged(currentValue)
        }
    }

    Controls.CheckBox {
        id: folderShowLabels
        Layout.columnSpan: 2
        visible: root.itemModeValue === "container"
        enabled: root.selectedItemType === "folder"
        text: root.showContainerLabelsText
        checked: true
        onClicked: root.formChanged()
    }

    Controls.CheckBox {
        id: radialBackground
        Layout.columnSpan: 2
        visible: root.itemModeValue === "container" && root.containerLayoutValue === "radial"
        enabled: root.selectedItemType === "folder"
        text: root.radialBackgroundText
        checked: true
        onClicked: root.formChanged()
    }

    Controls.CheckBox {
        id: radialIconSlots
        Layout.columnSpan: 2
        visible: root.itemModeValue === "container" && root.containerLayoutValue === "radial"
        enabled: root.selectedItemType === "folder"
        text: root.radialIconSlotsText
        checked: true
        onClicked: root.formChanged()
    }

    Controls.Label {
        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        visible: root.itemModeValue === "container" && root.containerLayoutValue === "radial"
        text: root.radialDistanceLabel
        horizontalAlignment: Text.AlignLeft
        opacity: 0.75
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.itemModeValue === "container" && root.containerLayoutValue === "radial"
        enabled: root.selectedItemType === "folder"
        spacing: Kirigami.Units.smallSpacing

        Controls.Slider {
            id: radialDistance
            Layout.fillWidth: true
            from: 0
            to: 360
            stepSize: 4
            snapMode: Controls.Slider.SnapAlways
            onMoved: root.formChanged()
        }

        Controls.Label {
            Layout.minimumWidth: Kirigami.Units.gridUnit * 3
            horizontalAlignment: Text.AlignRight
            text: Math.round(radialDistance.value) + " px"
            opacity: 0.75
        }
    }

    Controls.Label {
        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        visible: root.itemModeValue === "container" && root.containerLayoutValue === "fan"
        text: root.fanCenterDistanceLabel
        horizontalAlignment: Text.AlignLeft
        opacity: 0.75
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.itemModeValue === "container" && root.containerLayoutValue === "fan"
        enabled: root.selectedItemType === "folder"
        spacing: Kirigami.Units.smallSpacing

        Controls.Slider {
            id: fanCenterDistance
            Layout.fillWidth: true
            from: 0
            to: 100
            stepSize: 2
            snapMode: Controls.Slider.SnapAlways
            onMoved: root.formChanged()
        }

        Controls.Label {
            Layout.minimumWidth: Kirigami.Units.gridUnit * 3
            horizontalAlignment: Text.AlignRight
            text: Math.round(fanCenterDistance.value) + " px"
            opacity: 0.75
        }
    }

    Controls.Label {
        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        visible: root.itemModeValue === "app"
        text: root.aliasLabel
        horizontalAlignment: Text.AlignLeft
        opacity: 0.75
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.itemModeValue === "app"
        enabled: root.selectedItemType === "app"
        spacing: Kirigami.Units.smallSpacing

        Controls.TextField {
            id: appAlias
            Layout.fillWidth: true
            placeholderText: root.aliasPlaceholder
            onAccepted: root.autofillRequested(text)
        }

        Controls.Button {
            icon.name: "search"
            display: Controls.AbstractButton.IconOnly
            onClicked: root.autofillRequested(appAlias.text)
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }
    }

    Controls.Label {
        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        visible: root.itemModeValue === "app" || root.itemModeValue === "container" || root.itemModeValue === "note"
        text: root.nameLabel
        horizontalAlignment: Text.AlignLeft
        opacity: 0.75
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.itemModeValue === "app" || root.itemModeValue === "container" || root.itemModeValue === "note"
        enabled: root.selectedItemType === "app" || root.selectedItemType === "folder" || root.selectedItemType === "note"
        spacing: Kirigami.Units.smallSpacing

        Controls.TextField {
            id: appName
            Layout.fillWidth: true
            onAccepted: root.formChanged()
            onEditingFinished: root.formChanged()
        }

        Controls.Label {
            text: root.iconLabel
            opacity: 0.75
            verticalAlignment: Text.AlignVCenter
        }

        Controls.Button {
            HoverHandler { cursorShape: Qt.PointingHandCursor }
            icon.name: root.iconPreview(appIconName.text, "application-x-executable")
            icon.source: root.iconPreview(appIconName.text, "application-x-executable")
            display: Controls.AbstractButton.IconOnly
            onClicked: root.iconPickerRequested("item")

            Controls.ToolTip.visible: hovered
            Controls.ToolTip.text: root.chooseIconText
        }

        Controls.TextField {
            id: appIconName
            visible: false
            placeholderText: "firefox"
            onEditingFinished: root.formChanged()
        }
    }

    Controls.Label {
        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        visible: root.itemModeValue === "app"
        text: root.descLabel
        horizontalAlignment: Text.AlignLeft
        opacity: 0.75
    }

    Controls.TextField {
        id: appDescription
        Layout.fillWidth: true
        visible: root.itemModeValue === "app"
        enabled: root.selectedItemType === "app"
        onAccepted: root.formChanged()
        onEditingFinished: root.formChanged()
    }

    Controls.Label {
        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        visible: root.itemModeValue === "app"
        text: root.commandLabel
        horizontalAlignment: Text.AlignLeft
        opacity: 0.75
    }

    Controls.TextField {
        id: appCommand
        Layout.fillWidth: true
        visible: root.itemModeValue === "app"
        enabled: root.selectedItemType === "app"
        placeholderText: "firefox"
        onAccepted: root.appCommandEdited()
        onEditingFinished: root.appCommandEdited()
    }

    Controls.Label {
        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        visible: root.itemModeValue === "spacer"
        text: root.spacerSizeLabel
        horizontalAlignment: Text.AlignLeft
        opacity: 0.75
    }

    Controls.SpinBox {
        id: spacerSize
        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
        visible: root.itemModeValue === "spacer"
        enabled: root.selectedItemType === "spacer"
        from: 0
        to: 600
        stepSize: 4
        textFromValue: function(value) { return value + " px" }
        valueFromText: function(text) { return Number.fromLocaleString(Qt.locale(), text.replace("px", "")) }
        onValueModified: root.formChanged()
    }

    Controls.Label {
        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        visible: root.itemModeValue === "container"
        text: root.containerSourceLabel
        horizontalAlignment: Text.AlignLeft
        opacity: 0.75
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.itemModeValue === "container"
        spacing: Kirigami.Units.smallSpacing

        Controls.ComboBox {
            id: containerSource
            Layout.fillWidth: true
            enabled: root.selectedItemType === "folder"
            textRole: "text"
            valueRole: "value"
            model: [
                { "text": root.manualContainerText, "value": "manual" },
                { "text": root.folderContainerText, "value": "folder" },
                { "text": root.categoryContainerText, "value": "category" }
            ]
            onActivated: root.containerSourceChanged(currentValue)
        }

        Controls.Button {
            HoverHandler { cursorShape: Qt.PointingHandCursor }
            text: root.refreshContentText
            icon.name: "view-refresh-symbolic"
            enabled: root.selectedItemType === "folder" && containerSource.currentValue !== "manual"
            onClicked: root.containerRefreshRequested()
        }
    }

    Controls.Label {
        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        visible: root.itemModeValue === "container" && containerSource.currentValue === "folder"
        text: root.folderPathLabel
        horizontalAlignment: Text.AlignLeft
        opacity: 0.75
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.itemModeValue === "container" && containerSource.currentValue === "folder"
        spacing: Kirigami.Units.smallSpacing

        Controls.TextField {
            id: containerPath
            Layout.fillWidth: true
            enabled: root.selectedItemType === "folder"
            onAccepted: root.formChanged()
            onEditingFinished: root.formChanged()
        }

        Controls.Button {
            HoverHandler { cursorShape: Qt.PointingHandCursor }
            display: Controls.AbstractButton.IconOnly
            icon.name: "document-open-folder-symbolic"
            enabled: root.selectedItemType === "folder"
            onClicked: root.folderPickerRequested()
        }
    }

    Controls.Label {
        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        visible: root.itemModeValue === "container" && containerSource.currentValue === "category"
        text: root.categoryLabel
        horizontalAlignment: Text.AlignLeft
        opacity: 0.75
    }

    Controls.ComboBox {
        id: containerCategory
        Layout.fillWidth: true
        visible: root.itemModeValue === "container" && containerSource.currentValue === "category"
        enabled: root.selectedItemType === "folder"
        textRole: "text"
        valueRole: "value"
        model: [
            { "text": "Development", "value": "Development" },
            { "text": "Games", "value": "Game" },
            { "text": "Multimedia", "value": "AudioVideo" },
            { "text": "Internet", "value": "Network" },
            { "text": "Office", "value": "Office" },
            { "text": "System", "value": "System" },
            { "text": "Utilities", "value": "Utility" },
            { "text": "Graphics", "value": "Graphics" }
        ]
        onActivated: root.containerCategoryChanged(currentValue)
    }
}
