import QtQuick
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase

    name: "PopupCoordinatorState"
    when: windowShown

    Item {
        id: firstAnchor

        width: 48
        height: 48
        property bool containsMouse: true
    }

    Item {
        id: secondAnchor

        width: 48
        height: 48
        property bool containsMouse: true
    }

    Item {
        id: dynamicOwner

        width: 48
        height: 48
        property bool containsMouse: true
        property Item taskPopupAnchorItem: dynamicVisualAnchor

        Item {
            id: dynamicVisualAnchor

            x: 12
            width: 48
            height: 48
        }
    }

    QtObject {
        id: fakeTaskController

        function taskApplicationIdForRows(rows) {
            if (!rows || rows.length === 0) {
                return ""
            }
            return Number(rows[0]) === 2
                ? "org.videolan.vlc"
                : "org.mozilla.firefox"
        }

        function taskWindowsForRows(rows) {
            if (!rows || rows.length === 0) {
                return []
            }
            const row = Number(rows[0])
            return [{
                "row": row,
                "title": row === 2 ? "Second window" : "First window",
                "icon": row === 2 ? "vlc" : "firefox",
                "windowUuid": "window-" + row
            }]
        }
    }

    QtObject {
        id: fakeMprisController

        property string applicationId: ""
        property bool resolving: false
        property bool available: false

        signal stateChanged()
    }

    QtObject {
        id: fakePopupContent

        property bool actionsVisible: false
        property int showPreviewsCount: 0
        property int showActionsCount: 0

        function showPreviews() {
            showPreviewsCount += 1
            actionsVisible = false
        }

        function showActions() {
            showActionsCount += 1
            actionsVisible = true
        }
    }

    QtObject {
        id: fakeSurfaceStack

        property int focusMediaControlsCount: 0

        function focusMediaControls() {
            focusMediaControlsCount += 1
        }
    }

    QtObject {
        id: fakeAnimatedContent

        property int cancelClosingCount: 0
        property int beginClosingCount: 0

        function cancelClosing() {
            cancelClosingCount += 1
        }

        function beginClosing() {
            beginClosingCount += 1
        }
    }

    QtObject {
        id: fakeDialog

        property bool visible: false
        property bool preparingToShow: false
        property var visualParent: null
        property int openCount: 0
        property int closeCount: 0
        property bool deferOpen: false

        function openSafely() {
            openCount += 1
            preparingToShow = true
            if (!deferOpen) {
                preparingToShow = false
                visible = true
            }
        }

        function closeSafely() {
            closeCount += 1
            preparingToShow = false
            visible = false
        }
    }

    QtObject {
        id: fakeAppActionsDialog

        property bool visible: false
        property bool preparingToShow: false
        property var visualParent: null

        function openSafely() {
            visible = true
        }

        function closeSafely() {
            visible = false
        }
    }

    Components.PopupCoordinator {
        id: coordinator

        inPanel: true
        taskControllerRef: fakeTaskController
        mprisControllerRef: fakeMprisController
        taskWindowsPopupContentRef: fakePopupContent
        taskPopupSurfaceRef: fakeSurfaceStack
        taskPopupAnimatedContentRef: fakeAnimatedContent
        taskWindowsDialogRef: fakeDialog
        appActionsDialogRef: fakeAppActionsDialog
        applicationIdentityResolver: function(itemData) {
            return itemData && itemData.appId ? String(itemData.appId) : ""
        }
        contextActionsResolver: function() {
            return [{ "name": "Test action", "kind": "activate", "enabled": true }]
        }
        mediaHoverMode: "card"
        windowPreviewsEnabled: false
    }

    function resetFixture() {
        coordinator.resetTaskPopupState()
        fakeDialog.visible = false
        fakeDialog.preparingToShow = false
        fakeDialog.visualParent = null
        fakeDialog.openCount = 0
        fakeDialog.closeCount = 0
        fakeDialog.deferOpen = false
        fakePopupContent.actionsVisible = false
        fakePopupContent.showPreviewsCount = 0
        fakePopupContent.showActionsCount = 0
        fakeAppActionsDialog.visible = false
        fakeAppActionsDialog.preparingToShow = false
        fakeAppActionsDialog.visualParent = null
        fakeSurfaceStack.focusMediaControlsCount = 0
        fakeAnimatedContent.cancelClosingCount = 0
        fakeAnimatedContent.beginClosingCount = 0
        fakeMprisController.available = false
        fakeMprisController.resolving = false
        fakeMprisController.applicationId = ""
        firstAnchor.containsMouse = true
        secondAnchor.containsMouse = true
        dynamicOwner.containsMouse = true
        coordinator.mediaHoverMode = "card"
        coordinator.windowPreviewsEnabled = false
    }

    function scheduleResolvingCard(appName, rows, anchor) {
        fakeMprisController.available = false
        fakeMprisController.resolving = true
        coordinator.scheduleTaskWindowsPopup(appName, rows, anchor,
            false, false)
    }

    function openResolvedCard(appName, rows, anchor) {
        fakeMprisController.available = true
        fakeMprisController.resolving = false
        coordinator.scheduleTaskWindowsPopup(appName, rows, anchor,
            false, false)
        tryCompare(fakeDialog, "openCount", 1, 600)
        verify(fakeDialog.visible)
        verify(coordinator.mediaHoverActive)
        compare(coordinator.activeTaskPopupPresentation, coordinator.mediaHoverMode)
    }

    function init() {
        resetFixture()
    }

    function cleanup() {
        coordinator.resetTaskPopupState()
        fakeDialog.visible = false
        wait(0)
    }

    function test_dynamicTaskUsesVisualAnchorAndKeepsLogicalOwner() {
        fakeMprisController.available = true
        coordinator.scheduleTaskWindowsPopup("Firefox", [1], dynamicOwner,
            false, false)

        tryCompare(fakeDialog, "openCount", 1, 600)
        compare(fakeDialog.visualParent, dynamicVisualAnchor)
        compare(coordinator.taskPopupVisualParent, dynamicOwner)
    }

    function test_dynamicTaskHorizontalPositionUsesVisualAnchor() {
        coordinator.taskPopupVisualParent = dynamicOwner
        const popupWidth = 120
        const available = Qt.rect(-1000, 0, 2000, 800)
        const center = dynamicVisualAnchor.mapToGlobal(Qt.point(
            dynamicVisualAnchor.width / 2,
            dynamicVisualAnchor.height / 2))
        const expectedX = Math.round(center.x - (popupWidth / 2))

        compare(coordinator.taskPopupHorizontalX(popupWidth, available),
            expectedX)
    }

    function test_dynamicTaskHorizontalPositionClampsToAvailableGeometry() {
        coordinator.taskPopupVisualParent = dynamicOwner
        compare(coordinator.taskPopupHorizontalX(120,
            Qt.rect(500, 0, 100, 800)), 500)
    }

    function test_noneCardLateFirstResolutionOpens() {
        scheduleResolvingCard("Firefox", [1], firstAnchor)

        compare(fakeMprisController.applicationId, "org.mozilla.firefox")
        verify(coordinator.pendingTaskPopupRequestValid)
        wait(330)
        compare(fakeDialog.openCount, 0)
        verify(!fakeDialog.visible)
        verify(coordinator.pendingTaskPopupRequestValid)

        fakeMprisController.available = true
        fakeMprisController.resolving = false
        fakeMprisController.stateChanged()

        tryCompare(fakeDialog, "openCount", 1, 300)
        verify(fakeDialog.visible)
        verify(coordinator.mediaHoverActive)
        compare(coordinator.activeTaskPopupPresentation, "card")
        compare(coordinator.activeTaskPopupData.applicationId,
            "org.mozilla.firefox")
        compare(fakeDialog.visualParent, firstAnchor)
    }

    function test_noneFullCardLateFirstResolutionOpens() {
        coordinator.mediaHoverMode = "fullCard"
        scheduleResolvingCard("Firefox", [1], firstAnchor)

        wait(330)
        compare(fakeDialog.openCount, 0)
        verify(coordinator.pendingTaskPopupRequestValid)
        verify(coordinator.pendingTaskPopupAwaitingMediaResolution)

        fakeMprisController.available = true
        fakeMprisController.resolving = false
        fakeMprisController.stateChanged()

        tryCompare(fakeDialog, "openCount", 1, 300)
        verify(fakeDialog.visible)
        verify(coordinator.mediaHoverActive)
        compare(coordinator.activeTaskPopupPresentation, "fullCard")
        compare(coordinator.activeTaskPopupData.applicationId,
            "org.mozilla.firefox")
    }

    function test_retargetActiveCardClosesUntilNewDecisionIsReady() {
        openResolvedCard("Firefox", [1], firstAnchor)
        compare(coordinator.activeTaskPopupData.applicationId,
            "org.mozilla.firefox")

        fakeMprisController.available = false
        fakeMprisController.resolving = true
        coordinator.scheduleTaskWindowsPopup("VLC", [2], secondAnchor,
            false, false)
        fakeMprisController.stateChanged()

        verify(coordinator.pendingTaskPopupRequestValid)
        compare(fakeMprisController.applicationId, "org.videolan.vlc")
        wait(220)
        verify(!fakeDialog.visible)
        compare(fakeDialog.closeCount, 1)
        compare(coordinator.activeTaskPopupPresentation, "none")
        compare(coordinator.activeTaskPopupData.applicationId,
            "org.mozilla.firefox")

        fakeMprisController.available = true
        fakeMprisController.resolving = false
        fakeMprisController.stateChanged()

        tryCompare(fakeDialog, "openCount", 2, 300)
        compare(coordinator.activeTaskPopupData.applicationId,
            "org.videolan.vlc")
        verify(fakeDialog.visible)
        compare(fakeDialog.closeCount, 1)
        compare(fakeDialog.visualParent, secondAnchor)
        compare(coordinator.activeTaskPopupPresentation, "card")
    }

    function test_cancelBeforeResolutionNeverOpens() {
        scheduleResolvingCard("Firefox", [1], firstAnchor)
        wait(60)

        firstAnchor.containsMouse = false
        coordinator.cancelPendingTaskWindowsPopup(firstAnchor)

        verify(!coordinator.pendingTaskPopupRequestValid)
        compare(coordinator.pendingTaskPopupRows.length, 0)
        fakeMprisController.available = true
        fakeMprisController.resolving = false
        fakeMprisController.stateChanged()
        wait(330)

        compare(fakeDialog.openCount, 0)
        compare(fakeDialog.closeCount, 0)
        verify(!fakeDialog.visible)
        verify(!coordinator.mediaHoverActive)
    }

    function test_noneCardFinalUnavailableClosesPreviousPopup() {
        openResolvedCard("Firefox", [1], firstAnchor)

        fakeMprisController.available = false
        fakeMprisController.resolving = true
        coordinator.scheduleTaskWindowsPopup("VLC", [2], secondAnchor,
            false, false)
        fakeMprisController.stateChanged()
        verify(coordinator.pendingTaskPopupRequestValid)
        verify(!fakeDialog.visible)
        compare(fakeDialog.closeCount, 1)

        fakeMprisController.resolving = false
        fakeMprisController.stateChanged()

        tryCompare(coordinator, "pendingTaskPopupRequestValid", false, 600)
        compare(fakeDialog.closeCount, 1)
        verify(!fakeDialog.visible)
        verify(!coordinator.mediaHoverActive)
        verify(!coordinator.pendingTaskPopupRequestValid)
        compare(coordinator.pendingTaskPopupRows.length, 0)
    }

    function test_overlayResolutionDoesNotReopenPreviewPopup() {
        coordinator.mediaHoverMode = "overlay"
        coordinator.windowPreviewsEnabled = true
        fakeMprisController.available = false
        fakeMprisController.resolving = true

        coordinator.scheduleTaskWindowsPopup("Firefox", [1], firstAnchor,
            false, true)
        tryCompare(fakeDialog, "openCount", 1, 600)
        verify(fakeDialog.visible)
        verify(!coordinator.mediaHoverActive)
        verify(!coordinator.pendingTaskPopupAwaitingMediaResolution)

        fakeMprisController.available = true
        fakeMprisController.resolving = false
        fakeMprisController.stateChanged()
        wait(220)

        compare(fakeDialog.openCount, 1)
        verify(fakeDialog.visible)
        verify(!coordinator.mediaHoverActive)
    }

    function test_openingAnotherPopupCancelsWaitingMediaRequest() {
        scheduleResolvingCard("Firefox", [1], firstAnchor)
        wait(330)
        verify(coordinator.pendingTaskPopupRequestValid)
        verify(coordinator.pendingTaskPopupAwaitingMediaResolution)

        coordinator.closeAllPopups(null)
        verify(!coordinator.pendingTaskPopupRequestValid)
        verify(!coordinator.pendingTaskPopupAwaitingMediaResolution)

        fakeMprisController.available = true
        fakeMprisController.resolving = false
        fakeMprisController.stateChanged()
        wait(220)

        compare(fakeDialog.openCount, 0)
        verify(!fakeDialog.visible)
    }

    function test_cancelDuringGuardedPreparationStopsOpening() {
        coordinator.mediaHoverMode = "none"
        coordinator.windowPreviewsEnabled = true
        fakeDialog.deferOpen = true

        coordinator.scheduleTaskWindowsPopup("Firefox", [1], firstAnchor,
            false, true)
        tryCompare(fakeDialog, "openCount", 1, 600)
        verify(fakeDialog.preparingToShow)
        verify(!fakeDialog.visible)

        coordinator.cancelPendingTaskWindowsPopup(firstAnchor)

        compare(fakeDialog.closeCount, 1)
        verify(!fakeDialog.preparingToShow)
        verify(!fakeDialog.visible)
        verify(!coordinator.pendingTaskPopupRequestValid)
        compare(coordinator.pendingTaskPopupRows.length, 0)
    }

    function test_previewActionsPreserveResolvedPresentation() {
        coordinator.mediaHoverMode = "none"
        coordinator.windowPreviewsEnabled = true
        coordinator.scheduleTaskWindowsPopup("Firefox", [1], firstAnchor,
            false, true)
        tryCompare(fakeDialog, "openCount", 1, 600)
        compare(coordinator.activeTaskPopupPresentation, "preview")

        coordinator.openAppContextMenu({ "appId": "org.mozilla.firefox" },
            firstAnchor, [1], "pinned", 0)

        compare(fakePopupContent.showActionsCount, 1)
        verify(fakePopupContent.actionsVisible)
        compare(coordinator.activeTaskPopupPresentation, "preview")
    }

    function test_overlayActionsPreserveResolvedPresentation() {
        coordinator.mediaHoverMode = "overlay"
        coordinator.windowPreviewsEnabled = true
        coordinator.scheduleTaskWindowsPopup("Firefox", [1], firstAnchor,
            false, true)
        tryCompare(fakeDialog, "openCount", 1, 600)
        compare(coordinator.activeTaskPopupPresentation, "overlay")

        coordinator.openAppContextMenu({ "appId": "org.mozilla.firefox" },
            firstAnchor, [1], "pinned", 0)

        compare(fakePopupContent.showActionsCount, 1)
        verify(fakePopupContent.actionsVisible)
        compare(coordinator.activeTaskPopupPresentation, "overlay")
    }
}
