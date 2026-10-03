import QtQuick
import org.kde.taskmanager as TaskManager
import "../org/punchi/dock"

Item {
    id: root
    visible: false
    property var dockItems: []
    property SystemDiscovery systemDiscovery: null
    readonly property var items: selection.items
    property int maximumItems: 3
    property var excludedStorageIds: []

    RecentApplicationsAdapter {
        id: history
        objectName: "recentApplicationsHistory"
        enabled: true
    }
    RecentApplicationsModel {
        id: selection
        objectName: "recentApplicationsSelection"
        enabled: true
        sourceModel: history
        maximumItems: root.maximumItems
        excludedStorageIds: root.excludedStorageIds
    }
    // Exclude every open window, not just visible/overflow/current-desktop
    // entries. This model is created only while the feature is enabled.
    TaskManager.TasksModel {
        id: openTasks
        groupMode: TaskManager.TasksModel.GroupDisabled
        sortMode: TaskManager.TasksModel.SortDisabled
    }
    Connections {
        target: openTasks
        function onRowsInserted() { root.refreshExclusions() }
        function onRowsRemoved() { root.refreshExclusions() }
        function onModelReset() { root.refreshExclusions() }
        function onDataChanged(_first, _last, roles) {
            if (!roles || roles.length === 0
                    || roles.indexOf(TaskManager.AbstractTasksModel.AppId) >= 0
                    || roles.indexOf(TaskManager.AbstractTasksModel.LauncherUrlWithoutIcon) >= 0
                    || roles.indexOf(TaskManager.AbstractTasksModel.IsWindow) >= 0) {
                root.refreshExclusions()
            }
        }
    }
    Connections {
        target: root.systemDiscovery
        function onApplicationAccessed(storageId) { history.recordAccess(storageId) }
    }
    onDockItemsChanged: refreshExclusions()
    onSystemDiscoveryChanged: refreshExclusions()
    Component.onCompleted: refreshExclusions()

    function refreshExclusions() {
        if (!root.systemDiscovery) {
            root.excludedStorageIds = []
            return
        }
        const excluded = []
        const pinned = root.dockItems || []
        for (let i = 0; i < pinned.length; ++i) {
            const item = pinned[i]
            if (item && item.type === "app") {
                const app = root.systemDiscovery.resolveApplication(
                    String(item.storageId || item.appId || ""),
                    String(item.command || ""), String(item.launcherUrl || ""))
                if (app.storageId) { excluded.push(String(app.storageId)) }
            }
        }
        for (let row = 0; row < openTasks.count; ++row) {
            const index = openTasks.index(row, 0)
            if (!openTasks.data(index, TaskManager.AbstractTasksModel.IsWindow)) { continue }
            const appId = String(openTasks.data(index, TaskManager.AbstractTasksModel.AppId) || "")
            const launcher = String(openTasks.data(index, TaskManager.AbstractTasksModel.LauncherUrlWithoutIcon) || "")
            const app = root.systemDiscovery.applicationForLauncher(appId, launcher)
            if (app.storageId) { excluded.push(String(app.storageId)) }
            if (appId) { excluded.push(appId) }
        }
        root.excludedStorageIds = excluded
    }
}
