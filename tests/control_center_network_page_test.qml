// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtTest
import "../contents/ui/components/controlcenter" as ControlCenter

TestCase {
    id: testCase

    name: "ControlCenterNetworkPage"
    when: windowShown
    property var hostWindowUnderTest: null

    SignalSpy {
        id: backSpy
        signalName: "backRequested"
    }

    Component {
        id: windowComponent

        Window {
            id: hostWindow
            width: 640
            height: 600
            visible: true

            property alias page: networkPage
            property alias fakeAdapter: adapter

            QtObject {
                id: adapter

                property bool wifiEnabled: true
                property bool wifiHardwareEnabled: true
                property bool scanning: false
                property int scanRequests: 0
                property int wifiChanges: 0
                property int connectionChanges: 0
                property var model: ListModel {
                    ListElement {
                        ItemUniqueName: "Punchi Wi-Fi"
                        Name: "Punchi Wi-Fi"
                        ConnectionIcon: "network-wireless-connected-100"
                        SecurityTypeString: "WPA2"
                        Section: "Connected"
                        ConnectionState: 2
                    }
                    ListElement {
                        ItemUniqueName: "Guest"
                        Name: "Guest"
                        ConnectionIcon: "network-wireless-available"
                        SecurityTypeString: "Open"
                        Section: "Available"
                        ConnectionState: 4
                    }
                }

                function requestScan() {
                    scanRequests++
                    return true
                }

                function setWifiEnabled(enabled) {
                    wifiChanges++
                    wifiEnabled = enabled
                    return true
                }

                function isActivated(network) {
                    return network.ConnectionState === 2
                }

                function isBusy(network) {
                    return false
                }

                function changeConnectionState(network, password) {
                    connectionChanges++
                    return true
                }
            }

            ControlCenter.ControlCenterNetworkPage {
                id: networkPage
                anchors.fill: parent
                adapter: adapter
            }
        }
    }

    function init() {
        failOnWarning(/.?/)
        backSpy.clear()
    }

    function cleanup() {
        backSpy.target = null
        if (hostWindowUnderTest) {
            const hostWindow = hostWindowUnderTest
            hostWindowUnderTest = null
            hostWindow.close()
            wait(0)
            hostWindow.destroy()
            wait(0)
        }
    }

    function test_listsNetworksAndBackNavigationWorks() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)
        tryCompare(hostWindow.fakeAdapter, "scanRequests", 1)

        const page = hostWindow.page
        const list = findChild(page, "controlCenterNetworkList")
        const backButton = findChild(page, "controlCenterNetworkBackButton")
        const header = findChild(page, "controlCenterNetworkHeader")
        const navigationRow = findChild(page,
            "controlCenterNetworkNavigationRow")
        const actionsRow = findChild(page, "controlCenterNetworkActionsRow")
        verify(list !== null)
        verify(backButton !== null)
        verify(header !== null)
        verify(navigationRow !== null)
        verify(actionsRow !== null)
        tryCompare(page, "width", 640)
        tryCompare(header, "width", page.width)
        verify(navigationRow.childrenRect.x >= -0.5)
        verify(navigationRow.childrenRect.x
            + navigationRow.childrenRect.width <= navigationRow.width + 0.5)
        verify(actionsRow.childrenRect.x >= -0.5)
        verify(actionsRow.childrenRect.x + actionsRow.childrenRect.width
            <= actionsRow.width + 0.5)
        compare(list.count, 2)

        // The row itself is a click target for the same action as its button, so
        // the pointer does not have to find the small control.
        list.positionViewAtIndex(0, ListView.Beginning)
        wait(0)
        const firstDelegate = list.itemAtIndex(0)
        verify(firstDelegate !== null)
        const pointerX = Math.round(firstDelegate.width * 0.25)
        const pointerY = Math.round(firstDelegate.height / 2)
        // The hover state of a row behind its own content is not observable
        // under the offscreen platform, so it stays a visual check.
        mouseMove(firstDelegate, pointerX, pointerY)
        mouseClick(firstDelegate, pointerX, pointerY)
        compare(hostWindow.fakeAdapter.connectionChanges, 1)

        // The row is one tile: the highlight must cover the icon band, the centre
        // and the button band, not only the free space next to the icon.
        const stateButton = findChild(firstDelegate,
            "controlCenterNetworkStateButton")
        verify(stateButton !== null)
        verify(!stateButton.hoverEnabled)
        const hoverFractions = [0.10, 0.55, 0.90]
        for (let i = 0; i < hoverFractions.length; ++i) {
            // Leave the tile first, so a hover left over from a previous step
            // cannot pass the assertion.
            mouseMove(backButton, backButton.width / 2, backButton.height / 2)
            wait(30)
            verify(!firstDelegate.rowHovered,
                "the tile must stop reporting hover when the pointer leaves it")
            mouseMove(firstDelegate,
                Math.round(firstDelegate.width * hoverFractions[i]), pointerY)
            tryCompare(firstDelegate, "rowHovered", true, 5000,
                "the whole tile must report hover at " + hoverFractions[i]
                + " of its width")
        }

        backSpy.target = page
        mouseClick(backButton, backButton.width / 2, backButton.height / 2)
        compare(backSpy.count, 1)
    }

    function test_inlineHeaderSkipsUnavailableToggleAndScan() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)
        const page = hostWindow.page
        const toggle = findChild(page, "controlCenterWifiSwitch")
        const scan = findChild(page, "controlCenterNetworkScanButton")
        const settings = findChild(page,
            "controlCenterNetworkSettingsButton")
        verify(toggle !== null)
        verify(scan !== null)
        verify(settings !== null)
        hostWindow.fakeAdapter.wifiHardwareEnabled = false
        page.inlineMode = true
        verify(!toggle.enabled)
        verify(!scan.enabled)
        page.focusFirstControl()
        tryCompare(settings, "activeFocus", true)
    }
}
