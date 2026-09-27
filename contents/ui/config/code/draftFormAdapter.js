// Adapter between the item form and the draft of the «Add item» dialog.
//
// The business rules of every type live in `configItems.js` (the `prune*`
// functions), which both the existing action dialog and this flow use; this
// module only names fields, so no rule is duplicated here.
//
// The draft is the only copy of the data: `fieldsFor()` reads the form into a
// plain object that the controller merges into the draft, and `applyToPanel()`
// pushes the draft back into the form when a draft starts.

.import "configItems.js" as ConfigItemsJS
.import "configItemsController.js" as ConfigItemsControllerJS

// Index of the panel's own mode switch for a catalogue type. The panel keeps
// that switch hidden while the dialog owns the type, but its value drives which
// fields the panel shows.
function modeIndexForType(type) {
    if (type === "folder") {
        return 1
    }
    if (type === "note") {
        return 2
    }
    if (type === "separator") {
        return 3
    }
    if (type === "spacer") {
        return 4
    }
    return 0
}

// Types this adapter knows how to move between the form and the draft.
function handlesType(type) {
    return ["app", "folder", "note", "separator", "spacer",
        "dynamic-applications"].indexOf(String(type)) >= 0
}

function separatorFieldsFor(panel) {
    return {
        "separatorAppearanceSource": panel.separatorAppearanceSourceValue,
        "separatorStyle": panel.separatorStyleValue,
        "separatorThickness": panel.separatorThicknessValue,
        "separatorLengthRatio": panel.separatorLengthRatioValue,
        "separatorOpacity": panel.separatorOpacityValue,
        "separatorGlowEnabled": panel.separatorGlowEnabled,
        "showSeparator": panel.separatorVisibleChecked
    }
}

// Values the form is currently showing, ready to be merged into the draft.
function fieldsFor(draft, panel, type) {
    const kind = String(type)
    if (kind === "app") {
        const command = String(panel.appCommandText || "")
        return {
            "name": String(panel.appNameText || ""),
            "description": String(panel.appDescriptionText || ""),
            "command": command,
            "icon": String(panel.appIconText || "application-x-executable"),
            "appId": ConfigItemsJS.normalizedApplicationId(
                ConfigItemsJS.applicationIdForCommand(command))
        }
    }
    if (kind === "folder") {
        return {
            "name": String(panel.appNameText || ""),
            "icon": String(panel.appIconText || "folder"),
            "layout": String(panel.containerLayoutValue || "grid"),
            "sourceType": String(panel.containerSourceValue || "manual"),
            "sourcePath": String(panel.containerPathText || ""),
            "sourceCategory": String(panel.containerCategoryValue || "Development")
        }
    }
    if (kind === "note") {
        return {
            "name": String(panel.appNameText || ""),
            "icon": String(panel.appIconText || "knotes")
        }
    }
    if (kind === "spacer") {
        return {"size": Number(panel.spacerSizeValue)}
    }
    if (kind === "separator" || kind === "dynamic-applications") {
        return separatorFieldsFor(panel)
    }
    return {}
}

// Values the options panels of the extracted types show. They are read through a
// function, and the bindings that call it also read the revision of the draft, so
// a value written by any other path reaches the control even though a plain
// JavaScript object does not notify its changes.
//
// The normalization comes from `configItems.js`, the single owner of the valid
// modes: the panels keep the visible list and their texts, not a second set of
// rules.
function punchiMenuOptions(draft) {
    const item = draft === null ? {} : draft
    return {
        "menuMode": ConfigItemsJS.normalizedPunchiMenuMode(item.menuMode),
        "icon": ConfigItemsJS.normalizedPunchiMenuIcon(item.icon)
    }
}

function controlCenterOptions(draft) {
    const item = draft === null ? {} : draft
    return {
        "controlCenterMode": ConfigItemsJS.normalizedControlCenterMode(
            item.controlCenterMode)
    }
}

// Values the media options panel shows. They come from the canonical readers of
// `configItems.js`, so the panel and the page never disagree about what an absent
// field means.
function mediaOptions(draft) {
    const item = draft === null ? {} : draft
    return {
        "selectedStorageId": String(item.defaultPlayerStorageId || ""),
        "mediaTextMode": ConfigItemsJS.normalizedMediaTextMode(item.mediaTextMode),
        "mediaDisplayMode": ConfigItemsJS.normalizedMediaDisplayMode(
            item.mediaDisplayMode),
        "openPlayerMinimized": item.openPlayerMinimized === true,
        "autoCollapseDelaySeconds":
            ConfigItemsJS.normalizedMediaAutoCollapseDelaySeconds(
                item.mediaAutoCollapseDelaySeconds)
    }
}

// Fields a chosen player writes into the draft. The application arrives as whoever
// discovered it described it; the shape of the four fields is the one the page
// stores for an existing item, and the identifier is normalized by the canonical
// helper, so both flows keep the same data.
function mediaPlayerFields(application) {
    const selected = application || {}
    const storageId = String(selected.storageId || "").trim()
    if (storageId.length === 0) {
        return {
            "defaultPlayerStorageId": "",
            "defaultPlayerAppId": "",
            "defaultPlayerName": "",
            "defaultPlayerIcon": ""
        }
    }
    return {
        "defaultPlayerStorageId": storageId,
        "defaultPlayerAppId": ConfigItemsJS.normalizedApplicationId(
            selected.appId || storageId),
        "defaultPlayerName": String(selected.name || storageId),
        "defaultPlayerIcon": String(selected.icon || "applications-multimedia")
    }
}

// Values the trash options panel shows. The sound the element does not declare is
// the one a new one ships with, which the caller passes in.
function trashOptions(draft, defaultSoundPath) {
    const item = draft === null ? {} : draft
    return {
        "name": String(item.name || ""),
        "icon": String(item.icon || "user-trash"),
        "fullIcon": String(item.fullIcon || "user-trash-full"),
        "showState": ConfigItemsJS.normalizedTrashShowState(item.showState),
        "acceptDrops": ConfigItemsJS.normalizedTrashAcceptDrops(item.acceptDrops),
        "soundPath": String(item.emptySound || defaultSoundPath || "")
    }
}

// Fields the trash panel writes into the draft.
function trashFields(panel) {
    return {
        "name": String(panel.nameText || ""),
        "icon": String(panel.emptyIconText || "user-trash"),
        "fullIcon": String(panel.fullIconText || "user-trash-full"),
        "showState": Boolean(panel.showStateChecked),
        "acceptDrops": Boolean(panel.acceptDropsChecked),
        "emptySound": String(panel.soundPath || "")
    }
}

// Visible name of a sound file. The rule lives in `configItemsController.js`, which
// the page also uses, so the panel shows exactly the same name in both flows.
function soundFileName(path) {
    return ConfigItemsControllerJS.fileName(path)
}

// Values the calendar options panel shows. They come from the canonical readers of
// `configItems.js`, so the panel and the page never disagree about what an absent
// field means.
function calendarOptions(draft) {
    const item = draft === null ? {} : draft
    return {
        "name": String(item.name || "Calendar"),
        "color": String(item.color || ""),
        "format": String(item.format || "HH:mm"),
        "timeTextScale": ConfigItemsJS.normalizedCalendarTimeTextScale(
            item.timeTextScale),
        "dateTextScale": ConfigItemsJS.normalizedCalendarDateTextScale(
            item.dateTextScale),
        "textShadowsEnabled": ConfigItemsJS.normalizedCalendarTextShadowsEnabled(
            item.calendarTextShadowsEnabled),
        "showWeekNumbers": ConfigItemsJS.normalizedCalendarShowWeekNumbers(
            item.showWeekNumbers),
        "popupScale": ConfigItemsJS.normalizedCalendarPopupScale(item.popupScale)
    }
}

// Fields the calendar panel writes into the draft. The values are read from the same
// controls the page reads, and the defaults mirror the ones the form helper applies
// for this type.
function calendarFields(panel) {
    return {
        "name": String(panel.itemNameControl.text || "Calendar"),
        "color": String(panel.calendarTextColorControl.text || ""),
        "format": String(panel.calendarFormatControl.editText || "HH:mm"),
        "timeTextScale": Number(panel.calendarTimeTextScaleControl.value),
        "dateTextScale": Number(panel.calendarDateTextScaleControl.value),
        "calendarTextShadowsEnabled":
            Boolean(panel.calendarTextShadowsControl.checked),
        "showWeekNumbers": Boolean(panel.calendarShowWeekNumbersControl.checked),
        "popupScale": Number(panel.calendarPopupScaleControl.value)
    }
}

// Rows of the nested list of a type, built with the same helpers the existing
// action dialog uses, so the projection of the draft shows the same fields.
function actionRows(draft, type) {
    const item = draft === null ? {} : draft
    const kind = String(type)
    const rows = kind === "folder"
        ? (Array.isArray(item.apps) ? item.apps : [])
        : (Array.isArray(item.actions) ? item.actions : [])
    const result = []
    for (let index = 0; index < rows.length; index++) {
        result.push(kind === "folder"
            ? ConfigItemsJS.folderAppModelRow(rows[index], item.icon, i18n)
            : ConfigItemsJS.actionModelRow(rows[index], item.icon, i18n))
    }
    return result
}

function actionsEnabledValue(draft) {
    const item = draft === null ? {} : draft
    return Array.isArray(item.actions) && item.actionsEnabled !== false
}

function actionPopupLimitEnabled(draft) {
    const item = draft === null ? {} : draft
    return item.actionPopupMaxVisibleRows !== undefined
        && Number.isFinite(Number(item.actionPopupMaxVisibleRows))
}

function actionPopupLimitValue(draft) {
    const item = draft === null ? {} : draft
    const value = Number(item.actionPopupMaxVisibleRows)
    return Number.isFinite(value)
        ? Math.max(1, Math.min(12, Math.round(value))) : 6
}

// Pushes the draft into the form. The caller runs it with its synchronization
// guard set, so showing the draft is never read as an edit of the user.
function applyToPanel(draft, panel, type) {
    const kind = String(type)
    const item = draft === null ? {} : draft
    panel.selectedItemType = kind === "folder" ? "folder" : kind
    panel.itemModeIndex = modeIndexForType(kind)
    // The form keeps the widget of every type, so the shared fields are always
    // written: nothing of a discarded draft may survive in the form.
    panel.appNameText = String(item.name || "")
    panel.appIconText = String(item.icon || "")
    panel.appDescriptionText = String(item.description || "")
    panel.appCommandText = String(item.command || "")
    panel.containerPathText = String(item.sourcePath || "")
    if (kind === "folder") {
        panel.containerLayoutIndex =
            panel.layoutIndexFor(String(item.layout || "grid"))
        panel.containerSourceIndex =
            panel.sourceIndexFor(String(item.sourceType || "manual"))
        panel.containerCategoryIndex =
            panel.categoryIndexFor(String(item.sourceCategory || "Development"))
    }
    if (kind === "spacer") {
        panel.spacerSizeValue = Number(item.size === undefined ? 32 : item.size)
    }
    if (kind === "separator" || kind === "dynamic-applications") {
        panel.setSeparatorAppearanceSourceValue(
            ConfigItemsJS.normalizedSeparatorAppearanceSource(item))
        panel.setSeparatorStyleValue(item.separatorStyle === "pill"
            ? "capsule" : String(item.separatorStyle || "line"))
        panel.setSeparatorThicknessValue(
            Number(item.separatorThickness === undefined
                ? 2 : item.separatorThickness))
        panel.setSeparatorLengthRatioValue(
            Number(item.separatorLengthRatio === undefined
                ? 0.72 : item.separatorLengthRatio))
        panel.setSeparatorOpacityValue(
            Number(item.separatorOpacity === undefined
                ? 0.34 : item.separatorOpacity))
        panel.setSeparatorGlowEnabled(item.separatorGlowEnabled === true)
        panel.setSeparatorVisibleChecked(item.showSeparator !== false)
    }
}
