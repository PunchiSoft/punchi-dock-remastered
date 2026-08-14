import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.coreaddons as KCoreAddons
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import "../../org/punchi/dock" as Punchi

// qmllint disable import
// qmllint disable unqualified
FocusScope {
    id: root

    // Keep the fullscreen surface behind the dock, which remains interactive.
    z: 1
    visible: menuOpen || backdropContainer.opacity > 0.01
    enabled: menuOpen

    required property var systemDiscovery
    property var applicationCatalog: []
    property bool applicationCatalogLoaded: false
    property var applicationLayoutController: null
    property real applicationIconScale: 1.0
    property real favoriteIconScale: 1.0
    property int folderMaximumColumns: 5
    property int folderMaximumRows: 5
    property bool backgroundBlurEnabled: true
    property real backgroundOpacity: 0.50
    property bool showDistributionName: true
    property bool showPageNavigationArrows: true
    property bool showApplicationLabels: true
    property string hoverAnimation: "pulse"
    property bool sortApplicationsAlphabetically: false
    property string closeButtonPosition: "right"
    property var hiddenApplicationIds: []
    property bool revealHiddenApplications: false
    property bool menuOpen: false
    property bool applicationsLoading: false
    property bool applicationLaunchPending: false
    property bool suppressDragReleaseClick: false
    property int dragEdgeDirection: 0
    property bool dragEdgeArmed: true
    property string applicationErrorMessage: ""
    property string operationMessage: ""
    property bool operationMessageIsError: false
    property string settingsErrorMessage: ""
    property bool operationMessageDismissalInProgress: false
    property int operationSecondsRemaining: 0
    property string searchText: ""
    property int currentApplicationIndex: -1
    property bool pageNavigationActive: false
    property int pendingPageStep: 0
    property real wheelPageAccumulator: 0
    property bool wheelGestureCommitted: false
    property string contentViewActive: "applications"
    property string contentViewRequested: "applications"
    property real modeContentOpacity: 1.0

    readonly property bool motionEnabled: Kirigami.Units.longDuration > 0
    readonly property bool applicationViewActive:
        contentViewActive === "applications"
    readonly property bool sessionViewActive: contentViewActive === "session"
    readonly property bool sessionViewRequested:
        contentViewRequested === "session"
    readonly property bool settingsViewActive: contentViewActive === "settings"
    readonly property bool settingsViewRequested:
        contentViewRequested === "settings"
    readonly property bool closeButtonOnLeft: closeButtonPosition === "left"
    readonly property int closeButtonCornerMargin: Kirigami.Units.gridUnit
    readonly property bool modeTransitionActive: modeFadeOutAnimation.running
        || modeFadeInAnimation.running
    readonly property string distributionName: systemDiscovery
        ? String(systemDiscovery.distributionName || "").trim()
        : ""
    readonly property string distributionLogo: systemDiscovery
        ? String(systemDiscovery.distributionLogo || "").trim()
        : ""
    readonly property real safeBackgroundOpacity: {
        const requestedOpacity = Number(backgroundOpacity)
        return Number.isFinite(requestedOpacity)
            ? Math.max(0.50, Math.min(1.0, requestedOpacity))
            : 0.50
    }
    readonly property real safeApplicationIconScale: {
        const requestedScale = Number(applicationIconScale)
        return Number.isFinite(requestedScale)
            ? Math.max(0.75, Math.min(1.5, requestedScale))
            : 1.0
    }
    readonly property real safeFavoriteIconScale: {
        const requestedScale = Number(favoriteIconScale)
        return Number.isFinite(requestedScale)
            ? Math.max(0.75, Math.min(1.1, requestedScale))
            : 1.0
    }
    readonly property int safeFolderMaximumColumns: {
        const requestedCount = Number(folderMaximumColumns)
        return Number.isFinite(requestedCount)
            ? Math.max(1, Math.min(5, Math.round(requestedCount)))
            : 5
    }
    readonly property int safeFolderMaximumRows: {
        const requestedCount = Number(folderMaximumRows)
        return Number.isFinite(requestedCount)
            ? Math.max(1, Math.min(5, Math.round(requestedCount)))
            : 5
    }
    readonly property var hiddenApplicationLookup: {
        const source = hiddenApplicationIds instanceof Array
            ? hiddenApplicationIds
            : []
        const lookup = {}
        for (let index = 0; index < source.length && index < 512; index++) {
            const storageId = String(source[index] || "").trim()
            if (storageId.length === 0 || storageId.length > 512
                    || /[\u0000-\u001f\u007f]/.test(storageId)) {
                continue
            }
            lookup["#" + storageId] = true
        }
        return lookup
    }
    readonly property int hiddenApplicationCount: {
        let count = 0
        const source = applicationCatalog
        const sourceCount = source.length
        for (let index = 0; index < sourceCount; index++) {
            const storageId = String(source[index].storageId
                || source[index].appStorageId || "").trim()
            if (storageId.length > 0
                    && hiddenApplicationLookup["#" + storageId]) {
                count++
            }
        }
        return count
    }
    readonly property int gridColumns: Math.max(4, Math.min(8,
        Math.floor(Math.max(1, pagesView.width) / (Kirigami.Units.gridUnit * 7))))
    readonly property int gridRows: Math.max(3, Math.min(5,
        Math.floor(Math.max(1, pagesView.height) / (Kirigami.Units.gridUnit * 6))))
    readonly property int pageCapacity: Math.max(1, gridColumns * gridRows)
    readonly property bool organizedListingActive:
        searchText.trim().length === 0
        && applicationCatalogLoaded
    readonly property var visibleApplications: {
        const result = []
        const query = searchText.trim().toLocaleLowerCase()
        if (organizedListingActive) {
            const organizedNodes = applicationLayoutModel.nodes || []
            for (let index = 0; index < organizedNodes.length; index++) {
                const node = organizedNodes[index]
                if (!node) {
                    continue
                }
                result.push(node)
            }
            return result
        }
        const source = applicationCatalog
        const sourceCount = source.length
        for (let index = 0; index < sourceCount; index++) {
            const app = source[index]
            const appName = String(app.name || app.appName || "")
            const appStorageId = String(app.storageId
                || app.appStorageId || "")
            const appHidden = isApplicationHidden(appStorageId)
            if (appHidden && !revealHiddenApplications) {
                continue
            }
            if (query.length > 0 && appName.toLocaleLowerCase().indexOf(query) < 0) {
                continue
            }
            result.push({
                appName: appName,
                appIcon: String(app.icon || app.appIcon
                    || "application-x-executable"),
                appStorageId: appStorageId,
                appCommand: "",
                appHidden: appHidden
            })
        }
        return result
    }
    readonly property int pageCount: visibleApplications.length > 0
        ? Math.ceil(visibleApplications.length / pageCapacity)
        : 0
    readonly property bool favoritesSectionVisible: applicationViewActive
        && favorites.length > 0
        && searchText.trim().length === 0
    readonly property bool pageTransitionActive: pageCount > 0
        && (pagesView.moving || Math.abs(pagesView.contentX
            - pagesView.currentIndex * Math.max(1, pagesView.width)) > 0.5)
    readonly property bool applicationHoverAllowed: applicationViewActive
        && !modeTransitionActive
        && !pageTransitionActive
        && !applicationLaunchPending
        && !internalDragLayer.active
    readonly property real responsiveApplicationIconBase: Math.max(
        Kirigami.Units.iconSizes.large,
        Math.min(Kirigami.Units.iconSizes.huge, Math.min(width, height) / 15))
    readonly property int pageIndicatorDotDiameter: Math.round(Math.max(
        Kirigami.Units.smallSpacing * 0.75,
        Math.min(Kirigami.Units.gridUnit * 0.5, Math.min(width, height) / 220)))
    readonly property int pageIndicatorTargetDiameter: Math.round(Math.max(
        Kirigami.Units.gridUnit * 1.5, pageIndicatorDotDiameter * 3))
    readonly property int compactSearchWidth: Math.round(Math.max(
        Kirigami.Units.gridUnit * 14,
        Math.min(width * 0.24, Kirigami.Units.gridUnit * 20)))
    readonly property int headerControlSize: Kirigami.Units.gridUnit * 2
    readonly property int operationMessageDuration: 7000
    readonly property string operationBaseMessage: operationMessage.length > 0
        ? operationMessage
        : applicationErrorMessage.length > 0
            ? i18nc("@info:status", "Application could not be opened: %1",
                applicationErrorMessage)
            : ""
    readonly property string operationCountdownText:
        operationBaseMessage.length > 0 && operationSecondsRemaining > 0
            ? i18nc("@info:status %1 is the result and %2 is seconds remaining",
                "%1 · %2 s", operationBaseMessage, operationSecondsRemaining)
            : operationBaseMessage
    readonly property int applicationGridHorizontalInset: Math.round(Math.max(0,
        width * 0.15 - Kirigami.Units.gridUnit * 3))
    readonly property int animOpenDuration: Math.round(Kirigami.Units.longDuration * 1.1)
    readonly property int animCloseDuration: Math.round(Kirigami.Units.shortDuration * 1.4)
    readonly property int modeFadeOutDuration: Math.max(
        Kirigami.Units.shortDuration,
        Math.round(Kirigami.Units.longDuration * 0.6))
    readonly property int modeFadeInDuration: Math.max(
        Kirigami.Units.shortDuration,
        Math.round(Kirigami.Units.longDuration * 0.85))
    readonly property int pageInputWindow: motionEnabled
        ? Math.max(Kirigami.Units.shortDuration, 120)
        : 120
    readonly property int wheelGestureIdleWindow: Math.max(
        Kirigami.Units.shortDuration, 180)
    readonly property real wheelPixelThreshold: Math.max(
        Kirigami.Units.gridUnit * 2.5, 40)

    property var dockItemsController: null

    QtObject {
        id: folderSurface

        readonly property bool active: {
            const surface = loadedSurface()
            return Boolean(surface && surface.active)
        }

        function loadedSurface() {
            return folderSurfaceLoader.item
        }

        function ensureLoaded() {
            folderSurfaceLoader.active = true
            return folderSurfaceLoader.item
        }

        function beginCreate(application) {
            const surface = ensureLoaded()
            return surface ? surface.beginCreate(application) : false
        }

        function beginCreateFromStorageIds(storageIds) {
            const surface = ensureLoaded()
            return surface
                ? surface.beginCreateFromStorageIds(storageIds) : false
        }

        function beginDissolve(folderId) {
            const surface = ensureLoaded()
            return surface ? surface.beginDissolve(folderId) : false
        }

        function beginMove(application) {
            const surface = ensureLoaded()
            return surface ? surface.beginMove(application) : false
        }

        function beginRemove(application, folderId) {
            const surface = ensureLoaded()
            return surface
                ? surface.beginRemove(application, folderId) : false
        }

        function beginRename(folderId) {
            const surface = ensureLoaded()
            return surface ? surface.beginRename(folderId) : false
        }

        function closeCurrentView() {
            const surface = loadedSurface()
            if (surface) {
                surface.closeCurrentView()
            }
        }

        function openFolder(folderId) {
            const surface = ensureLoaded()
            return surface ? surface.openFolder(folderId) : false
        }

        function reset() {
            const surface = loadedSurface()
            if (surface) {
                surface.reset()
            }
        }

        function restoreFocus() {
            const surface = loadedSurface()
            if (surface) {
                surface.restoreFocus()
            }
        }
    }
    property var favorites: []

    signal closeFinished()
    signal addFavoriteRequested(string storageId)
    signal removeFavoriteRequested(string storageId)
    signal pinToDockRequested(string storageId, string appName, string appIcon, string appCommand)
    signal addToDesktopRequested(string storageId, string appCommand)
    signal setApplicationHiddenRequested(string storageId, bool hidden)
    signal configureRequested()
    signal settingChangeRequested(string fieldName, var value)

    Punchi.BlurBehindController {
        id: nativeBlurController
        window: root.Window.window
        fullWindow: true
        enabled: root.menuOpen && root.backgroundBlurEnabled
    }

    KCoreAddons.KUser {
        id: currentUser
    }

    Punchi.SessionActionsController {
        id: sessionActions
    }

    Punchi.PunchiMenuLayoutModel {
        id: applicationLayoutModel

        applications: root.applicationCatalog
        layoutDocument: root.applicationLayoutController
            ? root.applicationLayoutController.layoutDocument
            : ({})
        hiddenApplicationIds: root.hiddenApplicationIds
        revealHiddenApplications: root.revealHiddenApplications
        alphabeticalSortingEnabled: root.sortApplicationsAlphabetically
    }

    Connections {
        target: root.applicationLayoutController
        enabled: target !== null

        function onTransactionCommitted(transactionId, operation, subjectId) {
            root.operationMessage = root.applicationLayoutController.canUndo
                ? i18nc("@info:status", "Application folder updated.")
                : i18nc("@info:status", "Application folder change undone.")
            root.operationMessageIsError = false
        }

        function onTransactionFailed(transactionId, operation, errorCode) {
            root.operationMessage = i18nc("@info:status",
                "The application folder could not be updated.")
            root.operationMessageIsError = true
        }
    }

    Connections {
        target: root.Window.window
        enabled: target !== null
        ignoreUnknownSignals: true

        function onActiveChanged() {
            if (internalDragLayer.active && root.Window.window
                    && !root.Window.window.active) {
                root.cancelInternalLayoutDrag()
            }
        }
    }

    function showOperationResult(result) {
        operationMessage = result && result.message ? String(result.message) : ""
        operationMessageIsError = !(result && result.success)
    }

    function updateOperationMessageTimer() {
        if (operationMessageDismissalInProgress) {
            return
        }
        operationMessageTimer.stop()
        const messageAvailable = operationMessage.length > 0
            || applicationErrorMessage.length > 0
        operationInlineMessage.visible = applicationViewActive
            && messageAvailable
        operationSecondsRemaining = messageAvailable
            ? Math.max(1, Math.ceil(operationMessageDuration / 1000)) : 0
        if (messageAvailable && !operationInlineMessageHover.hovered) {
            operationMessageTimer.start()
        }
    }

    function dismissOperationMessage() {
        operationMessageDismissalInProgress = true
        operationMessageTimer.stop()
        operationSecondsRemaining = 0
        operationMessage = ""
        applicationErrorMessage = ""
        operationInlineMessage.visible = false
        operationMessageDismissalInProgress = false
    }

    function requestFolderUndo() {
        if (!applicationLayoutController
                || !applicationLayoutController.canUndo) {
            return
        }
        const result = applicationLayoutController.requestUndo()
        if (!result || result.accepted !== true) {
            operationMessage = i18nc("@info:status",
                "The last folder change could not be undone.")
            operationMessageIsError = true
        }
    }

    function isFavorite(storageId) {
        const requestedId = String(storageId || "").trim()
        if (requestedId.length === 0 || !root.favorites) {
            return false
        }
        for (let index = 0; index < root.favorites.length; index++) {
            if (String(root.favorites[index].appStorageId || "").trim()
                    === requestedId) {
                return true
            }
        }
        return false
    }

    function isApplicationHidden(storageId) {
        const normalizedId = String(storageId || "").trim()
        return normalizedId.length > 0
            && !!hiddenApplicationLookup["#" + normalizedId]
    }

    function horizontalScrollLimit(view) {
        return Math.max(0, view.contentWidth - view.width)
    }

    function scrollFavoritesBy(distance) {
        const currentPosition = Number(favoritesView.contentX)
        const pendingPosition = favoritesScrollAnimation.running
            ? Number(favoritesScrollAnimation.to)
            : currentPosition
        const targetPosition = Math.max(0, Math.min(
            horizontalScrollLimit(favoritesView), pendingPosition + distance))

        favoritesScrollAnimation.stop()
        if (!motionEnabled || Math.abs(targetPosition - currentPosition) < 0.5) {
            favoritesView.contentX = targetPosition
            return
        }

        favoritesScrollAnimation.to = targetPosition
        favoritesScrollAnimation.start()
    }

    function openApplicationContextMenu(sourceItem, storageId, appName, appIcon, appCommand, x, y) {
        const normalizedId = String(storageId || "").trim()
        const normalizedCmd = String(appCommand || "").trim()
        const primaryId = normalizedId.length > 0 ? normalizedId : normalizedCmd
        if (!sourceItem || primaryId.length === 0) {
            return
        }
        const placement = applicationLayoutModel.applicationPlacement(normalizedId)
        const targetMenu = String(placement.placement || "missing") === "folder"
            ? folderMemberContextMenu : standaloneApplicationContextMenu
        closeContextMenusExcept(targetMenu)
        targetMenu.targetStorageId = normalizedId
        targetMenu.targetAppCommand = normalizedCmd
        targetMenu.targetAppName = String(appName || "")
        targetMenu.targetAppIcon = String(appIcon || "")
        targetMenu.targetIsFavorite = isFavorite(primaryId)
        targetMenu.targetIsPinnedToDock = root.dockItemsController
            ? root.dockItemsController.isAppPinnedToDock(normalizedId, normalizedCmd)
            : false
        targetMenu.targetIsHidden = isApplicationHidden(normalizedId)
        if (targetMenu === folderMemberContextMenu) {
            targetMenu.targetContainingFolderId = String(
                placement.folderId || "")
        }
        requestContextMenu(targetMenu, sourceItem, x, y)
    }

    function openFolderContextMenu(sourceItem, folder, x, y) {
        const folderId = String(folder ? folder.folderId || "" : "").trim()
        if (!sourceItem || folderId.length === 0) {
            return
        }
        closeContextMenusExcept(folderContextMenu)
        folderContextMenu.targetFolderId = folderId
        requestContextMenu(folderContextMenu, sourceItem, x, y)
    }

    function closeContextMenusExcept(exception) {
        const menus = [standaloneApplicationContextMenu,
            folderMemberContextMenu, folderContextMenu]
        for (let index = 0; index < menus.length; index++) {
            const menu = menus[index]
            if (menu === exception) {
                continue
            }
            menu.pendingSourceItem = null
            if (menu.opened || menu.visible) {
                menu.close()
            }
        }
    }

    function requestContextMenu(menu, sourceItem, x, y) {
        if (!menu || !sourceItem) {
            return
        }
        if (menu.opened || menu.visible) {
            menu.pendingSourceItem = sourceItem
            menu.pendingPopupX = Number(x)
            menu.pendingPopupY = Number(y)
            menu.close()
            return
        }
        menu.pendingSourceItem = null
        menu.popup(sourceItem, Number(x), Number(y))
    }

    function completeContextMenuClose(menu) {
        const sourceItem = menu.pendingSourceItem
        const popupX = menu.pendingPopupX
        const popupY = menu.pendingPopupY
        menu.pendingSourceItem = null
        if (root.menuOpen && sourceItem) {
            Qt.callLater(function() {
                if (root.menuOpen && sourceItem) {
                    menu.popup(sourceItem, popupX, popupY)
                }
            })
            return
        }
        if (folderSurface.active) {
            folderSurface.restoreFocus()
        }
    }

    function toggleContextFavorite(contextMenu) {
        const storageId = contextMenu.targetStorageId
            || contextMenu.targetAppCommand
        if (contextMenu.targetIsFavorite) {
            root.removeFavoriteRequested(storageId)
        } else {
            root.addFavoriteRequested(storageId)
        }
    }

    function toggleContextDockPin(contextMenu) {
        root.pinToDockRequested(
            contextMenu.targetStorageId,
            contextMenu.targetAppName,
            contextMenu.targetAppIcon,
            contextMenu.targetAppCommand)
    }

    function addContextApplicationToDesktop(contextMenu) {
        root.addToDesktopRequested(
            contextMenu.targetStorageId,
            contextMenu.targetAppCommand)
    }

    function toggleContextApplicationHidden(contextMenu) {
        root.setApplicationHiddenRequested(
            contextMenu.targetStorageId,
            !contextMenu.targetIsHidden)
    }

    function openCurrentApplicationContextMenu() {
        const app = applicationAt(currentApplicationIndex)
        if (!app) {
            return false
        }
        const localIndex = currentApplicationIndex % pageCapacity
        const cellWidth = pagesView.width / Math.max(1, gridColumns)
        const cellHeight = pagesView.height / Math.max(1, gridRows)
        const column = localIndex % gridColumns
        const row = Math.floor(localIndex / gridColumns)
        if (String(app.nodeType || "") === "folder") {
            openFolderContextMenu(pagesView, app,
                (column + 0.5) * cellWidth,
                (row + 0.5) * cellHeight)
        } else {
            openApplicationContextMenu(
                pagesView,
                String(app.appStorageId || ""),
                String(app.appName || ""),
                String(app.appIcon || ""),
                String(app.appCommand || ""),
                (column + 0.5) * cellWidth,
                (row + 0.5) * cellHeight)
        }
        return true
    }

    function openCurrentFavoriteContextMenu() {
        const currentItem = favoritesView.currentItem
        const index = favoritesView.currentIndex
        if (!currentItem || index < 0 || index >= favorites.length) {
            return false
        }
        const favorite = favorites[index]
        openApplicationContextMenu(
            currentItem,
            String(favorite.appStorageId || ""),
            String(favorite.appName || ""),
            String(favorite.appIcon || ""),
            String(favorite.appCommand || ""),
            currentItem.width / 2,
            currentItem.height / 2)
        return true
    }

    function applicationsForPage(pageIndex) {
        const firstIndex = Math.max(0, pageIndex) * pageCapacity
        return visibleApplications.slice(firstIndex,
            Math.min(firstIndex + pageCapacity, visibleApplications.length))
    }

    function isInternalLayoutDrag(event) {
        return internalDragLayer.active && event
            && event.source === internalDragLayer.dragSource
            && event.keys && event.keys.indexOf(internalDragLayer.dragKey) >= 0
    }

    function beginInternalLayoutDrag(application, sourceItem, x, y) {
        if (!organizedListingActive || folderSurface.active
                || !applicationViewActive || applicationLaunchPending
                || !applicationLayoutController
                || applicationLayoutController.transactionPending) {
            return false
        }
        const nodeId = String(application ? application.nodeId || "" : "")
        if (!sourceItem || nodeId.length === 0) {
            return false
        }
        closeContextMenusExcept(null)
        resetPageNavigation()
        resetWheelGesture()
        const position = sourceItem.mapToItem(root, x, y)
        const started = internalDragLayer.begin(application, position,
            Qt.size(sourceItem.width, sourceItem.height))
        if (started) {
            suppressDragReleaseClick = true
            updateDragEdge(position)
        }
        return started
    }

    function updateInternalLayoutDrag(sourceItem, x, y) {
        if (!internalDragLayer.active || !sourceItem) {
            return
        }
        const position = sourceItem.mapToItem(root, x, y)
        internalDragLayer.move(position)
        updateDragEdge(position)
    }

    function finishInternalLayoutDrag() {
        dragEdgeTimer.stop()
        dragEdgeDirection = 0
        dragEdgeArmed = true
        internalDragLayer.drop()
        Qt.callLater(function() {
            root.suppressDragReleaseClick = false
        })
    }

    function cancelInternalLayoutDrag() {
        dragEdgeTimer.stop()
        dragEdgeDirection = 0
        dragEdgeArmed = true
        internalDragLayer.cancel()
        Qt.callLater(function() {
            root.suppressDragReleaseClick = false
        })
    }

    function updateDragEdge(position) {
        if (!internalDragLayer.active || pageCount <= 1) {
            dragEdgeTimer.stop()
            dragEdgeDirection = 0
            return
        }
        const edgeWidth = Math.max(Kirigami.Units.gridUnit * 3,
            applicationGridHorizontalInset * 0.45)
        let nextDirection = 0
        if (position.x <= gridArea.x + edgeWidth
                && pagesView.currentIndex > 0) {
            nextDirection = -1
        } else if (position.x >= gridArea.x + gridArea.width - edgeWidth
                && pagesView.currentIndex < pageCount - 1) {
            nextDirection = 1
        }
        if (nextDirection === 0) {
            dragEdgeTimer.stop()
            dragEdgeDirection = 0
            dragEdgeArmed = true
            return
        }
        if (dragEdgeDirection !== nextDirection) {
            dragEdgeDirection = nextDirection
            dragEdgeArmed = true
            dragEdgeTimer.restart()
        } else if (dragEdgeArmed && !dragEdgeTimer.running) {
            dragEdgeTimer.restart()
        }
    }

    function requestDraggedNodeMove(beforeNodeId) {
        if (root.sortApplicationsAlphabetically
                || !applicationLayoutController
                || typeof applicationLayoutController.requestMoveNode
                    !== "function") {
            return false
        }
        const result = applicationLayoutController.requestMoveNode(
            internalDragLayer.nodeId, String(beforeNodeId || ""))
        if (!result || result.accepted !== true) {
            if (result && String(result.errorCode || "") === "no-change") {
                return false
            }
            operationMessage = i18nc("@info:status",
            "The application folder could not be updated.")
            operationMessageIsError = true
            return false
        }
        return true
    }

    function handleDraggedNodeDrop(targetApplication) {
        if (!internalDragLayer.active || !targetApplication) {
            return false
        }
        const targetNodeId = String(targetApplication.nodeId || "")
        if (targetNodeId.length === 0
                || targetNodeId === internalDragLayer.nodeId) {
            return false
        }
        if (internalDragLayer.folder) {
            if (root.sortApplicationsAlphabetically) {
                return false
            }
            return requestDraggedNodeMove(targetNodeId)
        }
        if (String(targetApplication.nodeType || "") === "folder") {
            const folderId = String(targetApplication.folderId || "")
            if (folderId.length === 0) {
                return false
            }
            const result = applicationLayoutController
                .requestAddApplicationToFolder(
                    internalDragLayer.storageId, folderId)
            if (!result || result.accepted !== true) {
                operationMessage = i18nc("@info:status",
                    "The application folder could not be updated.")
                operationMessageIsError = true
                return false
            }
            return true
        }
        const targetStorageId = String(targetApplication.appStorageId || "")
        if (internalDragLayer.storageId.length === 0
                || targetStorageId.length === 0
                || internalDragLayer.storageId === targetStorageId) {
            return false
        }
        return folderSurface.beginCreateFromStorageIds([
            internalDragLayer.storageId, targetStorageId
        ])
    }

    function beforeNodeIdForInsertion(targetIndex, insertAfter) {
        let candidateIndex = Number(targetIndex) + (insertAfter ? 1 : 0)
        while (candidateIndex >= 0
                && candidateIndex < visibleApplications.length) {
            const candidate = applicationAt(candidateIndex)
            const candidateNodeId = String(candidate
                ? candidate.nodeId || "" : "")
            if (candidateNodeId.length > 0
                    && candidateNodeId !== internalDragLayer.nodeId) {
                return candidateNodeId
            }
            candidateIndex += 1
        }
        return ""
    }

    function nodeIdForGridDrop(pageIndex, x, y, grid) {
        if (!grid || gridColumns <= 0 || gridRows <= 0) {
            return ""
        }
        const cellWidth = (grid.width - grid.columnSpacing
            * (gridColumns - 1)) / gridColumns
        const cellHeight = (grid.height - grid.rowSpacing
            * (gridRows - 1)) / gridRows
        const column = Math.max(0, Math.min(gridColumns - 1,
            Math.floor(x / Math.max(1, cellWidth + grid.columnSpacing))))
        const row = Math.max(0, Math.min(gridRows - 1,
            Math.floor(y / Math.max(1, cellHeight + grid.rowSpacing))))
        const targetIndex = pageIndex * pageCapacity + row * gridColumns + column
        if (targetIndex < 0 || targetIndex >= visibleApplications.length) {
            return ""
        }
        return String(visibleApplications[targetIndex].nodeId || "")
    }

    function applicationAt(index) {
        if (index < 0 || index >= visibleApplications.length) {
            return null
        }
        return visibleApplications[index]
    }

    function restoreApplicationNodeFocus(nodeId) {
        let targetIndex = -1
        const requestedNodeId = String(nodeId || "")
        if (organizedListingActive && requestedNodeId.length > 0) {
            targetIndex = applicationLayoutModel.indexForNodeId(requestedNodeId)
        }
        if (targetIndex < 0 && visibleApplications.length > 0) {
            targetIndex = Math.max(0, Math.min(
                visibleApplications.length - 1, currentApplicationIndex))
        }
        setCurrentApplication(targetIndex)
        root.forceActiveFocus()
    }

    function pageForApplication(index) {
        return index >= 0 ? Math.floor(index / pageCapacity) : 0
    }

    function ensureSelectionOnPage(pageIndex) {
        if (visibleApplications.length === 0) {
            currentApplicationIndex = -1
            return
        }
        const firstIndex = Math.max(0, pageIndex) * pageCapacity
        const lastIndex = Math.min(visibleApplications.length - 1,
            firstIndex + pageCapacity - 1)
        if (currentApplicationIndex < firstIndex || currentApplicationIndex > lastIndex) {
            currentApplicationIndex = firstIndex
        }
    }

    function goToPage(pageIndex) {
        if (pageCount <= 0) {
            pagesView.currentIndex = 0
            currentApplicationIndex = -1
            return
        }
        const safePage = Math.max(0, Math.min(pageCount - 1, pageIndex))
        pagesView.currentIndex = safePage
        ensureSelectionOnPage(safePage)
    }

    function alignCurrentPage() {
        if (pageCount <= 0 || pagesView.count <= 0) {
            return
        }
        const safePage = Math.max(0, Math.min(pageCount - 1,
            pagesView.currentIndex))
        pagesView.positionViewAtIndex(safePage, ListView.Beginning)
    }

    onShowPageNavigationArrowsChanged: Qt.callLater(function() {
        root.alignCurrentPage()
    })

    function applyPageStep(step) {
        goToPage(pagesView.currentIndex + (step < 0 ? -1 : 1))
    }

    function requestPageStep(step, fromInternalDrag) {
        if (!menuOpen || pageCount <= 1) {
            return
        }
        if (internalDragLayer.active && fromInternalDrag !== true) {
            return
        }
        const normalizedStep = step < 0 ? -1 : 1
        if (pageNavigationActive) {
            pendingPageStep = normalizedStep
            return
        }
        pageNavigationActive = true
        pendingPageStep = 0
        applyPageStep(normalizedStep)
        pageNavigationTimer.restart()
    }

    function resetPageNavigation() {
        pageNavigationTimer.stop()
        pageNavigationActive = false
        pendingPageStep = 0
    }

    function resetWheelGesture() {
        wheelGestureResetTimer.stop()
        wheelPageAccumulator = 0
        wheelGestureCommitted = false
    }

    function handlePageWheel(wheel) {
        if (internalDragLayer.active) {
            wheel.accepted = true
            return
        }
        const pixelX = Number(wheel.pixelDelta.x)
        const pixelY = Number(wheel.pixelDelta.y)
        const usesPixelDelta = pixelX !== 0 || pixelY !== 0
        const horizontalDelta = usesPixelDelta ? pixelX : Number(wheel.angleDelta.x)
        const verticalDelta = usesPixelDelta ? pixelY : Number(wheel.angleDelta.y)
        const navigationDelta = Math.abs(horizontalDelta) > Math.abs(verticalDelta)
            ? horizontalDelta
            : -verticalDelta

        if (!Number.isFinite(navigationDelta) || navigationDelta === 0) {
            wheel.accepted = false
            return
        }

        wheel.accepted = true
        wheelGestureResetTimer.restart()
        if (wheelGestureCommitted) {
            return
        }

        wheelPageAccumulator += navigationDelta
        const threshold = usesPixelDelta ? wheelPixelThreshold : 120
        if (Math.abs(wheelPageAccumulator) < threshold) {
            return
        }

        const step = wheelPageAccumulator < 0 ? -1 : 1
        wheelPageAccumulator = 0
        wheelGestureCommitted = true
        if (!pageNavigationActive) {
            requestPageStep(step)
        }
    }

    function setCurrentApplication(index) {
        if (visibleApplications.length === 0) {
            currentApplicationIndex = -1
            return
        }
        currentApplicationIndex = Math.max(0,
            Math.min(visibleApplications.length - 1, index))
        const targetPage = pageForApplication(currentApplicationIndex)
        if (targetPage !== pagesView.currentIndex) {
            goToPage(targetPage)
        }
    }

    function launchApplicationAt(index) {
        const app = applicationAt(index)
        if (!app) {
            return
        }
        if (String(app.nodeType || "") === "folder") {
            folderSurface.openFolder(String(app.folderId || ""))
            return
        }
        if (String(app.appStorageId || "").length === 0) {
            return
        }
        applicationErrorMessage = ""
        applicationLaunchPending = true
        systemDiscovery.launchApplication(String(app.appStorageId))
    }

    function launchFavoriteAt(index) {
        if (applicationLaunchPending || index < 0 || index >= favorites.length) {
            return
        }
        const favorite = favorites[index]
        const storageId = String(favorite.appStorageId || "").trim()
        if (storageId.length === 0) {
            applicationErrorMessage = i18nc("@info:status",
                "This application could not be resolved safely.")
            return
        }
        favoritesView.currentIndex = index
        applicationErrorMessage = ""
        applicationLaunchPending = true
        systemDiscovery.launchApplication(storageId)
    }

    function resetPagination() {
        resetPageNavigation()
        resetWheelGesture()
        Qt.callLater(function() {
            if (!root.menuOpen) {
                return
            }
            root.currentApplicationIndex = root.visibleApplications.length > 0 ? 0 : -1
            root.goToPage(0)
        })
    }

    function reconcileApplicationSelection() {
        if (!menuOpen) {
            return
        }
        if (visibleApplications.length === 0) {
            currentApplicationIndex = -1
            pagesView.currentIndex = 0
            return
        }

        const requestedIndex = currentApplicationIndex < 0
            ? 0 : currentApplicationIndex
        currentApplicationIndex = Math.max(0, Math.min(
            visibleApplications.length - 1, requestedIndex))
        const targetPage = Math.max(0, Math.min(pageCount - 1,
            pageForApplication(currentApplicationIndex)))
        if (pagesView.currentIndex !== targetPage) {
            pagesView.currentIndex = targetPage
        }
    }

    function normalizedContentView(viewName) {
        const requestedView = String(viewName || "applications")
        return requestedView === "session" || requestedView === "settings"
            ? requestedView : "applications"
    }

    function commitContentViewState(viewName) {
        contentViewActive = normalizedContentView(viewName)
        resetPageNavigation()
        resetWheelGesture()
        if (!applicationViewActive) {
            searchText = ""
            currentApplicationIndex = -1
        } else {
            resetPagination()
        }
    }

    function focusCurrentMode() {
        if (!menuOpen) {
            return
        }
        if (sessionViewActive) {
            const loadedSessionView = sessionViewItem()
            if (loadedSessionView) {
                loadedSessionView.focusInitialAction()
            }
        } else if (settingsViewActive) {
            const loadedSettingsView = settingsViewItem()
            if (loadedSettingsView) {
                loadedSettingsView.focusInitialAction()
            }
        } else {
            searchField.forceActiveFocus()
        }
    }

    function sessionViewItem() {
        return sessionViewLoader.item
    }

    function settingsViewItem() {
        return settingsViewLoader.item
    }

    function resetContentTransition() {
        modeFadeOutAnimation.stop()
        modeFadeInAnimation.stop()
        modeContentOpacity = 1.0
        contentViewRequested = "applications"
        contentViewActive = "applications"
    }

    function setContentView(viewName) {
        cancelInternalLayoutDrag()
        const requestedView = normalizedContentView(viewName)
        if (contentViewRequested === requestedView
                && (contentViewActive === requestedView
                    || modeTransitionActive)) {
            return
        }

        contentViewRequested = requestedView
        resetPageNavigation()
        resetWheelGesture()

        modeFadeOutAnimation.stop()
        modeFadeInAnimation.stop()

        if (!motionEnabled) {
            modeContentOpacity = 1.0
            commitContentViewState(requestedView)
            Qt.callLater(focusCurrentMode)
            return
        }

        if (contentViewActive === requestedView) {
            if (modeContentOpacity < 0.999) {
                modeFadeInAnimation.start()
            } else {
                Qt.callLater(focusCurrentMode)
            }
            return
        }

        modeFadeOutAnimation.start()
    }

    function setSessionViewActive(active) {
        setContentView(active ? "session" : "applications")
    }

    function setSettingsViewActive(active) {
        setContentView(active ? "settings" : "applications")
    }

    function showSettingsPersistenceError() {
        settingsErrorMessage = i18nc("@info", "Changes could not be saved.")
    }

    function openOverlay() {
        closeTimer.stop()
        cancelInternalLayoutDrag()
        folderSurface.reset()
        resetPageNavigation()
        resetWheelGesture()
        revealHiddenApplications = false
        resetContentTransition()
        menuOpen = true
        searchText = ""
        applicationsLoading = !applicationCatalogLoaded
        applicationLaunchPending = false
        applicationErrorMessage = ""
        operationMessage = ""
        settingsErrorMessage = ""
        currentApplicationIndex = -1
        root.forceActiveFocus()
        if (applicationCatalogLoaded) {
            resetPagination()
        } else {
            Qt.callLater(function() {
                if (root.menuOpen && !root.applicationCatalogLoaded) {
                    root.systemDiscovery.requestApplicationCatalog()
                }
            })
        }
    }

    function forceClose() {
        closeTimer.stop()
        cancelInternalLayoutDrag()
        folderSurface.reset()
        if (applicationLayoutController) {
            applicationLayoutController.discardUndoHistory()
        }
        resetPageNavigation()
        resetWheelGesture()
        revealHiddenApplications = false
        modeFadeOutAnimation.stop()
        modeFadeInAnimation.stop()
        contentViewRequested = contentViewActive
        menuOpen = false
        applicationsLoading = false
        applicationLaunchPending = false
        closeTimer.restart()
    }

    function resetOverlay() {
        closeTimer.stop()
        cancelInternalLayoutDrag()
        folderSurface.reset()
        if (applicationLayoutController) {
            applicationLayoutController.discardUndoHistory()
        }
        resetPageNavigation()
        resetWheelGesture()
        revealHiddenApplications = false
        resetContentTransition()
        menuOpen = false
        searchText = ""
        applicationsLoading = false
        applicationLaunchPending = false
        applicationErrorMessage = ""
        operationMessage = ""
        settingsErrorMessage = ""
        currentApplicationIndex = -1
    }

    onSearchTextChanged: {
        cancelInternalLayoutDrag()
        resetPagination()
    }
    onMenuOpenChanged: {
        if (!menuOpen) {
            cancelInternalLayoutDrag()
        }
    }
    onApplicationCatalogLoadedChanged: {
        if (applicationCatalogLoaded) {
            applicationsLoading = false
            if (menuOpen) {
                resetPagination()
            }
        }
    }
    onApplicationCatalogChanged: {
        if (menuOpen && applicationCatalogLoaded) {
            applicationsLoading = false
            resetPagination()
        }
    }
    onOperationMessageChanged: updateOperationMessageTimer()
    onApplicationErrorMessageChanged: updateOperationMessageTimer()
    onSessionViewActiveChanged: updateOperationMessageTimer()
    onVisibleApplicationsChanged: Qt.callLater(
        root.reconcileApplicationSelection)
    onHiddenApplicationIdsChanged: {
        if (menuOpen) {
            if (hiddenApplicationCount === 0) {
                revealHiddenApplications = false
            }
            resetPagination()
        }
    }
    onRevealHiddenApplicationsChanged: {
        if (menuOpen) {
            resetPagination()
        }
    }
    onPageCapacityChanged: {
        if (menuOpen) {
            cancelInternalLayoutDrag()
            const selectedIndex = Math.max(0, currentApplicationIndex)
            Qt.callLater(function() {
                root.setCurrentApplication(selectedIndex)
            })
        }
    }
    onFavoritesSectionVisibleChanged: {
        if (!favoritesSectionVisible) {
            favoritesScrollAnimation.stop()
            favoritesView.contentX = 0
        }
    }

    Keys.onPressed: function(event) {
        if (internalDragLayer.active) {
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_Back) {
                root.cancelInternalLayoutDrag()
                event.accepted = true
            }
            return
        }
        if (folderSurface.active) {
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_Back) {
                folderSurface.closeCurrentView()
                event.accepted = true
            }
            return
        }
        if (root.contentViewRequested !== "applications"
                || !root.applicationViewActive) {
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_Back) {
                root.setContentView("applications")
                event.accepted = true
            }
            return
        }
        if (event.key === Qt.Key_Escape) {
            root.forceClose()
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
            root.setCurrentApplication(root.currentApplicationIndex - 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            root.setCurrentApplication(root.currentApplicationIndex + 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            root.setCurrentApplication(root.currentApplicationIndex - root.gridColumns)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            root.setCurrentApplication(root.currentApplicationIndex + root.gridColumns)
            event.accepted = true
        } else if (event.key === Qt.Key_PageUp) {
            root.requestPageStep(-1)
            event.accepted = true
        } else if (event.key === Qt.Key_PageDown) {
            root.requestPageStep(1)
            event.accepted = true
        } else if (event.key === Qt.Key_Home) {
            root.setCurrentApplication(0)
            event.accepted = true
        } else if (event.key === Qt.Key_End) {
            root.setCurrentApplication(root.visibleApplications.length - 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Menu
                || (event.key === Qt.Key_F10
                    && (event.modifiers & Qt.ShiftModifier))) {
            event.accepted = root.openCurrentApplicationContextMenu()
        } else if (event.key === Qt.Key_Return
                || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
            root.launchApplicationAt(root.currentApplicationIndex)
            event.accepted = true
        }
    }

    Shortcut {
        sequences: ["Escape", "Back"]
        enabled: root.menuOpen
        onActivated: {
            if (folderSurface.active) {
                folderSurface.closeCurrentView()
            } else if (root.contentViewRequested !== "applications"
                    || !root.applicationViewActive) {
                root.setContentView("applications")
            } else {
                root.forceClose()
            }
        }
    }

    PlasmaComponents.Menu {
        id: standaloneApplicationContextMenu

        modal: false
        closePolicy: Controls.Popup.CloseOnEscape
            | Controls.Popup.CloseOnPressOutside

        property string targetStorageId: ""
        property string targetAppCommand: ""
        property string targetAppName: ""
        property string targetAppIcon: ""
        property bool targetIsFavorite: false
        property bool targetIsPinnedToDock: false
        property bool targetIsHidden: false
        property Item pendingSourceItem: null
        property real pendingPopupX: 0
        property real pendingPopupY: 0
        readonly property bool layoutActionEnabled:
            root.applicationLayoutController
            && !root.applicationLayoutController.transactionPending

        function targetApplication() {
            return {
                appStorageId: targetStorageId,
                appName: targetAppName,
                appIcon: targetAppIcon
            }
        }

        onClosed: root.completeContextMenuClose(
            standaloneApplicationContextMenu)

        PlasmaComponents.MenuItem {
            enabled: standaloneApplicationContextMenu.layoutActionEnabled
            text: i18nc("@action:inmenu", "Create Folder…")
            icon.name: "folder-new"
            Accessible.name: text
            onTriggered: {
                const application = standaloneApplicationContextMenu
                    .targetApplication()
                Qt.callLater(function() {
                    folderSurface.beginCreate(application)
                })
            }
        }

        PlasmaComponents.MenuItem {
            enabled: standaloneApplicationContextMenu.layoutActionEnabled
                && applicationLayoutModel.folderChoiceCount > 0
            text: i18nc("@action:inmenu", "Move to Folder…")
            icon.name: "folder-move"
            Accessible.name: text
            onTriggered: {
                const application = standaloneApplicationContextMenu
                    .targetApplication()
                Qt.callLater(function() {
                    folderSurface.beginMove(application)
                })
            }
        }

        PlasmaComponents.MenuSeparator {}

        PlasmaComponents.MenuItem {
            text: standaloneApplicationContextMenu.targetIsFavorite
                ? i18nc("@action:inmenu", "Remove from Favorites")
                : i18nc("@action:inmenu", "Add to Favorites")
            icon.name: standaloneApplicationContextMenu.targetIsFavorite
                ? "favorite-favorited"
                : "favorite"
            Accessible.name: text
            onTriggered: root.toggleContextFavorite(
                standaloneApplicationContextMenu)
        }

        PlasmaComponents.MenuItem {
            text: standaloneApplicationContextMenu.targetIsPinnedToDock
                ? i18nc("@action:inmenu", "Remove from Dock")
                : i18nc("@action:inmenu", "Pin to Dock")
            icon.name: standaloneApplicationContextMenu.targetIsPinnedToDock
                ? "window-unpin"
                : "window-pin"
            Accessible.name: text
            onTriggered: root.toggleContextDockPin(
                standaloneApplicationContextMenu)
        }

        PlasmaComponents.MenuItem {
            text: i18nc("@action:inmenu", "Add to Desktop")
            icon.name: "user-desktop"
            Accessible.name: text
            onTriggered: root.addContextApplicationToDesktop(
                standaloneApplicationContextMenu)
        }

        PlasmaComponents.MenuSeparator {}

        PlasmaComponents.MenuItem {
            enabled: standaloneApplicationContextMenu
                .targetStorageId.length > 0
            text: standaloneApplicationContextMenu.targetIsHidden
                ? i18nc("@action:inmenu", "Show in listing")
                : i18nc("@action:inmenu", "Hide from listing")
            icon.name: standaloneApplicationContextMenu.targetIsHidden
                ? "view-visible"
                : "view-hidden"
            Accessible.name: text
            onTriggered: root.toggleContextApplicationHidden(
                standaloneApplicationContextMenu)
        }
    }

    PlasmaComponents.Menu {
        id: folderMemberContextMenu

        modal: false
        closePolicy: Controls.Popup.CloseOnEscape
            | Controls.Popup.CloseOnPressOutside

        property string targetStorageId: ""
        property string targetAppCommand: ""
        property string targetAppName: ""
        property string targetAppIcon: ""
        property string targetContainingFolderId: ""
        property bool targetIsFavorite: false
        property bool targetIsPinnedToDock: false
        property bool targetIsHidden: false
        property Item pendingSourceItem: null
        property real pendingPopupX: 0
        property real pendingPopupY: 0
        readonly property bool layoutActionEnabled:
            root.applicationLayoutController
            && !root.applicationLayoutController.transactionPending

        function targetApplication() {
            return {
                appStorageId: targetStorageId,
                appName: targetAppName,
                appIcon: targetAppIcon
            }
        }

        onClosed: root.completeContextMenuClose(folderMemberContextMenu)

        PlasmaComponents.MenuItem {
            enabled: folderMemberContextMenu.layoutActionEnabled
            text: i18nc("@action:inmenu", "Remove from Folder…")
            icon.name: "list-remove"
            Accessible.name: text
            onTriggered: {
                const application = folderMemberContextMenu
                    .targetApplication()
                const folderId = folderMemberContextMenu
                    .targetContainingFolderId
                Qt.callLater(function() {
                    folderSurface.beginRemove(application, folderId)
                })
            }
        }

        PlasmaComponents.MenuSeparator {}

        PlasmaComponents.MenuItem {
            text: folderMemberContextMenu.targetIsFavorite
                ? i18nc("@action:inmenu", "Remove from Favorites")
                : i18nc("@action:inmenu", "Add to Favorites")
            icon.name: folderMemberContextMenu.targetIsFavorite
                ? "favorite-favorited"
                : "favorite"
            Accessible.name: text
            onTriggered: root.toggleContextFavorite(folderMemberContextMenu)
        }

        PlasmaComponents.MenuItem {
            text: folderMemberContextMenu.targetIsPinnedToDock
                ? i18nc("@action:inmenu", "Remove from Dock")
                : i18nc("@action:inmenu", "Pin to Dock")
            icon.name: folderMemberContextMenu.targetIsPinnedToDock
                ? "window-unpin"
                : "window-pin"
            Accessible.name: text
            onTriggered: root.toggleContextDockPin(folderMemberContextMenu)
        }

        PlasmaComponents.MenuItem {
            text: i18nc("@action:inmenu", "Add to Desktop")
            icon.name: "user-desktop"
            Accessible.name: text
            onTriggered: root.addContextApplicationToDesktop(
                folderMemberContextMenu)
        }

        PlasmaComponents.MenuSeparator {}

        PlasmaComponents.MenuItem {
            enabled: folderMemberContextMenu.targetStorageId.length > 0
            text: folderMemberContextMenu.targetIsHidden
                ? i18nc("@action:inmenu", "Show in listing")
                : i18nc("@action:inmenu", "Hide from listing")
            icon.name: folderMemberContextMenu.targetIsHidden
                ? "view-visible"
                : "view-hidden"
            Accessible.name: text
            onTriggered: root.toggleContextApplicationHidden(
                folderMemberContextMenu)
        }
    }

    PlasmaComponents.Menu {
        id: folderContextMenu

        modal: false
        closePolicy: Controls.Popup.CloseOnEscape
            | Controls.Popup.CloseOnPressOutside

        property string targetFolderId: ""
        property Item pendingSourceItem: null
        property real pendingPopupX: 0
        property real pendingPopupY: 0
        readonly property bool layoutActionEnabled:
            root.applicationLayoutController
            && !root.applicationLayoutController.transactionPending

        onClosed: root.completeContextMenuClose(folderContextMenu)

        PlasmaComponents.MenuItem {
            enabled: folderContextMenu.layoutActionEnabled
            text: i18nc("@action:inmenu", "Rename Folder…")
            icon.name: "edit-rename"
            Accessible.name: text
            onTriggered: {
                const folderId = folderContextMenu.targetFolderId
                Qt.callLater(function() {
                    folderSurface.beginRename(folderId)
                })
            }
        }

        PlasmaComponents.MenuSeparator {}

        PlasmaComponents.MenuItem {
            enabled: folderContextMenu.layoutActionEnabled
            text: i18nc("@action:inmenu", "Dissolve Folder…")
            icon.name: "edit-delete"
            Accessible.name: text
            onTriggered: {
                const folderId = folderContextMenu.targetFolderId
                Qt.callLater(function() {
                    folderSurface.beginDissolve(folderId)
                })
            }
        }
    }

    NumberAnimation {
        id: modeFadeOutAnimation
        target: root
        property: "modeContentOpacity"
        to: 0.0
        duration: root.modeFadeOutDuration
        easing.type: Easing.InCubic
        onFinished: {
            root.commitContentViewState(root.contentViewRequested)
            modeFadeInAnimation.start()
        }
    }

    NumberAnimation {
        id: modeFadeInAnimation
        target: root
        property: "modeContentOpacity"
        to: 1.0
        duration: root.modeFadeInDuration
        easing.type: Easing.OutCubic
        onFinished: root.focusCurrentMode()
    }

    Timer {
        id: closeTimer
        interval: root.animCloseDuration
        repeat: false
        onTriggered: root.closeFinished()
    }

    Timer {
        id: pageNavigationTimer
        interval: root.pageInputWindow
        repeat: false
        onTriggered: {
            if (!root.menuOpen) {
                root.resetPageNavigation()
                return
            }
            if (root.pendingPageStep !== 0) {
                const nextStep = root.pendingPageStep
                root.pendingPageStep = 0
                root.applyPageStep(nextStep)
                restart()
                return
            }
            root.pageNavigationActive = false
        }
    }

    Timer {
        id: wheelGestureResetTimer
        interval: root.wheelGestureIdleWindow
        repeat: false
        onTriggered: {
            root.wheelPageAccumulator = 0
            root.wheelGestureCommitted = false
        }
    }

    Timer {
        id: dragEdgeTimer
        interval: Math.max(420, Math.round(Kirigami.Units.longDuration * 1.5))
        repeat: false
        onTriggered: {
            if (!internalDragLayer.active || !root.dragEdgeArmed
                    || root.dragEdgeDirection === 0) {
                return
            }
            root.dragEdgeArmed = false
            root.requestPageStep(root.dragEdgeDirection, true)
        }
    }

    Connections {
        target: root.systemDiscovery
        ignoreUnknownSignals: true

        function onApplicationLaunchFinished(succeeded, message) {
            if (!root.applicationLaunchPending) {
                return
            }
            root.applicationLaunchPending = false
            if (succeeded) {
                root.forceClose()
            } else {
                root.applicationErrorMessage = String(message || "")
            }
        }
    }

    Item {
        id: backdropContainer
        anchors.fill: parent
        opacity: root.menuOpen ? 1.0 : 0.0

        Behavior on opacity {
            enabled: root.motionEnabled
            NumberAnimation {
                duration: root.menuOpen ? root.animOpenDuration : root.animCloseDuration
                easing.type: root.menuOpen ? Easing.OutCubic : Easing.InQuad
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Kirigami.Theme.backgroundColor
            opacity: root.safeBackgroundOpacity
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.forceClose()
        }
    }

    PlasmaComponents.ToolButton {
        id: closeButton

        z: 2
        x: root.closeButtonOnLeft
            ? root.closeButtonCornerMargin
            : Math.max(root.closeButtonCornerMargin,
                parent.width - width - root.closeButtonCornerMargin)
        y: root.closeButtonCornerMargin
        enabled: root.menuOpen
        opacity: root.menuOpen ? 1.0 : 0.0

        readonly property bool highlightedContent: enabled
            && (hovered || down || activeFocus)

        icon.name: "window-close"
        icon.color: highlightedContent
            ? root.Kirigami.Theme.highlightedTextColor
            : root.Kirigami.Theme.textColor
        display: PlasmaComponents.AbstractButton.IconOnly
        text: i18nc("@action:button", "Close")
        Accessible.name: text
        background: PunchiMenuActionBackground {
            highlighted: closeButton.highlightedContent
            circular: true
        }

        HoverHandler {
            enabled: closeButton.enabled
            cursorShape: Qt.PointingHandCursor
        }

        onClicked: root.forceClose()

        Behavior on opacity {
            enabled: root.motionEnabled
            NumberAnimation {
                duration: root.menuOpen
                    ? root.animOpenDuration : root.animCloseDuration
                easing.type: root.menuOpen ? Easing.OutCubic : Easing.InCubic
            }
        }
    }

    ColumnLayout {
        id: mainContentContainer
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.gridUnit * 3
        anchors.rightMargin: Kirigami.Units.gridUnit * 3
        anchors.topMargin: Kirigami.Units.largeSpacing
        anchors.bottomMargin: Kirigami.Units.gridUnit * 4
        spacing: Kirigami.Units.largeSpacing
        opacity: root.menuOpen ? 1.0 : 0.0
        scale: root.menuOpen ? 1.0 : 0.97
        transformOrigin: Item.Center

        Behavior on opacity {
            enabled: root.motionEnabled
            NumberAnimation {
                duration: root.menuOpen ? root.animOpenDuration : root.animCloseDuration
                easing.type: root.menuOpen ? Easing.OutCubic : Easing.InCubic
            }
        }

        Behavior on scale {
            enabled: root.motionEnabled
            NumberAnimation {
                duration: root.menuOpen ? root.animOpenDuration : root.animCloseDuration
                easing.type: root.menuOpen ? Easing.OutCubic : Easing.InCubic
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.mediumSpacing

            Item {
                id: distributionTitleContainer

                Layout.fillWidth: true
                Layout.preferredHeight: distributionHeading.implicitHeight
                visible: root.distributionName.length > 0
                opacity: root.showDistributionName ? 1.0 : 0.0

                readonly property int logoSize: Math.max(1, Math.min(
                    Kirigami.Units.iconSizes.small,
                    Math.round(distributionFontMetrics.height)))

                FontMetrics {
                    id: distributionFontMetrics
                    font: distributionHeading.font
                }

                RowLayout {
                    id: distributionTitle

                    anchors.centerIn: parent
                    width: Math.min(parent.width,
                        distributionHeading.implicitWidth
                        + (distributionIcon.visible
                            ? distributionTitleContainer.logoSize + spacing
                            : 0))
                    height: Math.max(distributionHeading.implicitHeight,
                        distributionTitleContainer.logoSize)
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        id: distributionIcon

                        Layout.preferredWidth: distributionTitleContainer.logoSize
                        Layout.preferredHeight: distributionTitleContainer.logoSize
                        Layout.minimumWidth: Layout.preferredWidth
                        Layout.minimumHeight: Layout.preferredHeight
                        Layout.maximumWidth: Layout.preferredWidth
                        Layout.maximumHeight: Layout.preferredHeight
                        source: root.distributionLogo
                        visible: root.showDistributionName
                            && root.distributionName.length > 0
                            && root.distributionLogo.length > 0
                            && valid
                        Accessible.ignored: true
                    }

                    Kirigami.Heading {
                        id: distributionHeading

                        Layout.fillWidth: true
                        level: 2
                        text: root.distributionName
                        horizontalAlignment: distributionIcon.visible
                            ? Text.AlignLeft
                            : Text.AlignHCenter
                        elide: Text.ElideRight
                        Accessible.ignored: !root.showDistributionName
                    }
                }

                Behavior on opacity {
                    enabled: root.motionEnabled
                    NumberAnimation {
                        duration: Kirigami.Units.shortDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }

        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Kirigami.Units.smallSpacing

            Item {
                id: searchContainer

                Layout.preferredWidth: root.compactSearchWidth
                Layout.minimumWidth: root.compactSearchWidth
                Layout.maximumWidth: root.compactSearchWidth
                Layout.preferredHeight: root.headerControlSize
                Layout.minimumHeight: Layout.preferredHeight
                Layout.maximumHeight: Layout.preferredHeight
                visible: true
                enabled: root.applicationViewActive
                    && !root.modeTransitionActive
                opacity: root.applicationViewActive
                    ? root.modeContentOpacity : 0.0

                PunchiMenuSearchBackground {
                    anchors.fill: parent
                    fieldActiveFocus: searchField.activeFocus
                    fieldHovered: searchField.hovered
                    auxiliaryHovered: clearSearchButton.hovered
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Kirigami.Units.mediumSpacing
                    anchors.rightMargin: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: width
                        source: "system-search-symbolic"
                        color: Kirigami.Theme.textColor
                        Accessible.ignored: true
                    }

                    PlasmaComponents.TextField {
                        id: searchField

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: i18nc("@placeholder", "Search applications…")
                        Accessible.name: i18nc("@label", "Search applications")
                        text: root.searchText
                        selectByMouse: true
                        KeyNavigation.tab: clearSearchButton.visible
                            ? clearSearchButton
                            : hiddenApplicationsButton.visible
                                ? hiddenApplicationsButton
                                : configureButton

                        background: Item {}

                        onTextEdited: root.searchText = text

                        Keys.onDownPressed: function(event) {
                            root.forceActiveFocus()
                            if (root.currentApplicationIndex < 0
                                    && root.visibleApplications.length > 0) {
                                root.setCurrentApplication(0)
                            }
                            event.accepted = true
                        }
                        Keys.onEscapePressed: function(event) {
                            if (text.length > 0) {
                                clear()
                                root.searchText = ""
                            } else {
                                root.forceClose()
                            }
                            event.accepted = true
                        }
                    }

                    PlasmaComponents.ToolButton {
                        id: clearSearchButton

                        Layout.preferredWidth: visible ? implicitWidth : 0
                        Layout.preferredHeight: implicitHeight
                        visible: searchField.text.length > 0
                        enabled: visible && root.menuOpen
                        icon.name: searchField.effectiveHorizontalAlignment
                                === TextInput.AlignRight
                            ? "edit-clear-locationbar-ltr"
                            : "edit-clear-locationbar-rtl"
                        display: PlasmaComponents.AbstractButton.IconOnly
                        text: i18nc("@action:button", "Clear search")
                        Accessible.name: text
                        KeyNavigation.backtab: searchField
                        KeyNavigation.tab: hiddenApplicationsButton.visible
                            ? hiddenApplicationsButton
                            : configureButton

                        onClicked: {
                            searchField.clear()
                            root.searchText = ""
                            searchField.forceActiveFocus()
                        }
                    }
                }
            }

            PlasmaComponents.ToolButton {
                id: hiddenApplicationsButton
                readonly property bool highlightedContent: enabled
                    && (hovered || down || activeFocus || checked)
                Layout.preferredWidth: root.headerControlSize
                Layout.minimumWidth: Layout.preferredWidth
                Layout.maximumWidth: Layout.preferredWidth
                Layout.preferredHeight: root.headerControlSize
                Layout.minimumHeight: Layout.preferredHeight
                Layout.maximumHeight: Layout.preferredHeight
                visible: root.hiddenApplicationCount > 0
                enabled: root.applicationViewActive
                    && root.menuOpen && !root.modeTransitionActive
                    && !root.applicationLaunchPending
                opacity: root.applicationViewActive
                    ? root.modeContentOpacity : 0.0
                icon.name: root.revealHiddenApplications
                    ? "view-visible"
                    : "view-hidden"
                icon.color: highlightedContent
                    ? root.Kirigami.Theme.highlightedTextColor
                    : root.Kirigami.Theme.textColor
                display: PlasmaComponents.AbstractButton.IconOnly
                text: root.revealHiddenApplications
                    ? i18nc("@action:button", "Hide hidden applications")
                    : i18nc("@action:button", "Show hidden applications")
                checkable: true
                checked: root.revealHiddenApplications
                Accessible.name: text
                KeyNavigation.backtab: clearSearchButton.visible
                    ? clearSearchButton
                    : searchField
                KeyNavigation.tab: configureButton

                background: PunchiMenuActionBackground {
                    highlighted: hiddenApplicationsButton.highlightedContent
                    circular: true
                }

                PlasmaCore.ToolTipArea {
                    id: hiddenApplicationsToolTip
                    anchors.fill: parent
                    active: hiddenApplicationsButton.enabled
                        && hiddenApplicationsButton.visible
                    mainText: hiddenApplicationsButton.text
                }

                HoverHandler {
                    enabled: hiddenApplicationsButton.enabled
                    cursorShape: Qt.PointingHandCursor
                }

                onActiveFocusChanged: {
                    if (activeFocus) {
                        hiddenApplicationsToolTip.showToolTip()
                    } else if (!hiddenApplicationsToolTip.containsMouse) {
                        hiddenApplicationsToolTip.hideImmediately()
                    }
                }
                onClicked: root.revealHiddenApplications
                    = !root.revealHiddenApplications
            }

            PlasmaComponents.ToolButton {
                id: configureButton
                readonly property bool highlightedContent: enabled
                    && (hovered || down || activeFocus || checked)
                Layout.preferredWidth: root.headerControlSize
                Layout.minimumWidth: Layout.preferredWidth
                Layout.maximumWidth: Layout.preferredWidth
                Layout.preferredHeight: root.headerControlSize
                Layout.minimumHeight: Layout.preferredHeight
                Layout.maximumHeight: Layout.preferredHeight
                icon.name: root.settingsViewRequested
                    ? "view-grid" : "configure"
                icon.color: highlightedContent
                    ? root.Kirigami.Theme.highlightedTextColor
                    : root.Kirigami.Theme.textColor
                display: PlasmaComponents.AbstractButton.IconOnly
                text: root.settingsViewRequested
                    ? i18nc("@action:button", "Show applications")
                    : i18n("Configure PunchiMenu")
                checkable: true
                checked: root.settingsViewRequested
                Accessible.name: text
                KeyNavigation.backtab: hiddenApplicationsButton.visible
                    ? hiddenApplicationsButton
                    : clearSearchButton.visible
                        ? clearSearchButton
                        : searchField
                KeyNavigation.tab: sessionButton

                background: PunchiMenuActionBackground {
                    highlighted: configureButton.highlightedContent
                    circular: true
                }

                PlasmaCore.ToolTipArea {
                    id: configureToolTip
                    anchors.fill: parent
                    active: configureButton.enabled && configureButton.visible
                    mainText: configureButton.text
                }

                HoverHandler {
                    enabled: configureButton.enabled
                    cursorShape: Qt.PointingHandCursor
                }

                onClicked: root.setSettingsViewActive(
                    !root.settingsViewRequested)
            }

            PlasmaComponents.ToolButton {
                id: sessionButton
                readonly property bool highlightedContent: enabled
                    && (hovered || down || activeFocus || checked)
                readonly property color foregroundColor: highlightedContent
                    ? root.Kirigami.Theme.highlightedTextColor
                    : root.Kirigami.Theme.textColor
                Layout.preferredWidth: root.headerControlSize
                Layout.minimumWidth: Layout.preferredWidth
                Layout.maximumWidth: Layout.preferredWidth
                Layout.preferredHeight: root.headerControlSize
                Layout.minimumHeight: Layout.preferredHeight
                Layout.maximumHeight: Layout.preferredHeight
                display: PlasmaComponents.AbstractButton.IconOnly
                text: root.sessionViewRequested
                    ? i18nc("@action:button", "Show applications")
                    : i18nc("@action:button", "Show session actions")
                checkable: true
                checked: root.sessionViewRequested
                flat: false
                hoverEnabled: true
                Accessible.name: text
                KeyNavigation.backtab: configureButton
                // The Loader item is a PunchiMenuSessionView at runtime, but
                // static analysis resolves Loader items as QObject.
                // qmllint disable incompatible-type
                KeyNavigation.tab: root.settingsViewActive
                    && settingsViewLoader.item
                    ? settingsViewLoader.item
                    : root.sessionViewActive
                    && sessionViewLoader.item
                    ? sessionViewLoader.item : closeButton
                // qmllint enable incompatible-type

                contentItem: Item {
                    implicitWidth: root.headerControlSize
                    implicitHeight: root.headerControlSize

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: Kirigami.Units.iconSizes.smallMedium
                        height: width
                        source: "user-identity"
                        color: sessionButton.foregroundColor
                        visible: !root.sessionViewRequested
                        Accessible.ignored: true
                    }

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: Kirigami.Units.iconSizes.smallMedium
                        height: width
                        source: "view-grid"
                        color: sessionButton.foregroundColor
                        visible: root.sessionViewRequested
                        Accessible.ignored: true
                    }
                }

                background: PunchiMenuActionBackground {
                    highlighted: sessionButton.highlightedContent
                    circular: true
                }

                PlasmaCore.ToolTipArea {
                    id: sessionToolTip
                    anchors.fill: parent
                    active: sessionButton.enabled && sessionButton.visible
                    mainText: sessionButton.text
                }

                HoverHandler {
                    enabled: sessionButton.enabled
                    cursorShape: Qt.PointingHandCursor
                }

                onActiveFocusChanged: {
                    if (activeFocus) {
                        sessionToolTip.showToolTip()
                    } else if (!sessionToolTip.containsMouse) {
                        sessionToolTip.hideImmediately()
                    }
                }
                onClicked: root.setSessionViewActive(
                    !root.sessionViewRequested)
            }
        }

        Item {
            id: gridArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            enabled: !root.modeTransitionActive
            opacity: root.modeContentOpacity

            ListView {
                id: pagesView
                anchors.fill: parent
                anchors.leftMargin: root.applicationGridHorizontalInset
                anchors.rightMargin: root.applicationGridHorizontalInset
                orientation: ListView.Horizontal
                model: root.pageCount
                clip: true
                interactive: root.pageCount > 1 && !internalDragLayer.active
                boundsBehavior: Flickable.StopAtBounds
                snapMode: ListView.SnapOneItem
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: 0
                preferredHighlightEnd: 0
                highlightMoveDuration: root.motionEnabled ? Kirigami.Units.longDuration : 0
                maximumFlickVelocity: 4 * width
                cacheBuffer: Math.max(0, width)
                enabled: root.applicationViewActive
                    && !root.modeTransitionActive
                    && !root.applicationLaunchPending
                visible: root.applicationViewActive

                onMovementStarted: root.resetPageNavigation()
                onMovementEnded: {
                    const settledPage = Math.max(0, Math.min(root.pageCount - 1,
                        Math.round(contentX / Math.max(1, width))))
                    currentIndex = settledPage
                    root.ensureSelectionOnPage(settledPage)
                }

                delegate: Item {
                    id: pageDelegate
                    required property int index
                    width: pagesView.width
                    height: pagesView.height
                    readonly property var pageApplications: root.applicationsForPage(index)

                    DropArea {
                        x: applicationsGrid.x
                        y: applicationsGrid.y
                        width: applicationsGrid.width
                        height: applicationsGrid.height
                        keys: [internalDragLayer.dragKey]
                        z: 0

                        onEntered: function(drag) {
                            drag.accepted = root.isInternalLayoutDrag(drag)
                        }
                        onDropped: function(drop) {
                            if (!root.isInternalLayoutDrag(drop)) {
                                drop.accepted = false
                                return
                            }
                            const beforeNodeId = root.nodeIdForGridDrop(
                                pageDelegate.index, drop.x, drop.y,
                                applicationsGrid)
                            drop.accepted = root.requestDraggedNodeMove(
                                beforeNodeId)
                        }
                    }

                    Grid {
                        id: applicationsGrid
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        columns: root.gridColumns
                        rows: root.gridRows
                        columnSpacing: Kirigami.Units.mediumSpacing
                        rowSpacing: Kirigami.Units.smallSpacing
                        z: 1

                        Repeater {
                            model: pageDelegate.pageApplications

                            delegate: Item {
                                id: appDelegate
                                required property var modelData
                                required property int index

                                readonly property int globalIndex: pageDelegate.index
                                    * root.pageCapacity + index
                                readonly property bool isFolder:
                                    String(modelData.nodeType || "application")
                                        === "folder"
                                readonly property bool isSelected: root.currentApplicationIndex
                                    === globalIndex
                                readonly property bool highlighted: isSelected
                                    || (delegatePointer.containsMouse
                                        && root.applicationHoverAllowed)
                                readonly property bool isHiddenApplication:
                                    !isFolder && !!modelData.appHidden
                                readonly property bool isDragSource:
                                    internalDragLayer.active
                                    && internalDragLayer.nodeId
                                        === String(modelData.nodeId || "")
                                readonly property bool dropGroupingActive:
                                    nodeDropTarget.containsDrag
                                    && nodeDropTarget.dropIntent === "group"
                                readonly property bool dropInsertionActive:
                                    nodeDropTarget.containsDrag
                                    && (nodeDropTarget.dropIntent
                                            === "insertBefore"
                                        || nodeDropTarget.dropIntent
                                            === "insertAfter")
                                readonly property int safeIconSize:
                                    applicationIconMetrics.effectiveSize

                                width: (applicationsGrid.width
                                    - applicationsGrid.columnSpacing
                                        * (root.gridColumns - 1)) / root.gridColumns
                                height: (applicationsGrid.height
                                    - applicationsGrid.rowSpacing
                                        * (root.gridRows - 1)) / root.gridRows

                                PunchiMenuIconMetrics {
                                    id: applicationIconMetrics
                                    requestedScale: root.safeApplicationIconScale
                                    minimumScale: 0.75
                                    maximumScale: 1.5
                                    baseSize: root.responsiveApplicationIconBase
                                    minimumSize: Kirigami.Units.iconSizes.medium
                                    availableWidth: Math.max(0,
                                        appDelegate.width
                                            - Kirigami.Units.gridUnit)
                                    availableHeight: Math.max(0,
                                        appDelegate.height
                                            - Kirigami.Units.gridUnit * 3)
                                }
                                opacity: isDragSource ? 0.34
                                    : isHiddenApplication ? 0.58 : 1.0
                                Accessible.ignored: isFolder
                                Accessible.role: Accessible.Button
                                Accessible.name: isFolder
                                    ? String(modelData.folderLabel || "")
                                    : String(modelData.appName || "")
                                Accessible.description: !isFolder
                                    && isHiddenApplication
                                    ? i18nc("@info:accessibility",
                                        "Hidden from the application listing")
                                    : ""
                                Accessible.focused: isSelected
                                Accessible.onPressAction: root.launchApplicationAt(globalIndex)

                                PunchiMenuFolderTile {
                                    anchors.fill: parent
                                    anchors.margins: Kirigami.Units.smallSpacing
                                    visible: appDelegate.isFolder
                                    enabled: visible
                                    activeFocusOnTab: false
                                    folderId: String(appDelegate.modelData.folderId || "")
                                    folderLabel: String(
                                        appDelegate.modelData.folderLabel || "")
                                    previewIcons: appDelegate.modelData
                                        .folderPreviewIcons || []
                                    memberCount: Number(appDelegate.modelData
                                        .folderMemberCount || 0)
                                    selected: appDelegate.highlighted
                                        || appDelegate.dropGroupingActive
                                    motionEnabled: root.motionEnabled
                                    requestedIconSize: appDelegate.safeIconSize
                                    hoverAnimation: root.hoverAnimation
                                    onActivated: root.launchApplicationAt(
                                        appDelegate.globalIndex)
                                    onContextRequested: function(sourceItem, x, y) {
                                        root.setCurrentApplication(
                                            appDelegate.globalIndex)
                                        root.openFolderContextMenu(sourceItem,
                                            appDelegate.modelData, x, y)
                                    }
                                    onRenameRequested: folderSurface.beginRename(
                                        String(appDelegate.modelData.folderId || ""))
                                }

                                PunchiMenuItemHighlight {
                                    anchors.fill: parent
                                    anchors.margins: Kirigami.Units.smallSpacing
                                    visible: !appDelegate.isFolder
                                    hovered: delegatePointer.containsMouse
                                        && root.applicationHoverAllowed
                                    selected: appDelegate.highlighted
                                        || appDelegate.dropGroupingActive
                                    pressed: delegatePointer.pressed
                                        && !internalDragLayer.active
                                    motionEnabled: root.motionEnabled
                                    animationMode: root.hoverAnimation

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        width: parent.width - Kirigami.Units.gridUnit
                                        spacing: Kirigami.Units.smallSpacing

                                        Kirigami.Icon {
                                            Layout.alignment: Qt.AlignHCenter
                                            Layout.preferredWidth: appDelegate.safeIconSize
                                            Layout.preferredHeight: appDelegate.safeIconSize
                                            source: String(appDelegate.modelData.appIcon
                                                || "application-x-executable")
                                        }

                                        PlasmaComponents.Label {
                                            id: applicationLabel
                                            Layout.fillWidth: true
                                            visible: root.showApplicationLabels
                                            text: String(appDelegate.modelData.appName || "")
                                            textFormat: Text.PlainText
                                            horizontalAlignment: Text.AlignHCenter
                                            wrapMode: Text.Wrap
                                            maximumLineCount: 2
                                            elide: Text.ElideRight
                                            font: Kirigami.Theme.smallFont
                                        }
                                    }

                                    PlasmaCore.ToolTipArea {
                                        anchors.fill: parent
                                        active: !root.showApplicationLabels
                                            || applicationLabel.truncated
                                        mainText: String(appDelegate.modelData
                                            .appName || "")
                                    }

                                    Kirigami.Icon {
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: Kirigami.Units.largeSpacing
                                        width: Kirigami.Units.iconSizes.small
                                        height: width
                                        source: "view-hidden-symbolic"
                                        visible: appDelegate.isHiddenApplication
                                        Accessible.ignored: true
                                    }

                                }

                                DropArea {
                                    id: nodeDropTarget
                                    property string dropIntent: "none"
                                    readonly property real insertionEdgeWidth:
                                        Math.min(width * 0.25,
                                            Kirigami.Units.gridUnit * 1.75)

                                    function updateDropIntent(drag) {
                                        if (!root.isInternalLayoutDrag(drag)
                                                || internalDragLayer.nodeId
                                                    === String(appDelegate
                                                        .modelData.nodeId
                                                        || "")) {
                                            dropIntent = "none"
                                            return false
                                        }
                                        const pointerX = Number(drag.x)
                                        if (root.sortApplicationsAlphabetically) {
                                            dropIntent = internalDragLayer.folder
                                                ? "none" : "group"
                                            return dropIntent !== "none"
                                        }
                                        if (internalDragLayer.folder) {
                                            dropIntent = pointerX < width / 2
                                                ? "insertBefore"
                                                : "insertAfter"
                                        } else if (pointerX
                                                <= insertionEdgeWidth) {
                                            dropIntent = "insertBefore"
                                        } else if (pointerX >= width
                                                - insertionEdgeWidth) {
                                            dropIntent = "insertAfter"
                                        } else {
                                            dropIntent = "group"
                                        }
                                        return true
                                    }

                                    anchors.fill: parent
                                    anchors.margins: Kirigami.Units.smallSpacing
                                    keys: [internalDragLayer.dragKey]
                                    z: 20

                                    onEntered: function(drag) {
                                        drag.accepted = updateDropIntent(drag)
                                    }
                                    onPositionChanged: function(drag) {
                                        drag.accepted = updateDropIntent(drag)
                                    }
                                    onExited: {
                                        dropIntent = "none"
                                    }
                                    onDropped: function(drop) {
                                        if (!root.isInternalLayoutDrag(drop)) {
                                            drop.accepted = false
                                            dropIntent = "none"
                                            return
                                        }
                                        if (dropIntent === "insertBefore"
                                                || dropIntent
                                                    === "insertAfter") {
                                            drop.accepted
                                                = root.requestDraggedNodeMove(
                                                    root.beforeNodeIdForInsertion(
                                                        appDelegate.globalIndex,
                                                        dropIntent
                                                            === "insertAfter"))
                                        } else {
                                            drop.accepted
                                                = root.handleDraggedNodeDrop(
                                                    appDelegate.modelData)
                                        }
                                        dropIntent = "none"
                                    }
                                }

                                Rectangle {
                                    readonly property bool after:
                                        nodeDropTarget.dropIntent
                                            === "insertAfter"
                                    readonly property int gridColumn:
                                        appDelegate.index
                                            % Math.max(1, root.gridColumns)
                                    readonly property bool atLeadingPageEdge:
                                        !after && gridColumn === 0
                                    readonly property bool atTrailingPageEdge:
                                        after && gridColumn
                                            === root.gridColumns - 1
                                    readonly property real centeredX: after
                                        ? parent.width - width / 2
                                        : -width / 2

                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.topMargin:
                                        Kirigami.Units.smallSpacing
                                    anchors.bottomMargin:
                                        Kirigami.Units.smallSpacing
                                    x: atLeadingPageEdge ? 0
                                        : atTrailingPageEdge
                                            ? parent.width - width
                                            : centeredX
                                    width: Kirigami.Units.largeSpacing
                                    radius: Kirigami.Units.cornerRadius
                                    color: Qt.alpha(
                                        Kirigami.Theme.highlightColor, 0.22)
                                    border.width: 2
                                    border.color:
                                        Kirigami.Theme.highlightColor
                                    visible: appDelegate.dropInsertionActive
                                    z: 25
                                    Accessible.ignored: true
                                }

                                Kirigami.Icon {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: Kirigami.Units.smallSpacing
                                    width: Kirigami.Units.iconSizes.small
                                    height: width
                                    visible: nodeDropTarget.containsDrag
                                        && nodeDropTarget.dropIntent !== "none"
                                    source: appDelegate.dropInsertionActive
                                        ? "transform-move-symbolic"
                                        : appDelegate.isFolder
                                            ? "folder-add-symbolic"
                                            : "folder-new-symbolic"
                                    color: Kirigami.Theme.highlightColor
                                    z: 30
                                    Accessible.ignored: true
                                }

                                MouseArea {
                                    id: delegatePointer
                                    anchors.fill: parent
                                    z: 40
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    preventStealing: internalDragLayer.active
                                    cursorShape: appDelegate.isDragSource
                                        ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                                    onEntered: {
                                        if (root.applicationHoverAllowed) {
                                            root.setCurrentApplication(
                                                appDelegate.globalIndex)
                                        }
                                    }
                                    onPressAndHold: function(mouse) {
                                        if (mouse.button === Qt.LeftButton) {
                                            root.setCurrentApplication(
                                                appDelegate.globalIndex)
                                            root.beginInternalLayoutDrag(
                                                appDelegate.modelData,
                                                delegatePointer,
                                                mouse.x, mouse.y)
                                        }
                                    }
                                    onPositionChanged: function(mouse) {
                                        if (appDelegate.isDragSource) {
                                            root.updateInternalLayoutDrag(
                                                delegatePointer,
                                                mouse.x, mouse.y)
                                        }
                                    }
                                    onReleased: function(mouse) {
                                        if (mouse.button === Qt.LeftButton
                                                && appDelegate.isDragSource) {
                                            root.finishInternalLayoutDrag()
                                        }
                                    }
                                    onCanceled: {
                                        if (appDelegate.isDragSource) {
                                            root.cancelInternalLayoutDrag()
                                        }
                                    }
                                    onClicked: function(mouse) {
                                        if (root.suppressDragReleaseClick) {
                                            return
                                        }
                                        root.setCurrentApplication(
                                            appDelegate.globalIndex)
                                        if (mouse.button === Qt.RightButton) {
                                            if (appDelegate.isFolder) {
                                                root.openFolderContextMenu(
                                                    appDelegate,
                                                    appDelegate.modelData,
                                                    mouse.x, mouse.y)
                                            } else {
                                                root.openApplicationContextMenu(
                                                    appDelegate,
                                                    String(appDelegate.modelData.appStorageId || ""),
                                                    String(appDelegate.modelData.appName || ""),
                                                    String(appDelegate.modelData.appIcon || ""),
                                                    root.organizedListingActive
                                                        ? ""
                                                        : String(appDelegate.modelData.appCommand || ""),
                                                    mouse.x, mouse.y)
                                            }
                                        } else {
                                            root.launchApplicationAt(
                                                appDelegate.globalIndex)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Kirigami.WheelHandler {
                id: wheelInputHandler
                target: pagesView
                scrollFlickableTarget: false
                blockTargetWheel: true
                onWheel: function(wheel) {
                    if (folderSurface.active) {
                        wheel.accepted = true
                        return
                    }
                    if (root.applicationViewActive) {
                        root.handlePageWheel(wheel)
                    }
                }
            }

            PlasmaComponents.ToolButton {
                id: previousPageButton
                anchors.left: parent.left
                anchors.leftMargin: Math.max(Kirigami.Units.smallSpacing,
                    Math.round(root.applicationGridHorizontalInset / 2 - width / 2))
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(implicitWidth, Kirigami.Units.gridUnit * 2.5)
                height: width
                z: 30
                visible: root.applicationViewActive && root.pageCount > 1
                enabled: root.showPageNavigationArrows
                    && pagesView.currentIndex > 0 && !root.applicationLaunchPending
                    && !internalDragLayer.active
                opacity: !root.showPageNavigationArrows
                    ? 0.0 : enabled
                        ? (hovered || activeFocus ? 1.0 : 0.62) : 0.20
                focusPolicy: root.showPageNavigationArrows
                    ? Qt.StrongFocus : Qt.NoFocus
                icon.name: "go-previous-symbolic"
                display: PlasmaComponents.AbstractButton.IconOnly
                text: i18nc("@action:button", "Previous page")
                Accessible.name: text
                Accessible.ignored: !root.showPageNavigationArrows
                KeyNavigation.right: nextPageButton

                PlasmaCore.ToolTipArea {
                    id: previousPageToolTip
                    anchors.fill: parent
                    active: previousPageButton.enabled && previousPageButton.visible
                    mainText: previousPageButton.text
                }

                onActiveFocusChanged: {
                    if (activeFocus) {
                        previousPageToolTip.showToolTip()
                    } else if (!previousPageToolTip.containsMouse) {
                        previousPageToolTip.hideImmediately()
                    }
                }
                onClicked: root.requestPageStep(-1)

                Behavior on opacity {
                    enabled: root.motionEnabled
                    NumberAnimation {
                        duration: Kirigami.Units.shortDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }

            PlasmaComponents.ToolButton {
                id: nextPageButton
                anchors.right: parent.right
                anchors.rightMargin: Math.max(Kirigami.Units.smallSpacing,
                    Math.round(root.applicationGridHorizontalInset / 2 - width / 2))
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(implicitWidth, Kirigami.Units.gridUnit * 2.5)
                height: width
                z: 30
                visible: root.applicationViewActive && root.pageCount > 1
                enabled: root.showPageNavigationArrows
                    && pagesView.currentIndex < root.pageCount - 1
                    && !root.applicationLaunchPending
                    && !internalDragLayer.active
                opacity: !root.showPageNavigationArrows
                    ? 0.0 : enabled
                        ? (hovered || activeFocus ? 1.0 : 0.62) : 0.20
                focusPolicy: root.showPageNavigationArrows
                    ? Qt.StrongFocus : Qt.NoFocus
                icon.name: "go-next-symbolic"
                display: PlasmaComponents.AbstractButton.IconOnly
                text: i18nc("@action:button", "Next page")
                Accessible.name: text
                Accessible.ignored: !root.showPageNavigationArrows
                KeyNavigation.left: previousPageButton

                PlasmaCore.ToolTipArea {
                    id: nextPageToolTip
                    anchors.fill: parent
                    active: nextPageButton.enabled && nextPageButton.visible
                    mainText: nextPageButton.text
                }

                onActiveFocusChanged: {
                    if (activeFocus) {
                        nextPageToolTip.showToolTip()
                    } else if (!nextPageToolTip.containsMouse) {
                        nextPageToolTip.hideImmediately()
                    }
                }
                onClicked: root.requestPageStep(1)

                Behavior on opacity {
                    enabled: root.motionEnabled
                    NumberAnimation {
                        duration: Kirigami.Units.shortDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(parent.width - Kirigami.Units.largeSpacing * 2,
                    Kirigami.Units.gridUnit * 30)
                spacing: Kirigami.Units.largeSpacing
                visible: root.applicationViewActive && (root.applicationsLoading
                    || (!root.applicationsLoading && root.visibleApplications.length === 0)
                    )
                z: 20

                Controls.BusyIndicator {
                    Layout.alignment: Qt.AlignHCenter
                    running: visible
                    visible: root.applicationsLoading
                }

                Kirigami.Icon {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                    Layout.preferredHeight: width
                    source: "edit-none"
                    visible: !root.applicationsLoading
                    Accessible.ignored: true
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: root.applicationsLoading
                        ? i18nc("@info:status", "Loading applications…")
                        : root.searchText.length > 0
                            ? i18nc("@info:status", "No applications match your search.")
                            : i18nc("@info:status", "No applications were found in this category.")
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    Accessible.role: Accessible.StaticText
                    Accessible.name: text
                }
            }

            Loader {
                id: settingsViewLoader
                anchors.fill: parent
                active: root.settingsViewRequested || root.settingsViewActive
                visible: root.settingsViewActive
                enabled: visible && !root.modeTransitionActive
                asynchronous: false

                sourceComponent: Component {
                    PunchiMenuFullScreenSettingsView {
                        backgroundBlurEnabled: root.backgroundBlurEnabled
                        backgroundOpacityPercent: Math.round(
                            root.safeBackgroundOpacity * 100)
                        showDistributionName: root.showDistributionName
                        showPageNavigationArrows:
                            root.showPageNavigationArrows
                        showApplicationLabels: root.showApplicationLabels
                        hoverAnimation: root.hoverAnimation
                        sortApplicationsAlphabetically:
                            root.sortApplicationsAlphabetically
                        closeButtonPosition: root.closeButtonPosition
                        applicationIconScalePercent: Math.round(
                            root.safeApplicationIconScale * 100)
                        favoriteIconScalePercent: Math.round(
                            root.safeFavoriteIconScale * 100)
                        folderMaximumColumns: root.safeFolderMaximumColumns
                        folderMaximumRows: root.safeFolderMaximumRows
                        errorMessage: root.settingsErrorMessage

                        onSettingChanged: function(fieldName, value) {
                            root.settingsErrorMessage = ""
                            root.settingChangeRequested(fieldName, value)
                        }
                        onAdvancedConfigurationRequested:
                            root.configureRequested()
                    }
                }
            }

            Loader {
                id: sessionViewLoader
                anchors.fill: parent
                active: root.sessionViewRequested || root.sessionViewActive
                visible: root.sessionViewActive
                enabled: visible && !root.modeTransitionActive
                asynchronous: false

                sourceComponent: Component {
                    PunchiMenuSessionView {
                        userName: String(currentUser.fullName
                            || currentUser.loginName
                            || i18nc("@info:user", "User"))
                        userAvatar: currentUser.faceIconUrl
                        canLogout: sessionActions.canLogout
                        canRestart: sessionActions.canReboot
                        canShutdown: sessionActions.canShutdown

                        onLogoutRequested: {
                            root.forceClose()
                            sessionActions.requestLogout()
                        }
                        onRestartRequested: {
                            root.forceClose()
                            sessionActions.requestReboot()
                        }
                        onShutdownRequested: {
                            root.forceClose()
                            sessionActions.requestShutdown()
                        }
                    }
                }
            }
        }

        ColumnLayout {
            id: favoritesSection

            readonly property real reservedHeight: Kirigami.Units.gridUnit * 6.5

            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.leftMargin: root.applicationGridHorizontalInset
            Layout.rightMargin: root.applicationGridHorizontalInset
            Layout.minimumHeight: visible ? reservedHeight : 0
            Layout.preferredHeight: visible ? reservedHeight : 0
            Layout.maximumHeight: visible ? reservedHeight : 0
            visible: root.favoritesSectionVisible
            enabled: !root.modeTransitionActive
            opacity: root.modeContentOpacity
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: width
                    source: "favorite-symbolic"
                    Accessible.ignored: true
                }

                Kirigami.Heading {
                    level: 4
                    text: i18nc("@title:section", "Favorites")
                    Accessible.role: Accessible.Heading
                    Accessible.name: text
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.ToolButton {
                    id: favoritesLeftButton

                    readonly property bool overflow:
                        favoritesView.contentWidth > favoritesView.width
                    readonly property bool canScroll: overflow
                        && !favoritesView.atXBeginning

                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                    Layout.fillHeight: true
                    enabled: canScroll
                    opacity: canScroll ? (hovered || activeFocus ? 0.90 : 0.55) : 0.0
                    icon.name: "go-previous-symbolic"
                    display: PlasmaComponents.AbstractButton.IconOnly
                    text: i18nc("@action:button", "Scroll favorites left")
                    Accessible.name: text

                    PlasmaCore.ToolTipArea {
                        id: favoritesLeftToolTip
                        anchors.fill: parent
                        active: favoritesLeftButton.enabled
                            && favoritesLeftButton.visible
                        mainText: favoritesLeftButton.text
                    }

                    onActiveFocusChanged: {
                        if (activeFocus) {
                            favoritesLeftToolTip.showToolTip()
                        } else if (!favoritesLeftToolTip.containsMouse) {
                            favoritesLeftToolTip.hideImmediately()
                        }
                    }
                    onClicked: root.scrollFavoritesBy(-favoritesView.delegateWidth)

                    Behavior on opacity {
                        enabled: root.motionEnabled
                        NumberAnimation { duration: Kirigami.Units.shortDuration }
                    }
                }

                ListView {
                    id: favoritesView

                    readonly property real delegateWidth:
                        Kirigami.Units.gridUnit * 6.6

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: ListView.Horizontal
                    spacing: Kirigami.Units.smallSpacing
                    clip: true
                    model: root.favorites
                    boundsBehavior: Flickable.StopAtBounds
                    keyNavigationWraps: false
                    activeFocusOnTab: root.favoritesSectionVisible
                    enabled: !root.applicationLaunchPending

                    onDraggingChanged: {
                        if (dragging) {
                            favoritesScrollAnimation.stop()
                        }
                    }
                    onFlickingChanged: {
                        if (flicking) {
                            favoritesScrollAnimation.stop()
                        }
                    }
                    onActiveFocusChanged: {
                        if (activeFocus && count > 0) {
                            if (currentIndex < 0 || currentIndex >= count) {
                                currentIndex = 0
                            }
                            positionViewAtIndex(currentIndex, ListView.Contain)
                        }
                    }
                    onCurrentIndexChanged: {
                        if (activeFocus && currentIndex >= 0) {
                            positionViewAtIndex(currentIndex, ListView.Contain)
                        }
                    }
                    onCountChanged: {
                        if (count > 0 && currentIndex < 0) {
                            currentIndex = 0
                        } else if (currentIndex >= count) {
                            currentIndex = count - 1
                        }
                    }

                    Keys.onUpPressed: function(event) {
                        root.forceActiveFocus()
                        event.accepted = true
                    }
                    Keys.onReturnPressed: function(event) {
                        root.launchFavoriteAt(currentIndex)
                        event.accepted = true
                    }
                    Keys.onEnterPressed: function(event) {
                        root.launchFavoriteAt(currentIndex)
                        event.accepted = true
                    }
                    Keys.onSpacePressed: function(event) {
                        root.launchFavoriteAt(currentIndex)
                        event.accepted = true
                    }
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Menu
                                || (event.key === Qt.Key_F10
                                    && (event.modifiers & Qt.ShiftModifier))) {
                            event.accepted = root.openCurrentFavoriteContextMenu()
                        }
                    }

                    delegate: Item {
                        id: favoriteDelegate

                        required property var modelData
                        required property int index

                        width: favoritesView.delegateWidth
                        height: favoritesView.height
                        readonly property string appName:
                            String(modelData.appName || "")
                        readonly property string appIcon:
                            String(modelData.appIcon || "application-x-executable")
                        readonly property string appStorageId:
                            String(modelData.appStorageId || "")
                        readonly property string appCommand:
                            String(modelData.appCommand || "")
                        readonly property bool isHiddenApplication:
                            root.isApplicationHidden(appStorageId)
                        readonly property bool keyboardFocused:
                            favoritesView.activeFocus
                            && favoritesView.currentIndex === index
                        readonly property bool selected: keyboardFocused
                            || favoriteMouseArea.containsMouse

                        PunchiMenuIconMetrics {
                            id: favoriteIconMetrics
                            requestedScale: root.safeFavoriteIconScale
                            minimumScale: 0.75
                            maximumScale: 1.1
                            baseSize: Kirigami.Units.iconSizes.large
                            minimumSize: Kirigami.Units.iconSizes.medium
                            availableWidth: Math.max(0,
                                favoriteDelegate.width
                                    - Kirigami.Units.gridUnit)
                            availableHeight: Math.max(0,
                                favoriteDelegate.height * 0.58)
                        }
                        opacity: isHiddenApplication ? 0.58 : 1.0
                        Accessible.role: Accessible.Button
                        Accessible.name: appName
                        Accessible.description: isHiddenApplication
                            ? i18nc("@info:accessibility",
                                "Hidden from the application listing")
                            : ""
                        Accessible.focused: keyboardFocused
                        Accessible.onPressAction: root.launchFavoriteAt(index)

                            PunchiMenuItemHighlight {
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.smallSpacing
                                hovered: favoriteMouseArea.containsMouse
                                selected: favoriteDelegate.selected
                                focused: favoriteDelegate.keyboardFocused
                                pressed: favoriteMouseArea.pressed
                                motionEnabled: root.motionEnabled
                                animationMode: root.hoverAnimation

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.smallSpacing
                                anchors.topMargin: root.showApplicationLabels
                                    ? Kirigami.Units.smallSpacing
                                    : Math.max(Kirigami.Units.smallSpacing,
                                        (parent.height - favoriteIconMetrics
                                            .effectiveSize) / 2)
                                anchors.bottomMargin: anchors.topMargin
                                spacing: Kirigami.Units.smallSpacing

                                Kirigami.Icon {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth:
                                        favoriteIconMetrics.effectiveSize
                                    Layout.preferredHeight: width
                                    source: favoriteDelegate.appIcon
                                }

                                PlasmaComponents.Label {
                                    id: favoriteLabel
                                    Layout.fillWidth: true
                                    visible: root.showApplicationLabels
                                    text: favoriteDelegate.appName
                                    horizontalAlignment: Text.AlignHCenter
                                    maximumLineCount: 1
                                    elide: Text.ElideRight
                                    font: Kirigami.Theme.smallFont
                                }
                            }

                            Kirigami.Icon {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: Kirigami.Units.smallSpacing
                                width: Kirigami.Units.iconSizes.small
                                height: width
                                source: "view-hidden-symbolic"
                                visible: favoriteDelegate.isHiddenApplication
                                Accessible.ignored: true
                            }

                            PlasmaCore.ToolTipArea {
                                anchors.fill: parent
                                active: !root.showApplicationLabels
                                    || favoriteLabel.truncated
                                mainText: favoriteDelegate.appName

                                MouseArea {
                                    id: favoriteMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: favoritesView.currentIndex
                                        = favoriteDelegate.index
                                    onClicked: function(mouse) {
                                        favoritesView.currentIndex
                                            = favoriteDelegate.index
                                        if (mouse.button === Qt.RightButton) {
                                            root.openApplicationContextMenu(
                                                favoriteDelegate,
                                                favoriteDelegate.appStorageId,
                                                favoriteDelegate.appName,
                                                favoriteDelegate.appIcon,
                                                favoriteDelegate.appCommand,
                                                mouse.x, mouse.y)
                                        } else {
                                            root.launchFavoriteAt(
                                                favoriteDelegate.index)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                PlasmaComponents.ToolButton {
                    id: favoritesRightButton

                    readonly property bool overflow:
                        favoritesView.contentWidth > favoritesView.width
                    readonly property bool canScroll: overflow
                        && !favoritesView.atXEnd

                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                    Layout.fillHeight: true
                    enabled: canScroll
                    opacity: canScroll ? (hovered || activeFocus ? 0.90 : 0.55) : 0.0
                    icon.name: "go-next-symbolic"
                    display: PlasmaComponents.AbstractButton.IconOnly
                    text: i18nc("@action:button", "Scroll favorites right")
                    Accessible.name: text

                    PlasmaCore.ToolTipArea {
                        id: favoritesRightToolTip
                        anchors.fill: parent
                        active: favoritesRightButton.enabled
                            && favoritesRightButton.visible
                        mainText: favoritesRightButton.text
                    }

                    onActiveFocusChanged: {
                        if (activeFocus) {
                            favoritesRightToolTip.showToolTip()
                        } else if (!favoritesRightToolTip.containsMouse) {
                            favoritesRightToolTip.hideImmediately()
                        }
                    }
                    onClicked: root.scrollFavoritesBy(favoritesView.delegateWidth)

                    Behavior on opacity {
                        enabled: root.motionEnabled
                        NumberAnimation { duration: Kirigami.Units.shortDuration }
                    }
                }
            }

            SmoothedAnimation {
                id: favoritesScrollAnimation
                target: favoritesView
                property: "contentX"
                velocity: Kirigami.Units.gridUnit * 28
                maximumEasingTime: 120
            }
        }

        Row {
            id: pageIndicator
            Layout.alignment: Qt.AlignHCenter
            spacing: Math.max(1, Math.round(root.pageIndicatorDotDiameter * 0.5))
            visible: root.applicationViewActive && root.pageCount > 1
            enabled: !root.modeTransitionActive
            opacity: root.modeContentOpacity
            Accessible.role: Accessible.Grouping

            Repeater {
                model: root.pageCount

                delegate: Controls.AbstractButton {
                    id: pageButton
                    required property int index
                    width: root.pageIndicatorTargetDiameter
                    height: width
                    focusPolicy: Qt.StrongFocus
                    Accessible.name: i18nc("@action:button", "Page %1 of %2",
                        index + 1, root.pageCount)
                    Accessible.onPressAction: root.goToPage(index)
                    onClicked: root.goToPage(index)

                    contentItem: Item {
                        Rectangle {
                            anchors.centerIn: parent
                            width: root.pageIndicatorDotDiameter
                            height: width
                            radius: width / 2
                            color: pagesView.currentIndex === index
                                ? Kirigami.Theme.highlightColor
                                : Qt.alpha(Kirigami.Theme.textColor, 0.45)
                            border.width: pageButton.activeFocus ? 1 : 0
                            border.color: Kirigami.Theme.highlightColor
                        }
                    }

                    background: Item {}
                }
            }
        }
    }

    PunchiMenuDragLayer {
        id: internalDragLayer
        anchors.fill: parent
        z: 230
        showApplicationLabels: root.showApplicationLabels
        motionEnabled: root.motionEnabled
    }

    Loader {
        id: folderSurfaceLoader
        anchors.fill: parent
        z: 200
        active: false
        asynchronous: false

        sourceComponent: Component {
            PunchiMenuFolderSurface {
                layoutModel: applicationLayoutModel
                layoutController: root.applicationLayoutController
                motionEnabled: root.motionEnabled
                iconScale: root.safeApplicationIconScale
                maximumColumnCount: root.safeFolderMaximumColumns
                maximumRowCount: root.safeFolderMaximumRows
                showApplicationLabels: root.showApplicationLabels
                hoverAnimation: root.hoverAnimation
                detailedApplicationFeedback: true
                returnToFolderAfterMemberRemoval: true
                allowedExternalFocusItems: [
                    standaloneApplicationContextMenu.contentItem,
                    folderMemberContextMenu.contentItem,
                    folderContextMenu.contentItem,
                    operationInlineMessage
                ]

                onLaunchRequested: function(storageId) {
                    const requestedStorageId = String(storageId || "")
                    if (requestedStorageId.length === 0
                            || root.applicationLaunchPending) {
                        return
                    }
                    root.applicationErrorMessage = ""
                    root.applicationLaunchPending = true
                    root.systemDiscovery.launchApplication(requestedStorageId)
                }
                onApplicationContextRequested: function(sourceItem, application,
                        folderId, x, y) {
                    root.openApplicationContextMenu(sourceItem,
                        String(application.appStorageId
                            || application.storageId || ""),
                        String(application.appName || application.name || ""),
                        String(application.appIcon || application.icon
                            || "application-x-executable"),
                        "", x, y)
                }
                onCloseRequested: function(nodeId) {
                    root.restoreApplicationNodeFocus(nodeId)
                }
            }
        }
    }

    Kirigami.InlineMessage {
        id: operationInlineMessage

        y: mainContentContainer.y + gridArea.y
        anchors.horizontalCenter: root.horizontalCenter
        width: Math.min(gridArea.width, Kirigami.Units.gridUnit * 36)
        visible: false
        enabled: visible
        showCloseButton: true
        type: root.operationMessage.length > 0 && !root.operationMessageIsError
            ? Kirigami.MessageType.Positive
            : Kirigami.MessageType.Error
        text: root.operationCountdownText
        Accessible.name: root.operationBaseMessage
        Accessible.description: i18nc("@info:accessible",
            "Closes automatically")
        actions: [
            Kirigami.Action {
                text: i18nc("@action:button", "Undo Folder Change")
                icon.name: "edit-undo"
                visible: root.operationMessage.length > 0
                    && root.applicationLayoutController
                    && root.applicationLayoutController.canUndo
                enabled: visible
                onTriggered: root.requestFolderUndo()
            }
        ]
        z: 240

        onVisibleChanged: {
            if (!visible && !root.operationMessageDismissalInProgress
                    && root.applicationViewActive
                    && (root.operationMessage.length > 0
                        || root.applicationErrorMessage.length > 0)) {
                root.dismissOperationMessage()
            }
        }

        HoverHandler {
            id: operationInlineMessageHover
            onHoveredChanged: {
                if (hovered) {
                    operationMessageTimer.stop()
                } else if (operationInlineMessage.visible
                        && root.operationSecondsRemaining > 0) {
                    operationMessageTimer.start()
                }
            }
        }
    }

    Timer {
        id: operationMessageTimer
        interval: 1000
        repeat: true
        onTriggered: {
            if (root.operationSecondsRemaining <= 1) {
                root.dismissOperationMessage()
            } else {
                root.operationSecondsRemaining--
            }
        }
    }
}
// qmllint enable unqualified
