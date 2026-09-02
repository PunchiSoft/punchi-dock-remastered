// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

FocusScope {
    id: root

    required property var network
    required property var adapter
    property string searchText: ""
    readonly property string networkName:
        String(network ? network.ItemUniqueName || network.Name || "" : "")
    readonly property bool matchesSearch: searchText.length === 0
        || networkName.toLocaleLowerCase().includes(
            searchText.toLocaleLowerCase())
    readonly property bool connected: adapter
        ? adapter.isActivated(network) : false
    readonly property bool busy: adapter ? adapter.isBusy(network) : false

    visible: matchesSearch
    implicitHeight: visible ? Kirigami.Units.gridUnit * 3.5 : 0
    Accessible.role: Accessible.ListItem
    Accessible.name: networkName

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
            source: String(root.network.ConnectionIcon
                || (root.connected ? "network-wireless-connected-100"
                    : "network-wireless-available"))
            Accessible.ignored: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Controls.Label {
                Layout.fillWidth: true
                text: root.networkName
                font.bold: root.connected
                elide: Text.ElideRight
            }

            Controls.Label {
                Layout.fillWidth: true
                text: root.connected
                    ? i18nc("@info:status Network connection", "Connected") // qmllint disable unqualified
                    : String(root.network.SecurityTypeString || "")
                opacity: 0.68
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
            text: root.connected
                ? i18nc("@action:button", "Disconnect") // qmllint disable unqualified
                : i18nc("@action:button", "Connect") // qmllint disable unqualified
            icon.name: root.connected
                ? "network-disconnect-symbolic" : "network-connect-symbolic"
            enabled: !root.busy
            Accessible.description: root.networkName
            onClicked: root.adapter.changeConnectionState(root.network, "")
        }
    }
}
