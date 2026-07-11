function refreshFromItems(markAsChanged) {
    syncing = true
    try {
        itemModel.clear()
        for (var index = 0; index < items.length; index++) {
            itemModel.append(ConfigItemsJS.itemModelRow(items[index], i18n, i18np))
        }
        refreshItemForm()
        refreshActions()
    } finally {
        syncing = false
    }
    if (markAsChanged !== false) {
        markChanged()
    }
    Qt.callLater(StateHelper.showSelectedItem)
}

function refreshItemForm() {
    var item = StateHelper.selectedItem()
    if (!item) {
        selectedItemType = "app"
        itemName.text = ""
        itemCommand.text = ""
        actionDialog.appNameText = ""
        actionDialog.appAliasText = ""
        actionDialog.appDescriptionText = ""
        actionDialog.appIconText = ""
        actionDialog.appCommandText = ""
        actionDialog.appStorageId = ""
        actionDialog.appApplicationId = ""
        actionDialog.itemModeIndex = 0
        actionDialog.spacerSizeValue = 24
        actionDialog.containerSourceIndex = 0
        actionDialog.containerPathText = ""
        actionDialog.containerCategoryIndex = 0
        trashDialog.nameText = ""
        trashDialog.emptyIconText = ""
        trashDialog.fullIconText = ""
        calendarFormat.editText = ""
        calendarBackgroundColor.text = ""
        calendarAccentColor.text = ""
        calendarBorderColor.text = ""
        calendarRadius.value = 0
        calendarDisplayMode.currentIndex = 0
        calendarFormat.editText = "HH:mm"
        timedItemWidth.value = 0
        timedTextScale.value = 1.15
        trashDialog.soundPath = defaultTrashEmptySound
        trashDialog.showStateChecked = true
        trashDialog.acceptDropsChecked = true
        actionDialog.actionsEnabledChecked = false
        actionDialog.containerLayoutIndex = 0
        actionDialog.radialBackgroundChecked = true
        actionDialog.radialIconSlotsChecked = true
        actionDialog.fanCenterDistanceValue = 0
        return
    }

    selectedItemType = item.type || "app"
    itemName.text = item.name || ""
    itemCommand.text = item.command || ""
    actionDialog.appNameText = item.name || ""
    actionDialog.appAliasText = ""
    actionDialog.appDescriptionText = item.description || ""
    actionDialog.appIconText = item.icon || ""
    actionDialog.appCommandText = item.command || ""
    actionDialog.appStorageId = item.storageId || ""
    actionDialog.appApplicationId = item.appId || ConfigItemsJS.applicationIdForCommand(item.command || "")
    actionDialog.itemModeIndex = item.type === "folder" ? 1 : (item.type === "note" ? 2 : (item.type === "separator" ? 3 : (item.type === "spacer" ? 4 : 0)))
    actionDialog.containerLayoutIndex = actionDialog.layoutIndexFor(item.layout || "grid")
    actionDialog.containerShowLabelsChecked = item.showLabels === undefined ? true : item.showLabels
    actionDialog.radialBackgroundChecked = item.radialBackground === undefined ? true : item.radialBackground
    actionDialog.radialIconSlotsChecked = item.radialIconSlots === undefined ? true : item.radialIconSlots
    actionDialog.radialDistanceValue = item.radialDistance || 0
    actionDialog.fanCenterDistanceValue = item.fanCenterDistance || 0
    actionDialog.spacerSizeValue = item.size || 24
    actionDialog.containerSourceIndex = actionDialog.sourceIndexFor(item.sourceType || "manual")
    actionDialog.containerPathText = item.sourcePath || ""
    actionDialog.containerCategoryIndex = actionDialog.categoryIndexFor(item.sourceCategory || "Development")
    trashDialog.nameText = item.name || ""
    trashDialog.emptyIconText = item.icon || ""
    trashDialog.fullIconText = item.fullIcon || ""
    calendarFormat.editText = item.format || "HH:mm"
    timedTextScale.value = item.textScale === undefined ? 1.15 : item.textScale

    trashDialog.soundPath = item.emptySound || defaultTrashEmptySound
    trashDialog.showStateChecked = item.showState === undefined ? true : item.showState
    trashDialog.acceptDropsChecked = item.acceptDrops === undefined ? true : item.acceptDrops
    actionDialog.actionsEnabledChecked = selectedItemType === "app" && item.actions instanceof Array && item.actionsEnabled !== false
}

function refreshActions() {
    actionModel.clear()
    var item = StateHelper.selectedItem()
    if (!item || (item.type !== "folder" && ((item.type || "app") !== "app" || !(item.actions instanceof Array)))) {
        selectedActionIndex = -1
        refreshActionForm()
        return
    }

    var rows = item.type === "folder" ? (item.apps || []) : item.actions
    for (var index = 0; index < rows.length; index++) {
        actionModel.append(item.type === "folder"
            ? ConfigItemsJS.folderAppModelRow(rows[index], item.icon, i18n)
            : ConfigItemsJS.actionModelRow(rows[index], item.icon, i18n))
    }
    selectedActionIndex = rows.length > 0 ? Math.min(Math.max(selectedActionIndex, 0), rows.length - 1) : -1
    refreshActionForm()
}

function refreshActionForm() {
    var action = StateHelper.selectedAction()
    actionDialog.actionNameText = action ? action.name || "" : ""
    actionDialog.actionIconText = action ? action.icon || "" : ""
    actionDialog.actionCommandText = action ? action.command || "" : ""
}

function applyItemForm(force) {
    if ((!force && syncing) || selectedIndex < 0 || selectedIndex >= items.length) {
        return
    }

    var nextItems = ConfigItemsJS.clone(items)
    var item = nextItems[selectedIndex]
    item.type = item.type || "app"

    if (item.type === "separator") {
        ConfigItemsJS.pruneSeparator(item)
    } else if (item.type === "spacer") {
        item.size = actionDialog.spacerSizeValue
        ConfigItemsJS.pruneSpacer(item)
    } else if (item.type === "note") {
        item.name = actionDialog.appNameText || "Note"
        item.icon = actionDialog.appIconText || "knotes"
        item.note = item.note || ""
        item.popupWidth = item.popupWidth || 360
        item.popupHeight = item.popupHeight || 260
        ConfigItemsJS.pruneNote(item)
    } else if (item.type === "clock") {
        item.name = itemName.text || "Clock"
        item.mode = clockMode.currentValue || "digital"
        item.format = calendarFormat.editText || "HH:mm"
        item.fontFamily = selectedClockFontFamily()
        item.color = clockColor.text
        item.width = timedItemWidth.value
        item.textScale = timedTextScale.value
        if (item.mode === "analog") {
            item.showSeconds = analogShowSeconds.checked
            item.analogCustomAppearance = analogCustomAppearance.checked
            if (analogCustomAppearance.checked) {
                item.analogAccentColor = analogAccentColor.text
                item.analogTickColor = analogTickColor.text
                item.analogBorderColor = analogBorderColor.text
                item.analogFaceColor = analogFaceColor.text
            }
        }
        ConfigItemsJS.pruneClock(item)
    } else if (item.type === "calendar") {
        item.name = itemName.text || "Calendar"
        item.color = clockColor.text
        item.backgroundColor = calendarBackgroundColor.text
        item.accentColor = calendarAccentColor.text
        item.borderColor = calendarBorderColor.text
        item.radius = calendarRadius.value
        item.format = calendarFormat.editText || "HH:mm"
        ConfigItemsJS.pruneCalendar(item)
    } else if (item.type === "trash") {
        item.name = trashDialog.nameText || "Trash"
        item.icon = trashDialog.emptyIconText || "user-trash"
        item.fullIcon = trashDialog.fullIconText || "user-trash-full"
        item.emptySound = trashDialog.soundPath || defaultTrashEmptySound
        item.showState = trashDialog.showStateChecked
        item.acceptDrops = trashDialog.acceptDropsChecked
        ConfigItemsJS.pruneTrash(item)
    } else if (item.type === "folder") {
        item.name = actionDialog.appNameText || "Folder"
        item.icon = actionDialog.appIconText || "folder"
        item.layout = actionDialog.containerLayoutValue || "grid"
        item.showLabels = actionDialog.containerShowLabelsChecked
        item.radialBackground = actionDialog.radialBackgroundChecked
        item.radialIconSlots = actionDialog.radialIconSlotsChecked
        item.radialDistance = actionDialog.radialDistanceValue
        item.fanCenterDistance = actionDialog.fanCenterDistanceValue
        item.sourceType = actionDialog.containerSourceValue || "manual"
        item.sourcePath = actionDialog.containerPathText || ""
        item.sourceCategory = actionDialog.containerCategoryValue || "Development"
        item.apps = item.apps instanceof Array ? item.apps : []
        ConfigItemsJS.pruneFolder(item)
    } else {
        item.type = "app"
        item.name = actionDialog.appNameText || "Application"
        item.description = actionDialog.appDescriptionText || ""
        item.command = actionDialog.appCommandText
        item.icon = appIconWithCommandFallback(actionDialog.appIconText, item.command)
        item.storageId = String(actionDialog.appStorageId || "").trim()
        item.appId = ConfigItemsJS.normalizedApplicationId(
            String(actionDialog.appApplicationId || "")
            || String(item.storageId || "")
            || ConfigItemsJS.applicationIdForCommand(item.command)
        )
        if (actionDialog.actionsEnabledChecked) {
            item.actions = item.actions instanceof Array ? item.actions : []
            delete item.actionsEnabled
        } else {
            item.actionsEnabled = false
        }
        ConfigItemsJS.pruneApp(item)
    }

    items = nextItems
    refreshFromItems()
}

function applyActionForm(force) {
    if (!force && syncing) {
        return
    }

    var item = StateHelper.selectedItem()
    if (!item || selectedActionIndex < 0) {
        return
    }

    if (item.type === "folder") {
        if (!(item.apps instanceof Array)) {
            return
        }
        items = ConfigItemsJS.applyContainerApp(items, selectedIndex, selectedActionIndex, actionDialog.actionNameText, actionDialog.actionIconText, actionDialog.actionCommandText)
    } else {
        if ((item.type || "app") !== "app" || !(item.actions instanceof Array)) {
            return
        }
        items = ConfigItemsJS.applyAction(items, selectedIndex, selectedActionIndex, actionDialog.actionNameText, actionDialog.actionIconText, actionDialog.actionCommandText)
    }
    refreshActions()
    markChanged()
    Qt.callLater(StateHelper.showSelectedAction)
}

function applyDiscoveredApplication(application) {
    actionDialog.appNameText = application.name || ""
    actionDialog.appDescriptionText = application.description || ""
    actionDialog.appIconText = application.icon || ""
    actionDialog.appCommandText = application.command || ""
    actionDialog.appStorageId = application.storageId || ""
    actionDialog.appApplicationId = application.appId || ConfigItemsJS.normalizedApplicationId(application.storageId || "")
    applyItemForm(true)
}

function applyContainerApps(apps) {
    if (selectedIndex < 0 || selectedIndex >= items.length) {
        return
    }

    var nextItems = ConfigItemsJS.clone(items)
    var item = nextItems[selectedIndex]
    if (!item || item.type !== "folder") {
        return
    }

    item.apps = apps instanceof Array ? apps : []
    ConfigItemsJS.pruneFolder(item)
    items = nextItems
    refreshFromItems()
    mainView.showStatus(i18n("%1 items loaded.", item.apps.length), Kirigami.MessageType.Information)
}
