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
            }
        }
    }

    function init() {
        failOnWarning(/.?/)
        valueSpy.clear()
    }

    function cleanup() {
        valueSpy.target = null
        if (hostWindowUnderTest) {
            const hostWindow = hostWindowUnderTest
            hostWindowUnderTest = null
            hostWindow.close()
            wait(0)
            hostWindow.destroy()
            wait(0)
        }
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
