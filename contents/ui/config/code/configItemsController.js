.pragma library

function fileName(path) {
    var text = String(path || "")
    var slash = text.lastIndexOf("/")
    return slash >= 0 ? text.substring(slash + 1) : text
}

function selectedComboFont(editText, currentText, automaticText) {
    var text = String(editText || "")
    if (text.length > 0 && text !== automaticText) {
        return text
    }
    var current = String(currentText || "")
    return current === automaticText ? "" : current
}

function displayFontName(value, automaticText) {
    return value && String(value).length > 0 ? String(value) : automaticText
}

function compactListHeight(count, minRows, maxRows, rowHeight, footerHeight, framePadding) {
    var rows = Math.max(minRows, Math.min(maxRows, Math.max(1, count)))
    return rows * rowHeight + footerHeight + framePadding
}

function selectedAction(item, selectedActionIndex) {
    if (!item || selectedActionIndex < 0) {
        return null
    }
    if (item.type === "folder") {
        return item.apps && selectedActionIndex < item.apps.length ? item.apps[selectedActionIndex] : null
    }
    if ((item.type || "app") !== "app" || !item.actions || selectedActionIndex >= item.actions.length) {
        return null
    }
    return item.actions[selectedActionIndex]
}

function itemAcceptsActions(item) {
    return !!item && (item.type === "folder" || (item.type || "app") === "app")
}

function itemHasMutableActions(item) {
    if (!itemAcceptsActions(item)) {
        return false
    }
    return item.type === "folder" ? item.apps instanceof Array : item.actions instanceof Array
}

function actionRows(item) {
    if (!item) {
        return []
    }
    return item.type === "folder" ? item.apps : item.actions
}

function canMoveAction(item, selectedActionIndex, targetIndex) {
    var rows = actionRows(item)
    return rows instanceof Array && selectedActionIndex >= 0 && targetIndex >= 0 && targetIndex < rows.length
}
