.pragma library
.import "../../../code/defaultItems.js" as DockDefaults

// #######################
// Default dock layout.
// #######################
var configureDockItem = {
    "_comment": "Internal shortcut. Opens Punchi Dock configuration without using external commands.",
    "type": "app",
    "name": "Configure Dock",
    "icon": "systemsettings",
    "command": "punchi-dock://configure"
}

var defaultItems = DockDefaults.cloneItems()

function cloneJson(value) {
    return JSON.parse(JSON.stringify(value))
}

function isConfigureDockItem(item) {
    return item && item.command === "punchi-dock://configure"
}

function isGithubShortcut(item) {
    var command = String(item && item.command ? item.command : "").toLowerCase()
    return command.indexOf("github.com/punchisoft/punchi-dock-plasmoid") >= 0
}

function shouldUseWebLinkIcon(iconName) {
    var icon = String(iconName || "").trim()
    return icon.length === 0
        || icon === "github"
        || icon === "internet-web-browser"
        || icon === "applications-internet"
        || icon === "web-browser"
        || icon === "browser"
}

function dockIconName(iconName) {
    var icon = String(iconName || "").trim()
    if (icon === "preferences-system") {
        return "systemsettings"
    }
    if (icon === "libreoffice-main") {
        return "libreoffice-startcenter"
    }
    if (icon === "applications-graphics") {
        return "folder-pictures"
    }
    if (icon === "clock-symbolic") {
        return "preferences-system-time"
    }
    if (icon === "clock") {
        return "preferences-system-time"
    }
    if (icon === "view-calendar") {
        return "x-office-calendar"
    }
    if (icon === "view-more-symbolic") {
        return "view-grid"
    }
    if (icon === "user-trash-symbolic") {
        return "user-trash"
    }
    if (icon === "user-trash-full-symbolic") {
        return "user-trash-full"
    }
    return iconName
}

function desktopIdFromLauncherCommand(command) {
    var text = String(command || "")
    if (text.indexOf("sh -c ") !== 0 || text.indexOf("kioclient") < 0 || text.indexOf("gtk-launch") < 0) {
        return ""
    }

    var match = text.match(/applications:([^'"\\\s;]+\.desktop)/)
    if (!match) {
        return ""
    }
    var desktopId = match[1]
    var slashIndex = desktopId.lastIndexOf("/")
    if (slashIndex >= 0) {
        desktopId = desktopId.substring(slashIndex + 1)
    }
    return desktopId
}

function normalizeLaunchCommand(command) {
    var desktopId = desktopIdFromLauncherCommand(command)
    if (desktopId.length > 0) {
        return "gtk-launch " + desktopId
    }
    return command
}

function normalizeDefaultItems(items) {
    var nextItems = cloneJson(items || [])
    for (var index = 0; index < nextItems.length; index++) {
        var item = nextItems[index]
        item.icon = dockIconName(item.icon)
        item.fullIcon = dockIconName(item.fullIcon)
        item.command = normalizeLaunchCommand(item.command)
        if (isConfigureDockItem(item)) {
            item.icon = configureDockItem.icon
        }
        if (isGithubShortcut(item)) {
            if (shouldUseWebLinkIcon(item.icon)) {
                item.icon = "internet-web-browser"
            }
            if (!item.confirmationMessage) {
                item.confirmationMessage = "You will be directed to the official repository page. Check your default web browser. Thank you for using Punchi Dock. Linux for everyone."
            }
        }
        if (item.apps instanceof Array) {
            item.apps = normalizeDefaultItems(item.apps)
        }
    }
    return nextItems
}

function withConfigureDockItem(items) {
    return normalizeDefaultItems(items || [])
}

function defaultJson() {
    return JSON.stringify(normalizeDefaultItems(defaultItems), null, 4)
}

function parseItems(text) {
    try {
        var parsed = JSON.parse(text)
        if (parsed instanceof Array) {
            return normalizeDefaultItems(parsed)
        }
    } catch (error) {
        console.warn("Punchi Dock: invalid dock_items.json:", error)
    }
    return normalizeDefaultItems(defaultItems)
}
