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

    var nextLayout = layout === "list" || layout === "detailed" ? layout : "grid"
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
    if (!item || (item.type !== "folder" && item.type !== "note"
            && item.type !== "separator" && item.type !== "spacer"
            && item.type !== "dynamic-applications"
            && (item.type || "app") !== "app")) {
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

function openMediaPlayerDialog(index) {
    if (index !== undefined && index >= 0 && index < items.length) {
        selectItem(index)
    }

    var item = selectedItem()
    if (!item || item.type !== "media") {
        return
    }

    mediaPlayerDialog.applications = []
    mediaPlayerDialog.selectedStorageId = String(item.defaultPlayerStorageId || "")
    mediaPlayerDialog.mediaTextMode = String(item.mediaTextMode || "automatic")
    mediaPlayerDialog.mediaDisplayMode = String(item.mediaDisplayMode || "normal") === "compact"
        ? "compact"
        : "normal"
    mediaPlayerDialog.openPlayerMinimized = item.openPlayerMinimized === true
    mediaPlayerDialog.autoCollapseDelaySeconds = Number.isFinite(
        Number(item.mediaAutoCollapseDelaySeconds))
        ? Math.max(0, Math.min(30, Math.round(Number(item.mediaAutoCollapseDelaySeconds))))
        : 3
    mediaPlayerDialog.open()
    pendingApplicationListTarget = "media"
    systemDiscovery.requestApplications("AudioVideo")
}

function openPunchiMenuDialog(index) {
    if (index !== undefined && index >= 0 && index < items.length) {
        selectItem(index)
    }

    var item = selectedItem()
    if (!item || item.type !== "punchimenu") {
        return
    }

    punchiMenuDialog.menuMode = ConfigItemsJS.normalizedPunchiMenuMode(
        item.menuMode)
    punchiMenuDialog.iconName = ConfigItemsJS.normalizedPunchiMenuIcon(
        item.icon)
    punchiMenuDialog.open()
}

function setPunchiMenuIcon(iconName) {
    if (selectedIndex < 0 || selectedIndex >= items.length) {
        return
    }

    var nextItems = clone(items)
    var item = nextItems[selectedIndex]
    if (!item || item.type !== "punchimenu") {
        return
    }

    item.icon = ConfigItemsJS.normalizedPunchiMenuIcon(iconName)
    ConfigItemsJS.prunePunchiMenu(item)
    setItems(nextItems)
    punchiMenuDialog.iconName = item.icon
}

function setPunchiMenuMode(mode) {
    if (selectedIndex < 0 || selectedIndex >= items.length) {
        return
    }

    var nextItems = clone(items)
    var item = nextItems[selectedIndex]
    if (!item || item.type !== "punchimenu") {
        return
    }

    item.menuMode = ConfigItemsJS.normalizedPunchiMenuMode(mode)
    ConfigItemsJS.prunePunchiMenu(item)
    setItems(nextItems)
    punchiMenuDialog.menuMode = item.menuMode
}

function setMediaDefaultPlayer(application) {
    if (selectedIndex < 0 || selectedIndex >= items.length) {
        return
    }

    var nextItems = clone(items)
    var item = nextItems[selectedIndex]
    if (!item || item.type !== "media") {
        return
    }

    var selectedApplication = application || {}
    var storageId = String(selectedApplication.storageId || "").trim()
    if (storageId.length === 0) {
        delete item.defaultPlayerStorageId
        delete item.defaultPlayerAppId
        delete item.defaultPlayerName
        delete item.defaultPlayerIcon
    } else {
        item.defaultPlayerStorageId = storageId
        item.defaultPlayerAppId = ConfigItemsJS.normalizedApplicationId(
            selectedApplication.appId || storageId)
        item.defaultPlayerName = String(selectedApplication.name || storageId)
        item.defaultPlayerIcon = String(selectedApplication.icon || "applications-multimedia")
    }
    ConfigItemsJS.pruneMedia(item)
    setItems(nextItems)
    mediaPlayerDialog.selectedStorageId = String(item.defaultPlayerStorageId || "")
    mediaPlayerDialog.openPlayerMinimized = item.openPlayerMinimized === true
}

function setMediaTextMode(mode) {
    if (selectedIndex < 0 || selectedIndex >= items.length) {
        return
    }

    var nextItems = clone(items)
    var item = nextItems[selectedIndex]
    if (!item || item.type !== "media") {
        return
    }

    var normalizedMode = String(mode || "automatic")
    item.mediaTextMode = normalizedMode === "always" || normalizedMode === "hidden"
        ? normalizedMode
        : "automatic"
    ConfigItemsJS.pruneMedia(item)
    setItems(nextItems)
    mediaPlayerDialog.mediaTextMode = String(item.mediaTextMode || "automatic")
}

function setMediaDisplayMode(mode) {
    if (selectedIndex < 0 || selectedIndex >= items.length) {
        return
    }

    var nextItems = clone(items)
    var item = nextItems[selectedIndex]
    if (!item || item.type !== "media") {
        return
    }

    item.mediaDisplayMode = String(mode || "normal") === "compact"
        ? "compact"
        : "normal"
    ConfigItemsJS.pruneMedia(item)
    setItems(nextItems)
    mediaPlayerDialog.mediaDisplayMode = String(item.mediaDisplayMode || "normal")
}

function setMediaOpenPlayerMinimized(enabled) {
    if (selectedIndex < 0 || selectedIndex >= items.length) {
        return
    }

    var nextItems = clone(items)
    var item = nextItems[selectedIndex]
    if (!item || item.type !== "media") {
        return
    }

    item.openPlayerMinimized = enabled === true
    ConfigItemsJS.pruneMedia(item)
    setItems(nextItems)
    mediaPlayerDialog.openPlayerMinimized = item.openPlayerMinimized === true
}

function setMediaAutoCollapseDelaySeconds(seconds) {
    if (selectedIndex < 0 || selectedIndex >= items.length) {
        return
    }

    var nextItems = clone(items)
    var item = nextItems[selectedIndex]
    if (!item || item.type !== "media") {
        return
    }

    var requestedSeconds = Number(seconds)
    item.mediaAutoCollapseDelaySeconds = Number.isFinite(requestedSeconds)
        ? Math.max(0, Math.min(30, Math.round(requestedSeconds)))
        : 3
    ConfigItemsJS.pruneMedia(item)
    setItems(nextItems)
    mediaPlayerDialog.autoCollapseDelaySeconds = Number.isFinite(
        Number(item.mediaAutoCollapseDelaySeconds))
        ? Number(item.mediaAutoCollapseDelaySeconds)
        : 3
}

function selectedConfigureTitle() {
    if (selectedItemType === "punchimenu") {
        return i18n("Configure PunchiMenu")
    }
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
    if (selectedItemType === "dynamic-applications") {
        return i18n("Configure open applications")
    }
    if (selectedItemType === "spacer") {
        return i18n("Configure spacer")
    }
    if (selectedItemType === "media") {
        return i18n("Media player item")
    }
    return i18n("Configure app")
}

function canConfigureSelectedItem() {
    return selectedIndex >= 0
}

function configureSelectedItem() {
    if (!canConfigureSelectedItem()) {
        return
    }
    if (selectedItemType === "punchimenu") {
        openPunchiMenuDialog(selectedIndex)
    } else if (selectedItemType === "media") {
        openMediaPlayerDialog(selectedIndex)
    } else if (selectedItemType === "folder" || selectedItemType === "note"
            || selectedItemType === "separator" || selectedItemType === "spacer"
            || selectedItemType === "dynamic-applications") {
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
    if (type === "media" && hasItemType("media")) {
        mainView.showStatus(
            i18n("Only one media player item can be added."),
            Kirigami.MessageType.Information)
        return
    }
    if (type === "punchimenu" && hasItemType("punchimenu")) {
        mainView.showStatus(
            i18n("Only one PunchiMenu item can be added."),
            Kirigami.MessageType.Information)
        return
    }
    if (type === "dynamic-applications" && hasItemType("dynamic-applications")) {
        mainView.showStatus(
            i18n("Only one open applications item can be added."),
            Kirigami.MessageType.Information)
        return
    }
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
    } else {
        clockColor.text = value
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

function addApplicationLauncherToSelectedContainer(application) {
    var item = selectedItem()
    if (!item) {
        return {
            "items": items,
            "changed": false,
            "status": "invalid-target",
            "container": null
        }
    }

    var result = ConfigItemsJS.addApplicationToManualContainer(
        items, selectedIndex, application)
    if (!result.changed) {
        return result
    }

    selectedActionIndex = result.container.apps.length - 1
    items = result.items
    refreshFromItems()
    Qt.callLater(showSelectedAction)
    return result
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
