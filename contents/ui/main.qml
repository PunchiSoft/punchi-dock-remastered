pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.taskmanager as TaskManager
import org.kde.kirigami as Kirigami
import org.kde.kwindowsystem
import "org/punchi/dock" as Punchi
import "components"
import "components/punchimenu"
import "config/code/configItems.js" as ConfigItemsJS

PlasmoidItem {
    id: root
    objectName: "punchiDockRoot"

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    toolTipMainText: ""
    toolTipSubText: ""
    preferredRepresentation: fullRepresentation
    compactRepresentation: fullRepresentation

    onExpandedChanged: {
        // A dock hosted in a panel owns its popups and must never expose its
        // full representation through Plasma's generic activation lifecycle.
        if (root.inPanel && root.configuredPunchiMenuItem && root.expanded) {
            root.expanded = false
        }
    }

    // Plasma documents PlasmaCore.Action as the QAction factory for
    // Plasmoid.contextualActions. Qt 6.8 qmllint cannot resolve that type from
    // the installed Plasma metadata and reports cascading property warnings.
    // qmllint disable import
    // qmllint disable missing-property
    // qmllint disable unqualified
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
        },
        PlasmaCore.Action {
            visible: !root.inPanel
            text: i18n("Plasma theme")
            icon.name: "preferences-desktop-theme-global"
            checkable: true
            checked: String(Plasmoid.configuration.dockThemeMode || "plasma") === "plasma"
            onTriggered: Plasmoid.configuration.dockThemeMode = "plasma"
        },
        PlasmaCore.Action {
            visible: !root.inPanel
                && String(Plasmoid.configuration.dockThemeCustomId || "").length > 0
            text: i18n("External JSON theme")
            icon.name: "preferences-desktop-theme-global"
            checkable: true
            checked: String(Plasmoid.configuration.dockThemeMode || "plasma") === "custom"
            onTriggered: Plasmoid.configuration.dockThemeMode = "custom"
        }
        // qmllint enable unqualified
    ]
    // qmllint enable missing-property
    // qmllint enable import

    property bool deletingActiveNote: false
    property var dynamicApplicationsMoveModeTarget: null
    readonly property bool dynamicApplicationsMoveModeActive:
        !!dynamicApplicationsMoveModeTarget
        && dynamicApplicationsMoveModeTarget.dynamicApplicationsMoveModeActive

    function requestDynamicApplicationsMoveMode() {
        const target = root.dynamicApplicationsMoveModeTarget
        if (!target || typeof target.enterDynamicApplicationsMoveMode
                !== "function" || root.dynamicApplicationsMarkerIndex < 0) {
            return false
        }
        Qt.callLater(function() {
            if (root.dynamicApplicationsMoveModeTarget === target
                    && typeof target.enterDynamicApplicationsMoveMode
                        === "function") {
                target.enterDynamicApplicationsMoveMode()
            }
        })
        return true
    }
    
    // Host environment detection (panel or floating dock).
    property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool floatingVertical: !inPanel
        && String(Plasmoid.configuration.floatingDockOrientation || "horizontal") === "vertical"
    property var floatingDockAnchor: null
    property bool floatingOrientationReady: false
    property bool mediaItemExpanded: true
    readonly property var visibleTaskRows: taskController.visibleTaskRows
    readonly property var overflowTaskRows: taskController.overflowTaskRows
    readonly property int dynamicApplicationsMarkerIndex: {
        const items = dockItemsController.dockItems || []
        for (let index = 0; index < items.length; index++) {
            if (items[index]
                    && items[index].type === "dynamic-applications") {
                return index
            }
        }
        return -1
    }
    readonly property int dynamicApplicationsAnchorIndex:
        dynamicApplicationsMarkerIndex >= 0
            ? dynamicApplicationsMarkerIndex
            : dockItemsController.dockItems.length
    readonly property int renderedOverflowItemCount:
        overflowTaskRows.length > 0 ? 1 : 0
    readonly property int taskVisualRevision: taskController.visualRevision
    readonly property var dockItemsControllerService: dockItemsController
    readonly property var configuredMediaItem: {
        const items = dockItemsController.dockItems || []
        for (let index = 0; index < items.length; index++) {
            if (items[index] && items[index].type === "media") {
                return items[index]
            }
        }
        return null
    }
    readonly property string configuredMediaApplicationId: configuredMediaItem
        ? String(configuredMediaItem.defaultPlayerAppId
            || configuredMediaItem.defaultPlayerStorageId || "").substring(0, 512)
        : ""
    readonly property int configuredPunchiMenuItemIndex: {
        const items = dockItemsController.dockItems || []
        for (let index = 0; index < items.length; index++) {
            if (items[index] && items[index].type === "punchimenu") {
                return index
            }
        }
        return -1
    }
    readonly property var configuredPunchiMenuItem: configuredPunchiMenuItemIndex >= 0
        ? (dockItemsController.dockItems || [])[configuredPunchiMenuItemIndex]
        : null
    readonly property real configuredPunchiMenuGridIconScale: {
        const requestedPercent = Number(configuredPunchiMenuItem
            ? configuredPunchiMenuItem.gridIconScalePercent
            : 100)
        const safePercent = Number.isFinite(requestedPercent)
            ? Math.max(75, Math.min(150, Math.round(requestedPercent / 5) * 5))
            : 100
        return safePercent / 100
    }
    readonly property real configuredPunchiMenuFavoriteIconScale: {
        const requestedPercent = Number(configuredPunchiMenuItem
            ? configuredPunchiMenuItem.favoriteIconScalePercent
            : 100)
        const safePercent = Number.isFinite(requestedPercent)
            ? Math.max(75, Math.min(110, Math.round(requestedPercent / 5) * 5))
            : 100
        return safePercent / 100
    }
    readonly property int configuredPunchiMenuNormalFolderMaximumColumns: {
        const requestedCount = Number(configuredPunchiMenuItem
            ? configuredPunchiMenuItem.normalFolderMaximumColumns
            : 3)
        return Number.isFinite(requestedCount)
            ? Math.max(1, Math.min(3, Math.round(requestedCount)))
            : 3
    }
    readonly property int configuredPunchiMenuNormalFolderMaximumRows: {
        const requestedCount = Number(configuredPunchiMenuItem
            ? configuredPunchiMenuItem.normalFolderMaximumRows
            : 3)
        return Number.isFinite(requestedCount)
            ? Math.max(1, Math.min(3, Math.round(requestedCount)))
            : 3
    }
    readonly property int configuredPunchiMenuFullScreenFolderMaximumColumns: {
        const requestedCount = Number(configuredPunchiMenuItem
            ? configuredPunchiMenuItem.fullScreenFolderMaximumColumns
            : 5)
        return Number.isFinite(requestedCount)
            ? Math.max(1, Math.min(5, Math.round(requestedCount)))
            : 5
    }
    readonly property int configuredPunchiMenuFullScreenFolderMaximumRows: {
        const requestedCount = Number(configuredPunchiMenuItem
            ? configuredPunchiMenuItem.fullScreenFolderMaximumRows
            : 5)
        return Number.isFinite(requestedCount)
            ? Math.max(1, Math.min(5, Math.round(requestedCount)))
            : 5
    }
    readonly property bool configuredPunchiMenuShowDistributionName:
        !configuredPunchiMenuItem
        || configuredPunchiMenuItem.showDistributionName !== false
    readonly property bool configuredPunchiMenuShowPageNavigationArrows:
        !configuredPunchiMenuItem
        || configuredPunchiMenuItem.showPageNavigationArrows !== false
    readonly property bool configuredPunchiMenuShowApplicationLabels:
        !configuredPunchiMenuItem
        || configuredPunchiMenuItem.showApplicationLabels !== false
    readonly property string configuredPunchiMenuHoverAnimation:
        ConfigItemsJS.normalizedPunchiMenuHoverAnimation(
            configuredPunchiMenuItem
                ? configuredPunchiMenuItem.hoverAnimation : "pulse")
    readonly property bool configuredPunchiMenuSortApplicationsAlphabetically:
        !!configuredPunchiMenuItem
        && configuredPunchiMenuItem.sortApplicationsAlphabetically === true
    readonly property string configuredPunchiMenuFullScreenApplicationOrder:
        ConfigItemsJS.normalizedPunchiMenuFullScreenApplicationOrder(
            configuredPunchiMenuItem
                ? configuredPunchiMenuItem.fullScreenApplicationOrder : "",
            configuredPunchiMenuSortApplicationsAlphabetically)
    readonly property string configuredPunchiMenuFullScreenCloseButtonPosition:
        configuredPunchiMenuItem
            && configuredPunchiMenuItem.fullScreenCloseButtonPosition === "left"
        ? "left"
        : "right"
    readonly property bool configuredPunchiMenuFullScreenBlurEnabled:
        !configuredPunchiMenuItem
        || configuredPunchiMenuItem.fullScreenBlurEnabled !== false
    readonly property real configuredPunchiMenuFullScreenBackgroundOpacity: {
        const requestedPercent = Number(configuredPunchiMenuItem
            ? configuredPunchiMenuItem.fullScreenBackgroundOpacityPercent
            : 50)
        const safePercent = Number.isFinite(requestedPercent)
            ? Math.max(50, Math.min(100, Math.round(requestedPercent / 5) * 5))
            : 50
        return safePercent / 100
    }
    readonly property bool configuredPunchiMenuNormalBlurEnabled:
        !configuredPunchiMenuItem
        || configuredPunchiMenuItem.normalBlurEnabled !== false
    readonly property real configuredPunchiMenuNormalBackgroundOpacity: {
        const requestedPercent = Number(configuredPunchiMenuItem
            ? configuredPunchiMenuItem.normalBackgroundOpacityPercent
            : 75)
        const safePercent = Number.isFinite(requestedPercent)
            ? Math.max(50, Math.min(100, Math.round(requestedPercent / 5) * 5))
            : 75
        return safePercent / 100
    }
    readonly property var configuredPunchiMenuHiddenApplicationIds: {
        const source = configuredPunchiMenuItem
                && configuredPunchiMenuItem.hiddenApplicationIds instanceof Array
            ? configuredPunchiMenuItem.hiddenApplicationIds
            : []
        const result = []
        const seen = {}
        for (let index = 0; index < source.length && result.length < 512; index++) {
            const storageId = String(source[index] || "").trim()
            if (storageId.length === 0 || storageId.length > 512
                    || /[\u0000-\u001f\u007f]/.test(storageId)) {
                continue
            }
            const comparisonKey = "#" + storageId
            if (seen[comparisonKey] === true) {
                continue
            }
            seen[comparisonKey] = true
            result.push(storageId)
        }
        return result
    }
    readonly property bool configuredPunchiMenuCompactBlurEnabled:
        !configuredPunchiMenuItem
        || configuredPunchiMenuItem.compactBlurEnabled !== false
    readonly property real configuredPunchiMenuCompactBackgroundOpacity: {
        const requestedPercent = Number(configuredPunchiMenuItem
            ? configuredPunchiMenuItem.compactBackgroundOpacityPercent
            : 85)
        const safePercent = Number.isFinite(requestedPercent)
            ? Math.max(50, Math.min(100, Math.round(requestedPercent / 5) * 5))
            : 85
        return safePercent / 100
    }
    readonly property bool configuredPunchiMenuCompactShowQuickLaunchers: {
        const item = configuredPunchiMenuItem
        if (item && item.compactShowQuickLaunchers !== undefined) {
            return item.compactShowQuickLaunchers !== false
        }
        return true
    }
    readonly property string configuredPunchiMenuMode: {
        const itemMode = configuredPunchiMenuItem
            ? String(configuredPunchiMenuItem.menuMode || "normal")
            : "normal"
        if (itemMode === "compact") {
            return "compact"
        }
        if (itemMode === "normal") {
            return "normal"
        }
        return "fullScreen"
    }
    readonly property string configuredPunchiMenuNormalPlacementMode:
        configuredPunchiMenuItem
            && String(configuredPunchiMenuItem.normalPlacementMode || "anchored")
                === "centered"
        ? "centered"
        : "anchored"
    readonly property int configuredPunchiMenuNormalWidthPercent: {
        const requestedPercent = Number(configuredPunchiMenuItem
            ? configuredPunchiMenuItem.normalWidthPercent
            : 55)
        return Number.isFinite(requestedPercent)
            ? Math.max(30, Math.min(90, Math.round(requestedPercent / 5) * 5))
            : 55
    }
    readonly property int configuredPunchiMenuNormalHeightPercent: {
        const requestedPercent = Number(configuredPunchiMenuItem
            ? configuredPunchiMenuItem.normalHeightPercent
            : 65)
        return Number.isFinite(requestedPercent)
            ? Math.max(30, Math.min(90, Math.round(requestedPercent / 5) * 5))
            : 65
    }
    readonly property int configuredPunchiMenuNormalPanelDistancePercent: {
        const requestedPercent = Number(configuredPunchiMenuItem
            ? configuredPunchiMenuItem.normalPanelDistancePercent
            : 25)
        return Number.isFinite(requestedPercent)
            ? Math.max(0, Math.min(100,
                Math.round(requestedPercent / 5) * 5))
            : 25
    }
    readonly property int configuredPunchiMenuNormalPanelGap:
        dockGeometry.popupGapForPercent(
            root.configuredPunchiMenuNormalPanelDistancePercent)
    readonly property bool configuredPunchiMenuNormalShowCategories: {
        const item = configuredPunchiMenuItem
        if (item && item.normalShowCategories !== undefined) {
            return item.normalShowCategories !== false
        }
        return true
    }
    readonly property bool configuredPunchiMenuNormalCategoryGrouping: {
        const item = configuredPunchiMenuItem
        if (item && item.normalCategoryGrouping !== undefined) {
            return item.normalCategoryGrouping === true
        }
        return false
    }
    signal taskStructureChanged()

    function persistentVisualIndex(modelIndex) {
        const index = Number(modelIndex)
        if (root.dynamicApplicationsMarkerIndex < 0
                || index <= root.dynamicApplicationsMarkerIndex) {
            return index
        }
        return index + root.visibleTaskRows.length
            + root.renderedOverflowItemCount
    }

    function dynamicVisualIndex(taskIndex) {
        return root.dynamicApplicationsAnchorIndex
            + (root.dynamicApplicationsMarkerIndex >= 0 ? 1 : 0)
            + Number(taskIndex)
    }

    function dynamicLauncherInsertionIndex() {
        return root.dynamicApplicationsMarkerIndex >= 0
            ? root.dynamicApplicationsMarkerIndex
            : dockItemsController.dockItems.length
    }

    function dockItemReorderIconName(item) {
        const itemData = item || ({})
        const configuredIcon = String(itemData.icon || "")
        if (configuredIcon.length > 0) {
            return configuredIcon
        }
        const type = String(itemData.type || "")
        if (type === "dynamic-applications") {
            return "window-duplicate"
        }
        if (type === "separator") {
            return "draw-line"
        }
        if (type === "spacer") {
            return "distribute-horizontal-x"
        }
        if (type === "calendar") {
            return "view-calendar-day"
        }
        if (type === "note") {
            return "knotes"
        }
        if (type === "folder") {
            return "folder"
        }
        if (type === "trash") {
            return "user-trash"
        }
        if (type === "punchimenu") {
            return "start-here-kde"
        }
        return "application-x-executable"
    }

    // Virtual desktop visibility.
    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }
    Punchi.SystemDiscovery {
        id: systemDiscovery
        onApplicationCatalogReady: function(applications) {
            const storageIds = []
            const catalog = []
            const seenStorageIds = {}
            const source = applications || []
            for (let index = 0; index < source.length && index < 1024; index++) {
                const application = source[index]
                const storageId = String(application
                    ? application.storageId || ""
                    : "")
                if (storageId.length > 0
                        && !seenStorageIds["#" + storageId]) {
                    seenStorageIds["#" + storageId] = true
                    storageIds.push(storageId)
                    catalog.push({
                        storageId: storageId,
                        name: String(application.name || storageId),
                        icon: String(application.icon
                            || "application-x-executable"),
                        categories: application.categories || []
                    })
                }
            }
            root.punchiMenuApplicationCatalog = catalog
            root.punchiMenuApplicationCatalogLoaded = true
            punchiMenuLayoutController.applicationStorageIds = storageIds
        }
        onOperationFailed: function(operation, message) {
            console.warn("Punchi Dock:", operation, message)
        }
    }
    readonly property var systemDiscoveryService: systemDiscovery
    readonly property var punchiMenuLayoutControllerService: punchiMenuLayoutController
    property var punchiMenuApplicationCatalog: []
    property bool punchiMenuApplicationCatalogLoaded: false
    Punchi.DockRuntimeService {
        id: runtimeService
        onOperationFailed: function(operation, message) {
            console.warn("Punchi Dock:", operation, message)
        }
    }
    Punchi.DockItemsPersistenceAdapter {
        id: dockItemsPersistenceAdapter
        applet: root.plasmoid
    }
    Punchi.PunchiMenuLayoutController {
        id: punchiMenuLayoutController

        onPersistenceRequested: function(transactionId, document, operation, subjectId) {
            const result = dockItemsController.commitPunchiMenuApplicationLayout(
                punchiMenuLayoutController.layoutDocument, document)
            if (result && result.success) {
                punchiMenuLayoutController.confirmPersistence(transactionId)
            } else {
                const errorCode = result
                    ? String(result.errorCode || "persist-failed")
                    : "persist-failed"
                punchiMenuLayoutController.rejectPersistence(
                    transactionId, errorCode)
                if (result && (errorCode === "conflict"
                        || errorCode === "layout-conflict"
                        || errorCode === "persistence-failed")) {
                    const reconciliation
                        = dockItemsPersistenceAdapter.reconcileDockItemsJson(
                            String(result.currentJson || ""))
                    if (!reconciliation || !reconciliation.success) {
                        console.warn(
                            "Punchi Dock: Unable to reconcile dock item configuration after a persistence conflict.")
                    }
                }
            }
        }
    }
    Punchi.MprisController {
        id: mprisController
    }
    Punchi.MprisController {
        id: dockMediaController
        selectionMode: root.configuredMediaApplicationId.length > 0
            ? "application"
            : "activePlayer"
        applicationId: root.configuredMediaApplicationId
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
        verticalPanel: root.inPanel ? Plasmoid.formFactor === PlasmaCore.Types.Vertical : root.floatingVertical
        horizontalPanel: root.inPanel ? Plasmoid.formFactor === PlasmaCore.Types.Horizontal : !root.floatingVertical
        panelLocation: root.floatingVertical ? PlasmaCore.Types.LeftEdge : Plasmoid.location
        configuredIconSize: Number(Plasmoid.configuration.iconSize || 48)
        configuredIconSpacing: {
            const spacing = Number(Plasmoid.configuration.iconSpacing)
            return Number.isFinite(spacing) ? spacing : 8
        }
        configuredPanelLengthMode: String(Plasmoid.configuration.panelLengthMode || "fit")
        configuredPanelAlignmentMode: String(Plasmoid.configuration.panelAlignmentMode || "start")
        panelHoverScale: dockConfig.panelHoverScale
        folderPopupDistancePercent: dockConfig.folderPopupDistancePercent
        contextMenuDistancePercent: dockConfig.contextMenuDistancePercent
        dockShowLabels: dockConfig.dockShowLabels
        dockLabelAreaHeight: dockConfig.dockLabelAreaHeight
        dockItems: dockItemsController.dockItems
        mediaItemExpanded: root.mediaItemExpanded
        visibleTaskCount: root.visibleTaskRows.length
        overflowTaskCount: root.overflowTaskRows.length
        totalDynamicGroups: taskController.totalDynamicGroups
        dynamicApplicationsMoveModeActive:
            root.dynamicApplicationsMoveModeActive
        availableScreenRect: root.availableScreenRect
        floatingAnchor: root.floatingDockAnchor
        hostHeight: root.height
        // PanelView and containment expose these properties at runtime.
        // qmllint disable missing-property
        panelWindow: root.Window.window
        containment: Plasmoid.containment
        // qmllint enable missing-property
    }
    Punchi.PanelLengthModeBridge {
        containmentId: Plasmoid.containment ? Plasmoid.containment.id : 0
        reportedPanelLengthMode: dockGeometry.detectedPanelLengthMode
    }
    Punchi.TaskGeometryOwnershipBridge {
        id: taskGeometryOwnership
        instanceId: Plasmoid.id
        panel: root.inPanel
        eligible: !root.hiddenByVirtualDesktop
    }
    Punchi.PunchiMenuShortcutController {
        id: punchiMenuShortcutController
        instanceId: Plasmoid.id
        configuredShortcut: String(Plasmoid.configuration.punchiMenuShortcut || "")
        enabled: Boolean(root.configuredPunchiMenuItem)
        onActivated: {
            if (root.configuredPunchiMenuItem) {
                root.togglePunchiMenu()
            }
        }
        onShortcutRegistrationFailed: function(requestedShortcut) {
            console.warn("Punchi Dock: PunchiMenu shortcut registration failed:",
                requestedShortcut)
        }
    }
    Punchi.AudioSpectrumController {
        id: audioSpectrumController
        enabled: dockConfig.audioSpectrumConfigured
            && !root.hiddenByVirtualDesktop
    }

    property var punchiMenuDialogInstance: null
    property var punchiMenuAnchorItem: null

    function togglePunchiMenu(anchorItem) {
        if (anchorItem && typeof anchorItem.mapToGlobal === "function") {
            root.punchiMenuAnchorItem = anchorItem
        }
        const requestedMode = root.configuredPunchiMenuMode
        if (punchiMenuDialogInstance
                && punchiMenuDialogInstance.menuMode !== requestedMode) {
            punchiMenuDialogInstance.closeImmediately()
            punchiMenuDialogInstance.destroy()
            punchiMenuDialogInstance = null
        }

        if ((requestedMode === "normal" || requestedMode === "compact") && anchorItem
                && punchiMenuDialogInstance
                && typeof punchiMenuDialogInstance.consumeRecentExternalHide
                    === "function"
                && punchiMenuDialogInstance.consumeRecentExternalHide()) {
            return
        }

        if (!punchiMenuDialogInstance) {
            const component = requestedMode === "normal"
                ? punchiMenuNormalDialogComponent
                : (requestedMode === "compact"
                    ? punchiMenuCompactDialogComponent
                    : punchiMenuFullscreenDialogComponent)
            punchiMenuDialogInstance = component.createObject(root)
            if (!punchiMenuDialogInstance) {
                return
            }
        }

        if (requestedMode === "fullScreen"
                && punchiMenuDialogInstance.openedFromPanel !== undefined) {
            punchiMenuDialogInstance.openedFromPanel = root.inPanel
        }

        if (punchiMenuDialogInstance.visible) {
            if (typeof punchiMenuDialogInstance.closeWithFade === "function") {
                punchiMenuDialogInstance.closeWithFade()
            } else {
                punchiMenuDialogInstance.closeImmediately()
            }
        } else {
            punchiMenuDialogInstance.openWithReveal()
        }
    }

    Component {
        id: punchiMenuFullscreenDialogComponent

        PlasmaCore.Dialog {
            id: punchiMenuDialog
            readonly property string menuMode: "fullScreen"
            readonly property bool isX11Session: KWindowSystem.isPlatformX11
            property bool openedFromPanel: false
            location: PlasmaCore.Types.Floating
            type: PlasmaCore.Dialog.Normal
            flags: openedFromPanel
                ? Qt.Window | Qt.FramelessWindowHint
                : isX11Session
                    ? Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
                    : Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
            backgroundHints: PlasmaCore.Dialog.NoBackground
            x: 0
            y: 0
            width: Screen.width
            height: Screen.height
            hideOnWindowDeactivate: true
            visible: false
            opacity: 0

            function openWithReveal() {
                opacity = 1
                visible = true
                requestActivate()
                punchiMenuOverlay.openOverlay()
                if (KWindowSystem.isPlatformX11) {
                    Qt.callLater(function() {
                        if (punchiMenuDialog.visible) {
                            punchiMenuDialog.requestActivate()
                            punchiMenuOverlay.forceActiveFocus()
                        }
                    })
                }
            }

            function closeImmediately() {
                punchiMenuOverlay.resetOverlay()
                opacity = 0
                visible = false
            }

            onVisibleChanged: {
                if (!visible) {
                    punchiMenuOverlay.resetOverlay()
                    opacity = 0
                }
            }

            mainItem: PunchiMenuOverlay {
                id: punchiMenuOverlay
                width: Screen.width
                height: Screen.height
                systemDiscovery: root.systemDiscoveryService
                applicationCatalog: root.punchiMenuApplicationCatalog
                // qmllint disable unqualified
                applicationCatalogLoaded:
                    root.punchiMenuApplicationCatalogLoaded
                // qmllint enable unqualified
                applicationLayoutController:
                    root.punchiMenuLayoutControllerService
                // qmllint disable unqualified
                dockItemsController: root.dockItemsControllerService
                favorites: punchiMenuFavoritesController.favorites
                applicationIconScale: root.configuredPunchiMenuGridIconScale
                favoriteIconScale: root.configuredPunchiMenuFavoriteIconScale
                folderMaximumColumns:
                    root.configuredPunchiMenuFullScreenFolderMaximumColumns
                folderMaximumRows:
                    root.configuredPunchiMenuFullScreenFolderMaximumRows
                showDistributionName: root.configuredPunchiMenuShowDistributionName
                showPageNavigationArrows:
                    root.configuredPunchiMenuShowPageNavigationArrows
                showApplicationLabels:
                    root.configuredPunchiMenuShowApplicationLabels
                hoverAnimation: root.configuredPunchiMenuHoverAnimation
                applicationOrderMode:
                    root.configuredPunchiMenuFullScreenApplicationOrder
                closeButtonPosition:
                    root.configuredPunchiMenuFullScreenCloseButtonPosition
                backgroundBlurEnabled: root.configuredPunchiMenuFullScreenBlurEnabled
                backgroundOpacity: root.configuredPunchiMenuFullScreenBackgroundOpacity
                hiddenApplicationIds: root.configuredPunchiMenuHiddenApplicationIds
                onAddFavoriteRequested: function(storageId) {
                    punchiMenuFavoritesController.addFavorite(storageId)
                }
                onRemoveFavoriteRequested: function(storageId) {
                    punchiMenuFavoritesController.removeFavorite(storageId)
                }
                onPinToDockRequested: function(storageId, appName, appIcon, appCommand) {
                    punchiMenuOverlay.showOperationResult(
                        root.dockItemsControllerService.togglePinAppToDock(
                            storageId, appName, appIcon, appCommand))
                }
                onAddToDesktopRequested: function(storageId, appCommand) {
                    punchiMenuOverlay.showOperationResult(
                        root.dockItemsControllerService.pinAppToDesktop(storageId, appCommand))
                }
                onSetApplicationHiddenRequested: function(storageId, hidden) {
                    if (!root.dockItemsControllerService.setPunchiMenuApplicationHidden(
                            storageId, hidden)) {
                        punchiMenuOverlay.showOperationResult(
                            root.dockItemsControllerService.operationResult(
                            false, "persist-failed", ""))
                    }
                }
                onSettingChangeRequested: function(fieldName, value) {
                    if (!root.dockItemsControllerService.setPunchiMenuValue(
                            fieldName, value)) {
                        punchiMenuOverlay.showSettingsPersistenceError()
                    }
                }
                onConfigureRequested: {
                    const itemIndex = root.configuredPunchiMenuItemIndex
                    punchiMenuDialog.closeImmediately()
                    Qt.callLater(function() {
                        root.openDockItemEditor(itemIndex)
                    })
                }
                onCloseFinished: punchiMenuDialog.closeImmediately()
                // qmllint enable unqualified
            }
        }
    }

    Component {
        id: punchiMenuNormalDialogComponent

        PlasmaCore.Dialog {
            id: punchiMenuNormalDialog

            readonly property string menuMode: "normal"
            readonly property bool isX11Session: KWindowSystem.isPlatformX11
            property double lastExternalHideTimestamp: -1
            property bool internalCloseRequested: false
            readonly property int screenMargin: Kirigami.Units.gridUnit * 2
            readonly property int minimumContentWidth:
                Kirigami.Units.gridUnit * 22
            readonly property int minimumContentHeight:
                Kirigami.Units.gridUnit * 16
            readonly property real reportedAvailableWidth: Math.max(
                Number(Screen.desktopAvailableWidth || 0),
                Number(Screen.width || 0))
            readonly property real reportedAvailableHeight: Math.max(
                Number(Screen.desktopAvailableHeight || 0),
                Number(Screen.height || 0))
            readonly property int safeScreenWidth: reportedAvailableWidth > 1
                ? Math.round(reportedAvailableWidth)
                : minimumContentWidth + screenMargin
                    + Kirigami.Units.largeSpacing * 2
            readonly property int safeScreenHeight: reportedAvailableHeight > 1
                ? Math.round(reportedAvailableHeight)
                : minimumContentHeight + screenMargin
                    + Kirigami.Units.largeSpacing * 2
            readonly property int usableScreenWidth: Math.max(1,
                safeScreenWidth - screenMargin)
            readonly property int usableScreenHeight: Math.max(1,
                safeScreenHeight - screenMargin)
            readonly property int desiredContentWidth: Math.min(
                Math.max(1, usableScreenWidth - Kirigami.Units.largeSpacing * 2),
                Math.max(minimumContentWidth,
                    Math.round(safeScreenWidth
                        * root.configuredPunchiMenuNormalWidthPercent / 100)))
            readonly property int desiredContentHeight: Math.min(
                Math.max(1, usableScreenHeight - Kirigami.Units.largeSpacing * 2),
                Math.max(minimumContentHeight,
                    Math.round(safeScreenHeight
                        * root.configuredPunchiMenuNormalHeightPercent / 100)))

            // The normal menu is a lazily created component whose owner ids
            // remain available in the plasmoid runtime context.
            // qmllint disable unqualified
            // PunchiMenuNormalPlacement owns the final window coordinates.
            // A visualParent makes PlasmaQuick::Dialog recompute popupPosition()
            // after our configured panel gap has already been applied.
            visualParent: null
            location: PlasmaCore.Types.Floating
            type: PlasmaCore.Dialog.PopupMenu
            flags: isX11Session
                ? Qt.Popup | Qt.FramelessWindowHint
                : Qt.Dialog | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
            backgroundHints: PlasmaCore.Dialog.NoBackground
            hideOnWindowDeactivate: true
            visible: false
            opacity: 0

            readonly property Punchi.BlurBehindController normalBlurController:
                Punchi.BlurBehindController {
                    window: punchiMenuNormalDialog
                    fullWindow: false
                    maskSource: punchiMenuNormal.backgroundBlurMaskSource
                    useMaskSourceInsets: true
                    maskOffset: punchiMenuNormal.backgroundBlurMaskOffset
                    enabled: punchiMenuNormalDialog.visible
                        && root.configuredPunchiMenuNormalBlurEnabled
                }

            readonly property PunchiMenuNormalPlacement normalPlacement: PunchiMenuNormalPlacement {

                inPanel: root.inPanel
                placementMode: root.configuredPunchiMenuNormalPlacementMode
                panelLocation: dockGeometry.effectivePanelLocation
                availableScreenRect: root.availableScreenRect
                screenGeometry: Plasmoid.containment
                    && Plasmoid.containment.screenGeometry
                    ? Plasmoid.containment.screenGeometry
                    : Qt.rect(0, 0, Screen.width, Screen.height)
                itemAnchor: root.punchiMenuAnchorItem
                floatingDockAnchor: root.floatingDockAnchor
                panelWindow: root.Window.window
                panelThickness: dockGeometry.detectedPanelThickness
                menuWidth: punchiMenuNormalDialog.width
                menuHeight: punchiMenuNormalDialog.height
                panelGap: root.configuredPunchiMenuNormalPanelGap
                floatingGap: root.configuredPunchiMenuNormalPanelGap
                screenInset: root.configuredPunchiMenuNormalPlacementMode === "anchored"
                    ? root.configuredPunchiMenuNormalPanelGap
                    : 0
                themeFrameLeftMargin: punchiMenuNormalDialog.themeFrameMargin("left")
                themeFrameTopMargin: punchiMenuNormalDialog.themeFrameMargin("top")
                themeFrameRightMargin: punchiMenuNormalDialog.themeFrameMargin("right")
                themeFrameBottomMargin: punchiMenuNormalDialog.themeFrameMargin("bottom")
                surfaceFrameLeftMargin: root.inPanel
                    ? 0 : dockBackground.backgroundFrameInset("left")
                surfaceFrameTopMargin: root.inPanel
                    ? 0 : dockBackground.backgroundFrameInset("top")
                surfaceFrameRightMargin: root.inPanel
                    ? 0 : dockBackground.backgroundFrameInset("right")
                surfaceFrameBottomMargin: root.inPanel
                    ? 0 : dockBackground.backgroundFrameInset("bottom")
            }

            function positionAtAnchor() {
                const targetPosition = normalPlacement.calculatePosition()
                x = targetPosition.x
                y = targetPosition.y
            }

            function scheduleReposition() {
                if (visible) {
                    Qt.callLater(positionAtAnchor)
                }
            }

            function themeFrameMargin(side) {
                const nativeMargins = margins
                const requestedMargin = nativeMargins
                    ? Number(nativeMargins[side])
                    : 0
                return Number.isFinite(requestedMargin)
                    ? Math.max(0, requestedMargin)
                    : 0
            }

            onWidthChanged: scheduleReposition()
            onHeightChanged: scheduleReposition()

            readonly property Connections configurationConnections: Connections {
                target: root
                function onConfiguredPunchiMenuNormalPlacementModeChanged() {
                    punchiMenuNormalDialog.scheduleReposition()
                }
                function onConfiguredPunchiMenuNormalWidthPercentChanged() {
                    punchiMenuNormalDialog.scheduleReposition()
                }
                function onConfiguredPunchiMenuNormalHeightPercentChanged() {
                    punchiMenuNormalDialog.scheduleReposition()
                }
                function onConfiguredPunchiMenuNormalPanelGapChanged() {
                    punchiMenuNormalDialog.scheduleReposition()
                }
                function onConfiguredPunchiMenuNormalBlurEnabledChanged() {
                    Qt.callLater(function() {
                        punchiMenuNormalDialog.normalBlurController.reapply()
                    })
                }
            }

            function consumeRecentExternalHide() {
                const hideTimestamp = lastExternalHideTimestamp
                lastExternalHideTimestamp = -1
                if (hideTimestamp < 0) {
                    return false
                }
                const elapsed = Date.now() - hideTimestamp
                // QtStyleHints exposes this property at runtime, but qmllint
                // resolves Qt.styleHints as a generic QObject.
                // qmllint disable missing-property
                const guardInterval = Math.max(1,
                    Qt.styleHints.mouseDoubleClickInterval)
                // qmllint enable missing-property
                return elapsed >= 0
                    && elapsed <= guardInterval
            }

            function finishOpening() {
                if (!visible) {
                    return
                }
                positionAtAnchor()
                opacity = 1
                requestActivate()
                Qt.callLater(function() {
                    punchiMenuNormalDialog.normalBlurController.reapply()
                })
                punchiMenuFavoritesController.refresh()
                punchiMenuNormal.openMenu()
            }

            function openWithReveal() {
                internalCloseRequested = false
                lastExternalHideTimestamp = -1
                opacity = 0
                positionAtAnchor()
                visible = true
                Qt.callLater(finishOpening)
            }

            readonly property Timer normalDialogCloseTimer: Timer {
                id: normalDialogCloseTimer
                interval: 160
                repeat: false
                onTriggered: {
                    punchiMenuNormalDialog.closeImmediately()
                }
            }

            function closeWithFade() {
                if (!visible || normalDialogCloseTimer.running) {
                    return
                }
                internalCloseRequested = true
                punchiMenuNormal.forceClose()
                normalDialogCloseTimer.restart()
            }

            function closeImmediately() {
                normalDialogCloseTimer.stop()
                internalCloseRequested = true
                lastExternalHideTimestamp = -1
                punchiMenuNormal.resetMenu()
                opacity = 0
                visible = false
                Qt.callLater(function() {
                    punchiMenuNormalDialog.internalCloseRequested = false
                })
            }

            onVisibleChanged: {
                if (!visible) {
                    if (!internalCloseRequested) {
                        lastExternalHideTimestamp = Date.now()
                    }
                    punchiMenuNormal.resetMenu()
                    opacity = 0
                }
            }

            // qmllint disable unqualified
            mainItem: PunchiMenuNormal {
                id: punchiMenuNormal
                width: punchiMenuNormalDialog.desiredContentWidth
                height: punchiMenuNormalDialog.desiredContentHeight
                Layout.minimumWidth: punchiMenuNormalDialog.desiredContentWidth
                Layout.preferredWidth: punchiMenuNormalDialog.desiredContentWidth
                Layout.maximumWidth: punchiMenuNormalDialog.desiredContentWidth
                Layout.minimumHeight: punchiMenuNormalDialog.desiredContentHeight
                Layout.preferredHeight: punchiMenuNormalDialog.desiredContentHeight
                Layout.maximumHeight: punchiMenuNormalDialog.desiredContentHeight
                systemDiscovery: root.systemDiscoveryService
                applicationCatalog: root.punchiMenuApplicationCatalog
                applicationLayoutController:
                    root.punchiMenuLayoutControllerService
                dockItemsController: root.dockItemsControllerService
                applicationIconScale: root.configuredPunchiMenuGridIconScale
                favoriteIconScale: root.configuredPunchiMenuFavoriteIconScale
                folderMaximumColumns:
                    root.configuredPunchiMenuNormalFolderMaximumColumns
                folderMaximumRows:
                    root.configuredPunchiMenuNormalFolderMaximumRows
                showApplicationLabels:
                    root.configuredPunchiMenuShowApplicationLabels
                hoverAnimation: root.configuredPunchiMenuHoverAnimation
                sortApplicationsAlphabetically:
                    root.configuredPunchiMenuSortApplicationsAlphabetically
                backgroundBlurEnabled:
                    root.configuredPunchiMenuNormalBlurEnabled
                backgroundOpacity: root.configuredPunchiMenuNormalBackgroundOpacity
                normalPlacementMode:
                    root.configuredPunchiMenuNormalPlacementMode
                normalPanelDistancePercent:
                    root.configuredPunchiMenuNormalPanelDistancePercent
                normalWidthPercent: root.configuredPunchiMenuNormalWidthPercent
                normalHeightPercent: root.configuredPunchiMenuNormalHeightPercent
                showCategories: root.configuredPunchiMenuNormalShowCategories
                categoryGroupingEnabled: root.configuredPunchiMenuNormalCategoryGrouping
                themeFrameLeftMargin: punchiMenuNormalDialog.themeFrameMargin("left")
                themeFrameTopMargin: punchiMenuNormalDialog.themeFrameMargin("top")
                themeFrameRightMargin: punchiMenuNormalDialog.themeFrameMargin("right")
                themeFrameBottomMargin: punchiMenuNormalDialog.themeFrameMargin("bottom")
                favorites: punchiMenuFavoritesController.favorites
                favoriteLimitReached: punchiMenuFavoritesController.limitReached
                hiddenApplicationIds: root.configuredPunchiMenuHiddenApplicationIds
                onAddFavoriteRequested: function(storageId) {
                    punchiMenuFavoritesController.addFavorite(storageId)
                }
                onRemoveFavoriteRequested: function(storageId) {
                    punchiMenuFavoritesController.removeFavorite(storageId)
                }
                onPinToDockRequested: function(storageId, appName, appIcon, appCommand) {
                    punchiMenuNormal.showOperationResult(
                        root.dockItemsControllerService.togglePinAppToDock(
                            storageId, appName, appIcon, appCommand))
                }
                onAddToDesktopRequested: function(storageId, appCommand) {
                    punchiMenuNormal.showOperationResult(
                        root.dockItemsControllerService.pinAppToDesktop(storageId, appCommand))
                }
                onSetApplicationHiddenRequested: function(storageId, hidden) {
                    if (!root.dockItemsControllerService.setPunchiMenuApplicationHidden(
                            storageId, hidden)) {
                        punchiMenuNormal.showOperationResult(
                            root.dockItemsControllerService.operationResult(
                                false, "persist-failed", ""))
                    }
                }
                onSettingChangeRequested: function(fieldName, value) {
                    if (!root.dockItemsControllerService.setPunchiMenuValue(
                            fieldName, value)) {
                        punchiMenuNormal.showSettingsPersistenceError()
                    }
                }
                onConfigureRequested: {
                    const itemIndex = root.configuredPunchiMenuItemIndex
                    punchiMenuNormalDialog.closeImmediately()
                    Qt.callLater(function() {
                        root.openDockItemEditor(itemIndex)
                    })
                }
                onCloseFinished: punchiMenuNormalDialog.closeImmediately()
            }
            // qmllint enable unqualified
        }
    }

    Component {
        id: punchiMenuCompactDialogComponent

        PlasmaCore.Dialog {
            id: punchiMenuCompactDialog

            readonly property string menuMode: "compact"
            readonly property bool isX11Session: KWindowSystem.isPlatformX11
            property double lastExternalHideTimestamp: -1
            property bool internalCloseRequested: false

            readonly property int defaultContentWidth: Math.round(punchiMenuCompact.implicitWidth)
            readonly property int defaultContentHeight: Math.round(punchiMenuCompact.implicitHeight)

            readonly property int desiredContentWidth: Math.max(
                Math.round(Kirigami.Units.gridUnit * 15),
                defaultContentWidth)
            readonly property int desiredContentHeight: Math.max(
                Math.round(Kirigami.Units.gridUnit * 15),
                defaultContentHeight)

            // qmllint disable unqualified
            visualParent: null
            location: PlasmaCore.Types.Floating
            type: PlasmaCore.Dialog.PopupMenu
            flags: isX11Session
                ? Qt.Popup | Qt.FramelessWindowHint
                : Qt.Dialog | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
            backgroundHints: PlasmaCore.Dialog.NoBackground
            hideOnWindowDeactivate: true
            visible: false
            opacity: 0

            readonly property Punchi.BlurBehindController compactBlurController:
                Punchi.BlurBehindController {
                    window: punchiMenuCompactDialog
                    fullWindow: false
                    maskSource: punchiMenuCompact.backgroundBlurMaskSource
                    useMaskSourceInsets: true
                    maskOffset: punchiMenuCompact.backgroundBlurMaskOffset
                    enabled: punchiMenuCompactDialog.visible
                        && root.configuredPunchiMenuCompactBlurEnabled
                }

            readonly property PunchiMenuNormalPlacement compactPlacement: PunchiMenuNormalPlacement {
                inPanel: root.inPanel
                placementMode: "anchored"
                panelLocation: dockGeometry.effectivePanelLocation
                availableScreenRect: root.availableScreenRect
                screenGeometry: Plasmoid.containment
                    && Plasmoid.containment.screenGeometry
                    ? Plasmoid.containment.screenGeometry
                    : Qt.rect(0, 0, Screen.width, Screen.height)
                itemAnchor: root.punchiMenuAnchorItem
                floatingDockAnchor: root.floatingDockAnchor
                panelWindow: root.Window.window
                panelThickness: dockGeometry.detectedPanelThickness
                menuWidth: punchiMenuCompactDialog.width
                menuHeight: punchiMenuCompactDialog.height
                horizontalAnchorWidth: punchiMenuCompact.primarySurfaceWidth
                panelGap: root.configuredPunchiMenuNormalPanelGap
                floatingGap: root.configuredPunchiMenuNormalPanelGap
                screenInset: root.configuredPunchiMenuNormalPanelGap
                themeFrameLeftMargin: punchiMenuCompactDialog.themeFrameMargin("left")
                themeFrameTopMargin: punchiMenuCompactDialog.themeFrameMargin("top")
                themeFrameRightMargin: punchiMenuCompactDialog.themeFrameMargin("right")
                themeFrameBottomMargin: punchiMenuCompactDialog.themeFrameMargin("bottom")
                surfaceFrameLeftMargin: root.inPanel
                    ? 0 : dockBackground.backgroundFrameInset("left")
                surfaceFrameTopMargin: root.inPanel
                    ? 0 : dockBackground.backgroundFrameInset("top")
                surfaceFrameRightMargin: root.inPanel
                    ? 0 : dockBackground.backgroundFrameInset("right")
                surfaceFrameBottomMargin: root.inPanel
                    ? 0 : dockBackground.backgroundFrameInset("bottom")
            }

            function positionAtAnchor() {
                const targetPosition = compactPlacement.calculatePosition()
                x = targetPosition.x
                y = targetPosition.y
            }

            function scheduleReposition() {
                if (visible) {
                    Qt.callLater(positionAtAnchor)
                }
            }

            function themeFrameMargin(side) {
                const nativeMargins = margins
                const requestedMargin = nativeMargins
                    ? Number(nativeMargins[side])
                    : 0
                return Number.isFinite(requestedMargin)
                    ? Math.max(0, requestedMargin)
                    : 0
            }

            onWidthChanged: scheduleReposition()
            onHeightChanged: scheduleReposition()

            function recordExternalHide() {
                lastExternalHideTimestamp = Date.now()
            }

            function consumeRecentExternalHide() {
                if (lastExternalHideTimestamp <= 0) {
                    return false
                }
                const elapsedMs = Date.now() - lastExternalHideTimestamp
                lastExternalHideTimestamp = -1
                return elapsedMs >= 0 && elapsedMs < 350
            }

            readonly property Connections configurationConnections: Connections {
                target: root
                function onInPanelChanged() {
                    punchiMenuCompactDialog.scheduleReposition()
                }
                function onPunchiMenuAnchorItemChanged() {
                    punchiMenuCompactDialog.scheduleReposition()
                }
                function onFloatingDockAnchorChanged() {
                    punchiMenuCompactDialog.scheduleReposition()
                }
                function onConfiguredPunchiMenuNormalPanelGapChanged() {
                    punchiMenuCompactDialog.scheduleReposition()
                }
                function onConfiguredPunchiMenuCompactBlurEnabledChanged() {
                    if (punchiMenuCompactDialog.visible) {
                        punchiMenuCompactDialog.compactBlurController.reapply()
                    }
                }
            }

            readonly property Connections dockGeometryConnections: Connections {
                target: dockGeometry
                function onDetectedPanelThicknessChanged() {
                    punchiMenuCompactDialog.scheduleReposition()
                }
                function onEffectivePanelLocationChanged() {
                    punchiMenuCompactDialog.scheduleReposition()
                }
            }

            onVisibleChanged: {
                if (!visible) {
                    recordExternalHide()
                    opacity = 0
                    punchiMenuCompact.resetMenu()
                }
            }

            function openWithReveal() {
                internalCloseRequested = false
                positionAtAnchor()
                visible = true
                opacity = 1
                requestActivate()
                Qt.callLater(function() {
                    punchiMenuCompactDialog.compactBlurController.reapply()
                })
                punchiMenuCompact.openMenu()
            }

            readonly property Timer compactDialogCloseTimer: Timer {
                id: compactDialogCloseTimer
                interval: 160
                repeat: false
                onTriggered: {
                    punchiMenuCompactDialog.closeImmediately()
                }
            }

            function closeWithFade() {
                if (!visible || compactDialogCloseTimer.running) {
                    return
                }
                internalCloseRequested = true
                punchiMenuCompact.forceClose()
                compactDialogCloseTimer.restart()
            }

            function closeImmediately() {
                compactDialogCloseTimer.stop()
                internalCloseRequested = true
                visible = false
                opacity = 0
                punchiMenuCompact.resetMenu()
                Qt.callLater(function() {
                    punchiMenuCompactDialog.internalCloseRequested = false
                })
            }

            mainItem: PunchiMenuCompact {
                id: punchiMenuCompact
                width: punchiMenuCompactDialog.desiredContentWidth
                height: punchiMenuCompactDialog.desiredContentHeight
                Layout.minimumWidth: punchiMenuCompactDialog.desiredContentWidth
                Layout.preferredWidth: punchiMenuCompactDialog.desiredContentWidth
                Layout.maximumWidth: punchiMenuCompactDialog.desiredContentWidth
                Layout.minimumHeight: punchiMenuCompactDialog.desiredContentHeight
                Layout.preferredHeight: punchiMenuCompactDialog.desiredContentHeight
                Layout.maximumHeight: punchiMenuCompactDialog.desiredContentHeight
                systemDiscovery: root.systemDiscoveryService
                applicationCatalog: root.punchiMenuApplicationCatalog
                dockItemsController: root.dockItemsControllerService
                showApplicationLabels: root.configuredPunchiMenuShowApplicationLabels
                hoverAnimation: root.configuredPunchiMenuHoverAnimation
                sortApplicationsAlphabetically: root.configuredPunchiMenuSortApplicationsAlphabetically
                backgroundBlurEnabled: root.configuredPunchiMenuCompactBlurEnabled
                backgroundOpacity: root.configuredPunchiMenuCompactBackgroundOpacity
                compactShowQuickLaunchers: root.configuredPunchiMenuCompactShowQuickLaunchers
                normalPanelDistancePercent:
                    root.configuredPunchiMenuNormalPanelDistancePercent
                themeFrameLeftMargin: punchiMenuCompactDialog.themeFrameMargin("left")
                themeFrameTopMargin: punchiMenuCompactDialog.themeFrameMargin("top")
                themeFrameRightMargin: punchiMenuCompactDialog.themeFrameMargin("right")
                themeFrameBottomMargin: punchiMenuCompactDialog.themeFrameMargin("bottom")
                favorites: punchiMenuFavoritesController.favorites
                favoriteLimitReached: punchiMenuFavoritesController.limitReached

                onAddFavoriteRequested: function(storageId) {
                    punchiMenuFavoritesController.addFavorite(storageId)
                }
                onRemoveFavoriteRequested: function(storageId) {
                    punchiMenuFavoritesController.removeFavorite(storageId)
                }
                onPinToDockRequested: function(storageId, appName, appIcon, appCommand) {
                    root.dockItemsControllerService.togglePinAppToDock(
                        storageId, appName, appIcon, appCommand)
                }
                onAddToDesktopRequested: function(storageId, appCommand) {
                    root.dockItemsControllerService.pinAppToDesktop(storageId, appCommand)
                }
                onSetApplicationHiddenRequested: function(storageId, hidden) {
                    root.dockItemsControllerService.setPunchiMenuApplicationHidden(
                        storageId, hidden)
                }
                onApplicationLaunched: punchiMenuCompactDialog.closeWithFade()
                onMenuCloseRequested: punchiMenuCompactDialog.closeWithFade()
                onCloseFinished: punchiMenuCompactDialog.closeImmediately()
                onSettingChangeRequested: function(fieldName, value) {
                    root.dockItemsControllerService.setPunchiMenuValue(fieldName, value)
                }
            }
            // qmllint enable unqualified
        }
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
    function invalidatePunchiMenuInstance() {
        if (punchiMenuDialogInstance && !punchiMenuDialogInstance.visible) {
            punchiMenuDialogInstance.destroy()
            punchiMenuDialogInstance = null
        }
    }

    function synchronizePunchiMenuLayoutController() {
        punchiMenuLayoutController.layoutDocument
            = dockItemsController.punchiMenuApplicationLayout()
    }

    DockItemsController {
        id: dockItemsController
        objectName: "dockItemsController"
        dynamicApplicationsEnabled: Plasmoid.configuration.showActiveTasks
        runtimeService: runtimeService
        persistenceAdapter: dockItemsPersistenceAdapter
        systemDiscovery: systemDiscovery
        taskController: taskController
        trashIntegration: trashIntegration
        minimizeEffect: dockConfig.dockWindowMinimizeEffect
        onConfigurationChanged: {
            root.synchronizePunchiMenuLayoutController()
            root.invalidatePunchiMenuInstance()
        }
    }
    PunchiMenuFavoritesController {
        id: punchiMenuFavoritesController
        systemDiscovery: systemDiscovery
    }
    DockContextActionsController {
        id: dockContextActionsController
        systemDiscovery: systemDiscovery
        taskController: taskController
        dockItemsController: dockItemsController
        showEditDockItemAction: Plasmoid.configuration.showEditDockItemAction !== false
        showConfigureDockAction: Plasmoid.configuration.showConfigureDockAction !== false
        editDockItemHandler: function(index) {
            return root.openDockItemEditor(index)
        }
        configureDockHandler: function() {
            return root.openDockConfiguration()
        }
        moveDynamicApplicationsHandler: function() {
            return root.requestDynamicApplicationsMoveMode()
        }
    }
    DropFeedbackPopup {
        id: dropFeedbackPopup
    }
    readonly property string currentVirtualDesktopId: String(virtualDesktopInfo.currentDesktop || "")
    readonly property bool singleVirtualDesktopMode: Plasmoid.configuration.virtualDesktopMode === "single"
        && Plasmoid.configuration.targetVirtualDesktop !== ""
    readonly property bool hiddenByVirtualDesktop: singleVirtualDesktopMode
        && currentVirtualDesktopId !== Plasmoid.configuration.targetVirtualDesktop
    property int panelDynamicGroupCapacity: -1

    // Translation functions and controller ids are provided by the plasmoid
    // context and remain valid at runtime.
    // qmllint disable unqualified
    function openDockConfiguration() {
        const configureAction = Plasmoid.internalAction("configure")
        if (!configureAction || configureAction.enabled === false) {
            return false
        }

        Plasmoid.configuration.pendingEditDockItemIndex = -1
        // Persist the hand-off before opening the KCM, which may run in a
        // separate configuration context.
        // qmllint disable missing-property
        Plasmoid.configuration.writeConfig()
        // qmllint enable missing-property
        configureAction.trigger()
        return true
    }

    function openDockItemEditor(index) {
        if (!Number.isInteger(index) || index < 0) {
            return false
        }

        const configureAction = Plasmoid.internalAction("configure")
        if (!configureAction || configureAction.enabled === false) {
            return false
        }

        Plasmoid.configuration.pendingEditDockItemIndex = index
        // Persist the hand-off before opening the KCM, which may run in a
        // separate configuration context.
        // qmllint disable missing-property
        Plasmoid.configuration.writeConfig()
        // qmllint enable missing-property
        configureAction.trigger()
        return true
    }

    function droppedUrlErrorMessage(result) {
        const errorCode = String(result && result.errorCode || "")
        if (errorCode === "noUrls") {
            return i18nc("@info:status", "No local files were found in this drop.")
        }
        if (errorCode === "tooManyUrls") {
            const maximumCount = Number(result.maximumUrlCount || 64)
            return i18nc("@info:status", "You can open up to %1 local files at once.",
                maximumCount)
        }
        if (errorCode === "invalidUrl") {
            return i18nc("@info:status", "The drop contains an invalid local file location.")
        }
        if (errorCode === "unsupportedScheme") {
            return i18nc("@info:status", "Only local files can be opened with an application.")
        }
        if (errorCode === "urlTooLong") {
            return i18nc("@info:status", "A file location is too long to open safely.")
        }
        if (errorCode === "batchTooLarge") {
            return i18nc("@info:status", "The dropped file list is too large to open safely.")
        }
        if (errorCode === "applicationUnavailable") {
            return i18nc("@info:status", "This application cannot be resolved safely for file opening.")
        }
        return i18nc("@info:status", "The dropped files could not be opened.")
    }

    function handleApplicationUrlsDrop(item, taskRows, urls, visualParent,
            coordinator) {
        const result = dockItemsController.handleApplicationUrlsDrop(
            item, taskRows, urls)
        if (!result.accepted) {
            dropFeedbackPopup.presentFeedback(visualParent,
                root.droppedUrlErrorMessage(result))
            return
        }
        dropFeedbackPopup.dismissFeedback()
        if (coordinator) {
            coordinator.closeAllPopups(null)
        }
    }

    function handleContainerApplicationLauncherDrop(urls, targetIndex,
            expectedContainerText, visualParent, coordinator) {
        const result = dockItemsController.addApplicationLauncherToContainer(
            urls, targetIndex, expectedContainerText)
        if (!result.success) {
            dropFeedbackPopup.presentFeedback(visualParent, result.message,
                false)
            return
        }

        dropFeedbackPopup.dismissFeedback()
        const folderPopup = coordinator
            ? coordinator.folderPopupDialogRef : null
        const activeFolderMatches = folderPopup && folderPopup.visible
            && dockItemsController.canonicalJsonText(
                coordinator.activeFolderData) === expectedContainerText
        if (result.success && activeFolderMatches && result.container) {
            coordinator.activeFolderData = result.container
        }
    }

    function launchConfiguredMediaPlayer(item, playWhenReady) {
        const storageId = String(
            item.defaultPlayerStorageId || "").substring(0, 512)
        if (storageId.length === 0) {
            return
        }

        taskController.cancelPendingMediaWindowMinimize()
        if (item.openPlayerMinimized === true) {
            taskController.requestMinimizeNextApplicationWindow(
                String(item.defaultPlayerAppId || "").substring(0, 512),
                storageId)
        }
        if (playWhenReady) {
            dockMediaController.requestPlayWhenAvailable(10000)
        }
        systemDiscovery.launchApplication(storageId)
    }
    // qmllint enable unqualified

    implicitWidth: inPanel ? dockGeometry.panelPreferredWidth : 0
    implicitHeight: inPanel ? dockGeometry.panelPreferredHeight : 0
    switchWidth: inPanel ? dockGeometry.panelPreferredWidth : Math.ceil(dockGeometry.panelItemWidth)
    switchHeight: inPanel ? dockGeometry.panelPreferredHeight : Math.ceil(dockGeometry.panelItemHeight)

    function applyFloatingOrientationFootprint() {
        if (inPanel || !floatingDockAnchor) {
            return
        }

        const targetWidth = Math.ceil(floatingDockAnchor.implicitWidth)
        const targetHeight = Math.ceil(floatingDockAnchor.implicitHeight)
        if (targetWidth <= 0 || targetHeight <= 0) {
            return
        }

        const centerX = x + (width / 2)
        const centerY = y + (height / 2)
        width = targetWidth
        height = targetHeight
        x = Math.round(centerX - (width / 2))
        y = Math.round(centerY - (height / 2))
        dockGeometry.updateFloatingScreenEdge(floatingDockAnchor)
    }

    onFloatingVerticalChanged: {
        if (floatingOrientationReady) {
            floatingOrientationFootprintTimer.restart()
        }
    }
    Component.onCompleted: {
        floatingOrientationReady = true
        Qt.callLater(function() {
            systemDiscovery.requestApplicationCatalog()
        })
        Qt.callLater(root.synchronizePunchiMenuLayoutController)
    }

    Timer {
        id: floatingOrientationFootprintTimer
        interval: 50
        repeat: false
        onTriggered: root.applyFloatingOrientationFootprint()
    }

    Layout.fillWidth: inPanel && !hiddenByVirtualDesktop
        && (dockGeometry.verticalPanel || dockGeometry.panelFillLengthEnabled)
    Layout.fillHeight: inPanel && !hiddenByVirtualDesktop
        && (dockGeometry.horizontalPanel || dockGeometry.panelFillLengthEnabled)
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
        objectName: "punchiDockFullRepresentation"
        property bool contextMenuVisible: false
        readonly property bool dynamicApplicationsMoveModeActive:
            dockLayout.persistentMoveModeActive

        function enterDynamicApplicationsMoveMode() {
            return dockLayout.enterDynamicApplicationsMoveMode()
        }

        Component.onCompleted:
            root.dynamicApplicationsMoveModeTarget = mainContainer
        Component.onDestruction: {
            if (root.dynamicApplicationsMoveModeTarget === mainContainer) {
                root.dynamicApplicationsMoveModeTarget = null
            }
        }
        // fullRepresentation is compiled as a nested component, so qmllint
        // cannot resolve accesses to the owning PlasmoidItem even though
        // Plasma provides that lexical context at runtime.
        // qmllint disable unqualified
        visible: !root.hiddenByVirtualDesktop
        enabled: visible
        implicitWidth: visible ? dockGeometry.panelPreferredWidth : 0
        implicitHeight: visible ? dockGeometry.panelPreferredHeight : 0
        Layout.fillWidth: root.inPanel && visible
            && (dockGeometry.verticalPanel || dockGeometry.panelFillLengthEnabled)
        Layout.fillHeight: root.inPanel && visible
            && (dockGeometry.horizontalPanel || dockGeometry.panelFillLengthEnabled)
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
            // qmllint disable unqualified
            geometryStateRef: dockGeometry
            // qmllint enable unqualified
            dockFallbackAnchor: dockWrapper
            taskStructureSource: root
            taskControllerRef: taskController
            mprisControllerRef: mprisController
            trashIntegrationRef: trashIntegration
            trashContextContentRef: trashContextContent
            notePopupContentRef: notePopupContent
            taskWindowsPopupContentRef: taskWindowsPopupContent
            taskPopupSurfaceRef: taskPopupSurface
            taskPopupAnimatedContentRef: taskPopupAnimatedContent
            // These ids belong to the owning full representation.
            // qmllint disable unqualified
            mediaHoverMode: dockConfig.mediaControlsMode
            mediaHoverEnabled: dockConfig.mediaControlsOnHover
            windowPreviewsEnabled: dockConfig.windowPreviewStyle !== "none"
            // qmllint enable unqualified
            folderPopupDialogRef: folderPopupDialog
            calendarPopupDialogRef: calendarPopupDialog
            trashMenuDialogRef: trashMenuDialog
            notePopupDialogRef: notePopupDialog
            appActionsDialogRef: appActionsDialog
            taskWindowsDialogRef: taskWindowsDialog
            taskOverflowDialogRef: taskOverflowDialog
            // The dynamic PunchiMenu instance belongs to the owning PlasmoidItem.
            // qmllint disable unqualified
            punchiMenuDialogRef: root.punchiMenuDialogInstance
            // qmllint enable unqualified
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
                trashMenuDialog.closeSafely()
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
                : dockLayout.implicitWidth + dockGeometry.floatingExtraWidth
            implicitHeight: root.inPanel ? dockGeometry.panelPreferredHeight : dockLayout.implicitHeight
                + dockGeometry.floatingExtraHeight
            width: root.inPanel ? parent.width : implicitWidth
            height: root.inPanel ? parent.height : implicitHeight

            Component.onCompleted: root.floatingDockAnchor = dockWrapper
            onXChanged: dockGeometry.updateFloatingScreenEdge(dockWrapper)
            onYChanged: dockGeometry.updateFloatingScreenEdge(dockWrapper)
            onWidthChanged: dockGeometry.updateFloatingScreenEdge(dockWrapper)
            onHeightChanged: dockGeometry.updateFloatingScreenEdge(dockWrapper)

            readonly property real dynamicTaskCapacityLength: {
                if (!root.inPanel) {
                    return -1
                }

                const isVertical = dockGeometry.verticalPanel
                if (dockGeometry.panelFillLengthEnabled) {
                    return isVertical ? height : width
                }

                // Fit-content geometry must not feed the dock's own assigned
                // length back into its capacity. The available screen axis is
                // independent from the preferred size produced by this dock.
                const availableLength = isVertical
                    ? Number(root.availableScreenRect.height || 0)
                    : Number(root.availableScreenRect.width || 0)
                return Number.isFinite(availableLength) && availableLength > 0
                    ? availableLength : -1
            }
            readonly property int dynamicTaskSlotCapacity: {
                if (dynamicTaskCapacityLength < 0) {
                    return -1
                }

                const isVertical = dockGeometry.verticalPanel
                const totalPadding = isVertical
                    ? (dockGeometry.dockBackgroundVerticalPadding * 2)
                    : (dockGeometry.dockBackgroundHorizontalPadding * 2)
                const innerLength = Math.max(0,
                    dynamicTaskCapacityLength - totalPadding)
                const boundarySpacing = dockItemsController.dockItems.length > 0
                    && taskController.totalDynamicGroups > 0
                    ? dockGeometry.dockSpacing
                    : 0
                const availableLength = Math.max(0, innerLength
                    - dockGeometry.panelFixedContentLength - boundarySpacing)
                const itemExtent = isVertical
                    ? dockGeometry.panelItemHeight
                    : dockGeometry.panelItemWidth
                return Math.max(0, Math.floor(
                    (availableLength + dockGeometry.dockSpacing)
                    / (itemExtent + dockGeometry.dockSpacing)))
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
                id: dockBackground
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
                spectrumVertical: dockGeometry.verticalPanel
                dockVertical: dockGeometry.verticalPanel
                spectrumOriginEdge: dockGeometry.verticalPanel ? dockGeometry.spectrumOriginEdge
                    : (dockConfig.audioSpectrumOrigin === "top" ? Qt.TopEdge : Qt.BottomEdge)
                spectrumEdgeInset: dockGeometry.verticalPanel
                    ? dockGeometry.floatingExtraWidth / 2
                    : dockGeometry.floatingExtraHeight / 2
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
                    ? (dockGeometry.panelFillLengthEnabled
                        ? Math.max(0, parent.height - y
                            - dockGeometry.dockBackgroundVerticalPadding)
                        : dockLayout.height)
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
                    originEdge: dockGeometry.spectrumOriginEdge
                }
            }
            // qmllint enable unqualified

            GridLayout {
                id: dockLayout
                z: 10
                flow: dockGeometry.verticalPanel ? GridLayout.TopToBottom : GridLayout.LeftToRight
                columns: dockGeometry.verticalPanel ? 1 : -1
                rows: dockGeometry.verticalPanel ? -1 : 1
                rowSpacing: dockGeometry.dockSpacing
                columnSpacing: dockGeometry.dockSpacing
                x: {
                    if (!root.inPanel) {
                        return Math.round((parent.width - width) / 2)
                    }
                    if (dockGeometry.verticalPanel) {
                        // Plasma already recenters the containment while an
                        // adaptive panel moves between floating and attached.
                        // Preserve a centered overflow when Wave needs more
                        // width than the lateral panel can allocate.
                        return Math.round((parent.width - width) / 2)
                    }
                    if (dockGeometry.configuredPanelAlignmentMode === "center") {
                        return Math.round((parent.width - width) / 2)
                    }
                    if (dockGeometry.configuredPanelAlignmentMode === "end") {
                        return parent.width - width
                            - dockGeometry.dockBackgroundHorizontalPadding
                    }
                    return dockGeometry.dockBackgroundHorizontalPadding
                }
                y: {
                    if (!root.inPanel) {
                        return Math.round((parent.height - height) / 2)
                    }
                    if (!dockGeometry.verticalPanel) {
                        return Math.round((parent.height - height) / 2)
                    }
                    if (dockGeometry.configuredPanelAlignmentMode === "center") {
                        return Math.round((parent.height - height) / 2)
                    }
                    if (dockGeometry.configuredPanelAlignmentMode === "end") {
                        return parent.height - height
                            - dockGeometry.dockBackgroundVerticalPadding
                    }
                    return dockGeometry.dockBackgroundVerticalPadding
                }
                
                property int hoveredIndex: -1
                property real mouseOffset: 0.0
                property real pointerPrimaryAxis: -1
                property real lastPointerPrimaryAxis: -1
                readonly property bool wavePointerInsideLayout:
                    dockWaveHover.hovered

                // State used for smooth transitions when entering or leaving the dock.
                property int lastHoveredIndex: -1
                property real lastMouseOffset: 0.0
                property real hoverZoomProgress: hoveredIndex >= 0 ? 1.0 : 0.0
                property bool mediaMorphActive: false
                property bool launcherDropTransitionActive: false
                property int persistentDragSourceIndex: -1
                property int persistentMoveModeIndex: -1
                property int persistentDragTargetIndex: -1
                property string persistentDragExpectedItemText: ""
                property var persistentDragSourceItem: null
                property point persistentDragPointerPosition:
                    Qt.point(0, 0)
                property string persistentDragIconName:
                    "application-x-executable"
                property bool persistentDragMovesDynamicApplications: false
                readonly property bool persistentDragActive:
                    persistentDragSourceIndex >= 0
                readonly property bool persistentMoveModeActive:
                    persistentMoveModeIndex >= 0
                readonly property string effectiveHoverAnimationMode:
                    persistentDragActive ? "none"
                        : dockConfig.dockHoverAnimation

                Timer {
                    id: persistentDragWatchdogTimer
                    interval: 3000
                    repeat: false
                    onTriggered: {
                        if (dockLayout.persistentDragActive) {
                            dockLayout.cancelPersistentDrag()
                        }
                    }
                }

                function cancelPersistentDrag() {
                    persistentDragWatchdogTimer.stop()
                    persistentDragSourceIndex = -1
                    persistentDragTargetIndex = -1
                    persistentDragExpectedItemText = ""
                    persistentDragSourceItem = null
                    persistentDragPointerPosition = Qt.point(0, 0)
                    persistentDragIconName = "application-x-executable"
                    persistentDragMovesDynamicApplications = false
                    persistentMoveModeIndex = -1
                }

                function enterDynamicApplicationsMoveMode() {
                    const index = root.dynamicApplicationsMarkerIndex
                    const items = dockItemsController.dockItems || []
                    if (!Number.isInteger(index) || index < 0
                            || index >= items.length || !items[index]
                            || items[index].type !== "dynamic-applications") {
                        return false
                    }
                    popupCoordinator.closeAllPopups(null)
                    persistentMoveModeIndex = index
                    Qt.callLater(function() {
                        const handle = persistentDockItemsRepeater.itemAt(index)
                        if (handle && handle.focusItem) {
                            handle.focusItem()
                        }
                    })
                    return true
                }

                function beginPersistentDrag(sourceIndex, sourceItem) {
                    const index = Number(sourceIndex)
                    const items = dockItemsController.dockItems || []
                    if (persistentDragActive || !sourceItem
                            || !Number.isInteger(index)
                            || index < 0 || index >= items.length
                            || !items[index]
                            || items[index].type === "media") {
                        return false
                    }
                    if (!root.inPanel
                            && !dockConfig.floatingItemDragReorderingEnabled
                            && persistentMoveModeIndex !== index) {
                        return false
                    }
                    popupCoordinator.closeAllPopups(null)
                    hoveredIndex = -1
                    lastHoveredIndex = -1
                    mouseOffset = 0.0
                    lastMouseOffset = 0.0
                    pointerPrimaryAxis = -1
                    lastPointerPrimaryAxis = -1
                    persistentDragSourceIndex = index
                    persistentDragTargetIndex = index
                    persistentDragExpectedItemText
                        = dockItemsController.canonicalJsonText(items[index])
                    persistentDragSourceItem = sourceItem
                    persistentDragIconName
                        = root.dockItemReorderIconName(items[index])
                    persistentDragMovesDynamicApplications
                        = items[index].type === "dynamic-applications"
                    persistentDragWatchdogTimer.restart()
                    return persistentDragExpectedItemText.length > 0
                }

                function updatePersistentDrag(sourceItem, x, y) {
                    if (!persistentDragActive
                            || sourceItem !== persistentDragSourceItem) {
                        return
                    }
                    persistentDragWatchdogTimer.restart()
                    const point = sourceItem.mapToItem(dockLayout, x, y)
                    persistentDragPointerPosition
                        = sourceItem.mapToItem(dockWrapper, x, y)
                    const primaryPosition = dockGeometry.verticalPanel
                        ? point.y : point.x
                    const itemCount = persistentDockItemsRepeater.count
                    let beforeIndex = itemCount
                    for (let index = 0; index < itemCount; index++) {
                        if (index === persistentDragSourceIndex) {
                            continue
                        }
                        const candidate = persistentDockItemsRepeater.itemAt(index)
                        if (!candidate) {
                            continue
                        }
                        const candidateCenter = dockGeometry.verticalPanel
                            ? candidate.y + candidate.height / 2
                            : candidate.x + candidate.width / 2
                        if (primaryPosition < candidateCenter) {
                            beforeIndex = index
                            break
                        }
                    }
                    if (beforeIndex >= itemCount) {
                        persistentDragTargetIndex = itemCount - 1
                    } else if (beforeIndex > persistentDragSourceIndex) {
                        persistentDragTargetIndex = beforeIndex - 1
                    } else {
                        persistentDragTargetIndex = beforeIndex
                    }
                }

                function finishPersistentDrag() {
                    if (!persistentDragActive) {
                        return
                    }
                    persistentDragWatchdogTimer.stop()
                    const sourceIndex = persistentDragSourceIndex
                    const targetIndex = persistentDragTargetIndex
                    const expectedItemText = persistentDragExpectedItemText
                    cancelPersistentDrag()
                    if (!dockItemsController.movePersistentItem(
                            sourceIndex, targetIndex, expectedItemText)) {
                        console.warn("Punchi Dock: Persistent item reorder was canceled because the configuration changed or could not be saved.")
                    }
                }

                function movePersistentItemFromKeyboard(modelIndex, delta) {
                    const sourceIndex = Number(modelIndex)
                    const targetIndex = sourceIndex + Number(delta)
                    const items = dockItemsController.dockItems || []
                    if (!Number.isInteger(sourceIndex)
                            || !Number.isInteger(targetIndex)
                            || sourceIndex < 0 || sourceIndex >= items.length
                            || targetIndex < 0 || targetIndex >= items.length
                            || !items[sourceIndex]) {
                        return
                    }
                    const expectedItemText
                        = dockItemsController.canonicalJsonText(items[sourceIndex])
                    if (dockItemsController.movePersistentItem(
                            sourceIndex, targetIndex, expectedItemText)
                            && persistentMoveModeIndex === sourceIndex) {
                        persistentMoveModeIndex = targetIndex
                        Qt.callLater(function() {
                            const handle = persistentDockItemsRepeater.itemAt(targetIndex)
                            if (handle && handle.focusItem) {
                                handle.focusItem()
                            }
                        })
                    }
                }

                Connections {
                    target: dockItemsController

                    function onConfigurationChanged() {
                        if (dockLayout.persistentDragActive) {
                            dockLayout.cancelPersistentDrag()
                        }
                    }
                }

                Connections {
                    target: dockConfig

                    function onFloatingItemDragReorderingEnabledChanged() {
                        if (!root.inPanel
                                && !dockConfig.floatingItemDragReorderingEnabled
                                && dockLayout.persistentDragActive) {
                            dockLayout.cancelPersistentDrag()
                        }
                    }
                }

                Connections {
                    target: root

                    function onInPanelChanged() {
                        if (!root.inPanel
                                && !dockConfig.floatingItemDragReorderingEnabled
                                && dockLayout.persistentDragActive) {
                            dockLayout.cancelPersistentDrag()
                        }
                    }
                }

                HoverHandler {
                    id: dockWaveHover
                    // qmllint disable unqualified
                    enabled:
                        dockConfig.dockHoverAnimation === "wave"
                        && !dockLayout.persistentDragActive
                    // qmllint enable unqualified
                    readonly property point trackedPosition: point.position

                    function updateWavePointer() {
                        if (!hovered) {
                            return
                        }
                        const position = dockLayout.flow === GridLayout.TopToBottom
                            ? trackedPosition.y : trackedPosition.x
                        if (!Number.isFinite(position)) {
                            return
                        }
                        dockLayout.pointerPrimaryAxis = position
                        dockLayout.lastPointerPrimaryAxis = position
                    }

                    onTrackedPositionChanged: updateWavePointer()
                    onHoveredChanged: {
                        if (hovered) {
                            updateWavePointer()
                            return
                        }
                        dockLayout.hoveredIndex = -1
                        dockLayout.mouseOffset = 0.0
                    }
                }

                function beginMediaMorph(transitionDuration) {
                    mediaMorphActive = true
                    mediaMorphTimer.interval = Math.max(1, Number(transitionDuration) || 220)
                    mediaMorphTimer.restart()
                }

                Timer {
                    id: mediaMorphTimer
                    interval: 220
                    repeat: false
                    onTriggered: dockLayout.mediaMorphActive = false
                }

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
                    enabled: Kirigami.Units.longDuration > 0
                    NumberAnimation {
                        duration: dockLayout.hoveredIndex >= 0
                            ? Math.max(80, Math.round(Kirigami.Units.shortDuration * 1.1))
                            : Math.max(60, Math.round(Kirigami.Units.shortDuration * 0.85))
                        easing.type: dockLayout.hoveredIndex >= 0 ? Easing.OutCubic : Easing.InQuad
                    }
                }

                signal trashUrlsDropped(var urls)
                onTrashUrlsDropped: function(urls) {
                    trashIntegration.trashUrls(urls)
                }

                Repeater {
                    id: persistentDockItemsRepeater
                    model: dockItemsController.dockItems
                    delegate: DockItem {
                        id: dockItemDelegate
                        required property var modelData
                        required property int index
                        layoutController: dockLayout
                        Layout.column: dockGeometry.verticalPanel
                            ? 0 : root.persistentVisualIndex(dockItemDelegate.index)
                        Layout.row: dockGeometry.verticalPanel
                            ? root.persistentVisualIndex(dockItemDelegate.index) : 0
                        itemIndex: root.persistentVisualIndex(dockItemDelegate.index)
                        persistentModelIndex: dockItemDelegate.index
                        persistentReorderEnabled:
                            dockItemDelegate.modelData.type !== "media"
                        persistentPointerReorderEnabled:
                            dockItemDelegate.persistentReorderEnabled
                            && (dockItemDelegate.persistentMoveHandleVisible
                                || root.inPanel
                                || dockConfig.floatingItemDragReorderingEnabled)
                        persistentMoveHandleVisible:
                            dockItemDelegate.modelData.type
                                === "dynamic-applications"
                            && dockLayout.persistentMoveModeIndex
                                === dockItemDelegate.index
                        persistentDirectReorderEnabled:
                            dockItemDelegate.persistentMoveHandleVisible
                        persistentReorderActive: dockLayout.persistentDragActive
                        persistentReorderSource: dockLayout.persistentDragSourceIndex
                            === dockItemDelegate.index
                        persistentReorderTarget: dockLayout.persistentDragActive
                            && dockLayout.persistentDragTargetIndex
                                === dockItemDelegate.index
                            && dockLayout.persistentDragSourceIndex
                                !== dockItemDelegate.index
                        persistentReorderInsertAfter:
                            dockLayout.persistentDragSourceIndex
                                < dockLayout.persistentDragTargetIndex
                        launcherModelInsertionIndex: dockItemDelegate.index
                        hoveredIndex: dockLayout.hoveredIndex
                        inPanel: root.inPanel
                        panelLocation: dockGeometry.effectivePanelLocation
                        iconSize: dockGeometry.effectiveIconSize
                        // The media item's text preference belongs to modelData.
                        // qmllint disable unqualified
                        mediaMainAxisLength: dockGeometry.mediaItemMainAxisLengthForItem(dockItemDelegate.modelData)
                        // qmllint enable unqualified
                        mediaController: dockItemDelegate.modelData.type === "media"
                            ? dockMediaController
                            : null
                        mediaLaunchAvailable: dockItemDelegate.modelData.type === "media"
                            && String(dockItemDelegate.modelData.defaultPlayerStorageId || "").length > 0
                        mediaDefaultPlayerName: dockItemDelegate.modelData.type === "media"
                            ? String(dockItemDelegate.modelData.defaultPlayerName || "")
                            : ""
                        mediaDefaultPlayerIcon: dockItemDelegate.modelData.type === "media"
                            ? String(dockItemDelegate.modelData.defaultPlayerIcon || "")
                            : ""
                        // The delegate model supplies modelData at runtime.
                        // qmllint disable unqualified
                        mediaTextMode: dockItemDelegate.modelData.type === "media"
                            ? String(dockItemDelegate.modelData.mediaTextMode || "automatic")
                            : "automatic"
                        mediaDisplayMode: dockItemDelegate.modelData.type === "media"
                            ? String(dockItemDelegate.modelData.mediaDisplayMode || "normal")
                            : "normal"
                        mediaAutoCollapseDelaySeconds: dockItemDelegate.modelData.type === "media"
                            ? Number(dockItemDelegate.modelData.mediaAutoCollapseDelaySeconds === undefined
                                ? 3 : dockItemDelegate.modelData.mediaAutoCollapseDelaySeconds)
                            : 3
                        dockMotionSpeedPercent: dockConfig.dockMotionSpeedPercent
                        mediaMotionEnabled: dockConfig.menuAnimationStyle !== "none"
                            && dockConfig.dockHoverAnimation !== "none"
                        hoverScaleSetting: dockConfig.panelHoverScale
                        hoverAnimationMode:
                            dockLayout.effectiveHoverAnimationMode
                        clickEffect: dockConfig.dockClickEffect
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
                            const appId = taskController.dockItemApplicationId(dockItemDelegate.modelData)
                            const launcherUrl = taskController.dockItemLauncherUrl(dockItemDelegate.modelData)
                            return (dockItemsController.recentlyTransitionedAppId.length > 0
                                    && appId === dockItemsController.recentlyTransitionedAppId)
                                || (dockItemsController.recentlyTransitionedLauncherUrl.length > 0
                                    && launcherUrl === dockItemsController.recentlyTransitionedLauncherUrl)
                        }
                        // qmllint enable unqualified
                        // qmllint disable unqualified
                        showPersistentLabel: dockConfig.dockShowLabels
                        textShadowsEnabled: dockConfig.dockTextShadowsEnabled
                        calendarTextShadowsEnabled: dockItemDelegate.modelData.calendarTextShadowsEnabled !== false
                        labelFontSize: dockConfig.dockLabelFontSize
                        indicatorType: dockConfig.dockIndicatorType
                        indicatorPosition: dockConfig.dockIndicatorPosition
                        indicatorColor: dockConfig.dockIndicatorColor
                        // qmllint disable unqualified
                        indicatorThickness: dockConfig.dockIndicatorThickness
                        indicatorOpacity: dockConfig.dockIndicatorOpacity
                        windowCountBadgeEnabled: dockConfig.windowCountBadgeEnabled
                        windowCountBadgePosition: dockConfig.windowCountBadgePosition
                        windowGroupingEnabled: taskController.groupingEnabled()
                        windowCountEmblemColor: dockConfig.windowCountEmblemColor
                        windowCountEmblemOpacity: dockConfig.windowCountEmblemOpacity
                        windowCountEmblemScale: dockConfig.windowCountEmblemScale
                        // qmllint enable unqualified
                        customSeparatorEnabled: dockConfig.customDockSeparatorActive
                        separatorTheme: dockConfig.customDockSeparatorTheme
                        // qmllint enable unqualified
                        
                        // Wave animation state.
                        hoverZoomProgress: dockLayout.hoverZoomProgress
                        lastHoveredIndex: dockLayout.lastHoveredIndex
                        lastMouseOffset: dockLayout.lastMouseOffset
                        readonly property int taskRevision: root.taskVisualRevision
                        readonly property var taskState: {
                            taskRevision
                            return taskController.taskStateForDockItem(dockItemDelegate.modelData)
                        }
                        
                        itemType: dockItemDelegate.modelData.type || "app"
                        timeTextScale: dockItemDelegate.modelData.timeTextScale === undefined ? (dockItemDelegate.modelData.textScale === undefined ? 1.0 : dockItemDelegate.modelData.textScale) : dockItemDelegate.modelData.timeTextScale
                        dateTextScale: dockItemDelegate.modelData.dateTextScale === undefined ? (dockItemDelegate.modelData.textScale === undefined ? 1.0 : dockItemDelegate.modelData.textScale) : dockItemDelegate.modelData.dateTextScale
                        separatorStyleSetting: dockItemDelegate.modelData.separatorStyle || "line"
                        separatorThicknessSetting: dockItemDelegate.modelData.separatorThickness === undefined ? 2 : dockItemDelegate.modelData.separatorThickness
                        separatorLengthRatioSetting: dockItemDelegate.modelData.separatorLengthRatio === undefined ? 0.72 : dockItemDelegate.modelData.separatorLengthRatio
                        separatorOpacitySetting: dockItemDelegate.modelData.separatorOpacity === undefined ? 0.34 : dockItemDelegate.modelData.separatorOpacity
                        separatorGlowSetting: dockItemDelegate.modelData.separatorGlowEnabled === true
                        separatorVisibleSetting:
                            dockItemDelegate.modelData.showSeparator !== false
                        iconName: dockItemDelegate.modelData.type === "trash" && dockItemDelegate.modelData.showState !== false
                            ? (dockItemsController.trashHasItems ? (dockItemDelegate.modelData.fullIcon || "user-trash-full") : (dockItemDelegate.modelData.icon || "user-trash"))
                            : (dockItemDelegate.modelData.icon || "")
                        itemName: dockItemDelegate.modelData.name || ""
                        itemCommand: dockItemDelegate.modelData.command || ""
                        taskIndicatorCount: taskState.count
                        taskIsActive: taskState.isActive
                        taskDemandsAttention: taskState.demandsAttention
                        // Popup ids belong to the owning full representation.
                        // qmllint disable unqualified
                        suppressTooltip: mainContainer.contextMenuVisible
                            || (taskWindowsDialog.visible && popupCoordinator.taskPopupVisualParent === dockItemDelegate)
                            || (folderPopupDialog.visible && folderPopupDialog.placementAnchor === dockItemDelegate)
                            || (calendarPopupDialog.visible && calendarPopupDialog.visualParent === dockItemDelegate)
                            || (notePopupDialog.visible && notePopupDialog.visualParent === dockItemDelegate)
                            || (trashMenuDialog.visible && trashMenuDialog.placementAnchor === dockItemDelegate)
                            || (appActionsDialog.visible && appActionsDialog.placementAnchor === dockItemDelegate)
                            || (root.punchiMenuDialogInstance && root.punchiMenuDialogInstance.visible && root.punchiMenuAnchorItem === dockItemDelegate)
                        // qmllint enable unqualified
                        supportsContextMenu: dockContextActionsController.itemHasContextMenu(dockItemDelegate.modelData, taskState.rows, "pinned")
                        mediaHoverControlsEnabled: dockConfig.mediaControlsOnHover && taskState.count > 0
                        // qmllint disable unqualified
                        externalDropEnabled: dockItemDelegate.modelData.type === "app"
                            && dockConfig.appDragAndDropEnabled
                        externalDropValidator: function(urls) {
                            return dockItemsController.validateDroppedUrls(urls)
                        }
                        launcherDropEnabled: true
                        launcherDropValidator: function(urls) {
                            return dockItemsController.validateApplicationLauncherDrop(urls)
                        }
                        launcherContainerDropTarget:
                            dockItemDelegate.modelData.type === "folder"
                        launcherContainerDropEnabled:
                            dockItemDelegate.launcherContainerDropTarget
                            && (dockItemDelegate.modelData.sourceType
                                || "manual") === "manual"
                        externalDropActivationEnabled: taskState.count > 0
                            && !taskState.isActive
                        externalDropActivator: function() {
                            return taskController.activateTaskRowsForExternalDrop(taskState.rows)
                        }
                        // qmllint enable unqualified

                        // The delegate is compiled separately and these handlers
                        // intentionally retain its owning plasmoid and model row.
                        // qmllint disable unqualified
                        Component.onCompleted: {
                            if (dockItemDelegate.modelData.type === "punchimenu") {
                                root.punchiMenuAnchorItem = dockItemDelegate
                            }
                        }
                        Component.onDestruction: {
                            if (root.punchiMenuAnchorItem === dockItemDelegate) {
                                root.punchiMenuAnchorItem = null
                            }
                        }
                        // qmllint enable unqualified

                        // qmllint disable unqualified
                        TaskDelegateGeometryPublisher {
                            taskModelController: taskController
                            targetItem: dockItemDelegate.taskGeometryItem
                            taskRows: dockItemDelegate.taskState.rows
                            publicationEnabled: taskGeometryOwnership.ownsTaskGeometry
                        }
                        // qmllint enable unqualified
                        
                        onItemClicked: function(cmd) {
                            if (dockItemDelegate.modelData.type === "folder") {
                                popupCoordinator.openFolderPopup(dockItemDelegate.modelData, dockItemDelegate)
                            } else if (dockItemDelegate.modelData.type === "calendar") {
                                popupCoordinator.openCalendarPopup(dockItemDelegate.modelData, dockItemDelegate)
                            } else if (dockItemDelegate.modelData.type === "note") {
                                popupCoordinator.openNotePopup(dockItemDelegate.modelData, dockItemDelegate, dockItemDelegate.index)
                            } else if (dockItemDelegate.modelData.type === "punchimenu") {
                                popupCoordinator.closeAllPopups(null)
                                root.togglePunchiMenu(dockItemDelegate)
                            } else {
                                popupCoordinator.closeAllPopups(null)
                                dockItemsController.handleDockItemActivation(dockItemDelegate.modelData, dockItemDelegate)
                            }
                        }
                        // qmllint disable unqualified
                        onTaskMinimized: function(minimizedItemIndex) {
                            dockItemsController.triggerMinimizeReaction(minimizedItemIndex)
                        }
                        onExternalUrlsDropped: function(urls, visualParent) {
                            root.handleApplicationUrlsDrop(
                                dockItemDelegate.modelData, taskState.rows,
                                urls, visualParent, popupCoordinator)
                        }
                        onApplicationLauncherDropped: function(urls, insertionIndex) {
                            dockItemsController.pinApplicationLauncherAt(
                                urls, insertionIndex)
                        }
                        onApplicationLauncherContainerDropped: function(
                                urls, visualParent) {
                            root.handleContainerApplicationLauncherDrop(
                                urls, dockItemDelegate.index,
                                dockItemsController.canonicalJsonText(
                                    dockItemDelegate.modelData), visualParent,
                                popupCoordinator)
                        }
                        onPersistentReorderPressStarted: {
                            popupCoordinator.cancelTaskPopupForPointerReorder()
                        }
                        onPersistentReorderStarted: function(modelIndex, visualParent) {
                            dockLayout.beginPersistentDrag(modelIndex, visualParent)
                        }
                        onPersistentReorderMoved: function(x, y) {
                            dockLayout.updatePersistentDrag(dockItemDelegate, x, y)
                        }
                        onPersistentReorderFinished: dockLayout.finishPersistentDrag()
                        onPersistentReorderCanceled: dockLayout.cancelPersistentDrag()
                        onPersistentMoveModeCanceled: dockLayout.cancelPersistentDrag()
                        onPersistentKeyboardMoveRequested: function(modelIndex, delta) {
                            dockLayout.movePersistentItemFromKeyboard(modelIndex, delta)
                        }
                        onMediaLaunchRequested: {
                            root.launchConfiguredMediaPlayer(dockItemDelegate.modelData, false)
                        }
                        onMediaPlaybackLaunchRequested: {
                            root.launchConfiguredMediaPlayer(dockItemDelegate.modelData, true)
                        }
                        onMediaExpansionChanged: function(expanded, transitionDuration) {
                            root.mediaItemExpanded = expanded
                            dockLayout.beginMediaMorph(transitionDuration)
                        }
                        // qmllint enable unqualified
                        onContextMenuRequested: function(visualParent, keyboardInvoked) {
                            if (dockItemDelegate.modelData.type === "trash") {
                                popupCoordinator.openTrashMenu(dockItemDelegate.modelData, visualParent, keyboardInvoked)
                            } else if (dockContextActionsController.itemHasContextMenu(dockItemDelegate.modelData, taskState.rows, "pinned")) {
                                popupCoordinator.openAppContextMenu(dockItemDelegate.modelData, visualParent,
                                    taskState.rows, "pinned", dockItemDelegate.index)
                            }
                        }
                        onHoverEntered: function(visualParent) {
                            if ((dockConfig.mediaControlsOnHover || dockConfig.windowPreviewStyle !== "none")
                                    && taskState.count > 0) {
                                popupCoordinator.scheduleTaskWindowsPopup(dockItemDelegate.modelData.name || "",
                                    taskState.rows, visualParent, false,
                                    dockConfig.windowPreviewStyle !== "none")
                            }
                        }
                        onMediaControlsRequested: function(visualParent) {
                            popupCoordinator.scheduleTaskWindowsPopup(dockItemDelegate.modelData.name || "",
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
                        layoutController: dockLayout
                        required property var modelData
                        required property int index
                        readonly property int taskRevision: root.taskVisualRevision
                        readonly property var taskData: {
                            taskRevision
                            return taskController.taskDataForEntry(modelData)
                        }

                        Layout.column: dockGeometry.verticalPanel
                            ? 0 : root.dynamicVisualIndex(taskDockItemDelegate.index)
                        Layout.row: dockGeometry.verticalPanel
                            ? root.dynamicVisualIndex(taskDockItemDelegate.index) : 0
                        itemIndex: root.dynamicVisualIndex(taskDockItemDelegate.index)
                        launcherModelInsertionIndex:
                            root.dynamicLauncherInsertionIndex()
                        hoveredIndex: dockLayout.hoveredIndex
                        inPanel: root.inPanel
                        panelLocation: dockGeometry.effectivePanelLocation
                        iconSize: dockGeometry.effectiveIconSize
                        hoverScaleSetting: dockConfig.panelHoverScale
                        // qmllint disable unqualified
                        hoverAnimationMode:
                            dockLayout.effectiveHoverAnimationMode
                        persistentReorderActive:
                            dockLayout.persistentDragActive
                        persistentReorderGroupMember:
                            dockLayout.persistentDragMovesDynamicApplications
                        // qmllint enable unqualified
                        dockMotionSpeedPercent: dockConfig.dockMotionSpeedPercent
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
                        taskPopupTracksVisualArea: true
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
                        // qmllint disable unqualified
                        showPersistentLabel: dockConfig.dockShowLabels
                        textShadowsEnabled: dockConfig.dockTextShadowsEnabled
                        labelFontSize: dockConfig.dockLabelFontSize
                        indicatorType: dockConfig.dockIndicatorType
                        indicatorPosition: dockConfig.dockIndicatorPosition
                        indicatorColor: dockConfig.dockIndicatorColor
                        // qmllint disable unqualified
                        indicatorThickness: dockConfig.dockIndicatorThickness
                        indicatorOpacity: dockConfig.dockIndicatorOpacity
                        windowCountBadgeEnabled: dockConfig.windowCountBadgeEnabled
                        windowCountBadgePosition: dockConfig.windowCountBadgePosition
                        windowGroupingEnabled: taskController.groupingEnabled()
                        windowCountEmblemColor: dockConfig.windowCountEmblemColor
                        windowCountEmblemOpacity: dockConfig.windowCountEmblemOpacity
                        windowCountEmblemScale: dockConfig.windowCountEmblemScale
                        // qmllint enable unqualified
                        hoverZoomProgress: dockLayout.hoverZoomProgress
                        lastHoveredIndex: dockLayout.lastHoveredIndex
                        lastMouseOffset: dockLayout.lastMouseOffset

                        itemType: "app"
                        iconName: taskData.icon
                        itemName: taskData.name
                        taskIndicatorCount: taskData.count
                        taskIsActive: taskData.active
                        taskDemandsAttention: taskData.demandsAttention
                        // Popup ids belong to the owning full representation.
                        // qmllint disable unqualified
                        suppressTooltip: mainContainer.contextMenuVisible
                            || (taskWindowsDialog.visible && popupCoordinator.taskPopupVisualParent === taskDockItemDelegate)
                            || (folderPopupDialog.visible && folderPopupDialog.placementAnchor === taskDockItemDelegate)
                            || (calendarPopupDialog.visible && calendarPopupDialog.visualParent === taskDockItemDelegate)
                            || (notePopupDialog.visible && notePopupDialog.visualParent === taskDockItemDelegate)
                            || (trashMenuDialog.visible && trashMenuDialog.placementAnchor === taskDockItemDelegate)
                            || (appActionsDialog.visible && appActionsDialog.placementAnchor === taskDockItemDelegate)
                            || (root.punchiMenuDialogInstance && root.punchiMenuDialogInstance.visible && root.punchiMenuAnchorItem === taskDockItemDelegate)
                        // qmllint enable unqualified
                        supportsContextMenu: dockContextActionsController.itemHasContextMenu(modelData, taskData.rows, "dynamic")
                        mediaHoverControlsEnabled: dockConfig.mediaControlsOnHover && taskData.count > 0
                        externalDropEnabled: dockConfig.appDragAndDropEnabled
                        // qmllint disable unqualified
                        externalDropValidator: function(urls) {
                            return dockItemsController.validateDroppedUrls(urls)
                        }
                        launcherDropEnabled: true
                        launcherDropValidator: function(urls) {
                            return dockItemsController.validateApplicationLauncherDrop(urls)
                        }
                        externalDropActivationEnabled: taskData.count > 0
                            && !taskData.active
                        externalDropActivator: function() {
                            return taskController.activateTaskRowsForExternalDrop(taskData.rows)
                        }
                        // qmllint enable unqualified

                        // qmllint disable unqualified
                        TaskDelegateGeometryPublisher {
                            taskModelController: taskController
                            targetItem: taskDockItemDelegate.taskGeometryItem
                            taskRows: taskDockItemDelegate.taskData.rows
                            publicationEnabled: taskGeometryOwnership.ownsTaskGeometry
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
                        onExternalUrlsDropped: function(urls, visualParent) {
                            root.handleApplicationUrlsDrop(
                                modelData, taskData.rows, urls, visualParent)
                        }
                        onApplicationLauncherDropped: function(urls, insertionIndex) {
                            dockItemsController.pinApplicationLauncherAt(
                                urls, root.dynamicLauncherInsertionIndex())
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

                // Overflow is a synthetic terminal entry. It participates in
                // the same layout as regular dock items but never enters the
                // persistent or reorderable dock-items model.
                // qmllint disable unqualified
                DockItem {
                    id: taskOverflowDockItem
                    visible: root.overflowTaskRows.length > 0
                    layoutController: dockLayout
                    Layout.column: dockGeometry.verticalPanel
                        ? 0 : root.dynamicVisualIndex(root.visibleTaskRows.length)
                    Layout.row: dockGeometry.verticalPanel
                        ? root.dynamicVisualIndex(root.visibleTaskRows.length) : 0
                    Layout.preferredWidth: root.inPanel
                        ? dockGeometry.panelItemWidth : implicitWidth
                    Layout.preferredHeight: root.inPanel
                        ? dockGeometry.panelItemHeight : implicitHeight
                    itemIndex: root.dynamicVisualIndex(root.visibleTaskRows.length)
                    launcherModelInsertionIndex:
                        root.dynamicLauncherInsertionIndex()
                    hoveredIndex: dockLayout.hoveredIndex
                    inPanel: root.inPanel
                    panelLocation: dockGeometry.effectivePanelLocation
                    iconSize: dockGeometry.effectiveIconSize
                    hoverScaleSetting: dockConfig.panelHoverScale
                    hoverAnimationMode:
                        dockLayout.effectiveHoverAnimationMode
                    persistentReorderActive:
                        dockLayout.persistentDragActive
                    persistentReorderGroupMember:
                        dockLayout.persistentDragMovesDynamicApplications
                    dockMotionSpeedPercent: dockConfig.dockMotionSpeedPercent
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
                    iconReflectionEnabled: false
                    positionTransitionEnabled: dockItemsController.itemTransitionActive
                    hoverZoomProgress: dockLayout.hoverZoomProgress
                    lastHoveredIndex: dockLayout.lastHoveredIndex
                    lastMouseOffset: dockLayout.lastMouseOffset
                    itemType: "overflow"
                    iconName: "view-grid"
                    itemName: i18np("%1 more window group", "%1 more window groups",
                        root.overflowTaskRows.length)
                    taskIndicatorCount: root.overflowTaskRows.length
                    launcherDropEnabled: true
                    launcherDropValidator: function(urls) {
                        return dockItemsController.validateApplicationLauncherDrop(urls)
                    }

                    TaskDelegateGeometryPublisher {
                        taskModelController: taskController
                        targetItem: taskOverflowDockItem.taskGeometryItem
                        taskRows: taskController.taskRowsForEntries(root.overflowTaskRows)
                        publicationEnabled: taskGeometryOwnership.ownsTaskGeometry
                    }

                    onItemClicked: popupCoordinator.openTaskOverflowPopup(taskOverflowDockItem)
                    onTaskMinimized: function(minimizedItemIndex) {
                        dockItemsController.triggerMinimizeReaction(minimizedItemIndex)
                    }
                    onApplicationLauncherDropped: function(urls, insertionIndex) {
                        dockItemsController.pinApplicationLauncherAt(
                            urls, root.dynamicLauncherInsertionIndex())
                    }
                }
                // qmllint enable unqualified

            }

            DockReorderDragLayer {
                id: dockReorderDragLayer
                anchors.fill: parent
                z: 20
                active: dockLayout.persistentDragActive
                pointerPosition:
                    dockLayout.persistentDragPointerPosition
                iconName: dockLayout.persistentDragIconName
                iconSize: dockGeometry.effectiveIconSize
                motionEnabled: Kirigami.Units.longDuration > 0
            }
        }

        GuardedPositionedPopupDialog {
            id: folderPopupDialog
            inPanel: root.inPanel
            panelLocation: dockGeometry.effectivePanelLocation
            availableScreenRect: root.availableScreenRect
            screenGeometry: Plasmoid.containment
                && Plasmoid.containment.screenGeometry
                ? Plasmoid.containment.screenGeometry
                : Qt.rect(0, 0, Screen.width, Screen.height)
            floatingDockAnchor: root.floatingDockAnchor
            floatingDockSurfaceFrame: dockBackground
            panelWindow: root.Window.window
            panelThickness: dockGeometry.detectedPanelThickness
            popupGap: dockGeometry.folderPopupGap
            surfaceFrame: folderSurfaceStack
            hideOnWindowDeactivate: true

            mainItem: PopupAnimatedContent {
                popupVisible: folderPopupDialog.visible
                // qmllint disable unqualified
                animationStyle: dockConfig.popupAnimationStyle
                animationSpeedPercent: dockConfig.popupAnimationSpeedPercent
                animationIntensityPercent: dockConfig.popupAnimationIntensity
                popupDirection: popupCoordinator.popupDirection
                // qmllint enable unqualified

                ContextSurfaceStack {
                    id: folderSurfaceStack
                    maximumAvailableHeight: dockGeometry.taskPopupAvailableHeight
                    showMedia: false
                    // Folder profiles use different widths. Resolve the final
                    // geometry before mapping the dialog so Plasma can center
                    // it against visualParent without an intermediate width.
                    contentGeometryTransitionsEnabled: false
                    drawContentBackground: true
                    backgroundImagePath: "widgets/background"
                    backgroundOpacity: dockConfig.folderPopupBackgroundOpacity
                    contentFramePaddingPercent: 2
                    minimumSurfaceWidth: Kirigami.Units.smallSpacing
                    minimumSurfaceHeight: Kirigami.Units.smallSpacing

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
                        profileScale: dockConfig.folderPopupScale
                        showHeaderLabel: dockConfig.folderPopupShowHeader
                        textShadowsEnabled: dockConfig.popupTextShadowsEnabled
                        maximumAvailableWidth: dockGeometry.taskPopupAvailableWidth
                        maximumAvailableHeight: dockGeometry.taskPopupAvailableHeight
                        // qmllint enable unqualified

                        onAppLaunched: function(app) {
                            folderPopupDialog.closeSafely()
                            dockItemsController.launchDockItem(app)
                        }

                        onAppContextMenuRequested: function(app) {
                            popupCoordinator.openAppContextMenu(app,
                                folderPopupDialog.placementAnchor, undefined,
                                "folder", -1)
                        }

                        onCloseRequested: folderPopupDialog.closeSafely()
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
        GuardedPositionedPopupDialog {
            id: trashMenuDialog
            inPanel: root.inPanel
            panelLocation: dockGeometry.effectivePanelLocation
            availableScreenRect: root.availableScreenRect
            screenGeometry: Plasmoid.containment
                && Plasmoid.containment.screenGeometry
                ? Plasmoid.containment.screenGeometry
                : Qt.rect(0, 0, Screen.width, Screen.height)
            floatingDockAnchor: root.floatingDockAnchor
            floatingDockSurfaceFrame: dockBackground
            panelWindow: root.Window.window
            panelThickness: dockGeometry.detectedPanelThickness
            popupGap: dockGeometry.contextMenuGap
            surfaceFrame: trashSurfaceStack
            hideOnWindowDeactivate: !trashContextContent.confirmationVisible

            mainItem: PopupAnimatedContent {
                popupVisible: trashMenuDialog.visible
                // qmllint disable unqualified
                animationStyle: dockConfig.menuAnimationStyle
                animationSpeedPercent: dockConfig.menuAnimationSpeedPercent
                animationIntensityPercent: dockConfig.menuAnimationIntensity
                popupDirection: popupCoordinator.popupDirection
                // qmllint enable unqualified

                ContextSurfaceStack {
                    id: trashSurfaceStack
                    showMedia: false
                    maximumAvailableHeight: dockGeometry.taskPopupAvailableHeight
                    drawContentBackground: true
                    backgroundImagePath: "widgets/background"
                    backgroundOpacity: dockConfig.contextMenuBackgroundOpacity
                    contentFramePaddingPercent: 2
                    minimumSurfaceWidth: Kirigami.Units.smallSpacing
                    minimumSurfaceHeight: Kirigami.Units.smallSpacing

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
                            trashMenuDialog.closeSafely()
                            trashIntegration.openTrash()
                        }
                        onEmptyTrashRequested: {
                            trashIntegration.emptyTrash()
                        }
                        onCloseRequested: {
                            trashSuccessCloseTimer.stop()
                            trashMenuDialog.closeSafely()
                            if (!trashIntegration.emptying) {
                                trashIntegration.resetOperationState()
                                trashContextContent.showMenu()
                            }
                        }
                        // qmllint enable unqualified
                    }
                }
            }
        }

        GuardedPositionedPopupDialog {
            id: appActionsDialog
            inPanel: root.inPanel
            panelLocation: dockGeometry.effectivePanelLocation
            availableScreenRect: root.availableScreenRect
            screenGeometry: Plasmoid.containment
                && Plasmoid.containment.screenGeometry
                ? Plasmoid.containment.screenGeometry
                : Qt.rect(0, 0, Screen.width, Screen.height)
            floatingDockAnchor: root.floatingDockAnchor
            floatingDockSurfaceFrame: dockBackground
            panelWindow: root.Window.window
            panelThickness: dockGeometry.detectedPanelThickness
            popupGap: dockGeometry.contextMenuGap
            surfaceFrame: appActionsSurfaceStack
            hideOnWindowDeactivate: !popupCoordinator.contextMenuOpening
            onOpenFailed: popupCoordinator.contextMenuOpening = false

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
                    drawContentBackground: true
                    backgroundImagePath: "widgets/background"
                    backgroundOpacity: dockConfig.contextMenuBackgroundOpacity
                    contentFramePaddingPercent: 2
                    minimumSurfaceWidth: Kirigami.Units.smallSpacing
                    minimumSurfaceHeight: Kirigami.Units.smallSpacing

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
                            appActionsDialog.closeSafely()
                            dockContextActionsController.triggerAction(action)
                        }
                        onCloseRequested: {
                            appActionsDialog.closeSafely()
                        }
                    }
                }
            }
        }

        GuardedPopupDialog {
            id: notePopupDialog
            location: dockGeometry.effectivePanelLocation
            hideOnWindowDeactivate: true
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

                ContextSurfaceStack {
                    showMedia: false
                    maximumAvailableHeight: dockGeometry.taskPopupAvailableHeight
                    drawContentBackground: true
                    backgroundImagePath: "widgets/background"
                    backgroundOpacity:
                        root.configuredPunchiMenuNormalBackgroundOpacity
                    contentFramePaddingPercent: 2
                    contentFramePaddingScale: 1.5
                    minimumSurfaceWidth: Kirigami.Units.smallSpacing
                    minimumSurfaceHeight: Kirigami.Units.smallSpacing

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
                        onCloseRequested: notePopupDialog.closeSafely()
                        onClearRequested: function(noteText, popupWidth, popupHeight) {
                            notePopupContent.initialText = noteText
                            popupCoordinator.activeNoteData = dockItemsController.updateNoteItem(
                                popupCoordinator.activeNoteData, noteText, popupWidth,
                                popupHeight, popupCoordinator.activeNoteIndex)
                        }
                        onDeleteRequested: {
                            root.deletingActiveNote = true
                            notePopupDialog.closeSafely()
                            if (dockItemsController.removeNoteItemAtIndex(popupCoordinator.activeNoteIndex)) {
                                popupCoordinator.activeNoteData = ({})
                                popupCoordinator.activeNoteIndex = -1
                            }
                            root.deletingActiveNote = false
                        }
                    }
                }
            }
        }

        PlasmaCore.Dialog {
            id: taskWindowsDialog

            readonly property bool isX11Session: KWindowSystem.isPlatformX11
            property bool preparingToShow: false
            property int openRequestSerial: 0

            location: dockGeometry.effectivePanelLocation
            type: PlasmaCore.Dialog.AppletPopup
            flags: isX11Session
                ? Qt.Popup | Qt.FramelessWindowHint
                : Qt.Dialog | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
            visible: false
            hideOnWindowDeactivate: true
            backgroundHints: PlasmaCore.Dialog.NoBackground

            // qmllint disable unqualified
            function compactDynamicHorizontalAnchorEnabled() {
                return root.inPanel
                    && dockGeometry.horizontalPanel
                    && !dockGeometry.panelFillLengthEnabled
                    && popupCoordinator.taskPopupVisualParent
                    && popupCoordinator.taskPopupVisualParent.taskPopupTracksVisualArea
            }

            function applyCompactDynamicHorizontalAnchor() {
                if (!compactDynamicHorizontalAnchorEnabled()) {
                    return
                }
                const targetX = popupCoordinator.taskPopupHorizontalX(
                    width, root.availableScreenRect)
                if (Number.isFinite(targetX)) {
                    x = targetX
                }
            }

            function finishPreparedOpen(requestSerial, remainingAttempts) {
                if (requestSerial !== openRequestSerial || !preparingToShow) {
                    return
                }
                const widthReady = Number(taskPopupAnimatedContent.implicitWidth) > 0
                    && Number(taskPopupAnimatedContent.width) > 0
                const heightReady = Number(taskPopupAnimatedContent.implicitHeight) > 0
                    && Number(taskPopupAnimatedContent.height) > 0
                const surfaceReady = taskPopupSurface.geometryReady
                if (!surfaceReady || !widthReady || !heightReady) {
                    if (remainingAttempts > 0) {
                        Qt.callLater(function() {
                            taskWindowsDialog.finishPreparedOpen(requestSerial,
                                remainingAttempts - 1)
                        })
                    } else {
                        preparingToShow = false
                        popupCoordinator.resetTaskPopupState()
                    }
                    return
                }
                visible = true
                applyCompactDynamicHorizontalAnchor()
                preparingToShow = false
            }

            function openSafely() {
                openRequestSerial += 1
                const requestSerial = openRequestSerial
                preparingToShow = true
                Qt.callLater(function() {
                    taskWindowsDialog.finishPreparedOpen(requestSerial, 3)
                })
            }

            function closeSafely() {
                openRequestSerial += 1
                preparingToShow = false
                visible = false
            }
            // qmllint enable unqualified

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
                onCloseAnimationFinished: taskWindowsDialog.closeSafely()

                TaskPopupSurface {
                    id: taskPopupSurface
                    visible: taskWindowsDialog.visible
                        || taskWindowsDialog.preparingToShow
                    enabled: visible
                    presentationMode: popupCoordinator.activeTaskPopupPresentation
                    mediaController: mprisController
                    taskControllerRef: taskController
                    mediaWindows: popupCoordinator.activeTaskPopupData.windows || []
                    mediaIcon: popupCoordinator.activeTaskPopupData.icon || "emblem-music-symbolic"
                    mediaActionsComposed: taskWindowsPopupContent.mediaActionsComposed
                    // qmllint disable unqualified
                    backgroundOpacity: taskPopupSurface.replacementMediaPresentation
                        ? dockConfig.mediaCardBackgroundOpacity
                        : dockConfig.windowPreviewBackgroundOpacity
                    // qmllint enable unqualified
                    contentFramePaddingPercent: 2
                    contentFramePaddingScale: dockConfig.windowPreviewFrameScale
                    minimumSurfaceWidth: Kirigami.Units.smallSpacing
                    minimumSurfaceHeight: Kirigami.Units.smallSpacing
                    maximumSurfaceWidth: dockGeometry.taskPopupAvailableWidth
                    maximumSurfaceHeight: dockGeometry.taskPopupAvailableHeight
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
                        presentationMode: popupCoordinator.activeTaskPopupPresentation
                        mprisControllerRef: mprisController
                        previewScale: dockConfig.windowPreviewScale
                        previewInfoMode: dockConfig.windowPreviewInfoMode
                        windowPreviewTextShadowsEnabled: dockConfig.windowPreviewTextShadowsEnabled
                        menuTextShadowsEnabled: dockConfig.menuTextShadowsEnabled
                        maxVisibleRows: dockConfig.maxPopupRows
                        maximumAvailableWidth: taskPopupSurface.maximumContentWidth
                        maximumAvailableHeight: taskPopupSurface.maximumContentHeight
                        actionItemName: popupCoordinator.activeAppContextMenuData.name || ""
                        actions: popupCoordinator.activeAppContextMenuData.actions || []
                        // qmllint disable unqualified
                        maxVisibleActionRows: dockConfig.contextMenuVisibleRows
                        actionRowHeight: dockConfig.contextMenuRowHeight
                        actionIconSize: dockConfig.contextMenuIconSize
                        actionMenuWidth: dockConfig.contextMenuWidth
                        transitionDirection: dockConfig.contextMenuTransitionDirection
                        // qmllint enable unqualified
                        previewsEnabled: (taskWindowsDialog.visible
                                || taskWindowsDialog.preparingToShow)
                            && (popupCoordinator.activeTaskPopupPresentation === "preview"
                                || popupCoordinator.activeTaskPopupPresentation === "overlay")
                        returnToMedia: popupCoordinator.mediaHoverActive
                        transitionsEnabled: dockConfig.menuAnimationStyle !== "none"
                        // qmllint disable unqualified
                        transitionSpeedPercent: dockConfig.contextMenuTransitionSpeed
                        // qmllint enable unqualified

                        onActivateRequested: function(taskRow) {
                            taskWindowsDialog.closeSafely()
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
                        onMediaCloseRequested: popupCoordinator.closeMediaHoverFromKeyboard()
                        onActionTriggered: function(action) {
                            taskWindowsDialog.closeSafely()
                            dockContextActionsController.triggerAction(action)
                        }
                    }
                }
            }
        }

        GuardedPopupDialog {
            id: taskOverflowDialog
            location: dockGeometry.effectivePanelLocation
            hideOnWindowDeactivate: true

            mainItem: PopupAnimatedContent {
                popupVisible: taskOverflowDialog.visible
                // qmllint disable unqualified
                animationStyle: dockConfig.popupAnimationStyle
                animationSpeedPercent: dockConfig.popupAnimationSpeedPercent
                animationIntensityPercent: dockConfig.popupAnimationIntensity
                popupDirection: popupCoordinator.popupDirection
                // qmllint enable unqualified

                ContextSurfaceStack {
                    showMedia: false
                    maximumAvailableHeight: dockGeometry.taskPopupAvailableHeight
                    drawContentBackground: true
                    backgroundImagePath: "widgets/background"
                    backgroundOpacity: dockConfig.contextMenuBackgroundOpacity
                    contentFramePaddingPercent: 2
                    minimumSurfaceWidth: Kirigami.Units.smallSpacing
                    minimumSurfaceHeight: Kirigami.Units.smallSpacing

                    TaskOverflowPopup {
                        id: taskOverflowPopupContent
                        entries: root.overflowTaskRows
                        taskControllerRef: taskController
                        maxVisibleRows: dockConfig.maxPopupRows
                        textShadowsEnabled:
                            dockConfig.windowPreviewTextShadowsEnabled

                        onEntryActivated: function(entry) {
                            taskOverflowDialog.closeSafely()
                            if (entry.count > 1) {
                                popupCoordinator.openTaskWindowsPopup(entry.name,
                                    entry.rows, taskOverflowDockItem)
                            } else if (entry.firstRow >= 0) {
                                taskOverflowPopupContent.taskControllerRef
                                    .activateTaskRow(entry.firstRow)
                            }
                        }
                        onMinimizeWindowRequested: function(taskRow) {
                            taskOverflowPopupContent.taskControllerRef
                                .minimizeTaskRow(taskRow)
                        }
                        onMaximizeWindowRequested: function(taskRow) {
                            taskOverflowPopupContent.taskControllerRef
                                .toggleMaximizedTaskRow(taskRow)
                        }
                        onCloseWindowRequested: function(taskRow) {
                            taskOverflowPopupContent.taskControllerRef
                                .closeTaskRow(taskRow)
                        }
                        onCloseRequested: taskOverflowDialog.closeSafely()
                    }
                }
            }
        }

    }

}
