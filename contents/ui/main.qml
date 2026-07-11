import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.taskmanager as TaskManager
import "org/punchi/dock" as Punchi
import "components"
import "../code/logic.js" as Logic

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    toolTipMainText: ""
    toolTipSubText: ""
    preferredRepresentation: fullRepresentation
    compactRepresentation: fullRepresentation

    // Propiedad base, inicia vacía hasta que leamos la configuración
    property var dockItems: []
    
    // Detector de entorno (Panel vs Flotante)
    property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    property bool trashHasItems: false
    property var visibleTaskRows: []
    property int taskVisualRevision: 0
    property bool pendingTaskStructureRefresh: false
    property var activeTaskPopupData: ({ "name": "", "windows": [] })
    property string hoverTaskPopupAppName: ""
    property var hoverTaskPopupRows: []
    property var hoverTaskPopupVisualParent: null

    // Visibilidad por Escritorios Virtuales
    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }
    TaskManager.TasksModel {
        id: tasksModel
        groupMode: TaskManager.TasksModel.GroupDisabled
        sortMode: TaskManager.TasksModel.SortDisabled
        filterByCurrentVirtualDesktop: Plasmoid.configuration.showActiveTasks
            && Plasmoid.configuration.showTasksCurrentDesktopOnly
    }
    Punchi.SystemDiscovery {
        id: systemDiscovery
        onOperationFailed: function(operation, message) {
            console.warn("Punchi Dock:", operation, message)
        }
    }
    Timer {
        id: refreshTasksTimer
        interval: 50
        repeat: false
        onTriggered: root.flushTaskRefresh()
    }
    Timer {
        id: hoverTaskPopupOpenTimer
        interval: 280
        repeat: false
        onTriggered: {
            if (root.hoverTaskPopupVisualParent && root.hoverTaskPopupRows.length > 0) {
                mainContainer.openTaskWindowsPopup(root.hoverTaskPopupAppName, root.hoverTaskPopupRows, root.hoverTaskPopupVisualParent)
            }
        }
    }
    Timer {
        id: hoverTaskPopupCloseTimer
        interval: 220
        repeat: false
        onTriggered: {
            if (!root.taskWindowsPopupShouldStayOpen()) {
                taskWindowsDialog.visible = false
                root.hoverTaskPopupVisualParent = null
                root.hoverTaskPopupRows = []
                root.hoverTaskPopupAppName = ""
            }
        }
    }
    readonly property string currentVirtualDesktopId: String(virtualDesktopInfo.currentDesktop || "")
    readonly property bool singleVirtualDesktopMode: Plasmoid.configuration.virtualDesktopMode === "single"
        && Plasmoid.configuration.targetVirtualDesktop !== ""
    readonly property bool hiddenByVirtualDesktop: singleVirtualDesktopMode
        && currentVirtualDesktopId !== Plasmoid.configuration.targetVirtualDesktop
    readonly property int visibleDockItemCount: (dockItems ? dockItems.length : 0) + visibleTaskRows.length
    readonly property int dockSpacing: 8
    readonly property int dockBackgroundHorizontalPadding: 18
    readonly property int dockBackgroundVerticalPadding: 12
    readonly property int floatingExtraWidth: 48
    readonly property int floatingExtraHeight: 32
    readonly property string windowPreviewStyle: String(Plasmoid.configuration.windowPreviewStyle || "thumbnail")
    readonly property bool showWindowThumbnails: windowPreviewStyle === "thumbnail"
    readonly property bool dockShowLabels: !!Plasmoid.configuration.showLabels
    readonly property int dockLabelFontSize: Math.max(10, Math.round(effectiveIconSize * 0.22))
    readonly property int dockLabelAreaHeight: dockShowLabels ? (dockLabelFontSize + 12) : 0
    readonly property string dockClickEffect: String(Plasmoid.configuration.clickEffect || "none")
    readonly property string dockIndicatorType: String(Plasmoid.configuration.indicatorType || "line")
    readonly property string dockIndicatorPosition: String(Plasmoid.configuration.indicatorPosition || "bottom")
    readonly property real dockIndicatorOpacity: Math.max(0.0, Math.min(1.0, Number(Plasmoid.configuration.indicatorOpacity || 100) / 100.0))
    readonly property int dockIndicatorThickness: Math.max(2, Number(Plasmoid.configuration.indicatorThickness || 4))
    readonly property real configuredHoverScale: Math.max(1.0, Number(Plasmoid.configuration.hoverScale || 1.0))
    readonly property real panelHoverScale: inPanel ? Math.min(configuredHoverScale, 1.18) : configuredHoverScale
    readonly property int panelLocation: Plasmoid.location
    readonly property bool verticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool horizontalPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
    readonly property bool topPanel: panelLocation === PlasmaCore.Types.TopEdge
    readonly property bool bottomPanel: panelLocation === PlasmaCore.Types.BottomEdge
    readonly property bool leftPanel: panelLocation === PlasmaCore.Types.LeftEdge
    readonly property bool rightPanel: panelLocation === PlasmaCore.Types.RightEdge
    readonly property int popupDialogLocation: {
        if (!inPanel) {
            return Plasmoid.location
        }
        if (panelLocation === PlasmaCore.Types.TopEdge) {
            return PlasmaCore.Types.BottomEdge
        }
        if (panelLocation === PlasmaCore.Types.BottomEdge) {
            return PlasmaCore.Types.TopEdge
        }
        if (panelLocation === PlasmaCore.Types.LeftEdge) {
            return PlasmaCore.Types.RightEdge
        }
        if (panelLocation === PlasmaCore.Types.RightEdge) {
            return PlasmaCore.Types.LeftEdge
        }
        return Plasmoid.location
    }
    readonly property int detectedPanelThickness: {
        try {
            var containment = Plasmoid.containment
            if (!containment || !containment.screenGeometry || !containment.availableScreenRect) {
                return 0
            }

            var screenGeometry = containment.screenGeometry
            var availableScreenRect = containment.availableScreenRect
            var thickness = verticalPanel
                ? Math.max(0, screenGeometry.width - availableScreenRect.width)
                : Math.max(0, screenGeometry.height - availableScreenRect.height)
            return thickness > 0 ? thickness : 0
        } catch (error) {
            return 0
        }
    }
    readonly property int panelCrossAxisPadding: verticalPanel ? (dockBackgroundHorizontalPadding * 2) : (dockBackgroundVerticalPadding * 2)
    readonly property int effectivePanelIconLimit: detectedPanelThickness > 0
        ? Math.max(32, detectedPanelThickness - panelCrossAxisPadding - 12)
        : Math.max(32, Number(Plasmoid.configuration.iconSize || 48))
    readonly property int effectivePanelBaseIconLimit: Math.max(24, Math.floor(effectivePanelIconLimit / panelHoverScale))
    readonly property int effectiveIconSize: inPanel
        ? Math.min(Number(Plasmoid.configuration.iconSize || 48), effectivePanelBaseIconLimit)
        : Number(Plasmoid.configuration.iconSize || 48)
    readonly property bool panelSeemsToFillEdge: {
        try {
            var containment = Plasmoid.containment
            if (!containment || !containment.availableScreenRect) {
                return false
            }
            if (verticalPanel) {
                return containment.height >= containment.availableScreenRect.height * 0.92
            }
            if (horizontalPanel) {
                return containment.width >= containment.availableScreenRect.width * 0.92
            }
            return false
        } catch (error) {
            return false
        }
    }
    readonly property bool panelFillLengthEnabled: inPanel
        && panelSeemsToFillEdge
        && Plasmoid.configuration.panelLengthMode === "fill"
    readonly property int panelItemWidth: Math.ceil(Math.max(effectiveIconSize + 12, dockShowLabels ? effectiveIconSize * 1.85 : 0))
    readonly property int panelItemHeight: Math.ceil(effectiveIconSize + 12 + dockLabelAreaHeight)
    readonly property int panelHoverCrossAxisExtent: Math.ceil(Math.max(panelItemWidth, panelItemHeight, (effectiveIconSize * panelHoverScale) + 12))
    readonly property int panelContentWidth: visibleDockItemCount > 0
        ? (visibleDockItemCount * panelItemWidth) + (Math.max(0, visibleDockItemCount - 1) * dockSpacing)
        : panelItemWidth
    readonly property int panelContentHeight: panelItemHeight
    readonly property int panelPreferredWidth: hiddenByVirtualDesktop
        ? 0
        : Math.ceil(
            panelFillLengthEnabled && horizontalPanel
                ? Math.max(panelContentWidth + (dockBackgroundHorizontalPadding * 2), (Plasmoid.containment && Plasmoid.containment.width) ? Plasmoid.containment.width : panelContentWidth)
                : ((verticalPanel ? Math.max(panelContentWidth, panelHoverCrossAxisExtent) : panelContentWidth) + (dockBackgroundHorizontalPadding * 2))
        )
    readonly property int panelPreferredHeight: hiddenByVirtualDesktop
        ? 0
        : Math.ceil(
            panelFillLengthEnabled && verticalPanel
                ? Math.max(panelContentHeight + (dockBackgroundVerticalPadding * 2), (Plasmoid.containment && Plasmoid.containment.height) ? Plasmoid.containment.height : panelContentHeight)
                : ((verticalPanel ? panelContentHeight : Math.max(panelContentHeight, panelHoverCrossAxisExtent)) + (dockBackgroundVerticalPadding * 2))
        )

    implicitWidth: inPanel ? panelPreferredWidth : 0
    implicitHeight: inPanel ? panelPreferredHeight : 0
    switchWidth: inPanel ? panelPreferredWidth : Math.ceil(panelItemWidth)
    switchHeight: inPanel ? panelPreferredHeight : Math.ceil(panelItemHeight)

    Layout.minimumWidth: inPanel ? panelPreferredWidth : -1
    Layout.minimumHeight: inPanel ? panelPreferredHeight : -1
    Layout.preferredWidth: inPanel ? panelPreferredWidth : -1
    Layout.preferredHeight: inPanel ? panelPreferredHeight : -1

    Plasma5Support.DataSource {
        id: executableDataSource
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, _data) {
            disconnectSource(sourceName)
        }
    }
    Punchi.TrashIntegration {
        id: trashIntegration
        onOperationFailed: function(operation, message) {
            console.warn("Punchi Dock:", operation, message)
        }
        onStateChanged: function(hasItems) {
            root.updateTrashState(hasItems)
        }
    }

    Connections {
        target: Plasmoid.configuration
        function onDockItemsJsonChanged() {
            var raw = Plasmoid.configuration.dockItemsJson || ""
            if (raw.trim().length > 0) {
                root.dockItems = Logic.loadItems(raw)
                // Sincronizar el archivo externo para scripts externos
                var writeCmd = "configDir=\"${XDG_CONFIG_HOME:-$HOME/.config}/punchi-dock-remastered\" && mkdir -p \"$configDir\" && printf %s " + Logic.shellQuote(raw) + " > \"$configDir/dock_items.json\""
                executableDataSource.connectSource(writeCmd)
            } else {
                root.dockItems = []
                var clearCmd = "configDir=\"${XDG_CONFIG_HOME:-$HOME/.config}/punchi-dock-remastered\" && mkdir -p \"$configDir\" && printf %s '[]' > \"$configDir/dock_items.json\""
                executableDataSource.connectSource(clearCmd)
            }
            trashIntegration.refresh()
            root.refreshVisibleTaskRows()
            root.bumpTaskVisualRevision()
        }

        function onShowActiveTasksChanged() {
            root.refreshVisibleTaskRows()
            root.bumpTaskVisualRevision()
        }

        function onShowTasksCurrentDesktopOnlyChanged() {
            root.refreshVisibleTaskRows()
            root.bumpTaskVisualRevision()
        }
    }

    Connections {
        target: tasksModel

        function onCountChanged() {
            root.scheduleTaskRefresh(true)
        }

        function onDataChanged() {
            root.scheduleTaskRefresh(false)
        }

        function onRowsInserted() {
            root.scheduleTaskRefresh(true)
        }

        function onRowsRemoved() {
            root.scheduleTaskRefresh(true)
        }

        function onModelReset() {
            root.scheduleTaskRefresh(true)
        }
    }

    Component.onCompleted: {
        var raw = Plasmoid.configuration.dockItemsJson || ""
        if (raw.trim().length > 0) {
            root.dockItems = Logic.loadItems(raw)
        } else {
            root.dockItems = Logic.loadItems("")
        }
        trashIntegration.refresh()
        refreshVisibleTaskRows()
        bumpTaskVisualRevision()
    }

    onDockItemsChanged: {
        refreshVisibleTaskRows()
        bumpTaskVisualRevision()
    }

    // Función puente para ejecutar comandos con doble escape seguro
    function runCommand(command) {
        var detachedCmd = Logic.detachedCommand(command)
        if (detachedCmd.length === 0) return
        
        console.log("Dock ejecutando nativamente:", detachedCmd)
        executableDataSource.connectSource(detachedCmd)
    }

    function launchDockItem(item) {
        if (item && item.storageId) {
            systemDiscovery.launchApplication(item.storageId)
        } else if (item && item.type === "app" && item.command && systemDiscovery.launchApplicationByCommand(item.command)) {
            return
        } else if (item && item.url) {
            systemDiscovery.openUrl(item.url)
        } else {
            Logic.launchItem(item, root.runCommand)
        }
    }

    function normalizeApplicationId(value) {
        var text = String(value || "").trim()
        if (text.endsWith(".desktop")) {
            text = text.slice(0, -8)
        }
        return text
    }

    function dockItemApplicationId(item) {
        if (!item || item.type !== "app") {
            return ""
        }

        var persistedStorageId = normalizeApplicationId(item.storageId || "")
        if (persistedStorageId.length > 0) {
            return persistedStorageId
        }

        var persistedAppId = normalizeApplicationId(item.appId || "")
        if (persistedAppId.length > 0) {
            return persistedAppId
        }

        return normalizeApplicationId(systemDiscovery.applicationIdForCommand(item.command || ""))
    }

    function taskAppIdForRow(row) {
        var taskIndex = tasksModel.index(row, 0)
        return normalizeApplicationId(tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.AppId))
    }

    function taskIconNameForRow(row) {
        var taskIndex = tasksModel.index(row, 0)
        var taskAppId = taskAppIdForRow(row)
        var iconName = taskAppId.length > 0 ? systemDiscovery.iconForApplication(taskAppId) : ""
        if (iconName.length > 0) {
            return iconName
        }

        var launcherUrl = String(tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.LauncherUrlWithoutIcon) || "")
        if (launcherUrl.indexOf("applications:") === 0) {
            iconName = systemDiscovery.iconForApplication(launcherUrl.slice("applications:".length))
            if (iconName.length > 0) {
                return iconName
            }
        }

        return "application-x-executable"
    }

    function taskWindowUuidForRow(row) {
        var taskIndex = tasksModel.index(row, 0)
        if (!taskIndex.valid) {
            return ""
        }

        var winIds = tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.WinIdList) || []
        return winIds.length > 0 ? String(winIds[0]) : ""
    }

    function isTaskRowVisible(row) {
        if (!Plasmoid.configuration.showActiveTasks) {
            return false
        }

        var taskIndex = tasksModel.index(row, 0)
        if (!taskIndex.valid) {
            return false
        }
        if (!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsWindow)) {
            return false
        }
        if (tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.SkipTaskbar)) {
            return false
        }

        var taskAppId = taskAppIdForRow(row)
        if (taskAppId.length === 0) {
            return true
        }

        for (var index = 0; index < root.dockItems.length; index++) {
            if (dockItemApplicationId(root.dockItems[index]) === taskAppId) {
                return false
            }
        }

        return true
    }

    function refreshVisibleTaskRows() {
        var rows = []
        if (Plasmoid.configuration.showActiveTasks) {
            for (var row = 0; row < tasksModel.count; row++) {
                if (isTaskRowVisible(row)) {
                    rows.push(row)
                }
            }
        }

        if (rows.length !== visibleTaskRows.length) {
            visibleTaskRows = rows
            return
        }

        for (var index = 0; index < rows.length; index++) {
            if (rows[index] !== visibleTaskRows[index]) {
                visibleTaskRows = rows
                return
            }
        }
    }

    function bumpTaskVisualRevision() {
        taskVisualRevision += 1
    }

    function scheduleTaskRefresh(needsStructureRefresh) {
        pendingTaskStructureRefresh = pendingTaskStructureRefresh || !!needsStructureRefresh
        refreshTasksTimer.restart()
    }

    function flushTaskRefresh() {
        if (pendingTaskStructureRefresh) {
            refreshVisibleTaskRows()
            pendingTaskStructureRefresh = false
        }
        bumpTaskVisualRevision()
    }

    function taskStateForDockItem(item) {
        var appId = dockItemApplicationId(item)
        var result = {
            "count": 0,
            "isActive": false,
            "demandsAttention": false,
            "firstRow": -1,
            "rows": []
        }
        if (appId.length === 0) {
            return result
        }

        for (var row = 0; row < tasksModel.count; row++) {
            var taskIndex = tasksModel.index(row, 0)
            if (!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsWindow)) {
                continue
            }
            if (tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.SkipTaskbar)) {
                continue
            }
            if (taskAppIdForRow(row) !== appId) {
                continue
            }
            if (result.firstRow === -1) {
                result.firstRow = row
            }
            result.count += 1
            result.rows.push(row)
            result.isActive = result.isActive || !!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsActive)
            result.demandsAttention = result.demandsAttention || !!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsDemandingAttention)
        }

        return result
    }

    function taskWindowsForRows(rows) {
        var windows = []
        for (var index = 0; index < rows.length; index++) {
            var row = rows[index]
            var taskIndex = tasksModel.index(row, 0)
            var windowUuid = root.taskWindowUuidForRow(row)
            windows.push({
                "row": row,
                "title": String(tasksModel.data(taskIndex, Qt.DisplayRole) || ""),
                "name": String(tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.AppName) || ""),
                "subtitle": String(tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.GenericName) || ""),
                "active": !!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsActive),
                "closable": !!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsClosable),
                "icon": root.taskIconNameForRow(row),
                "windowUuid": windowUuid
            })
        }
        return windows
    }

    function activateTaskRow(row) {
        var taskIndex = tasksModel.index(row, 0)
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

    function closeTaskRow(row) {
        var taskIndex = tasksModel.index(row, 0)
        if (!taskIndex.valid || !tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsClosable)) {
            return
        }
        tasksModel.requestClose(taskIndex)
    }

    function handleDockItemActivation(item, visualParent) {
        if (!item || item.type !== "app") {
            root.launchDockItem(item)
            return
        }

        var taskState = taskStateForDockItem(item)
        if (taskState.count > 1) {
            mainContainer.openTaskWindowsPopup(item.name || "", taskState.rows, visualParent)
            return
        }
        if (taskState.firstRow >= 0) {
            activateTaskRow(taskState.firstRow)
            return
        }

        root.launchDockItem(item)
    }

    function scheduleHoverTaskWindowsPopup(appName, rows, visualParent) {
        hoverTaskPopupAppName = appName || ""
        hoverTaskPopupRows = rows || []
        hoverTaskPopupVisualParent = visualParent || null
        hoverTaskPopupCloseTimer.stop()
        if (hoverTaskPopupRows.length > 0 && hoverTaskPopupVisualParent) {
            hoverTaskPopupOpenTimer.restart()
        }
    }

    function cancelHoverTaskWindowsPopup(visualParent) {
        if (visualParent && hoverTaskPopupVisualParent && visualParent !== hoverTaskPopupVisualParent) {
            return
        }
        hoverTaskPopupOpenTimer.stop()
        hoverTaskPopupCloseTimer.restart()
    }

    function taskWindowsPopupShouldStayOpen() {
        return !!(taskWindowsDialog.visible
            && hoverTaskPopupVisualParent
            && (hoverTaskPopupVisualParent.containsMouse
                || (taskWindowsPopupContent && taskWindowsPopupContent.containsMouse)))
    }

    function updateTrashState(hasItems) {
        root.trashHasItems = hasItems
    }

    function syncDockItemsConfiguration() {
        var raw = JSON.stringify(root.dockItems)
        Plasmoid.configuration.dockItemsJson = raw
        var writeCmd = "configDir=\"${XDG_CONFIG_HOME:-$HOME/.config}/punchi-dock-remastered\" && mkdir -p \"$configDir\" && printf %s " + Logic.shellQuote(raw) + " > \"$configDir/dock_items.json\""
        executableDataSource.connectSource(writeCmd)
    }

    function updateNoteItem(noteItem, noteText, popupWidth, popupHeight) {
        if (!noteItem) {
            return
        }

        var updatedItems = []
        var changed = false
        for (var i = 0; i < root.dockItems.length; i++) {
            var item = root.dockItems[i]
            if (item === noteItem) {
                item = Object.assign({}, item, {
                    "note": noteText,
                    "popupWidth": popupWidth,
                    "popupHeight": popupHeight
                })
                changed = true
                root.activeNoteData = item
            }
            updatedItems.push(item)
        }

        if (changed) {
            root.dockItems = updatedItems
            syncDockItemsConfiguration()
        }
    }

    fullRepresentation: Item {
        id: mainContainer
        visible: !root.hiddenByVirtualDesktop
        enabled: visible
        implicitWidth: visible ? dockWrapper.width : 0
        implicitHeight: visible ? dockWrapper.height : 0
        width: implicitWidth
        height: implicitHeight
        Layout.minimumWidth: root.panelPreferredWidth
        Layout.minimumHeight: root.panelPreferredHeight
        Layout.preferredWidth: root.panelPreferredWidth
        Layout.preferredHeight: root.panelPreferredHeight

        function closeAllPopups(exceptDialog) {
            if (folderPopupDialog !== exceptDialog) {
                folderPopupDialog.visible = false
            }
            if (calendarPopupDialog !== exceptDialog) {
                calendarPopupDialog.visible = false
            }
            if (trashMenuDialog !== exceptDialog) {
                trashMenuDialog.visible = false
            }
            if (notePopupDialog !== exceptDialog) {
                notePopupDialog.visible = false
            }
            if (taskWindowsDialog !== exceptDialog) {
                taskWindowsDialog.visible = false
            }
            if (trashConfirmDialog !== exceptDialog) {
                trashConfirmDialog.visible = false
            }
            if (exceptDialog !== taskWindowsDialog) {
                hoverTaskPopupOpenTimer.stop()
                hoverTaskPopupCloseTimer.stop()
                root.hoverTaskPopupVisualParent = null
                root.hoverTaskPopupRows = []
                root.hoverTaskPopupAppName = ""
            }
        }

        function openTrashMenu(visualParent) {
            mainContainer.closeAllPopups(trashMenuDialog)
            trashMenuDialog.visualParent = visualParent
            trashConfirmDialog.visualParent = visualParent
            trashMenuDialog.visible = !trashMenuDialog.visible
        }

        function openFolderPopup(itemData, itemIndex, visualParent) {
            mainContainer.closeAllPopups(folderPopupDialog)
            root.activeFolderData = itemData
            root.activeFolderIndex = itemIndex
            folderPopupDialog.visualParent = visualParent
            folderPopupDialog.visible = !folderPopupDialog.visible
        }

        function openCalendarPopup(visualParent) {
            mainContainer.closeAllPopups(calendarPopupDialog)
            calendarPopupDialog.visualParent = visualParent
            calendarPopupDialog.visible = !calendarPopupDialog.visible
        }

        function openNotePopup(itemData, visualParent) {
            mainContainer.closeAllPopups(null)
            root.activeNoteData = itemData
            notePopupDialog.visualParent = visualParent
            notePopupDialog.visible = true
            Qt.callLater(function() {
                notePopupContent.focusEditor()
            })
        }

        function openTaskWindowsPopup(appName, rows, visualParent) {
            hoverTaskPopupCloseTimer.stop()
            mainContainer.closeAllPopups(taskWindowsDialog)
            root.activeTaskPopupData = {
                "name": appName || "",
                "windows": root.taskWindowsForRows(rows || [])
            }
            taskWindowsDialog.visualParent = visualParent
            taskWindowsDialog.visible = true
        }

        Item {
            id: dockWrapper
            anchors.centerIn: parent
            implicitWidth: root.inPanel ? (dockLayout.implicitWidth + (root.dockBackgroundHorizontalPadding * 2)) : (dockLayout.implicitWidth + root.floatingExtraWidth)
            implicitHeight: root.inPanel ? (dockLayout.implicitHeight + (root.dockBackgroundVerticalPadding * 2)) : (dockLayout.implicitHeight + root.floatingExtraHeight)
            width: root.inPanel ? root.panelPreferredWidth : dockLayout.implicitWidth + root.floatingExtraWidth
            height: root.inPanel ? root.panelPreferredHeight : dockLayout.implicitHeight + root.floatingExtraHeight

            DockBackground {
                anchors.fill: parent
                radius: 12
                opacity: 0.85
                visible: !root.inPanel
            }

            RowLayout {
                id: dockLayout
                spacing: root.dockSpacing
                x: {
                    if (!root.inPanel) {
                        return Math.round((parent.width - width) / 2)
                    }
                    if (root.leftPanel) {
                        return root.dockBackgroundHorizontalPadding
                    }
                    if (root.rightPanel) {
                        return parent.width - width - root.dockBackgroundHorizontalPadding
                    }
                    return Math.round((parent.width - width) / 2)
                }
                y: {
                    if (!root.inPanel) {
                        return Math.round((parent.height - height) / 2)
                    }
                    if (root.topPanel) {
                        return root.dockBackgroundVerticalPadding
                    }
                    if (root.bottomPanel) {
                        return parent.height - height - root.dockBackgroundVerticalPadding
                    }
                    return Math.round((parent.height - height) / 2)
                }
                
                property int hoveredIndex: -1
                property real mouseOffset: 0.0

                // Variables para transición suave al entrar/salir del dock
                property int lastHoveredIndex: -1
                property real lastMouseOffset: 0.0
                property real hoverZoomProgress: hoveredIndex >= 0 ? 1.0 : 0.0

                onHoveredIndexChanged: {
                    if (hoveredIndex >= 0) {
                        lastHoveredIndex = hoveredIndex
                    }
                }
                onMouseOffsetChanged: {
                    if (hoveredIndex >= 0) {
                        lastMouseOffset = mouseOffset
                    }
                }

                Behavior on hoverZoomProgress {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                signal trashUrlsDropped(var urls)
                onTrashUrlsDropped: function(urls) {
                    var cmd = Logic.trashUrlsScript(urls)
                    root.runCommand(cmd)
                }

                Repeater {
                    model: root.dockItems
                    delegate: DockItem {
                        id: dockItemDelegate
                        itemIndex: index
                        hoveredIndex: dockLayout.hoveredIndex
                        inPanel: root.inPanel
                        panelLocation: root.panelLocation
                        iconSize: root.effectiveIconSize
                        hoverScaleSetting: root.panelHoverScale
                        hoverAnimationMode: Plasmoid.configuration.hoverAnimation || "wave"
                        clickEffect: root.dockClickEffect
                        showPersistentLabel: root.dockShowLabels
                        labelFontSize: root.dockLabelFontSize
                        indicatorType: root.dockIndicatorType
                        indicatorPosition: root.dockIndicatorPosition
                        indicatorThickness: root.dockIndicatorThickness
                        indicatorOpacity: root.dockIndicatorOpacity
                        
                        // Variables de animación de la ola
                        hoverZoomProgress: dockLayout.hoverZoomProgress
                        lastHoveredIndex: dockLayout.lastHoveredIndex
                        lastMouseOffset: dockLayout.lastMouseOffset
                        readonly property int taskRevision: root.taskVisualRevision
                        readonly property var taskState: {
                            taskRevision
                            return root.taskStateForDockItem(modelData)
                        }
                        
                        itemType: modelData.type || "app"
                        iconName: modelData.type === "trash" && modelData.showState !== false
                            ? (root.trashHasItems ? (modelData.fullIcon || "user-trash-full") : (modelData.icon || "user-trash"))
                            : (modelData.icon || "")
                        itemName: modelData.name || ""
                        itemCommand: modelData.command || ""
                        taskIndicatorCount: taskState.count
                        taskIsActive: taskState.isActive
                        taskDemandsAttention: taskState.demandsAttention
                        taskPreviewStyle: root.windowPreviewStyle
                        taskPreviewWindowUuid: taskState.firstRow >= 0
                            ? root.taskWindowUuidForRow(taskState.firstRow)
                            : ""
                        suppressTooltip: taskWindowsDialog.visible && root.hoverTaskPopupVisualParent === dockItemDelegate
                        
                        onItemClicked: function(cmd) {
                            if (modelData.type === "folder") {
                                mainContainer.openFolderPopup(modelData, index, dockItemDelegate)
                            } else if (modelData.type === "calendar") {
                                mainContainer.openCalendarPopup(dockItemDelegate)
                            } else if (modelData.type === "note") {
                                mainContainer.openNotePopup(modelData, dockItemDelegate)
                            } else {
                                mainContainer.closeAllPopups(null)
                                root.handleDockItemActivation(modelData, dockItemDelegate)
                            }
                        }
                        onContextMenuRequested: function(visualParent) {
                            if (modelData.type === "trash") {
                                mainContainer.openTrashMenu(visualParent)
                            }
                        }
                        onHoverEntered: function(visualParent) {
                            if (taskState.count > 0) {
                                root.scheduleHoverTaskWindowsPopup(modelData.name || "", taskState.rows, visualParent)
                            }
                        }
                        onHoverExited: function(visualParent) {
                            root.cancelHoverTaskWindowsPopup(visualParent)
                        }
                    }
                }

                Repeater {
                    model: root.visibleTaskRows
                    delegate: DockItem {
                        id: taskDockItemDelegate
                        required property int modelData

                        readonly property int taskRow: modelData
                        readonly property int taskRevision: root.taskVisualRevision
                        readonly property var taskIndex: tasksModel.index(taskRow, 0)
                        readonly property int taskVisualIndex: {
                            var position = root.visibleTaskRows.indexOf(taskRow)
                            return position >= 0 ? position : 0
                        }

                        itemIndex: root.dockItems.length + taskVisualIndex
                        hoveredIndex: dockLayout.hoveredIndex
                        inPanel: root.inPanel
                        panelLocation: root.panelLocation
                        iconSize: root.effectiveIconSize
                        hoverScaleSetting: root.panelHoverScale
                        hoverAnimationMode: Plasmoid.configuration.hoverAnimation || "wave"
                        clickEffect: root.dockClickEffect
                        showPersistentLabel: root.dockShowLabels
                        labelFontSize: root.dockLabelFontSize
                        indicatorType: root.dockIndicatorType
                        indicatorPosition: root.dockIndicatorPosition
                        indicatorThickness: root.dockIndicatorThickness
                        indicatorOpacity: root.dockIndicatorOpacity
                        hoverZoomProgress: dockLayout.hoverZoomProgress
                        lastHoveredIndex: dockLayout.lastHoveredIndex
                        lastMouseOffset: dockLayout.lastMouseOffset

                        itemType: "app"
                        iconName: {
                            taskRevision
                            return root.taskIconNameForRow(taskRow)
                        }
                        itemName: {
                            taskRevision
                            return tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.AppName)
                                || tasksModel.data(taskIndex, Qt.DisplayRole)
                                || ""
                        }
                        taskIndicatorCount: 1
                        taskIsActive: {
                            taskRevision
                            return !!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsActive)
                        }
                        taskDemandsAttention: {
                            taskRevision
                            return !!tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsDemandingAttention)
                        }
                        taskPreviewStyle: root.windowPreviewStyle
                        taskPreviewWindowUuid: {
                            taskRevision
                            return root.taskWindowUuidForRow(taskRow)
                        }
                        suppressTooltip: taskWindowsDialog.visible && root.hoverTaskPopupVisualParent === taskDockItemDelegate

                        onItemClicked: function() {
                            mainContainer.closeAllPopups(null)
                            root.activateTaskRow(taskRow)
                        }
                        onHoverEntered: function(visualParent) {
                            root.scheduleHoverTaskWindowsPopup(itemName, [taskRow], visualParent)
                        }
                        onHoverExited: function(visualParent) {
                            root.cancelHoverTaskWindowsPopup(visualParent)
                        }
                    }
                }
            }
        }

        // Diálogo emergente para Carpetas (FolderPopup)
        PlasmaCore.Dialog {
            id: folderPopupDialog
            location: root.popupDialogLocation
            visible: false
            hideOnWindowDeactivate: true
            // Si es circular/abanico desactivamos el fondo nativo para el vuelo de iconos.
            // Si es lista/grid/detalle, usamos el fondo nativo estándar del tema de KDE (tipo Kickoff)
            backgroundHints: (root.activeFolderData.layout === "circular" || root.activeFolderData.layout === "fan") 
                ? PlasmaCore.Types.NoBackground 
                : PlasmaCore.Types.StandardBackground

            mainItem: FolderPopup {
                id: folderPopupContent
                folderItem: root.activeFolderData
                layoutMode: root.activeFolderData.layout || "grid"
                virtualEdge: Plasmoid.location
                isOpen: folderPopupDialog.visible

                onAppLaunched: function(app) {
                    folderPopupDialog.visible = false
                    root.launchDockItem(app)
                }

                onCloseRequested: {
                    folderPopupDialog.visible = false
                }
            }
        }

        // Diálogo emergente para el Calendario (CalendarPopup)
        PlasmaCore.Dialog {
            id: calendarPopupDialog
            location: root.popupDialogLocation
            visible: false
            hideOnWindowDeactivate: true
            // El calendario siempre utiliza el fondo nativo del tema de KDE (Kickoff)
            backgroundHints: PlasmaCore.Types.StandardBackground

            mainItem: CalendarPopup {
                // El popup se reinicia a la fecha actual al mostrarse
                Component.onCompleted: {
                    displayedDate = new Date()
                    updateGrid()
                }
                onCloseRequested: {
                    calendarPopupDialog.visible = false
                }
            }
        }

        // Diálogo emergente para el Menú Contextual de la Papelera (TrashMenuPopup)
        PlasmaCore.Dialog {
            id: trashMenuDialog
            location: root.popupDialogLocation
            visible: false
            hideOnWindowDeactivate: true
            backgroundHints: PlasmaCore.Types.StandardBackground

            mainItem: TrashMenuPopup {
                id: trashMenuContent
                onOpenTrashClicked: {
                    console.log("main.qml: onOpenTrashClicked received")
                    trashMenuDialog.visible = false
                    trashIntegration.openTrash()
                }
                onEmptyTrashClicked: {
                    console.log("main.qml: onEmptyTrashClicked received")
                    trashMenuDialog.visible = false
                    trashConfirmDialog.visible = true
                }
                onCloseRequested: {
                    console.log("main.qml: onCloseRequested received")
                    trashMenuDialog.visible = false
                }
            }
        }

        PlasmaCore.Dialog {
            id: notePopupDialog
            location: root.popupDialogLocation
            visible: false
            hideOnWindowDeactivate: false
            backgroundHints: PlasmaCore.Types.StandardBackground
            onVisibleChanged: {
                if (!visible && notePopupContent.currentText !== notePopupContent.initialText) {
                    root.updateNoteItem(root.activeNoteData, notePopupContent.currentText, notePopupContent.activeWidth, notePopupContent.activeHeight)
                }
            }

            mainItem: NotePopup {
                id: notePopupContent
                noteItem: root.activeNoteData
                onCloseRequested: {
                    notePopupDialog.visible = false
                }
                onClearRequested: function(noteText, popupWidth, popupHeight) {
                    notePopupContent.initialText = noteText
                    root.updateNoteItem(root.activeNoteData, noteText, popupWidth, popupHeight)
                }
            }
        }

        PlasmaCore.Dialog {
            id: taskWindowsDialog
            location: root.popupDialogLocation
            visible: false
            hideOnWindowDeactivate: false
            backgroundHints: PlasmaCore.Types.StandardBackground

            mainItem: TaskWindowsPopup {
                id: taskWindowsPopupContent
                appName: root.activeTaskPopupData.name || ""
                windows: root.activeTaskPopupData.windows || []
                previewStyle: root.windowPreviewStyle

                onActivateRequested: function(taskRow) {
                    taskWindowsDialog.visible = false
                    root.activateTaskRow(taskRow)
                }
                onCloseWindowRequested: function(taskRow) {
                    root.closeTaskRow(taskRow)
                }
                onCloseRequested: {
                    taskWindowsDialog.visible = false
                }
                onContainsMouseChanged: {
                    if (!containsMouse && !root.taskWindowsPopupShouldStayOpen()) {
                        hoverTaskPopupCloseTimer.restart()
                    } else if (containsMouse) {
                        hoverTaskPopupCloseTimer.stop()
                    }
                }
            }
        }

        PlasmaCore.Dialog {
            id: trashConfirmDialog
            location: root.popupDialogLocation
            visible: false
            hideOnWindowDeactivate: true
            backgroundHints: PlasmaCore.Types.StandardBackground

            mainItem: ConfirmTrashEmptyPopup {
                onConfirmRequested: {
                    trashConfirmDialog.visible = false
                    trashIntegration.emptyTrash()
                }
                onCancelRequested: {
                    trashConfirmDialog.visible = false
                }
            }
        }
    }

    // Datos del popup de carpeta activo
    property var activeFolderData: ({})
    property int activeFolderIndex: -1
    property var activeNoteData: ({})
}
