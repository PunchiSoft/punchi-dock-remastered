// SPDX-License-Identifier: GPL-2.0-or-later

import QtQml
import org.kde.bluezqt as BluezQt
import org.kde.plasma.private.bluetooth as PlasmaBt

QtObject {
    id: root

    readonly property bool available: true
    readonly property bool hasAdapter:
        BluezQt.Manager.rfkill.state !== BluezQt.Rfkill.Unknown
    readonly property bool bluetoothEnabled:
        BluezQt.Manager.bluetoothOperational
    readonly property bool blocked: BluezQt.Manager.bluetoothBlocked
    readonly property bool busy: PlasmaBt.SharedDevicesStateProxyModel.connecting
        || PlasmaBt.SharedDevicesStateProxyModel.disconnecting
    readonly property int connectedCount:
        BluezQt.Manager.connectedDevices.length
    readonly property var model: devicesModel

    readonly property PlasmaBt.DevicesProxyModel devicesModel:
        PlasmaBt.DevicesProxyModel {
            hideBlockedDevices: true
            sourceModel: PlasmaBt.SharedDevicesStateProxyModel
        }

    function setBluetoothEnabled(enabled) {
        if (!hasAdapter) {
            return false
        }

        const targetEnabled = Boolean(enabled)
        BluezQt.Manager.bluetoothBlocked = !targetEnabled
        BluezQt.Manager.adapters.forEach(function(adapter) {
            adapter.powered = targetEnabled
        })
        return true
    }

    function changeDeviceState(device, ubi, connected, connecting,
            disconnecting) {
        if (!device || connecting || disconnecting) {
            return false
        }

        if (connected) {
            const call = device.disconnectFromDevice()
            PlasmaBt.SharedDevicesStateProxyModel
                .registerDisconnectingCallForDeviceUbi(call, String(ubi || ""))
        } else {
            const call = device.connectToDevice()
            PlasmaBt.SharedDevicesStateProxyModel
                .registerConnectingCallForDeviceUbi(call, String(ubi || ""))
        }
        return true
    }

    function openPairingWizard() {
        if (!hasAdapter || !bluetoothEnabled) {
            return false
        }
        PlasmaBt.LaunchApp.launchWizard()
        return true
    }

    function deviceTypeKey(iconName) {
        const icon = String(iconName || "").toLocaleLowerCase()
        if (icon.includes("headset")) {
            return "headset"
        }
        if (icon.includes("headphone")) {
            return "headphones"
        }
        if (icon.includes("audio") || icon.includes("speaker")) {
            return "audio"
        }
        if (icon.includes("keyboard")) {
            return "keyboard"
        }
        if (icon.includes("mouse")) {
            return "mouse"
        }
        if (icon.includes("gaming") || icon.includes("gamepad")
                || icon.includes("joystick")) {
            return "joypad"
        }
        if (icon.includes("tablet")) {
            return "tablet"
        }
        if (icon.includes("phone")) {
            return "phone"
        }
        if (icon.includes("camera")) {
            return "camera"
        }
        if (icon.includes("printer")) {
            return "printer"
        }
        return "other"
    }
}
