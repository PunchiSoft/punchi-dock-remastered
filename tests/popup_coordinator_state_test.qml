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

    Item {
        id: replacementDynamicOwner

        x: 96
        width: 48
        height: 48
        property bool containsMouse: true
        property Item taskPopupAnchorItem: replacementDynamicVisualAnchor

        Item {
            id: replacementDynamicVisualAnchor

            x: 8
            width: 48
            height: 48
        }
    }

    Components.TaskPopupAnchorProxy {
        id: stableDynamicAnchor
    }

    QtObject {
        id: fakeTaskController

        property var identityWindows: []

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
            return rows.map(function(taskRow) {
                const row = Number(taskRow)
                return {
                    "row": row,
                    "title": row === 2 ? "Second window" : "First window",
                    "icon": row === 2 ? "vlc" : "firefox",
                    "windowUuid": "window-" + row
                }
            })
        }

        function taskWindowsForIdentity() {
            return identityWindows
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
        property real width: 180
        property real height: 150
        property int visualParentChangeCount: 0
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

        onVisualParentChanged: visualParentChangeCount += 1
    }

    QtObject {
        id: fakeAppActionsDialog

        property bool visible: false
        property bool preparingToShow: false
        property var visualParent: null
        property var placementAnchor: null

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
        stableTaskPopupAnchorRef: stableDynamicAnchor
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
        fakeDialog.width = 180
        fakeDialog.height = 150
        fakeDialog.visualParentChangeCount = 0
        fakeDialog.openCount = 0
        fakeDialog.closeCount = 0
        fakeDialog.deferOpen = false
        fakePopupContent.actionsVisible = false
        fakePopupContent.showPreviewsCount = 0
        fakePopupContent.showActionsCount = 0
        fakeAppActionsDialog.visible = false
        fakeAppActionsDialog.preparingToShow = false
        fakeAppActionsDialog.visualParent = null
        fakeAppActionsDialog.placementAnchor = null
        fakeSurfaceStack.focusMediaControlsCount = 0
        fakeAnimatedContent.cancelClosingCount = 0
        fakeAnimatedContent.beginClosingCount = 0
        fakeMprisController.available = false
        fakeMprisController.resolving = false
        fakeMprisController.applicationId = ""
        fakeTaskController.identityWindows = []
        firstAnchor.containsMouse = true
        secondAnchor.containsMouse = true
        dynamicOwner.containsMouse = true
        replacementDynamicOwner.containsMouse = true
        replacementDynamicOwner.x = 96
        stableDynamicAnchor.clear()
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
        failOnWarning(/.?/)
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
        compare(fakeDialog.visualParent, stableDynamicAnchor)
        compare(coordinator.taskPopupVisualParent, dynamicOwner)
        verify(coordinator.taskPopupUsesStableAnchor)
    }

    function test_dynamicGroupWaitsForSettledReplacementAnchor_data() {
        return [
            { tag: "horizontal", horizontalEdge: true },
            { tag: "vertical", horizontalEdge: false }
        ]
    }

    function test_dynamicGroupWaitsForSettledReplacementAnchor(data) {
        coordinator.mediaHoverMode = "none"
        coordinator.windowPreviewsEnabled = true
        coordinator.scheduleTaskWindowsPopup("Firefox", [1, 3], dynamicOwner,
            false, true)

        tryCompare(fakeDialog, "openCount", 1, 600)
        compare(coordinator.activeTaskPopupData.windows.length, 2)
        compare(fakeDialog.visualParent, stableDynamicAnchor)
        verify(coordinator.configureStableTaskPopupAnchor(
            fakeDialog.width, fakeDialog.height, data.horizontalEdge))

        coordinator.removeTaskPopupWindow(3)
        compare(coordinator.activeTaskPopupData.windows.length, 1)
        coordinator.taskPopupVisualParent = null
        const previousAnchorX = stableDynamicAnchor.x
        const anchorChangesBeforeRestore = fakeDialog.visualParentChangeCount

        replacementDynamicOwner.x = 0
        verify(coordinator.scheduleDynamicTaskPopupOwnerRestore(
            replacementDynamicOwner, [1]))
        wait(20)
        compare(stableDynamicAnchor.x, previousAnchorX)

        replacementDynamicOwner.x = 96
        tryCompare(coordinator, "taskPopupVisualParent",
            replacementDynamicOwner, 600)
        compare(stableDynamicAnchor.x + stableDynamicAnchor.width / 2, 128)
        compare(stableDynamicAnchor.y + stableDynamicAnchor.height / 2, 24)
        if (data.horizontalEdge) {
            verify(stableDynamicAnchor.width / 3 > fakeDialog.width / 2)
        } else {
            verify(stableDynamicAnchor.height / 3 > fakeDialog.height / 2)
        }
        compare(fakeDialog.visualParent, stableDynamicAnchor)
        verify(fakeDialog.visualParentChangeCount
            >= anchorChangesBeforeRestore + 2)
        verify(fakeDialog.visible)
        compare(fakeDialog.closeCount, 0)
    }

    function test_pinnedTaskKeepsItsDirectAnchor() {
        coordinator.mediaHoverMode = "none"
        coordinator.windowPreviewsEnabled = true
        coordinator.scheduleTaskWindowsPopup("Firefox", [1], firstAnchor,
            false, true)

        tryCompare(fakeDialog, "openCount", 1, 600)
        compare(fakeDialog.visualParent, firstAnchor)
        verify(!coordinator.taskPopupUsesStableAnchor)
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

    function test_reorderPressCancelsPendingPreviewBeforeLongPress() {
        coordinator.mediaHoverMode = "none"
        coordinator.windowPreviewsEnabled = true
        coordinator.scheduleTaskWindowsPopup("Firefox", [1], firstAnchor,
            false, true)

        verify(coordinator.pendingTaskPopupRequestValid)
        coordinator.cancelTaskPopupForPointerReorder()

        wait(330)
        compare(fakeDialog.openCount, 0)
        verify(!fakeDialog.visible)
        verify(!coordinator.pendingTaskPopupRequestValid)
        compare(coordinator.pendingTaskPopupRows.length, 0)
        compare(coordinator.taskPopupVisualParent, null)
    }

    function test_reorderPressClosesVisiblePreviewImmediately() {
        coordinator.mediaHoverMode = "none"
        coordinator.windowPreviewsEnabled = true
        coordinator.scheduleTaskWindowsPopup("Firefox", [1], firstAnchor,
            false, true)
        tryCompare(fakeDialog, "openCount", 1, 600)
        verify(fakeDialog.visible)

        coordinator.cancelTaskPopupForPointerReorder()

        compare(fakeDialog.closeCount, 1)
        verify(!fakeDialog.visible)
        verify(!coordinator.pendingTaskPopupRequestValid)
        compare(coordinator.pendingTaskPopupRows.length, 0)
        compare(coordinator.taskPopupVisualParent, null)
        compare(coordinator.activeTaskPopupPresentation, "none")
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

    function test_positionedMenuUsesDedicatedPlacementAnchor() {
        coordinator.openAppContextMenu({
            "appId": "org.mozilla.firefox",
            "name": "Firefox"
        }, firstAnchor, [], "pinned", 0)

        tryVerify(function() {
            return fakeAppActionsDialog.visible
        }, 300)
        compare(fakeAppActionsDialog.placementAnchor, firstAnchor)
        compare(fakeAppActionsDialog.visualParent, firstAnchor)
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
