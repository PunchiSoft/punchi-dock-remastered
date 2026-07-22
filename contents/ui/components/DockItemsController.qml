import QtQuick
import org.kde.plasma.plasmoid
import "../../code/logic.js" as Logic

Item {
    id: root

    width: 0
    height: 0
    visible: false

    property var runtimeService: null
    property var systemDiscovery: null
    property var taskController: null
    property var trashIntegration: null
    property string minimizeEffect: "none"

    property var dockItems: []
    property string recentlyTransitionedAppId: ""
    property string recentlyTransitionedLauncherUrl: ""
    property int minimizeReactionRevision: 0
    property int minimizeReactionTargetIndex: -1
    property bool trashHasItems: false
    readonly property bool itemTransitionActive: itemTransitionTimer.running

    Timer {
        id: itemTransitionTimer
        interval: 500
        repeat: false
        onTriggered: {
            root.recentlyTransitionedAppId = ""
            root.recentlyTransitionedLauncherUrl = ""
        }
    }

    Connections {
        target: Plasmoid.configuration

        function onDockItemsJsonChanged() {
            const raw = Plasmoid.configuration.dockItemsJson || ""
            root.dockItems = raw.trim().length > 0 ? Logic.loadItems(raw) : []
            if (root.runtimeService) {
                root.runtimeService.persistDockItemsJson(raw, root.configInstanceId())
            }
            if (root.trashIntegration) {
                root.trashIntegration.refresh()
            }
        }
    }

    Connections {
        target: root.trashIntegration

        function onStateChanged(hasItems) {
            root.trashHasItems = hasItems
        }
    }

    Component.onCompleted: {
        const raw = Plasmoid.configuration.dockItemsJson || ""
        root.dockItems = Logic.loadItems(raw)
        if (root.trashIntegration) {
            root.trashIntegration.refresh()
        }
    }

    function configInstanceId() {
        let value = ""
        try {
            if (Plasmoid && Plasmoid.id !== undefined && Plasmoid.id !== null) {
                value = String(Plasmoid.id)
            }
        } catch (error) {
            value = ""
        }
        if (value.length === 0 || value === "undefined" || value === "null") {
            return "default"
        }
        return value.replace(/[^A-Za-z0-9_.-]/g, "_")
    }

    function runCommand(command) {
        if (root.runtimeService) {
            root.runtimeService.launchCommand(command)
        }
    }

    function launchDockItem(item) {
        if (item && item.storageId && root.systemDiscovery) {
            root.systemDiscovery.launchApplication(item.storageId)
        } else if (item && item.type === "app" && item.command
                && root.systemDiscovery
                && root.systemDiscovery.launchApplicationByCommand(item.command)) {
            return
        } else if (item && item.url && root.systemDiscovery) {
            root.systemDiscovery.openUrl(item.url)
        } else {
            Logic.launchItem(item, root.runCommand)
        }
    }

    function handleDockItemActivation(item) {
        if (!item || item.type !== "app" || !root.taskController) {
            root.launchDockItem(item)
            return
        }

        const taskState = root.taskController.taskStateForDockItem(item)
        if (taskState.count > 1) {
            root.taskController.activatePreferredTaskRow(taskState.rows)
            return
        }
        if (taskState.firstRow >= 0) {
            root.taskController.activateTaskRow(taskState.firstRow)
            return
        }

        root.launchDockItem(item)
    }

    function syncDockItemsConfiguration() {
        const raw = JSON.stringify(root.dockItems)
        Plasmoid.configuration.dockItemsJson = raw
        if (root.runtimeService) {
            root.runtimeService.persistDockItemsJson(raw, root.configInstanceId())
        }
    }

    function pinTaskToDock(descriptor) {
        if (!root.taskController || !descriptor
                || String(descriptor.storageId || "").trim().length === 0
                || root.taskController.dockContainsPinDescriptor(descriptor)) {
            return false
        }

        const pinnedItem = {
            "type": "app",
            // qmllint disable unqualified
            "name": String(descriptor.name || i18n("Application")),
            // qmllint enable unqualified
            "icon": String(descriptor.icon || "application-x-executable"),
            "storageId": String(descriptor.storageId),
            "appId": String(descriptor.appId || "")
        }
        const command = String(descriptor.command || "").trim()
        if (command.length > 0) {
            pinnedItem.command = command
        }
        root.recentlyTransitionedAppId = root.taskController.normalizeApplicationId(
            descriptor.appId || descriptor.storageId || "")
        root.recentlyTransitionedLauncherUrl = root.taskController.normalizeLauncherUrl(
            "applications:" + descriptor.storageId)
        itemTransitionTimer.restart()
        root.dockItems = root.dockItems.concat([pinnedItem])
        root.syncDockItemsConfiguration()
        return true
    }

    function unpinItemFromDock(targetIndex, expectedApplicationId, expectedLauncherUrl) {
        if (!root.taskController) {
            return false
        }
        const index = Number(targetIndex)
        if (!Number.isInteger(index) || index < 0 || index >= root.dockItems.length) {
            return false
        }

        const dockItem = root.dockItems[index]
        const actualApplicationId = root.taskController.dockItemApplicationId(dockItem)
        const actualLauncherUrl = root.taskController.dockItemLauncherUrl(dockItem)
        const normalizedExpectedApplicationId = root.taskController.normalizeApplicationId(
            expectedApplicationId || "")
        const normalizedExpectedLauncherUrl = root.taskController.normalizeLauncherUrl(
            expectedLauncherUrl || "")
        if (normalizedExpectedApplicationId.length > 0
                && actualApplicationId !== normalizedExpectedApplicationId) {
            return false
        }
        if (normalizedExpectedLauncherUrl.length > 0
                && actualLauncherUrl !== normalizedExpectedLauncherUrl) {
            return false
        }

        root.recentlyTransitionedAppId = actualApplicationId
        root.recentlyTransitionedLauncherUrl = actualLauncherUrl
        itemTransitionTimer.restart()
        root.dockItems = root.dockItems.slice(0, index)
            .concat(root.dockItems.slice(index + 1))
        root.syncDockItemsConfiguration()
        return true
    }

    function addQuickNote() {
        const noteItem = {
            "type": "note",
            // qmllint disable unqualified
            "name": i18nc("@title", "Quick Note"),
            // qmllint enable unqualified
            "icon": "knotes",
            "note": "",
            "popupWidth": 380,
            "popupHeight": 260
        }
        root.dockItems = root.dockItems.concat([noteItem])
        root.syncDockItemsConfiguration()
        return noteItem
    }

    function addQuickSeparator() {
        const separatorItem = {
            "type": "separator"
        }
        root.dockItems = root.dockItems.concat([separatorItem])
        root.syncDockItemsConfiguration()
        return separatorItem
    }

    function triggerMinimizeReaction(itemIndex) {
        if (root.minimizeEffect === "none" || itemIndex < 0) {
            return
        }

        root.minimizeReactionTargetIndex = itemIndex
        root.minimizeReactionRevision += 1
    }

    function updateNoteItem(noteItem, noteText, popupWidth, popupHeight, targetIndex) {
        if (!noteItem) {
            return null
        }

        const requestedIndex = Number(targetIndex)
        const hasValidIndex = Number.isInteger(requestedIndex)
            && requestedIndex >= 0
            && requestedIndex < root.dockItems.length
            && root.dockItems[requestedIndex]
            && root.dockItems[requestedIndex].type === "note"
        const updatedItems = []
        let updatedNoteItem = null
        let changed = false
        for (let index = 0; index < root.dockItems.length; index++) {
            let item = root.dockItems[index]
            if ((!changed && hasValidIndex && index === requestedIndex)
                    || (!changed && !hasValidIndex && item === noteItem)) {
                item = Object.assign({}, item, {
                    "note": noteText,
                    "popupWidth": popupWidth,
                    "popupHeight": popupHeight
                })
                updatedNoteItem = item
                changed = true
            }
            updatedItems.push(item)
        }

        if (changed) {
            root.dockItems = updatedItems
            root.syncDockItemsConfiguration()
        }
        return updatedNoteItem
    }

    function removeNoteItemAtIndex(targetIndex) {
        const index = Number(targetIndex)
        if (!Number.isInteger(index) || index < 0 || index >= root.dockItems.length
                || !root.dockItems[index] || root.dockItems[index].type !== "note") {
            return false
        }

        root.dockItems = root.dockItems.slice(0, index)
            .concat(root.dockItems.slice(index + 1))
        root.syncDockItemsConfiguration()
        return true
    }
}
