// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras

FocusScope {
    id: root

    required property var adapter

    signal backRequested()
    signal settingsRequested(string section)

    function focusFirstControl() {
        pageHeader.focusBackButton()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.mediumSpacing

        ControlCenterPageHeader {
            id: pageHeader

            Layout.fillWidth: true
            headerObjectName: "controlCenterBluetoothHeader"
            navigationRowObjectName: "controlCenterBluetoothNavigationRow"
            actionsRowObjectName: "controlCenterBluetoothActionsRow"
            backButtonObjectName: "controlCenterBluetoothBackButton"
            toggleObjectName: "controlCenterBluetoothSwitch"
            primaryActionObjectName: "controlCenterBluetoothPairButton"
            settingsActionObjectName: "controlCenterBluetoothSettingsButton"
            title: i18nc("@title", "Bluetooth Devices") // qmllint disable unqualified
            backActionName: i18nc("@action:button", "Back to Control Center") // qmllint disable unqualified
            toggleText: i18nc("@option:check", "Bluetooth") // qmllint disable unqualified
            toggleChecked: root.adapter.bluetoothEnabled
            toggleEnabled: root.adapter.hasAdapter
            primaryActionText: i18nc("@action:button", "Pair Device…") // qmllint disable unqualified
            primaryActionIconName: "list-add-symbolic"
            primaryActionEnabled: root.adapter.hasAdapter
                && root.adapter.bluetoothEnabled
            settingsActionText: i18nc("@action:button", "Open Bluetooth settings") // qmllint disable unqualified
            onBackRequested: root.backRequested()
            onToggleRequested: function(enabled) {
                root.adapter.setBluetoothEnabled(enabled)
            }
            onPrimaryActionRequested: root.adapter.openPairingWizard()
            onSettingsRequested: root.settingsRequested("bluetooth")
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Kirigami.Units.cornerRadius * 2.5
            color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.78)
            border.width: 1
            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.16)

            ListView {
                id: deviceList
                objectName: "controlCenterBluetoothDeviceList"
                anchors.fill: parent
                anchors.margins: Kirigami.Units.mediumSpacing
                clip: true
                model: root.adapter.bluetoothEnabled
                    ? root.adapter.model : null
                boundsBehavior: Flickable.StopAtBounds
                spacing: Kirigami.Units.smallSpacing
                section.property: "Section"
                section.delegate: PlasmaExtras.ListSectionHeader {
                    id: sectionHeader
                    required property string section
                    width: deviceList.width
                    text: sectionHeader.section
                }
                delegate: ControlCenterBluetoothDelegate {
                    required property var model
                    width: deviceList.width
                    device: model
                    adapter: root.adapter
                    onToggleRequested: root.adapter.changeDeviceState(
                        model.Device,
                        String(model.Ubi || ""),
                        Boolean(model.Connected),
                        Boolean(model.Connecting),
                        Boolean(model.Disconnecting))
                }

                PlasmaExtras.PlaceholderMessage {
                    anchors.centerIn: parent
                    width: Math.min(parent.width,
                        Kirigami.Units.gridUnit * 24)
                    visible: !root.adapter.hasAdapter
                        || !root.adapter.bluetoothEnabled
                        || deviceList.count === 0
                    iconName: root.adapter.bluetoothEnabled
                        ? "network-bluetooth-activated-symbolic"
                        : "network-bluetooth-inactive-symbolic"
                    text: {
                        if (!root.adapter.hasAdapter) {
                            return i18nc("@info", "No Bluetooth adapters available") // qmllint disable unqualified
                        }
                        if (!root.adapter.bluetoothEnabled) {
                            return i18nc("@info", "Bluetooth is turned off") // qmllint disable unqualified
                        }
                        return i18nc("@info", "No devices paired") // qmllint disable unqualified
                    }
                    explanation: {
                        if (!root.adapter.hasAdapter) {
                            return i18nc("@info", "Connect a Bluetooth adapter or open System Settings for details.") // qmllint disable unqualified
                        }
                        if (!root.adapter.bluetoothEnabled) {
                            return i18nc("@info", "Turn on Bluetooth to manage paired devices.") // qmllint disable unqualified
                        }
                        return i18nc("@info", "Pair a device with the official Bluetooth wizard.") // qmllint disable unqualified
                    }
                }
            }
        }
    }
}
