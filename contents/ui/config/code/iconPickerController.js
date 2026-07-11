.pragma library

function searchText(iconName) {
    var text = String(iconName || "")
    if (text.indexOf("/") >= 0) {
        return ""
    }
    return text
}

function initialName(target, actionIcon, trashFullIcon, fallbackIcon) {
    if (target === "action") {
        return actionIcon || ""
    }
    if (target === "trashFull") {
        return trashFullIcon || ""
    }
    return fallbackIcon || ""
}

function decodedFileUrl(fileUrl) {
    var path = String(fileUrl || "")
    if (path.indexOf("file://") === 0) {
        path = path.substring(7)
    }
    return decodeURIComponent(path)
}

function filterLimit(query) {
    return String(query || "").length > 0 ? 4000 : 1600
}

function shouldAcceptResolvedFlatpakIcon(stdout, selectedItemType, currentIcon, pendingAppId) {
    var icon = String(stdout || "").trim().split("\n")[0]
    if (icon.length === 0 || selectedItemType !== "app") {
        return false
    }
    return currentIcon === pendingAppId || currentIcon === "application-x-executable" || currentIcon.length === 0
}

function resolvedFlatpakIcon(stdout) {
    return String(stdout || "").trim().split("\n")[0]
}
