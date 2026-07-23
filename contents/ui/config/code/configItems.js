.pragma library

function clone(value) {
    return JSON.parse(JSON.stringify(value))
}

function defaultName(name, key, translate) {
    if (!name || name === key) {
        return translate(key)
    }
    var translated = translate(name)
    return translated === name ? name : translated
}

function flatpakAppIdFromCommand(command) {
    var parts = String(command || "").split(/\s+/)
    for (var index = 0; index < parts.length; index++) {
        var executable = parts[index].replace(/^['"]|['"]$/g, "")
        var slash = executable.lastIndexOf("/")
        var executableName = slash >= 0 ? executable.substring(slash + 1) : executable
        if (executableName === "gtk-launch" && index < parts.length - 1) {
            var launcher = parts[index + 1].replace(/^['"]|['"]$/g, "")
            launcher = launcher.replace(/^applications:/, "")
            launcher = launcher.replace(/\.desktop$/, "")
            return /^[A-Za-z0-9][A-Za-z0-9_.-]*\.[A-Za-z0-9_.-]+$/.test(launcher) ? launcher : ""
        }
        if (index >= parts.length - 1) {
            continue
        }
        var subcommand = parts[index + 1].replace(/^['"]|['"]$/g, "")
        if (executableName !== "flatpak" || subcommand !== "run") {
            continue
        }

        for (var runIndex = index + 2; runIndex < parts.length; runIndex++) {
            var part = parts[runIndex].replace(/^['"]|['"]$/g, "")
            if (part.length === 0 || part.indexOf("-") === 0) {
                continue
            }
            return /^[A-Za-z0-9][A-Za-z0-9_.-]*\.[A-Za-z0-9_.-]+$/.test(part) ? part : ""
        }
    }
    return ""
}

function normalizedApplicationId(value) {
    var text = String(value || "").trim()
    text = text.replace(/^applications:/, "")
    text = text.replace(/\.desktop$/, "")
    return text
}

function applicationIdForCommand(command) {
    var parts = String(command || "").split(/\s+/)
    for (var index = 0; index < parts.length; index++) {
        var executable = parts[index].replace(/^['"]|['"]$/g, "")
        var slash = executable.lastIndexOf("/")
        var executableName = slash >= 0 ? executable.substring(slash + 1) : executable
        if (executableName === "gtk-launch" && index < parts.length - 1) {
            return normalizedApplicationId(parts[index + 1].replace(/^['"]|['"]$/g, ""))
        }
        if (index < parts.length - 1 && executableName === "flatpak"
                && parts[index + 1].replace(/^['"]|['"]$/g, "") === "run") {
            for (var runIndex = index + 2; runIndex < parts.length; runIndex++) {
                var part = parts[runIndex].replace(/^['"]|['"]$/g, "")
                if (part.length === 0 || part.indexOf("-") === 0) {
                    continue
                }
                return normalizedApplicationId(part)
            }
        }
        if (executableName.length > 0) {
            return normalizedApplicationId(executableName)
        }
    }
    return ""
}

function isFlatpakLikeIconName(name) {
    var text = String(name || "").toLowerCase()
    return text.indexOf("org.") === 0 || text.indexOf("com.") === 0 || text.indexOf("io.") === 0
        || text.indexOf("net.") === 0 || text.indexOf("dev.") === 0 || text.indexOf("app.") === 0
        || text.indexOf("page.") === 0 || text.indexOf("md.") === 0
}

function iconValueForName(name) {
    var text = String(name || "")
    if (text.length === 0) {
        return text
    }
    return text
}

function iconPreviewSource(name) {
    var text = String(name || "")
    if (text.indexOf("/") === 0) {
        return "file://" + text
    }
    return text.length === 0 ? "application-x-executable" : text
}

function iconValueForCommand(command) {
    var appId = applicationIdForCommand(command)
    return appId.length > 0 ? iconValueForName(appId) : ""
}

function appIconWithCommandFallback(icon, command) {
    var text = String(icon || "")
    if (text.length > 0 && text !== "application-x-executable") {
        return text
    }
    return iconValueForCommand(command) || text || "application-x-executable"
}

function syncAppIdentity(item, command, storageId, appId) {
    var normalizedStorageId = normalizedApplicationId(storageId || "")
    var inferredAppId = normalizedApplicationId(appId || "")
    var commandAppId = applicationIdForCommand(command || "")

    if (normalizedStorageId.length > 0) {
        item.storageId = storageId
        item.appId = normalizedStorageId
        return
    }

    delete item.storageId
    item.appId = inferredAppId.length > 0 ? inferredAppId : commandAppId
}

function commandStartsWith(command, executable) {
    var text = String(command || "").trim()
    if (text.length === 0) {
        return false
    }
    var parts = text.split(/\s+/)
    if (parts.length === 0) {
        return false
    }
    var first = parts[0].replace(/^['"]|['"]$/g, "")
    var slash = first.lastIndexOf("/")
    var executableName = slash >= 0 ? first.substring(slash + 1) : first
    return executableName === executable
}

function appActionPreset(command, storageId, appId) {
    var commandId = normalizedApplicationId(applicationIdForCommand(command || ""))
    var normalizedStorageId = normalizedApplicationId(storageId || "")
    var normalizedAppId = normalizedApplicationId(appId || "")
    var identities = [normalizedStorageId, normalizedAppId, commandId]

    function hasIdentity(candidates) {
        for (var candidateIndex = 0; candidateIndex < candidates.length; candidateIndex++) {
            var candidate = normalizedApplicationId(candidates[candidateIndex])
            if (candidate.length === 0) {
                continue
            }
            for (var identityIndex = 0; identityIndex < identities.length; identityIndex++) {
                if (identities[identityIndex] === candidate) {
                    return true
                }
            }
        }
        return false
    }

    if (hasIdentity(["firefox", "org.mozilla.firefox"])) {
        return {
            "baseCommand": commandStartsWith(command, "flatpak") ? "flatpak run org.mozilla.firefox" : "firefox",
            "actions": [
                { "name": "New window", "icon": "window-new", "args": "--new-window" },
                { "name": "New private window", "icon": "view-private", "args": "--private-window" }
            ]
        }
    }

    if (hasIdentity(["org.kde.konsole", "konsole"])) {
        return {
            "baseCommand": commandStartsWith(command, "flatpak") ? "flatpak run org.kde.konsole" : "konsole",
            "actions": [
                { "name": "New window", "icon": "window-new", "args": "--new-window" },
                { "name": "New tab", "icon": "tab-new", "args": "--new-tab" }
            ]
        }
    }

    if (hasIdentity(["org.kde.dolphin", "dolphin"])) {
        return {
            "baseCommand": commandStartsWith(command, "flatpak") ? "flatpak run org.kde.dolphin" : "dolphin",
            "actions": [
                { "name": "New window", "icon": "window-new", "args": "--new-window" },
                { "name": "Home", "icon": "go-home", "args": "~" }
            ]
        }
    }

    return null
}

function suggestedActionsForApp(command, storageId, appId) {
    var preset = appActionPreset(command, storageId, appId)
    if (!preset || !(preset.actions instanceof Array) || preset.actions.length === 0) {
        return []
    }

    var baseCommand = String(preset.baseCommand || "").trim()
    if (baseCommand.length === 0) {
        return []
    }

    var actions = []
    for (var index = 0; index < preset.actions.length; index++) {
        var template = preset.actions[index]
        if (!template) {
            continue
        }

        var suffix = String(template.args || "").trim()
        var action = {
            "name": template.name || "Custom action",
            "icon": template.icon || "system-run",
            "command": suffix.length > 0 ? (baseCommand + " " + suffix) : baseCommand
        }
        syncAppIdentity(action, action.command, "", "")
        actions.push(action)
    }
    return actions
}

function maybeSeedSuggestedActions(item, command, storageId, appId) {
    if (!item || (item.type || "app") !== "app" || item.actionsEnabled === false) {
        return false
    }
    if (item.actions instanceof Array && item.actions.length > 0) {
        return false
    }

    var actions = suggestedActionsForApp(command, storageId, appId)
    if (actions.length === 0) {
        return false
    }

    item.actions = actions
    delete item.actionsEnabled
    return true
}

function itemTitle(item, translate) {
    if (!item) {
        return ""
    }
    if (item.type === "separator") {
        return translate("Separator")
    }
    if (item.type === "spacer") {
        return translate("Spacer")
    }
    if (item.type === "clock") {
        return defaultName(item.name, "Clock", translate)
    }
    if (item.type === "calendar") {
        return defaultName(item.name, "Calendar", translate)
    }
    if (item.type === "trash") {
        return defaultName(item.name, "Trash", translate)
    }
    if (item.type === "folder") {
        return defaultName(item.name, "Folder", translate)
    }
    if (item.type === "note") {
        return defaultName(item.name, "Note", translate)
    }
    return defaultName(item.name, "Application", translate)
}

function itemTypeTitle(type, translate) {
    if (type === "separator") {
        return translate("Separator")
    }
    if (type === "spacer") {
        return translate("Spacer")
    }
    if (type === "clock") {
        return translate("Clock")
    }
    if (type === "calendar") {
        return translate("Calendar")
    }
    if (type === "trash") {
        return translate("Trash")
    }
    if (type === "folder") {
        return translate("Folder")
    }
    if (type === "note") {
        return translate("Note")
    }
    return translate("Application")
}

function itemSubtitle(item, translate, translatePlural) {
    if (!item) {
        return ""
    }
    if (item.type === "app") {
        return item.description || translate("Application")
    }
    if (item.type === "folder") {
        return translatePlural("%1 application", "%1 applications", item.apps ? item.apps.length : 0)
    }
    if (item.type === "clock") {
        return item.format || "HH:mm"
    }
    if (item.type === "calendar") {
        return item.format || "ddd dd"
    }
    if (item.type === "trash") {
        return translate("System item")
    }
    if (item.type === "note") {
        return translate("Simple note")
    }
    if (item.type === "spacer") {
        return translate("%1 px", item.size || 24)
    }
    return item.type || ""
}

function itemIcon(item) {
    if (!item) {
        return "application-x-executable"
    }
    if (item.type === "folder") {
        return item.icon || "folder"
    }
    if (item.type === "separator") {
        return "draw-line"
    }
    if (item.type === "spacer") {
        return "distribute-horizontal-x"
    }
    if (item.type === "clock") {
        return item.icon || "preferences-system-time"
    }
    if (item.type === "calendar") {
        return item.icon || "x-office-calendar"
    }
    if (item.type === "trash") {
        return item.icon || "user-trash"
    }
    if (item.type === "note") {
        return !item.icon || item.icon === "note" ? "knotes" : item.icon
    }
    return item.icon || "application-x-executable"
}

function categoryIcon(category) {
    var value = String(category || "").trim()
    if (value === "Development") {
        return "applications-development"
    }
    if (value === "Game") {
        return "applications-games"
    }
    if (value === "AudioVideo") {
        return "applications-multimedia"
    }
    if (value === "Network") {
        return "applications-internet"
    }
    if (value === "Office") {
        return "applications-office"
    }
    if (value === "System") {
        return "applications-system"
    }
    if (value === "Utility") {
        return "applications-utilities"
    }
    if (value === "Graphics") {
        return "applications-graphics"
    }
    return "folder"
}

function itemModelRow(item, translate, translatePlural) {
    return {
        "title": itemTitle(item, translate),
        "subtitle": itemSubtitle(item, translate, translatePlural),
        "iconName": itemIcon(item)
    }
}

function actionModelRow(action, fallbackIcon, translate) {
    return {
        "title": defaultName(action ? action.name : "", "New action", translate),
        "subtitle": action && action.command ? action.command : translate("No command"),
        "iconName": action && action.icon ? action.icon : (fallbackIcon || "application-x-executable")
    }
}

function folderAppModelRow(app, fallbackIcon, translate) {
    return {
        "title": defaultName(app ? app.name : "", "Application", translate),
        "subtitle": app && app.description ? app.description : translate("Application"),
        "iconName": app && app.icon ? app.icon : (fallbackIcon || "application-x-executable")
    }
}

function removeKeys(item, keys) {
    for (var index = 0; index < keys.length; index++) {
        delete item[keys[index]]
    }
}

function pruneSeparator(item) {
    removeKeys(item, ["name", "icon", "command", "apps"])
    item.separatorStyle = item.separatorStyle || "line"
    item.separatorThickness = Math.max(1, Math.min(16, Number(item.separatorThickness === undefined ? 2 : item.separatorThickness)))
    item.separatorLengthRatio = Math.max(0.20, Math.min(1.0, Number(item.separatorLengthRatio === undefined ? 0.72 : item.separatorLengthRatio)))
    item.separatorOpacity = Math.max(0.10, Math.min(1.0, Number(item.separatorOpacity === undefined ? 0.34 : item.separatorOpacity)))
    item.separatorGlowEnabled = item.separatorGlowEnabled === true
}

function pruneSpacer(item) {
    removeKeys(item, ["name", "icon", "command", "apps"])
}

function pruneClock(item) {
    removeKeys(item, ["icon", "command", "apps"])
    if (item.mode === "analog") {
        if (!item.analogCustomAppearance) {
            removeKeys(item, ["analogAccentColor", "analogTickColor", "analogBorderColor", "analogFaceColor"])
        }
        return
    }
    removeKeys(item, [
        "showSeconds", "analogCustomAppearance", "analogAccentColor",
        "analogTickColor", "analogBorderColor", "analogFaceColor"
    ])
}

function pruneCalendar(item) {
    removeKeys(item, ["icon", "fontFamily", "mode", "showSeconds", "command", "apps", "width", "height", "backgroundColor", "accentColor", "borderColor", "radius", "textScale"])
    item.timeTextScale = Math.max(0.75, Math.min(2.0, Number(item.timeTextScale === undefined ? 1.0 : item.timeTextScale)))
    item.dateTextScale = Math.max(0.75, Math.min(2.0, Number(item.dateTextScale === undefined ? 1.0 : item.dateTextScale)))
    item.showWeekNumbers = item.showWeekNumbers === undefined ? true : !!item.showWeekNumbers
    item.popupScale = Math.max(0.5, Math.min(3.0,
        Number(item.popupScale === undefined ? 1.0 : item.popupScale)))
}

function pruneTrash(item) {
    removeKeys(item, ["command", "apps"])
}

function pruneNote(item) {
    removeKeys(item, ["command", "apps", "actions", "actionsEnabled"])
    item.name = item.name || "Note"
    item.icon = !item.icon || item.icon === "note" ? "knotes" : item.icon
    item.note = item.note || ""
    item.popupWidth = Math.max(220, item.popupWidth || 360)
    item.popupHeight = Math.max(160, item.popupHeight || 260)
}

function pruneApp(item) {
    removeKeys(item, ["apps"])
    if (!item.storageId || String(item.storageId).trim().length === 0) {
        delete item.storageId
    }
    if (!item.appId || String(item.appId).trim().length === 0) {
        delete item.appId
    } else {
        item.appId = normalizedApplicationId(item.appId)
    }
}

function pruneFolder(item) {
    removeKeys(item, ["command", "actions", "actionsEnabled"])
    removeKeys(item, ["radialBackground", "radialIconSlots", "radialDistance", "fanCenterDistance"])
    item.apps = item.apps instanceof Array ? item.apps : []
    item.layout = item.layout === "list" || item.layout === "detailed" ? item.layout : "grid"
    item.columns = Math.max(0, item.columns || 0)
    item.rows = Math.max(0, item.rows || 0)
    item.innerIconSize = Math.max(16, item.innerIconSize || 48)
    item.showLabels = item.showLabels === undefined ? true : item.showLabels
    item.closeOnLaunch = item.closeOnLaunch === undefined ? true : item.closeOnLaunch
    for (var index = 0; index < item.apps.length; index++) {
        item.apps[index].type = "app"
        item.apps[index].name = item.apps[index].name || "Application"
        item.apps[index].icon = item.apps[index].icon || "application-x-executable"
        item.apps[index].command = item.apps[index].command || ""
        pruneApp(item.apps[index])
    }
}

function newItem(type, defaultTrashEmptySound) {
    if (type === "separator") {
        return { "type": "separator" }
    }
    if (type === "spacer") {
        return { "type": "spacer", "size": 32 }
    }
    if (type === "clock") {
        return {
            "type": "clock",
            "name": "Clock",
            "icon": "preferences-system-time",
            "mode": "digital",
            "format": "HH:mm",
            "fontFamily": "",
            "color": "",
            "width": 0,
            "textScale": 1.15
        }
    }
    if (type === "calendar") {
        return {
            "type": "calendar",
            "name": "Calendar",
            "icon": "x-office-calendar",
            "color": "",
            "textScale": 1.15,
            "popupScale": 1.0,
            "calendarDisplayMode": "tile",
            "textShowWeekday": true,
            "textShowDay": true,
            "textShowMonth": true,
            "showWeekday": true,
            "showWeekNumbers": true
        }
    }
    if (type === "trash") {
        return {
            "type": "trash",
            "name": "Trash",
            "icon": "user-trash",
            "fullIcon": "user-trash-full",
            "emptySound": defaultTrashEmptySound,
            "showState": true,
            "acceptDrops": true
        }
    }
    if (type === "note") {
        return {
            "type": "note",
            "name": "Note",
            "icon": "knotes",
            "note": "",
            "popupWidth": 360,
            "popupHeight": 260
        }
    }
    if (type === "folder") {
        return {
            "type": "folder",
            "name": "Folder",
            "icon": "folder",
            "apps": [],
            "layout": "grid",
            "columns": 3,
            "rows": 0,
            "innerIconSize": 48,
            "showLabels": true,
            "closeOnLaunch": true,
            "sourceType": "manual",
            "sourcePath": "",
            "sourceCategory": "Development"
        }
    }
    return {
        "type": "app",
        "name": "New App",
        "icon": "application-x-executable",
        "command": ""
    }
}

function newAction(item) {
    var nextAction = {
        "name": "New action",
        "icon": item && item.icon ? item.icon : "application-x-executable",
        "command": item && item.command ? item.command : ""
    }
    syncAppIdentity(nextAction, nextAction.command, "", "")
    return nextAction
}

function newContainerApp(item) {
    var nextApp = {
        "type": "app",
        "name": "New App",
        "icon": item && item.icon ? item.icon : "application-x-executable",
        "command": item && item.command ? item.command : ""
    }
    syncAppIdentity(nextApp, nextApp.command, "", "")
    return nextApp
}

function parseJsonArray(text) {
    var parsed = JSON.parse(text)
    if (!(parsed instanceof Array)) {
        return {
            "ok": false,
            "items": [],
            "error": "array"
        }
    }
    return {
        "ok": true,
        "items": parsed,
        "error": ""
    }
}

function setActionsEnabled(items, selectedIndex, enabled) {
    var nextItems = clone(items)
    var item = nextItems[selectedIndex]
    item.type = item.type || "app"
    if (enabled) {
        item.actions = item.actions instanceof Array ? item.actions : []
        delete item.actionsEnabled
    } else {
        item.actionsEnabled = false
    }
    return nextItems
}

function setItemMode(items, selectedIndex, mode) {
    var nextItems = clone(items)
    var item = nextItems[selectedIndex]
    if (mode === "separator") {
        item.type = "separator"
        pruneSeparator(item)
    } else if (mode === "spacer") {
        item.type = "spacer"
        item.size = item.size || 32
        pruneSpacer(item)
    } else if (mode === "container") {
        item.type = "folder"
        item.name = item.name || "Folder"
        item.icon = item.icon || "folder"
        item.apps = item.apps instanceof Array ? item.apps : []
        item.layout = item.layout || "grid"
        item.columns = item.columns === undefined ? 3 : item.columns
        item.rows = item.rows === undefined ? 0 : item.rows
        item.innerIconSize = item.innerIconSize || 48
        item.showLabels = item.showLabels === undefined ? true : item.showLabels
        item.closeOnLaunch = item.closeOnLaunch === undefined ? true : item.closeOnLaunch
        item.sourceType = item.sourceType || "manual"
        item.sourcePath = item.sourcePath || ""
        item.sourceCategory = item.sourceCategory || "Development"
        pruneFolder(item)
    } else if (mode === "note") {
        item.type = "note"
        item.name = item.name || "Note"
        item.icon = !item.icon || item.icon === "note" ? "knotes" : item.icon
        item.note = item.note || ""
        item.popupWidth = item.popupWidth || 360
        item.popupHeight = item.popupHeight || 260
        pruneNote(item)
    } else {
        item.type = "app"
        item.name = item.name || "Application"
        item.icon = item.icon || "application-x-executable"
        item.command = item.command || ""
        pruneApp(item)
    }
    return nextItems
}

function addAction(items, selectedIndex) {
    var nextItems = clone(items)
    nextItems[selectedIndex].actions = nextItems[selectedIndex].actions instanceof Array ? nextItems[selectedIndex].actions : []
    nextItems[selectedIndex].actions.push(newAction(nextItems[selectedIndex]))
    return {
        "items": nextItems,
        "selectedActionIndex": nextItems[selectedIndex].actions.length - 1
    }
}

function removeAction(items, selectedIndex, selectedActionIndex) {
    var nextItems = clone(items)
    nextItems[selectedIndex].actions.splice(selectedActionIndex, 1)
    return {
        "items": nextItems,
        "selectedActionIndex": Math.min(selectedActionIndex, nextItems[selectedIndex].actions.length - 1)
    }
}

function moveAction(items, selectedIndex, selectedActionIndex, target) {
    var nextItems = clone(items)
    var action = nextItems[selectedIndex].actions.splice(selectedActionIndex, 1)[0]
    nextItems[selectedIndex].actions.splice(target, 0, action)
    return {
        "items": nextItems,
        "selectedActionIndex": target
    }
}

function removeItem(items, selectedIndex) {
    var nextItems = clone(items)
    nextItems.splice(selectedIndex, 1)
    return {
        "items": nextItems,
        "selectedIndex": Math.min(selectedIndex, nextItems.length - 1)
    }
}

function moveItem(items, selectedIndex, target) {
    var nextItems = clone(items)
    var item = nextItems.splice(selectedIndex, 1)[0]
    nextItems.splice(target, 0, item)
    return {
        "items": nextItems,
        "selectedIndex": target
    }
}

function applyAction(items, selectedIndex, selectedActionIndex, name, icon, command) {
    var nextItems = clone(items)
    var action = nextItems[selectedIndex].actions[selectedActionIndex]
    action.name = name || "New action"
    action.icon = icon || nextItems[selectedIndex].icon || "application-x-executable"
    action.command = command
    syncAppIdentity(action, action.command, action.storageId, action.appId)
    return nextItems
}

function addContainerApp(items, selectedIndex) {
    var nextItems = clone(items)
    nextItems[selectedIndex].apps = nextItems[selectedIndex].apps instanceof Array ? nextItems[selectedIndex].apps : []
    nextItems[selectedIndex].apps.push(newContainerApp(nextItems[selectedIndex]))
    return {
        "items": nextItems,
        "selectedActionIndex": nextItems[selectedIndex].apps.length - 1
    }
}

function removeContainerApp(items, selectedIndex, selectedActionIndex) {
    var nextItems = clone(items)
    nextItems[selectedIndex].apps.splice(selectedActionIndex, 1)
    return {
        "items": nextItems,
        "selectedActionIndex": Math.min(selectedActionIndex, nextItems[selectedIndex].apps.length - 1)
    }
}

function moveContainerApp(items, selectedIndex, selectedActionIndex, target) {
    var nextItems = clone(items)
    var app = nextItems[selectedIndex].apps.splice(selectedActionIndex, 1)[0]
    nextItems[selectedIndex].apps.splice(target, 0, app)
    return {
        "items": nextItems,
        "selectedActionIndex": target
    }
}

function applyContainerApp(items, selectedIndex, selectedActionIndex, name, icon, command) {
    var nextItems = clone(items)
    var app = nextItems[selectedIndex].apps[selectedActionIndex]
    app.type = "app"
    app.name = name || "Application"
    app.icon = icon || nextItems[selectedIndex].icon || "application-x-executable"
    app.command = command || ""
    syncAppIdentity(app, app.command, app.storageId, app.appId)
    pruneApp(app)
    return nextItems
}
