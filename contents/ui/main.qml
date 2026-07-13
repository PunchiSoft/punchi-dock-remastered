import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
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
    readonly property var visibleTaskRows: taskController.visibleTaskRows
    readonly property var overflowTaskRows: taskController.overflowTaskRows
    readonly property int taskVisualRevision: taskController.visualRevision
    property var activeTaskPopupData: ({ "name": "", "windows": [] })
    property var activeAppContextMenuData: ({ "name": "", "actions": [], "maxVisibleRows": 6 })
    property string pendingTaskPopupAppName: ""
    property var pendingTaskPopupRows: []
    property var taskPopupVisualParent: null
    property bool taskPopupHovered: false

    // Visibilidad por Escritorios Virtuales
    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }
    Punchi.SystemDiscovery {
        id: systemDiscovery
        onOperationFailed: function(operation, message) {
            console.warn("Punchi Dock:", operation, message)
        }
    }
    Punchi.DockRuntimeService {
        id: runtimeService
        onOperationFailed: function(operation, message) {
            console.warn("Punchi Dock:", operation, message)
        }
    }
    TaskModelController {
        id: taskController
        dockItems: root.dockItems
        showActiveTasks: Plasmoid.configuration.showActiveTasks
        currentDesktopOnly: Plasmoid.configuration.showTasksCurrentDesktopOnly
        windowGroupingMode: String(Plasmoid.configuration.windowGroupingMode || "application")
        maxDynamicGroups: Math.max(1, Math.min(20,
            Number(Plasmoid.configuration.maxDynamicTaskGroups || 8)))
        systemDiscovery: systemDiscovery
    }
    readonly property string currentVirtualDesktopId: String(virtualDesktopInfo.currentDesktop || "")
    readonly property bool singleVirtualDesktopMode: Plasmoid.configuration.virtualDesktopMode === "single"
        && Plasmoid.configuration.targetVirtualDesktop !== ""
    readonly property bool hiddenByVirtualDesktop: singleVirtualDesktopMode
        && currentVirtualDesktopId !== Plasmoid.configuration.targetVirtualDesktop
    readonly property int visibleDockItemCount: (dockItems ? dockItems.length : 0)
        + visibleTaskRows.length + (overflowTaskRows.length > 0 ? 1 : 0)
    readonly property int dockSpacing: 8
    readonly property int dockBackgroundHorizontalPadding: 18
    readonly property int dockBackgroundVerticalPadding: 12
    readonly property int floatingExtraWidth: 48
    readonly property int floatingExtraHeight: 32
    readonly property string windowPreviewStyle: String(Plasmoid.configuration.windowPreviewStyle || "thumbnail")
    readonly property real windowPreviewScale: Math.max(0.5, Math.min(2.0,
        Number(Plasmoid.configuration.windowPreviewScale || 1.0)))
    readonly property bool showWindowThumbnails: windowPreviewStyle === "thumbnail"
    readonly property int maxPopupRows: Math.max(1, Math.min(8,
        Number(Plasmoid.configuration.maxPopupRows || 4)))
    readonly property int taskPopupAvailableHeight: Math.max(240,
        Number(root.availableScreenRect.height || 640) - (root.inPanel ? root.panelPreferredHeight : 0) - 24)
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
    readonly property int popupDirection: {
        if (topPanel) {
            return Qt.BottomEdge
        }
        if (bottomPanel) {
            return Qt.TopEdge
        }
        if (leftPanel) {
            return Qt.RightEdge
        }
        if (rightPanel) {
            return Qt.LeftEdge
        }
        return Qt.BottomEdge
    }
    readonly property int popupMargin: root.inPanel ? 2 : 10
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
            } else {
                root.dockItems = []
            }
            runtimeService.persistDockItemsJson(raw)
            trashIntegration.refresh()
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
    }

    function runCommand(command) {
        runtimeService.launchCommand(command)
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

    function handleDockItemActivation(item, visualParent) {
        if (!item || item.type !== "app") {
            root.launchDockItem(item)
            return
        }

        var taskState = taskController.taskStateForDockItem(item)
        if (taskState.count > 1) {
            taskController.activatePreferredTaskRow(taskState.rows)
            return
        }
        if (taskState.firstRow >= 0) {
            taskController.activateTaskRow(taskState.firstRow)
            return
        }

        root.launchDockItem(item)
    }

    function updateTrashState(hasItems) {
        root.trashHasItems = hasItems
    }

    function itemContextActions(item) {
        if (!item || (item.type || "app") !== "app" || item.actionsEnabled === false) {
            return []
        }
        return item.actions instanceof Array
            ? item.actions.filter(function(action) {
                return action && String(action.command || "").trim().length > 0
            })
            : []
    }

    function itemHasContextMenu(item) {
        return itemContextActions(item).length > 0
    }

    function syncDockItemsConfiguration() {
        var raw = JSON.stringify(root.dockItems)
        Plasmoid.configuration.dockItemsJson = raw
        runtimeService.persistDockItemsJson(raw)
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

        Timer {
            id: taskPopupOpenTimer
            interval: 280
            repeat: false
            onTriggered: {
                if (root.taskPopupVisualParent && root.pendingTaskPopupRows.length > 0) {
                    mainContainer.openTaskWindowsPopup(root.pendingTaskPopupAppName,
                        root.pendingTaskPopupRows, root.taskPopupVisualParent)
                }
            }
        }

        Timer {
            id: taskPopupCloseTimer
            interval: 260
            repeat: false
            onTriggered: {
                if (!root.taskPopupHovered && !mainContainer.taskPopupSourceContainsMouse()) {
                    taskWindowsDialog.visible = false
                }
            }
        }

        function scheduleTaskWindowsPopup(appName, rows, visualParent) {
            root.pendingTaskPopupAppName = appName || ""
            root.pendingTaskPopupRows = rows || []
            root.taskPopupVisualParent = visualParent || null
            taskPopupCloseTimer.stop()
            if (root.pendingTaskPopupRows.length > 0 && root.taskPopupVisualParent) {
                taskPopupOpenTimer.restart()
            }
        }

        function cancelPendingTaskWindowsPopup(visualParent) {
            if (visualParent && root.taskPopupVisualParent
                    && visualParent !== root.taskPopupVisualParent) {
                return
            }
            if (!taskWindowsDialog.visible) {
                taskPopupOpenTimer.stop()
                root.pendingTaskPopupAppName = ""
                root.pendingTaskPopupRows = []
                root.taskPopupVisualParent = null
                root.taskPopupHovered = false
                taskPopupCloseTimer.stop()
                return
            }
            if (!root.taskPopupHovered) {
                taskPopupCloseTimer.restart()
            }
        }

        function taskPopupSourceContainsMouse() {
            try {
                return !!(root.taskPopupVisualParent && root.taskPopupVisualParent.containsMouse)
            } catch (error) {
                return false
            }
        }

        function popupAnchor(visualParent) {
            if (!visualParent) {
                return dockWrapper
            }
            if (!root.inPanel && visualParent.popupAnchorItem) {
                return visualParent.popupAnchorItem
            }
            return visualParent
        }

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
            if (appActionsDialog !== exceptDialog) {
                appActionsDialog.visible = false
            }
            if (taskOverflowDialog !== exceptDialog) {
                taskOverflowDialog.visible = false
            }
            if (taskWindowsDialog !== exceptDialog) {
                taskWindowsDialog.visible = false
            }
            if (trashConfirmDialog !== exceptDialog) {
                trashConfirmDialog.visible = false
            }
            if (exceptDialog !== taskWindowsDialog) {
                taskPopupOpenTimer.stop()
                taskPopupCloseTimer.stop()
            }
        }

        function openTrashMenu(visualParent) {
            mainContainer.closeAllPopups(trashMenuDialog)
            trashMenuDialog.visualParent = mainContainer.popupAnchor(visualParent)
            trashConfirmDialog.visualParent = mainContainer.popupAnchor(visualParent)
            trashMenuDialog.visible = !trashMenuDialog.visible
        }

        function openAppContextMenu(itemData, visualParent) {
            var actions = root.itemContextActions(itemData)
            if (actions.length === 0) {
                return
            }

            mainContainer.closeAllPopups(appActionsDialog)
            root.activeAppContextMenuData = {
                "name": itemData && itemData.name ? itemData.name : "",
                "actions": actions,
                "maxVisibleRows": Math.max(1, Math.min(12,
                    Number(itemData && itemData.actionPopupMaxVisibleRows ? itemData.actionPopupMaxVisibleRows : 6)))
            }
            appActionsDialog.visualParent = mainContainer.popupAnchor(visualParent)
            appActionsDialog.visible = true
        }

        function openTrashConfirmation() {
            trashMenuDialog.visible = false
            Qt.callLater(function() {
                trashConfirmDialog.visible = true
            })
        }

        function openFolderPopup(itemData, itemIndex, visualParent) {
            mainContainer.closeAllPopups(folderPopupDialog)
            root.activeFolderData = itemData
            root.activeFolderIndex = itemIndex
            folderPopupDialog.visualParent = mainContainer.popupAnchor(visualParent)
            folderPopupDialog.visible = !folderPopupDialog.visible
        }

        function openCalendarPopup(visualParent) {
            mainContainer.closeAllPopups(calendarPopupDialog)
            calendarPopupDialog.visualParent = mainContainer.popupAnchor(visualParent)
            calendarPopupDialog.visible = !calendarPopupDialog.visible
        }

        function openNotePopup(itemData, visualParent) {
            mainContainer.closeAllPopups(null)
            root.activeNoteData = itemData
            notePopupDialog.visualParent = mainContainer.popupAnchor(visualParent)
            notePopupDialog.visible = true
            Qt.callLater(function() {
                notePopupContent.focusEditor()
            })
        }

        function openTaskWindowsPopup(appName, rows, visualParent) {
            taskPopupOpenTimer.stop()
            mainContainer.closeAllPopups(taskWindowsDialog)
            root.activeTaskPopupData = {
                "name": appName || "",
                "windows": taskController.taskWindowsForRows(rows || [])
            }
            taskWindowsDialog.visualParent = mainContainer.popupAnchor(visualParent)
            root.taskPopupVisualParent = visualParent
            taskWindowsDialog.visible = true
        }

        function openTaskOverflowPopup(visualParent) {
            mainContainer.closeAllPopups(taskOverflowDialog)
            taskOverflowDialog.visualParent = mainContainer.popupAnchor(visualParent)
            taskOverflowDialog.visible = true
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
                        popupDirection: root.popupDirection
                        
                        // Variables de animación de la ola
                        hoverZoomProgress: dockLayout.hoverZoomProgress
                        lastHoveredIndex: dockLayout.lastHoveredIndex
                        lastMouseOffset: dockLayout.lastMouseOffset
                        readonly property int taskRevision: root.taskVisualRevision
                        readonly property var taskState: {
                            taskRevision
                            return taskController.taskStateForDockItem(modelData)
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
                        taskPreviewScale: root.windowPreviewScale
                        taskPreviewWindowUuid: taskState.firstRow >= 0
                            ? taskController.taskWindowUuidForRow(taskState.firstRow)
                            : ""
                        preferTaskPopupOnHover: taskState.count > 1
                        suppressTooltip: taskWindowsDialog.visible && root.taskPopupVisualParent === dockItemDelegate
                        supportsContextMenu: root.itemHasContextMenu(modelData)
                        
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
                            } else if (root.itemHasContextMenu(modelData)) {
                                mainContainer.openAppContextMenu(modelData, visualParent)
                            }
                        }
                        onHoverEntered: function(visualParent) {
                            if (taskState.count > 0) {
                                mainContainer.scheduleTaskWindowsPopup(modelData.name || "", taskState.rows, visualParent)
                            }
                        }
                        onHoverExited: function(visualParent) {
                            mainContainer.cancelPendingTaskWindowsPopup(visualParent)
                        }
                    }
                }

                Repeater {
                    model: root.visibleTaskRows
                    delegate: DockItem {
                        id: taskDockItemDelegate
                        required property var modelData
                        required property int index
                        readonly property int taskRevision: root.taskVisualRevision
                        readonly property var taskData: {
                            taskRevision
                            return taskController.taskDataForEntry(modelData)
                        }

                        itemIndex: root.dockItems.length + index
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
                        popupDirection: root.popupDirection
                        hoverZoomProgress: dockLayout.hoverZoomProgress
                        lastHoveredIndex: dockLayout.lastHoveredIndex
                        lastMouseOffset: dockLayout.lastMouseOffset

                        itemType: "app"
                        iconName: taskData.icon
                        itemName: taskData.name
                        taskIndicatorCount: taskData.count
                        taskIsActive: taskData.active
                        taskDemandsAttention: taskData.demandsAttention
                        taskPreviewStyle: root.windowPreviewStyle
                        taskPreviewScale: root.windowPreviewScale
                        taskPreviewWindowUuid: taskData.windowUuid
                        preferTaskPopupOnHover: taskData.count > 1
                        suppressTooltip: taskWindowsDialog.visible && root.taskPopupVisualParent === taskDockItemDelegate

                        onItemClicked: function() {
                            mainContainer.closeAllPopups(null)
                            if (taskData.count > 1) {
                                taskController.activatePreferredTaskRow(taskData.rows)
                            } else if (taskData.firstRow >= 0) {
                                taskController.activateTaskRow(taskData.firstRow)
                            }
                        }
                        onHoverEntered: function(visualParent) {
                            if (taskData.count > 0) {
                                mainContainer.scheduleTaskWindowsPopup(itemName, taskData.rows, visualParent)
                            }
                        }
                        onHoverExited: function(visualParent) {
                            mainContainer.cancelPendingTaskWindowsPopup(visualParent)
                        }
                    }
                }

                DockItem {
                    id: taskOverflowDockItem
                    visible: root.overflowTaskRows.length > 0
                    itemIndex: root.dockItems.length + root.visibleTaskRows.length
                    hoveredIndex: dockLayout.hoveredIndex
                    inPanel: root.inPanel
                    panelLocation: root.panelLocation
                    iconSize: root.effectiveIconSize
                    hoverScaleSetting: root.panelHoverScale
                    hoverAnimationMode: Plasmoid.configuration.hoverAnimation || "wave"
                    clickEffect: root.dockClickEffect
                    popupDirection: root.popupDirection
                    hoverZoomProgress: dockLayout.hoverZoomProgress
                    lastHoveredIndex: dockLayout.lastHoveredIndex
                    lastMouseOffset: dockLayout.lastMouseOffset
                    itemType: "overflow"
                    iconName: "view-more-symbolic"
                    itemName: i18np("%1 more window group", "%1 more window groups",
                        root.overflowTaskRows.length)
                    taskIndicatorCount: root.overflowTaskRows.length

                    onItemClicked: mainContainer.openTaskOverflowPopup(taskOverflowDockItem)
                }
            }
        }

        // Prueba controlada de AppletPopup: Plasma ancla el popup fuera del panel.
        PlasmaCore.AppletPopup {
            id: folderPopupDialog
            popupDirection: root.popupDirection
            margin: root.popupMargin
            floating: !root.inPanel
            removeBorderStrategy: root.inPanel
                ? PlasmaCore.AppletPopup.AtScreenEdges | PlasmaCore.AppletPopup.AtPanelEdges
                : PlasmaCore.AppletPopup.AtScreenEdges
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
        PlasmaCore.AppletPopup {
            id: calendarPopupDialog
            popupDirection: root.popupDirection
            margin: root.popupMargin
            floating: !root.inPanel
            removeBorderStrategy: root.inPanel
                ? PlasmaCore.AppletPopup.AtScreenEdges | PlasmaCore.AppletPopup.AtPanelEdges
                : PlasmaCore.AppletPopup.AtScreenEdges
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
        PlasmaCore.AppletPopup {
            id: trashMenuDialog
            popupDirection: root.popupDirection
            margin: root.popupMargin
            floating: !root.inPanel
            removeBorderStrategy: root.inPanel
                ? PlasmaCore.AppletPopup.AtScreenEdges | PlasmaCore.AppletPopup.AtPanelEdges
                : PlasmaCore.AppletPopup.AtScreenEdges
            visible: false
            hideOnWindowDeactivate: true
            backgroundHints: PlasmaCore.Types.StandardBackground

            mainItem: TrashMenuPopup {
                id: trashMenuContent
                onOpenTrashClicked: {
                    trashMenuDialog.visible = false
                    trashIntegration.openTrash()
                }
                onEmptyTrashClicked: {
                    mainContainer.openTrashConfirmation()
                }
                onCloseRequested: {
                    trashMenuDialog.visible = false
                }
            }
        }

        PlasmaCore.AppletPopup {
            id: appActionsDialog
            popupDirection: root.popupDirection
            margin: root.popupMargin
            floating: !root.inPanel
            removeBorderStrategy: root.inPanel
                ? PlasmaCore.AppletPopup.AtScreenEdges | PlasmaCore.AppletPopup.AtPanelEdges
                : PlasmaCore.AppletPopup.AtScreenEdges
            visible: false
            hideOnWindowDeactivate: true
            backgroundHints: PlasmaCore.Types.StandardBackground

            mainItem: AppActionsPopup {
                id: appActionsContent
                itemName: root.activeAppContextMenuData.name || ""
                actions: root.activeAppContextMenuData.actions || []
                maxVisibleRows: root.activeAppContextMenuData.maxVisibleRows || 6

                onActionTriggered: function(action) {
                    appActionsDialog.visible = false
                    if (action && String(action.command || "").trim().length > 0) {
                        root.runCommand(action.command)
                    }
                }
                onCloseRequested: {
                    appActionsDialog.visible = false
                }
            }
        }

        PlasmaCore.AppletPopup {
            id: notePopupDialog
            popupDirection: root.popupDirection
            margin: root.popupMargin
            floating: !root.inPanel
            removeBorderStrategy: root.inPanel
                ? PlasmaCore.AppletPopup.AtScreenEdges | PlasmaCore.AppletPopup.AtPanelEdges
                : PlasmaCore.AppletPopup.AtScreenEdges
            visible: false
            hideOnWindowDeactivate: true
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

        PlasmaCore.AppletPopup {
            id: taskWindowsDialog
            popupDirection: root.popupDirection
            margin: root.popupMargin
            floating: !root.inPanel
            removeBorderStrategy: root.inPanel
                ? PlasmaCore.AppletPopup.AtScreenEdges | PlasmaCore.AppletPopup.AtPanelEdges
                : PlasmaCore.AppletPopup.AtScreenEdges
            visible: false
            hideOnWindowDeactivate: false
            backgroundHints: PlasmaCore.Types.StandardBackground
            onVisibleChanged: {
                if (!visible) {
                    root.pendingTaskPopupAppName = ""
                    root.pendingTaskPopupRows = []
                    root.taskPopupVisualParent = null
                    root.taskPopupHovered = false
                    taskPopupCloseTimer.stop()
                }
            }

            mainItem: TaskWindowsPopup {
                id: taskWindowsPopupContent
                appName: root.activeTaskPopupData.name || ""
                windows: root.activeTaskPopupData.windows || []
                previewStyle: root.windowPreviewStyle
                previewScale: root.windowPreviewScale
                popupDirection: root.popupDirection
                inPanel: root.inPanel
                maxVisibleRows: root.maxPopupRows
                maximumAvailableHeight: root.taskPopupAvailableHeight

                onContainsMouseChanged: {
                    root.taskPopupHovered = containsMouse
                    if (containsMouse) {
                        taskPopupCloseTimer.stop()
                    } else if (!mainContainer.taskPopupSourceContainsMouse()) {
                        taskPopupCloseTimer.restart()
                    }
                }

                onActivateRequested: function(taskRow) {
                    taskWindowsDialog.visible = false
                    taskController.activateTaskRow(taskRow)
                }
                onCloseWindowRequested: function(taskRow) {
                    taskController.closeTaskRow(taskRow)
                }
                onCloseRequested: {
                    taskWindowsDialog.visible = false
                }
            }
        }

        PlasmaCore.AppletPopup {
            id: taskOverflowDialog
            popupDirection: root.popupDirection
            margin: root.popupMargin
            floating: !root.inPanel
            removeBorderStrategy: root.inPanel
                ? PlasmaCore.AppletPopup.AtScreenEdges | PlasmaCore.AppletPopup.AtPanelEdges
                : PlasmaCore.AppletPopup.AtScreenEdges
            visible: false
            hideOnWindowDeactivate: true
            backgroundHints: PlasmaCore.Types.StandardBackground

            mainItem: TaskOverflowPopup {
                entries: root.overflowTaskRows
                maxVisibleRows: root.maxPopupRows

                onEntryActivated: function(entry) {
                    taskOverflowDialog.visible = false
                    if (entry.count > 1) {
                        mainContainer.openTaskWindowsPopup(entry.name, entry.rows, taskOverflowDockItem)
                    } else if (entry.firstRow >= 0) {
                        taskController.activateTaskRow(entry.firstRow)
                    }
                }
                onCloseRequested: taskOverflowDialog.visible = false
            }
        }

        PlasmaCore.AppletPopup {
            id: trashConfirmDialog
            popupDirection: root.popupDirection
            margin: root.popupMargin
            floating: !root.inPanel
            removeBorderStrategy: root.inPanel
                ? PlasmaCore.AppletPopup.AtScreenEdges | PlasmaCore.AppletPopup.AtPanelEdges
                : PlasmaCore.AppletPopup.AtScreenEdges
            visible: false
            hideOnWindowDeactivate: false
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
