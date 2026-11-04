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

    function contentAction(actions) {
        for (let index = 0; index < actions.length; index++) {
            // The title carries the folder name, so the lookup matches the
            // stable prefix instead of the whole text.
            if (String(actions[index].name || "").startsWith("Content")) {
                return actions[index]
            }
        }
        return null
    }

    function childByName(action, name) {
        for (let index = 0; index < action.children.length; index++) {
            if (action.children[index].name === name) {
                return action.children[index]
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

    // The content group repeats "Enable" and "Disable" for each setting, so the
    // kind and the label together identify one row.
    function actionByKindAndName(children, kind, name) {
        for (let index = 0; index < children.length; index++) {
            if (children[index].kind === kind
                    && children[index].name === name) {
                return children[index]
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

    function test_manualContainerHidesTheContentGroup() {
        const actions = contextController.actionsForItem(folder, [], "pinned", 0)
        compare(contentAction(actions), null)

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
        compare(contentAction(pathlessActions), null)
    }

    function test_folderContainerOffersContentGroupAfterSort() {
        fakeDockItemsController.dockItems = [folderContainer]
        const actions = contextController.actionsForItem(
            folderContainer, [], "pinned", 0)
        const content = contentAction(actions)
        verify(content !== null)
        compare(content.kind, "submenu")
        // Every setting below is stored per item, so the title names the folder
        // it belongs to.
        compare(content.name, "Content — Downloads")
        // A section per setting plus an exclusive Enable/Disable pair each.
        compare(content.children.length, 6)

        compare(content.children[0].kind, "section")
        compare(content.children[0].name, "Live folder contents")
        const contentOn = actionByKindAndName(
            content.children, "setFolderSyncFolder", "Enable")
        const contentOff = actionByKindAndName(
            content.children, "setFolderSyncFolder", "Disable")
        verify(contentOn !== null)
        verify(contentOff !== null)
        compare(contentOn.icon, "checkmark")
        compare(contentOff.icon, "dialog-cancel")
        verify(contentOn.checked)
        verify(!contentOff.checked)
        verify(contentOn.exclusive)
        verify(contentOff.exclusive)
        compare(contentOn.sync, false)
        compare(contentOff.sync, true)
        compare(contentOff.targetIndex, 0)
        compare(contentOff.expectedFolderText, JSON.stringify(folderContainer))

        compare(content.children[3].kind, "section")
        compare(content.children[3].name, "Navigate subfolders")
        const browseOn = actionByKindAndName(
            content.children, "setFolderBrowseSubfolders", "Enable")
        const browseOff = actionByKindAndName(
            content.children, "setFolderBrowseSubfolders", "Disable")
        verify(browseOn !== null)
        verify(browseOff !== null)
        compare(browseOn.enabled, true)
        compare(browseOn.browseSubfolders, true)
        compare(browseOff.browseSubfolders, false)
        verify(!browseOn.checked)
        verify(browseOff.checked)
        compare(browseOff.expectedFolderText, JSON.stringify(folderContainer))

        let folderViewIndex = -1
        let sortIndex = -1
        let contentIndex = -1
        for (let index = 0; index < actions.length; index++) {
            if (actions[index].name === "Folder view") { folderViewIndex = index }
            if (actions[index].name === "Sort by") { sortIndex = index }
            if (String(actions[index].name || "").startsWith("Content")) {
                contentIndex = index
            }
        }
        verify(folderViewIndex >= 0)
        verify(sortIndex >= 0)
        verify(contentIndex >= 0)
        // Presentation comes first: both content choices live in a single group
        // below the sort choice.
        verify(folderViewIndex < sortIndex)
        verify(sortIndex < contentIndex)
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
        const content = contentAction(actions)
        verify(content !== null)
        compare(content.children.length, 3)
        compare(content.children[0].kind, "section")
        verify(actionByKindAndName(
            content.children, "setFolderSyncFolder", "Enable") !== null)
        verify(actionByKindAndName(
            content.children, "setFolderSyncFolder", "Disable") !== null)
        compare(actionByKind(content.children, "setFolderBrowseSubfolders"), null)
        // Only the two layouts that can navigate offer the subfolder choice.
        compare(childByName(content, "Navigate subfolders"), null)
    }

    function test_folderSyncToggleFreezesTheContainer() {
        fakeDockItemsController.dockItems = [folderContainer]
        const actions = contextController.actionsForItem(
            folderContainer, [], "pinned", 0)
        const content = contentAction(actions)
        const toggle = actionByKindAndName(
            content.children, "setFolderSyncFolder", "Disable")
        verify(toggle !== null)
        verify(contextController.triggerAction(toggle))
        compare(fakeDockItemsController.syncCallCount, 1)
        compare(fakeDockItemsController.lastTargetIndex, 0)
        compare(fakeDockItemsController.lastSync, true)
        compare(fakeDockItemsController.lastSyncExpectedFolderText,
            JSON.stringify(folderContainer))
    }

    function test_folderBrowseToggleKeepsTheSyncChoice() {
        fakeDockItemsController.dockItems = [folderContainer]
        const actions = contextController.actionsForItem(
            folderContainer, [], "pinned", 0)
        const content = contentAction(actions)
        const browse = actionByKindAndName(
            content.children, "setFolderBrowseSubfolders", "Enable")
        verify(browse !== null)
        verify(browse.checked === false)
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
        const content = contentAction(actions)
        const contentOn = actionByKindAndName(
            content.children, "setFolderSyncFolder", "Enable")
        const contentOff = actionByKindAndName(
            content.children, "setFolderSyncFolder", "Disable")
        verify(contentOn !== null)
        verify(contentOff !== null)
        verify(!contentOn.checked)
        verify(contentOff.checked)
        // The two choices keep their own value: freezing the container does not
        // clear the stored subfolder preference, and the subfolder pair stays
        // visible but inert while the listing is frozen.
        const browseOn = actionByKindAndName(
            content.children, "setFolderBrowseSubfolders", "Enable")
        const browseOff = actionByKindAndName(
            content.children, "setFolderBrowseSubfolders", "Disable")
        verify(browseOn !== null)
        verify(browseOff !== null)
        compare(browseOn.enabled, false)
        compare(browseOff.enabled, false)
        verify(browseOn.checked)
        verify(!browseOff.checked)

        verify(contextController.triggerAction(contentOn))
        compare(fakeDockItemsController.lastSync, false)
        compare(fakeDockItemsController.browseCallCount, 0)
    }
}
