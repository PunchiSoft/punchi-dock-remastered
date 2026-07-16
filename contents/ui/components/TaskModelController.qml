import QtQuick
import org.kde.taskmanager as TaskManager
import "TaskManagerCompatibility.js" as TaskManagerCompatibility

Item {
    id: root

    signal structureChanged()

    property var dockItems: []
    property bool showActiveTasks: true
    property bool currentDesktopOnly: true
    property string windowGroupingMode: "application"
    property int maxDynamicGroups: 8
    property var systemDiscovery: null

    property var visibleTaskRows: []
    property var overflowTaskRows: []
    property int visualRevision: 0
    property int structureRevision: 0
    property bool pendingStructureRefresh: false
    property bool useLegacyCurrentDesktopFilter: false

    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }

    TaskManager.TasksModel {
        id: tasksModel
        groupMode: TaskManager.TasksModel.GroupDisabled
        sortMode: TaskManager.TasksModel.SortDisabled
        virtualDesktop: virtualDesktopInfo.currentDesktop
        filterByVirtualDesktop: root.useLegacyCurrentDesktopFilter

        Component.onCompleted: root.updateCurrentDesktopFilter()
    }

    Timer {
        id: refreshTimer
        interval: 50
        repeat: false
        onTriggered: root.flushRefresh()
    }

    Connections {
        target: tasksModel

        function onCountChanged() {
            root.scheduleRefresh(true)
        }

        function onDataChanged(_topLeft, _bottomRight, roles) {
            root.scheduleRefresh(root.dataChangeNeedsStructureRefresh(roles))
        }

        function onActiveTaskChanged() {
            root.scheduleRefresh(false)
        }

        function onRowsInserted() {
            root.scheduleRefresh(true)
        }

        function onRowsRemoved() {
            root.scheduleRefresh(true)
        }

        function onModelReset() {
            root.scheduleRefresh(true)
        }
    }

    onDockItemsChanged: scheduleRefresh(true)
    onShowActiveTasksChanged: {
        updateCurrentDesktopFilter()
        scheduleRefresh(true)
    }
    onCurrentDesktopOnlyChanged: {
        updateCurrentDesktopFilter()
        scheduleRefresh(true)
    }
    onWindowGroupingModeChanged: scheduleRefresh(true)
    onMaxDynamicGroupsChanged: scheduleRefresh(true)

    Component.onCompleted: {
        updateCurrentDesktopFilter()
        refreshVisibleRows()
        bumpStructureRevision()
        bumpVisualRevision()
    }

    function updateCurrentDesktopFilter() {
        const enabled = root.showActiveTasks && root.currentDesktopOnly
        const nativeFilterApplied = TaskManagerCompatibility.setOptionalProperty(
            tasksModel, "filterByCurrentVirtualDesktop", enabled)
        root.useLegacyCurrentDesktopFilter = enabled && !nativeFilterApplied
    }

    function normalizeApplicationId(value) {
        let text = String(value || "").trim()
        if (text.endsWith(".desktop")) {
            text = text.slice(0, -8)
        }
        return text
    }

    function dockItemApplicationId(item) {
        if (!item || item.type !== "app") {
            return ""
        }

        const storageId = normalizeApplicationId(item.storageId || "")
        if (storageId.length > 0) {
            return storageId
        }

        const appId = normalizeApplicationId(item.appId || "")
        if (appId.length > 0) {
            return appId
        }

        return root.systemDiscovery
            ? normalizeApplicationId(root.systemDiscovery.applicationIdForCommand(item.command || ""))
            : ""
    }

    function normalizeLauncherUrl(value) {
        let text = String(value || "").trim()
        if (text.indexOf("applications:") === 0) {
            text = text.slice("applications:".length)
            if (text.endsWith(".desktop")) {
                text = text.slice(0, -8)
            }
            return text.length > 0 ? ("applications:" + text) : ""
        }
        return text
    }

    function dockItemLauncherUrl(item) {
        if (!item || item.type !== "app") {
            return ""
        }

        const storageId = normalizeApplicationId(item.storageId || "")
        return storageId.length > 0 ? ("applications:" + storageId) : ""
    }

    function taskAppIdForRow(row) {
        const taskIndex = tasksModel.index(row, 0)
        return normalizeApplicationId(tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.AppId))
    }

    function taskLauncherUrlForRow(row) {
        const taskIndex = tasksModel.index(row, 0)
        return normalizeLauncherUrl(tasksModel.data(
            taskIndex, TaskManager.AbstractTasksModel.LauncherUrlWithoutIcon))
    }

    function dockItemMatchesTaskRow(item, row) {
        const dockAppId = dockItemApplicationId(item)
        const taskAppId = taskAppIdForRow(row)
        if (dockAppId.length > 0 && dockAppId === taskAppId) {
            return true
        }

        const dockLauncherUrl = dockItemLauncherUrl(item)
        const taskLauncherUrl = taskLauncherUrlForRow(row)
        return dockLauncherUrl.length > 0 && dockLauncherUrl === taskLauncherUrl
    }

    function taskEntriesMatch(entry, nextEntry) {
        if (!entry || !nextEntry) {
            return false
        }
        if (nextEntry.appId.length > 0 && entry.appIds.indexOf(nextEntry.appId) >= 0) {
            return true
        }
        return nextEntry.launcherUrl.length > 0
            && entry.launcherUrls.indexOf(nextEntry.launcherUrl) >= 0
    }

    function appendEntryIdentity(entry, nextEntry) {
        if (nextEntry.appId.length > 0 && entry.appIds.indexOf(nextEntry.appId) < 0) {
            entry.appIds.push(nextEntry.appId)
        }
        if (nextEntry.launcherUrl.length > 0
                && entry.launcherUrls.indexOf(nextEntry.launcherUrl) < 0) {
            entry.launcherUrls.push(nextEntry.launcherUrl)
        }
    }

    function groupingEnabled() {
        return root.windowGroupingMode !== "window"
    }

    function dataChangeNeedsStructureRefresh(roles) {
        if (!roles || roles.length === 0) {
            return true
        }

        return roles.indexOf(TaskManager.AbstractTasksModel.AppId) >= 0
            || roles.indexOf(TaskManager.AbstractTasksModel.LauncherUrlWithoutIcon) >= 0
            || roles.indexOf(TaskManager.AbstractTasksModel.IsWindow) >= 0
            || roles.indexOf(TaskManager.AbstractTasksModel.SkipTaskbar) >= 0
    }

    function taskIconSourceForRow(row) {
        const taskIndex = tasksModel.index(row, 0)
        const taskAppId = taskAppIdForRow(row)
        let iconName = root.systemDiscovery && taskAppId.length > 0
            ? root.systemDiscovery.iconForApplication(taskAppId)
            : ""
        if (iconName.length > 0) {
            return iconName
        }

        const launcherUrl = taskLauncherUrlForRow(row)
        if (root.systemDiscovery && launcherUrl.indexOf("applications:") === 0) {
            iconName = root.systemDiscovery.iconForApplication(launcherUrl.slice("applications:".length))
            if (iconName.length > 0) {
                return iconName
            }
        }

        const windowIcon = tasksModel.data(taskIndex, Qt.DecorationRole)
        if (windowIcon) {
            return windowIcon
        }

        return "application-x-executable"
    }

    function taskWindowUuidForRow(row) {
        const taskIndex = tasksModel.index(row, 0)
        if (!taskIndex.valid) {
            return ""
        }

        const winIds = tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.WinIdList) || []
        return winIds.length > 0 ? String(winIds[0]) : ""
    }

    function isTaskRowActive(row) {
        const taskIndex = tasksModel.index(row, 0)
        if (!taskIndex.valid) {
            return false
        }
        return !!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsActive)
    }

    function isTaskRowVisible(row) {
        if (!root.showActiveTasks) {
            return false
        }

        const taskIndex = tasksModel.index(row, 0)
        if (!taskIndex.valid
                || !tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsWindow)
                || tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.SkipTaskbar)) {
            return false
        }

        for (let index = 0; index < root.dockItems.length; index++) {
            if (dockItemMatchesTaskRow(root.dockItems[index], row)) {
                return false
            }
        }

        return true
    }

    function buildVisibleTaskEntryForRow(row) {
        const taskIndex = tasksModel.index(row, 0)
        const appId = taskAppIdForRow(row)
        const launcherUrl = taskLauncherUrlForRow(row)
        return {
            "key": appId.length > 0
                ? ("app:" + appId)
                : (launcherUrl.length > 0 ? ("launcher:" + launcherUrl) : ("row:" + row)),
            "appId": appId,
            "appIds": appId.length > 0 ? [appId] : [],
            "launcherUrl": launcherUrl,
            "launcherUrls": launcherUrl.length > 0 ? [launcherUrl] : [],
            "rows": [row],
            "firstRow": row,
            "count": 1,
            "name": String(tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.AppName)
                || tasksModel.data(taskIndex, Qt.DisplayRole)
                || ""),
            "icon": taskIconSourceForRow(row),
            "active": isTaskRowActive(row),
            "demandsAttention": !!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsDemandingAttention),
            "windowUuid": taskWindowUuidForRow(row)
        }
    }

    function refreshVisibleRows() {
        const entries = []
        if (root.showActiveTasks) {
            for (let row = 0; row < tasksModel.count; row++) {
                if (isTaskRowVisible(row)) {
                    const nextEntry = buildVisibleTaskEntryForRow(row)
                    if (groupingEnabled()
                            && (nextEntry.appId.length > 0 || nextEntry.launcherUrl.length > 0)) {
                        let existingIndex = -1
                        for (let entryIndex = 0; entryIndex < entries.length; entryIndex++) {
                            if (taskEntriesMatch(entries[entryIndex], nextEntry)) {
                                existingIndex = entryIndex
                                break
                            }
                        }
                        if (existingIndex >= 0) {
                            const existingEntry = entries[existingIndex]
                            existingEntry.rows.push(row)
                            existingEntry.count += 1
                            existingEntry.active = existingEntry.active || nextEntry.active
                            existingEntry.demandsAttention = existingEntry.demandsAttention || nextEntry.demandsAttention
                            appendEntryIdentity(existingEntry, nextEntry)
                            continue
                        }
                    }
                    entries.push(nextEntry)
                }
            }
        }

        const safeLimit = Math.max(1, Math.min(20, root.maxDynamicGroups))
        root.visibleTaskRows = entries.slice(0, safeLimit)
        root.overflowTaskRows = entries.slice(safeLimit)
    }

    function bumpVisualRevision() {
        root.visualRevision += 1
    }

    function bumpStructureRevision() {
        root.structureRevision += 1
        root.structureChanged()
    }

    function scheduleRefresh(needsStructureRefresh) {
        root.pendingStructureRefresh = root.pendingStructureRefresh || !!needsStructureRefresh
        refreshTimer.restart()
    }

    function flushRefresh() {
        if (root.pendingStructureRefresh) {
            refreshVisibleRows()
            root.pendingStructureRefresh = false
            bumpStructureRevision()
        }
        bumpVisualRevision()
    }

    function taskStateForDockItem(item) {
        const result = {
            "count": 0,
            "isActive": false,
            "demandsAttention": false,
            "firstRow": -1,
            "rows": []
        }
        if (dockItemApplicationId(item).length === 0
                && dockItemLauncherUrl(item).length === 0) {
            return result
        }

        for (let row = 0; row < tasksModel.count; row++) {
            const taskIndex = tasksModel.index(row, 0)
            if (!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsWindow)
                    || tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.SkipTaskbar)
                    || !dockItemMatchesTaskRow(item, row)) {
                continue
            }
            if (result.firstRow === -1) {
                result.firstRow = row
            }
            result.count += 1
            result.rows.push(row)
            result.isActive = result.isActive || isTaskRowActive(row)
            result.demandsAttention = result.demandsAttention
                || !!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsDemandingAttention)
        }

        return result
    }

    function taskWindowsForRows(rows) {
        const windows = []
        for (let index = 0; index < rows.length; index++) {
            const row = rows[index]
            const taskIndex = tasksModel.index(row, 0)
            windows.push({
                "row": row,
                "title": String(tasksModel.data(taskIndex, Qt.DisplayRole) || ""),
                "name": String(tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.AppName) || ""),
                "subtitle": String(tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.GenericName) || ""),
                "active": isTaskRowActive(row),
                "closable": !!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsClosable),
                "minimizable": !!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsMinimizable),
                "minimized": !!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsMinimized),
                "maximizable": !!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsMaximizable),
                "maximized": !!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsMaximized),
                "icon": taskIconSourceForRow(row),
                "windowUuid": taskWindowUuidForRow(row)
            })
        }
        return windows
    }

    function taskApplicationIdForRows(rows) {
        for (let index = 0; index < rows.length; index++) {
            const row = Number(rows[index])
            const taskIndex = tasksModel.index(row, 0)
            if (!taskIndex.valid
                    || !tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsWindow)
                    || tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.SkipTaskbar)) {
                continue
            }

            const appId = taskAppIdForRow(row)
            if (appId.length > 0) {
                return appId
            }
        }

        return ""
    }

    function taskWindowsForIdentity(applicationId, windowUuids) {
        const normalizedAppId = normalizeApplicationId(applicationId)
        const acceptedUuids = {}
        const uuids = windowUuids instanceof Array ? windowUuids : []
        for (let index = 0; index < uuids.length; index++) {
            const uuid = String(uuids[index] || "")
            if (uuid.length > 0) {
                acceptedUuids[uuid] = true
            }
        }

        const rows = []
        for (let row = 0; row < tasksModel.count; row++) {
            const taskIndex = tasksModel.index(row, 0)
            if (!taskIndex.valid
                    || !tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsWindow)
                    || tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.SkipTaskbar)) {
                continue
            }

            const matchesApplication = normalizedAppId.length > 0
                && taskAppIdForRow(row) === normalizedAppId
            const windowUuid = taskWindowUuidForRow(row)
            const matchesWindow = normalizedAppId.length === 0
                && windowUuid.length > 0
                && acceptedUuids[windowUuid] === true
            if (matchesApplication || matchesWindow) {
                rows.push(row)
            }
        }

        return taskWindowsForRows(rows)
    }

    function taskDataForEntry(entry) {
        if (!entry || !entry.rows || entry.rows.length === 0) {
            return {
                "name": "",
                "icon": "application-x-executable",
                "count": 0,
                "rows": [],
                "firstRow": -1,
                "active": false,
                "demandsAttention": false,
                "windowUuid": ""
            }
        }

        const firstRow = Number(entry.firstRow)
        const taskIndex = tasksModel.index(firstRow, 0)
        if (!taskIndex.valid) {
            return {
                "name": "",
                "icon": "application-x-executable",
                "count": 0,
                "rows": [],
                "firstRow": -1,
                "active": false,
                "demandsAttention": false,
                "windowUuid": ""
            }
        }

        const rows = entry.rows.slice()
        let active = false
        let demandsAttention = false
        for (let index = 0; index < rows.length; index++) {
            const row = rows[index]
            const rowIndex = tasksModel.index(row, 0)
            if (!rowIndex.valid) {
                continue
            }
            active = active || isTaskRowActive(row)
            demandsAttention = demandsAttention || !!tasksModel.data(rowIndex, TaskManager.AbstractTasksModel.IsDemandingAttention)
        }
        return {
            "name": String(tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.AppName)
                || tasksModel.data(taskIndex, Qt.DisplayRole)
                || ""),
            "icon": taskIconSourceForRow(firstRow),
            "count": Math.max(1, Number(entry.count || rows.length || 1)),
            "rows": rows,
            "firstRow": firstRow,
            "active": active,
            "demandsAttention": demandsAttention,
            "windowUuid": taskWindowUuidForRow(firstRow)
        }
    }

    // qmllint disable unqualified
    function contextActionsForRows(taskRows) {
        const sourceRows = taskRows instanceof Array ? taskRows : []
        const rows = []
        for (let index = 0; index < sourceRows.length; index++) {
            const row = Number(sourceRows[index])
            if (tasksModel.index(row, 0).valid) {
                rows.push(row)
            }
        }
        if (rows.length === 0) {
            return []
        }

        let preferredRow = rows[0]
        for (let index = 0; index < rows.length; index++) {
            if (isTaskRowActive(rows[index])) {
                preferredRow = rows[index]
                break
            }
        }

        const taskIndex = tasksModel.index(preferredRow, 0)
        const actions = []
        if (tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.CanLaunchNewInstance)) {
            actions.push({
                "kind": "taskAction",
                "operation": "newInstance",
                "name": i18n("New window"),
                "icon": "window-new",
                "taskRow": preferredRow,
                "enabled": true
            })
        }

        if (rows.length > 1) {
            let closableCount = 0
            for (let index = 0; index < rows.length; index++) {
                const rowIndex = tasksModel.index(rows[index], 0)
                if (rowIndex.valid && tasksModel.data(rowIndex, TaskManager.AbstractTasksModel.IsClosable)) {
                    closableCount++
                }
            }
            if (closableCount > 0) {
                actions.push({
                    "kind": "taskAction",
                    "operation": "closeAll",
                    "name": i18np("Close %1 window", "Close all %1 windows", closableCount),
                    "icon": "window-close",
                    "taskRows": rows,
                    "enabled": true,
                    "destructive": true
                })
            }
            return actions
        }

        const minimized = !!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsMinimized)
        const maximized = !!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsMaximized)
        const keepAbove = !!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsKeepAbove)
        const fullScreen = !!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsFullScreen)

        if (tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsMinimizable)) {
            actions.push({
                "kind": "taskAction",
                "operation": "toggleMinimized",
                "name": minimized ? i18n("Restore") : i18n("Minimize"),
                "icon": minimized ? "window-restore" : "window-minimize",
                "taskRow": preferredRow,
                "enabled": true
            })
        }
        if (tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsMaximizable)) {
            actions.push({
                "kind": "taskAction",
                "operation": "toggleMaximized",
                "name": maximized ? i18n("Restore from maximized") : i18n("Maximize"),
                "icon": maximized ? "window-restore" : "window-maximize",
                "taskRow": preferredRow,
                "enabled": true
            })
        }
        actions.push({
            "kind": "taskAction",
            "operation": "toggleKeepAbove",
            "name": keepAbove ? i18n("Do not keep above") : i18n("Keep above"),
            "icon": "window-keep-above",
            "taskRow": preferredRow,
            "enabled": true,
            "checked": keepAbove
        })
        if (tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsFullScreenable)) {
            actions.push({
                "kind": "taskAction",
                "operation": "toggleFullScreen",
                "name": fullScreen ? i18n("Exit full screen") : i18n("Full screen"),
                "icon": fullScreen ? "view-restore" : "view-fullscreen",
                "taskRow": preferredRow,
                "enabled": true,
                "checked": fullScreen
            })
        }
        if (tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsClosable)) {
            actions.push({
                "kind": "taskAction",
                "operation": "close",
                "name": i18n("Close"),
                "icon": "window-close",
                "taskRow": preferredRow,
                "enabled": true,
                "destructive": true
            })
        }
        return actions
    }
    // qmllint enable unqualified

    function triggerContextAction(action) {
        if (!action || action.kind !== "taskAction") {
            return false
        }

        const operation = String(action.operation || "")
        const row = Number(action.taskRow)
        const taskIndex = tasksModel.index(row, 0)
        if (operation === "closeAll") {
            const rows = action.taskRows instanceof Array ? action.taskRows.slice() : []
            for (let index = 0; index < rows.length; index++) {
                closeTaskRow(Number(rows[index]))
            }
            return rows.length > 0
        }
        if (!taskIndex.valid) {
            return false
        }
        if (operation === "newInstance") {
            tasksModel.requestNewInstance(taskIndex)
        } else if (operation === "toggleMinimized") {
            minimizeTaskRow(row)
        } else if (operation === "toggleMaximized") {
            toggleMaximizedTaskRow(row)
        } else if (operation === "toggleKeepAbove") {
            tasksModel.requestToggleKeepAbove(taskIndex)
        } else if (operation === "toggleFullScreen") {
            tasksModel.requestToggleFullScreen(taskIndex)
        } else if (operation === "close") {
            return closeTaskRow(row)
        } else {
            return false
        }
        return true
    }

    function activateTaskRow(row) {
        const taskIndex = tasksModel.index(row, 0)
        if (!taskIndex.valid) {
            return
        }

        if (tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsActive)
                && tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsMinimizable)) {
            tasksModel.requestToggleMinimized(taskIndex)
            return
        }

        tasksModel.requestActivate(taskIndex)
    }

    function activatePreferredTaskRow(rows) {
        if (!rows || rows.length === 0) {
            return
        }

        for (let index = 0; index < rows.length; index++) {
            const row = Number(rows[index])
            if (isTaskRowActive(row)) {
                activateTaskRow(row)
                return
            }
        }

        activateTaskRow(Number(rows[0]))
    }

    function closeTaskRow(row) {
        const taskIndex = tasksModel.index(row, 0)
        if (!taskIndex.valid || !tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsClosable)) {
            return false
        }
        tasksModel.requestClose(taskIndex)
        return true
    }

    function requestWindowPresentation(row) {
        const taskIndex = tasksModel.index(row, 0)
        if (!taskIndex.valid) {
            return
        }

        tasksModel.requestActivate(taskIndex)
    }

    function minimizeTaskRow(row) {
        const taskIndex = tasksModel.index(row, 0)
        if (!taskIndex.valid || !tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsMinimizable)) {
            return
        }

        if (tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsMinimized)) {
            tasksModel.requestActivate(taskIndex)
            return
        }

        tasksModel.requestToggleMinimized(taskIndex)
    }

    function toggleMaximizedTaskRow(row) {
        const taskIndex = tasksModel.index(row, 0)
        if (!taskIndex.valid || !tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsMaximizable)) {
            return
        }

        if (tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsMinimized)) {
            tasksModel.requestActivate(taskIndex)
        }

        tasksModel.requestToggleMaximized(taskIndex)
        tasksModel.requestActivate(taskIndex)
    }
}
