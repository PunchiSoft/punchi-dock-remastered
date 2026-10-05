// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase
    name: "RecentContainerContext"
    when: windowShown
    visible: true
    width: 700
    height: 800
    property bool recentEnabled: true
    property string layout: "grid"
    property int viewCalls: 0
    property int disableCalls: 0
    property var page: null

    QtObject {
        id: tasks
        function dockItemApplicationId(_item) { return "" }
        function dockItemLauncherUrl(_item) { return "" }
    }
    QtObject {
        id: items
        property var dockItems: []
        function canonicalJsonText(item) { return JSON.stringify(item) }
        function setFolderLayout(_index, _layout, _expected) {
            testCase.fail("Recent container views must not edit persistent dock items")
            return false
        }
    }
    Components.DockContextActionsController {
        id: controller
        taskController: tasks
        dockItemsController: items
        recentContainerActive: testCase.recentEnabled
        configureDockHandler: function() { return true }
        disableRecentApplicationsHandler: function() {
            testCase.recentEnabled = false
            testCase.disableCalls += 1
            return true
        }
        setRecentContainerViewHandler: function(value) {
            testCase.layout = value
            testCase.viewCalls += 1
            return true
        }
    }

    function descriptor() {
        return {type: "folder", entryRole: "recent-container", layout: testCase.layout,
            name: "Recent applications", apps: []}
    }
    function actionOfKind(actions, kind) {
        for (let index = 0; index < actions.length; index++) {
            if (actions[index].kind === kind) { return actions[index] }
        }
        return null
    }
    function init() {
        failOnWarning(/.?/)
        recentEnabled = true
        layout = "grid"
        viewCalls = 0
        disableCalls = 0
        page = recentGeneralTestSupport.createPage(testCase)
        verify(page !== null)
        const tabs = findChild(page, "generalTabs")
        verify(tabs !== null)
        tabs.currentIndex = 1
        verify(waitForPolish(page))
    }
    function cleanup() { recentGeneralTestSupport.destroyPage(page) }
    function test_defaultsAndSettingsStayReactive() {
        const view = findChild(page, "recentApplicationsContainerLayoutCombo")
        const mode = findChild(page, "recentApplicationsModeCombo")
        compare(page.cfg_showRecentApplications, true)
        compare(page.cfg_recentApplicationsMode, "container")
        compare(page.cfg_recentApplicationsContainerLayout, "fan")
        compare(page.cfg_recentApplicationsCount, 5)
        verify(view.enabled)
        verify(view.visible)
        compare(view.count, 4)
        verify(view.activeFocusOnTab)
        verify(String(view.Accessible.name).length > 0)
        const values = ["grid", "list", "detailed", "fan"]
        for (let index = 0; index < values.length; index++) {
            view.activated(index)
            compare(page.cfg_recentApplicationsContainerLayout, values[index])
            compare(view.currentValue, values[index])
        }
        page.cfg_recentApplicationsContainerLayout = "list"
        compare(view.currentValue, "list")
        page.cfg_recentApplicationsMode = "inline"
        compare(view.enabled, false)
        compare(mode.currentValue, "inline")
        page.cfg_recentApplicationsMode = "container"
        page.cfg_showRecentApplications = false
        compare(view.enabled, false)
        compare(view.visible, true)
        compare(mode.visible, true)
        compare(findChild(page, "recentApplicationsCountSpin").visible, true)
        compare(page.cfg_recentApplicationsContainerLayout, "list")
        page.cfg_showRecentApplications = true
        compare(view.enabled, true)
        verify(view.visible && mode.visible)
    }
    function test_menuExposesOnlyRecentOperationsAndOneCheckedView() {
        const values = ["grid", "list", "detailed", "fan"]
        for (let current = 0; current < values.length; current++) {
            layout = values[current]
            verify(controller.itemHasContextMenu(descriptor(), [], "recent-container"))
            const actions = controller.actionsForItem(descriptor(), [], "recent-container", -1)
            const view = actionOfKind(actions, "submenu")
            verify(view !== null)
            compare(view.name, "Container view")
            compare(view.children.length, 4)
            verify(actionOfKind(actions, "disableRecentApplications") !== null)
            compare(actionOfKind(actions, "unpinFromDock"), null)
            compare(actionOfKind(actions, "pinToDock"), null)
            compare(actionOfKind(actions, "editDockItem"), null)
            for (let index = 0; index < values.length; index++) {
                const child = view.children[index]
                compare(child.kind, "setRecentContainerView")
                compare(child.layout, values[index])
                compare(child.checked, values[index] === layout)
                compare(child.targetIndex, undefined)
                compare(child.expectedFolderText, undefined)
            }
        }
    }
    function test_actionsRouteToRecentHandlersAndRejectStaleOrInvalidViews() {
        const actions = controller.actionsForItem(descriptor(), [], "recent-container", -1)
        const view = actionOfKind(actions, "submenu")
        for (let index = 0; index < view.children.length; index++) {
            verify(controller.triggerAction(view.children[index]))
            compare(layout, view.children[index].layout)
        }
        compare(viewCalls, 4)
        verify(!controller.triggerAction({kind: "setRecentContainerView", layout: "invalid"}))
        compare(viewCalls, 4)
        verify(controller.triggerAction(actionOfKind(actions, "disableRecentApplications")))
        compare(disableCalls, 1)
        compare(recentEnabled, false)
        verify(!controller.itemHasContextMenu(descriptor(), [], "recent-container"))
        compare(controller.actionsForItem(descriptor(), [], "recent-container", -1).length, 0)
        verify(!controller.triggerAction(view.children[0]))
        verify(!controller.triggerAction(actionOfKind(actions, "disableRecentApplications")))
        compare(viewCalls, 4)
        compare(items.dockItems.length, 0)
    }
    function test_pinnedFolderRetainsItsPersistentViewContract() {
        const folder = {type: "folder", name: "Pinned", layout: "fan", apps: []}
        const actions = controller.actionsForItem(folder, [], "pinned", 0)
        const view = actionOfKind(actions, "submenu")
        compare(actionOfKind(actions, "disableRecentApplications"), null)
        verify(actionOfKind(actions, "unpinFromDock") !== null)
        compare(view.children[3].kind, "setFolderView")
        compare(view.children[3].targetIndex, 0)
        compare(view.children[3].expectedFolderText, JSON.stringify(folder))
        verify(view.children[3].checked)
    }
}
