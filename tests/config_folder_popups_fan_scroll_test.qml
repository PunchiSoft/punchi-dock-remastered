// SPDX-License-Identifier: GPL-2.0-or-later
//
// Contract of the fan scroll switch inside the folder popup page: the KCM reads
// the value from the page properties on Apply and writes them back on load, so
// the page must expose the preference and drive the control both ways. The
// switch belongs to the fan profile alone; hiding it must not touch the value.

import QtQuick
import QtTest
import "../contents/ui/config" as ConfigPages

TestCase {
    id: testCase

    name: "ConfigFolderPopupsFanScroll"
    when: windowShown
    width: 640
    height: 760

    ConfigPages.ConfigFolderPopups {
        id: page
        width: 600
        height: implicitHeight
    }

    function init() {
        failOnWarning(/.?/)
        page.activeProfile = "fan"
        page.cfg_folderFanScrollEnabled = false
        wait(0)
    }

    function fanSwitch() {
        let item = null
        tryVerify(function() {
            item = findChild(page, "fanScrollCheck")
            return item !== null
        })
        return item
    }

    function test_theStaticDefaultIsOffAndReachesTheControl() {
        compare(page.cfg_folderFanScrollEnabled, false,
            "The persistent default must be the static fan")
        const fanScroll = fanSwitch()
        compare(fanScroll.checked, false,
            "Loading the default must leave the switch off")
    }

    function test_theControlFeedsTheValueTheKcmApplies() {
        const fanScroll = fanSwitch()

        // The KCM writes the stored value into the control when it loads.
        page.cfg_folderFanScrollEnabled = true
        tryCompare(fanScroll, "checked", true)

        // And reads it back from the control when the user applies changes.
        fanScroll.checked = false
        tryCompare(page, "cfg_folderFanScrollEnabled", false)

        // Restoring the defaults shows the documented off state again.
        fanScroll.checked = true
        tryCompare(page, "cfg_folderFanScrollEnabled", true)
        page.cfg_folderFanScrollEnabled = false
        tryCompare(fanScroll, "checked", false)
    }

    // The offscreen harness reports `visible` as false for the whole tree, so
    // the profile gate of the switch is asserted by the surface contract test.
    // What is checked here is that walking the profiles never rewrites the
    // stored value behind the user's back.
    function test_switchingTheProfileKeepsTheStoredValue() {
        const fanScroll = fanSwitch()
        page.cfg_folderFanScrollEnabled = true
        tryCompare(fanScroll, "checked", true)

        const otherProfiles = ["grid", "list", "detailed"]
        for (let index = 0; index < otherProfiles.length; index++) {
            page.activeProfile = otherProfiles[index]
            wait(0)
            compare(page.cfg_folderFanScrollEnabled, true,
                "Leaving the fan profile must not change the stored value for "
                    + otherProfiles[index])
        }

        page.activeProfile = "fan"
        tryCompare(fanScroll, "checked", true)
    }

    function test_theSwitchKeepsItsAccessibleDescription() {
        const fanScroll = fanSwitch()
        verify(String(fanScroll.Accessible.name).length > 0,
            "The switch needs an accessible name")
        verify(String(fanScroll.Accessible.description).length > 0,
            "The switch needs an accessible description")
        compare(fanScroll.activeFocusOnTab, true,
            "The switch must be reachable with the keyboard")
    }
}
