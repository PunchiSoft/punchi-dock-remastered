import QtQuick

Item {
    id: root

    width: 0
    height: 0
    visible: false

    property bool inPanel: false
    property int panelPopupDirection: Qt.TopEdge
    property rect availableScreenRect: Qt.rect(0, 0, 800, 640)
    property var geometryStateRef: null
    property int popupDirection: panelPopupDirection
    property var dockFallbackAnchor: null
    property var taskStructureSource: null
    property var taskControllerRef: null
    property var mprisControllerRef: null
    property var trashIntegrationRef: null
    property var trashContextContentRef: null
    property var notePopupContentRef: null
    property var taskWindowsPopupContentRef: null
    property var taskPopupSurfaceRef: null
    property var taskPopupAnimatedContentRef: null

    property var folderPopupDialogRef: null
    property var calendarPopupDialogRef: null
    property var trashMenuDialogRef: null
    property var notePopupDialogRef: null
    property var appActionsDialogRef: null
    property var taskWindowsDialogRef: null
    property var taskOverflowDialogRef: null
    property var punchiMenuDialogRef: null

    property var applicationIdentityResolver: null
    property var contextActionsResolver: null

    property var activeFolderData: ({})
    property var activeCalendarData: ({})
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
    property string mediaHoverMode: "card"
    property bool mediaHoverEnabled: mediaHoverMode !== "none"
    readonly property bool mediaReplacementMode:
        mediaHoverMode === "card" || mediaHoverMode === "fullCard"
    property bool windowPreviewsEnabled: true
    property string activeTaskPopupPresentation: "none"
    readonly property bool mediaHoverActive:
        taskPresentationPolicy.isReplacement(activeTaskPopupPresentation)
    property bool pendingTaskPopupKeyboardInvoked: false
    property bool pendingTaskPopupPreviewFallback: true
    property bool pendingTaskPopupRequestValid: false
    property bool pendingTaskPopupAwaitingMediaResolution: false

    readonly property bool contextMenuVisible: contextMenuOpening
        || (appActionsDialogRef && appActionsDialogRef.visible)
        || (trashMenuDialogRef && trashMenuDialogRef.visible)
            || (taskWindowsPopupContentRef && taskWindowsPopupContentRef.actionsVisible)

    TaskPopupPresentationController {
        id: taskPresentationPolicy
        mediaEnabled: root.mediaHoverEnabled
        mediaMode: root.mediaHoverMode
        mediaControllerRef: root.mprisControllerRef
    }

    readonly property bool isAnyPopupActiveGlobally: {
        return (folderPopupDialogRef && folderPopupDialogRef.visible)
            || (calendarPopupDialogRef && calendarPopupDialogRef.visible)
            || (trashMenuDialogRef && trashMenuDialogRef.visible)
            || (notePopupDialogRef && notePopupDialogRef.visible)
            || (appActionsDialogRef && appActionsDialogRef.visible)
            || (taskWindowsDialogRef && taskWindowsDialogRef.visible)
            || (taskOverflowDialogRef && taskOverflowDialogRef.visible)
            || (punchiMenuDialogRef && punchiMenuDialogRef.visible)
            || contextMenuOpening
    }

    onWindowPreviewsEnabledChanged: {
        if (windowPreviewsEnabled) {
            return
        }
        pendingTaskPopupPreviewFallback = false
        taskPopupOpenTimer.stop()
        if ((activeTaskPopupPresentation === "preview"
                || activeTaskPopupPresentation === "overlay")
                && root.popupDialogActive(taskWindowsDialogRef)) {
            hideTaskWindowsDialog()
            resetTaskPopupState()
        }
    }

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
                root.closeTaskWindowsPopup(true)
            }
        }
    }

    Timer {
        id: mediaAvailabilityFallbackTimer
        interval: 180
        repeat: false
        onTriggered: {
            if (!root.mediaHoverActive || !root.mprisControllerRef
                    || root.mprisControllerRef.available
                    || root.mprisControllerRef.resolving) {
                return
            }
            const activeApplicationId = String(
                root.activeTaskPopupData.applicationId || "")
            const requestedApplicationId = String(
                root.mprisControllerRef.applicationId || "")
            if (activeApplicationId.length > 0
                    && requestedApplicationId.length > 0
                    && activeApplicationId !== requestedApplicationId) {
                return
            }
            const previewAvailable = root.windowPreviewsEnabled
                && root.pendingTaskPopupPreviewFallback
                && (root.activeTaskPopupData.windows || []).length > 0
            root.activeTaskPopupPresentation = previewAvailable
                ? "preview"
                : "none"
            if (previewAvailable) {
                root.taskWindowsPopupContentRef.showPreviews()
            } else if (root.taskWindowsDialogRef) {
                root.hideTaskWindowsDialog()
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

        function onResolvingChanged() {
            if (root.mprisControllerRef.resolving) {
                mediaAvailabilityFallbackTimer.stop()
                return
            }
            root.resumePendingTaskPopupAfterMediaResolution()
            if (root.mediaHoverActive
                    && !root.mprisControllerRef.available) {
                mediaAvailabilityFallbackTimer.restart()
            }
        }

        function onStateChanged() {
            if (root.mprisControllerRef.resolving) {
                mediaAvailabilityFallbackTimer.stop()
                return
            }
            if (!root.mediaHoverActive) {
                root.resumePendingTaskPopupAfterMediaResolution()
                mediaAvailabilityFallbackTimer.stop()
                return
            }
            if (root.mprisControllerRef.available) {
                mediaAvailabilityFallbackTimer.stop()
                return
            }
            mediaAvailabilityFallbackTimer.restart()
        }
    }

    function surfaceAvailable(surface, name) {
        if (surface) {
            return true
        }
        console.warn("Punchi Dock: popup surface unavailable:", name)
        return false
    }

    function showTaskWindowsDialog() {
        if (root.popupDialogActive(root.taskWindowsDialogRef)) {
            return true
        }
        return root.showPopupDialog(root.taskWindowsDialogRef)
    }

    function hideTaskWindowsDialog() {
        root.hidePopupDialog(root.taskWindowsDialogRef)
    }

    function popupDialogActive(dialog) {
        return !!(dialog && (dialog.visible || dialog.preparingToShow))
    }

    function showPopupDialog(dialog) {
        if (!dialog) {
            return false
        }
        if (typeof dialog.openSafely === "function") {
            dialog.openSafely()
        } else {
            dialog.visible = true
        }
        return true
    }

    function hidePopupDialog(dialog) {
        if (!dialog) {
            return
        }
        if (typeof dialog.closeSafely === "function") {
            dialog.closeSafely()
        } else {
            dialog.visible = false
        }
    }

    function popupAnchor(visualParent) {
        return visualParent || dockFallbackAnchor
    }

    function taskPopupAnchor(visualParent) {
        if (visualParent && visualParent.taskPopupAnchorItem) {
            return visualParent.taskPopupAnchorItem
        }
        return popupAnchor(visualParent)
    }

    function taskPopupHorizontalX(popupWidth, availableGeometry) {
        const anchor = taskPopupAnchor(root.taskPopupVisualParent)
        const width = Number(popupWidth)
        const bounds = availableGeometry || Qt.rect(0, 0, 0, 0)
        const boundsX = Number(bounds.x)
        const boundsWidth = Number(bounds.width)
        if (!anchor || typeof anchor.mapToGlobal !== "function"
                || !Number.isFinite(width) || width <= 0
                || !Number.isFinite(boundsX)
                || !Number.isFinite(boundsWidth) || boundsWidth <= 0) {
            return Number.NaN
        }

        try {
            const anchorWidth = Math.max(0, Number(anchor.width || 0))
            const anchorHeight = Math.max(0, Number(anchor.height || 0))
            const center = anchor.mapToGlobal(Qt.point(
                anchorWidth / 2, anchorHeight / 2))
            const desiredX = Math.round(Number(center.x) - (width / 2))
            const maximumX = Math.max(boundsX,
                boundsX + boundsWidth - width)
            return Math.round(Math.max(boundsX,
                Math.min(maximumX, desiredX)))
        } catch (error) {
            return Number.NaN
        }
    }

    function popupDirectionForAnchor(anchor) {
        if (inPanel || !anchor) {
            return panelPopupDirection
        }

        try {
            const anchorPoint = Qt.point(Math.max(0, Number(anchor.width || 0)) / 2,
                Math.max(0, Number(anchor.height || 0)) / 2)
            const center = typeof anchor.mapToGlobal === "function"
                ? anchor.mapToGlobal(anchorPoint)
                : anchor.mapToScene(anchorPoint)
            const centerX = center.x
            const centerY = center.y
            const screen = availableScreenRect
            const distances = [
                { "direction": Qt.BottomEdge,
                    "distance": Math.abs(centerY - screen.y) },
                { "direction": Qt.TopEdge,
                    "distance": Math.abs((screen.y + screen.height) - centerY) },
                { "direction": Qt.RightEdge,
                    "distance": Math.abs(centerX - screen.x) },
                { "direction": Qt.LeftEdge,
                    "distance": Math.abs((screen.x + screen.width) - centerX) }
            ]
            let nearest = distances[0]
            for (let index = 1; index < distances.length; index++) {
                if (distances[index].distance < nearest.distance) {
                    nearest = distances[index]
                }
            }
            return nearest.direction
        } catch (error) {
            return panelPopupDirection
        }
    }

    function preparePopupAnchor(visualParent) {
        const anchor = popupAnchor(visualParent)
        if (!inPanel && geometryStateRef
                && typeof geometryStateRef.updateFloatingScreenEdge === "function") {
            geometryStateRef.updateFloatingScreenEdge(anchor)
        }
        popupDirection = popupDirectionForAnchor(anchor)
        return anchor
    }

    function assignPopupAnchor(dialog, anchor) {
        if (!dialog) {
            return
        }
        if (typeof dialog.placementAnchor !== "undefined") {
            dialog.placementAnchor = anchor
            dialog.visualParent = null
        } else {
            dialog.visualParent = anchor
        }
    }

    function closeAllPopups(exceptDialog) {
        const dialogs = [folderPopupDialogRef, calendarPopupDialogRef, trashMenuDialogRef,
            notePopupDialogRef, appActionsDialogRef, taskOverflowDialogRef, taskWindowsDialogRef]
        for (let index = 0; index < dialogs.length; index++) {
            const dialog = dialogs[index]
            if (dialog && dialog !== exceptDialog) {
                root.hidePopupDialog(dialog)
            }
        }
        if (exceptDialog !== taskWindowsDialogRef) {
            taskPopupOpenTimer.stop()
            taskPopupCloseTimer.stop()
            pendingTaskPopupRequestValid = false
            pendingTaskPopupAwaitingMediaResolution = false
        }
    }

    function openTrashMenu(itemData, visualParent, keyboardInvoked) {
        if (!surfaceAvailable(trashMenuDialogRef, "trashMenuDialog")
                || !surfaceAvailable(trashIntegrationRef, "trashIntegration")
                || !surfaceAvailable(trashContextContentRef, "trashContextContent")) {
            return
        }
        const wasActive = root.popupDialogActive(trashMenuDialogRef)
        closeAllPopups(trashMenuDialogRef)
        activeTrashEmptySound = itemData && itemData.emptySound
            ? String(itemData.emptySound)
            : ""
        root.assignPopupAnchor(trashMenuDialogRef,
            preparePopupAnchor(visualParent))
        if (trashIntegrationRef.emptying) {
            trashContextContentRef.showConfirmation()
        } else {
            trashIntegrationRef.resetOperationState()
            trashContextContentRef.showMenu(!!keyboardInvoked)
        }
        if (wasActive) {
            root.hidePopupDialog(trashMenuDialogRef)
        } else {
            root.showPopupDialog(trashMenuDialogRef)
        }
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
        const taskPopupAlreadyActive = taskWindowsDialogRef.visible
            && taskPopupVisualParent === visualParent
        if (taskPopupAlreadyActive && taskPopupAnimatedContentRef) {
            taskPopupAnimatedContentRef.cancelClosing()
        }
        if (taskPopupAlreadyActive && taskWindowsPopupContentRef.actionsVisible) {
            taskPopupOpenTimer.stop()
            taskPopupCloseTimer.stop()
            taskWindowsPopupContentRef.showPreviews()
            return
        }
        const contextualTaskApplicationId = taskControllerRef.taskApplicationIdForRows(rows)
        const preserveMediaContext = taskPopupAlreadyActive
            && mediaHoverActive
            && String(activeTaskPopupData.applicationId || "") === contextualTaskApplicationId
        if (!taskPopupAlreadyActive) {
            mprisControllerRef.applicationId = applicationId
            activeTaskPopupPresentation = "none"
        }
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
        if (taskPopupAlreadyActive) {
            taskPopupOpenTimer.stop()
            taskPopupCloseTimer.stop()
            taskWindowsPopupContentRef.showActions(!preserveMediaContext)
            return
        }

        const anchor = preparePopupAnchor(visualParent)
        closeAllPopups(appActionsDialogRef)
        contextMenuOpening = true
        Qt.callLater(function() {
            root.assignPopupAnchor(appActionsDialogRef, anchor)
            root.showPopupDialog(appActionsDialogRef)
            Qt.callLater(function() {
                root.contextMenuOpening = false
            })
        })
    }

    function openFolderPopup(itemData, visualParent) {
        if (!surfaceAvailable(folderPopupDialogRef, "folderPopupDialog")) {
            return
        }
        const wasActive = root.popupDialogActive(folderPopupDialogRef)
        closeAllPopups(folderPopupDialogRef)
        activeFolderData = itemData
        root.assignPopupAnchor(folderPopupDialogRef,
            preparePopupAnchor(visualParent))
        if (wasActive) {
            root.hidePopupDialog(folderPopupDialogRef)
        } else {
            root.showPopupDialog(folderPopupDialogRef)
        }
    }

    function openCalendarPopup(itemData, visualParent) {
        if (!surfaceAvailable(calendarPopupDialogRef, "calendarPopupDialog")) {
            return
        }
        closeAllPopups(calendarPopupDialogRef)
        activeCalendarData = itemData || ({})
        calendarPopupDialogRef.visualParent = preparePopupAnchor(visualParent)
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
        notePopupDialogRef.visualParent = preparePopupAnchor(visualParent)
        root.showPopupDialog(notePopupDialogRef)
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
        const popupRows = rows || []
        const popupWindows = taskControllerRef.taskWindowsForRows(popupRows)
        const applicationId = taskControllerRef.taskApplicationIdForRows(popupRows)
        const previewAllowed = windowPreviewsEnabled
            && previewFallback !== false
            && popupWindows.length > 0
        const presentation = taskPresentationPolicy.resolve(
            applicationId, previewAllowed)
        if (presentation === "waiting") {
            pendingTaskPopupAwaitingMediaResolution = true
            return
        }
        pendingTaskPopupAwaitingMediaResolution = false
        if (taskPopupAnimatedContentRef) {
            taskPopupAnimatedContentRef.cancelClosing()
        }
        closeAllPopups(taskWindowsDialogRef)
        taskWindowsPopupContentRef.showPreviews()
        if (presentation === "none") {
            if (root.popupDialogActive(taskWindowsDialogRef)) {
                root.hideTaskWindowsDialog()
            }
            resetTaskPopupState()
            return
        }
        activeTaskPopupPresentation = presentation
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
        taskWindowsDialogRef.visualParent = preparePopupAnchor(
            taskPopupAnchor(visualParent))
        taskPopupVisualParent = visualParent
        pendingTaskPopupRequestValid = false
        showTaskWindowsDialog()
        if (taskPresentationPolicy.isReplacement(presentation)
                && keyboardInvoked && taskPopupSurfaceRef) {
            Qt.callLater(function() {
                root.taskPopupSurfaceRef.focusMediaControls()
            })
        }
    }

    function pendingTaskPopupRequestActive() {
        return root.pendingTaskPopupRequestValid
            && root.pendingTaskPopupRows.length > 0
            && !!root.taskPopupVisualParent
    }

    function resumePendingTaskPopupAfterMediaResolution() {
        if (!root.mprisControllerRef
                || !root.mediaHoverEnabled
                || !root.mediaReplacementMode
                || root.mprisControllerRef.resolving
                || !root.pendingTaskPopupAwaitingMediaResolution
                || taskPopupOpenTimer.running
                || root.contextMenuVisible
                || !root.pendingTaskPopupRequestActive()) {
            return
        }
        const applicationId = root.taskControllerRef
            ? root.taskControllerRef.taskApplicationIdForRows(
                root.pendingTaskPopupRows)
            : ""
        if (String(root.mprisControllerRef.applicationId || "")
                !== String(applicationId || "")) {
            return
        }
        root.openTaskWindowsPopup(root.pendingTaskPopupAppName,
            root.pendingTaskPopupRows, root.taskPopupVisualParent,
            root.pendingTaskPopupKeyboardInvoked,
            root.pendingTaskPopupPreviewFallback)
    }

    function openTaskOverflowPopup(visualParent) {
        if (!surfaceAvailable(taskOverflowDialogRef, "taskOverflowDialog")) {
            return
        }
        closeAllPopups(taskOverflowDialogRef)
        taskOverflowDialogRef.visualParent = preparePopupAnchor(visualParent)
        root.showPopupDialog(taskOverflowDialogRef)
    }

    function scheduleTaskWindowsPopup(appName, rows, visualParent, keyboardInvoked, previewFallback) {
        if (contextMenuVisible) {
            taskPopupOpenTimer.stop()
            pendingTaskPopupRequestValid = false
            return
        }
        if (taskWindowsDialogRef && taskWindowsDialogRef.visible
                && taskPopupAnimatedContentRef) {
            taskPopupAnimatedContentRef.cancelClosing()
        }
        if (root.popupDialogActive(taskWindowsDialogRef)
                && taskPopupVisualParent
                && taskPopupVisualParent !== visualParent) {
            root.hideTaskWindowsDialog()
            root.activeTaskPopupPresentation = "none"
        }
        pendingTaskPopupAppName = appName || ""
        pendingTaskPopupRows = rows || []
        taskPopupVisualParent = visualParent || null
        pendingTaskPopupKeyboardInvoked = !!keyboardInvoked
        pendingTaskPopupPreviewFallback = windowPreviewsEnabled
            && previewFallback !== false
        pendingTaskPopupRequestValid = pendingTaskPopupRows.length > 0
            && !!taskPopupVisualParent
        pendingTaskPopupAwaitingMediaResolution = false
        if (!pendingTaskPopupPreviewFallback && !mediaHoverEnabled) {
            resetTaskPopupState()
            return
        }
        if (mediaHoverEnabled && mprisControllerRef && taskControllerRef) {
            mprisControllerRef.applicationId = taskControllerRef.taskApplicationIdForRows(
                pendingTaskPopupRows)
        }
        taskPopupCloseTimer.stop()
        if (pendingTaskPopupRows.length > 0 && taskPopupVisualParent) {
            if (taskWindowsDialogRef && taskWindowsDialogRef.visible
                    && taskWindowsDialogRef.visualParent
                        !== taskPopupAnchor(taskPopupVisualParent)) {
                openTaskWindowsPopup(pendingTaskPopupAppName, pendingTaskPopupRows,
                    taskPopupVisualParent, pendingTaskPopupKeyboardInvoked,
                    pendingTaskPopupPreviewFallback)
                return
            }
            taskPopupOpenTimer.restart()
        }
    }

    function cancelPendingTaskWindowsPopup(visualParent) {
        if (visualParent && taskPopupVisualParent && visualParent !== taskPopupVisualParent) {
            return
        }
        pendingTaskPopupRequestValid = false
        pendingTaskPopupAwaitingMediaResolution = false
        if (!root.popupDialogActive(taskWindowsDialogRef)) {
            resetTaskPopupState()
            return
        }
        if (taskWindowsDialogRef.preparingToShow
                && !taskWindowsDialogRef.visible) {
            root.hideTaskWindowsDialog()
            resetTaskPopupState()
            return
        }
        if (!taskPopupHovered) {
            taskPopupCloseTimer.restart()
        }
    }

    function cancelTaskPopupForPointerReorder() {
        if (root.popupDialogActive(taskWindowsDialogRef)) {
            root.hideTaskWindowsDialog()
        }
        root.resetTaskPopupState()
    }

    function resetTaskPopupState() {
        taskPopupOpenTimer.stop()
        taskPopupCloseTimer.stop()
        mediaAvailabilityFallbackTimer.stop()
        pendingTaskPopupAppName = ""
        pendingTaskPopupRows = []
        taskPopupVisualParent = null
        taskPopupHovered = false
        pendingTaskPopupKeyboardInvoked = false
        pendingTaskPopupPreviewFallback = true
        pendingTaskPopupRequestValid = false
        pendingTaskPopupAwaitingMediaResolution = false
        activeTaskPopupPresentation = "none"
    }

    function closeMediaHoverFromKeyboard() {
        const sourceItem = taskPopupVisualParent
        if (taskWindowsDialogRef) {
            hideTaskWindowsDialog()
        }
        if (sourceItem && sourceItem.focusItem) {
            Qt.callLater(function() {
                sourceItem.focusItem()
            })
        }
    }

    function closeTaskWindowsPopup(animated) {
        taskPopupOpenTimer.stop()
        taskPopupCloseTimer.stop()
        if (!root.popupDialogActive(taskWindowsDialogRef)) {
            return
        }
        if (taskWindowsDialogRef.visible
                && animated && taskPopupAnimatedContentRef) {
            taskPopupAnimatedContentRef.beginClosing()
            return
        }
        hideTaskWindowsDialog()
    }

    function setTaskPopupHovered(hovered) {
        taskPopupHovered = hovered
        if (hovered) {
            taskPopupCloseTimer.stop()
            if (taskPopupAnimatedContentRef) {
                taskPopupAnimatedContentRef.cancelClosing()
            }
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
            hideTaskWindowsDialog()
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
            hideTaskWindowsDialog()
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

    function isPopupActiveForVisualParent(targetItem) {
        if (!targetItem) {
            return false
        }
        const anchor = popupAnchor(targetItem)
        const isTarget = function(dialog) {
            return !!(dialog && dialog.visible && (dialog.visualParent === targetItem || dialog.visualParent === anchor))
        }
        return isTarget(folderPopupDialogRef)
            || isTarget(calendarPopupDialogRef)
            || isTarget(notePopupDialogRef)
            || isTarget(trashMenuDialogRef)
            || isTarget(appActionsDialogRef)
            || isTarget(taskWindowsDialogRef)
            || isTarget(taskOverflowDialogRef)
            || isTarget(punchiMenuDialogRef)
    }
}
