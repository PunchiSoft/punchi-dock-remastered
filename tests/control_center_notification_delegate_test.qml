// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtTest
import "../contents/ui/components/controlcenter" as ControlCenter

TestCase {
    id: testCase

    name: "ControlCenterNotificationDelegate"
    when: windowShown
    property var hostWindowUnderTest: null

    SignalSpy {
        id: closeSpy
        signalName: "closeRequested"
    }

    Component {
        id: windowComponent

        Window {
            id: hostWindow
            width: 520
            height: 180
            visible: true

            property alias notificationDelegate: notificationDelegate

            ControlCenter.ControlCenterNotificationDelegate {
                id: notificationDelegate
                width: 480
                height: implicitHeight
                anchors.centerIn: parent
                summary: "Build completed"
                body: "The project finished successfully"
                applicationName: "Example application"
                applicationIconName: "dialog-information"
                closable: true
            }
        }
    }

    function findItemByObjectName(item, name) {
        if (!item) {
            return null
        }
        if (item.objectName === name) {
            return item
        }
        const childItems = item.children || []
        for (let index = 0; index < childItems.length; ++index) {
            const match = findItemByObjectName(childItems[index], name)
            if (match) {
                return match
            }
        }
        return null
    }

    function init() {
        failOnWarning(/.?/)
        closeSpy.clear()
    }

    function cleanup() {
        closeSpy.target = null
        if (hostWindowUnderTest) {
            const hostWindow = hostWindowUnderTest
            hostWindowUnderTest = null
            hostWindow.close()
            wait(0)
            hostWindow.destroy()
            wait(0)
        }
    }

    function test_closeActionFollowsModelCapability() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)

        const notificationDelegate = hostWindow.notificationDelegate
        const closeButton = findItemByObjectName(
            notificationDelegate, "notificationCloseButton")
        verify(closeButton !== null)
        compare(closeButton.visible, true)
        compare(closeButton.Accessible.name, "Close")

        closeSpy.target = notificationDelegate
        mouseClick(closeButton, closeButton.width / 2, closeButton.height / 2)
        compare(closeSpy.count, 1)

        notificationDelegate.closable = false
        compare(closeButton.visible, false)
    }
}
