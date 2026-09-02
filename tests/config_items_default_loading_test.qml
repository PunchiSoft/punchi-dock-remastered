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
    property int selectedIndex: -1
    property int pendingRemovalIndex: -1
    property bool cfg_showActiveTasks: true
    property string defaultTrashEmptySound: ""
    property string selectedItemType: "app"

    QtObject {
        id: dynamicApplicationsRemovalDialog
        property int openCount: 0
        function open() { openCount += 1 }
    }

    QtObject {
        id: controlCenterDialog
        property string controlCenterMode: "fullScreen"
        property int openCount: 0
        function open() { openCount += 1 }
    }

    function selectedItem() {
        return selectedIndex >= 0 && selectedIndex < items.length
            ? items[selectedIndex] : null
    }

    function clone(value) {
        return JSON.parse(JSON.stringify(value))
    }

    function hasItemType(type) {
        return items.some(function(item) { return item.type === type })
    }

    function setItems(nextItems, markAsChanged) {
        items = nextItems
        setItemsCalled = true
        lastMarkAsChanged = markAsChanged === undefined ? true : markAsChanged
    }

    function init() {
        failOnWarning(/.?/)
        cfg_dockItemsJson = ""
        pendingOperation = ""
        diskItemsLoaded = false
        items = []
        setItemsCalled = false
        lastMarkAsChanged = true
        selectedIndex = -1
        pendingRemovalIndex = -1
        cfg_showActiveTasks = true
        selectedItemType = "app"
        dynamicApplicationsRemovalDialog.openCount = 0
        controlCenterDialog.controlCenterMode = "fullScreen"
        controlCenterDialog.openCount = 0
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

    function test_removingMarkerWaitsForConfirmationThenDisablesTasks() {
        items = [
            { "type": "dynamic-applications" },
            { "type": "app", "name": "Pinned" }
        ]
        selectedIndex = 0

        WorkflowHelper.removeSelectedItem()

        compare(dynamicApplicationsRemovalDialog.openCount, 1)
        compare(pendingRemovalIndex, 0)
        compare(items.length, 2)
        verify(cfg_showActiveTasks)

        WorkflowHelper.confirmDynamicApplicationsRemoval()

        compare(pendingRemovalIndex, -1)
        compare(items.length, 1)
        compare(items[0].type, "app")
        verify(!cfg_showActiveTasks)
    }

    function test_removingRegularItemDoesNotDisableTasks() {
        items = [{ "type": "app", "name": "Pinned" }]
        selectedIndex = 0

        WorkflowHelper.removeSelectedItem()

        compare(dynamicApplicationsRemovalDialog.openCount, 0)
        compare(items.length, 0)
        verify(cfg_showActiveTasks)
    }

    function test_addingMarkerEnablesActiveTasks() {
        items = []
        cfg_showActiveTasks = false

        WorkflowHelper.addItem("dynamic-applications")

        compare(items.length, 1)
        compare(items[0].type, "dynamic-applications")
        verify(cfg_showActiveTasks)
    }

    function test_addingControlCenterCreatesCanonicalSingletonItem() {
        items = []

        WorkflowHelper.addItem("control-center")

        compare(items.length, 1)
        compare(items[0].type, "control-center")
        compare(items[0].name, "Control Center")
        compare(items[0].icon, "preferences-system")
        compare(items[0].controlCenterMode, "fullScreen")
        selectedItemType = items[0].type
        verify(WorkflowHelper.canConfigureSelectedItem())
    }

    function test_controlCenterModeIsClosedAndPersistent() {
        items = [{
            "type": "control-center",
            "name": "Control Center",
            "icon": "preferences-system"
        }]
        selectedIndex = 0
        selectedItemType = "control-center"

        WorkflowHelper.openControlCenterDialog()

        compare(controlCenterDialog.openCount, 1)
        compare(controlCenterDialog.controlCenterMode, "fullScreen")

        WorkflowHelper.setControlCenterMode("floating")
        compare(items[0].controlCenterMode, "floating")
        compare(controlCenterDialog.controlCenterMode, "floating")

        WorkflowHelper.setControlCenterMode("unsupported")
        compare(items[0].controlCenterMode, "fullScreen")
        compare(controlCenterDialog.controlCenterMode, "fullScreen")
    }
}
