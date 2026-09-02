// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase

    name: "ControlCenterController"

    QtObject {
        id: fakeLauncher

        property bool actionAvailable: true
        property int actionCalls: 0
        property int applicationCalls: 0
        property string lastApplicationId: ""
        property string lastActionId: ""

        function reset() {
            actionAvailable = true
            actionCalls = 0
            applicationCalls = 0
            lastApplicationId = ""
            lastActionId = ""
        }

        function launchApplicationAction(applicationId, actionId) {
            actionCalls++
            lastApplicationId = applicationId
            lastActionId = actionId
            return actionAvailable
        }

        function launchApplication(applicationId) {
            applicationCalls++
            lastApplicationId = applicationId
        }
    }

    Components.ControlCenterController {
        id: controller
        applicationLauncher: fakeLauncher
    }

    function init() {
        failOnWarning(/.?/)
        fakeLauncher.reset()
    }

    function test_updatesUseTheDiscoverDesktopAction() {
        verify(controller.openApplication("updates"))
        compare(fakeLauncher.actionCalls, 1)
        compare(fakeLauncher.applicationCalls, 0)
        compare(fakeLauncher.lastApplicationId,
            "org.kde.discover.desktop")
        compare(fakeLauncher.lastActionId, "Updates")

        fakeLauncher.reset()
        fakeLauncher.actionAvailable = false
        verify(controller.openApplication("updates"))
        compare(fakeLauncher.actionCalls, 1)
        compare(fakeLauncher.applicationCalls, 1)
        compare(fakeLauncher.lastApplicationId,
            "org.kde.discover.desktop")
    }

    function test_calculatorUsesItsDesktopService() {
        verify(controller.openApplication("calculator"))
        compare(fakeLauncher.actionCalls, 0)
        compare(fakeLauncher.applicationCalls, 1)
        compare(fakeLauncher.lastApplicationId, "org.kde.kcalc.desktop")
        verify(!controller.openApplication("unsupported"))
    }
}
