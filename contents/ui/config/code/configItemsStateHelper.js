function selectedItem() {
    if (selectedIndex < 0 || selectedIndex >= items.length) {
        return null
    }
    return items[selectedIndex]
}

function selectedAction() {
    return ConfigItemsControllerJS.selectedAction(selectedItem(), selectedActionIndex)
}

function itemIconText() {
    if (selectedItemType === "app" || selectedItemType === "folder") {
        return actionDialog.appIconText
    }
    if (selectedItemType === "trash") {
        return trashDialog.emptyIconText
    }
    return ""
}

function showSelectedItem() {
    if (selectedIndex >= 0) {
        mainView.positionAtIndex(selectedIndex)
    }
}

function showSelectedAction() {
    if (selectedActionIndex >= 0 && actionDialog.actionCount > 0) {
        actionDialog.positionActionAtIndex(selectedActionIndex)
    }
}

function selectItem(index) {
    selectedIndex = index
    selectedActionIndex = -1
    FormHelper.refreshItemForm()
    FormHelper.refreshActions()
    showSelectedItem()
}

function compactListHeight(count, minRows, maxRows) {
    return ConfigItemsControllerJS.compactListHeight(count, minRows, maxRows, listRowHeight, listFooterHeight, listFramePadding)
}
