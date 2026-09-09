import QtQuick
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase

    name: "DockDynamicApplicationsContext"

    QtObject {
        id: fakeTaskController

        function pinDescriptorForEntry() { return null }
        function contextActionsForRows() { return [] }
    }

    QtObject {
        id: fakeDockItemsController
        property var dockItems: []
        property string selectedMode: ""
        function setControlCenterMode(mode) {
            selectedMode = mode
            return true
        }
    }

    Components.DockContextActionsController {
        id: contextController
        taskController: fakeTaskController
        dockItemsController: fakeDockItemsController
        showConfigureDockAction: false
        property int moveRequestCount: 0
        property int configureRequestCount: 0
        configureDockHandler: function() {
            configureRequestCount++
            return true
        }
        moveDynamicApplicationsHandler: function() {
            moveRequestCount++
            return true
        }
    }

    function init() {
        failOnWarning(/.?/)
        contextController.moveRequestCount = 0
        contextController.configureRequestCount = 0
        contextController.showConfigureDockAction = false
        fakeDockItemsController.dockItems = []
        fakeDockItemsController.selectedMode = ""
    }

    function test_controlCenterOffersModesAndConfiguration() {
        const item = { "type": "control-center" }
        fakeDockItemsController.dockItems = [item]
        verify(contextController.itemHasContextMenu(item, [], "pinned"))
        let actions = contextController.actionsForItem(item, [], "pinned", 0)
        compare(actions.length, 1)
        compare(actions[0].kind, "submenu")
        compare(actions[0].children.length, 2)
        compare(actions[0].children[0].checked, true)
        compare(actions[0].children[1].checked, false)
        verify(contextController.triggerAction(actions[0].children[1]))
        compare(fakeDockItemsController.selectedMode, "fullScreen")

        item.controlCenterMode = "fullScreen"
        contextController.showConfigureDockAction = true
        actions = contextController.actionsForItem(item, [], "pinned", 0)
        compare(actions[0].children[0].checked, false)
        compare(actions[0].children[1].checked, true)
        verify(contextController.triggerAction(actions[0].children[0]))
        compare(fakeDockItemsController.selectedMode, "floating")
        compare(actions[1].kind, "configureDock")
        verify(contextController.triggerAction(actions[1]))
        compare(contextController.configureRequestCount, 1)

        fakeDockItemsController.dockItems = [{ "type": "app" }]
        verify(!contextController.triggerAction(actions[0].children[1]))
        fakeDockItemsController.dockItems = []
        verify(!contextController.triggerAction(actions[0].children[0]))
    }

    function test_dynamicTaskOffersAndTriggersSectionMove() {
        const task = { "type": "app", "name": "Example" }
        const actions = contextController.actionsForItem(
            task, [], "dynamic", -1)

        compare(actions.length, 1)
        compare(actions[0].kind, "moveDynamicApplications")
        compare(actions[0].name, "Move open applications section")
        compare(actions[0].icon, "transform-move")
        verify(contextController.itemHasContextMenu(task, [], "dynamic"))
        verify(contextController.triggerAction(actions[0]))
        compare(contextController.moveRequestCount, 1)
    }
}
