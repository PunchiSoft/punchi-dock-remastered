// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest

TestCase {
    id: testCase
    name: "RecentApplicationsCountUi"
    when: windowShown
    visible: true
    width: 700
    height: 800
    property var page: null
    function initTestCase() {
        page = recentGeneralTestSupport.createPage(testCase)
        verify(page !== null)
    }
    function cleanupTestCase() { recentGeneralTestSupport.destroyPage(page) }
    function init() {
        failOnWarning(/.?/)
        page.cfg_showRecentApplications = true
        page.cfg_recentApplicationsCount = 3
        page.cfg_recentApplicationsMode = "container"
        const tabs = findChild(page, "generalTabs")
        verify(tabs !== null)
        tabs.currentIndex = 1
        verify(waitForPolish(page))
    }
    function test_default_and_two_way_control() {
        const spin = findChild(page, "recentApplicationsCountSpin")
        verify(spin !== null)
        verify(spin.visible)
        compare(spin.value, 3)
        compare(spin.from, 1)
        compare(spin.to, 20)
        spin.increase()
        compare(page.cfg_recentApplicationsCount, 4)
        page.cfg_recentApplicationsCount = 12
        compare(spin.value, 12)
        verify(spin.activeFocusOnTab)
        verify(String(spin.Accessible.name).length > 0)
    }
    function test_modes_and_disable_preserve_quantity() {
        const spin = findChild(page, "recentApplicationsCountSpin")
        page.cfg_recentApplicationsCount = 9
        page.cfg_recentApplicationsMode = "inline"
        compare(spin.enabled, true)
        compare(spin.value, 9)
        page.cfg_recentApplicationsMode = "container"
        for (const layout of ["grid", "list", "detailed", "fan"]) {
            page.cfg_recentApplicationsContainerLayout = layout
            compare(spin.value, 9)
            verify(spin.enabled)
        }
        page.cfg_showRecentApplications = false
        compare(spin.enabled, false)
        compare(spin.visible, true)
        compare(spin.value, 9)
        page.cfg_showRecentApplications = true
        compare(spin.enabled, true)
        compare(spin.visible, true)
        compare(spin.value, 9)
    }
}
