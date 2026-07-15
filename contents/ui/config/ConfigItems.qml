import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../org/punchi/dock" as Punchi

import "code/configItemsController.js" as ConfigItemsControllerJS
import "code/configItems.js" as ConfigItemsJS
import "code/configScripts.js" as ConfigScriptsJS
import "code/configUi.js" as ConfigUiJS
import "code/items.js" as ItemsJS
import "code/configItemsStateHelper.js" as StateHelper
import "code/configItemsFormHelper.js" as FormHelper
import "code/configItemsWorkflowHelper.js" as WorkflowHelper
import "components"

import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    title: i18n("Items")
    implicitWidth: layoutMetrics.pageImplicitWidth

    ConfigLayoutMetrics {
        id: layoutMetrics
        availableWidth: page.width
    }

    property string configDirectory: ConfigScriptsJS.localPath(StandardPaths.writableLocation(StandardPaths.ConfigLocation)) + "/punchi-dock"
    property string legacyConfigFile: ConfigScriptsJS.localPath(configDirectory + "/dock_items.json")
    property string configFile: ConfigScriptsJS.localPath(configDirectory + "/" + instanceConfigFileName())
    property string pendingOperation: "load"
    property string pendingContainerSource: ""
    property var items: []
    property int selectedIndex: -1
    property int selectedActionIndex: -1
    property string selectedItemType: "app"
    property bool syncing: false
    property bool loadingFromDisk: false
    property bool updatingConfigJson: false
    property bool diskItemsLoaded: false
    property string timedColorTarget: "text"
    property string cfg_dockItemsJson: ""
    property int cfg_pendingEditDockItemIndex: -1
    property alias cfg_actionPopupLimitRows: actionDialog.actionPopupLimitRowsChecked
    property alias cfg_actionPopupMaxVisibleRows: actionDialog.actionPopupMaxVisibleRowsValue
    property bool pendingEditConsumed: false
    property string iconFileDialogTarget: "item"
    property real listRowHeight: Kirigami.Units.gridUnit * 2.4
    property real listFooterHeight: Kirigami.Units.gridUnit * 2.4
    property real listFramePadding: Kirigami.Units.largeSpacing * 2
    property real listScrollGutter: Kirigami.Units.gridUnit * 1.6
    property real itemListHeight: listRowHeight * 6 + listFooterHeight + listFramePadding
    property real itemDetailsHeight: itemListHeight
    property real itemsColumnBodyHeight: Math.max(itemListHeight, page.height > 0 ? page.height - Kirigami.Units.gridUnit * 8 : itemListHeight)
    property string defaultTrashEmptySound: "/usr/share/sounds/ocean/stereo/trash-empty.oga"
    property var fontChoices: ["Anurati", "Noto Sans", "Noto Sans Mono", "Inter", "Roboto", "Ubuntu", "Cantarell", "DejaVu Sans", "Liberation Sans", "Monospace", "Serif", "Sans Serif"]
    property var colorChoices: ConfigUiJS.colorChoices()

    SystemDiscoveryManager {
        id: systemDiscovery

        onAppsDiscovered: function(apps) {
            page.applyContainerApps(apps)
        }
        onApplicationDiscovered: function(application) {
            page.applyDiscoveredApplication(application)
        }
        onOperationFailed: function(operation, message) {
            mainView.showStatus(i18n("System operation failed: %1", message), Kirigami.MessageType.Error)
        }
    }

    Punchi.DockRuntimeService {
        id: runtimeService

        // qmllint disable unqualified
        onOperationFailed: function(operation, message) {
            if (operation === "playSound") {
                mainView.showStatus(i18n("The sound could not be played: %1", message), Kirigami.MessageType.Error)
            }
        }
        // qmllint enable unqualified
    }
    property alias itemName: timedDialog.itemNameControl
    property alias timedItemWidth: timedDialog.timedItemWidthControl
    property alias timedTextScale: timedDialog.timedTextScaleControl
    property alias calendarItemHeight: timedDialog.calendarItemHeightControl
    property alias calendarFormat: timedDialog.calendarFormatControl
    property alias calendarBackgroundColor: timedDialog.calendarBackgroundColorControl
    property alias calendarAccentColor: timedDialog.calendarAccentColorControl
    property alias calendarBorderColor: timedDialog.calendarBorderColorControl
    property alias calendarRadius: timedDialog.calendarRadiusControl
    function configInstanceId() {
        var value = ""
        try {
            if (Plasmoid && Plasmoid.id !== undefined && Plasmoid.id !== null) {
                value = String(Plasmoid.id)
            }
        } catch (error) {
            value = ""
        }
        if (value.length === 0 || value === "undefined" || value === "null") {
            return "default"
        }
        return value.replace(/[^A-Za-z0-9_.-]/g, "_")
    }

    function instanceConfigFileName() {
        var instanceId = configInstanceId()
        return instanceId === "default" ? "dock_items.json" : "dock_items_" + instanceId + ".json"
    }

    function timedItemName() {
        return selectedItemType === "calendar" ? i18n("Calendar") : i18n("Clock")
    }

    function timedFontLabel() {
        return selectedItemType === "calendar" ? i18n("Calendar font:") : i18n("Clock font:")
    }

    function timedColorLabel() {
        return selectedItemType === "calendar" ? i18n("Calendar color:") : i18n("Clock color:")
    }

    function timedChooseColorTitle() {
        if (selectedItemType === "calendar") {
            if (timedColorTarget === "background") {
                return i18n("Choose calendar background color")
            }
            if (timedColorTarget === "accent") {
                return i18n("Choose calendar header color")
            }
            if (timedColorTarget === "border") {
                return i18n("Choose calendar border color")
            }
        }
        if (selectedItemType === "clock") {
            if (timedColorTarget === "analogAccent") {
                return i18n("Choose clock accent color")
            }
            if (timedColorTarget === "analogTick") {
                return i18n("Choose clock marker color")
            }
            if (timedColorTarget === "analogBorder") {
                return i18n("Choose clock border color")
            }
            if (timedColorTarget === "analogFace") {
                return i18n("Choose clock face color")
            }
        }
        return selectedItemType === "calendar" ? i18n("Choose calendar color") : i18n("Choose clock color")
    }

    function timedColorValue() {
        if (timedColorTarget === "background") {
            return calendarBackgroundColor.text
        }
        if (timedColorTarget === "accent") {
            return calendarAccentColor.text
        }
        if (timedColorTarget === "border") {
            return calendarBorderColor.text
        }
        if (timedColorTarget === "analogAccent") {
        return ""
        }
        if (timedColorTarget === "analogTick") {
        return ""
        }
        if (timedColorTarget === "analogBorder") {
        return ""
        }
        if (timedColorTarget === "analogFace") {
        return ""
        }
        return ""
    }

    function timedFallbackColor() {
        if (timedColorTarget === "background") {
            return Kirigami.Theme.backgroundColor
        }
        if (timedColorTarget === "accent") {
            return Kirigami.Theme.highlightColor
        }
        if (timedColorTarget === "border") {
            return Kirigami.Theme.textColor
        }
        if (timedColorTarget === "analogAccent") {
            return Kirigami.Theme.highlightColor
        }
        if (timedColorTarget === "analogTick") {
            return Kirigami.Theme.textColor
        }
        if (timedColorTarget === "analogBorder") {
            return Kirigami.Theme.disabledTextColor
        }
        if (timedColorTarget === "analogFace") {
            return Kirigami.Theme.backgroundColor
        }
        return Kirigami.Theme.textColor
    }

    function openTimedColorDialog(target) {
        timedColorTarget = target || "text"
        clockColorDialog.open()
    }

    function defaultTrashSoundFolder() {
        var slash = defaultTrashEmptySound.lastIndexOf("/")
        return slash > 0 ? defaultTrashEmptySound.substring(0, slash) : "/usr/share/sounds"
    }

    function openTrashSoundPicker() {
        trashSoundFileDialog.open()
    }

    function setTrashEmptySound(path) {
        trashDialog.soundPath = path && String(path).length > 0 ? String(path) : defaultTrashEmptySound
        applyItemForm()
    }

    function resolvedTrashEmptySound() {
        return trashDialog.soundPath.length > 0 ? trashDialog.soundPath : defaultTrashEmptySound
    }

    function fileName(path) {
        return ConfigItemsControllerJS.fileName(path)
    }

    function playTrashEmptySoundPreview() {
        var configuredSound = resolvedTrashEmptySound()
        runtimeService.playSound(configuredSound, "trash-empty")
    }

    function availableFonts(includeEmpty) {
        var result = []
        if (includeEmpty) {
            result.push(i18n("Automatic"))
        }
        try {
            var fonts = Qt.fontFamilies()
            if (fonts && fonts.length > 0) {
                return result.concat(fonts.sort())
            }
        } catch (error) {
        }
        return result.concat(fontChoices)
    }

    function selectedClockFontFamily() {
        return ""
    }

    function selectedComboFont(combo) {
        return ConfigItemsControllerJS.selectedComboFont(combo.editText, combo.currentText, i18n("Automatic"))
    }

    function displayFontName(value) {
        return ConfigItemsControllerJS.displayFontName(value, i18n("Automatic"))
    }

    function resetTimedColor(target) {
        if (target === "background") {
            calendarBackgroundColor.text = ""
        } else if (target === "accent") {
            calendarAccentColor.text = ""
        } else if (target === "border") {
            calendarBorderColor.text = ""
        } else if (target === "analogAccent") {
        } else if (target === "analogTick") {
        } else if (target === "analogBorder") {
        } else if (target === "analogFace") {
        } else {
        }
        applyItemForm()
    }

    function shellQuote(text) {
        return ConfigScriptsJS.shellQuote(text)
    }

    function iconPreviewSource(name) {
        return ConfigItemsJS.iconPreviewSource(name)
    }

    function appIconWithCommandFallback(icon, command) {
        return ConfigItemsJS.appIconWithCommandFallback(icon, command)
    }

    function autofillAppIconFromCommand() {
        var icon = appIconWithCommandFallback(actionDialog.appIconText, actionDialog.appCommandText)
        if (icon !== actionDialog.appIconText) {
            actionDialog.appIconText = icon
        }
        var appId = ConfigItemsJS.applicationIdForCommand(actionDialog.appCommandText)
        var currentStoredId = ConfigItemsJS.normalizedApplicationId(actionDialog.appStorageId || actionDialog.appApplicationId)
        if (appId.length > 0) {
            if (actionDialog.appStorageId.length > 0 && currentStoredId !== appId) {
                actionDialog.appStorageId = ""
            }
            actionDialog.appApplicationId = appId
        } else if (actionDialog.appStorageId.length === 0) {
            actionDialog.appApplicationId = ""
        }
        if (appId.length === 0) {
            return
        }
        if (actionDialog.appIconText.length > 0 && actionDialog.appIconText !== "application-x-executable" && actionDialog.appIconText !== appId) {
            return
        }
        actionDialog.appIconText = appId
    }

    function clone(value) {
        return ConfigItemsJS.clone(value)
    }

        function selectedItem() { return StateHelper.selectedItem() }

        function selectedAction() { return StateHelper.selectedAction() }

        function itemIconText() { return StateHelper.itemIconText() }

        function showSelectedItem() { StateHelper.showSelectedItem() }

        function showSelectedAction() { StateHelper.showSelectedAction() }

        function selectItem(index) { StateHelper.selectItem(index) }

        function compactListHeight(count, minRows, maxRows) { return StateHelper.compactListHeight(count, minRows, maxRows) }

    function setItems(nextItems, markAsChanged) {
        items = clone(nextItems)
        selectedIndex = items.length > 0 ? Math.min(Math.max(selectedIndex, 0), items.length - 1) : -1
        refreshFromItems(markAsChanged)
        consumePendingEditRequest()
    }

    function consumePendingEditRequest() {
        var pendingIndex = parseInt(cfg_pendingEditDockItemIndex, 10)
        if (pendingEditConsumed || isNaN(pendingIndex) || pendingIndex < 0 || pendingIndex >= items.length) {
            return
        }

        pendingEditConsumed = true
        cfg_pendingEditDockItemIndex = -1
        Qt.callLater(function() {
            page.selectItem(pendingIndex)
            page.configureSelectedItem()
        })
    }

    function markChanged() {
        if (!syncing) {
            updatingConfigJson = true
            cfg_dockItemsJson = JSON.stringify(items, null, 4)
            Qt.callLater(function() {
                updatingConfigJson = false
            })
        }
    }

    function syncItemsFromConfigJson() {
        if (!diskItemsLoaded || syncing || loadingFromDisk || updatingConfigJson || !cfg_dockItemsJson || cfg_dockItemsJson.length === 0) {
            return
        }

        if (JSON.stringify(items, null, 4) === cfg_dockItemsJson) {
            return
        }

        var result = ConfigItemsJS.parseJsonArray(cfg_dockItemsJson)
        if (!result.ok) {
            return
        }

        loadingFromDisk = true
        try {
            setItems(result.items, false)
        } finally {
            loadingFromDisk = false
        }
    }

        function refreshFromItems(markAsChanged) { FormHelper.refreshFromItems(markAsChanged) }

        function refreshItemForm() { FormHelper.refreshItemForm() }

        function refreshActions() { FormHelper.refreshActions() }

        function refreshActionForm() { FormHelper.refreshActionForm() }

        function applyItemForm(force) { FormHelper.applyItemForm(force) }

    function setAppActionsEnabled(enabled) { WorkflowHelper.setAppActionsEnabled(enabled) }

    function setSelectedItemMode(mode) { WorkflowHelper.setSelectedItemMode(mode) }

    function setContainerSource(source) { WorkflowHelper.setContainerSource(source) }

    function setContainerLayout(layout) { WorkflowHelper.setContainerLayout(layout) }

    function setContainerCategory(category) { WorkflowHelper.setContainerCategory(category) }

    function openContainerFolderPicker() { WorkflowHelper.openContainerFolderPicker() }

    function setContainerFolder(path) { WorkflowHelper.setContainerFolder(path) }

    function refreshContainerContent() { WorkflowHelper.refreshContainerContent() }

        function applyDiscoveredApplication(application) { FormHelper.applyDiscoveredApplication(application) }

        function applyContainerApps(apps) { FormHelper.applyContainerApps(apps) }

    function openAppActionsDialog(index) { WorkflowHelper.openAppActionsDialog(index) }

    function showFolderConfigDisabled(index) { WorkflowHelper.showFolderConfigDisabled(index) }

    function openTrashDialog(index) { WorkflowHelper.openTrashDialog(index) }

    function openTimedDialog(index) { WorkflowHelper.openTimedDialog(index) }

    function selectedConfigureTitle() { return WorkflowHelper.selectedConfigureTitle() }

    function configureSelectedItem() { WorkflowHelper.configureSelectedItem() }

        function applyActionForm(force) { FormHelper.applyActionForm(force) }

    function addItem(type) { WorkflowHelper.addItem(type) }

    function openIconPicker(target) {
        iconFileDialogTarget = target || "item"
        iconFileDialog.open()
    }

    function chooseIconFile(fileUrl) {
        var selectedIcon = String(fileUrl || "")
        if (selectedIcon.length === 0) {
            return
        }

        if (iconFileDialogTarget === "action") {
            actionDialog.actionIconText = selectedIcon
            applyActionForm()
            return
        }

        if (iconFileDialogTarget === "trashFull") {
            trashDialog.fullIconText = selectedIcon
            applyItemForm()
            return
        }

        if (iconFileDialogTarget === "trash") {
            trashDialog.emptyIconText = selectedIcon
            applyItemForm()
            return
        }

        actionDialog.appIconText = selectedIcon
        applyItemForm()
    }

    function applyTimedColor(value) { WorkflowHelper.applyTimedColor(value) }

    function applyClockColor(value) { WorkflowHelper.applyClockColor(value) }

    function removeSelectedItem() { WorkflowHelper.removeSelectedItem() }

    function moveSelectedItem(delta) { WorkflowHelper.moveSelectedItem(delta) }

    function addAction() { WorkflowHelper.addAction() }

    function removeAction() { WorkflowHelper.removeAction() }

    function moveAction(delta) { WorkflowHelper.moveAction(delta) }

    function loadItems() { WorkflowHelper.loadItems() }

    Component.onCompleted: {
        loadItems()
    }

    onCfg_dockItemsJsonChanged: syncItemsFromConfigJson()

    Component.onDestruction: {
        if (pendingEditConsumed) {
            cfg_pendingEditDockItemIndex = -1
        }
    }

    ListModel {
        id: itemModel
    }

    ListModel {
        id: actionModel
    }





    Timer {
        id: statusHideTimer
        interval: 3500
        repeat: false
        onTriggered: mainView.clearStatus()
    }

    IconFileDialog {
        id: iconFileDialog
        titleText: i18n("Choose icon file")
        imageFilesText: i18n("Image files")
        allFilesText: i18n("All files")
        onIconChosen: page.chooseIconFile(fileUrl)
    }

    FolderPathDialog {
        id: containerFolderDialog
        titleText: i18n("Choose folder")
        onFolderChosen: page.setContainerFolder(path)
    }

    ColorPaletteDialog {
        id: clockColorDialog
        title: page.timedChooseColorTitle()
        width: Math.min(page.width - Kirigami.Units.largeSpacing * 2, Kirigami.Units.gridUnit * 24)
        currentColor: page.timedColorValue()
        fallbackColor: page.timedFallbackColor()
        colorChoices: page.colorChoices
        themeText: i18n("Plasma theme")
        onColorChosen: page.applyTimedColor(color)
        onThemeChosen: page.applyTimedColor("")
    }

    ActionDialog {
        id: actionDialog
        title: page.selectedConfigureTitle()
        width: Math.min(page.width - Kirigami.Units.largeSpacing * 2, Kirigami.Units.gridUnit * 32)
        actionModel: actionModel
        selectedActionIndex: page.selectedActionIndex
        selectedItemIndex: page.selectedIndex
        selectedItemType: page.selectedItemType
        rowHeight: page.listRowHeight
        footerHeight: page.listFooterHeight
        framePadding: page.listFramePadding
        scrollGutter: page.listScrollGutter
        canMoveActionDown: {
            var item = page.selectedItem()
            var rows = item && item.type === "folder" ? item.apps : (item ? item.actions : [])
            return rows && page.selectedActionIndex >= 0 && page.selectedActionIndex < rows.length - 1
        }
        nameLabel: i18n("Name:")
        aliasLabel: i18n("Alias/Quick Search:")
        descLabel: i18n("Description:")
        aliasPlaceholder: i18n("Press Enter to search...")
        itemTypeLabel: i18n("Type:")
        launchAppText: i18n("Launch app")
        containerText: i18n("Container")
        viewLabel: i18n("View:")
        gridText: i18n("Grid")
        listText: i18n("List")
        detailedText: i18n("Detailed")
        radialText: i18n("Radial")
        fanText: i18n("Fan")
        showContainerLabelsText: i18n("Show labels")
        radialBackgroundText: i18n("Show radial background")
        radialIconSlotsText: i18n("Show icon circles")
        radialDistanceLabel: i18n("Radial distance:")
        fanCenterDistanceLabel: i18n("Fan spread:")
        noteText: i18n("Note")
        separatorText: i18n("Separator")
        spacerText: i18n("Spacer")
        iconLabel: i18n("Icon:")
        commandLabel: i18n("Command:")
        spacerSizeLabel: i18n("Spacer size:")
        chooseIconText: i18n("Choose icon")
        rightClickCommandsText: i18n("Right-click commands")
        containerApplicationsText: i18n("Container applications")
        containerSourceLabel: i18n("Content:")
        manualContainerText: i18n("Manual")
        folderContainerText: i18n("Folder")
        categoryContainerText: i18n("Application category")
        folderPathLabel: i18n("Folder:")
        categoryLabel: i18n("Category:")
        refreshContentText: i18n("Load content")
        enableRightClickMenuText: i18n("Enable right-click menu")
        limitContextMenuRowsText: i18n("Limit menu rows")
        rowsText: i18n("rows")
        rowsValueText: i18n("%1 rows")
        actionNameLabel: page.selectedItemType === "folder" ? i18n("App name:") : i18n("Action name:")
        actionIconLabel: page.selectedItemType === "folder" ? i18n("App icon:") : i18n("Action icon:")
        actionCommandLabel: page.selectedItemType === "folder" ? i18n("App command:") : i18n("Action command:")
        onFormChanged: page.applyItemForm()
        onItemModeChanged: function(mode) { page.setSelectedItemMode(mode) }
        onContainerLayoutChanged: function(layout) { page.setContainerLayout(layout) }
        onContainerSourceChanged: function(source) { page.setContainerSource(source) }
        onContainerCategoryChanged: function(category) { page.setContainerCategory(category) }
        onFolderPickerRequested: page.openContainerFolderPicker()
        onContainerRefreshRequested: page.refreshContainerContent()
        onAppCommandEdited: {
            page.autofillAppIconFromCommand()
            page.applyItemForm()
        }
        onAutofillRequested: function(alias) {
            if (alias && alias.length > 0) {
                systemDiscovery.requestApplication(alias)
            }
        }
        onIconPickerRequested: function(target) { page.openIconPicker(target) }
        onActionsEnabledToggled: function(checked) { page.setAppActionsEnabled(checked) }
        onActionSelected: function(index) {
            page.selectedActionIndex = index
            page.refreshActionForm()
            page.showSelectedAction()
        }
        onAddActionRequested: page.addAction()
        onMoveActionRequested: function(delta) { page.moveAction(delta) }
        onRemoveActionRequested: page.removeAction()
        onActionFormChanged: page.applyActionForm()
    }

    TrashDialog {
        id: trashDialog
        width: Math.min(page.width - Kirigami.Units.largeSpacing * 2, Kirigami.Units.gridUnit * 42)
        height: Math.min(page.height - Kirigami.Units.largeSpacing * 2, implicitHeight + Kirigami.Units.gridUnit * 2)
        controller: page
        onFormChanged: page.applyItemForm()
        onEmptyIconPickerRequested: page.openIconPicker("trash")
        onFullIconPickerRequested: page.openIconPicker("trashFull")
        onSoundPreviewRequested: page.playTrashEmptySoundPreview()
        onSoundResetRequested: {
            trashDialog.soundPath = page.defaultTrashEmptySound
            page.applyItemForm()
        }
        onSoundPickerRequested: page.openTrashSoundPicker()
    }

    TimedDialog {
        id: timedDialog
        controller: page
    }

    Controls.TextField {
        id: itemCommand
        visible: false
    }

    SoundFileDialog {
        id: trashSoundFileDialog
        title: i18n("Choose sound")
        startFolder: "file://" + page.defaultTrashSoundFolder()
        audioFilesText: i18n("Audio files")
        allFilesText: i18n("All files")
        onSoundChosen: page.setTrashEmptySound(path)
    }

    ConfigItemsMainView {
        id: mainView
        controller: page
        itemModel: itemModel
        statusHideTimer: statusHideTimer
    }
}
