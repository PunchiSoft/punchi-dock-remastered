import QtQuick
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase

    name: "DockFolderViewContext"

    property var folder: ({
        "type": "folder",
        "name": "Favorites",
        "icon": "folder-favorites",
        "layout": "list",
        "sourceType": "manual",
        "apps": []
    })

    property var folderContainer: ({
        "type": "folder",
        "name": "Downloads",
        "icon": "folder-download",
        "layout": "list",
        "sourceType": "folder",
        "sourcePath": "/home/user/Downloads",
        "apps": []
    })

    QtObject {
        id: fakeTaskController

        function dockItemApplicationId() { return "" }
        function dockItemLauncherUrl() { return "" }
    }

    QtObject {
        id: fakeDockItemsController

        property var dockItems: [testCase.folder]
        property int layoutCallCount: 0
        property int lastTargetIndex: -1
        property string lastLayout: ""
        property string lastExpectedFolderText: ""
        property int syncCallCount: 0
        property bool lastSync: true
        property string lastSyncExpectedFolderText: ""
        property int browseCallCount: 0
        property bool lastBrowseSubfolders: false
        property string lastBrowseExpectedFolderText: ""

        function canonicalJsonText(value) {
            return JSON.stringify(value)
        }

        function setFolderLayout(targetIndex, layout, expectedFolderText) {
            layoutCallCount++
            lastTargetIndex = targetIndex
            lastLayout = layout
            lastExpectedFolderText = expectedFolderText
            return true
        }

        function setFolderSyncFolder(targetIndex, sync, expectedFolderText) {
            syncCallCount++
            lastTargetIndex = targetIndex
            lastSync = sync
            lastSyncExpectedFolderText = expectedFolderText
            return true
        }

        function setFolderBrowseSubfolders(targetIndex, enabled, expectedFolderText) {
            browseCallCount++
            lastTargetIndex = targetIndex
            lastBrowseSubfolders = enabled
            lastBrowseExpectedFolderText = expectedFolderText
            return true
        }
    }

    Components.DockContextActionsController {
        id: contextController
        taskController: fakeTaskController
        dockItemsController: fakeDockItemsController
        configureDockHandler: function() { return true }
    }

    function init() {
        failOnWarning(/.?/)
        fakeDockItemsController.dockItems = [folder]
        fakeDockItemsController.layoutCallCount = 0
        fakeDockItemsController.lastTargetIndex = -1
        fakeDockItemsController.lastLayout = ""
        fakeDockItemsController.lastExpectedFolderText = ""
        fakeDockItemsController.syncCallCount = 0
        fakeDockItemsController.lastSync = true
        fakeDockItemsController.lastSyncExpectedFolderText = ""
        fakeDockItemsController.browseCallCount = 0
        fakeDockItemsController.lastBrowseSubfolders = false
        fakeDockItemsController.lastBrowseExpectedFolderText = ""
    }

    function behaviorAction(actions) {
        for (let index = 0; index < actions.length; index++) {
            if (actions[index].name === "Behavior") {
                return actions[index]
            }
        }
        return null
    }

    function actionByKind(actions, kind) {
        for (let index = 0; index < actions.length; index++) {
            if (actions[index].kind === kind) {
                return actions[index]
            }
        }
        return null
    }

    function childByLayout(action, layout) {
        for (let index = 0; index < action.children.length; index++) {
            if (action.children[index].layout === layout) {
                return action.children[index]
            }
        }
        return null
    }

    function test_folderMenuExposesExclusiveViewsAndCurrentDetail() {
        const actions = contextController.actionsForItem(folder, [], "pinned", 0)
        compare(actionByKind(actions, "editDockItem"), null)
        const configureAction = actionByKind(actions, "configureDock")
        verify(configureAction !== null)
        verify(contextController.triggerAction(configureAction))
        verify(actionByKind(actions, "unpinFromDock") !== null)
        const submenu = actionByKind(actions, "submenu")
        verify(submenu !== null)
        compare(submenu.name, "Folder view")
        verify(submenu.detail === undefined)
        compare(submenu.children.length, 4)

        const gridAction = childByLayout(submenu, "grid")
        const listAction = childByLayout(submenu, "list")
        const detailedAction = childByLayout(submenu, "detailed")
        const fanAction = childByLayout(submenu, "fan")
        verify(gridAction !== null)
        verify(listAction !== null)
        verify(detailedAction !== null)
        verify(fanAction !== null)
        verify(!gridAction.checked)
        verify(listAction.checked)
        verify(!detailedAction.checked)
        verify(!fanAction.checked)
        compare(detailedAction.kind, "setFolderView")
    }

    function test_folderViewActionCarriesStableTargetIdentity() {
        const actions = contextController.actionsForItem(folder, [], "pinned", 0)
        const submenu = actionByKind(actions, "submenu")
        const fanAction = childByLayout(submenu, "fan")
        const expectedText = JSON.stringify(folder)

        verify(contextController.triggerAction(fanAction))
        compare(fakeDockItemsController.layoutCallCount, 1)
        compare(fakeDockItemsController.lastTargetIndex, 0)
        compare(fakeDockItemsController.lastLayout, "fan")
        compare(fakeDockItemsController.lastExpectedFolderText, expectedText)
    }

    function test_nonFolderPinnedItemDoesNotExposeFolderView() {
        const media = { "type": "media", "name": "Player" }
        const actions = contextController.actionsForItem(media, [], "pinned", 0)
        for (let index = 0; index < actions.length; index++) {
            verify(actions[index].name !== "Folder view")
        }
    }

    function test_manualContainerHidesTheBehaviorGroup() {
        const actions = contextController.actionsForItem(folder, [], "pinned", 0)
        compare(behaviorAction(actions), null)

        const pathless = {
            "type": "folder",
            "name": "Empty",
            "icon": "folder",
            "layout": "list",
            "sourceType": "folder",
            "sourcePath": "",
            "apps": []
        }
        fakeDockItemsController.dockItems = [pathless]
        const pathlessActions = contextController.actionsForItem(
            pathless, [], "pinned", 0)
        compare(behaviorAction(pathlessActions), null)
    }

    function test_folderContainerOffersBehaviorGroupAfterFolderView() {
        fakeDockItemsController.dockItems = [folderContainer]
        const actions = contextController.actionsForItem(
            folderContainer, [], "pinned", 0)
        const behavior = behaviorAction(actions)
        verify(behavior !== null)
        compare(behavior.kind, "submenu")
        compare(behavior.children.length, 2)

        const sync = actionByKind(behavior.children, "setFolderSyncFolder")
        verify(sync !== null)
        compare(sync.name, "Live folder contents")
        compare(sync.enabled, true)
        verify(sync.checked)
        compare(sync.sync, false)
        compare(sync.targetIndex, 0)
        compare(sync.expectedFolderText, JSON.stringify(folderContainer))

        const browse = actionByKind(behavior.children, "setFolderBrowseSubfolders")
        verify(browse !== null)
        compare(browse.name, "Browse subfolders")
        compare(browse.enabled, true)
        verify(!browse.checked)
        compare(browse.browseSubfolders, true)
        compare(browse.targetIndex, 0)
        compare(browse.expectedFolderText, JSON.stringify(folderContainer))

        let folderViewIndex = -1
        let sortIndex = -1
        let behaviorIndex = -1
        for (let index = 0; index < actions.length; index++) {
            if (actions[index].name === "Folder view") { folderViewIndex = index }
            if (actions[index].name === "Sort by") { sortIndex = index }
            if (actions[index].name === "Behavior") { behaviorIndex = index }
        }
        verify(folderViewIndex >= 0)
        verify(sortIndex >= 0)
        compare(behaviorIndex, folderViewIndex + 1)
        verify(behaviorIndex < sortIndex)
    }

    function test_gridLayoutOnlyOffersTheSyncChoice() {
        const gridContainer = {
            "type": "folder",
            "name": "Downloads",
            "icon": "folder-download",
            "layout": "grid",
            "sourceType": "folder",
            "sourcePath": "/home/user/Downloads",
            "apps": []
        }
        fakeDockItemsController.dockItems = [gridContainer]
        const actions = contextController.actionsForItem(
            gridContainer, [], "pinned", 0)
        const behavior = behaviorAction(actions)
        verify(behavior !== null)
        compare(behavior.children.length, 1)
        verify(actionByKind(behavior.children, "setFolderSyncFolder") !== null)
        compare(actionByKind(behavior.children, "setFolderBrowseSubfolders"), null)
    }

    function test_folderSyncToggleFreezesTheContainer() {
        fakeDockItemsController.dockItems = [folderContainer]
        const actions = contextController.actionsForItem(
            folderContainer, [], "pinned", 0)
        const behavior = behaviorAction(actions)
        const toggle = actionByKind(behavior.children, "setFolderSyncFolder")
        verify(contextController.triggerAction(toggle))
        compare(fakeDockItemsController.syncCallCount, 1)
        compare(fakeDockItemsController.lastTargetIndex, 0)
        compare(fakeDockItemsController.lastSync, false)
        compare(fakeDockItemsController.lastSyncExpectedFolderText,
            JSON.stringify(folderContainer))
    }

    function test_folderBrowseToggleKeepsTheSyncChoice() {
        fakeDockItemsController.dockItems = [folderContainer]
        const actions = contextController.actionsForItem(
            folderContainer, [], "pinned", 0)
        const behavior = behaviorAction(actions)
        const browse = actionByKind(behavior.children, "setFolderBrowseSubfolders")
        verify(contextController.triggerAction(browse))
        compare(fakeDockItemsController.browseCallCount, 1)
        compare(fakeDockItemsController.syncCallCount, 0)
        compare(fakeDockItemsController.lastTargetIndex, 0)
        compare(fakeDockItemsController.lastBrowseSubfolders, true)
        compare(fakeDockItemsController.lastBrowseExpectedFolderText,
            JSON.stringify(folderContainer))
    }

    function test_frozenFolderContainerShowsUncheckedToggle() {
        const frozen = {
            "type": "folder",
            "name": "Downloads",
            "icon": "folder-download",
            "layout": "list",
            "sourceType": "folder",
            "sourcePath": "/home/user/Downloads",
            "syncFolder": false,
            "browseSubfolders": true,
            "apps": []
        }
        fakeDockItemsController.dockItems = [frozen]
        const actions = contextController.actionsForItem(frozen, [], "pinned", 0)
        const behavior = behaviorAction(actions)
        const sync = actionByKind(behavior.children, "setFolderSyncFolder")
        verify(sync !== null)
        verify(!sync.checked)
        compare(sync.sync, true)
        // The two choices keep their own value: freezing the container does not
        // clear the stored subfolder preference.
        const browse = actionByKind(behavior.children, "setFolderBrowseSubfolders")
        verify(browse !== null)
        verify(browse.checked)
        compare(browse.browseSubfolders, false)

        verify(contextController.triggerAction(sync))
        compare(fakeDockItemsController.lastSync, true)
        compare(fakeDockItemsController.browseCallCount, 0)
    }
}
