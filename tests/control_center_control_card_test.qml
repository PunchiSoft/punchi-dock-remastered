// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtTest
import "../contents/ui/components/controlcenter" as ControlCenter

TestCase {
    id: testCase

    name: "ControlCenterControlCard"
    when: windowShown
    property var hostWindowUnderTest: null

    SignalSpy {
        id: valueSpy
        signalName: "valueModified"
    }

    SignalSpy {
        id: secondaryActionSpy
        signalName: "secondaryActionTriggered"
    }

    SignalSpy {
        id: navigationSpy
        signalName: "navigationRequested"
    }

    Component {
        id: windowComponent

        Window {
            id: hostWindow
            width: 640
            height: 360
            visible: true

            property alias card: controlCard

            ControlCenter.ControlCenterControlCard {
                id: controlCard
                anchors.centerIn: parent
                width: 420
                title: "Sound"
                iconName: "audio-volume-high"
                value: 35
                controlAvailable: true
                secondaryActionVisible: true
                secondaryActionEnabled: true
                secondaryActionCheckable: true
                secondaryActionChecked: true
                secondaryActionIconName: "view-visible"
                secondaryActionName: "Hide Plasma volume indicator"
                secondaryActionDescription:
                    "Changes the volume indicator throughout Plasma"
                navigationActionVisible: true
                navigationActionEnabled: true
                navigationActionName: "Manage audio devices and applications"
            }
        }
    }

    function init() {
        failOnWarning(/.?/)
        valueSpy.clear()
        secondaryActionSpy.clear()
        navigationSpy.clear()
    }

    function cleanup() {
        valueSpy.target = null
        secondaryActionSpy.target = null
        navigationSpy.target = null
        if (hostWindowUnderTest) {
            const hostWindow = hostWindowUnderTest
            hostWindowUnderTest = null
            hostWindow.close()
            wait(0)
            hostWindow.destroy()
            wait(0)
        }
    }

    function test_navigationActionIsDiscoverableAndKeyboardAccessible() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)

        const card = hostWindow.card
        const action = findChild(card, "controlCenterNavigationActionButton")
        verify(action !== null)
        compare(action.visible, true)
        compare(action.enabled, true)
        compare(action.Accessible.name,
            "Manage audio devices and applications")

        navigationSpy.target = card
        action.forceActiveFocus(Qt.TabFocusReason)
        tryVerify(function() { return action.activeFocus })
        keyClick(Qt.Key_Space)
        tryCompare(navigationSpy, "count", 1)
    }

    function test_secondaryActionIsCheckableAccessibleAndClickable() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)

        const card = hostWindow.card
        const action = findChild(card, "controlCenterSecondaryActionButton")
        verify(action !== null)
        compare(action.visible, true)
        compare(action.enabled, true)
        compare(action.checkable, true)
        compare(action.checked, true)
        compare(action.icon.name, "view-visible")
        compare(action.Accessible.name, "Hide Plasma volume indicator")
        compare(action.Accessible.description,
            "Changes the volume indicator throughout Plasma")

        secondaryActionSpy.target = card
        mouseClick(action, action.width / 2, action.height / 2)
        tryCompare(secondaryActionSpy, "count", 1)
    }

    function test_sliderIsAccessibleAndEmitsUserChanges() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)

        const card = hostWindow.card
        const slider = findChild(card, "controlCenterControlSlider")
        verify(slider !== null)
        compare(slider.Accessible.name, "Sound")
        compare(slider.enabled, true)
        compare(Math.round(slider.value), 35)

        valueSpy.target = card
        mouseClick(slider, slider.width * 0.75, slider.height / 2)
        tryVerify(function() { return valueSpy.count > 0 })
        verify(valueSpy.signalArguments[0][0] > 35)
    }
}
