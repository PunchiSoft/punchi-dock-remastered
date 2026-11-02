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

    function test_manualContainerHidesTheFolderSyncToggle() {
        const actions = contextController.actionsForItem(folder, [], "pinned", 0)
        compare(actionByKind(actions, "setFolderSyncFolder"), null)

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
        compare(actionByKind(pathlessActions, "setFolderSyncFolder"), null)
    }

    function test_folderContainerOffersCheckedSyncToggleAfterFolderView() {
        fakeDockItemsController.dockItems = [folderContainer]
        const actions = contextController.actionsForItem(
            folderContainer, [], "pinned", 0)
        const toggle = actionByKind(actions, "setFolderSyncFolder")
        verify(toggle !== null)
        compare(toggle.name, "Live folder contents")
        compare(toggle.enabled, true)
        verify(toggle.checked)
        compare(toggle.sync, false)
        compare(toggle.targetIndex, 0)
        compare(toggle.expectedFolderText, JSON.stringify(folderContainer))

        let folderViewIndex = -1
        let sortIndex = -1
        let toggleIndex = -1
        for (let index = 0; index < actions.length; index++) {
            if (actions[index].name === "Folder view") { folderViewIndex = index }
            if (actions[index].name === "Sort by") { sortIndex = index }
            if (actions[index].kind === "setFolderSyncFolder") { toggleIndex = index }
        }
        verify(folderViewIndex >= 0)
        verify(sortIndex >= 0)
        compare(toggleIndex, folderViewIndex + 1)
        verify(toggleIndex < sortIndex)
    }

    function test_folderSyncToggleFreezesTheContainer() {
        fakeDockItemsController.dockItems = [folderContainer]
        const actions = contextController.actionsForItem(
            folderContainer, [], "pinned", 0)
        const toggle = actionByKind(actions, "setFolderSyncFolder")
        verify(contextController.triggerAction(toggle))
        compare(fakeDockItemsController.syncCallCount, 1)
        compare(fakeDockItemsController.lastTargetIndex, 0)
        compare(fakeDockItemsController.lastSync, false)
        compare(fakeDockItemsController.lastSyncExpectedFolderText,
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
            "apps": []
        }
        fakeDockItemsController.dockItems = [frozen]
        const actions = contextController.actionsForItem(frozen, [], "pinned", 0)
        const toggle = actionByKind(actions, "setFolderSyncFolder")
        verify(toggle !== null)
        verify(!toggle.checked)
        compare(toggle.sync, true)
        verify(contextController.triggerAction(toggle))
        compare(fakeDockItemsController.lastSync, true)
    }
}
