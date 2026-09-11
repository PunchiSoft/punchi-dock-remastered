// SPDX-License-Identifier: GPL-2.0-or-later

import QtQml
import QtTest
import "../contents/ui/components/controlcenter/ControlCenterBluetoothCompatibility.js" as BluetoothCompatibility

TestCase {
    id: testCase

    name: "ControlCenterBluetoothCompatibility"

    QtObject {
        id: legacyProxy

        property bool connecting: false
        property int genericRegistrations: 0
        property string lastUbi: ""

        function registerPendingCallForDeviceUbi(call, ubi) {
            genericRegistrations++
            lastUbi = ubi
        }
    }

    QtObject {
        id: modernProxy

        property bool connecting: false
        property bool disconnecting: false
        property int connectingRegistrations: 0
        property int disconnectingRegistrations: 0

        function registerConnectingCallForDeviceUbi(call, ubi) {
            connectingRegistrations++
        }

        function registerDisconnectingCallForDeviceUbi(call, ubi) {
            disconnectingRegistrations++
        }
    }

    QtObject {
        id: unsupportedProxy
        property bool connecting: false
    }

    function init() {
        failOnWarning(/.?/)
        legacyProxy.connecting = false
        legacyProxy.genericRegistrations = 0
        legacyProxy.lastUbi = ""
        modernProxy.connecting = false
        modernProxy.disconnecting = false
        modernProxy.connectingRegistrations = 0
        modernProxy.disconnectingRegistrations = 0
    }

    function test_optionalStateSupportsBothContracts() {
        compare(BluetoothCompatibility.optionalBooleanProperty(
            modernProxy, "disconnecting"), false)
        modernProxy.disconnecting = true
        compare(BluetoothCompatibility.optionalBooleanProperty(
            modernProxy, "disconnecting"), true)
        compare(BluetoothCompatibility.optionalBooleanProperty(
            legacyProxy, "disconnecting"), false)
    }

    function test_pendingCallPrefersModernMethodsAndFallsBackToLegacy() {
        verify(BluetoothCompatibility.registerPendingCall(
            modernProxy, null, "modern-connect", false))
        verify(BluetoothCompatibility.registerPendingCall(
            modernProxy, null, "modern-disconnect", true))
        compare(modernProxy.connectingRegistrations, 1)
        compare(modernProxy.disconnectingRegistrations, 1)

        verify(BluetoothCompatibility.registerPendingCall(
            legacyProxy, null, "legacy-device", false))
        compare(legacyProxy.genericRegistrations, 1)
        compare(legacyProxy.lastUbi, "legacy-device")
    }

    function test_missingHelpersFailSafely() {
        compare(BluetoothCompatibility.registerPendingCall(
            unsupportedProxy, null, "unsupported", false), false)
        compare(BluetoothCompatibility.registerPendingCall(
            null, null, "missing", false), false)
    }
}
