import QtQuick

Item {
    id: root

    width: 0
    height: 0
    visible: false

    property bool inPanel: false
    property var dockFallbackAnchor: null
    property var taskStructureSource: null
    property var taskControllerRef: null
    property var mprisControllerRef: null
    property var trashIntegrationRef: null
    property var trashContextContentRef: null
    property var notePopupContentRef: null
    property var taskWindowsPopupContentRef: null
    property var taskContextSurfaceStackRef: null

    property var folderPopupDialogRef: null
    property var calendarPopupDialogRef: null
    property var trashMenuDialogRef: null
    property var notePopupDialogRef: null
    property var appActionsDialogRef: null
    property var taskWindowsDialogRef: null
    property var taskOverflowDialogRef: null

    property var applicationIdentityResolver: null
    property var contextActionsResolver: null

    property var activeFolderData: ({})
    property var activeNoteData: ({})
    property int activeNoteIndex: -1
    property var activeTaskPopupData: ({ "name": "", "windows": [] })
    property var activeAppContextMenuData: ({ "name": "", "actions": [], "maxVisibleRows": 6 })
    property string activeTrashEmptySound: ""
    property string pendingTaskPopupAppName: ""
    property var pendingTaskPopupRows: []
    property var taskPopupVisualParent: null
    property bool taskPopupHovered: false
    property bool contextMenuOpening: false
    property bool mediaHoverEnabled: false
    property bool mediaHoverActive: false
    property bool pendingTaskPopupKeyboardInvoked: false
    property bool pendingTaskPopupPreviewFallback: true

    readonly property bool contextMenuVisible: contextMenuOpening
        || (appActionsDialogRef && appActionsDialogRef.visible)
        || (trashMenuDialogRef && trashMenuDialogRef.visible)
        || (taskWindowsPopupContentRef && taskWindowsPopupContentRef.actionsVisible)

    Timer {
        id: taskPopupOpenTimer
        interval: 280
        repeat: false
        onTriggered: {
            if (!root.contextMenuVisible
                    && root.taskPopupVisualParent
                    && root.pendingTaskPopupRows.length > 0) {
                root.openTaskWindowsPopup(root.pendingTaskPopupAppName,
                    root.pendingTaskPopupRows, root.taskPopupVisualParent,
                    root.pendingTaskPopupKeyboardInvoked,
                    root.pendingTaskPopupPreviewFallback)
            }
        }
    }

    Timer {
        id: taskPopupCloseTimer
        interval: 260
        repeat: false
        onTriggered: {
            if (root.taskWindowsDialogRef
                    && !root.taskPopupHovered
                    && !root.taskPopupSourceContainsMouse()) {
                root.taskWindowsDialogRef.visible = false
            }
        }
    }

    Connections {
        target: root.taskStructureSource
        function onTaskStructureChanged() {
            root.refreshTaskPopupAfterStructureChange()
        }
    }

    Connections {
        target: root.mprisControllerRef
        function onStateChanged() {
            if (!root.mediaHoverActive || root.mprisControllerRef.available) {
                return
            }
            root.mediaHoverActive = false
            if (root.pendingTaskPopupPreviewFallback) {
                root.taskWindowsPopupContentRef.showPreviews()
            } else if (root.taskWindowsDialogRef) {
                root.taskWindowsDialogRef.visible = false
            }
        }
    }

    function surfaceAvailable(surface, name) {
        if (surface) {
            return true
        }
        console.warn("Punchi Dock: popup surface unavailable:", name)
        return false
    }

    function popupAnchor(visualParent) {
        if (!visualParent) {
            return dockFallbackAnchor
        }
        if (!inPanel && visualParent.popupAnchorItem) {
            return visualParent.popupAnchorItem
        }
        return visualParent
    }

    function closeAllPopups(exceptDialog) {
        const dialogs = [folderPopupDialogRef, calendarPopupDialogRef, trashMenuDialogRef,
            notePopupDialogRef, appActionsDialogRef, taskOverflowDialogRef, taskWindowsDialogRef]
        for (let index = 0; index < dialogs.length; index++) {
            const dialog = dialogs[index]
            if (dialog && dialog !== exceptDialog) {
                dialog.visible = false
            }
        }
        if (exceptDialog !== taskWindowsDialogRef) {
            taskPopupOpenTimer.stop()
            taskPopupCloseTimer.stop()
        }
    }

    function openTrashMenu(itemData, visualParent, keyboardInvoked) {
        if (!surfaceAvailable(trashMenuDialogRef, "trashMenuDialog")
                || !surfaceAvailable(trashIntegrationRef, "trashIntegration")
                || !surfaceAvailable(trashContextContentRef, "trashContextContent")) {
            return
        }
        closeAllPopups(trashMenuDialogRef)
        activeTrashEmptySound = itemData && itemData.emptySound
            ? String(itemData.emptySound)
            : ""
        trashMenuDialogRef.visualParent = popupAnchor(visualParent)
        if (trashIntegrationRef.emptying) {
            trashContextContentRef.showConfirmation()
        } else {
            trashIntegrationRef.resetOperationState()
            trashContextContentRef.showMenu(!!keyboardInvoked)
        }
        trashMenuDialogRef.visible = !trashMenuDialogRef.visible
    }

    function openAppContextMenu(itemData, visualParent, taskRows, itemOrigin, persistentIndex) {
        if (!surfaceAvailable(taskControllerRef, "taskController")
                || !surfaceAvailable(mprisControllerRef, "mprisController")
                || !surfaceAvailable(appActionsDialogRef, "appActionsDialog")
                || !surfaceAvailable(taskWindowsDialogRef, "taskWindowsDialog")
                || !surfaceAvailable(taskWindowsPopupContentRef, "taskWindowsPopupContent")) {
            return
        }
        const rows = taskRows instanceof Array
            ? taskRows
            : taskControllerRef.taskStateForDockItem(itemData).rows
        const applicationId = applicationIdentityResolver
            ? applicationIdentityResolver(itemData)
            : ""
        mprisControllerRef.applicationId = applicationId
        mediaHoverActive = false
        const actions = contextActionsResolver
            ? contextActionsResolver(itemData, rows, itemOrigin || "",
                Number.isInteger(persistentIndex) ? persistentIndex : -1)
            : []
        if (actions.length === 0) {
            return
        }

        activeAppContextMenuData = {
            "name": itemData && itemData.name ? itemData.name : "",
            "icon": itemData && itemData.icon ? itemData.icon : "emblem-music-symbolic",
            "actions": actions,
            "maxVisibleRows": Math.max(1, Math.min(12,
                Number(itemData && itemData.actionPopupMaxVisibleRows
                    ? itemData.actionPopupMaxVisibleRows
                    : 6)))
        }
        if (taskWindowsDialogRef.visible && taskPopupVisualParent === visualParent) {
            taskPopupOpenTimer.stop()
            taskPopupCloseTimer.stop()
            taskWindowsPopupContentRef.showActions()
            return
        }

        const anchor = popupAnchor(visualParent)
        closeAllPopups(appActionsDialogRef)
        contextMenuOpening = true
        Qt.callLater(function() {
            appActionsDialogRef.visualParent = anchor
            appActionsDialogRef.visible = true
            Qt.callLater(function() {
                root.contextMenuOpening = false
            })
        })
    }

    function openFolderPopup(itemData, visualParent) {
        if (!surfaceAvailable(folderPopupDialogRef, "folderPopupDialog")) {
            return
        }
        closeAllPopups(folderPopupDialogRef)
        activeFolderData = itemData
        folderPopupDialogRef.visualParent = popupAnchor(visualParent)
        folderPopupDialogRef.visible = !folderPopupDialogRef.visible
    }

    function openCalendarPopup(visualParent) {
        if (!surfaceAvailable(calendarPopupDialogRef, "calendarPopupDialog")) {
            return
        }
        closeAllPopups(calendarPopupDialogRef)
        calendarPopupDialogRef.visualParent = popupAnchor(visualParent)
        calendarPopupDialogRef.visible = !calendarPopupDialogRef.visible
    }

    function openNotePopup(itemData, visualParent, itemIndex) {
        if (!surfaceAvailable(notePopupDialogRef, "notePopupDialog")
                || !surfaceAvailable(notePopupContentRef, "notePopupContent")) {
            return
        }
        closeAllPopups(null)
        activeNoteData = itemData
        activeNoteIndex = Number.isInteger(itemIndex) ? itemIndex : -1
        notePopupDialogRef.visualParent = popupAnchor(visualParent)
        notePopupDialogRef.visible = true
        Qt.callLater(function() {
            root.notePopupContentRef.focusEditor()
        })
    }

    function openTaskWindowsPopup(appName, rows, visualParent, keyboardInvoked, previewFallback) {
        if (!surfaceAvailable(taskWindowsDialogRef, "taskWindowsDialog")
                || !surfaceAvailable(taskWindowsPopupContentRef, "taskWindowsPopupContent")
                || !surfaceAvailable(taskControllerRef, "taskController")) {
            return
        }
        taskPopupOpenTimer.stop()
        closeAllPopups(taskWindowsDialogRef)
        taskWindowsPopupContentRef.showPreviews()
        const popupRows = rows || []
        const popupWindows = taskControllerRef.taskWindowsForRows(popupRows)
        const applicationId = taskControllerRef.taskApplicationIdForRows(popupRows)
        const showMedia = mediaHoverEnabled
            && mprisControllerRef.applicationId === applicationId
            && mprisControllerRef.available
        if (!showMedia && !previewFallback) {
            resetTaskPopupState()
            return
        }
        mediaHoverActive = showMedia
        activeTaskPopupData = {
            "name": appName || "",
            "icon": popupWindows.length > 0 && popupWindows[0].icon
                ? popupWindows[0].icon
                : "emblem-music-symbolic",
            "applicationId": applicationId,
            "windowUuids": popupWindows.map(function(windowData) {
                return String(windowData.windowUuid || "")
            }).filter(function(uuid) {
                return uuid.length > 0
            }),
            "windows": popupWindows
        }
        taskWindowsDialogRef.visualParent = popupAnchor(visualParent)
        taskPopupVisualParent = visualParent
        taskWindowsDialogRef.visible = true
        if (showMedia && keyboardInvoked && taskContextSurfaceStackRef) {
            Qt.callLater(function() {
                root.taskContextSurfaceStackRef.focusMediaControls()
            })
        }
    }

    function openTaskOverflowPopup(visualParent) {
        if (!surfaceAvailable(taskOverflowDialogRef, "taskOverflowDialog")) {
            return
        }
        closeAllPopups(taskOverflowDialogRef)
        taskOverflowDialogRef.visualParent = popupAnchor(visualParent)
        taskOverflowDialogRef.visible = true
    }

    function scheduleTaskWindowsPopup(appName, rows, visualParent, keyboardInvoked, previewFallback) {
        if (contextMenuVisible) {
            taskPopupOpenTimer.stop()
            return
        }
        pendingTaskPopupAppName = appName || ""
        pendingTaskPopupRows = rows || []
        taskPopupVisualParent = visualParent || null
        pendingTaskPopupKeyboardInvoked = !!keyboardInvoked
        pendingTaskPopupPreviewFallback = previewFallback !== false
        if (mediaHoverEnabled && mprisControllerRef && taskControllerRef) {
            mprisControllerRef.applicationId = taskControllerRef.taskApplicationIdForRows(
                pendingTaskPopupRows)
        }
        taskPopupCloseTimer.stop()
        if (pendingTaskPopupRows.length > 0 && taskPopupVisualParent) {
            taskPopupOpenTimer.restart()
        }
    }

    function cancelPendingTaskWindowsPopup(visualParent) {
        if (visualParent && taskPopupVisualParent && visualParent !== taskPopupVisualParent) {
            return
        }
        if (!taskWindowsDialogRef || !taskWindowsDialogRef.visible) {
            resetTaskPopupState()
            return
        }
        if (!taskPopupHovered) {
            taskPopupCloseTimer.restart()
        }
    }

    function resetTaskPopupState() {
        taskPopupOpenTimer.stop()
        taskPopupCloseTimer.stop()
        pendingTaskPopupAppName = ""
        pendingTaskPopupRows = []
        taskPopupVisualParent = null
        taskPopupHovered = false
        pendingTaskPopupKeyboardInvoked = false
        pendingTaskPopupPreviewFallback = true
        mediaHoverActive = false
    }

    function closeMediaHoverFromKeyboard() {
        const sourceItem = taskPopupVisualParent
        if (taskWindowsDialogRef) {
            taskWindowsDialogRef.visible = false
        }
        if (sourceItem && sourceItem.focusItem) {
            Qt.callLater(function() {
                sourceItem.focusItem()
            })
        }
    }

    function setTaskPopupHovered(hovered) {
        taskPopupHovered = hovered
        if (hovered) {
            taskPopupCloseTimer.stop()
        } else if (!taskPopupSourceContainsMouse()) {
            taskPopupCloseTimer.restart()
        }
    }

    function taskPopupSourceContainsMouse() {
        try {
            return !!(taskPopupVisualParent && taskPopupVisualParent.containsMouse)
        } catch (error) {
            return false
        }
    }

    function refreshTaskPopupAfterStructureChange() {
        if (!taskWindowsDialogRef || !taskControllerRef || !taskWindowsDialogRef.visible) {
            return -1
        }
        const popupData = activeTaskPopupData || {}
        const applicationId = String(popupData.applicationId || "")
        const windowUuids = popupData.windowUuids instanceof Array
            ? popupData.windowUuids
            : []
        if (applicationId.length === 0 && windowUuids.length === 0) {
            return -1
        }

        const windows = taskControllerRef.taskWindowsForIdentity(applicationId, windowUuids)
        if (windows.length === 0) {
            taskWindowsDialogRef.visible = false
            return 0
        }
        const previousKey = (popupData.windows || []).map(function(windowData) {
            return String(windowData.windowUuid || (windowData.row + ":" + windowData.title))
        }).join("\n")
        const currentKey = windows.map(function(windowData) {
            return String(windowData.windowUuid || (windowData.row + ":" + windowData.title))
        }).join("\n")
        if (currentKey !== previousKey) {
            activeTaskPopupData = {
                "name": String(popupData.name || ""),
                "icon": String(popupData.icon || "emblem-music-symbolic"),
                "applicationId": applicationId,
                "windowUuids": windows.map(function(windowData) {
                    return String(windowData.windowUuid || "")
                }).filter(function(uuid) {
                    return uuid.length > 0
                }),
                "windows": windows
            }
        }
        return windows.length
    }

    function removeTaskPopupWindow(taskRow) {
        if (!surfaceAvailable(taskWindowsDialogRef, "taskWindowsDialog")) {
            return
        }
        const popupData = activeTaskPopupData || {}
        const windows = (popupData.windows || []).filter(function(windowData) {
            return Number(windowData.row) !== Number(taskRow)
        })
        if (windows.length === 0) {
            taskWindowsDialogRef.visible = false
            return
        }
        activeTaskPopupData = {
            "name": String(popupData.name || ""),
            "applicationId": String(popupData.applicationId || ""),
            "windowUuids": windows.map(function(windowData) {
                return String(windowData.windowUuid || "")
            }).filter(function(uuid) {
                return uuid.length > 0
            }),
            "windows": windows
        }
    }

    function reanchorTaskWindowsPopup() {
        if (!taskWindowsDialogRef || !taskWindowsDialogRef.visible || !taskWindowsDialogRef.visualParent) {
            return
        }
        const anchor = taskWindowsDialogRef.visualParent
        taskWindowsDialogRef.visualParent = null
        taskWindowsDialogRef.visualParent = anchor
    }
}
