import QtQuick
import org.kde.taskmanager as TaskManager

Item {
    id: root

    property var dockItems: []
    property bool showActiveTasks: true
    property bool currentDesktopOnly: true
    property string windowGroupingMode: "application"
    property int maxDynamicGroups: 8
    property var systemDiscovery: null

    property var visibleTaskRows: []
    property var overflowTaskRows: []
    property int visualRevision: 0
    property bool pendingStructureRefresh: false

    TaskManager.TasksModel {
        id: tasksModel
        groupMode: TaskManager.TasksModel.GroupDisabled
        sortMode: TaskManager.TasksModel.SortDisabled
        filterByCurrentVirtualDesktop: root.showActiveTasks && root.currentDesktopOnly
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
    onShowActiveTasksChanged: scheduleRefresh(true)
    onCurrentDesktopOnlyChanged: scheduleRefresh(true)
    onWindowGroupingModeChanged: scheduleRefresh(true)
    onMaxDynamicGroupsChanged: scheduleRefresh(true)

    Component.onCompleted: {
        refreshVisibleRows()
        bumpVisualRevision()
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

    function taskAppIdForRow(row) {
        const taskIndex = tasksModel.index(row, 0)
        return normalizeApplicationId(tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.AppId))
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

    function taskIconNameForRow(row) {
        const taskIndex = tasksModel.index(row, 0)
        const taskAppId = taskAppIdForRow(row)
        let iconName = root.systemDiscovery && taskAppId.length > 0
            ? root.systemDiscovery.iconForApplication(taskAppId)
            : ""
        if (iconName.length > 0) {
            return iconName
        }

        const launcherUrl = String(tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.LauncherUrlWithoutIcon) || "")
        if (root.systemDiscovery && launcherUrl.indexOf("applications:") === 0) {
            iconName = root.systemDiscovery.iconForApplication(launcherUrl.slice("applications:".length))
            if (iconName.length > 0) {
                return iconName
            }
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

        const taskAppId = taskAppIdForRow(row)
        if (taskAppId.length === 0) {
            return true
        }

        for (let index = 0; index < root.dockItems.length; index++) {
            if (dockItemApplicationId(root.dockItems[index]) === taskAppId) {
                return false
            }
        }

        return true
    }

    function buildVisibleTaskEntryForRow(row) {
        const taskIndex = tasksModel.index(row, 0)
        const appId = taskAppIdForRow(row)
        return {
            "key": appId.length > 0 && groupingEnabled() ? ("app:" + appId) : ("row:" + row),
            "appId": appId,
            "rows": [row],
            "firstRow": row,
            "count": 1,
            "name": String(tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.AppName)
                || tasksModel.data(taskIndex, Qt.DisplayRole)
                || ""),
            "icon": taskIconNameForRow(row),
            "active": isTaskRowActive(row),
            "demandsAttention": !!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsDemandingAttention),
            "windowUuid": taskWindowUuidForRow(row)
        }
    }

    function refreshVisibleRows() {
        const entries = []
        const groupedIndexByKey = {}
        if (root.showActiveTasks) {
            for (let row = 0; row < tasksModel.count; row++) {
                if (isTaskRowVisible(row)) {
                    const nextEntry = buildVisibleTaskEntryForRow(row)
                    if (groupingEnabled() && nextEntry.appId.length > 0) {
                        const existingIndex = groupedIndexByKey[nextEntry.key]
                        if (existingIndex !== undefined) {
                            const existingEntry = entries[existingIndex]
                            existingEntry.rows.push(row)
                            existingEntry.count += 1
                            existingEntry.active = existingEntry.active || nextEntry.active
                            existingEntry.demandsAttention = existingEntry.demandsAttention || nextEntry.demandsAttention
                            continue
                        }
                        groupedIndexByKey[nextEntry.key] = entries.length
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

    function scheduleRefresh(needsStructureRefresh) {
        root.pendingStructureRefresh = root.pendingStructureRefresh || !!needsStructureRefresh
        refreshTimer.restart()
    }

    function flushRefresh() {
        if (root.pendingStructureRefresh) {
            refreshVisibleRows()
            root.pendingStructureRefresh = false
        }
        bumpVisualRevision()
    }

    function taskStateForDockItem(item) {
        const appId = dockItemApplicationId(item)
        const result = {
            "count": 0,
            "isActive": false,
            "demandsAttention": false,
            "firstRow": -1,
            "rows": []
        }
        if (appId.length === 0) {
            return result
        }

        for (let row = 0; row < tasksModel.count; row++) {
            const taskIndex = tasksModel.index(row, 0)
            if (!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsWindow)
                    || tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.SkipTaskbar)
                    || taskAppIdForRow(row) !== appId) {
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
                "icon": taskIconNameForRow(row),
                "windowUuid": taskWindowUuidForRow(row)
            })
        }
        return windows
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
            "icon": taskIconNameForRow(firstRow),
            "count": Math.max(1, Number(entry.count || rows.length || 1)),
            "rows": rows,
            "firstRow": firstRow,
            "active": active,
            "demandsAttention": demandsAttention,
            "windowUuid": taskWindowUuidForRow(firstRow)
        }
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
            return
        }
        tasksModel.requestClose(taskIndex)
    }
}
