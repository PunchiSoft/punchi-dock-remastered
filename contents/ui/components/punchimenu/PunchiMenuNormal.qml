import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import "../../org/punchi/dock" as Punchi

// qmllint disable unqualified
FocusScope {
    id: root

    required property var systemDiscovery
    required property var favorites
    property var applicationCatalog: []
    property var applicationLayoutController: null
    property real applicationIconScale: 1.0
    property real favoriteIconScale: 1.0
    property real backgroundOpacity: 0.75
    property real themeFrameLeftMargin: 0
    property real themeFrameTopMargin: 0
    property real themeFrameRightMargin: 0
    property real themeFrameBottomMargin: 0
    property var hiddenApplicationIds: []
    property bool revealHiddenApplications: false
    property bool favoriteLimitReached: false
    property bool menuOpen: false
    property bool applicationsLoading: false
    property bool applicationLaunchPending: false
    property string applicationErrorMessage: ""
    property string operationMessage: ""
    property bool operationMessageIsError: false
    property bool operationMessageDismissalInProgress: false
    property string activeCategoryKey: "All"
    property string activeCategoryTitle: i18nc("@title:category", "All Applications")
    property string pendingCategoryKey: ""
    property bool suppressSearchChange: false
    property int preferredApplicationIndexAfterRefresh: -1

    readonly property int columnCount: 6
    readonly property bool motionEnabled: Kirigami.Units.longDuration > 0
    readonly property int openDuration: motionEnabled
        ? Math.max(160, Math.min(240, Kirigami.Units.longDuration))
        : 0
    readonly property int closeDuration: motionEnabled
        ? Math.max(100, Math.min(160, Kirigami.Units.shortDuration))
        : 0
    readonly property int operationMessageDuration: 7000
    readonly property int headerControlSize: Kirigami.Units.gridUnit * 2
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
    readonly property real safeBackgroundOpacity: {
        const requestedOpacity = Number(backgroundOpacity)
        return Number.isFinite(requestedOpacity)
            ? Math.max(0.50, Math.min(1.0, requestedOpacity))
            : 0.75
    }
    readonly property real nativeFrameThickness: 2
    readonly property real safeThemeFrameLeftMargin: {
        const requestedMargin = Number(themeFrameLeftMargin)
        return Number.isFinite(requestedMargin) ? Math.max(0, requestedMargin) : 0
    }
    readonly property real safeThemeFrameTopMargin: {
        const requestedMargin = Number(themeFrameTopMargin)
        return Number.isFinite(requestedMargin) ? Math.max(0, requestedMargin) : 0
    }
    readonly property real safeThemeFrameRightMargin: {
        const requestedMargin = Number(themeFrameRightMargin)
        return Number.isFinite(requestedMargin) ? Math.max(0, requestedMargin) : 0
    }
    readonly property real safeThemeFrameBottomMargin: {
        const requestedMargin = Number(themeFrameBottomMargin)
        return Number.isFinite(requestedMargin) ? Math.max(0, requestedMargin) : 0
    }
    readonly property real themeFrameOverlapLeft: Math.max(0,
        safeThemeFrameLeftMargin - nativeFrameThickness)
    readonly property real themeFrameOverlapTop: Math.max(0,
        safeThemeFrameTopMargin - nativeFrameThickness)
    readonly property real themeFrameOverlapRight: Math.max(0,
        safeThemeFrameRightMargin - nativeFrameThickness)
    readonly property real themeFrameOverlapBottom: Math.max(0,
        safeThemeFrameBottomMargin - nativeFrameThickness)
    readonly property real maximumThemeFrameOverlap: Math.max(
        themeFrameOverlapLeft, themeFrameOverlapTop,
        themeFrameOverlapRight, themeFrameOverlapBottom)
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
        for (const key in hiddenApplicationLookup) {
            if (hiddenApplicationLookup[key] === true) {
                count++
            }
        }
        return count
    }
    readonly property bool favoritesSectionVisible: favorites.length > 0
        && searchField.text.length === 0
        && height >= Kirigami.Units.gridUnit * 24
    readonly property bool organizedListingActive:
        activeCategoryKey === "All"
        && searchField.text.trim().length === 0
        && applicationCatalog.length > 0
    readonly property int applicationListingCount: organizedListingActive
        ? applicationLayoutModel.nodes.length
        : visibleApplicationsModel.count

    property var dockItemsController: null

    signal closeFinished()
    signal addFavoriteRequested(string storageId)
    signal removeFavoriteRequested(string storageId)
    signal pinToDockRequested(string storageId, string appName, string appIcon, string appCommand)
    signal addToDesktopRequested(string storageId, string appCommand)
    signal setApplicationHiddenRequested(string storageId, bool hidden)

    function showOperationResult(result) {
        operationMessage = result && result.message ? String(result.message) : ""
        operationMessageIsError = !(result && result.success)
        updateOperationMessageTimer()
    }

    function requestFolderUndo() {
        if (!applicationLayoutController
                || !applicationLayoutController.canUndo) {
            return
        }
        operationMessageTimer.stop()
        const result = applicationLayoutController.requestUndo()
        if (!result || result.accepted !== true) {
            operationMessage = i18nc("@info:status",
                "The last folder change could not be undone.")
            operationMessageIsError = true
            updateOperationMessageTimer()
        }
    }

    function horizontalScrollLimit(view) {
        return Math.max(0, view.contentWidth - view.width)
    }

    function scrollHorizontalBy(view, animation, distance, velocity) {
        const currentPosition = Number(view.contentX)
        const pendingPosition = animation.running && !animation.edgeDriven
            ? Number(animation.to)
            : currentPosition
        const targetPosition = Math.max(0, Math.min(
            horizontalScrollLimit(view), pendingPosition + distance))

        animation.stop()
        animation.edgeDriven = false
        if (!motionEnabled || Math.abs(targetPosition - currentPosition) < 0.5) {
            view.contentX = targetPosition
            return
        }

        animation.velocity = velocity
        animation.to = targetPosition
        animation.start()
    }

    function updateHorizontalEdgeScroll(view, animation, direction, velocity) {
        animation.stop()
        if (!motionEnabled || direction === 0) {
            return
        }

        const targetPosition = direction < 0 ? 0 : horizontalScrollLimit(view)
        if (Math.abs(targetPosition - view.contentX) < 0.5) {
            view.contentX = targetPosition
            return
        }

        animation.edgeDriven = true
        animation.velocity = velocity
        animation.to = targetPosition
        animation.start()
    }

    function scrollCategoriesBy(distance) {
        scrollHorizontalBy(categoriesView, categoryScrollAnimation, distance,
            Kirigami.Units.gridUnit * 34)
    }

    function updateCategoryEdgeScroll() {
        const direction = categoryLeftEdge.hovered && categoryLeftEdge.canScroll
                && !categoryLeftEdge.autoScrollSuppressed
            ? -1
            : categoryRightEdge.hovered && categoryRightEdge.canScroll
                && !categoryRightEdge.autoScrollSuppressed ? 1 : 0
        updateHorizontalEdgeScroll(categoriesView, categoryScrollAnimation,
            direction, Kirigami.Units.gridUnit * 10)
    }

    function scrollFavoritesBy(distance) {
        scrollHorizontalBy(favoritesView, favoritesScrollAnimation, distance,
            Kirigami.Units.gridUnit * 28)
    }

    function handleHorizontalWheel(wheel, view, animation, step, velocity) {
        const pixelX = Number(wheel.pixelDelta.x)
        const pixelY = Number(wheel.pixelDelta.y)
        const validPixelX = Number.isFinite(pixelX) ? pixelX : 0
        const validPixelY = Number.isFinite(pixelY) ? pixelY : 0
        const usesPixelDelta = validPixelX !== 0 || validPixelY !== 0
        const angleX = Number(wheel.angleDelta.x)
        const angleY = Number(wheel.angleDelta.y)
        const horizontalDelta = usesPixelDelta
            ? validPixelX : (Number.isFinite(angleX) ? angleX : 0)
        const verticalDelta = usesPixelDelta
            ? validPixelY : (Number.isFinite(angleY) ? angleY : 0)
        const navigationDelta = Math.abs(horizontalDelta)
                > Math.abs(verticalDelta)
            ? horizontalDelta : -verticalDelta

        if (!Number.isFinite(navigationDelta) || navigationDelta === 0) {
            wheel.accepted = false
            return
        }

        const distance = usesPixelDelta
            ? Math.max(-step, Math.min(step, navigationDelta * 1.25))
            : navigationDelta < 0 ? -step : step
        wheel.accepted = true
        scrollHorizontalBy(view, animation, distance, velocity)
    }

    function updateFavoritesEdgeScroll() {
        const direction = favoritesLeftEdge.hovered && favoritesLeftEdge.canScroll
                && !favoritesLeftEdge.autoScrollSuppressed
            ? -1
            : favoritesRightEdge.hovered && favoritesRightEdge.canScroll
                && !favoritesRightEdge.autoScrollSuppressed ? 1 : 0
        updateHorizontalEdgeScroll(favoritesView, favoritesScrollAnimation,
            direction, Kirigami.Units.gridUnit * 7.5)
    }

    function stopHorizontalMotion() {
        categoryScrollAnimation.stop()
        favoritesScrollAnimation.stop()
    }

    onMenuOpenChanged: {
        if (!menuOpen) {
            stopHorizontalMotion()
        }
    }

    onMotionEnabledChanged: {
        if (!motionEnabled) {
            stopHorizontalMotion()
        }
    }

    onFavoritesSectionVisibleChanged: {
        if (!favoritesSectionVisible) {
            favoritesScrollAnimation.stop()
        }
    }

    onOperationMessageChanged: updateOperationMessageTimer()
    onApplicationErrorMessageChanged: updateOperationMessageTimer()

    function updateOperationMessageTimer() {
        if (operationMessageDismissalInProgress) {
            return
        }
        operationMessageTimer.stop()
        const messageAvailable = operationMessage.length > 0
            || applicationErrorMessage.length > 0
        operationFeedback.visible = messageAvailable
        if (messageAvailable) {
            operationMessageTimer.restart()
        }
    }

    function dismissOperationMessage() {
        operationMessageDismissalInProgress = true
        operationMessageTimer.stop()
        operationMessage = ""
        applicationErrorMessage = ""
        operationFeedback.visible = false
        operationMessageDismissalInProgress = false
    }

    function categoryIndexForKey(categoryKey) {
        const requestedKey = String(categoryKey || "")
        for (let index = 0; index < categoryModel.count; index++) {
            if (String(categoryModel.get(index).categoryKey || "") === requestedKey) {
                return index
            }
        }
        return categoryModel.count > 0 ? 0 : -1
    }

    function focusActiveCategory() {
        const index = categoryIndexForKey(activeCategoryKey)
        if (index < 0) {
            return
        }
        categoriesView.currentIndex = index
        categoriesView.positionViewAtIndex(index, ListView.Contain)
        categoriesView.forceActiveFocus()
    }

    function focusApplicationsGrid() {
        if (applicationListingCount === 0) {
            return
        }
        if (applicationsGrid.currentIndex < 0
                || applicationsGrid.currentIndex >= applicationListingCount) {
            applicationsGrid.currentIndex = 0
        }
        applicationsGrid.positionViewAtIndex(applicationsGrid.currentIndex, GridView.Contain)
        applicationsGrid.forceActiveFocus()
    }

    function focusFavorites() {
        if (!favoritesSectionVisible || favorites.length === 0) {
            return
        }
        if (favoritesView.currentIndex < 0
                || favoritesView.currentIndex >= favorites.length) {
            favoritesView.currentIndex = 0
        }
        favoritesView.positionViewAtIndex(favoritesView.currentIndex, ListView.Contain)
        favoritesView.forceActiveFocus()
    }

    function isFavorite(storageId) {
        const requestedId = String(storageId || "").trim()
        if (requestedId.length === 0) {
            return false
        }
        for (let index = 0; index < favorites.length; index++) {
            if (String(favorites[index].appStorageId || "").trim()
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

    function applicationShouldBeVisible(storageId) {
        return revealHiddenApplications || !isApplicationHidden(storageId)
    }

    function applicationNodeAt(index) {
        if (index < 0 || index >= applicationListingCount) {
            return null
        }
        if (organizedListingActive) {
            return applicationLayoutModel.nodes[index] || null
        }
        const application = visibleApplicationsModel.get(index)
        return {
            nodeType: "application",
            nodeId: "application:" + String(application.appStorageId || ""),
            appStorageId: String(application.appStorageId || ""),
            appName: String(application.appName || ""),
            appIcon: String(application.appIcon
                || "application-x-executable"),
            appCommand: String(application.appCommand || ""),
            appHidden: Boolean(application.appHidden)
        }
    }

    function restoreApplicationNodeFocus(nodeId) {
        let targetIndex = -1
        const requestedNodeId = String(nodeId || "")
        if (organizedListingActive && requestedNodeId.length > 0) {
            targetIndex = applicationLayoutModel.indexForNodeId(requestedNodeId)
        }
        if (targetIndex < 0 && applicationListingCount > 0) {
            targetIndex = Math.max(0, Math.min(
                applicationListingCount - 1, applicationsGrid.currentIndex))
        }
        applicationsGrid.currentIndex = targetIndex
        if (targetIndex >= 0) {
            applicationsGrid.positionViewAtIndex(targetIndex,
                GridView.Contain)
            applicationsGrid.forceActiveFocus()
        } else {
            searchField.forceActiveFocus()
        }
    }

    function restorePreferredApplicationIndex() {
        if (applicationListingCount === 0) {
            applicationsGrid.currentIndex = -1
        } else {
            const preferredIndex = preferredApplicationIndexAfterRefresh >= 0
                ? preferredApplicationIndexAfterRefresh
                : applicationsGrid.currentIndex
            applicationsGrid.currentIndex = Math.max(0,
                Math.min(applicationListingCount - 1, preferredIndex))
        }
        preferredApplicationIndexAfterRefresh = -1
        if (applicationsGrid.currentIndex >= 0) {
            applicationsGrid.positionViewAtIndex(
                applicationsGrid.currentIndex, GridView.Contain)
        }
    }

    function refreshApplicationListing() {
        if (!menuOpen) {
            return
        }
        if (searchField.text.trim().length > 0) {
            filterAllApplications()
        } else {
            selectCategory(activeCategoryKey, activeCategoryTitle, false)
        }
    }

    function openApplicationContextMenu(sourceItem, storageId, appName, appIcon, appCommand, x, y) {
        const normalizedId = String(storageId || "").trim()
        const normalizedCmd = String(appCommand || "").trim()
        const primaryId = normalizedId.length > 0 ? normalizedId : normalizedCmd
        const localX = Number(x)
        const localY = Number(y)
        if (!sourceItem || primaryId.length === 0
                || !Number.isFinite(localX) || !Number.isFinite(localY)) {
            return
        }
        closeApplicationContextMenu(false)
        const placement = applicationLayoutModel.applicationPlacement(normalizedId)
        const context = {
            kind: String(placement.placement || "missing") === "folder"
                ? "folderMember" : "standaloneApplication",
            storageId: normalizedId,
            appCommand: normalizedCmd,
            appName: String(appName || ""),
            appIcon: String(appIcon || ""),
            containingFolderId: String(placement.folderId || ""),
            isFavorite: isFavorite(primaryId),
            isPinnedToDock: root.dockItemsController
                ? root.dockItemsController.isAppPinnedToDock(
                    normalizedId, normalizedCmd)
                : false,
            isHidden: isApplicationHidden(normalizedId)
        }
        const entries = context.kind === "folderMember"
            ? folderMemberContextEntries(context)
            : standaloneApplicationContextEntries(context)
        applicationContextMenuSurface.openAt(sourceItem,
            localX, localY, entries, context)
    }

    function openFolderContextMenu(sourceItem, folder, x, y) {
        const folderId = String(folder ? folder.folderId || "" : "").trim()
        const localX = Number(x)
        const localY = Number(y)
        if (!sourceItem || folderId.length === 0
                || !Number.isFinite(localX) || !Number.isFinite(localY)) {
            return
        }
        closeApplicationContextMenu(false)
        const context = {
            kind: "folder",
            appName: String(folder.folderLabel || ""),
            folderId: folderId
        }
        applicationContextMenuSurface.openAt(sourceItem, localX, localY,
            folderContextEntries(), context)
    }

    function contextEntry(actionId, text, iconName, enabled) {
        return {
            actionId: actionId,
            text: text,
            iconName: iconName,
            enabled: enabled !== false,
            separator: false
        }
    }

    function contextSeparator() {
        return {
            actionId: "",
            text: "",
            iconName: "",
            enabled: false,
            separator: true
        }
    }

    function standaloneApplicationContextEntries(context) {
        const layoutActionEnabled = root.applicationLayoutController
            && !root.applicationLayoutController.transactionPending
        return [
            contextEntry("createFolder",
                i18nc("@action:inmenu", "Create Folder…"),
                "folder-new", layoutActionEnabled),
            contextEntry("moveToFolder",
                i18nc("@action:inmenu", "Move to Folder…"),
                "folder-move", layoutActionEnabled
                    && applicationLayoutModel.folderChoiceCount > 0),
            contextSeparator(),
            contextEntry("toggleFavorite", context.isFavorite
                    ? i18nc("@action:inmenu", "Remove from Favorites")
                    : i18nc("@action:inmenu", "Add to Favorites"),
                context.isFavorite ? "favorite-favorited" : "favorite",
                context.isFavorite || !root.favoriteLimitReached),
            contextEntry("toggleDockPin", context.isPinnedToDock
                    ? i18nc("@action:inmenu", "Remove from Dock")
                    : i18nc("@action:inmenu", "Pin to Dock"),
                context.isPinnedToDock ? "window-unpin" : "window-pin", true),
            contextEntry("addToDesktop",
                i18nc("@action:inmenu", "Add to Desktop"),
                "user-desktop", true),
            contextSeparator(),
            contextEntry("toggleHidden", context.isHidden
                    ? i18nc("@action:inmenu", "Show in listing")
                    : i18nc("@action:inmenu", "Hide from listing"),
                context.isHidden ? "view-visible" : "view-hidden",
                context.storageId.length > 0)
        ]
    }

    function folderMemberContextEntries(context) {
        const layoutActionEnabled = root.applicationLayoutController
            && !root.applicationLayoutController.transactionPending
        return [
            contextEntry("removeFromFolder",
                i18nc("@action:inmenu", "Remove from Folder…"),
                "list-remove", layoutActionEnabled),
            contextSeparator(),
            contextEntry("toggleFavorite", context.isFavorite
                    ? i18nc("@action:inmenu", "Remove from Favorites")
                    : i18nc("@action:inmenu", "Add to Favorites"),
                context.isFavorite ? "favorite-favorited" : "favorite",
                context.isFavorite || !root.favoriteLimitReached),
            contextEntry("toggleDockPin", context.isPinnedToDock
                    ? i18nc("@action:inmenu", "Remove from Dock")
                    : i18nc("@action:inmenu", "Pin to Dock"),
                context.isPinnedToDock ? "window-unpin" : "window-pin", true),
            contextEntry("addToDesktop",
                i18nc("@action:inmenu", "Add to Desktop"),
                "user-desktop", true),
            contextSeparator(),
            contextEntry("toggleHidden", context.isHidden
                    ? i18nc("@action:inmenu", "Show in listing")
                    : i18nc("@action:inmenu", "Hide from listing"),
                context.isHidden ? "view-visible" : "view-hidden",
                context.storageId.length > 0)
        ]
    }

    function folderContextEntries() {
        const layoutActionEnabled = root.applicationLayoutController
            && !root.applicationLayoutController.transactionPending
        return [
            contextEntry("renameFolder",
                i18nc("@action:inmenu", "Rename Folder…"),
                "edit-rename", layoutActionEnabled),
            contextSeparator(),
            contextEntry("dissolveFolder",
                i18nc("@action:inmenu", "Dissolve Folder…"),
                "edit-delete", layoutActionEnabled)
        ]
    }

    function closeApplicationContextMenu(restoreFocus) {
        applicationContextMenuSurface.close(restoreFocus !== false)
    }

    function activateContextMenuAction(actionId) {
        const contextMenu = applicationContextMenuSurface
        const application = contextMenu.targetApplication()
        const containingFolderId = contextMenu.targetContainingFolderId
        const targetFolderId = contextMenu.targetFolderId

        if (actionId === "createFolder") {
            closeApplicationContextMenu(false)
            Qt.callLater(function() {
                root.beginCreateFolder(application)
            })
        } else if (actionId === "moveToFolder") {
            closeApplicationContextMenu(false)
            Qt.callLater(function() {
                root.beginMoveToFolder(application)
            })
        } else if (actionId === "removeFromFolder") {
            closeApplicationContextMenu(false)
            Qt.callLater(function() {
                root.beginRemoveFromFolder(application, containingFolderId)
            })
        } else if (actionId === "renameFolder") {
            closeApplicationContextMenu(false)
            Qt.callLater(function() {
                root.beginRenameFolder(targetFolderId)
            })
        } else if (actionId === "dissolveFolder") {
            closeApplicationContextMenu(false)
            Qt.callLater(function() {
                root.beginDissolveFolder(targetFolderId)
            })
        } else if (actionId === "toggleFavorite") {
            closeApplicationContextMenu(true)
            toggleContextFavorite(contextMenu)
        } else if (actionId === "toggleDockPin") {
            closeApplicationContextMenu(true)
            toggleContextDockPin(contextMenu)
        } else if (actionId === "addToDesktop") {
            closeApplicationContextMenu(true)
            addContextApplicationToDesktop(contextMenu)
        } else if (actionId === "toggleHidden") {
            closeApplicationContextMenu(false)
            toggleContextApplicationHidden(contextMenu)
            if (folderSurface.active) {
                Qt.callLater(folderSurface.restoreFocus)
            }
        }
    }

    function beginCreateFolder(application) {
        folderSurface.beginCreate(application)
    }

    function beginMoveToFolder(application) {
        folderSurface.beginMove(application)
    }

    function beginRemoveFromFolder(application, folderId) {
        folderSurface.beginRemove(application, folderId)
    }

    function beginRenameFolder(folderId) {
        folderSurface.beginRename(folderId)
    }

    function beginDissolveFolder(folderId) {
        folderSurface.beginDissolve(folderId)
    }

    function toggleContextFavorite(contextMenu) {
        const storageId = contextMenu.targetStorageId
            || contextMenu.targetAppCommand
        if (contextMenu.targetIsFavorite) {
            const removingLastFavorite = root.favorites.length === 1
            root.removeFavoriteRequested(storageId)
            if (removingLastFavorite) {
                Qt.callLater(root.focusApplicationsGrid)
            }
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
        root.preferredApplicationIndexAfterRefresh =
            applicationsGrid.currentIndex
        root.setApplicationHiddenRequested(
            contextMenu.targetStorageId,
            !contextMenu.targetIsHidden)
    }

    function openCurrentApplicationContextMenu() {
        const currentItem = applicationsGrid.currentItem
        const index = applicationsGrid.currentIndex
        if (!currentItem || index < 0 || index >= applicationListingCount) {
            return
        }
        const application = applicationNodeAt(index)
        if (!application) {
            return
        }
        if (String(application.nodeType || "") === "folder") {
            openFolderContextMenu(currentItem, application,
                currentItem.width / 2, currentItem.height / 2)
            return
        }
        openApplicationContextMenu(currentItem,
            String(application.appStorageId || ""),
            String(application.appName || ""),
            String(application.appIcon || ""),
            String(application.appCommand || ""),
            currentItem.width / 2, currentItem.height / 2)
    }

    function openCurrentFavoriteContextMenu() {
        const currentItem = favoritesView.currentItem
        const index = favoritesView.currentIndex
        if (!currentItem || index < 0 || index >= favorites.length) {
            return
        }
        const fav = favorites[index]
        openApplicationContextMenu(currentItem,
            String(fav.appStorageId || ""),
            String(fav.appName || ""),
            String(fav.appIcon || ""),
            String(fav.appCommand || ""),
            currentItem.width / 2, currentItem.height / 2)
    }

    function appendApplication(model, application) {
        if (!application) {
            return
        }
        const name = String(application.name || "").trim()
        const storageId = String(application.storageId || "").trim()
        const command = String(application.command || "").trim()
        if (name.length === 0 || (storageId.length === 0 && command.length === 0)) {
            return
        }
        model.append({
            appName: name.substring(0, 256),
            appIcon: String(application.icon || "application-x-executable").substring(0, 512),
            appStorageId: storageId.substring(0, 512),
            appCommand: command.substring(0, 2048),
            appHidden: isApplicationHidden(storageId)
        })
    }

    function filterAllApplications() {
        if (!menuOpen) {
            return
        }
        const query = searchField.text.trim().toLocaleLowerCase()
        if (query.length === 0) {
            selectCategory(activeCategoryKey, activeCategoryTitle, false)
            return
        }

        visibleApplicationsModel.clear()
        for (let index = 0; index < allApplicationsModel.count; index++) {
            const application = allApplicationsModel.get(index)
            const storageId = String(application.appStorageId || "")
            if (applicationShouldBeVisible(storageId)
                    && String(application.appName || "").toLocaleLowerCase()
                        .indexOf(query) >= 0) {
                visibleApplicationsModel.append({
                    appName: String(application.appName || ""),
                    appIcon: String(application.appIcon
                        || "application-x-executable"),
                    appStorageId: storageId,
                    appCommand: String(application.appCommand || ""),
                    appHidden: isApplicationHidden(storageId)
                })
            }
        }
        applicationsLoading = allApplicationsModel.count === 0 && pendingCategoryKey === "__all__"
        restorePreferredApplicationIndex()
    }

    function requestAllApplications() {
        allApplicationsModel.clear()
        pendingCategoryKey = "__all__"
        systemDiscovery.requestApplications("")
    }

    function selectCategory(categoryKey, title, clearSearch) {
        if (clearSearch && searchField.text.length > 0) {
            suppressSearchChange = true
            searchField.clear()
            suppressSearchChange = false
        }
        activeCategoryKey = String(categoryKey)
        activeCategoryTitle = String(title)
        applicationErrorMessage = ""
        applicationLaunchPending = false

        applicationsLoading = true
        visibleApplicationsModel.clear()
        pendingCategoryKey = activeCategoryKey
        systemDiscovery.requestApplications(activeCategoryKey)
    }

    function launchApplication(storageId, command) {
        if (applicationLaunchPending) {
            return
        }
        applicationErrorMessage = ""
        if (storageId.length > 0) {
            applicationLaunchPending = true
            systemDiscovery.launchApplication(storageId)
            return
        }
        if (command.length > 0 && systemDiscovery.launchApplicationByCommand(command)) {
            forceClose()
            return
        }
        applicationErrorMessage = i18nc("@info:status", "This application could not be resolved safely.")
    }

    function launchCurrentApplication() {
        const index = applicationsGrid.currentIndex
        if (index < 0 || index >= applicationListingCount) {
            return
        }
        const application = applicationNodeAt(index)
        if (!application) {
            return
        }
        if (String(application.nodeType || "") === "folder") {
            folderSurface.openFolder(String(application.folderId || ""))
            return
        }
        launchApplication(String(application.appStorageId || ""),
            String(application.appCommand || ""))
    }

    function launchCurrentFavorite() {
        const index = favoritesView.currentIndex
        if (index < 0 || index >= favorites.length) {
            return
        }
        const favorite = favorites[index]
        launchApplication(String(favorite.appStorageId || ""), "")
    }

    function openMenu() {
        closeTimer.stop()
        operationMessageTimer.stop()
        folderSurface.reset()
        revealHiddenApplications = false
        menuOpen = true
        applicationErrorMessage = ""
        operationMessage = ""
        applicationLaunchPending = false
        activeCategoryKey = "All"
        activeCategoryTitle = i18nc("@title:category", "All Applications")
        categoriesView.currentIndex = categoryIndexForKey(activeCategoryKey)
        categoriesView.positionViewAtBeginning()
        suppressSearchChange = true
        searchField.clear()
        suppressSearchChange = false
        requestAllApplications()
        searchField.forceActiveFocus()
    }

    function forceClose() {
        closeApplicationContextMenu(false)
        folderSurface.reset()
        if (applicationLayoutController) {
            applicationLayoutController.discardUndoHistory()
        }
        closeTimer.stop()
        operationMessageTimer.stop()
        menuOpen = false
        revealHiddenApplications = false
        applicationLaunchPending = false
        closeTimer.restart()
    }

    function resetMenu() {
        closeApplicationContextMenu(false)
        folderSurface.reset()
        if (applicationLayoutController) {
            applicationLayoutController.discardUndoHistory()
        }
        closeTimer.stop()
        operationMessageTimer.stop()
        menuOpen = false
        revealHiddenApplications = false
        applicationsLoading = false
        applicationLaunchPending = false
        applicationErrorMessage = ""
        operationMessage = ""
        pendingCategoryKey = ""
        suppressSearchChange = true
        searchField.clear()
        suppressSearchChange = false
        visibleApplicationsModel.clear()
        allApplicationsModel.clear()
        preferredApplicationIndexAfterRefresh = -1
    }

    Keys.onEscapePressed: function(event) {
        if (applicationContextMenuSurface.active) {
            closeApplicationContextMenu(true)
        } else if (folderSurface.active) {
            folderSurface.closeCurrentView()
        } else {
            root.forceClose()
        }
        event.accepted = true
    }

    onHiddenApplicationIdsChanged: {
        if (menuOpen) {
            preferredApplicationIndexAfterRefresh = applicationsGrid.currentIndex
            refreshApplicationListing()
        }
    }

    onRevealHiddenApplicationsChanged: {
        if (menuOpen) {
            preferredApplicationIndexAfterRefresh = applicationsGrid.currentIndex
            refreshApplicationListing()
        }
    }

    Timer {
        id: closeTimer
        interval: root.closeDuration
        repeat: false
        onTriggered: root.closeFinished()
    }

    Timer {
        id: operationMessageTimer
        interval: root.operationMessageDuration
        repeat: false
        onTriggered: root.dismissOperationMessage()
    }

    ListModel {
        id: categoryModel
    }

    Component.onCompleted: {
        categoryModel.append({ categoryKey: "All", titleName: i18nc("@title:category", "All Applications") })
        categoryModel.append({ categoryKey: "Network", titleName: i18nc("@title:category", "Internet") })
        categoryModel.append({ categoryKey: "Graphics", titleName: i18nc("@title:category", "Graphics") })
        categoryModel.append({ categoryKey: "AudioVideo", titleName: i18nc("@title:category", "Multimedia") })
        categoryModel.append({ categoryKey: "Office", titleName: i18nc("@title:category", "Office") })
        categoryModel.append({ categoryKey: "Development", titleName: i18nc("@title:category", "Development") })
        categoryModel.append({ categoryKey: "System", titleName: i18nc("@title:category", "System") })
        categoryModel.append({ categoryKey: "Utility", titleName: i18nc("@title:category", "Utilities") })
        categoryModel.append({ categoryKey: "Game", titleName: i18nc("@title:category", "Games") })
        categoryModel.append({ categoryKey: "Education", titleName: i18nc("@title:category", "Education") })
    }

    ListModel { id: allApplicationsModel }
    ListModel { id: visibleApplicationsModel }

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
            root.updateOperationMessageTimer()
        }

        function onTransactionFailed(transactionId, operation, errorCode) {
            root.operationMessage = i18nc("@info:status",
                "The application folder could not be updated.")
            root.operationMessageIsError = true
            root.updateOperationMessageTimer()
        }
    }

    Punchi.SessionActionsController {
        id: sessionActions
    }

    Connections {
        target: root.systemDiscovery
        ignoreUnknownSignals: true

        function onApplicationsReady(applications) {
            const list = applications || []
            if (root.pendingCategoryKey === "__all__") {
                allApplicationsModel.clear()
                visibleApplicationsModel.clear()
                for (let index = 0; index < list.length; index++) {
                    const application = list[index]
                    root.appendApplication(allApplicationsModel, application)
                    if (searchField.text.length === 0 && application
                            && root.applicationShouldBeVisible(
                                String(application.storageId || ""))) {
                        root.appendApplication(visibleApplicationsModel, application)
                    }
                }
                root.pendingCategoryKey = ""
                root.applicationsLoading = false
                if (searchField.text.length > 0) {
                    root.filterAllApplications()
                } else {
                    root.restorePreferredApplicationIndex()
                }
                return
            }

            visibleApplicationsModel.clear()
            for (let index = 0; index < list.length; index++) {
                const application = list[index]
                if (application && root.applicationShouldBeVisible(
                        String(application.storageId || ""))) {
                    root.appendApplication(visibleApplicationsModel, application)
                }
            }
            root.pendingCategoryKey = ""
            root.applicationsLoading = false
            root.restorePreferredApplicationIndex()
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
                root.updateOperationMessageTimer()
            }
        }
    }

    Item {
        id: surface
        anchors.fill: parent
        opacity: root.menuOpen ? 1.0 : 0.0
        transform: Translate {
            y: root.menuOpen ? 0 : Kirigami.Units.gridUnit * 0.65

            Behavior on y {
                enabled: root.motionEnabled
                NumberAnimation {
                    duration: root.menuOpen ? root.openDuration : root.closeDuration
                    easing.type: root.menuOpen ? Easing.OutCubic : Easing.InQuad
                }
            }
        }

        Behavior on opacity {
            enabled: root.motionEnabled
            NumberAnimation {
                duration: root.menuOpen ? root.openDuration : root.closeDuration
                easing.type: root.menuOpen ? Easing.OutCubic : Easing.InQuad
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: -root.themeFrameOverlapLeft
            anchors.topMargin: -root.themeFrameOverlapTop
            anchors.rightMargin: -root.themeFrameOverlapRight
            anchors.bottomMargin: -root.themeFrameOverlapBottom
            radius: Kirigami.Units.cornerRadius * 2
                + root.maximumThemeFrameOverlap
            color: Kirigami.Theme.backgroundColor
            opacity: root.safeBackgroundOpacity
            Accessible.ignored: true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.mediumSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.mediumSpacing

                PlasmaCore.ToolTipArea {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: width
                    mainText: KCoreAddons.KOSRelease.prettyName

                    Kirigami.Icon {
                        anchors.fill: parent
                        source: KCoreAddons.KOSRelease.logo.length > 0
                            ? KCoreAddons.KOSRelease.logo
                            : "start-here-kde"
                        Accessible.role: Accessible.Graphic
                        Accessible.name: KCoreAddons.KOSRelease.prettyName
                    }
                }

                Kirigami.SearchField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: i18nc("@placeholder", "Search applications…")
                    Accessible.name: i18nc("@label", "Search applications")
                    background: PunchiMenuSearchBackground {
                        fieldActiveFocus: searchField.activeFocus
                        fieldHovered: searchField.hovered
                    }
                    KeyNavigation.tab: hiddenApplicationsButton.visible
                        ? hiddenApplicationsButton
                        : (btnLogOut.enabled ? btnLogOut
                            : (btnReboot.enabled ? btnReboot
                                : (btnShutdown.enabled ? btnShutdown : btnClose)))
                    onTextChanged: {
                        if (!root.suppressSearchChange) {
                            root.filterAllApplications()
                        }
                    }
                    Keys.onDownPressed: function(event) {
                        if (root.applicationListingCount > 0) {
                            root.focusApplicationsGrid()
                            event.accepted = true
                        }
                    }
                }

                PlasmaComponents.ToolButton {
                    id: hiddenApplicationsButton
                    readonly property bool highlightedContent: enabled
                        && (hiddenApplicationsHover.hovered || hovered || down
                            || activeFocus || checked)
                    Layout.preferredWidth: root.headerControlSize
                    Layout.minimumWidth: Layout.preferredWidth
                    Layout.maximumWidth: Layout.preferredWidth
                    Layout.preferredHeight: root.headerControlSize
                    Layout.minimumHeight: Layout.preferredHeight
                    Layout.maximumHeight: Layout.preferredHeight
                    visible: root.hiddenApplicationCount > 0
                    enabled: root.menuOpen && !root.applicationLaunchPending
                    icon.name: root.revealHiddenApplications
                        ? "view-visible-symbolic"
                        : "view-hidden-symbolic"
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
                    KeyNavigation.backtab: searchField
                    KeyNavigation.tab: btnLogOut.enabled ? btnLogOut
                        : (btnReboot.enabled ? btnReboot
                            : (btnShutdown.enabled ? btnShutdown : btnClose))
                    KeyNavigation.right: btnLogOut.enabled ? btnLogOut
                        : (btnReboot.enabled ? btnReboot
                            : (btnShutdown.enabled ? btnShutdown : btnClose))
                    KeyNavigation.down: categoriesView

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

                    onActiveFocusChanged: {
                        if (activeFocus) {
                            hiddenApplicationsToolTip.showToolTip()
                        } else if (!hiddenApplicationsToolTip.containsMouse) {
                            hiddenApplicationsToolTip.hideImmediately()
                        }
                    }
                    onClicked: root.revealHiddenApplications
                        = !root.revealHiddenApplications

                    HoverHandler {
                        id: hiddenApplicationsHover
                        enabled: hiddenApplicationsButton.enabled
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                PlasmaComponents.ToolButton {
                    id: btnLogOut
                    readonly property bool highlightedContent: enabled
                        && (logOutHover.hovered || hovered || down
                            || activeFocus)
                    Layout.preferredWidth: root.headerControlSize
                    Layout.minimumWidth: Layout.preferredWidth
                    Layout.maximumWidth: Layout.preferredWidth
                    Layout.preferredHeight: root.headerControlSize
                    Layout.minimumHeight: Layout.preferredHeight
                    Layout.maximumHeight: Layout.preferredHeight
                    icon.name: "system-log-out"
                    icon.color: highlightedContent
                        ? root.Kirigami.Theme.highlightedTextColor
                        : root.Kirigami.Theme.textColor
                    display: PlasmaComponents.AbstractButton.IconOnly
                    text: i18nc("@action:button", "Log Out")
                    Accessible.name: text
                    enabled: sessionActions.canLogout
                    KeyNavigation.backtab: hiddenApplicationsButton.visible
                        ? hiddenApplicationsButton : searchField
                    KeyNavigation.tab: categoriesView
                    KeyNavigation.right: btnReboot.enabled ? btnReboot : (btnShutdown.enabled ? btnShutdown : btnClose)
                    KeyNavigation.down: categoriesView

                    background: PunchiMenuActionBackground {
                        highlighted: btnLogOut.highlightedContent
                        circular: true
                    }

                    PlasmaCore.ToolTipArea {
                        id: logOutToolTip
                        anchors.fill: parent
                        active: btnLogOut.enabled
                        mainText: btnLogOut.text
                    }

                    onActiveFocusChanged: {
                        if (activeFocus) {
                            logOutToolTip.showToolTip()
                        } else if (!logOutToolTip.containsMouse) {
                            logOutToolTip.hideImmediately()
                        }
                    }
                    onClicked: {
                        root.forceClose()
                        sessionActions.requestLogout()
                    }

                    HoverHandler {
                        id: logOutHover
                        enabled: btnLogOut.enabled
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                PlasmaComponents.ToolButton {
                    id: btnReboot
                    readonly property bool highlightedContent: enabled
                        && (rebootHover.hovered || hovered || down
                            || activeFocus)
                    Layout.preferredWidth: root.headerControlSize
                    Layout.minimumWidth: Layout.preferredWidth
                    Layout.maximumWidth: Layout.preferredWidth
                    Layout.preferredHeight: root.headerControlSize
                    Layout.minimumHeight: Layout.preferredHeight
                    Layout.maximumHeight: Layout.preferredHeight
                    icon.name: "system-reboot"
                    icon.color: highlightedContent
                        ? root.Kirigami.Theme.highlightedTextColor
                        : root.Kirigami.Theme.textColor
                    display: PlasmaComponents.AbstractButton.IconOnly
                    text: i18nc("@action:button", "Restart")
                    Accessible.name: text
                    enabled: sessionActions.canReboot
                    KeyNavigation.backtab: searchField
                    KeyNavigation.tab: categoriesView
                    KeyNavigation.left: btnLogOut.enabled ? btnLogOut : null
                    KeyNavigation.right: btnShutdown.enabled ? btnShutdown : btnClose
                    KeyNavigation.down: categoriesView

                    background: PunchiMenuActionBackground {
                        highlighted: btnReboot.highlightedContent
                        circular: true
                    }

                    PlasmaCore.ToolTipArea {
                        id: rebootToolTip
                        anchors.fill: parent
                        active: btnReboot.enabled
                        mainText: btnReboot.text
                    }

                    onActiveFocusChanged: {
                        if (activeFocus) {
                            rebootToolTip.showToolTip()
                        } else if (!rebootToolTip.containsMouse) {
                            rebootToolTip.hideImmediately()
                        }
                    }
                    onClicked: {
                        root.forceClose()
                        sessionActions.requestReboot()
                    }

                    HoverHandler {
                        id: rebootHover
                        enabled: btnReboot.enabled
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                PlasmaComponents.ToolButton {
                    id: btnShutdown
                    readonly property bool highlightedContent: enabled
                        && (shutdownHover.hovered || hovered || down
                            || activeFocus)
                    Layout.preferredWidth: root.headerControlSize
                    Layout.minimumWidth: Layout.preferredWidth
                    Layout.maximumWidth: Layout.preferredWidth
                    Layout.preferredHeight: root.headerControlSize
                    Layout.minimumHeight: Layout.preferredHeight
                    Layout.maximumHeight: Layout.preferredHeight
                    icon.name: "system-shutdown"
                    icon.color: highlightedContent
                        ? root.Kirigami.Theme.highlightedTextColor
                        : root.Kirigami.Theme.textColor
                    display: PlasmaComponents.AbstractButton.IconOnly
                    text: i18nc("@action:button", "Shut Down")
                    Accessible.name: text
                    enabled: sessionActions.canShutdown
                    KeyNavigation.backtab: searchField
                    KeyNavigation.tab: categoriesView
                    KeyNavigation.left: btnReboot.enabled ? btnReboot : (btnLogOut.enabled ? btnLogOut : null)
                    KeyNavigation.right: btnClose
                    KeyNavigation.down: categoriesView

                    background: PunchiMenuActionBackground {
                        highlighted: btnShutdown.highlightedContent
                        circular: true
                    }

                    PlasmaCore.ToolTipArea {
                        id: shutdownToolTip
                        anchors.fill: parent
                        active: btnShutdown.enabled
                        mainText: btnShutdown.text
                    }

                    onActiveFocusChanged: {
                        if (activeFocus) {
                            shutdownToolTip.showToolTip()
                        } else if (!shutdownToolTip.containsMouse) {
                            shutdownToolTip.hideImmediately()
                        }
                    }
                    onClicked: {
                        root.forceClose()
                        sessionActions.requestShutdown()
                    }

                    HoverHandler {
                        id: shutdownHover
                        enabled: btnShutdown.enabled
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                PlasmaComponents.ToolButton {
                    id: btnClose
                    readonly property bool highlightedContent: enabled
                        && (closeHover.hovered || hovered || down
                            || activeFocus)
                    Layout.preferredWidth: root.headerControlSize
                    Layout.minimumWidth: Layout.preferredWidth
                    Layout.maximumWidth: Layout.preferredWidth
                    Layout.preferredHeight: root.headerControlSize
                    Layout.minimumHeight: Layout.preferredHeight
                    Layout.maximumHeight: Layout.preferredHeight
                    icon.name: "window-close"
                    icon.color: highlightedContent
                        ? root.Kirigami.Theme.highlightedTextColor
                        : root.Kirigami.Theme.textColor
                    display: PlasmaComponents.AbstractButton.IconOnly
                    text: i18nc("@action:button", "Close")
                    Accessible.name: text
                    KeyNavigation.backtab: searchField
                    KeyNavigation.tab: categoriesView
                    KeyNavigation.left: btnShutdown.enabled ? btnShutdown : (btnReboot.enabled ? btnReboot : (btnLogOut.enabled ? btnLogOut : null))
                    KeyNavigation.down: categoriesView

                    background: PunchiMenuActionBackground {
                        highlighted: btnClose.highlightedContent
                        circular: true
                    }

                    PlasmaCore.ToolTipArea {
                        id: closeToolTip
                        anchors.fill: parent
                        mainText: btnClose.text
                    }

                    onActiveFocusChanged: {
                        if (activeFocus) {
                            closeToolTip.showToolTip()
                        } else if (!closeToolTip.containsMouse) {
                            closeToolTip.hideImmediately()
                        }
                    }
                    onClicked: root.forceClose()

                    HoverHandler {
                        id: closeHover
                        enabled: btnClose.enabled
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.65

                RowLayout {
                    anchors.fill: parent
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents.ToolButton {
                        id: categoryLeftEdge
                        readonly property bool canScroll:
                            categoriesView.contentWidth > categoriesView.width
                            && !categoriesView.atXBeginning
                        property bool autoScrollSuppressed: false
                        readonly property bool highlightedContent: enabled
                            && (categoryLeftHover.hovered || hovered || down)

                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2.1
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2.1
                        Layout.alignment: Qt.AlignVCenter
                        icon.name: "go-previous-symbolic"
                        icon.color: highlightedContent
                            ? root.Kirigami.Theme.highlightedTextColor
                            : root.Kirigami.Theme.textColor
                        display: PlasmaComponents.AbstractButton.IconOnly
                        text: i18nc("@action:button", "Scroll categories left")
                        Accessible.name: text
                        activeFocusOnTab: false
                        enabled: canScroll
                        opacity: canScroll ? (hovered ? 0.90 : 0.55) : 0.0
                        onHoveredChanged: {
                            if (!hovered) {
                                autoScrollSuppressed = false
                            }
                            root.updateCategoryEdgeScroll()
                        }
                        onClicked: {
                            autoScrollSuppressed = true
                            root.scrollCategoriesBy(-Kirigami.Units.gridUnit * 8.4)
                        }

                        Behavior on opacity {
                            enabled: root.motionEnabled
                            NumberAnimation { duration: Kirigami.Units.shortDuration }
                        }

                        HoverHandler {
                            id: categoryLeftHover
                            enabled: categoryLeftEdge.enabled
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    ListView {
                        id: categoriesView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        orientation: ListView.Horizontal
                        spacing: Kirigami.Units.smallSpacing
                        clip: true
                        model: categoryModel
                        boundsBehavior: Flickable.StopAtBounds
                        keyNavigationWraps: false
                        activeFocusOnTab: true
                        KeyNavigation.tab: applicationsGrid
                        KeyNavigation.backtab: btnClose

                        Kirigami.WheelHandler {
                            id: categoriesWheelHandler
                            target: categoriesView
                            scrollFlickableTarget: false
                            blockTargetWheel: true
                            onWheel: function(wheel) {
                                root.handleHorizontalWheel(wheel,
                                    categoriesView,
                                    categoryScrollAnimation,
                                    Kirigami.Units.gridUnit * 4.2,
                                    Kirigami.Units.gridUnit * 34)
                            }
                        }

                        onDraggingChanged: {
                            if (dragging) {
                                categoryScrollAnimation.stop()
                            }
                        }

                        onFlickingChanged: {
                            if (flicking) {
                                categoryScrollAnimation.stop()
                            }
                        }

                        onActiveFocusChanged: {
                            if (activeFocus && currentIndex < 0) {
                                currentIndex = root.categoryIndexForKey(root.activeCategoryKey)
                            }
                            if (activeFocus && currentIndex >= 0) {
                                positionViewAtIndex(currentIndex, ListView.Contain)
                            }
                        }

                        onCurrentIndexChanged: {
                            if (activeFocus && currentIndex >= 0) {
                                positionViewAtIndex(currentIndex, ListView.Contain)
                            }
                        }

                        Keys.onDownPressed: function(event) {
                            if (root.applicationListingCount > 0) {
                                root.focusApplicationsGrid()
                                event.accepted = true
                            }
                        }

                        Keys.onReturnPressed: function(event) {
                            if (currentIndex >= 0 && currentIndex < categoryModel.count) {
                                const category = categoryModel.get(currentIndex)
                                root.selectCategory(category.categoryKey, category.titleName, true)
                                event.accepted = true
                            }
                        }

                        Keys.onEnterPressed: function(event) {
                            if (currentIndex >= 0 && currentIndex < categoryModel.count) {
                                const category = categoryModel.get(currentIndex)
                                root.selectCategory(category.categoryKey, category.titleName, true)
                                event.accepted = true
                            }
                        }

                        Keys.onSpacePressed: function(event) {
                            if (currentIndex >= 0 && currentIndex < categoryModel.count) {
                                const category = categoryModel.get(currentIndex)
                                root.selectCategory(category.categoryKey, category.titleName, true)
                                event.accepted = true
                            }
                        }

                        delegate: PunchiMenuCategoryPill {
                            checked: root.activeCategoryKey === categoryKey
                            keyboardFocused: categoriesView.activeFocus
                                && categoriesView.currentIndex === index
                            motionEnabled: root.motionEnabled
                            onClicked: {
                                categoriesView.currentIndex = index
                                root.selectCategory(categoryKey, titleName, true)
                            }
                        }
                    }

                    PlasmaComponents.ToolButton {
                        id: categoryRightEdge
                        readonly property bool canScroll:
                            categoriesView.contentWidth > categoriesView.width
                            && !categoriesView.atXEnd
                        property bool autoScrollSuppressed: false
                        readonly property bool highlightedContent: enabled
                            && (categoryRightHover.hovered || hovered || down)

                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2.1
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2.1
                        Layout.alignment: Qt.AlignVCenter
                        icon.name: "go-next-symbolic"
                        icon.color: highlightedContent
                            ? root.Kirigami.Theme.highlightedTextColor
                            : root.Kirigami.Theme.textColor
                        display: PlasmaComponents.AbstractButton.IconOnly
                        text: i18nc("@action:button", "Scroll categories right")
                        Accessible.name: text
                        activeFocusOnTab: false
                        enabled: canScroll
                        opacity: canScroll ? (hovered ? 0.90 : 0.55) : 0.0
                        onHoveredChanged: {
                            if (!hovered) {
                                autoScrollSuppressed = false
                            }
                            root.updateCategoryEdgeScroll()
                        }
                        onClicked: {
                            autoScrollSuppressed = true
                            root.scrollCategoriesBy(Kirigami.Units.gridUnit * 8.4)
                        }

                        Behavior on opacity {
                            enabled: root.motionEnabled
                            NumberAnimation { duration: Kirigami.Units.shortDuration }
                        }

                        HoverHandler {
                            id: categoryRightHover
                            enabled: categoryRightEdge.enabled
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }

                SmoothedAnimation {
                    id: categoryScrollAnimation

                    property bool edgeDriven: false

                    target: categoriesView
                    property: "contentX"
                    maximumEasingTime: 120
                    onFinished: root.updateCategoryEdgeScroll()
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                GridView {
                    id: applicationsGrid
                    readonly property bool verticalScrollRequired:
                        contentHeight > height + 0.5
                    readonly property real verticalScrollBarReserve:
                        verticalScrollRequired
                            ? Math.max(1,
                                applicationsScrollBar.implicitWidth)
                                + Kirigami.Units.smallSpacing
                            : 0
                    anchors.fill: parent
                    model: root.applicationListingCount
                    cellWidth: Math.max(1,
                        (width - verticalScrollBarReserve) / root.columnCount)
                    cellHeight: Math.max(Kirigami.Units.gridUnit * 7.5,
                        Kirigami.Units.iconSizes.large * root.safeApplicationIconScale
                            + Kirigami.Units.gridUnit * 3)
                    clip: true
                    focus: true
                    activeFocusOnTab: true
                    enabled: !root.applicationLaunchPending
                    keyNavigationWraps: false
                    KeyNavigation.backtab: categoriesView

                    onActiveFocusChanged: {
                        if (activeFocus && root.applicationListingCount > 0) {
                            if (currentIndex < 0
                                    || currentIndex >= root.applicationListingCount) {
                                currentIndex = 0
                            }
                            positionViewAtIndex(currentIndex, GridView.Contain)
                        }
                    }

                    PlasmaComponents.ScrollBar.vertical: PlasmaComponents.ScrollBar {
                        id: applicationsScrollBar
                        policy: applicationsGrid.verticalScrollRequired
                            ? PlasmaComponents.ScrollBar.AlwaysOn
                            : PlasmaComponents.ScrollBar.AlwaysOff
                    }

                    Keys.onReturnPressed: function(event) {
                        root.launchCurrentApplication()
                        event.accepted = true
                    }
                    Keys.onEnterPressed: function(event) {
                        root.launchCurrentApplication()
                        event.accepted = true
                    }
                    Keys.onSpacePressed: function(event) {
                        root.launchCurrentApplication()
                        event.accepted = true
                    }
                    Keys.onUpPressed: function(event) {
                        if (currentIndex >= 0 && currentIndex < root.columnCount) {
                            root.focusActiveCategory()
                            event.accepted = true
                        } else {
                            event.accepted = false
                        }
                    }
                    Keys.onDownPressed: function(event) {
                        if (root.favoritesSectionVisible
                                && currentIndex >= 0
                                && currentIndex + root.columnCount
                                    >= root.applicationListingCount) {
                            root.focusFavorites()
                            event.accepted = true
                        } else {
                            event.accepted = false
                        }
                    }
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Menu
                                || (event.key === Qt.Key_F10
                                    && (event.modifiers & Qt.ShiftModifier))) {
                            root.openCurrentApplicationContextMenu()
                            event.accepted = true
                        }
                    }

                    delegate: Item {
                        id: applicationDelegate
                        required property int index

                        readonly property var nodeData:
                            root.applicationNodeAt(index)
                        readonly property string nodeType: String(nodeData
                            ? nodeData.nodeType || "application" : "application")
                        readonly property bool isFolder: nodeType === "folder"
                        readonly property string nodeId: String(nodeData
                            ? nodeData.nodeId || "" : "")
                        readonly property string appName: String(nodeData
                            ? nodeData.appName || "" : "")
                        readonly property string appIcon: String(nodeData
                            ? nodeData.appIcon || "application-x-executable"
                            : "application-x-executable")
                        readonly property string appStorageId: String(nodeData
                            ? nodeData.appStorageId || "" : "")
                        readonly property string appCommand:
                            root.organizedListingActive ? "" : String(nodeData
                                ? nodeData.appCommand || "" : "")
                        readonly property bool appHidden: Boolean(nodeData
                            && nodeData.appHidden)

                        width: applicationsGrid.cellWidth
                        height: applicationsGrid.cellHeight
                        readonly property bool keyboardFocused:
                            applicationsGrid.activeFocus
                            && applicationsGrid.currentIndex === index
                        readonly property bool selected: keyboardFocused
                            || applicationMouseArea.containsMouse
                        readonly property bool isHiddenApplication: appHidden
                        readonly property real iconSize: Math.max(
                            Kirigami.Units.iconSizes.medium,
                            Math.min(Kirigami.Units.iconSizes.huge * root.safeApplicationIconScale,
                                width * 0.58, height * 0.55))
                        Accessible.ignored: isFolder
                        Accessible.role: Accessible.Button
                        Accessible.name: isFolder
                            ? String(nodeData.folderLabel || "") : appName
                        Accessible.description: !isFolder && isHiddenApplication
                            ? i18nc("@info:accessibility",
                                "Hidden from the application listing")
                            : ""
                        Accessible.focused: keyboardFocused
                        Accessible.onPressAction: launchApp()
                        opacity: isHiddenApplication ? 0.58 : 1.0

                        function launchApp() {
                            applicationsGrid.currentIndex = index
                            if (isFolder) {
                                folderSurface.openFolder(String(
                                    nodeData.folderId || ""))
                                return
                            }
                            root.launchApplication(appStorageId, appCommand)
                        }

                        PunchiMenuFolderTile {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            visible: applicationDelegate.isFolder
                            enabled: visible
                            activeFocusOnTab: false
                            folderId: String(applicationDelegate.nodeData
                                ? applicationDelegate.nodeData.folderId || "" : "")
                            folderLabel: String(applicationDelegate.nodeData
                                ? applicationDelegate.nodeData.folderLabel || "" : "")
                            previewIcons: applicationDelegate.nodeData
                                ? applicationDelegate.nodeData.folderPreviewIcons || [] : []
                            memberCount: Number(applicationDelegate.nodeData
                                ? applicationDelegate.nodeData.folderMemberCount || 0 : 0)
                            selected: applicationDelegate.selected
                            motionEnabled: root.motionEnabled
                            iconScale: root.safeApplicationIconScale
                            onActivated: applicationDelegate.launchApp()
                            onContextRequested: function(sourceItem, x, y) {
                                applicationsGrid.currentIndex
                                    = applicationDelegate.index
                                root.openFolderContextMenu(sourceItem,
                                    applicationDelegate.nodeData, x, y)
                            }
                            onRenameRequested: folderSurface.beginRename(
                                String(applicationDelegate.nodeData.folderId || ""))
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            visible: !applicationDelegate.isFolder
                            radius: Kirigami.Units.cornerRadius * 1.5
                            color: applicationDelegate.selected
                                ? Qt.alpha(Kirigami.Theme.highlightColor, 0.24)
                                : "transparent"
                            border.color: applicationDelegate.selected
                                ? Kirigami.Theme.highlightColor
                                : "transparent"
                            border.width: applicationDelegate.selected ? 2 : 0
                            scale: applicationMouseArea.pressed
                                ? 0.97
                                : applicationDelegate.selected ? 1.018 : 1.0

                            Behavior on scale {
                                enabled: root.motionEnabled
                                NumberAnimation {
                                    duration: applicationMouseArea.pressed ? 80 : 130
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on color {
                                enabled: root.motionEnabled
                                ColorAnimation {
                                    duration: Math.max(90,
                                        Math.min(150, Kirigami.Units.shortDuration))
                                }
                            }

                            Behavior on border.color {
                                enabled: root.motionEnabled
                                ColorAnimation {
                                    duration: Math.max(90,
                                        Math.min(150, Kirigami.Units.shortDuration))
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.smallSpacing
                                spacing: Kirigami.Units.smallSpacing

                                Kirigami.Icon {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: applicationDelegate.iconSize
                                    Layout.preferredHeight: width
                                    source: applicationDelegate.appIcon
                                }

                                PlasmaComponents.Label {
                                    id: applicationLabel
                                    Layout.fillWidth: true
                                    text: applicationDelegate.appName
                                    textFormat: Text.PlainText
                                    horizontalAlignment: Text.AlignHCenter
                                    maximumLineCount: 2
                                    wrapMode: Text.Wrap
                                    elide: Text.ElideRight
                                }
                            }

                            Kirigami.Icon {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: Kirigami.Units.smallSpacing
                                width: Kirigami.Units.iconSizes.small
                                height: width
                                source: "view-hidden-symbolic"
                                visible: applicationDelegate.isHiddenApplication
                                Accessible.ignored: true
                            }

                            PlasmaCore.ToolTipArea {
                                anchors.fill: parent
                                active: applicationLabel.truncated
                                mainText: applicationDelegate.appName

                                MouseArea {
                                    id: applicationMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: applicationsGrid.currentIndex
                                        = applicationDelegate.index
                                    onPressed: function(mouse) {
                                        if (mouse.button !== Qt.RightButton) {
                                            return
                                        }
                                        applicationsGrid.currentIndex =
                                            applicationDelegate.index
                                        root.openApplicationContextMenu(
                                            applicationMouseArea,
                                            applicationDelegate.appStorageId,
                                            applicationDelegate.appName,
                                            applicationDelegate.appIcon,
                                            applicationDelegate.appCommand,
                                            mouse.x, mouse.y)
                                    }
                                    onClicked: function(mouse) {
                                        if (mouse.button === Qt.LeftButton) {
                                            applicationsGrid.currentIndex =
                                                applicationDelegate.index
                                            applicationDelegate.launchApp()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - Kirigami.Units.largeSpacing * 2,
                        Kirigami.Units.gridUnit * 24)
                    visible: root.applicationsLoading
                        || (!root.applicationsLoading
                            && root.applicationListingCount === 0)
                    spacing: Kirigami.Units.mediumSpacing

                    Controls.BusyIndicator {
                        Layout.alignment: Qt.AlignHCenter
                        visible: root.applicationsLoading
                        running: visible
                    }

                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Kirigami.Units.iconSizes.large
                        Layout.preferredHeight: width
                        visible: !root.applicationsLoading
                        source: searchField.text.length > 0 ? "edit-find" : "edit-none"
                        Accessible.ignored: true
                    }

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: root.applicationsLoading
                            ? i18nc("@info:status", "Loading applications…")
                            : searchField.text.length > 0
                                ? i18nc("@info:status", "No applications match your search.")
                                : i18nc("@info:status", "No applications were found in this category.")
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        Accessible.role: Accessible.StaticText
                        Accessible.name: text
                    }
                }

            }

            ColumnLayout {
                id: favoritesSection

                readonly property real reservedHeight:
                    Kirigami.Units.gridUnit * 7.1

                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.minimumHeight: visible ? reservedHeight : 0
                Layout.preferredHeight: visible ? reservedHeight : 0
                Layout.maximumHeight: visible ? reservedHeight : 0
                visible: root.favoritesSectionVisible
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
                        id: favoritesLeftEdge
                        readonly property bool canScroll:
                            favoritesView.contentWidth > favoritesView.width
                            && !favoritesView.atXBeginning
                        property bool autoScrollSuppressed: false
                        readonly property bool highlightedContent: enabled
                            && (favoritesLeftHover.hovered || hovered || down)

                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                        Layout.fillHeight: true
                        icon.name: "go-previous-symbolic"
                        icon.color: highlightedContent
                            ? root.Kirigami.Theme.highlightedTextColor
                            : root.Kirigami.Theme.textColor
                        display: PlasmaComponents.AbstractButton.IconOnly
                        text: i18nc("@action:button", "Scroll favorites left")
                        Accessible.name: text
                        enabled: canScroll
                        opacity: canScroll ? (hovered ? 0.90 : 0.55) : 0.0
                        onHoveredChanged: {
                            if (!hovered) {
                                autoScrollSuppressed = false
                            }
                            root.updateFavoritesEdgeScroll()
                        }
                        onClicked: {
                            autoScrollSuppressed = true
                            root.scrollFavoritesBy(-favoritesView.delegateWidth)
                        }

                        Behavior on opacity {
                            enabled: root.motionEnabled
                            NumberAnimation { duration: Kirigami.Units.shortDuration }
                        }

                        HoverHandler {
                            id: favoritesLeftHover
                            enabled: favoritesLeftEdge.enabled
                            cursorShape: Qt.PointingHandCursor
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

                        Kirigami.WheelHandler {
                            id: favoritesWheelHandler
                            target: favoritesView
                            scrollFlickableTarget: false
                            blockTargetWheel: true
                            onWheel: function(wheel) {
                                root.handleHorizontalWheel(wheel,
                                    favoritesView,
                                    favoritesScrollAnimation,
                                    favoritesView.delegateWidth * 0.8,
                                    Kirigami.Units.gridUnit * 28)
                            }
                        }

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
                            root.focusApplicationsGrid()
                            event.accepted = true
                        }
                        Keys.onReturnPressed: function(event) {
                            root.launchCurrentFavorite()
                            event.accepted = true
                        }
                        Keys.onEnterPressed: function(event) {
                            root.launchCurrentFavorite()
                            event.accepted = true
                        }
                        Keys.onSpacePressed: function(event) {
                            root.launchCurrentFavorite()
                            event.accepted = true
                        }
                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Menu
                                    || (event.key === Qt.Key_F10
                                        && (event.modifiers & Qt.ShiftModifier))) {
                                root.openCurrentFavoriteContextMenu()
                                event.accepted = true
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
                            Accessible.role: Accessible.Button
                            Accessible.name: appName
                            Accessible.description: isHiddenApplication
                                ? i18nc("@info:accessibility",
                                    "Hidden from the application listing")
                                : ""
                            Accessible.focused: keyboardFocused
                            Accessible.onPressAction: launchFavorite()
                            opacity: isHiddenApplication ? 0.58 : 1.0

                            function launchFavorite() {
                                favoritesView.currentIndex = index
                                root.launchApplication(appStorageId, appCommand)
                            }

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
                                    ? 0.97
                                    : favoriteDelegate.selected ? 1.018 : 1.0

                                Behavior on scale {
                                    enabled: root.motionEnabled
                                    NumberAnimation {
                                        duration: favoriteMouseArea.pressed ? 80 : 130
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on color {
                                    enabled: root.motionEnabled
                                    ColorAnimation {
                                        duration: Math.max(90,
                                            Math.min(150, Kirigami.Units.shortDuration))
                                    }
                                }

                                Behavior on border.color {
                                    enabled: root.motionEnabled
                                    ColorAnimation {
                                        duration: Math.max(90,
                                            Math.min(150, Kirigami.Units.shortDuration))
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
                                        onPressed: function(mouse) {
                                            if (mouse.button !== Qt.RightButton) {
                                                return
                                            }
                                            favoritesView.currentIndex =
                                                favoriteDelegate.index
                                            root.openApplicationContextMenu(
                                                favoriteMouseArea,
                                                favoriteDelegate.appStorageId,
                                                favoriteDelegate.appName,
                                                favoriteDelegate.appIcon,
                                                favoriteDelegate.appCommand,
                                                mouse.x, mouse.y)
                                        }
                                        onClicked: function(mouse) {
                                            if (mouse.button === Qt.LeftButton) {
                                                favoritesView.currentIndex =
                                                    favoriteDelegate.index
                                                favoriteDelegate.launchFavorite()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    PlasmaComponents.ToolButton {
                        id: favoritesRightEdge
                        readonly property bool canScroll:
                            favoritesView.contentWidth > favoritesView.width
                            && !favoritesView.atXEnd
                        property bool autoScrollSuppressed: false
                        readonly property bool highlightedContent: enabled
                            && (favoritesRightHover.hovered || hovered || down)

                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                        Layout.fillHeight: true
                        icon.name: "go-next-symbolic"
                        icon.color: highlightedContent
                            ? root.Kirigami.Theme.highlightedTextColor
                            : root.Kirigami.Theme.textColor
                        display: PlasmaComponents.AbstractButton.IconOnly
                        text: i18nc("@action:button", "Scroll favorites right")
                        Accessible.name: text
                        enabled: canScroll
                        opacity: canScroll ? (hovered ? 0.90 : 0.55) : 0.0
                        onHoveredChanged: {
                            if (!hovered) {
                                autoScrollSuppressed = false
                            }
                            root.updateFavoritesEdgeScroll()
                        }
                        onClicked: {
                            autoScrollSuppressed = true
                            root.scrollFavoritesBy(favoritesView.delegateWidth)
                        }

                        Behavior on opacity {
                            enabled: root.motionEnabled
                            NumberAnimation { duration: Kirigami.Units.shortDuration }
                        }

                        HoverHandler {
                            id: favoritesRightHover
                            enabled: favoritesRightEdge.enabled
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }

                SmoothedAnimation {
                    id: favoritesScrollAnimation

                    property bool edgeDriven: false

                    target: favoritesView
                    property: "contentX"
                    maximumEasingTime: 120
                    onFinished: root.updateFavoritesEdgeScroll()
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
        compactLayout: true
        allowedExternalFocusItems: [applicationContextMenuSurface]

        onLaunchRequested: function(storageId) {
            root.launchApplication(String(storageId || ""), "")
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

    PunchiMenuContextSurface {
        id: applicationContextMenuSurface
        anchors.fill: parent
        z: 300

        onActionTriggered: function(actionId) {
            root.activateContextMenuAction(actionId)
        }
        onCloseRequested: function(restoreFocus) {
            root.closeApplicationContextMenu(restoreFocus)
        }
        onFocusFallbackRequested: {
            if (folderSurface.active) {
                folderSurface.restoreFocus()
            } else {
                root.focusApplicationsGrid()
            }
        }
    }

    Kirigami.InlineMessage {
        id: operationFeedback
        z: 400
        anchors.top: parent.top
        anchors.topMargin: Kirigami.Units.gridUnit * 5.25
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.max(0, Math.min(
            parent.width - Kirigami.Units.largeSpacing * 2,
            Kirigami.Units.gridUnit * 30))
        visible: false
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

        onVisibleChanged: {
            if (!visible && !root.operationMessageDismissalInProgress
                    && (root.operationMessage.length > 0
                        || root.applicationErrorMessage.length > 0)) {
                root.dismissOperationMessage()
            }
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered) {
                    operationMessageTimer.stop()
                } else if (operationFeedback.visible) {
                    operationMessageTimer.restart()
                }
            }
        }
    }
}
// qmllint enable unqualified
