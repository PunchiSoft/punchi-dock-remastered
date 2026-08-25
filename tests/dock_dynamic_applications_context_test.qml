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
    }

    Components.DockContextActionsController {
        id: contextController
        taskController: fakeTaskController
        dockItemsController: fakeDockItemsController
        showConfigureDockAction: false
        property int moveRequestCount: 0
        moveDynamicApplicationsHandler: function() {
            moveRequestCount++
            return true
        }
    }

    function init() {
        failOnWarning(/.?/)
        contextController.moveRequestCount = 0
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
