// SPDX-License-Identifier: GPL-2.0-or-later

import QtQml
import org.kde.plasma.networkmanagement as PlasmaNM

QtObject {
    id: root

    readonly property bool available: true
    readonly property bool wifiEnabled: enabledConnections.wirelessEnabled
    readonly property bool wifiHardwareEnabled:
        enabledConnections.wirelessHwEnabled
    readonly property bool scanning: handler.scanning
    readonly property var model: mobileProxyModel

    signal activationFailed(string message)
    signal passwordRequested(var network)

    readonly property PlasmaNM.EnabledConnections enabledConnections:
        PlasmaNM.EnabledConnections { }
    readonly property PlasmaNM.Handler handler: PlasmaNM.Handler {
        onConnectionActivationFailed: function(connectionPath, message) {
            root.activationFailed(message)
        }
    }
    readonly property PlasmaNM.NetworkModel sourceModel:
        PlasmaNM.NetworkModel { }
    readonly property PlasmaNM.MobileProxyModel mobileProxyModel:
        PlasmaNM.MobileProxyModel {
            sourceModel: root.sourceModel
            showSavedMode: false
            wired: false
        }

    function isActivated(network) {
        return network
            && network.ConnectionState === PlasmaNM.Enums.Activated
    }

    function isBusy(network) {
        return network
            && (network.ConnectionState === PlasmaNM.Enums.Activating
                || network.ConnectionState === PlasmaNM.Enums.Deactivating)
    }

    function usesInlinePassword(network) {
        if (!network || String(network.Uuid || "").length > 0
                || network.Type !== PlasmaNM.Enums.Wireless) {
            return false
        }
        return network.SecurityType === PlasmaNM.Enums.StaticWep
            || network.SecurityType === PlasmaNM.Enums.WpaPsk
            || network.SecurityType === PlasmaNM.Enums.Wpa2Psk
            || network.SecurityType === PlasmaNM.Enums.SAE
    }

    function passwordAcceptable(network, password) {
        const candidate = String(password || "")
        if (!usesInlinePassword(network)) {
            return true
        }
        if (network.SecurityType === PlasmaNM.Enums.StaticWep) {
            return candidate.length === 5 || candidate.length === 13
                || /^[0-9a-fA-F]{10}$/.test(candidate)
                || /^[0-9a-fA-F]{26}$/.test(candidate)
        }
        return candidate.length >= 8 && candidate.length <= 64
    }

    function snapshotNetwork(network) {
        return {
            "ItemUniqueName": String(network.ItemUniqueName || ""),
            "Name": String(network.Name || ""),
            "Uuid": String(network.Uuid || ""),
            "Type": Number(network.Type),
            "SecurityType": Number(network.SecurityType),
            "ConnectionState": Number(network.ConnectionState),
            "ConnectionPath": String(network.ConnectionPath || ""),
            "DevicePath": String(network.DevicePath || ""),
            "SpecificPath": String(network.SpecificPath || "")
        }
    }

    function setWifiEnabled(enabled) {
        if (!wifiHardwareEnabled) {
            return false
        }
        handler.enableWireless(Boolean(enabled))
        return true
    }

    function requestScan() {
        if (!wifiEnabled) {
            return false
        }
        handler.requestScan()
        return true
    }

    function changeConnectionState(network, password) {
        if (!network || isBusy(network)) {
            return false
        }
        if (isActivated(network)) {
            handler.deactivateConnection(String(network.ConnectionPath || ""),
                String(network.DevicePath || ""))
            return true
        }

        if (usesInlinePassword(network)
                && String(password || "").length === 0) {
            passwordRequested(snapshotNetwork(network))
            return false
        }

        const connectionPath = String(network.ConnectionPath || "")
        const devicePath = String(network.DevicePath || "")
        const specificPath = String(network.SpecificPath || "")
        if (String(network.Uuid || "").length > 0) {
            handler.activateConnection(connectionPath, devicePath, specificPath)
        } else if (usesInlinePassword(network)) {
            if (!passwordAcceptable(network, password)) {
                return false
            }
            handler.addAndActivateConnection(devicePath, specificPath,
                String(password))
        } else {
            handler.addAndActivateConnection(devicePath, specificPath)
        }
        return true
    }
}
