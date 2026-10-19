// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import "../contents/ui/components/BackgroundQuickActions.js" as BackgroundQuickActions

TestCase {
    id: testCase
    name: "BackgroundQuickActions"

    function test_visibilityToggleStoresAndRestoresExplicitModes() {
        let result = BackgroundQuickActions.visibilityToggle(false, "dodgeWindows", "")
        compare(result.mode, "autoHide")
        compare(result.previous, "dodgeWindows")

        result = BackgroundQuickActions.visibilityToggle(true, "autoHide", "dodgeWindows")
        compare(result.mode, "dodgeWindows")
        compare(result.previous, "")
    }

    function test_visibilityOffFallsBackToAlwaysVisible() {
        let result = BackgroundQuickActions.visibilityToggle(true, "autoHide", "")
        compare(result.mode, "alwaysVisible")
        result = BackgroundQuickActions.visibilityToggle(true, "autoHide", "system")
        compare(result.mode, "alwaysVisible")
        result = BackgroundQuickActions.visibilityToggle(true, "autoHide", "invalid")
        compare(result.mode, "alwaysVisible")
    }

    function test_magnificationToggleStoresAndRestoresScale() {
        let result = BackgroundQuickActions.magnificationToggle(true, 1.65, 0)
        compare(result.scale, 1.0)
        compare(result.previous, 1.65)

        result = BackgroundQuickActions.magnificationToggle(false, 1.0, 1.3)
        compare(result.scale, 1.3)
        compare(result.previous, 0)
    }

    function test_magnificationRejectsInvalidPreviousScale() {
        let result = BackgroundQuickActions.magnificationToggle(false, 1.0, 0)
        compare(result.scale, 1.65)
        result = BackgroundQuickActions.magnificationToggle(false, 1.0, 4.0)
        compare(result.scale, 1.65)
        result = BackgroundQuickActions.magnificationToggle(false, 1.0, -1)
        compare(result.scale, 1.65)
    }
}
