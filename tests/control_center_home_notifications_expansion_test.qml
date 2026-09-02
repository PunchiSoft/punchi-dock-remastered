// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtTest
import org.kde.kirigami as Kirigami
import "../contents/ui/components/controlcenter" as ControlCenter

TestCase {
    id: testCase

    name: "ControlCenterHomeNotificationsPersistent"
    when: windowShown
    property var hostWindowUnderTest: null

    SignalSpy {
        id: applicationSpy
        signalName: "applicationRequested"
    }

    SignalSpy {
        id: doNotDisturbSpy
        signalName: "doNotDisturbRequested"
    }

    SignalSpy {
        id: themeSpy
        signalName: "themeToggleRequested"
    }

    SignalSpy {
        id: nightLightSpy
        signalName: "nightLightToggleRequested"
    }

    SignalSpy {
        id: nightLightStrengthSpy
        signalName: "nightLightStrengthModified"
    }

    QtObject {
        id: fakeThemeAdapter
        property bool available: true
        property bool darkMode: false
        property bool busy: false
    }

    QtObject {
        id: fakeNightLightAdapter
        property bool available: true
        property bool configured: true
        property bool inhibited: false
        property bool ownsInhibition: false
        property bool busy: false
        property int strength: 36
    }

    Component {
        id: windowComponent

        Window {
            id: hostWindow
            width: 640
            height: 900
            visible: true

            property alias page: homePage

            ControlCenter.ControlCenterHomePage {
                id: homePage
                anchors.fill: parent
                motionEnabled: false
                notificationServiceValid: true
                doNotDisturbAvailable: true
                themeAdapter: fakeThemeAdapter
                nightLightAdapter: fakeNightLightAdapter
            }
        }
    }

    function init() {
        failOnWarning(/.?/)
        applicationSpy.clear()
        doNotDisturbSpy.clear()
        themeSpy.clear()
        nightLightSpy.clear()
        nightLightStrengthSpy.clear()
        fakeThemeAdapter.darkMode = false
        fakeThemeAdapter.busy = false
        fakeNightLightAdapter.inhibited = false
        fakeNightLightAdapter.ownsInhibition = false
        fakeNightLightAdapter.busy = false
        fakeNightLightAdapter.configured = true
        fakeNightLightAdapter.strength = 36
    }

    function cleanup() {
        if (hostWindowUnderTest) {
            const hostWindow = hostWindowUnderTest
            hostWindowUnderTest = null
            hostWindow.close()
            wait(0)
            hostWindow.destroy()
            wait(0)
        }
    }

    function test_historyIsPersistentAndQuickControlsRemainActionable() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)

        const page = hostWindow.page
        const dndTile = findChild(page, "controlCenterDoNotDisturbTile")
        const section = findChild(page,
            "controlCenterNotificationsSection")
        const updatesTile = findChild(page, "controlCenterUpdatesTile")
        const calculatorButton = findChild(page,
            "controlCenterCalculatorButton")
        const screenshotButton = findChild(page,
            "controlCenterScreenshotPlaceholderButton")
        const themeButton = findChild(page, "controlCenterThemeButton")
        const nightLightButton = findChild(page,
            "controlCenterNightLightButton")
        const brightnessCard = findChild(page, "controlCenterBrightnessCard")
        const strengthControl = findChild(page,
            "controlCenterNightLightStrengthControl")
        const strengthSlider = findChild(page,
            "controlCenterNightLightStrengthSlider")
        verify(dndTile !== null)
        verify(section !== null)
        verify(updatesTile !== null)
        verify(calculatorButton !== null)
        verify(screenshotButton !== null)
        verify(themeButton !== null)
        verify(nightLightButton !== null)
        verify(brightnessCard !== null)
        verify(strengthControl !== null)
        verify(strengthSlider !== null)
        compare(screenshotButton.enabled, false)
        compare(calculatorButton.implicitHeight,
            Kirigami.Units.gridUnit * 3)
        compare(screenshotButton.implicitHeight,
            Kirigami.Units.gridUnit * 3)
        verify(calculatorButton.implicitHeight < brightnessCard.implicitHeight)
        compare(calculatorButton.implicitWidth,
            calculatorButton.implicitHeight)
        compare(strengthControl.visible, true)
        compare(strengthControl.controlAvailable, true)
        compare(strengthSlider.value, 36)
        compare(strengthSlider.Accessible.name, "Night Light intensity")
        compare(section.visible, true)
        tryVerify(function() { return section.height > 0 })
        compare(findChild(page, "controlCenterNotificationsTile"), null)
        compare(dndTile.Accessible.checkable, true)
        compare(dndTile.Accessible.checked, false)
        compare(themeButton.Accessible.checkable, true)
        compare(themeButton.Accessible.checked, false)
        compare(nightLightButton.Accessible.checkable, true)
        compare(nightLightButton.Accessible.checked, true)

        doNotDisturbSpy.target = page
        themeSpy.target = page
        nightLightSpy.target = page
        mouseClick(dndTile, dndTile.width / 2, dndTile.height / 2)
        compare(doNotDisturbSpy.count, 1)
        mouseClick(themeButton, themeButton.width / 2,
            themeButton.height / 2)
        compare(themeSpy.count, 1)
        mouseClick(nightLightButton, nightLightButton.width / 2,
            nightLightButton.height / 2)
        compare(nightLightSpy.count, 1)

        nightLightStrengthSpy.target = page
        strengthControl.strengthModified(62)
        compare(nightLightStrengthSpy.count, 1)
        compare(nightLightStrengthSpy.signalArguments[0][0], 62)

        fakeNightLightAdapter.configured = false
        compare(strengthControl.controlAvailable, false)
        compare(nightLightButton.Accessible.checked, false)

        applicationSpy.target = page
        mouseClick(updatesTile, updatesTile.width / 2,
            updatesTile.height / 2)
        compare(applicationSpy.count, 1)
        compare(applicationSpy.signalArguments[0][0], "updates")

        mouseClick(calculatorButton, calculatorButton.width / 2,
            calculatorButton.height / 2)
        compare(applicationSpy.count, 2)
        compare(applicationSpy.signalArguments[1][0], "calculator")
    }
}
