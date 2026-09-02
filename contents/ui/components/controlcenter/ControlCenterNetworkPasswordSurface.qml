// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../punchimenu" as PunchiMenu

PunchiMenu.PunchiMenuModalSurface {
    id: root

    required property var adapter
    property var network: null
    readonly property string networkName:
        String(network ? network.ItemUniqueName || network.Name || "" : "")

    accessibleName: i18nc("@title:window", "Connect to %1", networkName) // qmllint disable unqualified
    preferredWidth: Kirigami.Units.gridUnit * 24
    preferredHeight: Kirigami.Units.gridUnit * 14
    panelBackgroundImagePath: "solid/dialogs/background"
    panelBackgroundOpacity: 1.0
    backdropOpacity: 0.64

    function openForNetwork(candidate) {
        network = candidate
        passwordField.clear()
        active = true
        Qt.callLater(function() {
            if (root.active) {
                passwordField.forceActiveFocus(Qt.PopupFocusReason)
            }
        })
    }

    function closeAndClear() {
        active = false
        passwordField.clear()
        network = null
    }

    onDismissed: closeAndClear()
    onConcealed: passwordField.clear()

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.mediumSpacing

        Controls.Label {
            Layout.fillWidth: true
            text: i18nc("@title:window", "Connect to %1", root.networkName) // qmllint disable unqualified
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.25
            font.bold: true
            wrapMode: Text.Wrap
        }

        Controls.Label {
            Layout.fillWidth: true
            text: i18nc("@info", "Enter the Wi-Fi password. It is used only for this connection attempt.") // qmllint disable unqualified
            opacity: 0.72
            wrapMode: Text.Wrap
        }

        PlasmaComponents.TextField {
            id: passwordField
            Layout.fillWidth: true
            placeholderText: i18nc("@label", "Password") // qmllint disable unqualified
            echoMode: TextInput.Password
            passwordCharacter: "●"
            Accessible.name: placeholderText
            onAccepted: connectButton.clicked()
        }

        Controls.Label {
            Layout.fillWidth: true
            visible: passwordField.text.length > 0
                && !root.adapter.passwordAcceptable(
                    root.network, passwordField.text)
            text: i18nc("@info:validation", "The password format is not valid for this network.") // qmllint disable unqualified
            color: Kirigami.Theme.negativeTextColor
            wrapMode: Text.Wrap
        }

        Item {
            Layout.fillHeight: true
        }

        RowLayout {
            Layout.fillWidth: true
            layoutDirection: Qt.RightToLeft

            PlasmaComponents.Button {
                id: connectButton
                text: i18nc("@action:button", "Connect") // qmllint disable unqualified
                enabled: root.network !== null
                    && root.adapter.passwordAcceptable(
                        root.network, passwordField.text)
                onClicked: {
                    const candidate = root.network
                    const password = passwordField.text
                    if (root.adapter.changeConnectionState(candidate, password)) {
                        root.closeAndClear()
                    }
                }
            }

            PlasmaComponents.Button {
                text: i18nc("@action:button", "Cancel") // qmllint disable unqualified
                onClicked: root.closeAndClear()
            }
        }
    }
}
