import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.taskmanager as TaskManager
import "org/punchi/dock" as Punchi
import "components"

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    toolTipMainText: ""
    toolTipSubText: ""
    preferredRepresentation: fullRepresentation
    compactRepresentation: fullRepresentation

    // Plasma documents PlasmaCore.Action as the QAction factory for
    // Plasmoid.contextualActions. Qt 6.8 qmllint cannot resolve that type from
    // the installed Plasma metadata and reports cascading property warnings.
    // qmllint disable import
    // qmllint disable missing-property
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18nc("@action:context", "Add Quick Note")
            icon.name: "knotes"
            onTriggered: dockItemsController.addQuickNote()
        },
        PlasmaCore.Action {
            text: i18nc("@action:context", "Add Separator")
            icon.name: "draw-line"
            onTriggered: dockItemsController.addQuickSeparator()
        }
    ]
    // qmllint enable missing-property
    // qmllint enable import

    property bool deletingActiveNote: false
    
    // Host environment detection (panel or floating dock).
    property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property var visibleTaskRows: taskController.visibleTaskRows
    readonly property var overflowTaskRows: taskController.overflowTaskRows
    readonly property int taskVisualRevision: taskController.visualRevision
    signal taskStructureChanged()

    // Virtual desktop visibility.
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
    Punchi.MprisController {
        id: mprisController
    }
    Punchi.ThemeIntegration {
        id: themeIntegration
    }
    Punchi.DockThemeRepository {
        id: dockThemeRepository
        themeId: root.inPanel ? "" : String(Plasmoid.configuration.dockThemeCustomId || "")
    }
    DockConfigurationState {
        id: dockConfig
        inPanel: root.inPanel
        horizontalPanel: dockGeometry.horizontalPanel
        effectiveIconSize: dockGeometry.effectiveIconSize
        themeRepositoryValid: dockThemeRepository.valid
        theme: dockThemeRepository.theme
    }
    DockGeometryState {
        id: dockGeometry
        inPanel: root.inPanel
        hiddenByVirtualDesktop: root.hiddenByVirtualDesktop
        verticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
        horizontalPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
        panelLocation: Plasmoid.location
        configuredIconSize: Number(Plasmoid.configuration.iconSize || 48)
        configuredPanelLengthMode: String(Plasmoid.configuration.panelLengthMode || "fit")
        panelHoverScale: dockConfig.panelHoverScale
        folderPopupExtraDistance: dockConfig.folderPopupExtraDistance
        dockShowLabels: dockConfig.dockShowLabels
        dockLabelAreaHeight: dockConfig.dockLabelAreaHeight
        dockItems: dockItemsController.dockItems
        visibleTaskCount: root.visibleTaskRows.length
        overflowTaskCount: root.overflowTaskRows.length
        totalDynamicGroups: taskController.totalDynamicGroups
        availableScreenRect: root.availableScreenRect
        hostHeight: root.height
        // PanelView and containment expose these properties at runtime.
        // qmllint disable missing-property
        panelWindow: root.Window.window
        containment: Plasmoid.containment
        // qmllint enable missing-property
    }
    Punchi.AudioSpectrumController {
        id: audioSpectrumController
        enabled: dockConfig.audioSpectrumConfigured
            && !root.hiddenByVirtualDesktop
    }
    TaskModelController {
        id: taskController
        dockItems: dockItemsController.dockItems
        showActiveTasks: Plasmoid.configuration.showActiveTasks
        currentDesktopOnly: Plasmoid.configuration.showTasksCurrentDesktopOnly
        windowGroupingMode: String(Plasmoid.configuration.windowGroupingMode || "application")
        maxDynamicGroups: Math.max(1, Math.min(20,
            Number(Plasmoid.configuration.maxDynamicTaskGroups || 8)))
        automaticDynamicGroups: dockGeometry.panelFillLengthEnabled
        dynamicGroupCapacity: root.panelDynamicGroupCapacity
        systemDiscovery: systemDiscovery
        onStructureChanged: root.taskStructureChanged()
    }
    DockItemsController {
        id: dockItemsController
        runtimeService: runtimeService
        systemDiscovery: systemDiscovery
        taskController: taskController
        trashIntegration: trashIntegration
        minimizeEffect: dockConfig.dockWindowMinimizeEffect
    }
    DockContextActionsController {
        id: dockContextActionsController
        systemDiscovery: systemDiscovery
        taskController: taskController
        dockItemsController: dockItemsController
    }
    readonly property string currentVirtualDesktopId: String(virtualDesktopInfo.currentDesktop || "")
    readonly property bool singleVirtualDesktopMode: Plasmoid.configuration.virtualDesktopMode === "single"
        && Plasmoid.configuration.targetVirtualDesktop !== ""
    readonly property bool hiddenByVirtualDesktop: singleVirtualDesktopMode
        && currentVirtualDesktopId !== Plasmoid.configuration.targetVirtualDesktop
    property int panelDynamicGroupCapacity: -1

    implicitWidth: inPanel ? dockGeometry.panelPreferredWidth : 0
    implicitHeight: inPanel ? dockGeometry.panelPreferredHeight : 0
    switchWidth: inPanel ? dockGeometry.panelPreferredWidth : Math.ceil(dockGeometry.panelItemWidth)
    switchHeight: inPanel ? dockGeometry.panelPreferredHeight : Math.ceil(dockGeometry.panelItemHeight)

    Layout.fillWidth: dockGeometry.panelFillLengthEnabled
    Layout.fillHeight: inPanel && dockGeometry.horizontalPanel && !hiddenByVirtualDesktop
    Layout.minimumWidth: inPanel ? dockGeometry.panelMinimumWidth : -1
    Layout.minimumHeight: inPanel ? dockGeometry.panelMinimumHeight : -1
    Layout.preferredWidth: inPanel ? dockGeometry.panelPreferredWidth : -1
    Layout.preferredHeight: inPanel ? dockGeometry.panelPreferredHeight : -1

    Punchi.TrashIntegration {
        id: trashIntegration
        // qmllint disable unqualified
        onOperationFailed: function(operation, message) {
            console.warn("Punchi Dock:", operation, message)
        }
        // qmllint enable unqualified
    }

    fullRepresentation: Item {
        id: mainContainer
        // fullRepresentation is compiled as a nested component, so qmllint
        // cannot resolve accesses to the owning PlasmoidItem even though
        // Plasma provides that lexical context at runtime.
        // qmllint disable unqualified
        visible: !root.hiddenByVirtualDesktop
        enabled: visible
        implicitWidth: visible ? dockGeometry.panelPreferredWidth : 0
        implicitHeight: visible ? dockGeometry.panelPreferredHeight : 0
        Layout.fillWidth: dockGeometry.panelFillLengthEnabled
        Layout.fillHeight: root.inPanel && dockGeometry.horizontalPanel && visible
        Layout.minimumWidth: dockGeometry.panelMinimumWidth
        Layout.minimumHeight: dockGeometry.panelMinimumHeight
        Layout.preferredWidth: dockGeometry.panelPreferredWidth
        Layout.preferredHeight: dockGeometry.panelPreferredHeight
        // qmllint enable unqualified

        PopupCoordinator {
            id: popupCoordinator
            inPanel: root.inPanel
            panelPopupDirection: dockGeometry.popupDirection
            availableScreenRect: root.availableScreenRect
            dockFallbackAnchor: dockWrapper
            taskStructureSource: root
            taskControllerRef: taskController
            mprisControllerRef: mprisController
            trashIntegrationRef: trashIntegration
            trashContextContentRef: trashContextContent
            notePopupContentRef: notePopupContent
            taskWindowsPopupContentRef: taskWindowsPopupContent
            taskContextSurfaceStackRef: taskContextSurfaceStack
            taskPopupAnimatedContentRef: taskPopupAnimatedContent
            mediaHoverEnabled: dockConfig.mediaControlsOnHover
            folderPopupDialogRef: folderPopupDialog
            calendarPopupDialogRef: calendarPopupDialog
            trashMenuDialogRef: trashMenuDialog
            notePopupDialogRef: notePopupDialog
            appActionsDialogRef: appActionsDialog
            taskWindowsDialogRef: taskWindowsDialog
            taskOverflowDialogRef: taskOverflowDialog
            applicationIdentityResolver: function(itemData) {
                return dockContextActionsController.applicationIdentityForItem(itemData)
            }
            // qmllint disable unqualified
            contextActionsResolver: function(itemData, rows, itemOrigin, persistentIndex) {
                return dockContextActionsController.actionsForItem(
                    itemData, rows, itemOrigin, persistentIndex)
            }
            // qmllint enable unqualified
        }

        // qmllint disable unqualified
        Connections {
            target: trashIntegration

            function onOperationSucceeded(operation) {
                if (operation !== "emptyTrash") {
                    return
                }
                runtimeService.playSound(popupCoordinator.activeTrashEmptySound, "trash-empty")
                if (trashMenuDialog.visible && trashContextContent.confirmationVisible) {
                    trashSuccessCloseTimer.restart()
                }
            }
        }

        Timer {
            id: trashSuccessCloseTimer
            interval: 1200
            repeat: false
            onTriggered: {
                trashMenuDialog.visible = false
                trashContextContent.showMenu()
                trashIntegration.resetOperationState()
            }
        }
        // qmllint enable unqualified

        Item {
            id: dockWrapper
            anchors.centerIn: parent
            // This nested representation intentionally reads the owning
            // PlasmoidItem and sibling controllers to follow panel geometry.
            // qmllint disable unqualified
            implicitWidth: root.inPanel
                ? dockGeometry.panelPreferredWidth
                : dockLayout.implicitWidth + dockLayout.trailingOverflowExtent
                    + dockGeometry.floatingExtraWidth
            implicitHeight: root.inPanel ? dockGeometry.panelPreferredHeight : dockLayout.implicitHeight + dockGeometry.floatingExtraHeight
            width: root.inPanel ? parent.width : implicitWidth
            height: root.inPanel ? parent.height : implicitHeight

            readonly property int dynamicTaskSlotCapacity: {
                if (!dockGeometry.panelFillLengthEnabled) {
                    return -1
                }

                const innerWidth = Math.max(0, width
                    - (dockGeometry.dockBackgroundHorizontalPadding * 2))
                const boundarySpacing = dockItemsController.dockItems.length > 0
                    && taskController.totalDynamicGroups > 0
                    ? dockGeometry.dockSpacing
                    : 0
                const availableWidth = Math.max(0, innerWidth
                    - dockGeometry.panelFixedContentWidth - boundarySpacing)
                return Math.max(0, Math.floor((availableWidth + dockGeometry.dockSpacing)
                    / (dockGeometry.panelItemWidth + dockGeometry.dockSpacing)))
            }

            Binding {
                target: root
                property: "panelDynamicGroupCapacity"
                value: dockWrapper.dynamicTaskSlotCapacity
                restoreMode: Binding.RestoreBindingOrValue
            }
            // qmllint enable unqualified

            WindowIntersectionController {
                id: windowIntersectionController
                targetItem: dockWrapper
                monitoringEnabled: !root.inPanel
                    && mainContainer.visible
                    && themeIntegration.adaptiveTransparencyEnabled
                screenGeometry: {
                    const containment = Plasmoid.containment
                    return containment && containment.screenGeometry
                        ? containment.screenGeometry
                        : Qt.rect(0, 0, 0, 0)
                }
            }

            DockBackground {
                anchors.fill: parent
                preferOpaque: !!(Plasmoid.containmentDisplayHints
                    & PlasmaCore.Types.ContainmentPrefersOpaqueBackground)
                    || windowIntersectionController.touchingWindow
                // qmllint disable unqualified
                spectrumActive: audioSpectrumController.active
                spectrumLevels: audioSpectrumController.levels
                spectrumIntensity: dockConfig.audioSpectrumIntensity
                spectrumUsePlasmaTheme: dockConfig.audioSpectrumUsePlasmaTheme
                spectrumBarCount: dockConfig.audioSpectrumBarCount
                spectrumOriginEdge: dockConfig.audioSpectrumOrigin === "top"
                    ? Qt.TopEdge
                    : Qt.BottomEdge
                spectrumEdgeInset: dockGeometry.floatingExtraHeight / 2
                spectrumBarStyle: dockConfig.audioSpectrumStyle
                spectrumFlowDirection: dockConfig.audioSpectrumFlow
                plasmaBackgroundVisible: !dockConfig.audioSpectrumConfigured
                    || dockConfig.audioSpectrumBackgroundMode === "plasma"
                customThemeEnabled: dockConfig.customDockThemeActive
                customTheme: dockThemeRepository.theme
                // qmllint enable unqualified
                visible: !root.inPanel
            }

            // qmllint disable unqualified
            Item {
                id: panelSpectrumViewport

                readonly property real panelCrossAxisExtent: {
                    const extent = Number(dockGeometry.verticalPanel ? root.width : root.height)
                    return extent > 0
                        ? extent
                        : (dockGeometry.verticalPanel ? dockLayout.width : dockLayout.height)
                }

                // The applet allocation excludes Plasma's adaptive floating margin.
                x: dockGeometry.verticalPanel
                    ? Math.round((parent.width - width) / 2)
                    : dockLayout.x
                y: dockGeometry.verticalPanel
                    ? dockLayout.y
                    : Math.round((parent.height - height) / 2)
                width: dockGeometry.verticalPanel
                    ? Math.min(dockLayout.width, panelCrossAxisExtent)
                    : (dockGeometry.panelFillLengthEnabled
                        ? Math.max(0, parent.width - x
                            - dockGeometry.dockBackgroundHorizontalPadding)
                        : dockLayout.width)
                height: dockGeometry.verticalPanel
                    ? dockLayout.height
                    : Math.min(dockLayout.height, panelCrossAxisExtent)
                clip: true
                visible: root.inPanel

                AudioSpectrumLayer {
                    anchors.fill: parent
                    active: root.inPanel && audioSpectrumController.active
                    levels: audioSpectrumController.levels
                    intensity: dockConfig.audioSpectrumIntensity
                    usePlasmaTheme: dockConfig.audioSpectrumUsePlasmaTheme
                    barCount: dockConfig.audioSpectrumBarCount
                    barStyle: dockConfig.audioSpectrumStyle
                    flowDirection: dockConfig.audioSpectrumFlow
                    vertical: dockGeometry.verticalPanel
                    originEdge: dockGeometry.verticalPanel
                        ? (dockGeometry.leftPanel ? Qt.LeftEdge : Qt.RightEdge)
                        : dockConfig.audioSpectrumOrigin === "top"
                            ? Qt.TopEdge
                            : Qt.BottomEdge
                }
            }
            // qmllint enable unqualified

            RowLayout {
                id: dockLayout
                spacing: dockGeometry.dockSpacing
                // The row is part of fullRepresentation and resolves its
                // trailing sibling through the owning representation.
                // qmllint disable unqualified
                readonly property real trailingOverflowExtent: overflowLayoutAnchor.visible
                    ? dockGeometry.dockSpacing + overflowLayoutAnchor.width
                    : 0
                // qmllint enable unqualified
                x: {
                    if (!root.inPanel) {
                        return Math.round((parent.width - width - trailingOverflowExtent) / 2)
                    }
                    if (dockGeometry.panelFillLengthEnabled) {
                        return dockGeometry.dockBackgroundHorizontalPadding
                    }
                    if (dockGeometry.leftPanel) {
                        return dockGeometry.dockBackgroundHorizontalPadding
                    }
                    if (dockGeometry.rightPanel) {
                        return parent.width - width - trailingOverflowExtent
                            - dockGeometry.dockBackgroundHorizontalPadding
                    }
                    return Math.round((parent.width - width - trailingOverflowExtent) / 2)
                }
                y: {
                    if (!root.inPanel) {
                        return Math.round((parent.height - height) / 2)
                    }
                    return Math.round((parent.height - height) / 2)
                }
                
                property int hoveredIndex: -1
                property real mouseOffset: 0.0

                // State used for smooth transitions when entering or leaving the dock.
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
                    dockItemsController.runCommand(cmd)
                }

                Repeater {
                    model: dockItemsController.dockItems
                    delegate: DockItem {
                        id: dockItemDelegate
                        itemIndex: index
                        hoveredIndex: dockLayout.hoveredIndex
                        inPanel: root.inPanel
                        panelLocation: dockGeometry.panelLocation
                        iconSize: dockGeometry.effectiveIconSize
                        hoverScaleSetting: dockConfig.panelHoverScale
                        hoverAnimationMode: Plasmoid.configuration.hoverAnimation || "wave"
                        clickEffect: dockConfig.dockClickEffect
                        // qmllint disable unqualified
                        windowMinimizeEffect: dockConfig.dockWindowMinimizeEffect
                        taskMinimizedCount: taskState.minimizedCount
                        minimizeReactionRevision: dockItemsController.minimizeReactionRevision
                        minimizeReactionTargetIndex: dockItemsController.minimizeReactionTargetIndex
                        showItemHoverBackground: dockConfig.dockShowItemHoverBackground
                        iconReflectionEnabled: dockConfig.dockIconReflectionsEnabled
                        iconReflectionOpacity: dockConfig.dockIconReflectionOpacity
                        iconReflectionAvailableExtent: dockGeometry.panelReflectionAvailableExtent
                        // qmllint enable unqualified
                        // The delegate is compiled as a nested component by
                        // qmllint; these bindings resolve the owning plasmoid at runtime.
                        // qmllint disable unqualified
                        positionTransitionEnabled: dockItemsController.itemTransitionActive
                        animateEntry: {
                            const appId = taskController.dockItemApplicationId(modelData)
                            const launcherUrl = taskController.dockItemLauncherUrl(modelData)
                            return (dockItemsController.recentlyTransitionedAppId.length > 0
                                    && appId === dockItemsController.recentlyTransitionedAppId)
                                || (dockItemsController.recentlyTransitionedLauncherUrl.length > 0
                                    && launcherUrl === dockItemsController.recentlyTransitionedLauncherUrl)
                        }
                        // qmllint enable unqualified
                        showPersistentLabel: dockConfig.dockShowLabels
                        textShadowsEnabled: dockConfig.dockTextShadowsEnabled
                        labelFontSize: dockConfig.dockLabelFontSize
                        indicatorType: dockConfig.dockIndicatorType
                        indicatorPosition: dockConfig.dockIndicatorPosition
                        indicatorThickness: dockConfig.dockIndicatorThickness
                        indicatorOpacity: dockConfig.dockIndicatorOpacity
                        customSeparatorEnabled: dockConfig.customDockSeparatorActive
                        separatorTheme: dockConfig.customDockSeparatorTheme
                        
                        // Wave animation state.
                        hoverZoomProgress: dockLayout.hoverZoomProgress
                        lastHoveredIndex: dockLayout.lastHoveredIndex
                        lastMouseOffset: dockLayout.lastMouseOffset
                        readonly property int taskRevision: root.taskVisualRevision
                        readonly property var taskState: {
                            taskRevision
                            return taskController.taskStateForDockItem(modelData)
                        }
                        
                        itemType: modelData.type || "app"
                        timeTextScale: modelData.timeTextScale === undefined ? (modelData.textScale === undefined ? 1.0 : modelData.textScale) : modelData.timeTextScale
                        dateTextScale: modelData.dateTextScale === undefined ? (modelData.textScale === undefined ? 1.0 : modelData.textScale) : modelData.dateTextScale
                        separatorStyleSetting: modelData.separatorStyle || "line"
                        separatorThicknessSetting: modelData.separatorThickness === undefined ? 2 : modelData.separatorThickness
                        separatorLengthRatioSetting: modelData.separatorLengthRatio === undefined ? 0.72 : modelData.separatorLengthRatio
                        separatorOpacitySetting: modelData.separatorOpacity === undefined ? 0.34 : modelData.separatorOpacity
                        separatorGlowSetting: modelData.separatorGlowEnabled === true
                        iconName: modelData.type === "trash" && modelData.showState !== false
                            ? (dockItemsController.trashHasItems ? (modelData.fullIcon || "user-trash-full") : (modelData.icon || "user-trash"))
                            : (modelData.icon || "")
                        itemName: modelData.name || ""
                        itemCommand: modelData.command || ""
                        taskIndicatorCount: taskState.count
                        taskIsActive: taskState.isActive
                        taskDemandsAttention: taskState.demandsAttention
                        suppressTooltip: mainContainer.contextMenuVisible
                            || (taskWindowsDialog.visible && popupCoordinator.taskPopupVisualParent === dockItemDelegate)
                        supportsContextMenu: dockContextActionsController.itemHasContextMenu(modelData, taskState.rows, "pinned")
                        mediaHoverControlsEnabled: dockConfig.mediaControlsOnHover && taskState.count > 0

                        // qmllint disable unqualified
                        TaskDelegateGeometryPublisher {
                            taskModelController: taskController
                            targetItem: dockItemDelegate.taskGeometryItem
                            taskRows: dockItemDelegate.taskState.rows
                        }
                        // qmllint enable unqualified
                        
                        onItemClicked: function(cmd) {
                            if (modelData.type === "folder") {
                                popupCoordinator.openFolderPopup(modelData, dockItemDelegate)
                            } else if (modelData.type === "calendar") {
                                popupCoordinator.openCalendarPopup(modelData, dockItemDelegate)
                            } else if (modelData.type === "note") {
                                popupCoordinator.openNotePopup(modelData, dockItemDelegate, index)
                            } else {
                                popupCoordinator.closeAllPopups(null)
                                dockItemsController.handleDockItemActivation(modelData, dockItemDelegate)
                            }
                        }
                        // qmllint disable unqualified
                        onTaskMinimized: function(minimizedItemIndex) {
                            dockItemsController.triggerMinimizeReaction(minimizedItemIndex)
                        }
                        // qmllint enable unqualified
                        onContextMenuRequested: function(visualParent, keyboardInvoked) {
                            if (modelData.type === "trash") {
                                popupCoordinator.openTrashMenu(modelData, visualParent, keyboardInvoked)
                            } else if (dockContextActionsController.itemHasContextMenu(modelData, taskState.rows, "pinned")) {
                                popupCoordinator.openAppContextMenu(modelData, visualParent,
                                    taskState.rows, "pinned", index)
                            }
                        }
                        onHoverEntered: function(visualParent) {
                            if ((dockConfig.mediaControlsOnHover || dockConfig.windowPreviewStyle !== "none")
                                    && taskState.count > 0) {
                                popupCoordinator.scheduleTaskWindowsPopup(modelData.name || "",
                                    taskState.rows, visualParent, false,
                                    dockConfig.windowPreviewStyle !== "none")
                            }
                        }
                        onMediaControlsRequested: function(visualParent) {
                            popupCoordinator.scheduleTaskWindowsPopup(modelData.name || "",
                                taskState.rows, visualParent, true, false)
                        }
                        onHoverExited: function(visualParent) {
                            popupCoordinator.cancelPendingTaskWindowsPopup(visualParent)
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

                        itemIndex: dockItemsController.dockItems.length + index
                        hoveredIndex: dockLayout.hoveredIndex
                        inPanel: root.inPanel
                        panelLocation: dockGeometry.panelLocation
                        iconSize: dockGeometry.effectiveIconSize
                        hoverScaleSetting: dockConfig.panelHoverScale
                        hoverAnimationMode: Plasmoid.configuration.hoverAnimation || "wave"
                        clickEffect: dockConfig.dockClickEffect
                        // qmllint disable unqualified
                        windowMinimizeEffect: dockConfig.dockWindowMinimizeEffect
                        taskMinimizedCount: taskData.minimizedCount
                        minimizeReactionRevision: dockItemsController.minimizeReactionRevision
                        minimizeReactionTargetIndex: dockItemsController.minimizeReactionTargetIndex
                        showItemHoverBackground: dockConfig.dockShowItemHoverBackground
                        iconReflectionEnabled: dockConfig.dockIconReflectionsEnabled
                        iconReflectionOpacity: dockConfig.dockIconReflectionOpacity
                        iconReflectionAvailableExtent: dockGeometry.panelReflectionAvailableExtent
                        // qmllint enable unqualified
                        // qmllint disable unqualified
                        positionTransitionEnabled: dockItemsController.itemTransitionActive
                        animateEntry: {
                            const appIds = modelData.appIds instanceof Array
                                ? modelData.appIds
                                : [String(modelData.appId || "")]
                            const launcherUrls = modelData.launcherUrls instanceof Array
                                ? modelData.launcherUrls
                                : [String(modelData.launcherUrl || "")]
                            return (dockItemsController.recentlyTransitionedAppId.length > 0
                                    && appIds.indexOf(dockItemsController.recentlyTransitionedAppId) >= 0)
                                || (dockItemsController.recentlyTransitionedLauncherUrl.length > 0
                                    && launcherUrls.indexOf(dockItemsController.recentlyTransitionedLauncherUrl) >= 0)
                        }
                        // qmllint enable unqualified
                        showPersistentLabel: dockConfig.dockShowLabels
                        textShadowsEnabled: dockConfig.dockTextShadowsEnabled
                        labelFontSize: dockConfig.dockLabelFontSize
                        indicatorType: dockConfig.dockIndicatorType
                        indicatorPosition: dockConfig.dockIndicatorPosition
                        indicatorThickness: dockConfig.dockIndicatorThickness
                        indicatorOpacity: dockConfig.dockIndicatorOpacity
                        hoverZoomProgress: dockLayout.hoverZoomProgress
                        lastHoveredIndex: dockLayout.lastHoveredIndex
                        lastMouseOffset: dockLayout.lastMouseOffset

                        itemType: "app"
                        iconName: taskData.icon
                        itemName: taskData.name
                        taskIndicatorCount: taskData.count
                        taskIsActive: taskData.active
                        taskDemandsAttention: taskData.demandsAttention
                        suppressTooltip: mainContainer.contextMenuVisible
                            || (taskWindowsDialog.visible && popupCoordinator.taskPopupVisualParent === taskDockItemDelegate)
                        supportsContextMenu: dockContextActionsController.itemHasContextMenu(modelData, taskData.rows, "dynamic")
                        mediaHoverControlsEnabled: dockConfig.mediaControlsOnHover && taskData.count > 0

                        // qmllint disable unqualified
                        TaskDelegateGeometryPublisher {
                            taskModelController: taskController
                            targetItem: taskDockItemDelegate.taskGeometryItem
                            taskRows: taskDockItemDelegate.taskData.rows
                        }
                        // qmllint enable unqualified

                        onItemClicked: function() {
                            popupCoordinator.closeAllPopups(null)
                            if (taskData.count > 1) {
                                taskController.activatePreferredTaskRow(taskData.rows)
                            } else if (taskData.firstRow >= 0) {
                                taskController.activateTaskRow(taskData.firstRow)
                            }
                        }
                        // qmllint disable unqualified
                        onTaskMinimized: function(minimizedItemIndex) {
                            dockItemsController.triggerMinimizeReaction(minimizedItemIndex)
                        }
                        // qmllint enable unqualified
                        onContextMenuRequested: function(visualParent) {
                            popupCoordinator.openAppContextMenu(modelData, visualParent,
                                taskData.rows, "dynamic", -1)
                        }
                        onHoverEntered: function(visualParent) {
                            if ((dockConfig.mediaControlsOnHover || dockConfig.windowPreviewStyle !== "none")
                                    && taskData.count > 0) {
                                popupCoordinator.scheduleTaskWindowsPopup(itemName,
                                    taskData.rows, visualParent, false,
                                    dockConfig.windowPreviewStyle !== "none")
                            }
                        }
                        onMediaControlsRequested: function(visualParent) {
                            popupCoordinator.scheduleTaskWindowsPopup(itemName,
                                taskData.rows, visualParent, true, false)
                        }
                        onHoverExited: function(visualParent) {
                            popupCoordinator.cancelPendingTaskWindowsPopup(visualParent)
                        }
                    }
                }

            }

            // The overflow anchor belongs to fullRepresentation and
            // intentionally references its owning PlasmoidItem and dock row.
            // qmllint disable unqualified
            Item {
                id: overflowLayoutAnchor
                visible: root.overflowTaskRows.length > 0
                width: taskOverflowDockItem.implicitWidth
                height: taskOverflowDockItem.implicitHeight
                x: dockGeometry.panelFillLengthEnabled
                    ? parent.width - dockGeometry.dockBackgroundHorizontalPadding - width
                    : dockLayout.x + dockLayout.width + dockGeometry.dockSpacing
                y: dockLayout.y

                // DockItem coordinates its wave hover state through its parent.
                property alias hoveredIndex: dockLayout.hoveredIndex
                property alias mouseOffset: dockLayout.mouseOffset

                DockItem {
                    id: taskOverflowDockItem
                    width: implicitWidth
                    height: implicitHeight
                    itemIndex: dockItemsController.dockItems.length + root.visibleTaskRows.length
                    hoveredIndex: dockLayout.hoveredIndex
                    inPanel: root.inPanel
                    panelLocation: dockGeometry.panelLocation
                    iconSize: dockGeometry.effectiveIconSize
                    hoverScaleSetting: dockConfig.panelHoverScale
                    hoverAnimationMode: Plasmoid.configuration.hoverAnimation || "wave"
                    clickEffect: dockConfig.dockClickEffect
                    windowMinimizeEffect: dockConfig.dockWindowMinimizeEffect
                    taskMinimizedCount: {
                        root.taskVisualRevision
                        return taskController.minimizedCountForRows(
                            taskController.taskRowsForEntries(root.overflowTaskRows))
                    }
                    minimizeReactionRevision: dockItemsController.minimizeReactionRevision
                    minimizeReactionTargetIndex: dockItemsController.minimizeReactionTargetIndex
                    showItemHoverBackground: dockConfig.dockShowItemHoverBackground
                    iconReflectionEnabled: dockConfig.dockIconReflectionsEnabled
                    iconReflectionOpacity: dockConfig.dockIconReflectionOpacity
                    iconReflectionAvailableExtent: dockGeometry.panelReflectionAvailableExtent
                    positionTransitionEnabled: dockItemsController.itemTransitionActive
                    hoverZoomProgress: dockLayout.hoverZoomProgress
                    lastHoveredIndex: dockLayout.lastHoveredIndex
                    lastMouseOffset: dockLayout.lastMouseOffset
                    itemType: "overflow"
                    iconName: "view-more-symbolic"
                    itemName: i18np("%1 more window group", "%1 more window groups",
                        root.overflowTaskRows.length)
                    taskIndicatorCount: root.overflowTaskRows.length

                    TaskDelegateGeometryPublisher {
                        taskModelController: taskController
                        targetItem: taskOverflowDockItem.taskGeometryItem
                        taskRows: taskController.taskRowsForEntries(root.overflowTaskRows)
                    }

                    onItemClicked: popupCoordinator.openTaskOverflowPopup(taskOverflowDockItem)
                    onTaskMinimized: function(minimizedItemIndex) {
                        dockItemsController.triggerMinimizeReaction(minimizedItemIndex)
                    }
                }
            }
            // qmllint enable unqualified
        }

        // Controlled AppletPopup usage: Plasma anchors the popup outside the panel.
        PlasmaCore.AppletPopup {
            id: folderPopupDialog
            popupDirection: popupCoordinator.popupDirection
            margin: dockGeometry.folderPopupMargin
            floating: !root.inPanel
            removeBorderStrategy: root.inPanel
                ? PlasmaCore.AppletPopup.AtScreenEdges | PlasmaCore.AppletPopup.AtPanelEdges
                : PlasmaCore.AppletPopup.AtScreenEdges
            visible: false
            hideOnWindowDeactivate: true
            backgroundHints: PlasmaCore.AppletPopup.StandardBackground

            mainItem: PopupAnimatedContent {
                popupVisible: folderPopupDialog.visible
                // qmllint disable unqualified
                animationStyle: dockConfig.popupAnimationStyle
                animationSpeedPercent: dockConfig.popupAnimationSpeedPercent
                animationIntensityPercent: dockConfig.popupAnimationIntensity
                popupDirection: popupCoordinator.popupDirection
                // qmllint enable unqualified

                FolderPopup {
                    id: folderPopupContent
                    folderItem: popupCoordinator.activeFolderData
                    layoutMode: ["list", "detailed"].indexOf(popupCoordinator.activeFolderData.layout) >= 0
                        ? popupCoordinator.activeFolderData.layout
                        : "grid"
                    // qmllint disable unqualified
                    profileIconSize: folderPopupContent.layoutMode === "list"
                        ? dockConfig.folderListIconSize
                        : (folderPopupContent.layoutMode === "detailed"
                            ? dockConfig.folderDetailedIconSize
                            : dockConfig.folderGridIconSize)
                    profileColumns: dockConfig.folderGridColumns
                    profileRows: folderPopupContent.layoutMode === "list"
                        ? dockConfig.folderListRows
                        : (folderPopupContent.layoutMode === "detailed"
                            ? dockConfig.folderDetailedRows
                            : dockConfig.folderGridRows)
                    profileShowLabels: folderPopupContent.layoutMode === "list"
                        ? dockConfig.folderListShowLabels
                        : (folderPopupContent.layoutMode === "detailed"
                            ? dockConfig.folderDetailedShowLabels
                            : dockConfig.folderGridShowLabels)
                    profileFontFamily: folderPopupContent.layoutMode === "list"
                        ? dockConfig.folderListFontFamily
                        : (folderPopupContent.layoutMode === "detailed"
                            ? dockConfig.folderDetailedFontFamily
                            : dockConfig.folderGridFontFamily)
                    profileFontSize: folderPopupContent.layoutMode === "list"
                        ? dockConfig.folderListFontSize
                        : (folderPopupContent.layoutMode === "detailed"
                            ? dockConfig.folderDetailedFontSize
                            : dockConfig.folderGridFontSize)
                    textShadowsEnabled: dockConfig.popupTextShadowsEnabled
                    maximumAvailableWidth: dockGeometry.taskPopupAvailableWidth
                    maximumAvailableHeight: dockGeometry.taskPopupAvailableHeight
                    // qmllint enable unqualified

                    onAppLaunched: function(app) {
                        folderPopupDialog.visible = false
                        dockItemsController.launchDockItem(app)
                    }

                    onCloseRequested: {
                        folderPopupDialog.visible = false
                    }
                }
            }
        }

        // Calendar popup.
        PlasmaCore.AppletPopup {
            id: calendarPopupDialog
            popupDirection: popupCoordinator.popupDirection
            margin: dockGeometry.popupMargin
            floating: !root.inPanel
            removeBorderStrategy: root.inPanel
                ? PlasmaCore.AppletPopup.AtScreenEdges | PlasmaCore.AppletPopup.AtPanelEdges
                : PlasmaCore.AppletPopup.AtScreenEdges
            visible: false
            hideOnWindowDeactivate: true
            // The calendar always uses the native KDE theme background, like Kickoff.
            backgroundHints: PlasmaCore.AppletPopup.StandardBackground

            mainItem: PopupAnimatedContent {
                popupVisible: calendarPopupDialog.visible
                // qmllint disable unqualified
                animationStyle: dockConfig.popupAnimationStyle
                animationSpeedPercent: dockConfig.popupAnimationSpeedPercent
                animationIntensityPercent: dockConfig.popupAnimationIntensity
                popupDirection: popupCoordinator.popupDirection
                // qmllint enable unqualified

                CalendarPopup {
                    showWeekNumbers: popupCoordinator.activeCalendarData.showWeekNumbers === undefined
                        ? true
                        : popupCoordinator.activeCalendarData.showWeekNumbers
                    popupScale: popupCoordinator.activeCalendarData.popupScale === undefined
                        ? 1.0
                        : Number(popupCoordinator.activeCalendarData.popupScale || 1.0)
                    // Reset the popup to the current date whenever it opens.
                    Component.onCompleted: {
                        displayedDate = new Date()
                        updateGrid()
                    }
                    onCloseRequested: {
                        calendarPopupDialog.visible = false
                    }
                }
            }
        }

        // Trash context menu popup.
        PlasmaCore.AppletPopup {
            id: trashMenuDialog
            popupDirection: popupCoordinator.popupDirection
            margin: dockGeometry.popupMargin
            floating: !root.inPanel
            removeBorderStrategy: root.inPanel
                ? PlasmaCore.AppletPopup.AtScreenEdges | PlasmaCore.AppletPopup.AtPanelEdges
                : PlasmaCore.AppletPopup.AtScreenEdges
            visible: false
            hideOnWindowDeactivate: !trashContextContent.confirmationVisible
            backgroundHints: PlasmaCore.AppletPopup.StandardBackground

            mainItem: PopupAnimatedContent {
                popupVisible: trashMenuDialog.visible
                // qmllint disable unqualified
                animationStyle: dockConfig.menuAnimationStyle
                animationSpeedPercent: dockConfig.menuAnimationSpeedPercent
                animationIntensityPercent: dockConfig.menuAnimationIntensity
                popupDirection: popupCoordinator.popupDirection
                // qmllint enable unqualified

                TrashContextPopup {
                    id: trashContextContent
                    // qmllint disable unqualified
                    operationState: trashIntegration.operationState
                    progressPercent: trashIntegration.progressPercent
                    progressDeterminate: trashIntegration.progressDeterminate
                    processedItems: trashIntegration.processedItems
                    totalItems: trashIntegration.totalItems
                    errorMessage: trashIntegration.errorMessage
                    transitionSpeedPercent: dockConfig.contextMenuTransitionSpeed
                    menuWidth: dockConfig.contextMenuWidth
                    menuRowHeight: dockConfig.contextMenuRowHeight
                    menuIconSize: dockConfig.contextMenuIconSize
                    menuTextShadowsEnabled: dockConfig.menuTextShadowsEnabled
                    maximumAvailableWidth: dockGeometry.taskPopupAvailableWidth
                    maximumAvailableHeight: dockGeometry.taskPopupAvailableHeight
                    onOpenTrashRequested: {
                        trashMenuDialog.visible = false
                        trashIntegration.openTrash()
                    }
                    onEmptyTrashRequested: {
                        trashIntegration.emptyTrash()
                    }
                    onCloseRequested: {
                        trashSuccessCloseTimer.stop()
                        trashMenuDialog.visible = false
                        if (!trashIntegration.emptying) {
                            trashIntegration.resetOperationState()
                            trashContextContent.showMenu()
                        }
                    }
                    // qmllint enable unqualified
                }
            }
        }

        PlasmaCore.AppletPopup {
            id: appActionsDialog
            popupDirection: popupCoordinator.popupDirection
            margin: dockGeometry.popupMargin
            floating: !root.inPanel
            removeBorderStrategy: root.inPanel
                ? PlasmaCore.AppletPopup.AtScreenEdges | PlasmaCore.AppletPopup.AtPanelEdges
                : PlasmaCore.AppletPopup.AtScreenEdges
            visible: false
            hideOnWindowDeactivate: !popupCoordinator.contextMenuOpening
            backgroundHints: PlasmaCore.AppletPopup.StandardBackground

            mainItem: PopupAnimatedContent {
                popupVisible: appActionsDialog.visible
                // qmllint disable unqualified
                animationStyle: dockConfig.menuAnimationStyle
                animationSpeedPercent: dockConfig.menuAnimationSpeedPercent
                animationIntensityPercent: dockConfig.menuAnimationIntensity
                popupDirection: popupCoordinator.popupDirection
                // qmllint enable unqualified

                ContextSurfaceStack {
                    id: appActionsSurfaceStack
                    showMedia: false
                    maximumAvailableHeight: dockGeometry.taskPopupAvailableHeight

                    AppActionsPopup {
                        id: appActionsContent
                        itemName: popupCoordinator.activeAppContextMenuData.name || ""
                        actions: popupCoordinator.activeAppContextMenuData.actions || []
                        // qmllint disable unqualified
                        maxVisibleRows: dockConfig.contextMenuVisibleRows
                        rowHeight: dockConfig.contextMenuRowHeight
                        iconSize: dockConfig.contextMenuIconSize
                        targetWidth: dockConfig.contextMenuWidth
                        textShadowsEnabled: dockConfig.menuTextShadowsEnabled
                        maximumAvailableWidth: dockGeometry.taskPopupAvailableWidth
                        maximumAvailableHeight: dockGeometry.taskPopupAvailableHeight
                        // qmllint enable unqualified

                        onActionTriggered: function(action) {
                            appActionsDialog.visible = false
                            dockContextActionsController.triggerAction(action)
                        }
                        onCloseRequested: {
                            appActionsDialog.visible = false
                        }
                    }
                }
            }
        }

        PlasmaCore.AppletPopup {
            id: notePopupDialog
            popupDirection: popupCoordinator.popupDirection
            margin: dockGeometry.popupMargin
            floating: !root.inPanel
            removeBorderStrategy: root.inPanel
                ? PlasmaCore.AppletPopup.AtScreenEdges | PlasmaCore.AppletPopup.AtPanelEdges
                : PlasmaCore.AppletPopup.AtScreenEdges
            visible: false
            hideOnWindowDeactivate: true
            backgroundHints: PlasmaCore.AppletPopup.StandardBackground
            onVisibleChanged: {
                if (!visible && !root.deletingActiveNote
                        && notePopupContent.currentText !== notePopupContent.initialText) {
                    const updatedNote = dockItemsController.updateNoteItem(popupCoordinator.activeNoteData,
                        notePopupContent.currentText, notePopupContent.activeWidth,
                        notePopupContent.activeHeight, popupCoordinator.activeNoteIndex)
                    if (updatedNote) {
                        popupCoordinator.activeNoteData = updatedNote
                        notePopupContent.markSaved(notePopupContent.currentText)
                    }
                }
            }

            mainItem: PopupAnimatedContent {
                popupVisible: notePopupDialog.visible
                // qmllint disable unqualified
                animationStyle: dockConfig.popupAnimationStyle
                animationSpeedPercent: dockConfig.popupAnimationSpeedPercent
                animationIntensityPercent: dockConfig.popupAnimationIntensity
                popupDirection: popupCoordinator.popupDirection
                // qmllint enable unqualified

                NotePopup {
                    id: notePopupContent
                    noteItem: popupCoordinator.activeNoteData
                    textShadowsEnabled: dockConfig.popupTextShadowsEnabled
                    // qmllint disable unqualified
                    onNoteChanged: function(noteText, popupWidth, popupHeight) {
                        const updatedNote = dockItemsController.updateNoteItem(
                            popupCoordinator.activeNoteData, noteText, popupWidth,
                            popupHeight, popupCoordinator.activeNoteIndex)
                        if (updatedNote) {
                            popupCoordinator.activeNoteData = updatedNote
                            notePopupContent.markSaved(noteText)
                        }
                    }
                    // qmllint enable unqualified
                    onCloseRequested: {
                        notePopupDialog.visible = false
                    }
                    onClearRequested: function(noteText, popupWidth, popupHeight) {
                        notePopupContent.initialText = noteText
                        popupCoordinator.activeNoteData = dockItemsController.updateNoteItem(
                            popupCoordinator.activeNoteData, noteText, popupWidth,
                            popupHeight, popupCoordinator.activeNoteIndex)
                    }
                    onDeleteRequested: {
                        root.deletingActiveNote = true
                        notePopupDialog.visible = false
                        if (dockItemsController.removeNoteItemAtIndex(popupCoordinator.activeNoteIndex)) {
                            popupCoordinator.activeNoteData = ({})
                            popupCoordinator.activeNoteIndex = -1
                        }
                        root.deletingActiveNote = false
                    }
                }
            }
        }

        PlasmaCore.AppletPopup {
            id: taskWindowsDialog
            popupDirection: popupCoordinator.popupDirection
            margin: dockGeometry.popupMargin
            floating: !root.inPanel
            removeBorderStrategy: root.inPanel
                ? PlasmaCore.AppletPopup.AtScreenEdges | PlasmaCore.AppletPopup.AtPanelEdges
                : PlasmaCore.AppletPopup.AtScreenEdges
            visible: false
            hideOnWindowDeactivate: true
            backgroundHints: PlasmaCore.AppletPopup.StandardBackground
            onVisibleChanged: {
                if (!visible) {
                    taskWindowsPopupContent.showPreviews()
                    popupCoordinator.resetTaskPopupState()
                }
            }

            mainItem: PopupAnimatedContent {
                id: taskPopupAnimatedContent
                popupVisible: taskWindowsDialog.visible
                // qmllint disable unqualified
                animationStyle: dockConfig.windowPreviewAnimationStyle
                animationSpeedPercent: dockConfig.windowPreviewAnimationSpeedPercent
                animationIntensityPercent: dockConfig.windowPreviewAnimationIntensity
                popupDirection: popupCoordinator.popupDirection
                // qmllint enable unqualified
                onCloseAnimationFinished: taskWindowsDialog.visible = false

                ContextSurfaceStack {
                    id: taskContextSurfaceStack
                    visible: taskWindowsDialog.visible
                    enabled: visible
                    mediaController: mprisController
                    taskControllerRef: taskController
                    mediaWindows: popupCoordinator.activeTaskPopupData.windows || []
                    mediaIcon: popupCoordinator.activeTaskPopupData.icon || "emblem-music-symbolic"
                    showMedia: popupCoordinator.mediaHoverActive
                    mediaOnly: popupCoordinator.mediaHoverActive
                        && !taskWindowsPopupContent.mediaActionsComposed
                    forceCompactMedia: popupCoordinator.mediaHoverActive
                        && taskWindowsPopupContent.mediaActionsComposed
                    transitionsEnabled: dockConfig.menuAnimationStyle !== "none"
                    contentGeometryTransitionsEnabled: taskWindowsDialog.visible
                        && taskPopupAnimatedContent.openingProgress >= 0.999
                    surfaceStateFrozen: taskPopupAnimatedContent.closing
                    transitionSpeedPercent: dockConfig.contextMenuTransitionSpeed
                    maximumAvailableHeight: dockGeometry.taskPopupAvailableHeight
                    function scheduleReanchor() {
                        if (taskWindowsDialog.visible) {
                            Qt.callLater(popupCoordinator.reanchorTaskWindowsPopup)
                        }
                    }
                    onImplicitWidthChanged: scheduleReanchor()
                    onImplicitHeightChanged: scheduleReanchor()
                    onContainsMouseChanged: {
                        popupCoordinator.setTaskPopupHovered(containsMouse)
                    }
                    onMediaCloseRequested: popupCoordinator.closeMediaHoverFromKeyboard()

                    TaskContextPopup {
                        id: taskWindowsPopupContent
                        windows: popupCoordinator.activeTaskPopupData.windows || []
                        taskControllerRef: taskController
                        taskRevision: root.taskVisualRevision
                        applicationId: popupCoordinator.activeTaskPopupData.applicationId || ""
                        windowUuids: popupCoordinator.activeTaskPopupData.windowUuids || []
                        previewStyle: dockConfig.windowPreviewStyle
                        previewScale: dockConfig.windowPreviewScale
                        previewInfoMode: dockConfig.windowPreviewInfoMode
                        windowPreviewTextShadowsEnabled: dockConfig.windowPreviewTextShadowsEnabled
                        menuTextShadowsEnabled: dockConfig.menuTextShadowsEnabled
                        maxVisibleRows: dockConfig.maxPopupRows
                        maximumAvailableWidth: dockGeometry.taskPopupAvailableWidth
                        maximumAvailableHeight: dockGeometry.taskPopupAvailableHeight
                        actionItemName: popupCoordinator.activeAppContextMenuData.name || ""
                        actions: popupCoordinator.activeAppContextMenuData.actions || []
                        // qmllint disable unqualified
                        maxVisibleActionRows: dockConfig.contextMenuVisibleRows
                        actionRowHeight: dockConfig.contextMenuRowHeight
                        actionIconSize: dockConfig.contextMenuIconSize
                        actionMenuWidth: dockConfig.contextMenuWidth
                        transitionDirection: dockConfig.contextMenuTransitionDirection
                        // qmllint enable unqualified
                        previewsEnabled: taskWindowsDialog.visible
                            && dockConfig.windowPreviewStyle !== "none"
                            && !popupCoordinator.mediaHoverActive
                        returnToMedia: popupCoordinator.mediaHoverActive
                        transitionsEnabled: dockConfig.menuAnimationStyle !== "none"
                        // qmllint disable unqualified
                        transitionSpeedPercent: dockConfig.contextMenuTransitionSpeed
                        // qmllint enable unqualified

                        onActivateRequested: function(taskRow) {
                            taskWindowsDialog.visible = false
                            taskController.activateTaskRow(taskRow)
                        }
                        onPresentWindowRequested: function(taskRow) {
                            taskController.requestWindowPresentation(taskRow)
                        }
                        onMinimizeWindowRequested: function(taskRow) {
                            taskController.minimizeTaskRow(taskRow)
                        }
                        onMaximizeWindowRequested: function(taskRow) {
                            taskController.toggleMaximizedTaskRow(taskRow)
                        }
                        onCloseWindowRequested: function(taskRow) {
                            if (taskController.closeTaskRow(taskRow)) {
                                popupCoordinator.removeTaskPopupWindow(taskRow)
                            }
                        }
                        onActionTriggered: function(action) {
                            taskWindowsDialog.visible = false
                            dockContextActionsController.triggerAction(action)
                        }
                    }
                }
            }
        }

        PlasmaCore.AppletPopup {
            id: taskOverflowDialog
            popupDirection: popupCoordinator.popupDirection
            margin: dockGeometry.popupMargin
            floating: !root.inPanel
            removeBorderStrategy: root.inPanel
                ? PlasmaCore.AppletPopup.AtScreenEdges | PlasmaCore.AppletPopup.AtPanelEdges
                : PlasmaCore.AppletPopup.AtScreenEdges
            visible: false
            hideOnWindowDeactivate: true
            backgroundHints: PlasmaCore.AppletPopup.StandardBackground

            mainItem: PopupAnimatedContent {
                popupVisible: taskOverflowDialog.visible
                // qmllint disable unqualified
                animationStyle: dockConfig.popupAnimationStyle
                animationSpeedPercent: dockConfig.popupAnimationSpeedPercent
                animationIntensityPercent: dockConfig.popupAnimationIntensity
                popupDirection: popupCoordinator.popupDirection
                // qmllint enable unqualified

                TaskOverflowPopup {
                    entries: root.overflowTaskRows
                    maxVisibleRows: dockConfig.maxPopupRows
                    textShadowsEnabled: dockConfig.windowPreviewTextShadowsEnabled

                    onEntryActivated: function(entry) {
                        taskOverflowDialog.visible = false
                        if (entry.count > 1) {
                            popupCoordinator.openTaskWindowsPopup(entry.name, entry.rows, taskOverflowDockItem)
                        } else if (entry.firstRow >= 0) {
                            taskController.activateTaskRow(entry.firstRow)
                        }
                    }
                    onCloseRequested: taskOverflowDialog.visible = false
                }
            }
        }

    }

}
