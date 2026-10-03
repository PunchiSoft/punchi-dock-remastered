import QtQuick
import QtTest
import "../contents/ui/config" as ConfigPages
import "../contents/ui/components" as Components

TestCase {
    id: testCase
    name: "RecentApplicationsUi"
    when: windowShown
    width: 640
    height: 800

    ConfigPages.ConfigWindows { id: page; width: 600; height: 760 }
    Components.DockGeometryState {
        id: geometry
        inPanel: true
        horizontalPanel: true
        configuredIconSize: 48
        dockItems: [{ "type": "app" }]
        visibleTaskCount: 2
        overflowTaskCount: 1
    }
    Components.DockContextActionsController {
        id: actions
        taskController: fakeTasks
        moveDynamicApplicationsHandler: function() { fail("A recent item must not move dynamic applications") }
    }
    QtObject {
        id: fakeTasks
        function pinDescriptorForEntry(item) { return { "type": "app", "storageId": item.storageId } }
        function dockContainsPinDescriptor(_item) { return false }
        function contextActionsForRows(_rows) { return [] }
        function applicationContextActions(_item, _rows) { return [] }
    }
    function init() {
        failOnWarning(/.?/)
        page.cfg_showRecentApplications = false
        page.cfg_recentApplicationsMode = "inline"
        geometry.supplementalDockItems = []
        geometry.horizontalPanel = true
        geometry.verticalPanel = false
        geometry.dockItems = [{ "type": "app" }]
        geometry.visibleTaskCount = 2
        geometry.overflowTaskCount = 1
    }
    function test_settingsAreReactiveAndKeyboardAccessible() {
        const combo = findChild(page, "recentApplicationsModeCombo")
        verify(combo !== null)
        compare(combo.enabled, false)
        compare(combo.currentValue, "inline")
        page.cfg_showRecentApplications = true
        compare(combo.enabled, true)
        page.cfg_recentApplicationsMode = "container"
        compare(combo.currentValue, "container")
        combo.activated(0)
        compare(page.cfg_recentApplicationsMode, "inline")
        verify(combo.activeFocusOnTab)
        verify(String(combo.Accessible.name).length > 0)
    }
    function test_recentGeometryDoesNotReduceDynamicCapacity() {
        const fixedLength = geometry.panelFixedContentLength
        const baseLength = geometry.panelBaseCompactContentLength
        geometry.supplementalDockItems = [{ "type": "separator" }, { "type": "app" }, { "type": "app" }]
        compare(geometry.panelFixedContentLength, fixedLength)
        compare(geometry.panelBaseCompactContentLength, baseLength)
        verify(geometry.panelCompactContentLength > baseLength)
        geometry.horizontalPanel = false
        geometry.verticalPanel = true
        verify(geometry.supplementalContentLength > 0)
        geometry.supplementalDockItems = []
        compare(geometry.panelCompactContentLength, geometry.panelBaseCompactContentLength)
    }
    function test_recentContextMenuOffersExplicitPinNotPersistentEdit() {
        const candidates = actions.actionsForItem({ "type": "app", "entryRole": "recent", "storageId": "org.example.App.desktop" }, [], "recent", -1)
        verify(candidates.some(function(action) { return action.kind === "pinToDock" }))
        verify(!candidates.some(function(action) { return action.kind === "moveDynamicApplications" || action.kind === "editDockItem" || action.kind === "removeDockItem" }))
    }
    function test_hiddenDynamicMarkerDoesNotAddASupplementalBoundaryGap() {
        geometry.dockItems = [{ "type": "dynamic-applications", "showSeparator": false }]
        geometry.visibleTaskCount = 0
        geometry.overflowTaskCount = 0
        geometry.supplementalDockItems = [{ "type": "app" }, { "type": "app" }]
        compare(geometry.panelBaseCompactContentLength, 0)
        compare(geometry.supplementalContentLength, geometry.panelItemWidth * 2 + geometry.dockSpacing)
    }
}
