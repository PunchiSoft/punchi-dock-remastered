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
    property var applicationLayoutController: null
    property real applicationIconScale: 1.0
    property real favoriteIconScale: 1.0
    property bool backgroundBlurEnabled: true
    property real backgroundOpacity: 0.50
    property bool showDistributionName: true
    property var hiddenApplicationIds: []
    property bool revealHiddenApplications: false
    property bool menuOpen: false
    property bool applicationsLoading: false
    property bool applicationLaunchPending: false
    property string applicationErrorMessage: ""
    property string operationMessage: ""
    property bool operationMessageIsError: false
    property bool operationMessageDismissalInProgress: false
    property string searchText: ""
    property int currentApplicationIndex: -1
    property bool pageNavigationActive: false
    property int pendingPageStep: 0
    property real wheelPageAccumulator: 0
    property bool wheelGestureCommitted: false
    property bool sessionViewActive: false
    property bool sessionViewRequested: false
    property real modeContentOpacity: 1.0
    property var applications: []

    readonly property bool motionEnabled: Kirigami.Units.longDuration > 0
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
            ? Math.max(0.75, Math.min(2.0, requestedScale))
            : 1.0
    }
    readonly property real safeFavoriteIconScale: {
        const requestedScale = Number(favoriteIconScale)
        return Number.isFinite(requestedScale)
            ? Math.max(0.75, Math.min(1.5, requestedScale))
            : 1.0
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
        const source = applicationCatalog.length > 0
            ? applicationCatalog : applications
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
        && applicationCatalog.length > 0
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
        const source = applicationCatalog.length > 0
            ? applicationCatalog : applications
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
                appCommand: applicationCatalog.length > 0
                    ? "" : String(app.appCommand || ""),
                appHidden: appHidden
            })
        }
        return result
    }
    readonly property int pageCount: visibleApplications.length > 0
        ? Math.ceil(visibleApplications.length / pageCapacity)
        : 0
    readonly property bool favoritesSectionVisible: !sessionViewActive
        && favorites.length > 0
        && searchText.trim().length === 0
    readonly property bool pageTransitionActive: pageCount > 0
        && (pagesView.moving || Math.abs(pagesView.contentX
            - pagesView.currentIndex * Math.max(1, pagesView.width)) > 0.5)
    readonly property bool applicationHoverAllowed: !sessionViewActive
        && !modeTransitionActive
        && !pageTransitionActive
        && !applicationLaunchPending
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
    property var favorites: []

    signal closeFinished()
    signal addFavoriteRequested(string storageId)
    signal removeFavoriteRequested(string storageId)
    signal pinToDockRequested(string storageId, string appName, string appIcon, string appCommand)
    signal addToDesktopRequested(string storageId, string appCommand)
    signal setApplicationHiddenRequested(string storageId, bool hidden)
    signal configureRequested()

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
        operationInlineMessage.visible = !sessionViewActive
            && messageAvailable
        if (messageAvailable) {
            operationMessageTimer.restart()
        }
    }

    function dismissOperationMessage() {
        operationMessageDismissalInProgress = true
        operationMessageTimer.stop()
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

    function applyPageStep(step) {
        goToPage(pagesView.currentIndex + (step < 0 ? -1 : 1))
    }

    function requestPageStep(step) {
        if (!menuOpen || pageCount <= 1) {
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

    function commitSessionViewState(active) {
        sessionViewActive = Boolean(active)
        resetPageNavigation()
        resetWheelGesture()
        if (sessionViewActive) {
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
            sessionView.focusInitialAction()
        } else {
            searchField.forceActiveFocus()
        }
    }

    function resetSessionTransition() {
        modeFadeOutAnimation.stop()
        modeFadeInAnimation.stop()
        modeContentOpacity = 1.0
        sessionViewRequested = false
        sessionViewActive = false
    }

    function setSessionViewActive(active) {
        const requestedState = Boolean(active)
        if (sessionViewRequested === requestedState
                && (sessionViewActive === requestedState
                    || modeTransitionActive)) {
            return
        }

        sessionViewRequested = requestedState
        resetPageNavigation()
        resetWheelGesture()
        sessionButton.forceActiveFocus()

        modeFadeOutAnimation.stop()
        modeFadeInAnimation.stop()

        if (!motionEnabled) {
            modeContentOpacity = 1.0
            commitSessionViewState(requestedState)
            Qt.callLater(focusCurrentMode)
            return
        }

        if (sessionViewActive === requestedState) {
            if (modeContentOpacity < 0.999) {
                modeFadeInAnimation.start()
            } else {
                Qt.callLater(focusCurrentMode)
            }
            return
        }

        modeFadeOutAnimation.start()
    }

    function openOverlay() {
        closeTimer.stop()
        folderSurface.reset()
        resetPageNavigation()
        resetWheelGesture()
        revealHiddenApplications = false
        resetSessionTransition()
        menuOpen = true
        searchText = ""
        applicationsLoading = true
        applicationLaunchPending = false
        applicationErrorMessage = ""
        operationMessage = ""
        applications = []
        currentApplicationIndex = -1
        root.forceActiveFocus()
        systemDiscovery.requestApplications("All")
    }

    function forceClose() {
        closeTimer.stop()
        folderSurface.reset()
        if (applicationLayoutController) {
            applicationLayoutController.discardUndoHistory()
        }
        resetPageNavigation()
        resetWheelGesture()
        revealHiddenApplications = false
        modeFadeOutAnimation.stop()
        modeFadeInAnimation.stop()
        sessionViewRequested = sessionViewActive
        menuOpen = false
        applicationsLoading = false
        applicationLaunchPending = false
        closeTimer.restart()
    }

    function resetOverlay() {
        closeTimer.stop()
        folderSurface.reset()
        if (applicationLayoutController) {
            applicationLayoutController.discardUndoHistory()
        }
        resetPageNavigation()
        resetWheelGesture()
        revealHiddenApplications = false
        resetSessionTransition()
        menuOpen = false
        searchText = ""
        applicationsLoading = false
        applicationLaunchPending = false
        applicationErrorMessage = ""
        operationMessage = ""
        applications = []
        currentApplicationIndex = -1
    }

    onSearchTextChanged: resetPagination()
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
        if (folderSurface.active) {
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_Back) {
                folderSurface.closeCurrentView()
                event.accepted = true
            }
            return
        }
        if (root.sessionViewRequested || root.sessionViewActive) {
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_Back) {
                root.setSessionViewActive(false)
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
            } else if (root.sessionViewRequested || root.sessionViewActive) {
                root.setSessionViewActive(false)
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
            root.commitSessionViewState(root.sessionViewRequested)
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

    Connections {
        target: root.systemDiscovery
        ignoreUnknownSignals: true

        function onApplicationsReady(applications) {
            const list = applications || []
            const resolvedApplications = []
            for (let index = 0; index < list.length; index++) {
                const app = list[index]
                resolvedApplications.push({
                    appName: String(app.name || ""),
                    appIcon: String(app.icon || "application-x-executable"),
                    appStorageId: String(app.storageId || ""),
                    appCommand: String(app.command || "")
                })
            }
            root.applications = resolvedApplications
            root.applicationsLoading = false
            root.resetPagination()
        }

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
                Layout.preferredWidth: closeButton.implicitWidth
                Layout.preferredHeight: 1
            }

            Item {
                id: distributionTitleContainer

                Layout.fillWidth: true
                Layout.preferredHeight: visible
                    ? distributionHeading.implicitHeight : 0
                visible: root.showDistributionName
                    && root.distributionName.length > 0

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
                    }
                }
            }

            PlasmaComponents.ToolButton {
                id: closeButton
                readonly property bool highlightedContent: enabled
                    && (hovered || down)
                icon.name: "window-close"
                icon.color: highlightedContent
                    ? root.Kirigami.Theme.highlightedTextColor
                    : root.Kirigami.Theme.textColor
                display: PlasmaComponents.AbstractButton.IconOnly
                text: i18nc("@action:button", "Close")
                Accessible.name: text
                onClicked: root.forceClose()
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
                enabled: !root.sessionViewActive && !root.modeTransitionActive
                opacity: root.sessionViewActive ? 0.0 : root.modeContentOpacity

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
                Layout.preferredWidth: root.headerControlSize
                Layout.minimumWidth: Layout.preferredWidth
                Layout.maximumWidth: Layout.preferredWidth
                Layout.preferredHeight: root.headerControlSize
                Layout.minimumHeight: Layout.preferredHeight
                Layout.maximumHeight: Layout.preferredHeight
                visible: root.hiddenApplicationCount > 0
                enabled: !root.sessionViewActive
                    && root.menuOpen && !root.modeTransitionActive
                    && !root.applicationLaunchPending
                opacity: root.sessionViewActive ? 0.0 : root.modeContentOpacity
                icon.name: root.revealHiddenApplications
                    ? "view-visible"
                    : "view-hidden"
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

                background: PunchiMenuSearchBackground {
                    fieldActiveFocus: hiddenApplicationsButton.activeFocus
                    fieldHovered: hiddenApplicationsButton.hovered
                    auxiliaryHovered: hiddenApplicationsButton.checked
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
                Layout.preferredWidth: root.headerControlSize
                Layout.minimumWidth: Layout.preferredWidth
                Layout.maximumWidth: Layout.preferredWidth
                Layout.preferredHeight: root.headerControlSize
                Layout.minimumHeight: Layout.preferredHeight
                Layout.maximumHeight: Layout.preferredHeight
                icon.name: "configure"
                display: PlasmaComponents.AbstractButton.IconOnly
                text: i18n("Configure PunchiMenu")
                Accessible.name: text
                KeyNavigation.backtab: hiddenApplicationsButton.visible
                    ? hiddenApplicationsButton
                    : clearSearchButton.visible
                        ? clearSearchButton
                        : searchField
                KeyNavigation.tab: sessionButton

                background: PunchiMenuSearchBackground {
                    fieldActiveFocus: configureButton.activeFocus
                    fieldHovered: configureButton.hovered
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

                onClicked: root.configureRequested()
            }

            PlasmaComponents.ToolButton {
                id: sessionButton
                Layout.preferredWidth: root.headerControlSize
                Layout.minimumWidth: Layout.preferredWidth
                Layout.maximumWidth: Layout.preferredWidth
                Layout.preferredHeight: root.headerControlSize
                Layout.minimumHeight: Layout.preferredHeight
                Layout.maximumHeight: Layout.preferredHeight
                icon.name: root.sessionViewRequested
                    ? "view-grid"
                    : "system-log-out"
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
                KeyNavigation.tab: root.sessionViewActive
                    ? sessionView : closeButton

                background: PunchiMenuSearchBackground {
                    fieldActiveFocus: sessionButton.activeFocus
                    fieldHovered: sessionButton.hovered
                    auxiliaryHovered: sessionButton.checked
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
                onClicked: root.setSessionViewActive(!root.sessionViewRequested)
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
                interactive: root.pageCount > 1
                boundsBehavior: Flickable.StopAtBounds
                snapMode: ListView.SnapOneItem
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: 0
                preferredHighlightEnd: 0
                highlightMoveDuration: root.motionEnabled ? Kirigami.Units.longDuration : 0
                maximumFlickVelocity: 4 * width
                cacheBuffer: Math.max(0, width)
                enabled: !root.sessionViewActive
                    && !root.modeTransitionActive
                    && !root.applicationLaunchPending
                visible: !root.sessionViewActive

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

                    Grid {
                        id: applicationsGrid
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        columns: root.gridColumns
                        rows: root.gridRows
                        columnSpacing: Kirigami.Units.mediumSpacing
                        rowSpacing: Kirigami.Units.smallSpacing

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
                                    || (appMouseArea.containsMouse
                                        && root.applicationHoverAllowed)
                                readonly property bool isHiddenApplication:
                                    !isFolder && !!modelData.appHidden
                                readonly property real safeIconSize: Math.max(
                                    Kirigami.Units.iconSizes.medium,
                                    Math.min(root.responsiveApplicationIconBase
                                            * root.safeApplicationIconScale,
                                        width * 0.55, height * 0.58))

                                width: (applicationsGrid.width
                                    - applicationsGrid.columnSpacing
                                        * (root.gridColumns - 1)) / root.gridColumns
                                height: (applicationsGrid.height
                                    - applicationsGrid.rowSpacing
                                        * (root.gridRows - 1)) / root.gridRows
                                opacity: isHiddenApplication ? 0.58 : 1.0
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
                                    selected: appDelegate.isSelected
                                    motionEnabled: root.motionEnabled
                                    iconScale: root.safeApplicationIconScale
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

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: Kirigami.Units.smallSpacing
                                    visible: !appDelegate.isFolder
                                    radius: Kirigami.Units.cornerRadius * 2
                                    color: appDelegate.highlighted
                                        ? Qt.alpha(Kirigami.Theme.highlightColor, 0.20)
                                        : "transparent"
                                    border.color: appDelegate.isSelected
                                        ? Kirigami.Theme.highlightColor
                                        : "transparent"
                                    border.width: appDelegate.isSelected ? 2 : 0
                                    scale: appDelegate.highlighted ? 1.03 : 1.0

                                    Behavior on scale {
                                        enabled: root.motionEnabled
                                        NumberAnimation {
                                            duration: Kirigami.Units.shortDuration
                                            easing.type: Easing.OutCubic
                                        }
                                    }

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
                                            Layout.fillWidth: true
                                            text: String(appDelegate.modelData.appName || "")
                                            textFormat: Text.PlainText
                                            horizontalAlignment: Text.AlignHCenter
                                            wrapMode: Text.Wrap
                                            maximumLineCount: 2
                                            elide: Text.ElideRight
                                            font: Kirigami.Theme.smallFont
                                        }
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

                                    MouseArea {
                                        id: appMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        preventStealing: false
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: {
                                            if (root.applicationHoverAllowed) {
                                                root.setCurrentApplication(appDelegate.globalIndex)
                                            }
                                        }
                                        onClicked: function(mouse) {
                                            root.setCurrentApplication(appDelegate.globalIndex)
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
                                                root.launchApplicationAt(appDelegate.globalIndex)
                                            }
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
                    if (!root.sessionViewActive) {
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
                visible: !root.sessionViewActive && root.pageCount > 1
                enabled: pagesView.currentIndex > 0 && !root.applicationLaunchPending
                opacity: enabled ? (hovered || activeFocus ? 1.0 : 0.62) : 0.20
                focusPolicy: Qt.StrongFocus
                icon.name: "go-previous-symbolic"
                display: PlasmaComponents.AbstractButton.IconOnly
                text: i18nc("@action:button", "Previous page")
                Accessible.name: text
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
                visible: !root.sessionViewActive && root.pageCount > 1
                enabled: pagesView.currentIndex < root.pageCount - 1
                    && !root.applicationLaunchPending
                opacity: enabled ? (hovered || activeFocus ? 1.0 : 0.62) : 0.20
                focusPolicy: Qt.StrongFocus
                icon.name: "go-next-symbolic"
                display: PlasmaComponents.AbstractButton.IconOnly
                text: i18nc("@action:button", "Next page")
                Accessible.name: text
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
                visible: !root.sessionViewActive && (root.applicationsLoading
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

            PunchiMenuSessionView {
                id: sessionView
                anchors.fill: parent
                visible: root.sessionViewActive
                enabled: visible && !root.modeTransitionActive
                userName: String(currentUser.fullName || currentUser.loginName
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
                        opacity: isHiddenApplication ? 0.58 : 1.0
                        Accessible.role: Accessible.Button
                        Accessible.name: appName
                        Accessible.description: isHiddenApplication
                            ? i18nc("@info:accessibility",
                                "Hidden from the application listing")
                            : ""
                        Accessible.focused: keyboardFocused
                        Accessible.onPressAction: root.launchFavoriteAt(index)

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            radius: Kirigami.Units.cornerRadius * 1.5
                            color: favoriteDelegate.selected
                                ? Qt.alpha(Kirigami.Theme.highlightColor, 0.24)
                                : "transparent"
                            border.color: favoriteDelegate.selected
                                ? Kirigami.Theme.highlightColor
                                : "transparent"
                            border.width: favoriteDelegate.selected ? 2 : 0
                            scale: favoriteMouseArea.pressed
                                ? 0.97 : favoriteDelegate.selected ? 1.018 : 1.0

                            Behavior on scale {
                                enabled: root.motionEnabled
                                NumberAnimation {
                                    duration: favoriteMouseArea.pressed ? 80 : 130
                                    easing.type: Easing.OutCubic
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.smallSpacing
                                spacing: Kirigami.Units.smallSpacing

                                Kirigami.Icon {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: Math.min(
                                        Kirigami.Units.iconSizes.large
                                            * root.safeFavoriteIconScale,
                                        favoriteDelegate.height * 0.58)
                                    Layout.preferredHeight: width
                                    source: favoriteDelegate.appIcon
                                }

                                PlasmaComponents.Label {
                                    id: favoriteLabel
                                    Layout.fillWidth: true
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
                                active: favoriteLabel.truncated
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
            visible: !root.sessionViewActive && root.pageCount > 1
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

    PunchiMenuFolderSurface {
        id: folderSurface
        anchors.fill: parent
        z: 200
        layoutModel: applicationLayoutModel
        layoutController: root.applicationLayoutController
        motionEnabled: root.motionEnabled
        iconScale: root.safeApplicationIconScale
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

    Kirigami.InlineMessage {
        id: operationInlineMessage

        y: mainContentContainer.y + gridArea.y
        anchors.horizontalCenter: root.horizontalCenter
        width: Math.min(gridArea.width, Kirigami.Units.gridUnit * 34)
        visible: false
        enabled: visible
        showCloseButton: true
        type: root.operationMessage.length > 0 && !root.operationMessageIsError
            ? Kirigami.MessageType.Positive
            : Kirigami.MessageType.Error
        text: root.operationMessage.length > 0
            ? root.operationMessage
            : i18nc("@info:status", "Application could not be opened: %1",
                root.applicationErrorMessage)
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
                    && !root.sessionViewActive
                    && (root.operationMessage.length > 0
                        || root.applicationErrorMessage.length > 0)) {
                root.dismissOperationMessage()
            }
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered) {
                    operationMessageTimer.stop()
                } else if (operationInlineMessage.visible) {
                    operationMessageTimer.restart()
                }
            }
        }
    }

    Timer {
        id: operationMessageTimer
        interval: root.operationMessageDuration
        repeat: false
        onTriggered: root.dismissOperationMessage()
    }
}
// qmllint enable unqualified
