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

        backSpy.target = page
        mouseClick(backButton, backButton.width / 2, backButton.height / 2)
        compare(backSpy.count, 1)
    }
}
