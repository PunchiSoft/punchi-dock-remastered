import QtQuick

QtObject {
    id: root

    property var systemDiscovery: null
    property var taskController: null
    property var dockItemsController: null
    property var editDockItemHandler: null
    property var configureDockHandler: null
    property bool showEditDockItemAction: true
    property bool showConfigureDockAction: true

    function removablePinnedItem(item) {
        if (!item) {
            return false
        }
        const type = String(item.type || "app")
        return type === "app" || type === "folder" || type === "media"
            || type === "punchimenu"
    }

    function editablePinnedItem(item, persistentIndex) {
        if (!item) {
            return false
        }
        const type = String(item.type || "app")
        return Number.isInteger(persistentIndex) && persistentIndex >= 0
            && (type === "app" || type === "folder" || type === "media"
                || type === "punchimenu")
            && typeof root.editDockItemHandler === "function"
    }

    function applicationIdentityForItem(item) {
        if (!item) {
            return ""
        }
        if (String(item.storageId || "").trim().length > 0) {
            return String(item.storageId)
        }
        if (String(item.appId || "").trim().length > 0) {
            return String(item.appId)
        }
        return root.systemDiscovery
            ? String(root.systemDiscovery.applicationIdForCommand(item.command || "") || "")
            : ""
    }

    function appendUniqueActions(target, source, seenNames) {
        const candidates = source instanceof Array ? source : []
        for (let index = 0; index < candidates.length; index++) {
            const action = candidates[index]
            const name = String(action && action.name ? action.name : "").trim()
            const key = name.toLocaleLowerCase()
            if (name.length === 0 || seenNames[key]) {
                continue
            }
            seenNames[key] = true
            target.push(action)
        }
    }

    function actionsForItem(item, taskRows, itemOrigin, persistentIndex) {
        if (!item || !root.taskController) {
            return []
        }

        const itemType = String(item.type || "app")
        const actions = []
        const seenNames = {}
        if (itemType === "app" && itemOrigin === "folder") {
            root.appendUniqueActions(actions, [{
                // Plasma injects translation functions into the applet context.
                // qmllint disable unqualified
                "name": i18nc("@action:context", "Open"),
                // qmllint enable unqualified
                "icon": String(item.icon || "application-x-executable"),
                "kind": "launchDockItem",
                "enabled": true,
                "targetItem": item
            }], seenNames)
        } else if (itemType === "app" && itemOrigin === "dynamic") {
            const pinDescriptor = root.taskController.pinDescriptorForEntry(item)
            if (pinDescriptor && !root.taskController.dockContainsPinDescriptor(pinDescriptor)) {
                root.appendUniqueActions(actions, [{
                    // Plasma injects translation functions into the applet context.
                    // qmllint disable unqualified
                    "name": i18nc("@action:context", "Pin to Dock"),
                    // qmllint enable unqualified
                    "icon": "window-pin",
                    "kind": "pinToDock",
                    "enabled": true,
                    "pinDescriptor": pinDescriptor
                }], seenNames)
            }
        } else if (itemOrigin === "pinned" && root.removablePinnedItem(item)) {
            const itemActions = []
            if (root.showEditDockItemAction && root.editablePinnedItem(item, persistentIndex)) {
                itemActions.push({
                    // qmllint disable unqualified
                    "name": i18nc("@action:context", "Edit item…"),
                    // qmllint enable unqualified
                    "icon": "document-edit",
                    "kind": "editDockItem",
                    "enabled": true,
                    "targetIndex": persistentIndex
                })
            }
            if (root.showConfigureDockAction && typeof root.configureDockHandler === "function") {
                itemActions.push({
                    // qmllint disable unqualified
                    "name": i18nc("@action:context", "Configure Punchi Dock…"),
                    // qmllint enable unqualified
                    "icon": "preferences-system",
                    "kind": "configureDock",
                    "enabled": true
                })
            }
            if (itemType === "punchimenu") {
                const currentMode = String(item.menuMode || "normal")
                const normalPlacement = String(item.normalPlacementMode || "anchored")
                const isNormalAnchored = currentMode === "normal"
                    && normalPlacement !== "centered"
                const isNormalCentered = currentMode === "normal"
                    && normalPlacement === "centered"
                const isFullScreen = currentMode === "fullScreen"
                const isCompact = currentMode === "compact"
                const activeDetail = isCompact
                    // qmllint disable unqualified
                    ? i18nc("@option:punchimenu-mode", "Compact")
                    : isNormalAnchored
                        ? i18nc("@option:punchimenu-mode", "Normal (anchored)")
                        : isNormalCentered
                            ? i18nc("@option:punchimenu-mode", "Normal (floating center)")
                            : i18nc("@option:punchimenu-mode", "Full screen")
                    // qmllint enable unqualified
                itemActions.push({
                    // qmllint disable unqualified
                    "name": i18nc("@title:menu", "Menu mode"),
                    "detail": activeDetail,
                    // qmllint enable unqualified
                    "icon": "view-grid",
                    "kind": "submenu",
                    "enabled": true,
                    "children": [
                        {
                            // qmllint disable unqualified
                            "name": i18nc("@option:punchimenu-mode", "Normal (anchored)"),
                            // qmllint enable unqualified
                            "icon": "view-list-icons",
                            "kind": "setPunchiMenuMode",
                            "enabled": true,
                            "checked": isNormalAnchored,
                            "mode": "normal",
                            "placementMode": "anchored",
                            "targetIndex": persistentIndex
                        },
                        {
                            // qmllint disable unqualified
                            "name": i18nc("@option:punchimenu-mode", "Normal (floating center)"),
                            // qmllint enable unqualified
                            "icon": "window-center",
                            "kind": "setPunchiMenuMode",
                            "enabled": true,
                            "checked": isNormalCentered,
                            "mode": "normal",
                            "placementMode": "centered",
                            "targetIndex": persistentIndex
                        },
                        {
                            // qmllint disable unqualified
                            "name": i18nc("@option:punchimenu-mode", "Full screen"),
                            // qmllint enable unqualified
                            "icon": "view-fullscreen",
                            "kind": "setPunchiMenuMode",
                            "enabled": true,
                            "checked": isFullScreen,
                            "mode": "fullScreen",
                            "targetIndex": persistentIndex
                        },
                        {
                            // qmllint disable unqualified
                            "name": i18nc("@option:punchimenu-mode", "Compact"),
                            // qmllint enable unqualified
                            "icon": "view-list-tree",
                            "kind": "setPunchiMenuMode",
                            "enabled": true,
                            "checked": isCompact,
                            "mode": "compact",
                            "placementMode": "anchored",
                            "targetIndex": persistentIndex
                        }
                    ]
                })
            }
            itemActions.push({
                // qmllint disable unqualified
                "name": i18nc("@action:context", "Unpin from Dock"),
                // qmllint enable unqualified
                "icon": "window-pin",
                "kind": "unpinFromDock",
                "enabled": true,
                "targetIndex": persistentIndex,
                "targetApplicationId": itemType === "app"
                    ? root.taskController.dockItemApplicationId(item)
                    : "",
                "targetLauncherUrl": itemType === "app"
                    ? root.taskController.dockItemLauncherUrl(item)
                    : ""
            })
            root.appendUniqueActions(actions, itemActions, seenNames)
        }

        if (itemType !== "app") {
            return actions
        }

        const applicationId = root.applicationIdentityForItem(item)
        if (applicationId.length > 0 && root.systemDiscovery) {
            root.appendUniqueActions(actions,
                root.systemDiscovery.applicationActions(applicationId), seenNames)
        }

        if (item.actionsEnabled !== false && item.actions instanceof Array) {
            const customActions = item.actions.filter(function(action) {
                return action && String(action.command || "").trim().length > 0
            }).map(function(action) {
                return Object.assign({}, action, {
                    "kind": "customCommand",
                    "enabled": true,
                    "detail": String(action.command || "")
                })
            })
            root.appendUniqueActions(actions, customActions, seenNames)
        }

        root.appendUniqueActions(actions,
            root.taskController.contextActionsForRows(taskRows || []), seenNames)
        if (root.showConfigureDockAction && typeof root.configureDockHandler === "function") {
            root.appendUniqueActions(actions, [{
                // qmllint disable unqualified
                "name": i18nc("@action:context", "Configure Punchi Dock…"),
                // qmllint enable unqualified
                "icon": "preferences-system",
                "kind": "configureDock",
                "enabled": true
            }], seenNames)
        }
        return actions
    }

    function itemHasContextMenu(item, taskRows, itemOrigin) {
        if (!item || !root.taskController) {
            return false
        }
        const itemType = String(item.type || "app")
        if (itemType !== "app") {
            return (itemOrigin === "pinned" && root.removablePinnedItem(item))
                || (root.showConfigureDockAction && typeof root.configureDockHandler === "function")
        }
        return itemOrigin === "pinned"
            || (itemOrigin === "dynamic" && !!root.taskController.pinDescriptorForEntry(item))
            || String(item.storageId || item.appId || item.command || "").trim().length > 0
            || (item.actions instanceof Array && item.actions.length > 0)
            || (taskRows instanceof Array && taskRows.length > 0)
            || (root.showConfigureDockAction && typeof root.configureDockHandler === "function")
    }

    function triggerAction(action) {
        if (!action || action.enabled === false || !root.dockItemsController) {
            return false
        }
        if (action.kind === "launchDockItem") {
            root.dockItemsController.launchDockItem(action.targetItem)
            return true
        }
        if (action.kind === "pinToDock") {
            return root.dockItemsController.pinTaskToDock(action.pinDescriptor)
        }
        if (action.kind === "unpinFromDock") {
            return root.dockItemsController.unpinItemFromDock(action.targetIndex,
                action.targetApplicationId, action.targetLauncherUrl)
        }
        if (action.kind === "editDockItem") {
            return root.editDockItemHandler
                ? root.editDockItemHandler(action.targetIndex)
                : false
        }
        if (action.kind === "configureDock") {
            return root.configureDockHandler
                ? root.configureDockHandler()
                : false
        }
        if (action.kind === "setPunchiMenuMode") {
            const targetIndex = Number(action.targetIndex)
            const targetItem = Number.isInteger(targetIndex)
                    && targetIndex >= 0
                    && targetIndex < root.dockItemsController.dockItems.length
                ? root.dockItemsController.dockItems[targetIndex]
                : null
            if (!targetItem || String(targetItem.type || "") !== "punchimenu") {
                return false
            }
            if (action.placementMode) {
                root.dockItemsController.setPunchiMenuValue(
                    "normalPlacementMode", String(action.placementMode))
            }
            return root.dockItemsController.setPunchiMenuValue(
                "menuMode", String(action.mode || "fullScreen"))
        }
        if (action.kind === "desktopAction") {
            return root.systemDiscovery
                ? root.systemDiscovery.launchApplicationAction(
                    action.applicationId || "", action.actionId || "")
                : false
        }
        if (action.kind === "taskAction" && root.taskController) {
            return root.taskController.triggerContextAction(action)
        }
        if (String(action.command || "").trim().length > 0) {
            root.dockItemsController.runCommand(action.command)
            return true
        }
        return false
    }
}
