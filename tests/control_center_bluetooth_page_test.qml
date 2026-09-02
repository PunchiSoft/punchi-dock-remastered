// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtTest
import "../contents/ui/components/controlcenter" as ControlCenter

TestCase {
    id: testCase

    name: "ControlCenterBluetoothPage"
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

            property alias page: bluetoothPage
            property alias fakeAdapter: adapter

            QtObject {
                id: firstDevice

                function connectToDevice() {
                    return null
                }

                function disconnectFromDevice() {
                    return null
                }
            }

            QtObject {
                id: secondDevice

                function connectToDevice() {
                    return null
                }

                function disconnectFromDevice() {
                    return null
                }
            }

            QtObject {
                id: firstBattery
                property int percentage: 72
            }

            ListModel {
                id: deviceModel
                dynamicRoles: true

                Component.onCompleted: {
                    append({
                        "Device": firstDevice,
                        "Ubi": "/org/bluez/hci0/dev_01",
                        "DeviceFullName": "Punchi Headphones",
                        "Name": "Punchi Headphones",
                        "Icon": "audio-headphones",
                        "Connected": true,
                        "Connecting": false,
                        "Disconnecting": false,
                        "ConnectionFailed": false,
                        "Battery": firstBattery,
                        "Section": "Connected"
                    })
                    append({
                        "Device": secondDevice,
                        "Ubi": "/org/bluez/hci0/dev_02",
                        "DeviceFullName": "Punchi Keyboard",
                        "Name": "Punchi Keyboard",
                        "Icon": "input-keyboard",
                        "Connected": false,
                        "Connecting": false,
                        "Disconnecting": false,
                        "ConnectionFailed": false,
                        "Battery": null,
                        "Section": "Available"
                    })
                }
            }

            QtObject {
                id: adapter

                property bool hasAdapter: true
                property bool bluetoothEnabled: true
                property int connectedCount: 1
                property int enabledChanges: 0
                property int pairingRequests: 0
                property int deviceChanges: 0
                property var model: deviceModel

                function setBluetoothEnabled(enabled) {
                    enabledChanges++
                    bluetoothEnabled = Boolean(enabled)
                    return true
                }

                function openPairingWizard() {
                    pairingRequests++
                    return true
                }

                function changeDeviceState(device, ubi, connected, connecting,
                        disconnecting) {
                    deviceChanges++
                    return true
                }

                function deviceTypeKey(iconName) {
                    if (String(iconName).includes("headphone")) {
                        return "headphones"
                    }
                    if (String(iconName).includes("keyboard")) {
                        return "keyboard"
                    }
                    return "other"
                }
            }

            ControlCenter.ControlCenterBluetoothPage {
                id: bluetoothPage
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

    function test_listsDevicesAndRoutesActions() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)

        const page = hostWindow.page
        const list = findChild(page, "controlCenterBluetoothDeviceList")
        const backButton = findChild(page,
            "controlCenterBluetoothBackButton")
        const bluetoothSwitch = findChild(page,
            "controlCenterBluetoothSwitch")
        const pairButton = findChild(page,
            "controlCenterBluetoothPairButton")
        const settingsButton = findChild(page,
            "controlCenterBluetoothSettingsButton")
        const header = findChild(page, "controlCenterBluetoothHeader")
        const navigationRow = findChild(page,
            "controlCenterBluetoothNavigationRow")
        const actionsRow = findChild(page,
            "controlCenterBluetoothActionsRow")
        verify(list !== null)
        verify(backButton !== null)
        verify(bluetoothSwitch !== null)
        verify(pairButton !== null)
        verify(settingsButton !== null)
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
        tryCompare(list, "count", 2)
        list.positionViewAtIndex(0, ListView.Beginning)
        wait(0)
        const firstDelegate = list.itemAtIndex(0)
        verify(firstDelegate !== null)
        const stateButton = findChild(firstDelegate,
            "controlCenterBluetoothStateButton")
        verify(stateButton !== null)

        mouseClick(stateButton, stateButton.width / 2,
            stateButton.height / 2)
        compare(hostWindow.fakeAdapter.deviceChanges, 1)

        mouseClick(pairButton, pairButton.width / 2,
            pairButton.height / 2)
        compare(hostWindow.fakeAdapter.pairingRequests, 1)

        mouseClick(bluetoothSwitch, bluetoothSwitch.width / 2,
            bluetoothSwitch.height / 2)
        compare(hostWindow.fakeAdapter.enabledChanges, 1)
        compare(hostWindow.fakeAdapter.bluetoothEnabled, false)

        backSpy.target = page
        mouseClick(backButton, backButton.width / 2,
            backButton.height / 2)
        compare(backSpy.count, 1)
    }
}
