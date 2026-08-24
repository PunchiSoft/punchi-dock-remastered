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
    }

    Components.DockContextActionsController {
        id: contextController
        taskController: fakeTaskController
        dockItemsController: fakeDockItemsController
        editDockItemHandler: function() { return true }
        configureDockHandler: function() { return true }
    }

    function init() {
        failOnWarning(/.?/)
        fakeDockItemsController.dockItems = [folder]
        fakeDockItemsController.layoutCallCount = 0
        fakeDockItemsController.lastTargetIndex = -1
        fakeDockItemsController.lastLayout = ""
        fakeDockItemsController.lastExpectedFolderText = ""
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
        const submenu = actionByKind(actions, "submenu")
        verify(submenu !== null)
        compare(submenu.name, "Folder view")
        compare(submenu.detail, "List")
        compare(submenu.children.length, 3)

        const gridAction = childByLayout(submenu, "grid")
        const listAction = childByLayout(submenu, "list")
        const detailedAction = childByLayout(submenu, "detailed")
        verify(gridAction !== null)
        verify(listAction !== null)
        verify(detailedAction !== null)
        verify(!gridAction.checked)
        verify(listAction.checked)
        verify(!detailedAction.checked)
        compare(detailedAction.kind, "setFolderView")
    }

    function test_folderViewActionCarriesStableTargetIdentity() {
        const actions = contextController.actionsForItem(folder, [], "pinned", 0)
        const submenu = actionByKind(actions, "submenu")
        const detailedAction = childByLayout(submenu, "detailed")
        const expectedText = JSON.stringify(folder)

        verify(contextController.triggerAction(detailedAction))
        compare(fakeDockItemsController.layoutCallCount, 1)
        compare(fakeDockItemsController.lastTargetIndex, 0)
        compare(fakeDockItemsController.lastLayout, "detailed")
        compare(fakeDockItemsController.lastExpectedFolderText, expectedText)
    }

    function test_nonFolderPinnedItemDoesNotExposeFolderView() {
        const media = { "type": "media", "name": "Player" }
        const actions = contextController.actionsForItem(media, [], "pinned", 0)
        for (let index = 0; index < actions.length; index++) {
            verify(actions[index].name !== "Folder view")
        }
    }
}
