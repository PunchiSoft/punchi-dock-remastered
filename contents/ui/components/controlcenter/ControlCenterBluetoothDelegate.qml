// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

FocusScope {
    id: root

    required property var device
    required property var adapter

    readonly property string deviceName:
        String(device ? device.DeviceFullName || device.Name || "" : "")
    readonly property bool connected: Boolean(device && device.Connected)
    readonly property bool connecting: Boolean(device && device.Connecting)
    readonly property bool disconnecting:
        Boolean(device && device.Disconnecting)
    readonly property bool busy: connecting || disconnecting
    readonly property bool connectionFailed:
        Boolean(device && device.ConnectionFailed)
    readonly property int batteryPercentage:
        device && device.Battery
            ? Math.round(Number(device.Battery.percentage)) : -1
    readonly property string statusText: buildStatusText()

    signal toggleRequested()

    implicitHeight: Kirigami.Units.gridUnit * 3.5
    activeFocusOnTab: true
    Accessible.role: Accessible.ListItem
    Accessible.name: deviceName
    Accessible.description: statusText
    Keys.onReturnPressed: function(event) {
        root.requestToggle()
        event.accepted = true
    }
    Keys.onEnterPressed: function(event) {
        root.requestToggle()
        event.accepted = true
    }
    Keys.onSpacePressed: function(event) {
        root.requestToggle()
        event.accepted = true
    }

    function requestToggle() {
        if (!busy) {
            toggleRequested()
        }
    }

    // The translation helpers are supplied by the plasmoid context.
    // qmllint disable unqualified
    function deviceTypeText() {
        switch (String(adapter.deviceTypeKey(device ? device.Icon : ""))) {
        case "headset":
            return i18nc("@info:status Bluetooth device type", "Headset")
        case "headphones":
            return i18nc("@info:status Bluetooth device type", "Headphones")
        case "audio":
            return i18nc("@info:status Bluetooth device type", "Audio device")
        case "keyboard":
            return i18nc("@info:status Bluetooth device type", "Keyboard")
        case "mouse":
            return i18nc("@info:status Bluetooth device type", "Mouse")
        case "joypad":
            return i18nc("@info:status Bluetooth device type", "Game controller")
        case "tablet":
            return i18nc("@info:status Bluetooth device type", "Drawing tablet")
        case "phone":
            return i18nc("@info:status Bluetooth device type", "Phone")
        case "camera":
            return i18nc("@info:status Bluetooth device type", "Camera")
        case "printer":
            return i18nc("@info:status Bluetooth device type", "Printer")
        default:
            return i18nc("@info:status Bluetooth device type", "Other device")
        }
    }

    function buildStatusText() {
        if (connecting) {
            return i18nc("@info:status", "Connecting…")
        }
        if (disconnecting) {
            return i18nc("@info:status", "Disconnecting…")
        }

        const parts = []
        if (connectionFailed) {
            parts.push(i18nc("@info:status", "Connection failed"))
        } else if (connected) {
            parts.push(i18nc("@info:status", "Connected"))
        }
        parts.push(deviceTypeText())
        if (batteryPercentage >= 0) {
            parts.push(i18nc("@info:status", "%1% battery",
                batteryPercentage))
        }
        return parts.join(" · ")
    }
    // qmllint enable unqualified

    Rectangle {
        anchors.fill: parent
        radius: Kirigami.Units.cornerRadius * 1.5
        color: root.activeFocus
            ? Qt.alpha(Kirigami.Theme.highlightColor, 0.24)
            : "transparent"
        border.width: root.activeFocus ? 2 : 0
        border.color: Kirigami.Theme.highlightColor
        Accessible.ignored: true
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.mediumSpacing
        anchors.rightMargin: Kirigami.Units.mediumSpacing
        spacing: Kirigami.Units.mediumSpacing

        Kirigami.Icon {
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            source: String(root.device
                ? root.device.Icon || "preferences-system-bluetooth" : "")
            Accessible.ignored: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Controls.Label {
                Layout.fillWidth: true
                text: root.deviceName
                font.bold: root.connected
                elide: Text.ElideRight
            }

            Controls.Label {
                Layout.fillWidth: true
                text: root.statusText
                opacity: root.connectionFailed ? 1.0 : 0.68
                color: root.connectionFailed
                    ? Kirigami.Theme.negativeTextColor
                    : Kirigami.Theme.textColor
                font: Kirigami.Theme.smallFont
                elide: Text.ElideRight
            }
        }

        PlasmaComponents.BusyIndicator {
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            running: root.busy
            visible: running
        }

        PlasmaComponents.Button {
            id: stateButton
            objectName: "controlCenterBluetoothStateButton"
            text: root.connected
                ? i18nc("@action:button", "Disconnect") // qmllint disable unqualified
                : i18nc("@action:button", "Connect") // qmllint disable unqualified
            icon.name: root.connected
                ? "network-disconnect-symbolic" : "network-connect-symbolic"
            enabled: !root.busy
            Accessible.description: root.deviceName
            onClicked: root.requestToggle()
        }
    }
}
