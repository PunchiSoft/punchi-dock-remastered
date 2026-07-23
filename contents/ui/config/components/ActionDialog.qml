import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import ".."


Controls.Dialog {
    id: root

    property var actionModel
    property int selectedActionIndex: -1
    property int selectedItemIndex: -1
    property string selectedItemType: "app"
    property real rowHeight: Kirigami.Units.gridUnit * 2.4
    property real footerHeight: Kirigami.Units.gridUnit * 2.4
    property real framePadding: Kirigami.Units.largeSpacing * 2
    property real scrollGutter: Kirigami.Units.gridUnit * 1.6
    property bool canMoveActionDown: false
    property alias appNameText: itemEditor.appNameText
    property alias appAliasText: itemEditor.appAliasText
    property alias appDescriptionText: itemEditor.appDescriptionText
    property alias appIconText: itemEditor.appIconText
    property alias appCommandText: itemEditor.appCommandText
    property string appStorageId: ""
    property string appApplicationId: ""
    readonly property string itemModeValue: itemEditor.itemModeValue
    property alias itemModeIndex: itemEditor.itemModeIndex
    readonly property string containerLayoutValue: itemEditor.containerLayoutValue
    property alias containerLayoutIndex: itemEditor.containerLayoutIndex
    property alias containerShowLabelsChecked: itemEditor.containerShowLabelsChecked
    property alias actionsEnabledChecked: actionEditor.actionsEnabledChecked
    property alias actionPopupLimitRowsChecked: actionEditor.actionPopupLimitRowsChecked
    property alias actionPopupMaxVisibleRowsValue: actionEditor.actionPopupMaxVisibleRowsValue
    property alias actionNameText: actionEditor.actionNameText
    property alias actionIconText: actionEditor.actionIconText
    property alias actionCommandText: actionEditor.actionCommandText
    property alias spacerSizeValue: itemEditor.spacerSizeValue
    property alias separatorStyleControl: itemEditor.separatorStyleControl
    property alias separatorThicknessControl: itemEditor.separatorThicknessControl
    property alias separatorLengthRatioControl: itemEditor.separatorLengthRatioControl
    property alias separatorOpacityControl: itemEditor.separatorOpacityControl
    property alias separatorGlowControl: itemEditor.separatorGlowControl
    readonly property string containerSourceValue: itemEditor.containerSourceValue
    property alias containerSourceIndex: itemEditor.containerSourceIndex
    property alias containerPathText: itemEditor.containerPathText
    readonly property string containerCategoryValue: itemEditor.containerCategoryValue
    property alias containerCategoryIndex: itemEditor.containerCategoryIndex
    property int actionCount: actionEditor.actionCount

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
    property string showContainerLabelsText: "Show labels"
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
    property string rightClickCommandsText: "Right-click commands"
    property string containerApplicationsText: "Container applications"
    property string enableRightClickMenuText: "Enable right-click menu"
    property string limitContextMenuRowsText: "Limit menu rows"
    property string rowsText: i18n("rows")
    property string rowsValueText: i18n("%1 rows")
    property string actionNameLabel: "Action name:"
    property string actionIconLabel: "Action icon:"
    property string actionCommandLabel: "Action command:"

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
    signal actionsEnabledToggled(bool checked)
    signal actionSelected(int index)
    signal addActionRequested()
    signal moveActionRequested(int delta)
    signal removeActionRequested()
    signal actionFormChanged()

    function positionActionAtIndex(index) {
        actionEditor.positionActionAtIndex(index)
    }

    function sourceIndexFor(value) {
        return itemEditor.sourceIndexFor(value)
    }

    function categoryIndexFor(value) {
        return itemEditor.categoryIndexFor(value)
    }

    function layoutIndexFor(value) {
        return itemEditor.layoutIndexFor(value)
    }

    function iconPreview(value, fallback) {
        var text = String(value || "")
        return text.length > 0 ? text : fallback
    }

    modal: true
    standardButtons: Controls.Dialog.Close

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        ItemEditorPanel {
            id: itemEditor
            selectedItemType: root.selectedItemType
            nameLabel: root.nameLabel
            aliasLabel: root.aliasLabel
            descLabel: root.descLabel
            aliasPlaceholder: root.aliasPlaceholder
            itemTypeLabel: root.itemTypeLabel
            launchAppText: root.launchAppText
            containerText: root.containerText
            viewLabel: root.viewLabel
            gridText: root.gridText
            listText: root.listText
            detailedText: root.detailedText
            showContainerLabelsText: root.showContainerLabelsText
            noteText: root.noteText
            separatorText: root.separatorText
            spacerText: root.spacerText
            containerSourceLabel: root.containerSourceLabel
            manualContainerText: root.manualContainerText
            folderContainerText: root.folderContainerText
            categoryContainerText: root.categoryContainerText
            folderPathLabel: root.folderPathLabel
            categoryLabel: root.categoryLabel
            refreshContentText: root.refreshContentText
            iconLabel: root.iconLabel
            commandLabel: root.commandLabel
            spacerSizeLabel: root.spacerSizeLabel
            chooseIconText: root.chooseIconText
            onFormChanged: root.formChanged()
            onItemModeChanged: function(mode) { root.itemModeChanged(mode) }
            onContainerLayoutChanged: function(layout) { root.containerLayoutChanged(layout) }
            onContainerSourceChanged: function(source) { root.containerSourceChanged(source) }
            onContainerCategoryChanged: function(category) { root.containerCategoryChanged(category) }
            onFolderPickerRequested: root.folderPickerRequested()
            onContainerRefreshRequested: root.containerRefreshRequested()
            onAppCommandEdited: root.appCommandEdited()
            onAutofillRequested: function(alias) { root.autofillRequested(alias) }
            onIconPickerRequested: function(target) { root.iconPickerRequested(target) }
        }

        ItemActionEditor {
            id: actionEditor
            Layout.fillWidth: true
            actionModel: root.actionModel
            selectedActionIndex: root.selectedActionIndex
            selectedItemIndex: root.selectedItemIndex
            selectedItemType: root.selectedItemType
            itemModeValue: root.itemModeValue
            appIconText: root.appIconText
            rowHeight: root.rowHeight
            footerHeight: root.footerHeight
            framePadding: root.framePadding
            scrollGutter: root.scrollGutter
            canMoveActionDown: root.canMoveActionDown
            rightClickCommandsText: root.rightClickCommandsText
            containerApplicationsText: root.containerApplicationsText
            enableRightClickMenuText: root.enableRightClickMenuText
            limitContextMenuRowsText: root.limitContextMenuRowsText
            rowsText: root.rowsText
            rowsValueText: root.rowsValueText
            actionNameLabel: root.actionNameLabel
            actionIconLabel: root.actionIconLabel
            actionCommandLabel: root.actionCommandLabel
            chooseIconText: root.chooseIconText
            onActionsEnabledToggled: function(checked) { root.actionsEnabledToggled(checked) }
            onActionSelected: function(index) { root.actionSelected(index) }
            onAddActionRequested: root.addActionRequested()
            onMoveActionRequested: function(delta) { root.moveActionRequested(delta) }
            onRemoveActionRequested: root.removeActionRequested()
            onActionFormChanged: root.actionFormChanged()
            onIconPickerRequested: function(target) { root.iconPickerRequested(target) }
        }

    }
}
