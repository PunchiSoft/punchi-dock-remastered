import QtQuick

QtObject {
    id: root

    property var systemDiscovery: null
    property var taskController: null
    property var dockItemsController: null

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
        if (!item || (item.type || "app") !== "app" || !root.taskController) {
            return []
        }

        const actions = []
        const seenNames = {}
        if (itemOrigin === "dynamic") {
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
        } else if (itemOrigin === "pinned") {
            root.appendUniqueActions(actions, [{
                // qmllint disable unqualified
                "name": i18nc("@action:context", "Unpin from Dock"),
                // qmllint enable unqualified
                "icon": "window-pin",
                "kind": "unpinFromDock",
                "enabled": true,
                "targetIndex": persistentIndex,
                "targetApplicationId": root.taskController.dockItemApplicationId(item),
                "targetLauncherUrl": root.taskController.dockItemLauncherUrl(item)
            }], seenNames)
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
        return actions
    }

    function itemHasContextMenu(item, taskRows, itemOrigin) {
        if (!item || (item.type || "app") !== "app" || !root.taskController) {
            return false
        }
        return itemOrigin === "pinned"
            || (itemOrigin === "dynamic" && !!root.taskController.pinDescriptorForEntry(item))
            || String(item.storageId || item.appId || item.command || "").trim().length > 0
            || (item.actions instanceof Array && item.actions.length > 0)
            || (taskRows instanceof Array && taskRows.length > 0)
    }

    function triggerAction(action) {
        if (!action || action.enabled === false || !root.dockItemsController) {
            return false
        }
        if (action.kind === "pinToDock") {
            return root.dockItemsController.pinTaskToDock(action.pinDescriptor)
        }
        if (action.kind === "unpinFromDock") {
            return root.dockItemsController.unpinItemFromDock(action.targetIndex,
                action.targetApplicationId, action.targetLauncherUrl)
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
