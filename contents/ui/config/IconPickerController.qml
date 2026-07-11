import QtQuick

import "code/iconPickerController.js" as IconPickerJS
import "code/configItems.js" as ConfigItemsJS
import "code/configScripts.js" as ConfigScriptsJS

Item {
    id: control

    required property var page

    readonly property var iconDialog: page.iconDialogLoader.item

    property string target: ""
    property bool systemIconsRequested: false
    property var systemIconNames: []
    property var systemIconPaths: ({})
    property int filteredIconTotal: 0

    property var filteredIconModel: ListModel {}

    property var iconCategories: [
        { "text": i18n("All icons"), "value": "all" },
        { "text": i18n("Applications"), "value": "applications" },
        { "text": i18n("Places"), "value": "places" },
        { "text": i18n("Actions"), "value": "actions" },
        { "text": i18n("Devices"), "value": "devices" },
        { "text": i18n("Status"), "value": "status" },
        { "text": i18n("Mimetypes"), "value": "mimetypes" },
        { "text": i18n("Other"), "value": "other" }
    ]

    function iconPreviewSource(name) {
        return ConfigItemsJS.iconPreviewSource(name)
    }

    function open(pickerTarget) {
        target = pickerTarget
        page.iconDialogLoader.active = true
        var dialog = iconDialog

        var iconName = ""
        if (target === "action") {
            iconName = page.actionDialog.actionIconText
        } else if (target === "trashFull") {
            iconName = page.trashDialog.fullIconText
        } else if (target === "trash") {
            iconName = page.trashDialog.emptyIconText
        } else {
            iconName = page.itemIconName.text
        }

        dialog.categoryIndex = 0
        dialog.iconName = IconPickerJS.initialName(target, page.actionDialog.actionIconText, page.trashDialog.fullIconText, page.itemIconText())
        dialog.searchText = IconPickerJS.searchText(dialog.iconName)

        if (!systemIconsRequested) {
            loadSystemIcons()
        }
        updateIconFilter()
        dialog.open()
    }

    function choose(name) {
        var selectedIcon = page.iconValueForName(name)
        if (target === "action") {
            page.actionDialog.actionIconText = selectedIcon
            page.applyActionForm()
        } else {
            if (page.selectedItemType === "app" || page.selectedItemType === "folder") {
                page.actionDialog.appIconText = selectedIcon
            } else if (target === "trashFull") {
                page.trashDialog.fullIconText = selectedIcon
            } else if (page.selectedItemType === "trash") {
                page.trashDialog.emptyIconText = selectedIcon
            } else {
                page.itemIconName.text = selectedIcon
            }
            page.applyItemForm()
        }
        if (iconDialog) {
            iconDialog.close()
        }
    }

    function setSystemIcons(text) {
        var parsed = ConfigItemsJS.parseSystemIcons(text, page.commonIconNames)
        systemIconPaths = parsed.paths
        systemIconNames = parsed.icons
        updateIconFilter()
    }

    function loadSystemIcons() {
        systemIconsRequested = true
        iconSource.connectSource("sh -c " + page.shellQuote(ConfigScriptsJS.iconIndexScript()))
    }

    function openIconFileDialog() {
        page.iconFileDialog.open()
    }

    function chooseIconFile(fileUrl) {
        if (iconDialog) {
            iconDialog.iconName = IconPickerJS.decodedFileUrl(fileUrl)
        }
    }

    function updateIconFilter() {
        if (!iconDialog) {
            return
        }
        var query = iconDialog.searchText.toLowerCase()
        var category = iconDialog.categoryValue || "all"
        var limit = IconPickerJS.filterLimit(query)
        var filtered = ConfigItemsJS.filteredIcons(systemIconNames, page.commonIconNames, query, category, limit)
        filteredIconModel.clear()
        filteredIconTotal = filtered.total

        for (var index = 0; index < filtered.rows.length; index++) {
            filteredIconModel.append(filtered.rows[index])
        }
    }

}
