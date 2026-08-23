import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.ksvg as KSvg
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
    property int folderMaximumColumns: 3
    property int folderMaximumRows: 3
    property bool showApplicationLabels: true
    property string hoverAnimation: "pulse"
    property bool sortApplicationsAlphabetically: false
    property bool backgroundBlurEnabled: true
    property real backgroundOpacity: 0.75
    property string normalPlacementMode: "anchored"
    property int normalPanelGap: 8
    property int normalWidthPercent: 55
    property int normalHeightPercent: 65
    property real themeFrameLeftMargin: 0
    property real themeFrameTopMargin: 0
    property real themeFrameRightMargin: 0
    property real themeFrameBottomMargin: 0
    readonly property var backgroundBlurMaskSource: normalBackground
    readonly property point backgroundBlurMaskOffset: {
        // mapToItem() follows the complete visual hierarchy. Reading the
        // participating geometry explicitly keeps the binding reactive while
        // the surface translation is animated.
        const geometryValues = [
            root.x, root.y,
            surface.x, surface.y,
            surfaceTranslation.x, surfaceTranslation.y,
            normalBackground.x, normalBackground.y
        ]
        if (geometryValues.some(value => !Number.isFinite(value))) {
            return Qt.point(0, 0)
        }
        const scenePosition = normalBackground.mapToItem(
            null, Qt.point(0, 0))
        return Qt.point(Math.round(scenePosition.x),
            Math.round(scenePosition.y))
    }
    readonly property real normalBackgroundBlurRadius: {
        return Kirigami.Units.cornerRadius * 2
            + root.maximumThemeFrameOverlap
    }
    readonly property rect folderDialogBackdropGeometry: {
        // Match the effective themed surface: margins describe only its
        // content area, while the uncontracted frame includes its projection.
        const leftInset = Number(normalBackground.inset.left)
        const topInset = Number(normalBackground.inset.top)
        const rightInset = Number(normalBackground.inset.right)
        const bottomInset = Number(normalBackground.inset.bottom)
        const geometryValues = [
            surface.x, surface.y,
            surfaceTranslation.x, surfaceTranslation.y,
            normalBackground.x, normalBackground.y,
            normalBackground.width, normalBackground.height,
            leftInset, topInset, rightInset, bottomInset
        ]
        const hasValidGeometry = geometryValues.every(
            value => Number.isFinite(value))
        const hasValidInsets = hasValidGeometry
            && leftInset >= 0 && topInset >= 0
            && rightInset >= 0 && bottomInset >= 0
            && leftInset + rightInset < normalBackground.width
            && topInset + bottomInset < normalBackground.height
        if (!hasValidInsets) {
            return Qt.rect(0, 0, root.width, root.height)
        }
        const topLeft = normalBackground.mapToItem(
            root, Qt.point(leftInset, topInset))
        const bottomRight = normalBackground.mapToItem(
            root, Qt.point(normalBackground.width - rightInset,
                normalBackground.height - bottomInset))
        return Qt.rect(
            Math.round(Math.min(topLeft.x, bottomRight.x)),
            Math.round(Math.min(topLeft.y, bottomRight.y)),
            Math.max(0, Math.round(Math.abs(bottomRight.x - topLeft.x))),
            Math.max(0, Math.round(Math.abs(bottomRight.y - topLeft.y))))
    }
    property var hiddenApplicationIds: []
    property bool revealHiddenApplications: false
    property bool showCategories: true
    property bool favoriteLimitReached: false
    property bool menuOpen: false
    property bool applicationsLoading: false
    property bool applicationLaunchPending: false
    property bool suppressDragReleaseClick: false
    property string externalDragSourceNodeId: ""
    property int dragScrollDirection: 0
    property string applicationErrorMessage: ""
    property string settingsErrorMessage: ""
    property string contentViewActive: "applications"
    property string operationMessage: ""
    property bool operationMessageIsError: false
    property bool operationMessageDismissalInProgress: false
    property int operationSecondsRemaining: 0
    property string activeCategoryKey: "All"
    property string activeCategoryTitle: i18nc("@title:category", "All Applications")
    property string pendingCategoryKey: ""
    property bool suppressSearchChange: false
    property int preferredApplicationIndexAfterRefresh: -1
    property var searchApplications: []

    onShowCategoriesChanged: {
        if (!showCategories && activeCategoryKey !== "All") {
            selectCategory("All", i18nc("@title:category", "All Applications"), false)
        }
    }

    readonly property int columnCount: 6
    readonly property bool motionEnabled: Kirigami.Units.longDuration > 0
    readonly property int openDuration: motionEnabled
        ? Math.max(220, Math.min(280, Kirigami.Units.longDuration))
        : 0
    readonly property int closeDuration: motionEnabled
        ? Math.max(140, Math.min(180, Kirigami.Units.shortDuration))
        : 0
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
    readonly property int headerControlSize: Kirigami.Units.gridUnit * 2
    readonly property bool applicationViewActive:
        contentViewActive === "applications"
    readonly property bool settingsViewActive:
        contentViewActive === "settings"
    readonly property bool sessionViewActive:
        contentViewActive === "session"
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
            ? Math.max(1, Math.min(3, Math.round(requestedCount)))
            : 3
    }
    readonly property int safeFolderMaximumRows: {
        const requestedCount = Number(folderMaximumRows)
        return Number.isFinite(requestedCount)
            ? Math.max(1, Math.min(3, Math.round(requestedCount)))
            : 3
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
    readonly property var hiddenApplicationLookup:
        applicationState.hiddenApplicationLookup
    readonly property int hiddenApplicationCount: applicationState.hiddenIdCount
    readonly property bool favoritesSectionVisible: applicationViewActive
        && favorites.length > 0
        && searchField.text.length === 0
        && height >= Kirigami.Units.gridUnit * 24
    readonly property bool organizedListingActive:
        activeCategoryKey === "All"
        && searchField.text.trim().length === 0
        && applicationCatalog.length > 0
    readonly property bool searchListingActive:
        searchField.text.trim().length > 0
    property bool categoryGroupingEnabled: false
    readonly property bool categoryGroupingActive:
        categoryGroupingEnabled
        && !searchListingActive
        && applicationCatalog.length > 0
    readonly property bool effectiveTopCategoryBarVisible:
        showCategories
        && !categoryGroupingActive
        && applicationViewActive
    readonly property var categoryFolderNodes: {
        const result = []
        const nodes = applicationLayoutModel.nodes || []
        for (let index = 0; index < nodes.length; index++) {
            const node = nodes[index]
            if (node && String(node.nodeType || "") === "folder") {
                result.push(node)
            }
        }
        return result
    }
    readonly property bool applicationHoverAllowed:
        !internalDragLayer.active
    readonly property int applicationListingCount: searchListingActive
        ? searchApplications.length
        : organizedListingActive
            ? applicationLayoutModel.nodes.length
            : visibleApplicationsModel.count

    property var dockItemsController: null

    signal closeFinished()
    signal addFavoriteRequested(string storageId)
    signal removeFavoriteRequested(string storageId)
    signal pinToDockRequested(string storageId, string appName, string appIcon, string appCommand)
    signal addToDesktopRequested(string storageId, string appCommand)
    signal setApplicationHiddenRequested(string storageId, bool hidden)
    signal settingChangeRequested(string fieldName, var value)
    signal configureRequested()

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

    function isInternalLayoutDrag(event) {
        return internalDragLayer.active && event
            && event.source === internalDragLayer.dragSource
            && event.keys && event.keys.indexOf(internalDragLayer.dragKey) >= 0
    }

    function beginInternalLayoutDrag(application, sourceItem, x, y) {
        if (!organizedListingActive || folderSurface.active
                || applicationLaunchPending || !applicationLayoutController
                || applicationLayoutController.transactionPending) {
            return false
        }
        const nodeId = String(application ? application.nodeId || "" : "")
        if (!sourceItem || nodeId.length === 0) {
            return false
        }
        closeApplicationContextMenu(false)
        stopHorizontalMotion()
        const position = sourceItem.mapToItem(root, x, y)
        const started = internalDragLayer.begin(application, position,
            Qt.size(sourceItem.width, sourceItem.height))
        if (started) {
            suppressDragReleaseClick = true
            updateDragAutoScroll(position)
        }
        return started
    }

    function updateInternalLayoutDrag(sourceItem, x, y) {
        if (!internalDragLayer.active || !sourceItem) {
            return
        }
        const position = sourceItem.mapToItem(root, x, y)
        if (handleDragOutsideSurface(sourceItem, position)) {
            return
        }
        internalDragLayer.move(position, false)
        updateDragAutoScroll(position)
    }

    function handleDragOutsideSurface(sourceItem, position) {
        if (!internalDragLayer.active || launcherDragController.dragging) {
            return false
        }
        if (internalDragLayer.folder) {
            const bounds = root.folderDialogBackdropGeometry
            const outsideBounds = position.x < bounds.x
                || position.y < bounds.y
                || position.x > bounds.x + bounds.width
                || position.y > bounds.y + bounds.height
            if (!outsideBounds) {
                return false
            }
            dragScrollTimer.stop()
            dragScrollDirection = 0
            internalDragLayer.move(position, true)
            return true
        }

        const surfacePosition = normalBackground.mapFromItem(root, position)
        const outsideSurface = surfacePosition.x < 0 || surfacePosition.y < 0
            || surfacePosition.x > normalBackground.width
            || surfacePosition.y > normalBackground.height
        if (!outsideSurface) {
            return false
        }

        const nodeId = String(internalDragLayer.nodeId || "")
        if (nodeId.length === 0) {
            return false
        }

        const storageId = String(internalDragLayer.storageId || "")
        const iconName = String(internalDragLayer.iconName
            || "application-x-executable")
        if (storageId.length === 0) {
            return false
        }

        externalDragSourceNodeId = nodeId
        cancelInternalLayoutDrag(true)
        if (!launcherDragController.startApplicationDrag(
                sourceItem, storageId, iconName)) {
            externalDragSourceNodeId = ""
            Qt.callLater(function() {
                root.suppressDragReleaseClick = false
            })
            return false
        }
        return true
    }

    function finishInternalLayoutDrag() {
        dragScrollTimer.stop()
        dragScrollDirection = 0
        internalDragLayer.drop()
        Qt.callLater(function() {
            root.suppressDragReleaseClick = false
        })
    }

    function cancelInternalLayoutDrag(preserveReleaseSuppression) {
        dragScrollTimer.stop()
        dragScrollDirection = 0
        internalDragLayer.cancel()
        if (!preserveReleaseSuppression) {
            Qt.callLater(function() {
                root.suppressDragReleaseClick = false
            })
        }
    }

    function updateDragAutoScroll(position) {
        if (!internalDragLayer.active || !applicationsGrid.visible
                || applicationsGrid.height <= 0) {
            dragScrollTimer.stop()
            dragScrollDirection = 0
            return
        }
        const viewportPosition = applicationsGrid.mapToItem(
            root, Qt.point(0, 0))
        const withinHorizontalBounds = position.x >= viewportPosition.x
            && position.x <= viewportPosition.x + applicationsGrid.width
        const edgeHeight = Math.min(applicationsGrid.height / 3,
            Math.max(Kirigami.Units.gridUnit * 2.5,
                applicationsGrid.cellHeight * 0.42))
        const maximumContentY = Math.max(0,
            applicationsGrid.contentHeight - applicationsGrid.height)
        let nextDirection = 0
        if (withinHorizontalBounds
                && position.y <= viewportPosition.y + edgeHeight
                && applicationsGrid.contentY > 0.5) {
            nextDirection = -1
        } else if (withinHorizontalBounds
                && position.y >= viewportPosition.y
                    + applicationsGrid.height - edgeHeight
                && applicationsGrid.contentY < maximumContentY - 0.5) {
            nextDirection = 1
        }
        if (nextDirection === 0) {
            dragScrollTimer.stop()
            dragScrollDirection = 0
            return
        }
        if (dragScrollDirection !== nextDirection) {
            dragScrollDirection = nextDirection
            dragScrollTimer.restart()
        } else if (!dragScrollTimer.running) {
            dragScrollTimer.restart()
        }
    }

    function performDragAutoScroll() {
        if (!internalDragLayer.active || dragScrollDirection === 0) {
            return
        }
        const maximumContentY = Math.max(0,
            applicationsGrid.contentHeight - applicationsGrid.height)
        const currentContentY = Number(applicationsGrid.contentY)
        const step = Math.max(Kirigami.Units.gridUnit * 2,
            applicationsGrid.cellHeight * 0.72)
        const targetContentY = Math.max(0, Math.min(maximumContentY,
            currentContentY + dragScrollDirection * step))
        applicationsGrid.contentY = targetContentY
        if (Math.abs(targetContentY - currentContentY) < 0.5) {
            dragScrollDirection = 0
            return
        }
        Qt.callLater(function() {
            root.updateDragAutoScroll(internalDragLayer.pointerPosition)
        })
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
                && candidateIndex < applicationListingCount) {
            const candidate = applicationNodeAt(candidateIndex)
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

    function nodeIdForGridDrop(x, y) {
        const gridPosition = applicationsGrid.mapFromItem(
            applicationsDropArea, Qt.point(x, y))
        const index = applicationsGrid.indexAt(
            gridPosition.x + applicationsGrid.contentX,
            gridPosition.y + applicationsGrid.contentY)
        const application = applicationNodeAt(index)
        return String(application ? application.nodeId || "" : "")
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
        if (internalDragLayer.active) {
            wheel.accepted = true
            return
        }
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
            cancelInternalLayoutDrag()
        }
    }

    onWidthChanged: cancelInternalLayoutDrag()
    onHeightChanged: cancelInternalLayoutDrag()

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
        operationSecondsRemaining = messageAvailable
            ? Math.max(1, Math.ceil(operationMessageDuration / 1000)) : 0
        if (messageAvailable && !operationFeedbackHover.hovered) {
            operationMessageTimer.start()
        }
    }

    function dismissOperationMessage() {
        operationMessageDismissalInProgress = true
        operationMessageTimer.stop()
        operationSecondsRemaining = 0
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
        return applicationState.isFavorite(storageId)
    }

    function isApplicationHidden(storageId) {
        return applicationState.isApplicationHidden(storageId)
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
        const application = searchListingActive
            ? searchApplications[index]
            : visibleApplicationsModel.get(index)
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
            searchApplications = []
            selectCategory(activeCategoryKey, activeCategoryTitle, false)
            return
        }

        const matches = []
        for (let index = 0; index < allApplicationsModel.count; index++) {
            const application = allApplicationsModel.get(index)
            const storageId = String(application.appStorageId || "")
            if (applicationShouldBeVisible(storageId)
                    && String(application.appName || "").toLocaleLowerCase()
                        .indexOf(query) >= 0) {
                matches.push({
                    appName: String(application.appName || ""),
                    appIcon: String(application.appIcon
                        || "application-x-executable"),
                    appStorageId: storageId,
                    appCommand: String(application.appCommand || ""),
                    appHidden: isApplicationHidden(storageId)
                })
            }
        }
        searchApplications = matches
        applicationsLoading = allApplicationsModel.count === 0 && pendingCategoryKey === "__all__"
        restorePreferredApplicationIndex()
    }

    function requestAllApplications() {
        allApplicationsModel.clear()
        pendingCategoryKey = "__all__"
        systemDiscovery.requestApplications("")
    }

    function selectCategory(categoryKey, title, clearSearch) {
        cancelInternalLayoutDrag()
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
        cancelInternalLayoutDrag()
        operationMessageTimer.stop()
        folderSurface.reset()
        revealHiddenApplications = false
        menuOpen = true
        applicationErrorMessage = ""
        operationMessage = ""
        applicationLaunchPending = false
        settingsErrorMessage = ""
        contentViewActive = "applications"
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
        cancelInternalLayoutDrag()
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
        contentViewActive = "applications"
        closeTimer.restart()
    }

    function resetMenu() {
        cancelInternalLayoutDrag()
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
        settingsErrorMessage = ""
        contentViewActive = "applications"
        pendingCategoryKey = ""
        suppressSearchChange = true
        searchField.clear()
        suppressSearchChange = false
        searchApplications = []
        visibleApplicationsModel.clear()
        allApplicationsModel.clear()
        preferredApplicationIndexAfterRefresh = -1
    }

    Keys.onEscapePressed: function(event) {
        if (internalDragLayer.active) {
            cancelInternalLayoutDrag()
        } else if (applicationContextMenuSurface.active) {
            closeApplicationContextMenu(true)
        } else if (folderSurface.active) {
            folderSurface.closeCurrentView()
        } else if (!applicationViewActive) {
            setContentView("applications")
        } else {
            root.forceClose()
        }
        event.accepted = true
    }

    function normalizedContentView(viewName) {
        const requestedView = String(viewName || "applications")
        return requestedView === "settings" || requestedView === "session"
            ? requestedView : "applications"
    }

    function setContentView(viewName) {
        const requestedView = normalizedContentView(viewName)
        if (contentViewActive === requestedView) {
            return
        }
        cancelInternalLayoutDrag()
        closeApplicationContextMenu(false)
        folderSurface.reset()
        settingsErrorMessage = ""
        contentViewActive = requestedView
        if (settingsViewActive) {
            Qt.callLater(function() {
                const loadedView = settingsViewLoader.item
                if (loadedView) {
                    loadedView.focusInitialAction()
                }
            })
        } else if (sessionViewActive) {
            Qt.callLater(function() {
                const loadedView = sessionViewLoader.item
                if (loadedView) {
                    loadedView.focusInitialAction()
                }
            })
        } else {
            Qt.callLater(function() {
                searchField.forceActiveFocus()
            })
        }
    }

    function setSettingsViewActive(active) {
        setContentView(active ? "settings" : "applications")
    }

    function setSessionViewActive(active) {
        setContentView(active ? "session" : "applications")
    }

    function focusPrimaryContent() {
        if (sessionViewActive) {
            const loadedView = sessionViewLoader.item
            if (loadedView) {
                loadedView.focusInitialAction()
            }
            return
        }
        if (settingsViewActive) {
            const loadedView = settingsViewLoader.item
            if (loadedView) {
                loadedView.focusInitialAction()
            }
            return
        }
        if (effectiveTopCategoryBarVisible && categoriesView.count > 0) {
            categoriesView.forceActiveFocus()
        } else if (categoryGroupingActive && categorySectionsView.visible) {
            categorySectionsView.forceActiveFocus()
        } else {
            focusApplicationsGrid()
        }
    }

    function showSettingsPersistenceError() {
        settingsErrorMessage = i18nc("@info", "Changes could not be saved.")
    }

    onHiddenApplicationIdsChanged: {
        if (menuOpen) {
            cancelInternalLayoutDrag()
            preferredApplicationIndexAfterRefresh = applicationsGrid.currentIndex
            refreshApplicationListing()
        }
    }

    onRevealHiddenApplicationsChanged: {
        if (menuOpen) {
            cancelInternalLayoutDrag()
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

    Timer {
        id: dragScrollTimer
        interval: Math.max(320, Math.round(Kirigami.Units.longDuration * 1.2))
        repeat: false
        onTriggered: root.performDragAutoScroll()
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

    PunchiMenuApplicationState {
        id: applicationState

        favorites: root.favorites
        hiddenApplicationIds: root.hiddenApplicationIds
        applicationCatalog: root.applicationCatalog
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
            root.updateOperationMessageTimer()
        }

        function onTransactionFailed(transactionId, operation, errorCode) {
            root.operationMessage = i18nc("@info:status",
                "The application folder could not be updated.")
            root.operationMessageIsError = true
            root.updateOperationMessageTimer()
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

    KCoreAddons.KUser {
        id: currentUser
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
        scale: root.motionEnabled
            ? (root.menuOpen ? 1.0 : (root.normalPlacementMode === "centered" ? 0.93 : 0.88))
            : 1.0
        transformOrigin: root.normalPlacementMode === "centered"
            ? Item.Center
            : Item.Bottom

        Behavior on scale {
            enabled: root.motionEnabled
            NumberAnimation {
                duration: root.menuOpen ? root.openDuration : root.closeDuration
                easing.type: root.menuOpen ? Easing.OutBack : Easing.InQuad
                easing.overshoot: 1.15
            }
        }

        transform: Translate {
            id: surfaceTranslation
            y: root.motionEnabled
                ? (root.menuOpen ? 0 : (root.normalPlacementMode === "centered" ? 0 : Kirigami.Units.gridUnit * 1.5))
                : 0

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

        KSvg.FrameSvgItem {
            id: normalBackground
            anchors.fill: parent
            anchors.leftMargin: -root.themeFrameOverlapLeft
            anchors.topMargin: -root.themeFrameOverlapTop
            anchors.rightMargin: -root.themeFrameOverlapRight
            anchors.bottomMargin: -root.themeFrameOverlapBottom
            imagePath: "widgets/background"
            opacity: root.safeBackgroundOpacity
            Accessible.ignored: true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: normalBackground.margins.left
                + Kirigami.Units.largeSpacing
            anchors.topMargin: normalBackground.margins.top
                + Kirigami.Units.largeSpacing
            anchors.rightMargin: normalBackground.margins.right
                + Kirigami.Units.largeSpacing
            anchors.bottomMargin: normalBackground.margins.bottom
                + Kirigami.Units.largeSpacing
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
                    enabled: root.menuOpen && root.applicationViewActive
                    placeholderText: i18nc("@placeholder", "Search applications…")
                    Accessible.name: i18nc("@label", "Search applications")
                    background: PunchiMenuSearchBackground {
                        fieldActiveFocus: searchField.activeFocus
                        fieldHovered: searchField.hovered
                    }
                    KeyNavigation.tab: configureButton
                    onTextChanged: {
                        if (!root.suppressSearchChange) {
                            root.cancelInternalLayoutDrag()
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
                    id: configureButton
                    readonly property bool highlightedContent: enabled
                        && (configureHover.hovered || hovered || down
                            || activeFocus || checked)
                    Layout.preferredWidth: root.headerControlSize
                    Layout.minimumWidth: Layout.preferredWidth
                    Layout.maximumWidth: Layout.preferredWidth
                    Layout.preferredHeight: root.headerControlSize
                    Layout.minimumHeight: Layout.preferredHeight
                    Layout.maximumHeight: Layout.preferredHeight
                    enabled: root.menuOpen && !root.applicationLaunchPending
                    icon.name: root.settingsViewActive ? "view-grid" : "configure"
                    icon.color: highlightedContent
                        ? root.Kirigami.Theme.highlightedTextColor
                        : root.Kirigami.Theme.textColor
                    display: PlasmaComponents.AbstractButton.IconOnly
                    text: root.settingsViewActive
                        ? i18nc("@action:button", "Show applications")
                        : i18n("Configure PunchiMenu")
                    checkable: true
                    checked: root.settingsViewActive
                    Accessible.name: text
                    KeyNavigation.backtab: searchField
                    KeyNavigation.tab: sessionButton

                    background: PunchiMenuActionBackground {
                        highlighted: configureButton.highlightedContent
                        circular: true
                    }

                    PlasmaCore.ToolTipArea {
                        id: configureToolTip
                        anchors.fill: parent
                        active: configureButton.enabled
                        mainText: configureButton.text
                    }

                    onActiveFocusChanged: {
                        if (activeFocus) {
                            configureToolTip.showToolTip()
                        } else if (!configureToolTip.containsMouse) {
                            configureToolTip.hideImmediately()
                        }
                    }
                    onClicked: root.setSettingsViewActive(
                        !root.settingsViewActive)

                    Keys.onDownPressed: function(event) {
                        root.focusPrimaryContent()
                        event.accepted = true
                    }

                    HoverHandler {
                        id: configureHover
                        enabled: configureButton.enabled
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                PlasmaComponents.ToolButton {
                    id: sessionButton
                    readonly property bool highlightedContent: enabled
                        && (sessionHover.hovered || hovered || down
                            || activeFocus || checked)
                    readonly property color foregroundColor: highlightedContent
                        ? root.Kirigami.Theme.highlightedTextColor
                        : root.Kirigami.Theme.textColor
                    Layout.preferredWidth: root.headerControlSize
                    Layout.minimumWidth: Layout.preferredWidth
                    Layout.maximumWidth: Layout.preferredWidth
                    Layout.preferredHeight: root.headerControlSize
                    Layout.minimumHeight: Layout.preferredHeight
                    Layout.maximumHeight: Layout.preferredHeight
                    enabled: root.menuOpen && !root.applicationLaunchPending
                    display: PlasmaComponents.AbstractButton.IconOnly
                    text: root.sessionViewActive
                        ? i18nc("@action:button", "Show applications")
                        : i18nc("@action:button", "Show session actions")
                    checkable: true
                    checked: root.sessionViewActive
                    Accessible.name: text
                    KeyNavigation.backtab: configureButton
                    KeyNavigation.tab: hiddenApplicationsButton.visible
                            && root.applicationViewActive
                        ? hiddenApplicationsButton : btnClose

                    contentItem: Item {
                        implicitWidth: root.headerControlSize
                        implicitHeight: root.headerControlSize

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: Kirigami.Units.iconSizes.smallMedium
                            height: width
                            source: "user-identity"
                            color: sessionButton.foregroundColor
                            visible: !root.sessionViewActive
                            Accessible.ignored: true
                        }

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: Kirigami.Units.iconSizes.smallMedium
                            height: width
                            source: "view-grid"
                            color: sessionButton.foregroundColor
                            visible: root.sessionViewActive
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
                        active: sessionButton.enabled
                        mainText: sessionButton.text
                    }

                    onActiveFocusChanged: {
                        if (activeFocus) {
                            sessionToolTip.showToolTip()
                        } else if (!sessionToolTip.containsMouse) {
                            sessionToolTip.hideImmediately()
                        }
                    }
                    onClicked: root.setSessionViewActive(
                        !root.sessionViewActive)

                    Keys.onDownPressed: function(event) {
                        root.focusPrimaryContent()
                        event.accepted = true
                    }

                    HoverHandler {
                        id: sessionHover
                        enabled: sessionButton.enabled
                        cursorShape: Qt.PointingHandCursor
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
                    enabled: root.menuOpen && root.applicationViewActive
                        && !root.applicationLaunchPending
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
                    KeyNavigation.backtab: sessionButton
                    KeyNavigation.tab: btnClose
                    KeyNavigation.right: btnClose
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
                    KeyNavigation.backtab: hiddenApplicationsButton.visible
                            && root.applicationViewActive
                        ? hiddenApplicationsButton : sessionButton
                    KeyNavigation.tab: root.applicationViewActive
                        ? (root.effectiveTopCategoryBarVisible
                            ? categoriesView
                            : (root.categoryGroupingActive ? categorySectionsView : applicationsGrid))
                        : sessionButton
                    KeyNavigation.left: hiddenApplicationsButton.visible
                            && root.applicationViewActive
                        ? hiddenApplicationsButton : sessionButton

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

            Kirigami.Separator {
                Layout.fillWidth: true
                visible: root.effectiveTopCategoryBarVisible
                Accessible.ignored: true
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.effectiveTopCategoryBarVisible
                    ? Kirigami.Units.gridUnit * 2.65 : 0
                visible: root.effectiveTopCategoryBarVisible

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
                            && (categoryLeftHover.hovered || hovered || down
                                || activeFocus)

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
                        opacity: canScroll
                            ? (highlightedContent ? 1.0 : 0.55) : 0.0

                        background: PunchiMenuActionBackground {
                            highlighted: categoryLeftEdge.highlightedContent
                            circular: true
                        }
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
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2.1
                        Layout.alignment: Qt.AlignVCenter
                        orientation: ListView.Horizontal
                        spacing: Kirigami.Units.smallSpacing
                        clip: true
                        model: categoryModel
                        boundsBehavior: Flickable.StopAtBounds
                        keyNavigationWraps: false
                        activeFocusOnTab: root.showCategories && root.applicationViewActive
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
                            && (categoryRightHover.hovered || hovered || down
                                || activeFocus)

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
                        opacity: canScroll
                            ? (highlightedContent ? 1.0 : 0.55) : 0.0

                        background: PunchiMenuActionBackground {
                            highlighted: categoryRightEdge.highlightedContent
                            circular: true
                        }
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

            Kirigami.Separator {
                Layout.fillWidth: true
                visible: root.applicationViewActive
                Accessible.ignored: true
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.applicationViewActive

                DropArea {
                    id: applicationsDropArea
                    anchors.fill: applicationsGrid
                    keys: [internalDragLayer.dragKey]
                    z: 0
                    visible: !root.categoryGroupingActive && !root.searchListingActive
                    enabled: visible

                    onEntered: function(drag) {
                        drag.accepted = root.isInternalLayoutDrag(drag)
                    }
                    onDropped: function(drop) {
                        if (!root.isInternalLayoutDrag(drop)) {
                            drop.accepted = false
                            return
                        }
                        drop.accepted = root.requestDraggedNodeMove(
                            root.nodeIdForGridDrop(drop.x, drop.y))
                    }
                }

                PunchiMenuCategorySectionsView {
                    id: categorySectionsView
                    anchors.fill: parent
                    visible: root.applicationViewActive
                        && root.categoryGroupingActive
                        && !root.searchListingActive
                    enabled: visible && !root.applicationLaunchPending
                    activeFocusOnTab: visible
                    KeyNavigation.backtab: root.effectiveTopCategoryBarVisible
                        ? categoriesView : btnClose
                    categoryGroups: applicationLayoutModel.categoryGroups
                    folderNodes: root.categoryFolderNodes
                    showApplicationLabels: root.showApplicationLabels
                    motionEnabled: root.motionEnabled
                    hoverEnabled: root.applicationHoverAllowed
                    hoverAnimation: root.hoverAnimation
                    iconScale: root.safeApplicationIconScale
                    baseIconSize: Kirigami.Units.iconSizes.huge

                    isDragActive: internalDragLayer.active
                    dragSourceNodeId: String(internalDragLayer.nodeId || "")
                    isDragFolder: Boolean(internalDragLayer.folder)
                    dragKey: internalDragLayer.dragKey
                    suppressDragReleaseClick: root.suppressDragReleaseClick

                    onDragBeginRequested: function(application, sourceItem, x, y) {
                        root.beginInternalLayoutDrag(application, sourceItem, x, y)
                    }
                    onDragUpdateRequested: function(sourceItem, x, y) {
                        root.updateInternalLayoutDrag(sourceItem, x, y)
                    }
                    onDragFinishRequested: root.finishInternalLayoutDrag()
                    onDragCancelRequested: root.cancelInternalLayoutDrag(false)
                    onDropOntoNodeRequested: function(targetNode) {
                        return root.handleDraggedNodeDrop(targetNode)
                    }

                    onLaunchRequested: function(storageId) {
                        if (root.applicationLaunchPending || storageId.length === 0) {
                            return
                        }
                        root.applicationErrorMessage = ""
                        root.applicationLaunchPending = true
                        root.systemDiscovery.launchApplication(storageId)
                    }
                    onApplicationContextRequested: function(sourceItem, application, x, y) {
                        root.openApplicationContextMenu(sourceItem,
                            String(application.appStorageId || ""),
                            String(application.appName || ""),
                            String(application.appIcon || ""), "", x, y)
                    }
                    onFolderOpenRequested: function(folderId) {
                        folderSurface.openFolder(folderId)
                    }
                    onFolderContextRequested: function(sourceItem, folder, x, y) {
                        root.openFolderContextMenu(sourceItem, folder, x, y)
                    }
                    onFolderRenameRequested: function(folderId) {
                        folderSurface.beginRename(folderId)
                    }
                    onReturnToSearchRequested: function() {
                        searchField.forceActiveFocus()
                    }
                    onBottomReached: {
                        if (root.favoritesSectionVisible && favoritesView.count > 0) {
                            favoritesView.forceActiveFocus()
                            if (favoritesView.currentIndex < 0) {
                                favoritesView.currentIndex = 0
                            }
                        }
                    }
                }

                GridView {
                    id: applicationsGrid
                    readonly property int stableRowCount: Math.ceil(
                        root.applicationListingCount / Math.max(1, root.columnCount))
                    readonly property real stableContentHeight:
                        stableRowCount * cellHeight
                    readonly property bool verticalScrollRequired:
                        stableContentHeight > height + 0.5
                    readonly property real verticalScrollBarReserve:
                        Math.max(1, applicationsScrollBar.implicitWidth)
                            + Kirigami.Units.smallSpacing
                    anchors.fill: parent
                    z: 1
                    visible: !root.categoryGroupingActive || root.searchListingActive
                    model: root.applicationListingCount
                    cellWidth: Math.max(1,
                        (width - verticalScrollBarReserve) / root.columnCount)
                    cellHeight: Math.max(Kirigami.Units.gridUnit * 7.5,
                        Kirigami.Units.iconSizes.huge * root.safeApplicationIconScale
                            + Kirigami.Units.gridUnit * 3)
                    clip: true
                    focus: true
                    activeFocusOnTab: visible
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: !internalDragLayer.active
                    enabled: visible && !root.applicationLaunchPending
                    keyNavigationWraps: false
                    KeyNavigation.backtab: root.effectiveTopCategoryBarVisible ? categoriesView : btnClose

                    onActiveFocusChanged: {
                        if (activeFocus && root.applicationListingCount > 0) {
                            if (currentIndex < 0
                                    || currentIndex >= root.applicationListingCount) {
                                currentIndex = 0
                            }
                            positionViewAtIndex(currentIndex, GridView.Contain)
                        }
                    }

                    Kirigami.WheelHandler {
                        id: applicationDragWheelBlocker
                        target: internalDragLayer.active
                            ? applicationsGrid : null
                        scrollFlickableTarget: false
                        blockTargetWheel: true
                        onWheel: function(wheel) {
                            wheel.accepted = true
                        }
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
                        readonly property bool pointerHovered:
                            delegatePointer.containsMouse
                            && root.applicationHoverAllowed
                        readonly property bool selected: keyboardFocused
                            || pointerHovered
                        readonly property bool isDragSource:
                            internalDragLayer.active
                            && internalDragLayer.nodeId === nodeId
                        readonly property bool isHiddenApplication: appHidden
                        readonly property bool dropGroupingActive:
                            nodeDropTarget.containsDrag
                            && nodeDropTarget.dropIntent === "group"
                        readonly property bool dropInsertionActive:
                            nodeDropTarget.containsDrag
                            && (nodeDropTarget.dropIntent === "insertBefore"
                                || nodeDropTarget.dropIntent === "insertAfter")
                        readonly property int iconSize:
                            applicationIconMetrics.effectiveSize

                        PunchiMenuIconMetrics {
                            id: applicationIconMetrics
                            requestedScale: root.safeApplicationIconScale
                            minimumScale: 0.75
                            maximumScale: 1.5
                            baseSize: Kirigami.Units.iconSizes.huge
                            minimumSize: Kirigami.Units.iconSizes.medium
                            availableWidth: Math.max(0,
                                applicationDelegate.width
                                    - Kirigami.Units.gridUnit)
                            availableHeight: Math.max(0,
                                applicationDelegate.height
                                    - Kirigami.Units.gridUnit * 3)
                        }
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
                        opacity: isDragSource ? 0.34
                            : isHiddenApplication ? 0.58 : 1.0

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
                            id: folderTile
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
                                || applicationDelegate.dropGroupingActive
                            motionEnabled: root.motionEnabled
                            requestedIconSize: applicationDelegate.iconSize
                            hoverAnimation: root.hoverAnimation
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

                        PunchiMenuItemHighlight {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            visible: !applicationDelegate.isFolder
                            hovered: applicationDelegate.pointerHovered
                            selected: applicationDelegate.selected
                                || applicationDelegate.dropGroupingActive
                            focused: applicationDelegate.keyboardFocused
                            pressed: delegatePointer.pressed
                                && !internalDragLayer.active
                            motionEnabled: root.motionEnabled
                            animationMode: root.hoverAnimation

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.smallSpacing
                                anchors.topMargin: root.showApplicationLabels
                                    ? Kirigami.Units.smallSpacing
                                    : Math.max(Kirigami.Units.smallSpacing,
                                        (parent.height
                                            - applicationDelegate.iconSize) / 2)
                                anchors.bottomMargin: anchors.topMargin
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
                                    visible: root.showApplicationLabels
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
                                active: !root.showApplicationLabels
                                    || applicationLabel.truncated
                                mainText: applicationDelegate.appName
                            }
                        }

                        DropArea {
                            id: nodeDropTarget
                            property string dropIntent: "none"
                            readonly property real insertionEdgeWidth: Math.min(
                                width * 0.25, Kirigami.Units.gridUnit * 1.75)

                            function updateDropIntent(drag) {
                                if (!root.isInternalLayoutDrag(drag)
                                        || internalDragLayer.nodeId
                                            === applicationDelegate.nodeId) {
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
                                        ? "insertBefore" : "insertAfter"
                                } else if (pointerX <= insertionEdgeWidth) {
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
                                        || dropIntent === "insertAfter") {
                                    drop.accepted = root.requestDraggedNodeMove(
                                        root.beforeNodeIdForInsertion(
                                            applicationDelegate.index,
                                            dropIntent === "insertAfter"))
                                } else {
                                    drop.accepted = root.handleDraggedNodeDrop(
                                        applicationDelegate.nodeData)
                                }
                                dropIntent = "none"
                            }
                        }

                        Rectangle {
                            readonly property bool after:
                                nodeDropTarget.dropIntent === "insertAfter"
                            readonly property int gridColumn:
                                applicationDelegate.index
                                    % Math.max(1, root.columnCount)
                            readonly property bool atLeadingGridEdge:
                                !after && gridColumn === 0

                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.topMargin: Kirigami.Units.smallSpacing
                            anchors.bottomMargin: Kirigami.Units.smallSpacing
                            x: atLeadingGridEdge ? 0
                                : after ? parent.width - width / 2
                                : -width / 2
                            width: Kirigami.Units.largeSpacing
                            radius: Kirigami.Units.cornerRadius
                            color: Qt.alpha(Kirigami.Theme.highlightColor, 0.22)
                            border.width: 2
                            border.color: Kirigami.Theme.highlightColor
                            visible: applicationDelegate.dropInsertionActive
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
                            source: applicationDelegate.dropInsertionActive
                                ? "transform-move-symbolic"
                                : applicationDelegate.isFolder
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
                            cursorShape: applicationDelegate.isDragSource
                                ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                            onEntered: {
                                if (root.applicationHoverAllowed) {
                                    applicationsGrid.currentIndex
                                        = applicationDelegate.index
                                }
                            }
                            onPressed: function(mouse) {
                                if (mouse.button !== Qt.RightButton) {
                                    return
                                }
                                applicationsGrid.currentIndex
                                    = applicationDelegate.index
                                if (applicationDelegate.isFolder) {
                                    root.openFolderContextMenu(
                                        applicationDelegate,
                                        applicationDelegate.nodeData,
                                        mouse.x, mouse.y)
                                } else {
                                    root.openApplicationContextMenu(
                                        applicationDelegate,
                                        applicationDelegate.appStorageId,
                                        applicationDelegate.appName,
                                        applicationDelegate.appIcon,
                                        applicationDelegate.appCommand,
                                        mouse.x, mouse.y)
                                }
                            }
                            onPressAndHold: function(mouse) {
                                if (mouse.button === Qt.LeftButton) {
                                    applicationsGrid.currentIndex
                                        = applicationDelegate.index
                                    root.beginInternalLayoutDrag(
                                        applicationDelegate.nodeData,
                                        delegatePointer, mouse.x, mouse.y)
                                }
                            }
                            onPositionChanged: function(mouse) {
                                if (applicationDelegate.isDragSource) {
                                    root.updateInternalLayoutDrag(
                                        delegatePointer, mouse.x, mouse.y)
                                }
                            }
                            onReleased: function(mouse) {
                                if (mouse.button === Qt.LeftButton
                                        && applicationDelegate.isDragSource) {
                                    root.finishInternalLayoutDrag()
                                }
                            }
                            onCanceled: {
                                if (applicationDelegate.isDragSource) {
                                    root.cancelInternalLayoutDrag()
                                }
                            }
                            onClicked: function(mouse) {
                                if (root.suppressDragReleaseClick) {
                                    return
                                }
                                applicationsGrid.currentIndex
                                    = applicationDelegate.index
                                if (mouse.button === Qt.RightButton) {
                                    return
                                } else {
                                    applicationDelegate.launchApp()
                                }
                            }
                        }
                    }
                }

                PlasmaComponents.ScrollBar {
                    id: applicationsScrollBar

                    readonly property real stableSize:
                        applicationsGrid.stableContentHeight > 0
                            ? Math.min(1, applicationsGrid.height
                                / applicationsGrid.stableContentHeight)
                            : 1
                    readonly property real stablePosition: {
                        const totalHeight = applicationsGrid.stableContentHeight
                        if (totalHeight <= 0) {
                            return 0
                        }
                        const maximumPosition = Math.max(0, 1 - stableSize)
                        const logicalPosition = (applicationsGrid.contentY
                            - applicationsGrid.originY) / totalHeight
                        return Math.max(0, Math.min(maximumPosition,
                            logicalPosition))
                    }

                    anchors.top: applicationsGrid.top
                    anchors.right: applicationsGrid.right
                    anchors.bottom: applicationsGrid.bottom
                    z: 3
                    orientation: Qt.Vertical
                    visible: applicationsGrid.visible
                        && applicationsGrid.verticalScrollRequired
                    policy: visible
                        ? PlasmaComponents.ScrollBar.AlwaysOn
                        : PlasmaComponents.ScrollBar.AlwaysOff
                    size: stableSize
                    position: stablePosition
                    stepSize: applicationsGrid.stableContentHeight > 0
                        ? Math.min(1, applicationsGrid.cellHeight
                            / applicationsGrid.stableContentHeight)
                        : 0
                    active: applicationsGrid.moving
                        || applicationsGrid.flicking || hovered || pressed

                    onPositionChanged: {
                        if (!pressed) {
                            return
                        }
                        const maximumContentY = Math.max(0,
                            applicationsGrid.stableContentHeight
                                - applicationsGrid.height)
                        const targetContentY = applicationsGrid.originY
                            + Math.max(0, Math.min(maximumContentY,
                                position
                                    * applicationsGrid.stableContentHeight))
                        if (Math.abs(applicationsGrid.contentY
                                - targetContentY) > 0.5) {
                            applicationsGrid.contentY = targetContentY
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - Kirigami.Units.largeSpacing * 2,
                        Kirigami.Units.gridUnit * 24)
                    visible: (!root.categoryGroupingActive
                        || root.searchListingActive)
                        && (root.applicationsLoading
                            || (!root.applicationsLoading
                                && root.applicationListingCount === 0))
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
                            if (root.categoryGroupingActive && categorySectionsView.visible) {
                                categorySectionsView.forceActiveFocus()
                            } else {
                                root.focusApplicationsGrid()
                            }
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

            Loader {
                id: settingsViewLoader
                Layout.fillWidth: true
                Layout.fillHeight: true
                active: root.settingsViewActive
                visible: root.settingsViewActive
                enabled: visible
                asynchronous: false

                sourceComponent: Component {
                    PunchiMenuNormalSettingsView {
                        backgroundBlurEnabled: root.backgroundBlurEnabled
                        backgroundOpacityPercent: Math.round(
                            root.safeBackgroundOpacity * 100)
                        showApplicationLabels: root.showApplicationLabels
                        normalShowCategories: root.showCategories
                        normalCategoryGrouping: root.categoryGroupingEnabled
                        hoverAnimation: root.hoverAnimation
                        sortApplicationsAlphabetically:
                            root.sortApplicationsAlphabetically
                        applicationIconScalePercent: Math.round(
                            root.safeApplicationIconScale * 100)
                        favoriteIconScalePercent: Math.round(
                            root.safeFavoriteIconScale * 100)
                        folderMaximumColumns: root.safeFolderMaximumColumns
                        folderMaximumRows: root.safeFolderMaximumRows
                        normalPlacementMode: root.normalPlacementMode
                        normalPanelGap: root.normalPanelGap
                        normalWidthPercent: root.normalWidthPercent
                        normalHeightPercent: root.normalHeightPercent
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
                Layout.fillWidth: true
                Layout.fillHeight: true
                active: root.sessionViewActive
                visible: root.sessionViewActive
                enabled: visible
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
    }

    PunchiMenuDragLayer {
        id: internalDragLayer
        anchors.fill: parent
        z: 230
        showApplicationLabels: root.showApplicationLabels
        motionEnabled: root.motionEnabled
        visualBounds: root.folderDialogBackdropGeometry
    }

    Punchi.LauncherDragController {
        id: launcherDragController
        iconSize: Math.round(Kirigami.Units.iconSizes.large
            * root.safeApplicationIconScale)

        onDragFinished: function(accepted) {
            const nodeId = root.externalDragSourceNodeId
            root.externalDragSourceNodeId = ""
            root.suppressDragReleaseClick = false
            if (accepted) {
                root.forceClose()
            } else if (nodeId.length > 0) {
                root.restoreApplicationNodeFocus(nodeId)
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
        maximumColumnCount: root.safeFolderMaximumColumns
        maximumRowCount: root.safeFolderMaximumRows
        showApplicationLabels: root.showApplicationLabels
        hoverAnimation: root.hoverAnimation
        detailedApplicationFeedback: true
        backdropGeometry: root.folderDialogBackdropGeometry
        backdropRadius: root.normalBackgroundBlurRadius
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
            Kirigami.Units.gridUnit * 36))
        visible: false
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

        onVisibleChanged: {
            if (!visible && !root.operationMessageDismissalInProgress
                    && (root.operationMessage.length > 0
                        || root.applicationErrorMessage.length > 0)) {
                root.dismissOperationMessage()
            }
        }

        HoverHandler {
            id: operationFeedbackHover
            onHoveredChanged: {
                if (hovered) {
                    operationMessageTimer.stop()
                } else if (operationFeedback.visible
                        && root.operationSecondsRemaining > 0) {
                    operationMessageTimer.start()
                }
            }
        }
    }
}
// qmllint enable unqualified
