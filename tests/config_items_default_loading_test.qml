import QtQuick
import QtTest
import "../contents/ui/config/code/configItemsController.js" as ConfigItemsControllerJS
import "../contents/ui/config/code/configItems.js" as ConfigItemsJS
import "../contents/ui/config/code/items.js" as ItemsJS
import "../contents/ui/config/code/configItemsWorkflowHelper.js" as WorkflowHelper
import "../contents/ui/config/code/configItemsStateHelper.js" as StateHelper
import "fixtures/config_items_selection_form_stub.js" as FormHelper

TestCase {
    id: testCase
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
    property bool syncing: false
    property int selectedActionIndex: -1
    property var selectionRefreshes: []
    property string failingSelectionPhase: ""
    property int selectionEditCount: 0

    onSelectedIndexChanged: {
        if (!syncing) {
            selectionEditCount += 1
        }
    }

    QtObject {
        id: mainView
        property int lastPosition: -1
        property int positionCount: 0
        function positionAtIndex(index) {
            lastPosition = index
            positionCount += 1
        }
    }

    function recordSelectionRefresh(phase) {
        selectionRefreshes = selectionRefreshes.concat([{phase: phase, guarded: syncing}])
        if (!syncing) {
            selectionEditCount += 1
            cfg_dockItemsJson = "unexpected edit"
        }
        if (failingSelectionPhase === phase) {
            throw new Error("Selection refresh failed")
        }
    }

    QtObject {
        id: dynamicApplicationsRemovalDialog
        property int openCount: 0
        function open() { openCount += 1 }
    }

    QtObject {
        id: controlCenterDialog
        property string controlCenterMode: "floating"
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
        controlCenterDialog.controlCenterMode = "floating"
        controlCenterDialog.openCount = 0
        syncing = false
        selectedActionIndex = -1
        selectionRefreshes = []
        failingSelectionPhase = ""
        selectionEditCount = 0
        mainView.lastPosition = -1
        mainView.positionCount = 0
    }

    function test_selectionLoadsWithoutChangingConfiguration() {
        items = [{type: "calendar", timeTextScale: 1.35},
            {type: "app", name: "Pinned"}, {type: "folder", apps: []},
            {type: "trash"}, {type: "clock", textScale: 1.2}]
        const before = JSON.stringify(items)
        cfg_dockItemsJson = before
        const indices = [0, 1, 2, 3, 4, 0, 0, -1]
        for (let index = 0; index < indices.length; ++index) {
            selectedActionIndex = 2
            StateHelper.selectItem(indices[index])
            compare(selectedIndex, indices[index])
            compare(selectedActionIndex, -1)
            compare(syncing, false)
            compare(cfg_dockItemsJson, before)
            compare(JSON.stringify(items), before)
            compare(selectionEditCount, 0,
                "Selection bindings and form loading must not announce edits")
        }
        compare(selectionRefreshes.length, indices.length * 2)
        for (let index = 0; index < selectionRefreshes.length; ++index) {
            compare(selectionRefreshes[index].guarded, true)
            compare(selectionRefreshes[index].phase, index % 2 === 0 ? "form" : "actions")
        }
        compare(mainView.lastPosition, 0)
        compare(mainView.positionCount, indices.length - 1)
    }

    function test_selectionRestoresOuterSynchronization() {
        syncing = true
        StateHelper.selectItem(0)
        compare(syncing, true, "An outer synchronization must remain active")
        compare(selectionEditCount, 0)
        compare(mainView.lastPosition, 0)
    }

    function test_selectionRestoresSynchronizationAfterFailure_data() {
        return [{tag: "form-editable", phase: "form", outer: false},
            {tag: "form-syncing", phase: "form", outer: true},
            {tag: "actions-editable", phase: "actions", outer: false},
            {tag: "actions-syncing", phase: "actions", outer: true}]
    }

    function test_selectionRestoresSynchronizationAfterFailure(data) {
        syncing = data.outer
        failingSelectionPhase = data.phase
        let caught = false
        try {
            StateHelper.selectItem(0)
        } catch (error) {
            compare(error.message, "Selection refresh failed")
            caught = true
        }
        verify(caught, "The refresh failure must propagate")
        compare(syncing, data.outer, "Failure must restore the previous guard")
        compare(selectionEditCount, 0)
        compare(mainView.positionCount, 0)
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

    function test_itemSelectionNormalizationPreservesNoSelectionOnLoad() {
        compare(ConfigItemsControllerJS.normalizedItemSelectionIndex(-1, 3), -1)
        compare(ConfigItemsControllerJS.normalizedItemSelectionIndex(-2, 3), -1)
        compare(ConfigItemsControllerJS.normalizedItemSelectionIndex(0, 0), -1)
    }

    function test_itemSelectionNormalizationPreservesAndBoundsExplicitSelection() {
        compare(ConfigItemsControllerJS.normalizedItemSelectionIndex(1, 3), 1)
        compare(ConfigItemsControllerJS.normalizedItemSelectionIndex(8, 3), 2)
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

    function test_markerAdditionImpactEnablesActiveTasksAfterCommit() {
        const impact = ConfigItemsJS.itemAdditionImpact(
            "dynamic-applications")
        verify(impact.enableActiveTasks)
        verify(!ConfigItemsJS.itemAdditionImpact("app").enableActiveTasks)
    }

    function test_newControlCenterIsCanonicalBeforeCommit() {
        const item = ConfigItemsJS.newItem("control-center", "")
        compare(item.type, "control-center")
        compare(item.name, "Control Center")
        compare(item.icon, "preferences-system")
        compare(item.controlCenterMode, "floating")
        items = [item]
        selectedIndex = 0
        selectedItemType = item.type
        verify(WorkflowHelper.canConfigureSelectedItem())
    }

    function test_actionPopupRowOverrideIsNormalizedForApplications() {
        const app = {
            "type": "app",
            "actionPopupMaxVisibleRows": 32
        }

        ConfigItemsJS.pruneApp(app)

        compare(app.actionPopupMaxVisibleRows, 12)
        app.actionPopupMaxVisibleRows = "invalid"
        ConfigItemsJS.pruneApp(app)
        verify(app.actionPopupMaxVisibleRows === undefined)
    }

    function test_actionPopupRowOverrideIsRemovedFromNonApplications() {
        const folder = {
            "type": "folder",
            "actionPopupMaxVisibleRows": 5,
            "apps": []
        }

        ConfigItemsJS.pruneFolder(folder)

        verify(folder.actionPopupMaxVisibleRows === undefined)
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
        compare(controlCenterDialog.controlCenterMode, "floating")

        WorkflowHelper.setControlCenterMode("floating")
        compare(items[0].controlCenterMode, "floating")
        compare(controlCenterDialog.controlCenterMode, "floating")

        WorkflowHelper.setControlCenterMode("fullScreen")
        compare(items[0].controlCenterMode, "fullScreen")
        WorkflowHelper.openControlCenterDialog()
        compare(controlCenterDialog.controlCenterMode, "fullScreen")

        WorkflowHelper.setControlCenterMode("unsupported")
        compare(items[0].controlCenterMode, "floating")
        compare(controlCenterDialog.controlCenterMode, "floating")
    }
}
