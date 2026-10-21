import QtQuick
import "../config/code/configItems.js" as ConfigItemsJS

QtObject {
    id: root

    signal showAllPlacesRequested(string applicationId)

    property var systemDiscovery: null
    property var taskController: null
    property var mprisController: null
    property var dockItemsController: null
    property var configureDockHandler: null
    property var moveDynamicApplicationsHandler: null
    property bool showConfigureDockAction: true
    property bool recentContainerActive: false
    property var disableRecentApplicationsHandler: null
    property var setRecentContainerViewHandler: null
    property bool recentApplicationsActive: false
    // The fan is a horizontal-only presentation: a vertical dock cannot select
    // it, but the stored preference stays visible in the menu.
    property bool verticalDock: false

    function removablePinnedItem(item) {
        if (!item) {
            return false
        }
        const type = String(item.type || "app")
        return type === "app" || type === "folder" || type === "media"
            || type === "punchimenu" || type === "note"
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

    function extractActions(target, predicate) {
        const extracted = []
        for (let index = target.length - 1; index >= 0; index--) {
            if (predicate(target[index])) {
                extracted.unshift(target[index])
                target.splice(index, 1)
            }
        }
        return extracted
    }

    function sectionHeader(title) {
        return {
            "name": String(title || ""),
            "kind": "section",
            "enabled": false
        }
    }

    function controlCenterActions(item, persistentIndex) {
        const mode = ConfigItemsJS.normalizedControlCenterMode(item.controlCenterMode)
        // Plasma injects translation functions into the applet context.
        // qmllint disable unqualified
        const floatingName = i18nc("@option:control-center-mode", "Floating")
        const fullscreenName = i18nc("@option:control-center-mode", "Full screen")
        const menuName = i18nc("@title:menu", "Menu mode")
        // qmllint enable unqualified
        const actions = [{
            "name": menuName,
            "icon": "view-grid",
            "kind": "submenu",
            "enabled": true,
            "children": [
                {
                    "name": floatingName,
                    "icon": "window-center",
                    "kind": "setControlCenterMode",
                    "enabled": true,
                    "checked": mode === "floating",
                    "exclusive": true,
                    "mode": "floating",
                    "targetIndex": persistentIndex
                },
                {
                    "name": fullscreenName,
                    "icon": "view-fullscreen",
                    "kind": "setControlCenterMode",
                    "enabled": true,
                    "checked": mode === "fullScreen",
                    "exclusive": true,
                    "mode": "fullScreen",
                    "targetIndex": persistentIndex
                }
            ]
        }]
        if (root.showConfigureDockAction && typeof root.configureDockHandler === "function") {
            actions.push({
                "kind": "separator",
                "enabled": false
            })
            actions.push({
                "name": i18nc("@action:context", "Configure Punchi Dock…"), // qmllint disable unqualified
                "icon": "preferences-system",
                "kind": "configureDock",
                "enabled": true
            })
        }
        return actions
    }

    // qmllint disable unqualified
    function placeAction(place, applicationId) {
        return {
            "name": String(place && place.name ? place.name : ""),
            "icon": String(place && place.icon ? place.icon : "folder"),
            "kind": "openFilePlace",
            "enabled": !place || place.available !== false,
            "applicationId": String(applicationId || ""),
            "resource": String(place && place.resource ? place.resource : "")
        }
    }

    function placeSectionRows(places, applicationId, showAllPlaces) {
        const values = places instanceof Array ? places : []
        if (values.length === 0) {
            return null
        }
        const groups = {}
        const order = []
        for (let index = 0; index < values.length; index++) {
            const group = String(values[index].groupName || "")
            if (!Object.prototype.hasOwnProperty.call(groups, group)) {
                groups[group] = []
                order.push(group)
            }
            groups[group].push(values[index])
        }

        // KFilePlacesModel exposes the first group inline and keeps the
        // remaining groups one level down, exactly like the native applet.
        const firstGroup = order.length > 0 ? order[0] : ""
        const rows = []
        const firstEntries = groups[firstGroup] || []
        for (let index = 0; index < firstEntries.length; index++) {
            rows.push(placeAction(firstEntries[index], applicationId))
        }
        for (let orderIndex = 1; orderIndex < order.length; orderIndex++) {
            const group = order[orderIndex]
            const children = []
            const entries = groups[group] || []
            for (let index = 0; index < entries.length; index++) {
                children.push(placeAction(entries[index], applicationId))
            }
            rows.push({
                "name": group,
                "icon": "folder",
                "kind": "submenu",
                "enabled": true,
                "children": children
            })
        }

        if (!showAllPlaces && rows.length > 7) {
            const remaining = rows.slice(5)
            const visible = rows.slice(0, 5)
            visible.push({
                "name": i18ncp("@action:context", "%1 more Place…",
                    "%1 more Places…", remaining.length),
                "icon": "view-more-symbolic",
                "kind": "showAllPlaces",
                "enabled": true,
                "applicationId": String(applicationId || "")
            })
            return visible
        }
        return rows
    }

    function recentSectionRows(documents, applicationId) {
        const values = documents instanceof Array ? documents : []
        if (values.length === 0) {
            return null
        }
        const rows = []
        const limit = Math.min(values.length, 5)
        for (let index = 0; index < limit; index++) {
            rows.push({
                "name": String(values[index].name || ""),
                "icon": String(values[index].icon || "text-x-generic"),
                "kind": "openRecentDocument",
                "enabled": true,
                "applicationId": String(applicationId || ""),
                "resource": String(values[index].resource || ""),
                "mimeType": String(values[index].mimeType || "")
            })
        }
        rows.push({
            "name": i18nc("@action:context", "Forget Recent Files"),
            "icon": "edit-clear-history",
            "kind": "forgetRecentDocuments",
            "enabled": true,
            "applicationId": String(applicationId || "")
        })
        return rows
    }

    // Rows that mirror the native launcher for a single application: the open
    // entry, its jump list, Places and Recent Files. PunchiMenu consumes these
    // so it does not reimplement the composition of the dock context menu.
    function applicationBackendRows(applicationId) {
        const id = String(applicationId || "")
        const rows = []
        if (id.length === 0 || !root.systemDiscovery) {
            return rows
        }

        rows.push({
            "name": i18nc("@action:context", "Open"),
            "icon": "application-x-executable",
            "kind": "launchApplication",
            "enabled": true,
            "applicationId": id
        })

        if (typeof root.systemDiscovery.applicationActions === "function") {
            const jumpList = root.systemDiscovery.applicationActions(id)
            if (jumpList instanceof Array) {
                for (let index = 0; index < jumpList.length; index++) {
                    rows.push(jumpList[index])
                }
            }
        }

        let places = null
        if (typeof root.systemDiscovery.filePlaceActions === "function") {
            places = root.placeSectionRows(
                root.systemDiscovery.filePlaceActions(id), id, true)
        }
        if (places instanceof Array && places.length > 0) {
            rows.push(root.sectionHeader(
                i18nc("@title:group for section of menu items", "Places")))
            for (let index = 0; index < places.length; index++) {
                rows.push(places[index])
            }
        }

        let recent = null
        if (typeof root.systemDiscovery.recentDocumentActions === "function") {
            recent = root.recentSectionRows(
                root.systemDiscovery.recentDocumentActions(id), id)
        }
        if (recent instanceof Array && recent.length > 0) {
            rows.push(root.sectionHeader(
                i18nc("@title:group for section of menu items", "Recent Files")))
            for (let index = 0; index < recent.length; index++) {
                rows.push(recent[index])
            }
        }
        return rows
    }

    // Provider-backed rows stay hidden when the external tool is missing.
    function applicationProviderRows(applicationId) {
        const id = String(applicationId || "")
        const rows = []
        if (id.length === 0 || !root.systemDiscovery) {
            return rows
        }
        if (typeof root.systemDiscovery.canEditApplication === "function"
                && root.systemDiscovery.canEditApplication(id)) {
            rows.push({
                "name": i18nc("@action:context", "Edit Application…"),
                "icon": "kmenuedit",
                "kind": "editApplication",
                "enabled": true,
                "applicationId": id
            })
        }
        if (typeof root.systemDiscovery.canManageApplication === "function"
                && root.systemDiscovery.canManageApplication(id)) {
            rows.push({
                "name": i18nc("@action:context",
                    "Uninstall or Manage Add-Ons…"),
                "icon": "system-software-install",
                "kind": "manageApplication",
                "enabled": true,
                "applicationId": id
            })
        }
        return rows
    }

    function mediaSubmenu(controller, applicationId) {
        if (!controller || !controller.available
                || String(controller.applicationId || "")
                    !== String(applicationId || "")) {
            return null
        }
        const children = []
        if (controller.canGoPrevious) {
            children.push({
                "name": i18nc("@action:context", "Previous track"),
                "icon": "media-skip-backward",
                "kind": "mprisCommand",
                "command": "previous",
                "applicationId": String(applicationId || ""),
                "enabled": true
            })
        }
        const canPlayPause = controller.playing
            ? controller.canPause : controller.canPlay
        if (canPlayPause) {
            children.push({
                "name": controller.playing
                    ? i18nc("@action:context", "Pause")
                    : i18nc("@action:context", "Play"),
                "icon": controller.playing
                    ? "media-playback-pause" : "media-playback-start",
                "kind": "mprisCommand",
                "command": "togglePlaying",
                "applicationId": String(applicationId || ""),
                "enabled": true
            })
        }
        if (controller.canGoNext) {
            children.push({
                "name": i18nc("@action:context", "Next track"),
                "icon": "media-skip-forward",
                "kind": "mprisCommand",
                "command": "next",
                "applicationId": String(applicationId || ""),
                "enabled": true
            })
        }
        if (controller.canStop === true) {
            children.push({
                "name": i18nc("@action:context", "Stop"),
                "icon": "media-playback-stop",
                "kind": "mprisCommand",
                "command": "stop",
                "applicationId": String(applicationId || ""),
                "enabled": true
            })
        }
        if (children.length === 0) {
            return null
        }
        return {
            "name": i18nc("@title:menu", "Media"),
            "icon": "multimedia-player",
            "kind": "submenu",
            "enabled": true,
            "children": children
        }
    }
    // qmllint enable unqualified

    function actionsForItem(item, taskRows, itemOrigin, persistentIndex, options) {
        if (!item || !root.taskController) {
            return []
        }

        const itemType = String(item.type || "app")
        const recentContainer = itemType === "folder"
            && itemOrigin === "recent-container" && item.entryRole === "recent-container"
        if (recentContainer && !root.recentContainerActive) {
            return []
        }
        if (itemType === "control-center" && itemOrigin === "pinned") {
            return root.controlCenterActions(item, persistentIndex)
        }
        const actions = []
        const dockActions = []
        const seenNames = {}
        let deferredPinnedActions = []
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
        } else if (itemType === "app" && (itemOrigin === "dynamic" || itemOrigin === "recent")) {
            if (itemOrigin === "dynamic" && typeof root.moveDynamicApplicationsHandler === "function") {
                root.appendUniqueActions(actions, [{
                    // Plasma injects translation functions into the applet context.
                    // qmllint disable unqualified
                    "name": i18nc("@action:context", "Move open applications section"),
                    // qmllint enable unqualified
                    "icon": "transform-move",
                    "kind": "moveDynamicApplications",
                    "enabled": true
                }], seenNames)
            }
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
        } else if (recentContainer
                || (itemOrigin === "pinned" && root.removablePinnedItem(item))) {
            const itemActions = []
            if (itemType === "punchimenu") {
                const currentMode = String(item.menuMode || "normal")
                const normalPlacement = String(item.normalPlacementMode || "anchored")
                const isNormalAnchored = currentMode === "normal"
                    && normalPlacement !== "centered"
                const isNormalCentered = currentMode === "normal"
                    && normalPlacement === "centered"
                const isFullScreen = currentMode === "fullScreen"
                const isCompact = currentMode === "compact"
                itemActions.push({
                    // qmllint disable unqualified
                    "name": i18nc("@title:menu", "Menu mode"),
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
                            "exclusive": true,
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
                            "exclusive": true,
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
                            "exclusive": true,
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
                            "exclusive": true,
                            "mode": "compact",
                            "placementMode": "anchored",
                            "targetIndex": persistentIndex
                        }
                    ]
                })
            }
            if (itemType === "folder") {
                const currentFolderView = item.layout === "list"
                        || item.layout === "detailed"
                        || item.layout === "fan"
                    ? item.layout : "grid"
                const expectedFolderText = typeof root.dockItemsController.canonicalJsonText
                        === "function"
                    ? root.dockItemsController.canonicalJsonText(item) : ""
                const folderViewAction = {
                    // qmllint disable unqualified
                    "name": i18nc("@title:menu", "Folder view"),
                    // qmllint enable unqualified
                    "icon": "view-grid",
                    "kind": "submenu",
                    "enabled": true,
                    "children": [
                        {
                            // qmllint disable unqualified
                            "name": i18nc("@item:inlistbox Folder popup layout", "Grid"),
                            // qmllint enable unqualified
                            "icon": "view-grid",
                            "kind": "setFolderView",
                            "enabled": true,
                            "checked": currentFolderView === "grid",
                            "exclusive": true,
                            "layout": "grid",
                            "targetIndex": persistentIndex,
                            "expectedFolderText": expectedFolderText
                        },
                        {
                            // qmllint disable unqualified
                            "name": i18nc("@item:inlistbox Folder popup layout", "List"),
                            // qmllint enable unqualified
                            "icon": "view-list-icons",
                            "kind": "setFolderView",
                            "enabled": true,
                            "checked": currentFolderView === "list",
                            "exclusive": true,
                            "layout": "list",
                            "targetIndex": persistentIndex,
                            "expectedFolderText": expectedFolderText
                        },
                        {
                            // qmllint disable unqualified
                            "name": i18nc("@item:inlistbox Folder popup layout", "Detailed"),
                            // qmllint enable unqualified
                            "icon": "view-list-details",
                            "kind": "setFolderView",
                            "enabled": true,
                            "checked": currentFolderView === "detailed",
                            "exclusive": true,
                            "layout": "detailed",
                            "targetIndex": persistentIndex,
                            "expectedFolderText": expectedFolderText
                        },
                        {
                            // qmllint disable unqualified
                            "name": i18nc("@item:inlistbox Folder popup layout", "Fan"),
                            // qmllint enable unqualified
                            "icon": "view-list-icons",
                            "kind": "setFolderView",
                            "enabled": !root.verticalDock,
                            "checked": currentFolderView === "fan",
                            "exclusive": true,
                            "layout": "fan",
                            "targetIndex": persistentIndex,
                            "expectedFolderText": expectedFolderText
                        }
                    ]
                }
                if (recentContainer) {
                    folderViewAction.name = i18nc("@title:menu", "Container view") // qmllint disable unqualified
                    for (let index = 0; index < folderViewAction.children.length; index++) {
                        const child = folderViewAction.children[index]
                        child.kind = "setRecentContainerView"
                        child.enabled = typeof root.setRecentContainerViewHandler === "function"
                            && !(root.verticalDock && child.layout === "fan")
                        delete child.targetIndex
                        delete child.expectedFolderText
                    }
                }
                itemActions.push(folderViewAction)
                if (!recentContainer) {
                    const currentSort = item.sortMode === "name"
                            || item.sortMode === "size"
                            || item.sortMode === "created"
                            || item.sortMode === "kind"
                        ? item.sortMode : "modified"
                    itemActions.push({
                        // qmllint disable unqualified
                        "name": i18nc("@title:menu", "Sort by"),
                        // qmllint enable unqualified
                        "icon": "view-sort-ascending",
                        "kind": "submenu",
                        "enabled": true,
                        "children": [
                            {
                                "name": i18nc("@item:inmenu folder sort mode", "Name"), // qmllint disable unqualified
                                "icon": "format-text-direction-ltr",
                                "kind": "setFolderSortMode",
                                "enabled": true,
                                "checked": currentSort === "name",
                                "exclusive": true,
                                "sortMode": "name",
                                "targetIndex": persistentIndex,
                                "expectedFolderText": expectedFolderText
                            },
                            {
                                "name": i18nc("@item:inmenu folder sort mode", "Size"), // qmllint disable unqualified
                                "icon": "view-sort-descending",
                                "kind": "setFolderSortMode",
                                "enabled": true,
                                "checked": currentSort === "size",
                                "exclusive": true,
                                "sortMode": "size",
                                "targetIndex": persistentIndex,
                                "expectedFolderText": expectedFolderText
                            },
                            {
                                "name": i18nc("@item:inmenu folder sort mode", "Date Modified"), // qmllint disable unqualified
                                "icon": "document-open-recent",
                                "kind": "setFolderSortMode",
                                "enabled": true,
                                "checked": currentSort === "modified",
                                "exclusive": true,
                                "sortMode": "modified",
                                "targetIndex": persistentIndex,
                                "expectedFolderText": expectedFolderText
                            },
                            {
                                "name": i18nc("@item:inmenu folder sort mode", "Date Created"), // qmllint disable unqualified
                                "icon": "document-new",
                                "kind": "setFolderSortMode",
                                "enabled": true,
                                "checked": currentSort === "created",
                                "exclusive": true,
                                "sortMode": "created",
                                "targetIndex": persistentIndex,
                                "expectedFolderText": expectedFolderText
                            },
                            {
                                "name": i18nc("@item:inmenu folder sort mode", "Type"), // qmllint disable unqualified
                                "icon": "application-x-executable",
                                "kind": "setFolderSortMode",
                                "enabled": true,
                                "checked": currentSort === "kind",
                                "exclusive": true,
                                "sortMode": "kind",
                                "targetIndex": persistentIndex,
                                "expectedFolderText": expectedFolderText
                            }
                        ]
                    })
                    const folderPath = String(item.sourcePath || "").trim()
                    if (folderPath.length > 0) {
                        itemActions.push({
                            "name": i18nc("@action:context", "Open in File Manager"), // qmllint disable unqualified
                            "icon": "document-open-folder",
                            "kind": "openFolderLocation",
                            "enabled": true,
                            "targetPath": folderPath
                        })
                    }
                }
            }
            if (recentContainer) {
                itemActions.push({
                    "name": i18nc("@action:context", "Disable recent applications"), // qmllint disable unqualified
                    "icon": "view-hidden",
                    "kind": "disableRecentApplications",
                    "enabled": typeof root.disableRecentApplicationsHandler === "function"
                })
            } else {
                dockActions.push({
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
            }
            if (itemType === "app" && itemOrigin === "pinned") {
                deferredPinnedActions = itemActions
            } else {
                root.appendUniqueActions(actions, itemActions, seenNames)
            }
        }

        if (itemType !== "app") {
            root.appendDockActionsSection(actions, dockActions, seenNames)
            return actions
        }

        const applicationId = root.applicationIdentityForItem(item)
        const hasTaskRows = taskRows instanceof Array && taskRows.length > 0
        const showAllPlaces = !!options && options.showAllPlaces === true
        let placesRows = null
        let recentRows = null
        if (applicationId.length > 0 && root.systemDiscovery) {
            // qmllint disable unqualified
            const mediaAction = root.mediaSubmenu(root.mprisController, applicationId)
            if (mediaAction) {
                root.appendUniqueActions(actions, [mediaAction], seenNames)
            }

            if (typeof root.systemDiscovery.filePlaceActions === "function") {
                placesRows = root.placeSectionRows(
                    root.systemDiscovery.filePlaceActions(applicationId),
                    applicationId, showAllPlaces)
            }
            if (typeof root.systemDiscovery.recentDocumentActions === "function") {
                recentRows = root.recentSectionRows(
                    root.systemDiscovery.recentDocumentActions(applicationId),
                    applicationId)
            }

            root.appendUniqueActions(actions,
                root.systemDiscovery.applicationActions(applicationId), seenNames)

            if (itemOrigin === "pinned" && !hasTaskRows
                    && typeof root.systemDiscovery.canLaunchNewWindow === "function"
                    && root.systemDiscovery.canLaunchNewWindow(applicationId)) {
                root.appendUniqueActions(actions, [{
                    "name": i18nc("@action:context", "New window"),
                    "icon": "window-new",
                    "kind": "launchNewWindow",
                    "enabled": true,
                    "applicationId": applicationId
                }], seenNames)
            }
            // qmllint enable unqualified
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
        root.appendUniqueActions(actions, deferredPinnedActions, seenNames)

        // Dock management actions (pin/unpin and configure) are one family and
        // stay together at the tail, before the final Close row.
        const pinActions = root.extractActions(actions, function(action) {
            return !!action && action.kind === "pinToDock"
        })
        for (let index = 0; index < pinActions.length; index++) {
            const name = String(pinActions[index].name || "").toLocaleLowerCase()
            if (name.length > 0) {
                delete seenNames[name]
            }
            dockActions.unshift(pinActions[index])
        }
        const closingActions = root.extractActions(actions, function(action) {
            return !!action && action.kind === "taskAction"
                && (action.operation === "close"
                    || action.operation === "closeAll")
        })

        const finalActions = []
        const hasPlaces = placesRows instanceof Array && placesRows.length > 0
        const hasRecent = recentRows instanceof Array && recentRows.length > 0
        if (hasPlaces) {
            // qmllint disable unqualified
            finalActions.push(root.sectionHeader(
                i18nc("@title:group for section of menu items", "Places")))
            // qmllint enable unqualified
            for (let index = 0; index < placesRows.length; index++) {
                finalActions.push(placesRows[index])
            }
        }
        if (hasRecent) {
            // qmllint disable unqualified
            finalActions.push(root.sectionHeader(
                i18nc("@title:group for section of menu items", "Recent Files")))
            // qmllint enable unqualified
            for (let index = 0; index < recentRows.length; index++) {
                finalActions.push(recentRows[index])
            }
        }
        if ((hasPlaces || hasRecent) && actions.length > 0) {
            // qmllint disable unqualified
            finalActions.push(root.sectionHeader(
                i18nc("@title:group for section of menu items", "Actions")))
            // qmllint enable unqualified
        }
        for (let index = 0; index < actions.length; index++) {
            finalActions.push(actions[index])
        }
        root.appendDockActionsSection(finalActions, dockActions, seenNames)
        if (closingActions.length > 0) {
            if (finalActions.length > 0
                    && finalActions[finalActions.length - 1].kind !== "separator") {
                finalActions.push({
                    "kind": "separator",
                    "enabled": false
                })
            }
            for (let index = 0; index < closingActions.length; index++) {
                finalActions.push(closingActions[index])
            }
        }
        return finalActions
    }

    function appendDockActionsSection(actions, dockActions, seenNames) {
        const hasConfigureAction = root.showConfigureDockAction
            && typeof root.configureDockHandler === "function"
        const hasDockActions = dockActions instanceof Array && dockActions.length > 0
        if (!hasDockActions && !hasConfigureAction) {
            return
        }
        if (actions.length > 0 && actions[actions.length - 1].kind !== "separator") {
            actions.push({
                "kind": "separator",
                "enabled": false
            })
        }
        if (hasDockActions) {
            root.appendUniqueActions(actions, dockActions, seenNames)
        }
        if (hasConfigureAction) {
            actions.push({
                // qmllint disable unqualified
                "name": i18nc("@action:context", "Configure Punchi Dock…"),
                // qmllint enable unqualified
                "icon": "preferences-system",
                "kind": "configureDock",
                "enabled": true
            })
        }
    }

    function appendConfigureDockSection(actions) {
        if (!root.showConfigureDockAction
                || typeof root.configureDockHandler !== "function") {
            return
        }
        if (actions.length > 0 && actions[actions.length - 1].kind !== "separator") {
            actions.push({
                "kind": "separator",
                "enabled": false
            })
        }
        actions.push({
            // qmllint disable unqualified
            "name": i18nc("@action:context", "Configure Punchi Dock…"),
            // qmllint enable unqualified
            "icon": "preferences-system",
            "kind": "configureDock",
            "enabled": true
        })
    }

    function itemHasContextMenu(item, taskRows, itemOrigin) {
        if (!item || !root.taskController) {
            return false
        }
        const itemType = String(item.type || "app")
        if (itemOrigin === "recent-container" && itemType === "folder"
                && item.entryRole === "recent-container") {
            return root.recentContainerActive
                && (typeof root.disableRecentApplicationsHandler === "function"
                    || typeof root.setRecentContainerViewHandler === "function")
        }
        if (itemType !== "app") {
            return (itemOrigin === "pinned"
                    && (root.removablePinnedItem(item) || itemType === "control-center"))
                || (root.showConfigureDockAction && typeof root.configureDockHandler === "function")
        }
        return itemOrigin === "pinned"
            || (itemOrigin === "dynamic"
                && (typeof root.moveDynamicApplicationsHandler === "function"
                    || !!root.taskController.pinDescriptorForEntry(item)))
            || String(item.storageId || item.appId || item.command || "").trim().length > 0
            || (item.actions instanceof Array && item.actions.length > 0)
            || (taskRows instanceof Array && taskRows.length > 0)
            || (root.showConfigureDockAction && typeof root.configureDockHandler === "function")
    }

    function triggerAction(action) {
        if (!action || action.enabled === false || !root.dockItemsController) {
            return false
        }
        if (action.kind === "disableRecentApplications") {
            return root.recentContainerActive
                && typeof root.disableRecentApplicationsHandler === "function"
                ? root.disableRecentApplicationsHandler() : false
        }
        if (action.kind === "setRecentContainerView") {
            if (root.verticalDock && action.layout === "fan") {
                return false
            }
            return root.recentContainerActive
                && ["grid", "list", "detailed", "fan"].indexOf(action.layout) >= 0
                && typeof root.setRecentContainerViewHandler === "function"
                ? root.setRecentContainerViewHandler(action.layout) : false
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
        if (action.kind === "configureDock") {
            return root.configureDockHandler
                ? root.configureDockHandler()
                : false
        }
        if (action.kind === "moveDynamicApplications") {
            return root.moveDynamicApplicationsHandler
                ? root.moveDynamicApplicationsHandler()
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
        if (action.kind === "setControlCenterMode") {
            const targetIndex = Number(action.targetIndex)
            const items = root.dockItemsController.dockItems
            const targetItem = Number.isInteger(targetIndex) && targetIndex >= 0
                    && targetIndex < items.length ? items[targetIndex] : null
            if (!targetItem || targetItem.type !== "control-center"
                    || (action.mode !== "floating" && action.mode !== "fullScreen")) {
                return false
            }
            return root.dockItemsController.setControlCenterMode(action.mode)
        }
        if (action.kind === "setFolderView") {
            if (root.verticalDock && action.layout === "fan") {
                return false
            }
            return root.dockItemsController.setFolderLayout(
                action.targetIndex, String(action.layout || ""),
                String(action.expectedFolderText || ""))
        }
        if (action.kind === "setFolderSortMode") {
            return root.dockItemsController.setFolderSortMode(
                action.targetIndex, String(action.sortMode || ""),
                String(action.expectedFolderText || ""))
        }
        if (action.kind === "openFolderLocation") {
            if (!root.dockItemsController
                    || typeof root.dockItemsController.openLocation !== "function") {
                return false
            }
            const targetPath = String(action.targetPath || "").trim()
            if (targetPath.length === 0) {
                return false
            }
            root.dockItemsController.openLocation(targetPath)
            return true
        }
        if (action.kind === "launchNewWindow") {
            return !!root.systemDiscovery
                && typeof root.systemDiscovery.launchApplicationNewInstance
                    === "function"
                && root.systemDiscovery.launchApplicationNewInstance(
                    String(action.applicationId || ""))
        }
        if (action.kind === "openRecentDocument") {
            return !!root.systemDiscovery
                && typeof root.systemDiscovery.openRecentDocument === "function"
                && root.systemDiscovery.openRecentDocument(
                    String(action.applicationId || ""),
                    String(action.resource || ""),
                    String(action.mimeType || ""))
        }
        if (action.kind === "forgetRecentDocuments") {
            return !!root.systemDiscovery
                && typeof root.systemDiscovery.forgetRecentDocuments === "function"
                && root.systemDiscovery.forgetRecentDocuments(
                    String(action.applicationId || ""))
        }
        if (action.kind === "showAllPlaces") {
            root.showAllPlacesRequested(String(action.applicationId || ""))
            return true
        }
        if (action.kind === "openFilePlace") {
            return !!root.systemDiscovery
                && typeof root.systemDiscovery.openFilePlace === "function"
                && root.systemDiscovery.openFilePlace(
                    String(action.applicationId || ""),
                    String(action.resource || ""))
        }
        if (action.kind === "mprisCommand") {
            const controller = root.mprisController
            if (!controller || !controller.available
                    || String(controller.applicationId || "")
                        !== String(action.applicationId || "")) {
                return false
            }
            const command = String(action.command || "")
            if (command === "previous") {
                if (!controller.canGoPrevious) {
                    return false
                }
                controller.previous()
                return true
            }
            if (command === "togglePlaying") {
                if (controller.playing ? !controller.canPause : !controller.canPlay) {
                    return false
                }
                controller.togglePlaying()
                return true
            }
            if (command === "next") {
                if (!controller.canGoNext) {
                    return false
                }
                controller.next()
                return true
            }
            if (command === "stop") {
                if (controller.canStop !== true) {
                    return false
                }
                controller.stop()
                return true
            }
            return false
        }
        if (action.kind === "launchApplication") {
            if (!root.systemDiscovery
                    || typeof root.systemDiscovery.launchApplication !== "function") {
                return false
            }
            root.systemDiscovery.launchApplication(
                String(action.applicationId || ""))
            return true
        }
        if (action.kind === "editApplication") {
            return !!root.systemDiscovery
                && typeof root.systemDiscovery.editApplication === "function"
                && root.systemDiscovery.editApplication(
                    String(action.applicationId || ""))
        }
        if (action.kind === "manageApplication") {
            return !!root.systemDiscovery
                && typeof root.systemDiscovery.manageApplication === "function"
                && root.systemDiscovery.manageApplication(
                    String(action.applicationId || ""))
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
