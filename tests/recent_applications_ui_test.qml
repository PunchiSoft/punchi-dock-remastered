import QtQuick
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase
    name: "RecentApplicationsUi"
    when: windowShown
    visible: true
    width: 640
    height: 800

    property var page: null
    function initTestCase() {
        page = recentGeneralTestSupport.createPage(testCase)
        verify(page !== null)
        page.width = 600
        page.height = 760
    }
    function cleanupTestCase() { recentGeneralTestSupport.destroyPage(page) }
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
        page.cfg_recentApplicationsCount = 3
        page.cfg_recentApplicationsContainerLayout = "grid"
        geometry.supplementalDockItems = []
        geometry.horizontalPanel = true
        geometry.verticalPanel = false
        geometry.dockItems = [{ "type": "app" }]
        geometry.visibleTaskCount = 2
        geometry.overflowTaskCount = 1
        const tabs = findChild(page, "generalTabs")
        verify(tabs !== null)
        tabs.currentIndex = 1
        verify(waitForPolish(page))
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
    function test_switchTogglesAvailabilityAndPreservesValues() {
        const toggle = findChild(page, "showRecentApplicationsSwitch")
        const mode = findChild(page, "recentApplicationsModeCombo")
        const count = findChild(page, "recentApplicationsCountSpin")
        const view = findChild(page, "recentApplicationsContainerLayoutCombo")
        verify(recentGeneralTestSupport.isSwitch(toggle), String(toggle))
        verify(toggle.activeFocusOnTab)
        verify(String(toggle.Accessible.name).length > 0)
        verify(mode.visible && count.visible && view.visible)
        verify(!mode.enabled && !count.enabled && !view.enabled)
        page.cfg_recentApplicationsCount = 7
        page.cfg_recentApplicationsContainerLayout = "fan"
        verify(waitForPolish(page))
        mouseClick(toggle, toggle.width / 2, toggle.height / 2)
        compare(page.cfg_showRecentApplications, true)
        verify(mode.enabled && count.enabled)
        compare(view.enabled, false)
        page.cfg_recentApplicationsMode = "container"
        compare(view.enabled, true)
        toggle.forceActiveFocus()
        tryCompare(toggle, "activeFocus", true)
        keyClick(Qt.Key_Space)
        compare(page.cfg_showRecentApplications, false)
        verify(mode.visible && count.visible && view.visible)
        verify(!mode.enabled && !count.enabled && !view.enabled)
        compare(page.cfg_recentApplicationsCount, 7)
        compare(page.cfg_recentApplicationsContainerLayout, "fan")
        keyClick(Qt.Key_Space)
        compare(page.cfg_showRecentApplications, true)
        verify(mode.enabled && count.enabled && view.enabled)
        compare(count.value, 7)
        compare(view.currentValue, "fan")
    }
    function test_windowsNoLongerOwnsRecentOptions() {
        const windows = Qt.createComponent("../contents/ui/config/ConfigWindows.qml")
        compare(windows.status, Component.Ready)
        const oldPage = createTemporaryObject(windows, testCase)
        verify(oldPage !== null)
        for (const name of ["cfg_showRecentApplications", "cfg_recentApplicationsCount",
                "cfg_recentApplicationsMode", "cfg_recentApplicationsContainerLayout"]) {
            verify(!oldPage.hasOwnProperty(name))
        }
        compare(findChild(oldPage, "showRecentApplicationsCheck"), null)
        compare(findChild(oldPage, "recentApplicationsModeCombo"), null)
        compare(findChild(oldPage, "recentApplicationsCountSpin"), null)
        compare(findChild(oldPage, "recentApplicationsContainerLayoutCombo"), null)
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
