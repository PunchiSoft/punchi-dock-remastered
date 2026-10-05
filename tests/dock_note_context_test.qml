import QtQuick
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase
    name: "DockNoteContext"

    property var note: ({ type: "note", name: "Welcome note", note: "Fixture text" })

    QtObject {
        id: taskController
        function dockItemApplicationId() { return "" }
        function dockItemLauncherUrl() { return "" }
    }

    QtObject {
        id: itemsController
        property int unpinCalls: 0
        property int targetIndex: -1
        property string applicationId: ""
        property string launcherUrl: ""
        function unpinItemFromDock(index, expectedApplicationId, expectedLauncherUrl) {
            unpinCalls++
            targetIndex = index
            applicationId = expectedApplicationId
            launcherUrl = expectedLauncherUrl
            return index === 2
        }
    }

    Components.DockContextActionsController {
        id: controller
        taskController: taskController
        dockItemsController: itemsController
        showConfigureDockAction: false
    }

    function init() {
        failOnWarning(/.?/)
        itemsController.unpinCalls = 0
        itemsController.targetIndex = -1
    }

    function test_pinnedNoteOffersUnpinWithoutConfigureAction() {
        verify(controller.itemHasContextMenu(note, [], "pinned"))
        const actions = controller.actionsForItem(note, [], "pinned", 2)
        compare(actions.length, 1)
        compare(actions[0].kind, "unpinFromDock")
        compare(actions[0].name, "Unpin from Dock")
        verify(actions[0].enabled)
        verify(controller.triggerAction(actions[0]))
        compare(itemsController.unpinCalls, 1)
        compare(itemsController.targetIndex, 2)
        compare(itemsController.applicationId, "")
        compare(itemsController.launcherUrl, "")
        compare(note.note, "Fixture text")
    }

    function test_nonPinnedNoteDoesNotOfferUnpin() {
        verify(!controller.itemHasContextMenu(note, [], "folder"))
        compare(controller.actionsForItem(note, [], "folder", -1).length, 0)
    }

    function test_disabledActionDoesNotRemoveNote() {
        const action = controller.actionsForItem(note, [], "pinned", 2)[0]
        action.enabled = false
        verify(!controller.triggerAction(action))
        compare(itemsController.unpinCalls, 0)
    }
}
