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
    // One tile, one hover state. Icon and labels claim hover for themselves, so a
    // pointer area behind them stops reporting as soon as the pointer leaves the
    // empty margin. This area is stacked above the content instead: it accepts no
    // button, so presses still reach the button and the free space below it, and it
    // hands the wheel back to the list so the row stays scrollable.
    readonly property bool rowHovered: rowHoverArea.containsMouse

    visible: matchesSearch
    implicitHeight: visible ? Kirigami.Units.gridUnit * 3.5 : 0
    Accessible.role: Accessible.ListItem
    Accessible.name: networkName

    // Hover only, on top of the content: it covers the whole tile, including the
    // button band, and never takes a press or the wheel away from the list.
    MouseArea {
        id: rowHoverArea

        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        z: 1
        hoverEnabled: true
        enabled: !root.busy
        cursorShape: Qt.PointingHandCursor
        Accessible.ignored: true
        onWheel: function(wheel) {
            wheel.accepted = false
        }
    }

    // Press target for the free space of the tile. Declared behind the content, as
    // in the Night Light row, so the button keeps its own press.
    MouseArea {
        id: rowPointer

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        enabled: !root.busy
        Accessible.ignored: true
        onClicked: root.adapter.changeConnectionState(root.network, "")
    }

    Rectangle {
        anchors.fill: parent
        radius: Kirigami.Units.cornerRadius * 1.5
        color: root.activeFocus || root.rowHovered
            ? Qt.alpha(Kirigami.Theme.highlightColor, 0.24)
            : "transparent"
        // Pointer and focus feedback share the fill; only the focus ring is
        // exclusive to the keyboard. The fill fades on the theme scale while the
        // border stays immediate, so focus is visible in the same frame it
        // arrives. Same feedback profile as ControlCenterShortcutTile.
        border.width: root.activeFocus ? 2 : 0
        border.color: Kirigami.Theme.highlightColor

        Behavior on color {
            ColorAnimation {
                duration: root.activeFocus
                    ? Math.max(1, Kirigami.Units.shortDuration)
                    : Math.max(1,
                        Math.round(Kirigami.Units.shortDuration * 0.8))
            }
        }

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

            objectName: "controlCenterNetworkStateButton"
            // The tile owns the hover feedback; the button must not take it for
            // itself, or the row would light up in two separate pieces.
            hoverEnabled: false
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
