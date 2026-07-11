function setAppActionsEnabled(enabled) {
    if (syncing || selectedIndex < 0 || selectedIndex >= items.length || selectedItemType !== "app") {
        return
    }

    if (!enabled) {
        selectedActionIndex = -1
    }
    items = ConfigItemsJS.setActionsEnabled(items, selectedIndex, enabled)
    refreshFromItems()
}

function setSelectedItemMode(mode) {
    if (syncing || selectedIndex < 0 || selectedIndex >= items.length || (selectedItemType !== "app" && selectedItemType !== "folder" && selectedItemType !== "separator" && selectedItemType !== "spacer")) {
        return
    }

    items = ConfigItemsJS.setItemMode(items, selectedIndex, mode)
    selectedItemType = mode === "container" ? "folder" : mode
    selectedActionIndex = -1
    refreshFromItems()
}

function setContainerSource(source) {
    if (syncing || selectedIndex < 0 || selectedIndex >= items.length || selectedItemType !== "folder") {
        return
    }

    var nextSource = source === "folder" || source === "category" ? source : "manual"
    var nextItems = clone(items)
    var item = nextItems[selectedIndex]
    if (!item || item.type !== "folder" || item.sourceType === nextSource) {
        return
    }

    item.sourceType = nextSource
    item.sourcePath = actionDialog.containerPathText || item.sourcePath || ""
    item.sourceCategory = actionDialog.containerCategoryValue || item.sourceCategory || "Development"
    ConfigItemsJS.pruneFolder(item)
    items = nextItems
    markChanged()
}

function setContainerLayout(layout) {
    if (syncing || selectedIndex < 0 || selectedIndex >= items.length || selectedItemType !== "folder") {
        return
    }

    var nextLayout = layout === "list" || layout === "detailed" || layout === "radial" || layout === "fan" ? layout : "grid"
    var nextItems = clone(items)
    var item = nextItems[selectedIndex]
    if (!item || item.type !== "folder" || item.layout === nextLayout) {
        return
    }

    item.layout = nextLayout
    ConfigItemsJS.pruneFolder(item)
    items = nextItems
    markChanged()
}

function setContainerCategory(category) {
    if (syncing || selectedIndex < 0 || selectedIndex >= items.length || selectedItemType !== "folder") {
        return
    }

    var nextCategory = category || "Development"
    var nextItems = clone(items)
    var item = nextItems[selectedIndex]
    if (!item || item.type !== "folder" || item.sourceCategory === nextCategory) {
        return
    }

    item.sourceCategory = nextCategory
    ConfigItemsJS.pruneFolder(item)
    items = nextItems
    markChanged()
}

function openContainerFolderPicker() {
    containerFolderDialog.open()
}

function setContainerFolder(path) {
    actionDialog.containerPathText = path || ""
    applyItemForm()
}

function refreshContainerContent() {
    var item = selectedItem()
    if (!item || item.type !== "folder") {
        return
    }

    applyItemForm()
    item = selectedItem()
    var sourceType = actionDialog.containerSourceValue || item.sourceType || "manual"
    if (sourceType === "folder") {
        var folderPath = actionDialog.containerPathText || item.sourcePath || ""
        if (folderPath.length === 0) {
            mainView.showStatus(i18n("Choose a folder first."), Kirigami.MessageType.Warning)
            return
        }
        pendingContainerSource = "folder"
        systemDiscovery.requestFolderEntries(folderPath)
    } else if (sourceType === "category") {
        pendingContainerSource = "category"
        systemDiscovery.requestApplications(actionDialog.containerCategoryValue || item.sourceCategory || "Development")
    }
}

function openAppActionsDialog(index) {
    if (index !== undefined && index >= 0 && index < items.length) {
        selectItem(index)
    }

    var item = selectedItem()
    if (!item || (item.type !== "folder" && item.type !== "note" && item.type !== "separator" && item.type !== "spacer" && (item.type || "app") !== "app")) {
        return
    }

    actionDialog.open()
    Qt.callLater(showSelectedAction)
}

function showFolderConfigDisabled(index) {
    if (index !== undefined && index >= 0 && index < items.length) {
        selectItem(index)
    }

    var item = selectedItem()
    if (!item || item.type !== "folder") {
        return
    }

    mainView.showStatus(i18n("Folder configuration was removed temporarily while it is rebuilt safely."), Kirigami.MessageType.Information)
}

function openTrashDialog(index) {
    if (index !== undefined && index >= 0 && index < items.length) {
        selectItem(index)
    }

    var item = selectedItem()
    if (!item || item.type !== "trash") {
        return
    }

    trashDialog.open()
}

function openTimedDialog(index) {
    if (index !== undefined && index >= 0 && index < items.length) {
        selectItem(index)
    }

    var item = selectedItem()
    if (!item || (item.type !== "clock" && item.type !== "calendar")) {
        return
    }

    timedDialog.open()
}

function selectedConfigureTitle() {
    if (selectedItemType === "folder") {
        return i18n("Configure folder")
    }
    if (selectedItemType === "trash") {
        return i18n("Configure trash")
    }
    if (selectedItemType === "clock") {
        return i18n("Configure clock")
    }
    if (selectedItemType === "calendar") {
        return i18n("Configure calendar")
    }
    if (selectedItemType === "note") {
        return i18n("Configure note")
    }
    if (selectedItemType === "separator") {
        return i18n("Configure separator")
    }
    if (selectedItemType === "spacer") {
        return i18n("Configure spacer")
    }
    return i18n("Configure app")
}

function configureSelectedItem() {
    if (selectedItemType === "folder" || selectedItemType === "note" || selectedItemType === "separator" || selectedItemType === "spacer") {
        openAppActionsDialog(selectedIndex)
    } else if (selectedItemType === "trash") {
        openTrashDialog(selectedIndex)
    } else if (selectedItemType === "clock" || selectedItemType === "calendar") {
        openTimedDialog(selectedIndex)
    } else {
        openAppActionsDialog(selectedIndex)
    }
}

function addItem(type) {
    var nextItems = clone(items)
    nextItems.push(ConfigItemsJS.newItem(type, defaultTrashEmptySound))
    selectedIndex = nextItems.length - 1
    setItems(nextItems)
}

function applyTimedColor(value) {
    if (timedColorTarget === "background") {
        calendarBackgroundColor.text = value
    } else if (timedColorTarget === "accent") {
        calendarAccentColor.text = value
    } else if (timedColorTarget === "border") {
        calendarBorderColor.text = value
    } else if (timedColorTarget === "analogAccent") {
    } else if (timedColorTarget === "analogTick") {
    } else if (timedColorTarget === "analogBorder") {
    } else if (timedColorTarget === "analogFace") {
    }
    applyItemForm()
}

function applyClockColor(value) {
    timedColorTarget = "text"
    applyItemForm()
}

function removeSelectedItem() {
    if (selectedIndex < 0) {
        return
    }
    var result = ConfigItemsJS.removeItem(items, selectedIndex)
    selectedIndex = result.selectedIndex
    setItems(result.items)
}

function moveSelectedItem(delta) {
    var target = selectedIndex + delta
    if (selectedIndex < 0 || target < 0 || target >= items.length) {
        return
    }
    var result = ConfigItemsJS.moveItem(items, selectedIndex, target)
    selectedIndex = result.selectedIndex
    setItems(result.items)
}

function addAction() {
    var item = selectedItem()
    if (!ConfigItemsControllerJS.itemAcceptsActions(item)) {
        return
    }
    var result = item.type === "folder"
        ? ConfigItemsJS.addContainerApp(items, selectedIndex)
        : ConfigItemsJS.addAction(items, selectedIndex)
    selectedActionIndex = result.selectedActionIndex
    items = result.items
    refreshFromItems()
    Qt.callLater(showSelectedAction)
}

function removeAction() {
    var item = selectedItem()
    if (!item || selectedActionIndex < 0) {
        return
    }
    if (!ConfigItemsControllerJS.itemHasMutableActions(item)) {
        return
    }
    var result = item.type === "folder"
        ? ConfigItemsJS.removeContainerApp(items, selectedIndex, selectedActionIndex)
        : ConfigItemsJS.removeAction(items, selectedIndex, selectedActionIndex)
    selectedActionIndex = result.selectedActionIndex
    items = result.items
    refreshFromItems()
    Qt.callLater(showSelectedAction)
}

function moveAction(delta) {
    var item = selectedItem()
    var target = selectedActionIndex + delta
    if (!ConfigItemsControllerJS.canMoveAction(item, selectedActionIndex, target)) {
        return
    }
    var result = item.type === "folder"
        ? ConfigItemsJS.moveContainerApp(items, selectedIndex, selectedActionIndex, target)
        : ConfigItemsJS.moveAction(items, selectedIndex, selectedActionIndex, target)
    selectedActionIndex = result.selectedActionIndex
    items = result.items
    refreshFromItems()
    Qt.callLater(showSelectedAction)
}

function loadItems() {
    pendingOperation = "load"
    var jsonToLoad = cfg_dockItemsJson && cfg_dockItemsJson.length > 0 ? cfg_dockItemsJson : ItemsJS.defaultJson()
    var result = ConfigItemsJS.parseJsonArray(jsonToLoad)
    if (result.ok) {
        setItems(result.items, false)
        diskItemsLoaded = true
    } else {
        console.warn("Punchi Dock: invalid dock item configuration")
        setItems([], false)
    }
}
