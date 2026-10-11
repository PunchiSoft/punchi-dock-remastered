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

    function test_separatorControlsAreReactiveAndPreserved() {
        const settings = findChild(page, "recentApplicationsSeparatorSettings")
        const show = findChild(settings, "recentApplicationsSeparatorVisibleSwitch")
        const options = findChild(settings, "recentApplicationsSeparatorOptions")
        const custom = findChild(options, "separatorAppearanceControls")
        const appearance = findChild(options, "separatorAppearanceSourceCombo")
        const view = findChild(page, "recentApplicationsContainerLayoutCombo")
        verify(settings !== null && show !== null && options !== null)
        verify(custom !== null && appearance !== null && view !== null)
        page.cfg_recentApplicationsShowSeparator = true
        page.cfg_recentApplicationsSeparatorAppearanceSource = "theme"
        verify(recentGeneralTestSupport.isSwitch(show), String(show))
        verify(show.activeFocusOnTab)
        verify(String(show.Accessible.name).length > 0)
        verify(waitForPolish(page))
        verify(settings.mapToItem(page, 0, 0).y >= view.mapToItem(page, 0, view.height).y)
        verify(show.visible && options.visible)
        verify(appearance.visible && !custom.visible)
        const themeHeight = settings.height
        page.cfg_recentApplicationsShowSeparator = false
        verify(!show.checked && !options.enabled && !options.visible)
        verify(!appearance.visible && !custom.visible)
        verify(waitForPolish(page))
        tryVerify(function() { return settings.height < themeHeight }, 1000,
            "The hidden options must release layout space; initial height: " + themeHeight)
        show.forceActiveFocus()
        tryCompare(show, "activeFocus", true)
        keyClick(Qt.Key_Space)
        compare(page.cfg_recentApplicationsShowSeparator, true)
        verify(options.visible && appearance.visible && !custom.visible)
        appearance.currentIndex = appearance.indexOfValue("item")
        appearance.activated(appearance.currentIndex)
        compare(page.cfg_recentApplicationsSeparatorAppearanceSource, "item")
        verify(custom.visible && custom.enabled)
        verify(waitForPolish(page))
        tryVerify(function() { return settings.height > themeHeight }, 1000,
            "Custom appearance controls must expand the layout")
        page.cfg_recentApplicationsSeparatorStyle = "diamond"
        page.cfg_recentApplicationsSeparatorThickness = 7
        page.cfg_recentApplicationsSeparatorLengthRatio = 0.85
        page.cfg_recentApplicationsSeparatorOpacity = 0.65
        page.cfg_recentApplicationsSeparatorGlowEnabled = true
        compare(options.separatorAppearanceSourceValue, "item")
        compare(options.separatorStyleValue, "diamond")
        compare(options.separatorThicknessValue, 7)
        compare(options.separatorLengthRatioValue, 0.85)
        compare(options.separatorOpacityValue, 0.65)
        verify(options.separatorGlowEnabled)
        options.setSeparatorStyleValue("ring")
        options.setSeparatorThicknessValue(9)
        settings.applyItemForm()
        compare(page.cfg_recentApplicationsSeparatorStyle, "ring")
        compare(page.cfg_recentApplicationsSeparatorThickness, 9)
        page.cfg_recentApplicationsSeparatorAppearanceSource = "theme"
        verify(options.visible && !custom.visible)
        page.cfg_recentApplicationsShowSeparator = false
        verify(!options.visible)
        page.cfg_recentApplicationsShowSeparator = true
        verify(options.visible && !custom.visible)
        page.cfg_recentApplicationsSeparatorAppearanceSource = "item"
        verify(custom.visible && custom.enabled)
        compare(options.separatorStyleValue, "ring")
        compare(options.separatorThicknessValue, 9)
        compare(options.separatorLengthRatioValue, 0.85)
        compare(options.separatorOpacityValue, 0.65)
        verify(options.separatorGlowEnabled)
        page.cfg_recentApplicationsMode = "inline"
        verify(settings.enabled)
        page.cfg_showRecentApplications = false
        verify(!settings.enabled)
        page.cfg_showRecentApplications = true
        compare(options.separatorStyleValue, "ring")
        compare(options.separatorThicknessValue, 9)
    }
}
