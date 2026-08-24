import QtQuick
import QtTest
import "../contents/ui/config/code/configItems.js" as ConfigItemsJS
import "../contents/ui/config/code/items.js" as ItemsJS
import "../contents/ui/config/code/configItemsWorkflowHelper.js" as WorkflowHelper

TestCase {
    name: "ConfigItemsDefaultLoading"

    property string cfg_dockItemsJson: ""
    property string pendingOperation: ""
    property bool diskItemsLoaded: false
    property var items: []
    property bool setItemsCalled: false
    property bool lastMarkAsChanged: true

    function setItems(nextItems, markAsChanged) {
        items = nextItems
        setItemsCalled = true
        lastMarkAsChanged = markAsChanged
    }

    function init() {
        failOnWarning(/.?/)
        cfg_dockItemsJson = ""
        pendingOperation = ""
        diskItemsLoaded = false
        items = []
        setItemsCalled = false
        lastMarkAsChanged = true
    }

    function test_missingConfigurationLoadsDefaults() {
        WorkflowHelper.loadItems()

        compare(pendingOperation, "load")
        verify(setItemsCalled)
        verify(diskItemsLoaded)
        verify(items.length > 0)
        compare(items[0].type, "punchimenu")
        compare(lastMarkAsChanged, false)
    }

    function test_explicitEmptyArrayRemainsEmpty() {
        cfg_dockItemsJson = "[]"

        WorkflowHelper.loadItems()

        verify(setItemsCalled)
        verify(diskItemsLoaded)
        compare(items.length, 0)
        compare(lastMarkAsChanged, false)
    }
}
