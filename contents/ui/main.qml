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
    signal taskStructureChanged()

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
    Punchi.MprisController {
        id: mprisController
    }
    Punchi.ThemeIntegration {
        id: themeIntegration
    }
    Punchi.DockThemeRepository {
        id: dockThemeRepository
        themeId: root.inPanel ? "" : root.dockThemeCustomId
    }
    Punchi.AudioSpectrumController {
        id: audioSpectrumController
        enabled: root.audioSpectrumConfigured
            && !root.hiddenByVirtualDesktop
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
        onStructureChanged: root.taskStructureChanged()
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
    readonly property string windowPreviewStyle: String(Plasmoid.configuration.windowPreviewStyle || "card")
    readonly property real windowPreviewScale: Math.max(0.5, Math.min(2.0,
        Number(Plasmoid.configuration.windowPreviewScale || 1.0)))
    readonly property bool taskPopupRadiusAuto: Plasmoid.configuration.taskPopupRadiusAuto !== false
    readonly property int taskPopupRadius: Math.max(4, Math.min(32,
        Number(Plasmoid.configuration.taskPopupRadius || 4)))
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
    readonly property string dockThemeMode: {
        const configuredMode = String(Plasmoid.configuration.dockThemeMode || "plasma")
        return configuredMode === "custom" ? "custom" : "plasma"
    }
    readonly property string dockThemeCustomId: String(Plasmoid.configuration.dockThemeCustomId || "")
    readonly property bool customDockThemeActive: !inPanel
        && dockThemeMode === "custom"
        && dockThemeRepository.valid
    readonly property var customDockSeparatorTheme: customDockThemeActive
        && dockThemeRepository.theme.separator
        ? dockThemeRepository.theme.separator
        : ({})
    readonly property bool customDockSeparatorActive: !inPanel
        && String(customDockSeparatorTheme.style || "").length > 0
    readonly property bool audioSpectrumConfigured: Plasmoid.configuration.audioSpectrumEnabled === true
    readonly property real audioSpectrumIntensity: Math.max(0.1, Math.min(0.6,
        Number(Plasmoid.configuration.audioSpectrumIntensity || 35) / 100.0))
    readonly property bool audioSpectrumUsePlasmaTheme: Plasmoid.configuration.audioSpectrumUsePlasmaTheme !== false
    readonly property int audioSpectrumBarCount: {
        const configuredCount = Number(Plasmoid.configuration.audioSpectrumBarCount || 12)
        return [8, 12, 16, 24, 32, 48].indexOf(configuredCount) >= 0 ? configuredCount : 12
    }
    readonly property string audioSpectrumStyle: {
        const configuredStyle = String(Plasmoid.configuration.audioSpectrumStyle || "edge")
        const supportedStyles = ["edge", "centered", "capsules", "pixel", "cloud", "particles"]
        return supportedStyles.indexOf(configuredStyle) >= 0 ? configuredStyle : "edge"
    }
    readonly property string audioSpectrumBackgroundMode: {
        const configuredMode = String(Plasmoid.configuration.audioSpectrumBackgroundMode || "plasma")
        return configuredMode === "spectrumOnly" ? "spectrumOnly" : "plasma"
    }
    readonly property string audioSpectrumOrigin: {
        const configuredOrigin = String(Plasmoid.configuration.audioSpectrumOrigin || "bottom")
        return configuredOrigin === "top" ? "top" : "bottom"
    }
    readonly property string audioSpectrumFlow: {
        const configuredFlow = String(Plasmoid.configuration.audioSpectrumFlow || "none")
        return ["left", "right"].indexOf(configuredFlow) >= 0 ? configuredFlow : "none"
    }
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
    readonly property string popupAnimationStyle: {
        const configuredStyle = String(Plasmoid.configuration.popupAnimation || "scale")
        return ["scale", "bounce", "fade", "slide", "none"].indexOf(configuredStyle) >= 0
            ? configuredStyle
            : "scale"
    }
    readonly property int popupAnimationSpeedPercent: Math.max(10, Math.min(200,
        Number(Plasmoid.configuration.popupAnimationSpeedPercent || 100)))
    readonly property int popupAnimationIntensity: Math.max(10, Math.min(200,
        Number(Plasmoid.configuration.popupAnimationIntensity || 100)))
    readonly property int contextMenuTransitionSpeed: Math.max(10, Math.min(200,
        Number(Plasmoid.configuration.contextMenuTransitionSpeed || 100)))
    // Plasma::Containment exposes its visual geometry at runtime, although the
    // generated QML type metadata does not declare width/height.
    // qmllint disable missing-property
    readonly property int detectedPanelThickness: {
        try {
            var containment = Plasmoid.containment
            if (!containment) {
                return 0
            }

            var thickness = verticalPanel
                ? Math.max(0, Number(containment["width"] || 0))
                : Math.max(0, Number(containment["height"] || 0))
            return thickness > 0 ? thickness : 0
        } catch (error) {
            return 0
        }
    }
    // qmllint enable missing-property
    readonly property int panelCrossAxisPadding: verticalPanel ? (dockBackgroundHorizontalPadding * 2) : (dockBackgroundVerticalPadding * 2)
    readonly property int effectivePanelIconLimit: detectedPanelThickness > 0
        ? Math.max(32, detectedPanelThickness - panelCrossAxisPadding - 12)
        : Math.max(32, Number(Plasmoid.configuration.iconSize || 48))
    readonly property int effectivePanelBaseIconLimit: detectedPanelThickness > 0
        ? Math.max(24, Math.floor(effectivePanelIconLimit / panelHoverScale))
        : Math.max(32, Number(Plasmoid.configuration.iconSize || 48))
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
        // qmllint disable unqualified
        onOperationFailed: function(operation, message) {
            console.warn("Punchi Dock:", operation, message)
        }
        onStateChanged: function(hasItems) {
            root.updateTrashState(hasItems)
        }
        // qmllint enable unqualified
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
            runtimeService.persistDockItemsJson(raw, root.configInstanceId())
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

    function configInstanceId() {
        var value = ""
        try {
            if (Plasmoid && Plasmoid.id !== undefined && Plasmoid.id !== null) {
                value = String(Plasmoid.id)
            }
        } catch (error) {
            value = ""
        }
        if (value.length === 0 || value === "undefined" || value === "null") {
            return "default"
        }
        return value.replace(/[^A-Za-z0-9_.-]/g, "_")
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
        return String(systemDiscovery.applicationIdForCommand(item.command || "") || "")
    }

    function appendUniqueContextActions(target, source, seenNames) {
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

    function itemContextActions(item, taskRows) {
        if (!item || (item.type || "app") !== "app") {
            return []
        }

        const actions = []
        const seenNames = {}
        const applicationId = applicationIdentityForItem(item)
        if (applicationId.length > 0) {
            appendUniqueContextActions(actions, systemDiscovery.applicationActions(applicationId), seenNames)
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
            appendUniqueContextActions(actions, customActions, seenNames)
        }

        appendUniqueContextActions(actions, taskController.contextActionsForRows(taskRows || []), seenNames)
        return actions
    }

    function itemHasContextMenu(item, taskRows) {
        if (!item || (item.type || "app") !== "app") {
            return false
        }
        return String(item.storageId || item.appId || item.command || "").trim().length > 0
            || (item.actions instanceof Array && item.actions.length > 0)
            || (taskRows instanceof Array && taskRows.length > 0)
    }

    function triggerContextAction(action) {
        if (!action || action.enabled === false) {
            return false
        }
        if (action.kind === "desktopAction") {
            return systemDiscovery.launchApplicationAction(action.applicationId || "", action.actionId || "")
        }
        if (action.kind === "taskAction") {
            return taskController.triggerContextAction(action)
        }
        if (String(action.command || "").trim().length > 0) {
            root.runCommand(action.command)
            return true
        }
        return false
    }

    function syncDockItemsConfiguration() {
        var raw = JSON.stringify(root.dockItems)
        Plasmoid.configuration.dockItemsJson = raw
        runtimeService.persistDockItemsJson(raw, root.configInstanceId())
    }

    function updateNoteItem(noteItem, noteText, popupWidth, popupHeight) {
        if (!noteItem) {
            return null
        }

        var updatedItems = []
        var updatedNoteItem = noteItem
        var changed = false
        for (var i = 0; i < root.dockItems.length; i++) {
            var item = root.dockItems[i]
            if (item === noteItem) {
                item = Object.assign({}, item, {
                    "note": noteText,
                    "popupWidth": popupWidth,
                    "popupHeight": popupHeight
                })
                updatedNoteItem = item
                changed = true
            }
            updatedItems.push(item)
        }

        if (changed) {
            root.dockItems = updatedItems
            syncDockItemsConfiguration()
        }
        return updatedNoteItem
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

        PopupCoordinator {
            id: popupCoordinator
            inPanel: root.inPanel
            dockFallbackAnchor: dockWrapper
            taskStructureSource: root
            taskControllerRef: taskController
            mprisControllerRef: mprisController
            trashIntegrationRef: trashIntegration
            trashContextContentRef: trashContextContent
            notePopupContentRef: notePopupContent
            taskWindowsPopupContentRef: taskWindowsPopupContent
            folderPopupDialogRef: folderPopupDialog
            calendarPopupDialogRef: calendarPopupDialog
            trashMenuDialogRef: trashMenuDialog
            notePopupDialogRef: notePopupDialog
            appActionsDialogRef: appActionsDialog
            taskWindowsDialogRef: taskWindowsDialog
            taskOverflowDialogRef: taskOverflowDialog
            applicationIdentityResolver: function(itemData) {
                return root.applicationIdentityForItem(itemData)
            }
            contextActionsResolver: function(itemData, rows) {
                return root.itemContextActions(itemData, rows)
            }
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
            implicitWidth: root.inPanel ? (dockLayout.implicitWidth + (root.dockBackgroundHorizontalPadding * 2)) : (dockLayout.implicitWidth + root.floatingExtraWidth)
            implicitHeight: root.inPanel ? (dockLayout.implicitHeight + (root.dockBackgroundVerticalPadding * 2)) : (dockLayout.implicitHeight + root.floatingExtraHeight)
            width: root.inPanel ? root.panelPreferredWidth : dockLayout.implicitWidth + root.floatingExtraWidth
            height: root.inPanel ? root.panelPreferredHeight : dockLayout.implicitHeight + root.floatingExtraHeight

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
                spectrumIntensity: root.audioSpectrumIntensity
                spectrumUsePlasmaTheme: root.audioSpectrumUsePlasmaTheme
                spectrumBarCount: root.audioSpectrumBarCount
                spectrumOriginEdge: root.audioSpectrumOrigin === "top"
                    ? Qt.TopEdge
                    : Qt.BottomEdge
                spectrumEdgeInset: root.floatingExtraHeight / 2
                spectrumBarStyle: root.audioSpectrumStyle
                spectrumFlowDirection: root.audioSpectrumFlow
                plasmaBackgroundVisible: !root.audioSpectrumConfigured
                    || root.audioSpectrumBackgroundMode === "plasma"
                customThemeEnabled: root.customDockThemeActive
                customTheme: dockThemeRepository.theme
                // qmllint enable unqualified
                visible: !root.inPanel
            }

            // qmllint disable unqualified
            Item {
                id: panelSpectrumViewport

                readonly property real panelCrossAxisExtent: {
                    const extent = Number(root.verticalPanel ? root.width : root.height)
                    return extent > 0
                        ? extent
                        : (root.verticalPanel ? dockLayout.width : dockLayout.height)
                }

                // The applet allocation excludes Plasma's adaptive floating margin.
                x: root.verticalPanel
                    ? Math.round((parent.width - width) / 2)
                    : dockLayout.x
                y: root.verticalPanel
                    ? dockLayout.y
                    : Math.round((parent.height - height) / 2)
                width: root.verticalPanel
                    ? Math.min(dockLayout.width, panelCrossAxisExtent)
                    : dockLayout.width
                height: root.verticalPanel
                    ? dockLayout.height
                    : Math.min(dockLayout.height, panelCrossAxisExtent)
                clip: true
                visible: root.inPanel

                AudioSpectrumLayer {
                    anchors.fill: parent
                    active: root.inPanel && audioSpectrumController.active
                    levels: audioSpectrumController.levels
                    intensity: root.audioSpectrumIntensity
                    usePlasmaTheme: root.audioSpectrumUsePlasmaTheme
                    barCount: root.audioSpectrumBarCount
                    barStyle: root.audioSpectrumStyle
                    flowDirection: root.audioSpectrumFlow
                    vertical: root.verticalPanel
                    originEdge: root.verticalPanel
                        ? (root.leftPanel ? Qt.LeftEdge : Qt.RightEdge)
                        : root.audioSpectrumOrigin === "top"
                            ? Qt.TopEdge
                            : Qt.BottomEdge
                }
            }
            // qmllint enable unqualified

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
                        customSeparatorEnabled: root.customDockSeparatorActive
                        separatorTheme: root.customDockSeparatorTheme
                        
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
                        preferTaskPopupOnHover: root.windowPreviewStyle !== "none" && taskState.count > 1
                        suppressTooltip: mainContainer.contextMenuVisible
                            || (taskWindowsDialog.visible && popupCoordinator.taskPopupVisualParent === dockItemDelegate)
                        supportsContextMenu: root.itemHasContextMenu(modelData, taskState.rows)
                        
                        onItemClicked: function(cmd) {
                            if (modelData.type === "folder") {
                                popupCoordinator.openFolderPopup(modelData, dockItemDelegate)
                            } else if (modelData.type === "calendar") {
                                popupCoordinator.openCalendarPopup(dockItemDelegate)
                            } else if (modelData.type === "note") {
                                popupCoordinator.openNotePopup(modelData, dockItemDelegate)
                            } else {
                                popupCoordinator.closeAllPopups(null)
                                root.handleDockItemActivation(modelData, dockItemDelegate)
                            }
                        }
                        onContextMenuRequested: function(visualParent, keyboardInvoked) {
                            if (modelData.type === "trash") {
                                popupCoordinator.openTrashMenu(modelData, visualParent, keyboardInvoked)
                            } else if (root.itemHasContextMenu(modelData, taskState.rows)) {
                                popupCoordinator.openAppContextMenu(modelData, visualParent, taskState.rows)
                            }
                        }
                        onHoverEntered: function(visualParent) {
                            if (root.windowPreviewStyle !== "none" && taskState.count > 0) {
                                popupCoordinator.scheduleTaskWindowsPopup(modelData.name || "", taskState.rows, visualParent)
                            }
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
                        preferTaskPopupOnHover: root.windowPreviewStyle !== "none" && taskData.count > 1
                        suppressTooltip: mainContainer.contextMenuVisible
                            || (taskWindowsDialog.visible && popupCoordinator.taskPopupVisualParent === taskDockItemDelegate)
                        supportsContextMenu: root.itemHasContextMenu(modelData, taskData.rows)

                        onItemClicked: function() {
                            popupCoordinator.closeAllPopups(null)
                            if (taskData.count > 1) {
                                taskController.activatePreferredTaskRow(taskData.rows)
                            } else if (taskData.firstRow >= 0) {
                                taskController.activateTaskRow(taskData.firstRow)
                            }
                        }
                        onContextMenuRequested: function(visualParent) {
                            popupCoordinator.openAppContextMenu(modelData, visualParent, taskData.rows)
                        }
                        onHoverEntered: function(visualParent) {
                            if (root.windowPreviewStyle !== "none" && taskData.count > 0) {
                                popupCoordinator.scheduleTaskWindowsPopup(itemName, taskData.rows, visualParent)
                            }
                        }
                        onHoverExited: function(visualParent) {
                            popupCoordinator.cancelPendingTaskWindowsPopup(visualParent)
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

                    onItemClicked: popupCoordinator.openTaskOverflowPopup(taskOverflowDockItem)
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
            backgroundHints: PlasmaCore.Types.StandardBackground

            mainItem: PopupAnimatedContent {
                popupVisible: folderPopupDialog.visible
                // qmllint disable unqualified
                animationStyle: root.popupAnimationStyle
                animationSpeedPercent: root.popupAnimationSpeedPercent
                animationIntensityPercent: root.popupAnimationIntensity
                popupDirection: root.popupDirection
                // qmllint enable unqualified

                FolderPopup {
                    id: folderPopupContent
                    folderItem: popupCoordinator.activeFolderData
                    layoutMode: ["list", "detailed"].indexOf(popupCoordinator.activeFolderData.layout) >= 0
                        ? popupCoordinator.activeFolderData.layout
                        : "grid"
                    maximumAvailableHeight: root.taskPopupAvailableHeight

                    onAppLaunched: function(app) {
                        folderPopupDialog.visible = false
                        root.launchDockItem(app)
                    }

                    onCloseRequested: {
                        folderPopupDialog.visible = false
                    }
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
            backgroundHints: PlasmaCore.Types.NoBackground

            mainItem: PopupAnimatedContent {
                popupVisible: calendarPopupDialog.visible
                // qmllint disable unqualified
                animationStyle: root.popupAnimationStyle
                animationSpeedPercent: root.popupAnimationSpeedPercent
                animationIntensityPercent: root.popupAnimationIntensity
                popupDirection: root.popupDirection
                // qmllint enable unqualified

                CalendarPopup {
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
            hideOnWindowDeactivate: !trashContextContent.confirmationVisible
            backgroundHints: PlasmaCore.Types.StandardBackground

            mainItem: PopupAnimatedContent {
                popupVisible: trashMenuDialog.visible
                // qmllint disable unqualified
                animationStyle: root.popupAnimationStyle
                animationSpeedPercent: root.popupAnimationSpeedPercent
                animationIntensityPercent: root.popupAnimationIntensity
                popupDirection: root.popupDirection
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
                    transitionSpeedPercent: root.contextMenuTransitionSpeed
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
            popupDirection: root.popupDirection
            margin: root.popupMargin
            floating: !root.inPanel
            removeBorderStrategy: root.inPanel
                ? PlasmaCore.AppletPopup.AtScreenEdges | PlasmaCore.AppletPopup.AtPanelEdges
                : PlasmaCore.AppletPopup.AtScreenEdges
            visible: false
            hideOnWindowDeactivate: !popupCoordinator.contextMenuOpening
            backgroundHints: PlasmaCore.Types.NoBackground

            mainItem: PopupAnimatedContent {
                popupVisible: appActionsDialog.visible
                // qmllint disable unqualified
                animationStyle: root.popupAnimationStyle
                animationSpeedPercent: root.popupAnimationSpeedPercent
                animationIntensityPercent: root.popupAnimationIntensity
                popupDirection: root.popupDirection
                // qmllint enable unqualified

                ContextSurfaceStack {
                    id: appActionsSurfaceStack
                    mediaController: mprisController
                    mediaIcon: popupCoordinator.activeAppContextMenuData.icon || "emblem-music-symbolic"
                    maximumAvailableHeight: root.taskPopupAvailableHeight

                    AppActionsPopup {
                        id: appActionsContent
                        itemName: popupCoordinator.activeAppContextMenuData.name || ""
                        actions: popupCoordinator.activeAppContextMenuData.actions || []
                        maxVisibleRows: popupCoordinator.activeAppContextMenuData.maxVisibleRows || 6

                        onActionTriggered: function(action) {
                            appActionsDialog.visible = false
                            root.triggerContextAction(action)
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
                    popupCoordinator.activeNoteData = root.updateNoteItem(popupCoordinator.activeNoteData,
                        notePopupContent.currentText, notePopupContent.activeWidth,
                        notePopupContent.activeHeight)
                }
            }

            mainItem: PopupAnimatedContent {
                popupVisible: notePopupDialog.visible
                // qmllint disable unqualified
                animationStyle: root.popupAnimationStyle
                animationSpeedPercent: root.popupAnimationSpeedPercent
                animationIntensityPercent: root.popupAnimationIntensity
                popupDirection: root.popupDirection
                // qmllint enable unqualified

                NotePopup {
                    id: notePopupContent
                    noteItem: popupCoordinator.activeNoteData
                    onCloseRequested: {
                        notePopupDialog.visible = false
                    }
                    onClearRequested: function(noteText, popupWidth, popupHeight) {
                        notePopupContent.initialText = noteText
                        popupCoordinator.activeNoteData = root.updateNoteItem(
                            popupCoordinator.activeNoteData, noteText, popupWidth, popupHeight)
                    }
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
            backgroundHints: PlasmaCore.Types.NoBackground
            onVisibleChanged: {
                if (!visible) {
                    taskWindowsPopupContent.showPreviews()
                    popupCoordinator.resetTaskPopupState()
                }
            }

            mainItem: PopupAnimatedContent {
                popupVisible: taskWindowsDialog.visible
                // qmllint disable unqualified
                animationStyle: root.popupAnimationStyle
                animationSpeedPercent: root.popupAnimationSpeedPercent
                animationIntensityPercent: root.popupAnimationIntensity
                popupDirection: root.popupDirection
                // qmllint enable unqualified

                ContextSurfaceStack {
                    id: taskContextSurfaceStack
                    mediaController: mprisController
                    mediaIcon: popupCoordinator.activeAppContextMenuData.icon || "emblem-music-symbolic"
                    showMedia: taskWindowsPopupContent.actionsVisible
                    maximumAvailableHeight: root.taskPopupAvailableHeight
                    onImplicitHeightChanged: {
                        if (taskWindowsDialog.visible) {
                            Qt.callLater(popupCoordinator.reanchorTaskWindowsPopup)
                        }
                    }
                    onContainsMouseChanged: {
                        popupCoordinator.setTaskPopupHovered(containsMouse)
                    }

                    TaskContextPopup {
                        id: taskWindowsPopupContent
                        appName: popupCoordinator.activeTaskPopupData.name || ""
                        windows: popupCoordinator.activeTaskPopupData.windows || []
                        previewStyle: root.windowPreviewStyle
                        previewScale: root.windowPreviewScale
                        automaticPopupRadius: root.taskPopupRadiusAuto
                        popupRadius: root.taskPopupRadius
                        popupDirection: root.popupDirection
                        inPanel: root.inPanel
                        maxVisibleRows: root.maxPopupRows
                        maximumAvailableHeight: root.taskPopupAvailableHeight
                        actionItemName: popupCoordinator.activeAppContextMenuData.name || ""
                        actions: popupCoordinator.activeAppContextMenuData.actions || []
                        maxVisibleActionRows: popupCoordinator.activeAppContextMenuData.maxVisibleRows || 6
                        // qmllint disable unqualified
                        transitionSpeedPercent: root.contextMenuTransitionSpeed
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
                        onCloseRequested: {
                            taskWindowsDialog.visible = false
                        }
                        onActionTriggered: function(action) {
                            taskWindowsDialog.visible = false
                            root.triggerContextAction(action)
                        }
                    }
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

            mainItem: PopupAnimatedContent {
                popupVisible: taskOverflowDialog.visible
                // qmllint disable unqualified
                animationStyle: root.popupAnimationStyle
                animationSpeedPercent: root.popupAnimationSpeedPercent
                animationIntensityPercent: root.popupAnimationIntensity
                popupDirection: root.popupDirection
                // qmllint enable unqualified

                TaskOverflowPopup {
                    entries: root.overflowTaskRows
                    maxVisibleRows: root.maxPopupRows

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
