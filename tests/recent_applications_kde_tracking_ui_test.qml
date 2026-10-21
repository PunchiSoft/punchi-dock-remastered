import QtQuick
import QtTest

TestCase {
    id: testCase
    name: "RecentApplicationsKdeTrackingUi"
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
    function init() {
        failOnWarning(/.?/)
        page.cfg_showRecentApplications = true
        const tabs = findChild(page, "generalTabs")
        verify(tabs !== null)
        tabs.currentIndex = 1
        const tracking = findChild(page, "recentApplicationsTrackingAdapter")
        verify(tracking !== null)
        verify(tracking.setTrackingEnabled(true))
        compare(tracking.trackingEnabled, true)
        verify(waitForPolish(page))
    }
    function test_switchWritesTheKdePreference() {
        const toggle = findChild(page, "rememberApplicationsTrackingSwitch")
        const tracking = findChild(page, "recentApplicationsTrackingAdapter")
        verify(toggle !== null)
        verify(recentGeneralTestSupport.isSwitch(toggle), String(toggle))
        verify(toggle.activeFocusOnTab)
        verify(String(toggle.Accessible.name).length > 0)
        compare(toggle.checked, true)
        mouseClick(toggle, toggle.width / 2, toggle.height / 2)
        compare(tracking.trackingEnabled, false)
        compare(toggle.checked, false)
        compare(page.cfg_showRecentApplications, true)
        toggle.forceActiveFocus()
        tryCompare(toggle, "activeFocus", true)
        keyClick(Qt.Key_Space)
        compare(tracking.trackingEnabled, true)
        compare(toggle.checked, true)
    }
    function test_switchFollowsKdeStateAfterTheGesture() {
        const toggle = findChild(page, "rememberApplicationsTrackingSwitch")
        const tracking = findChild(page, "recentApplicationsTrackingAdapter")
        compare(toggle.checked, true)
        mouseClick(toggle, toggle.width / 2, toggle.height / 2)
        compare(tracking.trackingEnabled, false)
        // The gesture breaks the declarative binding, so an external change must
        // still reach the control.
        verify(tracking.setTrackingEnabled(true))
        tryCompare(toggle, "checked", true)
    }
    function test_kdePreferenceIsIndependentFromDockVisibility() {
        const toggle = findChild(page, "rememberApplicationsTrackingSwitch")
        const button = findChild(page, "openKdeRecentFilesSettingsButton")
        page.cfg_showRecentApplications = false
        verify(waitForPolish(page))
        verify(toggle.enabled)
        compare(toggle.checked, true)
        verify(button !== null)
        verify(button.enabled)
        verify(button.activeFocusOnTab)
        verify(String(button.text).length > 0)
        verify(String(button.Accessible.name).length > 0)
    }
}
