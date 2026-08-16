import QtQuick
import org.kde.plasma.plasmoid
import "../../code/logic.js" as Logic
import "../config/code/configItems.js" as ConfigItemsJS

Item {
    id: root

    width: 0
    height: 0
    visible: false

    property var runtimeService: null
    property var persistenceAdapter: null
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

    signal configurationChanged()

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
            root.configurationChanged()
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
        if (item && item.type === "trash") {
            if (root.trashIntegration) {
                root.trashIntegration.openTrash()
            } else {
                console.warn("Punchi Dock: Trash integration is unavailable.")
            }
            return
        }

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

    function validateDroppedUrls(urls) {
        if (!root.systemDiscovery) {
            return {
                "accepted": false,
                "errorCode": "applicationUnavailable",
                "urls": []
            }
        }
        return root.systemDiscovery.validateDroppedUrls(urls || [])
    }

    function validateApplicationLauncherDrop(urls) {
        if (!root.systemDiscovery
                || typeof root.systemDiscovery.validateApplicationLauncherDrop
                    !== "function") {
            return {
                "accepted": false,
                "errorCode": "applicationUnavailable"
            }
        }
        return root.systemDiscovery.validateApplicationLauncherDrop(urls || [])
    }

    function handleApplicationUrlsDrop(item, taskRows, urls) {
        const validation = root.validateDroppedUrls(urls)
        if (!validation.accepted) {
            return validation
        }

        const rows = taskRows || []
        if (rows.length > 0) {
            if (root.taskController
                    && root.taskController.openUrlsWithTaskRows(rows, validation.urls)) {
                return {
                    "accepted": true,
                    "errorCode": "",
                    "urls": validation.urls
                }
            }
            return {
                "accepted": false,
                "errorCode": "applicationUnavailable",
                "urls": []
            }
        }

        if (!item || !root.systemDiscovery) {
            return {
                "accepted": false,
                "errorCode": "applicationUnavailable",
                "urls": []
            }
        }

        const applicationId = String(item.storageId || item.appId || "")
        const command = String(item.command || "")
        const launcherUrl = String(item.url || "")
        if (!root.systemDiscovery.launchApplicationWithUrls(
                applicationId, command, launcherUrl, validation.urls)) {
            return {
                "accepted": false,
                "errorCode": "applicationUnavailable",
                "urls": []
            }
        }
        return {
            "accepted": true,
            "errorCode": "",
            "urls": validation.urls
        }
    }

    function syncDockItemsConfiguration() {
        const raw = JSON.stringify(root.dockItems)
        if (raw.length > Logic.maximumDockItemsJsonLength) {
            console.warn("Punchi Dock: Refused to persist an oversized dock configuration.")
            return false
        }
        Plasmoid.configuration.dockItemsJson = raw
        if (root.runtimeService) {
            return root.runtimeService.persistDockItemsJson(raw, root.configInstanceId())
        }
        return true
    }

    function punchiMenuLayoutPersistenceResult(success, errorCode, currentJson) {
        return {
            "success": success,
            "errorCode": String(errorCode || ""),
            "currentJson": String(currentJson || ""),
            "changed": false,
            "rolledBack": false
        }
    }

    function emptyPunchiMenuApplicationLayout() {
        return {
            "version": 1,
            "nodes": []
        }
    }

    function clonedJsonObject(value) {
        if (!value || typeof value !== "object" || Array.isArray(value)) {
            return null
        }
        try {
            return JSON.parse(JSON.stringify(value))
        } catch (error) {
            return null
        }
    }

    function sortedJsonValue(value, depth) {
        if (depth > 8) {
            throw new Error("nested-json-limit")
        }
        if (value instanceof Array) {
            const result = []
            for (let index = 0; index < value.length; index++) {
                result.push(root.sortedJsonValue(value[index], depth + 1))
            }
            return result
        }
        if (value && typeof value === "object") {
            const keys = Object.keys(value).sort()
            if (keys.length > 2048) {
                throw new Error("object-key-limit")
            }
            const result = {}
            for (let index = 0; index < keys.length; index++) {
                const key = keys[index]
                result[key] = root.sortedJsonValue(value[key], depth + 1)
            }
            return result
        }
        return value
    }

    function canonicalJsonText(value) {
        try {
            return JSON.stringify(root.sortedJsonValue(value, 0))
        } catch (error) {
            return ""
        }
    }

    function punchiMenuItemIndex(items) {
        const source = items instanceof Array ? items : []
        for (let index = 0; index < source.length; index++) {
            if (source[index] && source[index].type === "punchimenu") {
                return index
            }
        }
        return -1
    }

    function setPunchiMenuValue(fieldName, value) {
        const allowedFields = {
            "menuMode": true,
            "normalBlurEnabled": true,
            "normalBackgroundOpacityPercent": true,
            "fullScreenBlurEnabled": true,
            "fullScreenBackgroundOpacityPercent": true,
            "showDistributionName": true,
            "showPageNavigationArrows": true,
            "showApplicationLabels": true,
            "hoverAnimation": true,
            "sortApplicationsAlphabetically": true,
            "fullScreenApplicationOrder": true,
            "fullScreenCloseButtonPosition": true,
            "gridIconScalePercent": true,
            "favoriteIconScalePercent": true,
            "normalFolderMaximumColumns": true,
            "normalFolderMaximumRows": true,
            "normalPlacementMode": true,
            "normalPanelGap": true,
            "normalWidthPercent": true,
            "normalHeightPercent": true,
            "normalShowCategories": true,
            "fullScreenFolderMaximumColumns": true,
            "fullScreenFolderMaximumRows": true
        }
        const normalizedFieldName = String(fieldName || "")
        if (allowedFields[normalizedFieldName] !== true) {
            return false
        }

        const itemIndex = root.punchiMenuItemIndex(root.dockItems)
        if (itemIndex < 0) {
            return false
        }
        const nextItem = root.clonedJsonObject(root.dockItems[itemIndex])
        if (nextItem === null) {
            return false
        }
        nextItem[normalizedFieldName] = value
        ConfigItemsJS.prunePunchiMenu(nextItem)

        const currentText = root.canonicalJsonText(root.dockItems[itemIndex])
        const nextText = root.canonicalJsonText(nextItem)
        if (nextText.length === 0) {
            return false
        }
        if (currentText === nextText) {
            return true
        }

        const previousItems = root.dockItems
        const nextItems = root.dockItems.slice()
        nextItems[itemIndex] = nextItem
        root.dockItems = nextItems
        if (!root.syncDockItemsConfiguration()) {
            root.dockItems = previousItems
            return false
        }
        return true
    }

    function punchiMenuApplicationLayout() {
        const itemIndex = root.punchiMenuItemIndex(root.dockItems)
        if (itemIndex < 0) {
            return root.emptyPunchiMenuApplicationLayout()
        }
        const item = root.dockItems[itemIndex]
        if (item.applicationLayout === undefined) {
            return root.emptyPunchiMenuApplicationLayout()
        }
        const layout = root.clonedJsonObject(item.applicationLayout)
        return layout === null
            ? { "version": -1, "nodes": [] }
            : layout
    }

    function commitPunchiMenuApplicationLayout(expectedDocument, nextDocument) {
        if (!root.persistenceAdapter) {
            return root.punchiMenuLayoutPersistenceResult(
                false, "persistence-adapter-unavailable", "")
        }

        const expectedLayout = root.clonedJsonObject(expectedDocument)
        const candidateLayout = root.clonedJsonObject(nextDocument)
        if (expectedLayout === null || candidateLayout === null) {
            return root.punchiMenuLayoutPersistenceResult(
                false, "invalid-application-layout", "")
        }

        const expectedRaw = String(Plasmoid.configuration.dockItemsJson || "")
        let sourceItems = null
        if (expectedRaw.trim().length === 0) {
            try {
                sourceItems = JSON.parse(JSON.stringify(root.dockItems))
            } catch (error) {
                sourceItems = null
            }
        } else {
            try {
                sourceItems = JSON.parse(expectedRaw)
            } catch (error) {
                sourceItems = null
            }
        }
        if (!(sourceItems instanceof Array) || sourceItems.length > 512) {
            return root.punchiMenuLayoutPersistenceResult(
                false, "invalid-dock-configuration", expectedRaw)
        }

        const itemIndex = root.punchiMenuItemIndex(sourceItems)
        if (itemIndex < 0) {
            return root.punchiMenuLayoutPersistenceResult(
                false, "punchimenu-item-unavailable", expectedRaw)
        }

        const currentItem = sourceItems[itemIndex]
        let currentLayout = root.emptyPunchiMenuApplicationLayout()
        if (currentItem.applicationLayout !== undefined) {
            currentLayout = root.clonedJsonObject(currentItem.applicationLayout)
            if (currentLayout === null) {
                return root.punchiMenuLayoutPersistenceResult(
                    false, "invalid-application-layout", expectedRaw)
            }
        }
        const currentLayoutText = root.canonicalJsonText(currentLayout)
        const expectedLayoutText = root.canonicalJsonText(expectedLayout)
        if (currentLayoutText.length === 0
                || currentLayoutText !== expectedLayoutText) {
            return root.punchiMenuLayoutPersistenceResult(
                false, "layout-conflict", expectedRaw)
        }

        const nextItem = root.clonedJsonObject(currentItem)
        if (nextItem === null) {
            return root.punchiMenuLayoutPersistenceResult(
                false, "invalid-punchimenu-item", expectedRaw)
        }
        nextItem.applicationLayout = candidateLayout
        sourceItems[itemIndex] = nextItem

        let candidateRaw = ""
        try {
            candidateRaw = JSON.stringify(sourceItems)
        } catch (error) {
            return root.punchiMenuLayoutPersistenceResult(
                false, "invalid-dock-configuration", expectedRaw)
        }
        if (candidateRaw.length > Logic.maximumDockItemsJsonLength) {
            return root.punchiMenuLayoutPersistenceResult(
                false, "dock-configuration-too-large", expectedRaw)
        }

        return root.persistenceAdapter.commitDockItemsJson(
            expectedRaw, candidateRaw)
    }

    function normalizedPunchiMenuHiddenApplicationId(value) {
        const storageId = String(value || "").trim()
        if (storageId.length === 0 || storageId.length > 512
                || /[\u0000-\u001f\u007f]/.test(storageId)) {
            return ""
        }
        return storageId
    }

    function punchiMenuHiddenApplicationIds(item) {
        const source = item && item.hiddenApplicationIds instanceof Array
            ? item.hiddenApplicationIds
            : []
        const result = []
        const seen = {}
        for (let index = 0; index < source.length && result.length < 512; index++) {
            const storageId = root.normalizedPunchiMenuHiddenApplicationId(source[index])
            const comparisonKey = "#" + storageId
            if (storageId.length === 0 || seen[comparisonKey] === true) {
                continue
            }
            seen[comparisonKey] = true
            result.push(storageId)
        }
        return result
    }

    function setPunchiMenuApplicationHidden(storageId, hidden) {
        const normalizedId = root.normalizedPunchiMenuHiddenApplicationId(storageId)
        if (normalizedId.length === 0) {
            return false
        }

        let punchiMenuIndex = -1
        for (let index = 0; index < root.dockItems.length; index++) {
            if (root.dockItems[index] && root.dockItems[index].type === "punchimenu") {
                punchiMenuIndex = index
                break
            }
        }
        if (punchiMenuIndex < 0) {
            return false
        }

        const currentItem = root.dockItems[punchiMenuIndex]
        const currentIds = root.punchiMenuHiddenApplicationIds(currentItem)
        const comparisonKey = normalizedId
        const nextIds = []
        let alreadyHidden = false
        for (let index = 0; index < currentIds.length; index++) {
            const currentId = currentIds[index]
            if (currentId === comparisonKey) {
                alreadyHidden = true
                if (!hidden) {
                    continue
                }
            }
            nextIds.push(currentId)
        }
        if (hidden && !alreadyHidden) {
            if (nextIds.length >= 512) {
                return false
            }
            nextIds.push(normalizedId)
        }
        if ((hidden && alreadyHidden) || (!hidden && !alreadyHidden)) {
            return true
        }

        const nextItem = JSON.parse(JSON.stringify(currentItem))
        if (nextIds.length > 0) {
            nextItem.hiddenApplicationIds = nextIds
        } else {
            delete nextItem.hiddenApplicationIds
        }
        const previousItems = root.dockItems
        const nextItems = root.dockItems.slice()
        nextItems[punchiMenuIndex] = nextItem
        root.dockItems = nextItems
        if (!root.syncDockItemsConfiguration()) {
            root.dockItems = previousItems
            return false
        }
        return true
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

    // Translation functions are provided by the plasmoid context.
    // qmllint disable unqualified
    function operationResult(success, status, applicationName) {
        const name = String(applicationName || "").trim()
        let message = ""
        switch (status) {
        case "pinned":
            message = i18nc("@info:status", "%1 was pinned to the Dock.", name)
            break
        case "moved":
            message = i18nc("@info:status", "%1 was moved on the Dock.", name)
            break
        case "unpinned":
            message = i18nc("@info:status", "%1 was removed from the Dock.", name)
            break
        case "created":
            message = i18nc("@info:status", "A desktop shortcut for %1 was created.", name)
            break
        case "already-exists":
            message = i18nc("@info:status", "A desktop shortcut for %1 already exists.", name)
            break
        case "ambiguous":
            message = i18nc("@info:status", "The application identity is ambiguous.")
            break
        case "not-found":
            message = i18nc("@info:status", "The application could not be resolved.")
            break
        case "persist-failed":
            message = i18nc("@info:status", "The Dock configuration could not be saved.")
            break
        case "invalid-source":
        case "invalid-target":
            message = i18nc("@info:status", "The desktop shortcut source is not safe.")
            break
        case "desktop-unavailable":
            message = i18nc("@info:status", "The desktop folder is not available.")
            break
        case "permissions-failed":
            message = i18nc("@info:status", "The desktop shortcut permissions could not be set.")
            break
        case "read-failed":
        case "write-failed":
            message = i18nc("@info:status", "The desktop shortcut could not be written.")
            break
        default:
            message = i18nc("@info:status", "The requested application action could not be completed.")
            break
        }
        return { "success": !!success, "status": String(status || "failed"), "message": message }
    }
    // qmllint enable unqualified

    function resolveApplication(storageId, command) {
        if (!root.systemDiscovery || typeof root.systemDiscovery.resolveApplication !== "function") {
            return { "resolved": false, "status": "unavailable" }
        }
        return root.systemDiscovery.resolveApplication(
            String(storageId || ""), String(command || ""), "")
    }

    function findDockItemIndexForResolvedApplication(resolved) {
        if (!resolved || !resolved.resolved) {
            return -1
        }
        const targetStorageId = String(resolved.storageId || "").toLowerCase()
        const targetAppId = String(resolved.appId || "").toLowerCase()
        for (let i = 0; i < root.dockItems.length; i++) {
            const item = root.dockItems[i]
            if (!item || (item.type && item.type !== "app")) {
                continue
            }
            const itemResolution = root.resolveApplication(
                item.storageId || item.appId || "", item.command || "")
            if (!itemResolution || !itemResolution.resolved) {
                continue
            }
            const itemStorageId = String(itemResolution.storageId || "").toLowerCase()
            const itemAppId = String(itemResolution.appId || "").toLowerCase()
            if ((targetStorageId.length > 0 && itemStorageId === targetStorageId)
                    || (targetAppId.length > 0 && itemAppId === targetAppId)) {
                return i
            }
        }
        return -1
    }

    function isAppPinnedToDock(storageId, command) {
        return root.findDockItemIndexForResolvedApplication(
            root.resolveApplication(storageId, command)) >= 0
    }

    function togglePinAppToDock(storageId, name, icon, command) {
        const resolved = root.resolveApplication(storageId, command)
        if (!resolved || !resolved.resolved) {
            return root.operationResult(false, resolved ? resolved.status : "unavailable", name)
        }

        const appName = String(resolved.name || name || resolved.storageId || "")
        const existingIndex = root.findDockItemIndexForResolvedApplication(resolved)
        const previousItems = root.dockItems
        if (existingIndex >= 0) {
            root.dockItems = root.dockItems.slice(0, existingIndex)
                .concat(root.dockItems.slice(existingIndex + 1))
            if (!root.syncDockItemsConfiguration()) {
                root.dockItems = previousItems
                return root.operationResult(false, "persist-failed", appName)
            }
            return root.operationResult(true, "unpinned", appName)
        }

        const pinDescriptor = {
            "type": "app",
            "name": appName,
            "icon": String(resolved.icon || icon || "application-x-executable"),
            "storageId": String(resolved.storageId || ""),
            "appId": String(resolved.appId || ""),
            "command": String(resolved.command || command || ""),
            "launcherUrl": String(resolved.launcherUrl || "")
        }

        root.dockItems = root.dockItems.concat([pinDescriptor])
        if (!root.syncDockItemsConfiguration()) {
            root.dockItems = previousItems
            return root.operationResult(false, "persist-failed", appName)
        }
        return root.operationResult(true, "pinned", appName)
    }

    function pinAppToDockAt(storageId, targetIndex) {
        const resolved = root.resolveApplication(storageId, "")
        if (!resolved || !resolved.resolved) {
            return root.operationResult(false,
                resolved ? resolved.status : "unavailable", storageId)
        }

        const appName = String(resolved.name || resolved.storageId || "")
        const existingIndex = root.findDockItemIndexForResolvedApplication(resolved)
        const boundedTarget = Math.max(0, Math.min(root.dockItems.length,
            Number.isFinite(Number(targetIndex)) ? Math.round(Number(targetIndex)) : root.dockItems.length))
        const previousItems = root.dockItems
        let nextItems = root.dockItems.slice()
        let pinDescriptor = null
        let adjustedTarget = boundedTarget

        if (existingIndex >= 0) {
            pinDescriptor = nextItems[existingIndex]
            nextItems.splice(existingIndex, 1)
            if (existingIndex < adjustedTarget) {
                adjustedTarget--
            }
        } else {
            pinDescriptor = {
                "type": "app",
                "name": appName,
                "icon": String(resolved.icon || "application-x-executable"),
                "storageId": String(resolved.storageId || ""),
                "appId": String(resolved.appId || ""),
                "command": String(resolved.command || ""),
                "launcherUrl": String(resolved.launcherUrl || "")
            }
        }

        adjustedTarget = Math.max(0, Math.min(nextItems.length, adjustedTarget))
        if (existingIndex >= 0 && adjustedTarget === existingIndex) {
            return root.operationResult(true, "moved", appName)
        }
        nextItems.splice(adjustedTarget, 0, pinDescriptor)
        root.dockItems = nextItems
        if (!root.syncDockItemsConfiguration()) {
            root.dockItems = previousItems
            return root.operationResult(false, "persist-failed", appName)
        }

        root.recentlyTransitionedAppId = root.taskController
            ? root.taskController.normalizeApplicationId(
                resolved.appId || resolved.storageId || "")
            : String(resolved.appId || resolved.storageId || "")
        root.recentlyTransitionedLauncherUrl = root.taskController
            ? root.taskController.normalizeLauncherUrl(
                "applications:" + String(resolved.storageId || ""))
            : String(resolved.launcherUrl || "")
        itemTransitionTimer.restart()
        return root.operationResult(true,
            existingIndex >= 0 ? "moved" : "pinned", appName)
    }

    function pinApplicationLauncherAt(urls, targetIndex) {
        const validation = root.validateApplicationLauncherDrop(urls)
        if (!validation.accepted) {
            return root.operationResult(false,
                validation.errorCode || "invalid-source", "")
        }
        return root.pinAppToDockAt(validation.storageId, targetIndex)
    }

    function pinAppToDesktop(storageId, command) {
        if (root.systemDiscovery && typeof root.systemDiscovery.createDesktopShortcut === "function") {
            const result = root.systemDiscovery.createDesktopShortcut(
                String(storageId || ""), String(command || ""))
            return root.operationResult(!!result.success, result.status,
                result.name || storageId || command)
        }
        return root.operationResult(false, "unavailable", storageId || command)
    }

    function unpinItemFromDock(targetIndex, expectedApplicationId, expectedLauncherUrl) {
        const index = Number(targetIndex)
        if (!Number.isInteger(index) || index < 0 || index >= root.dockItems.length) {
            return false
        }

        const dockItem = root.dockItems[index]
        const actualApplicationId = root.taskController
            ? root.taskController.dockItemApplicationId(dockItem)
            : ""
        const actualLauncherUrl = root.taskController
            ? root.taskController.dockItemLauncherUrl(dockItem)
            : ""
        const normalizedExpectedApplicationId = root.taskController
            ? root.taskController.normalizeApplicationId(expectedApplicationId || "")
            : String(expectedApplicationId || "")
        const normalizedExpectedLauncherUrl = root.taskController
            ? root.taskController.normalizeLauncherUrl(expectedLauncherUrl || "")
            : String(expectedLauncherUrl || "")
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
