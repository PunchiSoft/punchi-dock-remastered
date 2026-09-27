// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtTest
import "../contents/ui/components/punchimenu" as PunchiMenu

TestCase {
    id: testCase

    name: "PunchiMenuSessionFocus"
    when: windowShown
    property var hostWindowUnderTest: null

    Component {
        id: windowComponent

        Window {
            id: hostWindow
            width: 720
            height: 480
            visible: true

            property alias sessionView: sessionView
            property alias focusSink: focusSink

            Item {
                id: focusSink
                width: 1
                height: 1
            }

            PunchiMenu.PunchiMenuSessionView {
                id: sessionView
                anchors.fill: parent
                userName: "Test User"
                userAvatar: ""
                canLogout: true
                canRestart: true
                canShutdown: true
            }
        }
    }

    function init() {
        failOnWarning(/.?/)
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

    function createSessionWindow() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)
        hostWindow.requestActivate()
        tryCompare(hostWindow, "active", true)
        wait(0)
        return hostWindow
    }

    function test_programmaticFocusDoesNotPaintTheDefaultAction() {
        const hostWindow = createSessionWindow()
        const sessionView = hostWindow.sessionView
        const logoutButton = findChild(
            sessionView, "punchiMenuLogoutButton")
        verify(logoutButton !== null)

        hostWindow.focusSink.forceActiveFocus(Qt.OtherFocusReason)
        tryVerify(function() { return !logoutButton.activeFocus })
        sessionView.focusInitialAction(Qt.PopupFocusReason)
        tryVerify(function() { return logoutButton.activeFocus })
        verify(!logoutButton.visualFocus)
        verify(!logoutButton.highlightedContent)
    }

    function test_keyboardFocusPaintsTheDefaultAction() {
        const hostWindow = createSessionWindow()
        const sessionView = hostWindow.sessionView
        const logoutButton = findChild(
            sessionView, "punchiMenuLogoutButton")
        verify(logoutButton !== null)

        hostWindow.focusSink.forceActiveFocus(Qt.OtherFocusReason)
        tryVerify(function() { return !logoutButton.activeFocus })
        sessionView.focusInitialAction(Qt.TabFocusReason)
        tryVerify(function() { return logoutButton.activeFocus })
        verify(logoutButton.visualFocus,
            "focus reason=" + logoutButton.focusReason)
        verify(logoutButton.highlightedContent)
    }

    function test_keyboardFocusUsesTheFirstAvailableAction() {
        const hostWindow = createSessionWindow()
        const sessionView = hostWindow.sessionView
        const logoutButton = findChild(
            sessionView, "punchiMenuLogoutButton")
        const restartButton = findChild(
            sessionView, "punchiMenuRestartButton")
        verify(logoutButton !== null)
        verify(restartButton !== null)

        sessionView.canLogout = false
        hostWindow.focusSink.forceActiveFocus(Qt.OtherFocusReason)
        sessionView.focusInitialAction(Qt.TabFocusReason)
        tryVerify(function() { return restartButton.activeFocus })
        verify(!logoutButton.highlightedContent)
        verify(restartButton.visualFocus)
        verify(restartButton.highlightedContent)
    }
}
