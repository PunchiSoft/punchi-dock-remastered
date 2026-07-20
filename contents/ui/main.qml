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

    // Plasma documents PlasmaCore.Action as the QAction factory for
    // Plasmoid.contextualActions. Qt 6.8 qmllint cannot resolve that type from
    // the installed Plasma metadata and reports cascading property warnings.
    // qmllint disable import
    // qmllint disable missing-property
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18nc("@action:context", "Add Quick Note")
            icon.name: "knotes"
            onTriggered: root.addQuickNote()
        }
    ]
    // qmllint enable missing-property
    // qmllint enable import

    // Base property, initially empty until the configuration is loaded.
    property var dockItems: []
    property string recentlyTransitionedAppId: ""
    property string recentlyTransitionedLauncherUrl: ""
    property bool deletingActiveNote: false
    property int minimizeReactionRevision: 0
    property int minimizeReactionTargetIndex: -1
    readonly property bool dockItemTransitionActive: dockItemTransitionTimer.running
    
    // Host environment detection (panel or floating dock).
    property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    property bool trashHasItems: false
    readonly property var visibleTaskRows: taskController.visibleTaskRows
    readonly property var overflowTaskRows: taskController.overflowTaskRows
    readonly property int taskVisualRevision: taskController.visualRevision
    signal taskStructureChanged()

    Timer {
        id: dockItemTransitionTimer
        interval: 500
        repeat: false
        onTriggered: {
            root.recentlyTransitionedAppId = ""
            root.recentlyTransitionedLauncherUrl = ""
        }
    }

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
        automaticDynamicGroups: root.panelFillLengthEnabled
        dynamicGroupCapacity: root.panelDynamicGroupCapacity
        systemDiscovery: systemDiscovery
        onStructureChanged: root.taskStructureChanged()
    }
    readonly property string currentVirtualDesktopId: String(virtualDesktopInfo.currentDesktop || "")
    readonly property bool singleVirtualDesktopMode: Plasmoid.configuration.virtualDesktopMode === "single"
        && Plasmoid.configuration.targetVirtualDesktop !== ""
    readonly property bool hiddenByVirtualDesktop: singleVirtualDesktopMode
        && currentVirtualDesktopId !== Plasmoid.configuration.targetVirtualDesktop
    property int panelDynamicGroupCapacity: -1
    readonly property int dockSpacing: 8
    readonly property int dockBackgroundHorizontalPadding: 18
    readonly property int dockBackgroundVerticalPadding: 12
    readonly property int floatingExtraWidth: 48
    readonly property int floatingExtraHeight: 32
    readonly property string windowPreviewStyle: String(Plasmoid.configuration.windowPreviewStyle || "card")
    readonly property bool mediaControlsOnHover: !!Plasmoid.configuration.mediaControlsOnHover
    readonly property real windowPreviewScale: Math.max(1.5, Math.min(4.5,
        Number(Plasmoid.configuration.windowPreviewScale || 1.5)))
    readonly property string windowPreviewInfoMode: {
        const mode = String(Plasmoid.configuration.windowPreviewInfoMode || "full")
        return mode === "icon" || mode === "none" ? mode : "full"
    }
    readonly property bool showWindowThumbnails: windowPreviewStyle === "thumbnail"
    readonly property int maxPopupRows: Math.max(1, Math.min(8,
        Number(Plasmoid.configuration.maxPopupRows || 4)))
    readonly property int taskPopupAvailableHeight: Math.max(240,
        Number(root.availableScreenRect.height || 640) - (root.inPanel ? root.panelPreferredHeight : 0) - 24)
    readonly property int taskPopupAvailableWidth: Math.max(280,
        Number(root.availableScreenRect.width || 800) - 48)
    readonly property bool dockShowLabels: !!Plasmoid.configuration.showLabels
    readonly property bool dockShowItemHoverBackground:
        Plasmoid.configuration.showItemHoverBackground !== false
    readonly property bool dockIconReflectionsEnabled: (!inPanel || horizontalPanel)
        && !dockShowLabels
        && !!Plasmoid.configuration.iconReflectionsEnabled
    readonly property real dockIconReflectionOpacity: {
        const configuredPercent = Number(
            Plasmoid.configuration.iconReflectionOpacity)
        const safePercent = Number.isFinite(configuredPercent)
            ? configuredPercent
            : 22
        return Math.max(5, Math.min(50, safePercent)) / 100.0
    }
    readonly property int dockLabelFontSize: Math.max(10, Math.round(effectiveIconSize * 0.22))
    readonly property int dockLabelAreaHeight: dockShowLabels ? (dockLabelFontSize + 12) : 0
    readonly property string dockClickEffect: String(Plasmoid.configuration.clickEffect || "none")
    readonly property string dockWindowMinimizeEffect: {
        const configuredEffect = String(Plasmoid.configuration.windowMinimizeEffect || "none")
        return ["none", "slowBounce", "lateralRipple"].indexOf(configuredEffect) >= 0
            ? configuredEffect
            : "none"
    }
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
    // PanelView exposes lengthMode as a Q_PROPERTY. Bracket access keeps this
    // guarded when the plasmoid is hosted by a different kind of window. The
    // generic QQuickWindow metadata used by qmllint cannot declare this
    // PanelView-specific property.
    // qmllint disable missing-property
    readonly property int detectedPanelLengthMode: {
        try {
            const panelWindow = root.Window.window
            if (!root.inPanel || !panelWindow
                    || typeof panelWindow["lengthMode"] === "undefined") {
                return -1
            }
            const lengthMode = Number(panelWindow["lengthMode"])
            return Number.isFinite(lengthMode) ? lengthMode : -1
        } catch (error) {
            return -1
        }
    }
    // qmllint enable missing-property
    readonly property bool panelUsesFillAvailable: detectedPanelLengthMode === 0
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
    readonly property bool panelFillLengthEnabled: inPanel
        && horizontalPanel
        && panelUsesFillAvailable
        && !hiddenByVirtualDesktop
        && Plasmoid.configuration.panelLengthMode === "fill"
    readonly property int panelItemWidth: Math.ceil(Math.max(effectiveIconSize + 12, dockShowLabels ? effectiveIconSize * 1.85 : 0))
    readonly property int panelItemHeight: Math.ceil(effectiveIconSize + 12 + dockLabelAreaHeight)
    readonly property int panelHoverCrossAxisExtent: Math.ceil(horizontalPanel
        ? (effectiveIconSize * panelHoverScale) + 12 + dockLabelAreaHeight
        : Math.max(panelItemWidth, (effectiveIconSize * panelHoverScale) + 12))

    function panelWidthForDockItem(item) {
        const itemType = item && item.type ? String(item.type) : "app"
        if (itemType === "separator") {
            return 10
        }
        if (itemType === "spacer") {
            return Math.max(12, effectiveIconSize * 0.5)
        }
        return panelItemWidth
    }

    readonly property int panelFixedContentWidth: {
        let extent = 0
        const items = dockItems || []
        for (let index = 0; index < items.length; index++) {
            extent += panelWidthForDockItem(items[index])
        }
        return Math.ceil(extent + (Math.max(0, items.length - 1) * dockSpacing))
    }
    readonly property int renderedDynamicItemCount: visibleTaskRows.length
        + (overflowTaskRows.length > 0 ? 1 : 0)
    readonly property int panelCompactContentWidth: {
        const boundarySpacing = dockItems.length > 0 && renderedDynamicItemCount > 0
            ? dockSpacing
            : 0
        const dynamicWidth = renderedDynamicItemCount > 0
            ? (renderedDynamicItemCount * panelItemWidth)
                + (Math.max(0, renderedDynamicItemCount - 1) * dockSpacing)
            : 0
        return Math.ceil(panelFixedContentWidth + boundarySpacing + dynamicWidth)
    }
    readonly property int panelMinimumContentWidth: {
        const hasDynamicGroups = taskController.totalDynamicGroups > 0
        const boundarySpacing = dockItems.length > 0 && hasDynamicGroups ? dockSpacing : 0
        return Math.ceil(panelFixedContentWidth + boundarySpacing
            + (hasDynamicGroups ? panelItemWidth : 0))
    }
    readonly property int panelContentWidth: panelFillLengthEnabled
        ? panelMinimumContentWidth
        : Math.max(panelItemWidth, panelCompactContentWidth)
    readonly property int panelContentHeight: panelItemHeight
    readonly property int panelMinimumWidth: hiddenByVirtualDesktop
        ? 0
        : Math.ceil((verticalPanel ? Math.max(panelContentWidth, panelHoverCrossAxisExtent) : panelContentWidth)
            + (dockBackgroundHorizontalPadding * 2))
    readonly property int panelMinimumHeight: hiddenByVirtualDesktop
        ? 0
        : Math.ceil(horizontalPanel
            ? panelContentHeight
            : panelContentHeight + (dockBackgroundVerticalPadding * 2))
    readonly property int panelPreferredWidth: hiddenByVirtualDesktop
        ? 0
        : panelMinimumWidth
    readonly property int panelPreferredHeight: hiddenByVirtualDesktop
        ? 0
        : panelMinimumHeight
    readonly property real panelReflectionAvailableExtent: {
        if (!inPanel || !horizontalPanel) {
            return -1
        }

        const allocatedHeight = Math.max(panelItemHeight,
            Number(root.height || 0) > 0 ? Number(root.height) : panelPreferredHeight)
        const outerBottomMargin = Math.max(0,
            (allocatedHeight - panelItemHeight) / 2)
        const itemBottomMargin = Math.max(0,
            (panelItemHeight - effectiveIconSize) / 2)
        return outerBottomMargin + itemBottomMargin
    }

    implicitWidth: inPanel ? panelPreferredWidth : 0
    implicitHeight: inPanel ? panelPreferredHeight : 0
    switchWidth: inPanel ? panelPreferredWidth : Math.ceil(panelItemWidth)
    switchHeight: inPanel ? panelPreferredHeight : Math.ceil(panelItemHeight)

    Layout.fillWidth: panelFillLengthEnabled
    Layout.fillHeight: inPanel && horizontalPanel && !hiddenByVirtualDesktop
    Layout.minimumWidth: inPanel ? panelMinimumWidth : -1
    Layout.minimumHeight: inPanel ? panelMinimumHeight : -1
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

    function itemContextActions(item, taskRows, itemOrigin, persistentIndex) {
        if (!item || (item.type || "app") !== "app") {
            return []
        }

        const actions = []
        const seenNames = {}
        if (itemOrigin === "dynamic") {
            const pinDescriptor = taskController.pinDescriptorForEntry(item)
            if (pinDescriptor && !taskController.dockContainsPinDescriptor(pinDescriptor)) {
                appendUniqueContextActions(actions, [{
                    "name": i18nc("@action:context", "Pin to Dock"),
                    "icon": "window-pin",
                    "kind": "pinToDock",
                    "enabled": true,
                    "pinDescriptor": pinDescriptor
                }], seenNames)
            }
        } else if (itemOrigin === "pinned") {
            appendUniqueContextActions(actions, [{
                "name": i18nc("@action:context", "Unpin from Dock"),
                "icon": "window-pin",
                "kind": "unpinFromDock",
                "enabled": true,
                "targetIndex": persistentIndex,
                "targetApplicationId": taskController.dockItemApplicationId(item),
                "targetLauncherUrl": taskController.dockItemLauncherUrl(item)
            }], seenNames)
        }

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

    function itemHasContextMenu(item, taskRows, itemOrigin) {
        if (!item || (item.type || "app") !== "app") {
            return false
        }
        return itemOrigin === "pinned"
            || (itemOrigin === "dynamic" && !!taskController.pinDescriptorForEntry(item))
            || String(item.storageId || item.appId || item.command || "").trim().length > 0
            || (item.actions instanceof Array && item.actions.length > 0)
            || (taskRows instanceof Array && taskRows.length > 0)
    }

    function triggerContextAction(action) {
        if (!action || action.enabled === false) {
            return false
        }
        if (action.kind === "pinToDock") {
            return root.pinTaskToDock(action.pinDescriptor)
        }
        if (action.kind === "unpinFromDock") {
            return root.unpinItemFromDock(action.targetIndex,
                action.targetApplicationId, action.targetLauncherUrl)
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

    function pinTaskToDock(descriptor) {
        if (!descriptor || String(descriptor.storageId || "").trim().length === 0
                || taskController.dockContainsPinDescriptor(descriptor)) {
            return false
        }

        const pinnedItem = {
            "type": "app",
            "name": String(descriptor.name || i18n("Application")),
            "icon": String(descriptor.icon || "application-x-executable"),
            "storageId": String(descriptor.storageId),
            "appId": String(descriptor.appId || "")
        }
        const command = String(descriptor.command || "").trim()
        if (command.length > 0) {
            pinnedItem.command = command
        }
        root.recentlyTransitionedAppId = taskController.normalizeApplicationId(
            descriptor.appId || descriptor.storageId || "")
        root.recentlyTransitionedLauncherUrl = taskController.normalizeLauncherUrl(
            "applications:" + descriptor.storageId)
        dockItemTransitionTimer.restart()
        root.dockItems = root.dockItems.concat([pinnedItem])
        syncDockItemsConfiguration()
        return true
    }

    function unpinItemFromDock(targetIndex, expectedApplicationId, expectedLauncherUrl) {
        const index = Number(targetIndex)
        if (!Number.isInteger(index) || index < 0 || index >= root.dockItems.length) {
            return false
        }

        const dockItem = root.dockItems[index]
        const actualApplicationId = taskController.dockItemApplicationId(dockItem)
        const actualLauncherUrl = taskController.dockItemLauncherUrl(dockItem)
        const normalizedExpectedApplicationId = taskController.normalizeApplicationId(
            expectedApplicationId || "")
        const normalizedExpectedLauncherUrl = taskController.normalizeLauncherUrl(
            expectedLauncherUrl || "")
        if (normalizedExpectedApplicationId.length > 0
                && actualApplicationId !== normalizedExpectedApplicationId) {
            return false
        }
        if (normalizedExpectedLauncherUrl.length > 0
                && actualLauncherUrl !== normalizedExpectedLauncherUrl) {
            return false
        }

        root.recentlyTransitionedAppId = actualApplicationId
        root.recentlyTransitionedLauncherUrl = actualLauncherUrl
        dockItemTransitionTimer.restart()
        root.dockItems = root.dockItems.slice(0, index)
            .concat(root.dockItems.slice(index + 1))
        syncDockItemsConfiguration()
        return true
    }

    function addQuickNote() {
        const noteItem = {
            "type": "note",
            "name": i18nc("@title", "Quick Note"),
            "icon": "knotes",
            "note": "",
            "popupWidth": 380,
            "popupHeight": 260
        }
        root.dockItems = root.dockItems.concat([noteItem])
        syncDockItemsConfiguration()
        return noteItem
    }

    function triggerMinimizeReaction(itemIndex) {
        if (root.dockWindowMinimizeEffect === "none" || itemIndex < 0) {
            return
        }

        root.minimizeReactionTargetIndex = itemIndex
        root.minimizeReactionRevision += 1
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

    function removeNoteItemAtIndex(targetIndex) {
        const index = Number(targetIndex)
        if (!Number.isInteger(index) || index < 0 || index >= root.dockItems.length
                || !root.dockItems[index] || root.dockItems[index].type !== "note") {
            return false
        }

        root.dockItems = root.dockItems.slice(0, index)
            .concat(root.dockItems.slice(index + 1))
        syncDockItemsConfiguration()
        return true
    }

    fullRepresentation: Item {
        id: mainContainer
        // fullRepresentation is compiled as a nested component, so qmllint
        // cannot resolve accesses to the owning PlasmoidItem even though
        // Plasma provides that lexical context at runtime.
        // qmllint disable unqualified
        visible: !root.hiddenByVirtualDesktop
        enabled: visible
        implicitWidth: visible ? root.panelPreferredWidth : 0
        implicitHeight: visible ? root.panelPreferredHeight : 0
        Layout.fillWidth: root.panelFillLengthEnabled
        Layout.fillHeight: root.inPanel && root.horizontalPanel && visible
        Layout.minimumWidth: root.panelMinimumWidth
        Layout.minimumHeight: root.panelMinimumHeight
        Layout.preferredWidth: root.panelPreferredWidth
        Layout.preferredHeight: root.panelPreferredHeight
        // qmllint enable unqualified

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
            taskContextSurfaceStackRef: taskContextSurfaceStack
            taskPopupAnimatedContentRef: taskPopupAnimatedContent
            mediaHoverEnabled: root.mediaControlsOnHover
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
            // qmllint disable unqualified
            contextActionsResolver: function(itemData, rows, itemOrigin, persistentIndex) {
                return root.itemContextActions(itemData, rows, itemOrigin, persistentIndex)
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
                ? root.panelPreferredWidth
                : dockLayout.implicitWidth + dockLayout.trailingOverflowExtent
                    + root.floatingExtraWidth
            implicitHeight: root.inPanel ? root.panelPreferredHeight : dockLayout.implicitHeight + root.floatingExtraHeight
            width: root.inPanel ? parent.width : implicitWidth
            height: root.inPanel ? parent.height : implicitHeight

            readonly property int dynamicTaskSlotCapacity: {
                if (!root.panelFillLengthEnabled) {
                    return -1
                }

                const innerWidth = Math.max(0, width
                    - (root.dockBackgroundHorizontalPadding * 2))
                const boundarySpacing = root.dockItems.length > 0
                    && taskController.totalDynamicGroups > 0
                    ? root.dockSpacing
                    : 0
                const availableWidth = Math.max(0, innerWidth
                    - root.panelFixedContentWidth - boundarySpacing)
                return Math.max(0, Math.floor((availableWidth + root.dockSpacing)
                    / (root.panelItemWidth + root.dockSpacing)))
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
                    : (root.panelFillLengthEnabled
                        ? Math.max(0, parent.width - x
                            - root.dockBackgroundHorizontalPadding)
                        : dockLayout.width)
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
                // The row is part of fullRepresentation and resolves its
                // trailing sibling through the owning representation.
                // qmllint disable unqualified
                readonly property real trailingOverflowExtent: overflowLayoutAnchor.visible
                    ? root.dockSpacing + overflowLayoutAnchor.width
                    : 0
                // qmllint enable unqualified
                x: {
                    if (!root.inPanel) {
                        return Math.round((parent.width - width - trailingOverflowExtent) / 2)
                    }
                    if (root.panelFillLengthEnabled) {
                        return root.dockBackgroundHorizontalPadding
                    }
                    if (root.leftPanel) {
                        return root.dockBackgroundHorizontalPadding
                    }
                    if (root.rightPanel) {
                        return parent.width - width - trailingOverflowExtent
                            - root.dockBackgroundHorizontalPadding
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
                        // qmllint disable unqualified
                        windowMinimizeEffect: root.dockWindowMinimizeEffect
                        taskMinimizedCount: taskState.minimizedCount
                        minimizeReactionRevision: root.minimizeReactionRevision
                        minimizeReactionTargetIndex: root.minimizeReactionTargetIndex
                        showItemHoverBackground: root.dockShowItemHoverBackground
                        iconReflectionEnabled: root.dockIconReflectionsEnabled
                        iconReflectionOpacity: root.dockIconReflectionOpacity
                        iconReflectionAvailableExtent: root.panelReflectionAvailableExtent
                        // qmllint enable unqualified
                        // The delegate is compiled as a nested component by
                        // qmllint; these bindings resolve the owning plasmoid at runtime.
                        // qmllint disable unqualified
                        positionTransitionEnabled: root.dockItemTransitionActive
                        animateEntry: {
                            const appId = taskController.dockItemApplicationId(modelData)
                            const launcherUrl = taskController.dockItemLauncherUrl(modelData)
                            return (root.recentlyTransitionedAppId.length > 0
                                    && appId === root.recentlyTransitionedAppId)
                                || (root.recentlyTransitionedLauncherUrl.length > 0
                                    && launcherUrl === root.recentlyTransitionedLauncherUrl)
                        }
                        // qmllint enable unqualified
                        showPersistentLabel: root.dockShowLabels
                        labelFontSize: root.dockLabelFontSize
                        indicatorType: root.dockIndicatorType
                        indicatorPosition: root.dockIndicatorPosition
                        indicatorThickness: root.dockIndicatorThickness
                        indicatorOpacity: root.dockIndicatorOpacity
                        popupDirection: root.popupDirection
                        customSeparatorEnabled: root.customDockSeparatorActive
                        separatorTheme: root.customDockSeparatorTheme
                        
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
                        iconName: modelData.type === "trash" && modelData.showState !== false
                            ? (root.trashHasItems ? (modelData.fullIcon || "user-trash-full") : (modelData.icon || "user-trash"))
                            : (modelData.icon || "")
                        itemName: modelData.name || ""
                        itemCommand: modelData.command || ""
                        taskIndicatorCount: taskState.count
                        taskIsActive: taskState.isActive
                        taskDemandsAttention: taskState.demandsAttention
                        suppressTooltip: mainContainer.contextMenuVisible
                            || (taskWindowsDialog.visible && popupCoordinator.taskPopupVisualParent === dockItemDelegate)
                        supportsContextMenu: root.itemHasContextMenu(modelData, taskState.rows, "pinned")
                        mediaHoverControlsEnabled: root.mediaControlsOnHover && taskState.count > 0

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
                                popupCoordinator.openCalendarPopup(dockItemDelegate)
                            } else if (modelData.type === "note") {
                                popupCoordinator.openNotePopup(modelData, dockItemDelegate, index)
                            } else {
                                popupCoordinator.closeAllPopups(null)
                                root.handleDockItemActivation(modelData, dockItemDelegate)
                            }
                        }
                        // qmllint disable unqualified
                        onTaskMinimized: function(minimizedItemIndex) {
                            root.triggerMinimizeReaction(minimizedItemIndex)
                        }
                        // qmllint enable unqualified
                        onContextMenuRequested: function(visualParent, keyboardInvoked) {
                            if (modelData.type === "trash") {
                                popupCoordinator.openTrashMenu(modelData, visualParent, keyboardInvoked)
                            } else if (root.itemHasContextMenu(modelData, taskState.rows, "pinned")) {
                                popupCoordinator.openAppContextMenu(modelData, visualParent,
                                    taskState.rows, "pinned", index)
                            }
                        }
                        onHoverEntered: function(visualParent) {
                            if ((root.mediaControlsOnHover || root.windowPreviewStyle !== "none")
                                    && taskState.count > 0) {
                                popupCoordinator.scheduleTaskWindowsPopup(modelData.name || "",
                                    taskState.rows, visualParent, false,
                                    root.windowPreviewStyle !== "none")
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

                        itemIndex: root.dockItems.length + index
                        hoveredIndex: dockLayout.hoveredIndex
                        inPanel: root.inPanel
                        panelLocation: root.panelLocation
                        iconSize: root.effectiveIconSize
                        hoverScaleSetting: root.panelHoverScale
                        hoverAnimationMode: Plasmoid.configuration.hoverAnimation || "wave"
                        clickEffect: root.dockClickEffect
                        // qmllint disable unqualified
                        windowMinimizeEffect: root.dockWindowMinimizeEffect
                        taskMinimizedCount: taskData.minimizedCount
                        minimizeReactionRevision: root.minimizeReactionRevision
                        minimizeReactionTargetIndex: root.minimizeReactionTargetIndex
                        showItemHoverBackground: root.dockShowItemHoverBackground
                        iconReflectionEnabled: root.dockIconReflectionsEnabled
                        iconReflectionOpacity: root.dockIconReflectionOpacity
                        iconReflectionAvailableExtent: root.panelReflectionAvailableExtent
                        // qmllint enable unqualified
                        // qmllint disable unqualified
                        positionTransitionEnabled: root.dockItemTransitionActive
                        animateEntry: {
                            const appIds = modelData.appIds instanceof Array
                                ? modelData.appIds
                                : [String(modelData.appId || "")]
                            const launcherUrls = modelData.launcherUrls instanceof Array
                                ? modelData.launcherUrls
                                : [String(modelData.launcherUrl || "")]
                            return (root.recentlyTransitionedAppId.length > 0
                                    && appIds.indexOf(root.recentlyTransitionedAppId) >= 0)
                                || (root.recentlyTransitionedLauncherUrl.length > 0
                                    && launcherUrls.indexOf(root.recentlyTransitionedLauncherUrl) >= 0)
                        }
                        // qmllint enable unqualified
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
                        suppressTooltip: mainContainer.contextMenuVisible
                            || (taskWindowsDialog.visible && popupCoordinator.taskPopupVisualParent === taskDockItemDelegate)
                        supportsContextMenu: root.itemHasContextMenu(modelData, taskData.rows, "dynamic")
                        mediaHoverControlsEnabled: root.mediaControlsOnHover && taskData.count > 0

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
                            root.triggerMinimizeReaction(minimizedItemIndex)
                        }
                        // qmllint enable unqualified
                        onContextMenuRequested: function(visualParent) {
                            popupCoordinator.openAppContextMenu(modelData, visualParent,
                                taskData.rows, "dynamic", -1)
                        }
                        onHoverEntered: function(visualParent) {
                            if ((root.mediaControlsOnHover || root.windowPreviewStyle !== "none")
                                    && taskData.count > 0) {
                                popupCoordinator.scheduleTaskWindowsPopup(itemName,
                                    taskData.rows, visualParent, false,
                                    root.windowPreviewStyle !== "none")
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
                x: root.panelFillLengthEnabled
                    ? parent.width - root.dockBackgroundHorizontalPadding - width
                    : dockLayout.x + dockLayout.width + root.dockSpacing
                y: dockLayout.y

                // DockItem coordinates its wave hover state through its parent.
                property alias hoveredIndex: dockLayout.hoveredIndex
                property alias mouseOffset: dockLayout.mouseOffset

                DockItem {
                    id: taskOverflowDockItem
                    width: implicitWidth
                    height: implicitHeight
                    itemIndex: root.dockItems.length + root.visibleTaskRows.length
                    hoveredIndex: dockLayout.hoveredIndex
                    inPanel: root.inPanel
                    panelLocation: root.panelLocation
                    iconSize: root.effectiveIconSize
                    hoverScaleSetting: root.panelHoverScale
                    hoverAnimationMode: Plasmoid.configuration.hoverAnimation || "wave"
                    clickEffect: root.dockClickEffect
                    windowMinimizeEffect: root.dockWindowMinimizeEffect
                    taskMinimizedCount: {
                        root.taskVisualRevision
                        return taskController.minimizedCountForRows(
                            taskController.taskRowsForEntries(root.overflowTaskRows))
                    }
                    minimizeReactionRevision: root.minimizeReactionRevision
                    minimizeReactionTargetIndex: root.minimizeReactionTargetIndex
                    showItemHoverBackground: root.dockShowItemHoverBackground
                    iconReflectionEnabled: root.dockIconReflectionsEnabled
                    iconReflectionOpacity: root.dockIconReflectionOpacity
                    iconReflectionAvailableExtent: root.panelReflectionAvailableExtent
                    positionTransitionEnabled: root.dockItemTransitionActive
                    popupDirection: root.popupDirection
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
                        root.triggerMinimizeReaction(minimizedItemIndex)
                    }
                }
            }
            // qmllint enable unqualified
        }

        // Controlled AppletPopup usage: Plasma anchors the popup outside the panel.
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

        // Calendar popup.
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
            // The calendar always uses the native KDE theme background, like Kickoff.
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
                    showMedia: false
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
                if (!visible && !root.deletingActiveNote
                        && notePopupContent.currentText !== notePopupContent.initialText) {
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
                    onDeleteRequested: {
                        root.deletingActiveNote = true
                        notePopupDialog.visible = false
                        if (root.removeNoteItemAtIndex(popupCoordinator.activeNoteIndex)) {
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
            popupDirection: root.popupDirection
            margin: root.popupMargin
            floating: !root.inPanel
            removeBorderStrategy: root.inPanel
                ? PlasmaCore.AppletPopup.AtScreenEdges | PlasmaCore.AppletPopup.AtPanelEdges
                : PlasmaCore.AppletPopup.AtScreenEdges
            visible: false
            hideOnWindowDeactivate: true
            backgroundHints: PlasmaCore.Types.NoBackground
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
                animationStyle: root.popupAnimationStyle
                animationSpeedPercent: root.popupAnimationSpeedPercent
                animationIntensityPercent: root.popupAnimationIntensity
                popupDirection: root.popupDirection
                // qmllint enable unqualified
                onCloseAnimationFinished: taskWindowsDialog.visible = false

                ContextSurfaceStack {
                    id: taskContextSurfaceStack
                    visible: taskWindowsDialog.visible
                    enabled: visible
                    mediaController: mprisController
                    mediaIcon: popupCoordinator.activeTaskPopupData.icon || "emblem-music-symbolic"
                    showMedia: popupCoordinator.mediaHoverActive
                    mediaOnly: popupCoordinator.mediaHoverActive
                        && !taskWindowsPopupContent.mediaActionsComposed
                    forceCompactMedia: popupCoordinator.mediaHoverActive
                        && taskWindowsPopupContent.mediaActionsComposed
                    transitionsEnabled: root.popupAnimationStyle !== "none"
                    transitionSpeedPercent: root.contextMenuTransitionSpeed
                    maximumAvailableHeight: root.taskPopupAvailableHeight
                    onImplicitHeightChanged: {
                        if (taskWindowsDialog.visible) {
                            Qt.callLater(popupCoordinator.reanchorTaskWindowsPopup)
                        }
                    }
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
                        previewStyle: root.windowPreviewStyle
                        previewScale: root.windowPreviewScale
                        previewInfoMode: root.windowPreviewInfoMode
                        maxVisibleRows: root.maxPopupRows
                        maximumAvailableWidth: root.taskPopupAvailableWidth
                        maximumAvailableHeight: root.taskPopupAvailableHeight
                        actionItemName: popupCoordinator.activeAppContextMenuData.name || ""
                        actions: popupCoordinator.activeAppContextMenuData.actions || []
                        maxVisibleActionRows: popupCoordinator.activeAppContextMenuData.maxVisibleRows || 6
                        previewsEnabled: taskWindowsDialog.visible
                            && !popupCoordinator.mediaHoverActive
                        returnToMedia: popupCoordinator.mediaHoverActive
                        transitionsEnabled: root.popupAnimationStyle !== "none"
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
