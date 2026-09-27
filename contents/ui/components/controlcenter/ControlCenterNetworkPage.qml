// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras

FocusScope {
    id: root

    required property var adapter
    property string errorMessage: ""
    // Inline presentation: the page is opened inside the Wi-Fi row of the home
    // page instead of replacing it, so it hides its navigation row and keeps its
    // own controls.
    property bool inlineMode: false

    signal backRequested()
    signal settingsRequested(string section)

    function focusFirstControl(reason) {
        pageHeader.focusFirstControl(reason)
    }

    function showError(message) {
        errorMessage = String(message || "")
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.mediumSpacing

        ControlCenterPageHeader {
            id: pageHeader

            Layout.fillWidth: true
            navigationRowVisible: !root.inlineMode
            headerObjectName: "controlCenterNetworkHeader"
            navigationRowObjectName: "controlCenterNetworkNavigationRow"
            actionsRowObjectName: "controlCenterNetworkActionsRow"
            backButtonObjectName: "controlCenterNetworkBackButton"
            toggleObjectName: "controlCenterWifiSwitch"
            primaryActionObjectName: "controlCenterNetworkScanButton"
            settingsActionObjectName: "controlCenterNetworkSettingsButton"
            title: i18nc("@title", "Networks") // qmllint disable unqualified
            backActionName: i18nc("@action:button", "Back to Control Center") // qmllint disable unqualified
            toggleText: i18nc("@option:check", "Wi-Fi") // qmllint disable unqualified
            toggleChecked: root.adapter.wifiEnabled
            toggleEnabled: root.adapter.wifiHardwareEnabled
            primaryActionText: i18nc("@action:button", "Scan for networks") // qmllint disable unqualified
            primaryActionIconName: "view-refresh-symbolic"
            primaryActionEnabled: root.adapter.wifiEnabled
                && root.adapter.wifiHardwareEnabled
                && !root.adapter.scanning
            settingsActionText: i18nc("@action:button", "Open network settings") // qmllint disable unqualified
            onBackRequested: root.backRequested()
            onToggleRequested: function(enabled) {
                root.adapter.setWifiEnabled(enabled)
            }
            onPrimaryActionRequested: root.adapter.requestScan()
            onSettingsRequested: root.settingsRequested("network")
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: root.errorMessage.length > 0
            text: root.errorMessage
            type: Kirigami.MessageType.Error
            showCloseButton: true
            onVisibleChanged: {
                if (!visible) {
                    root.errorMessage = ""
                }
            }
        }

        PlasmaComponents.TextField {
            id: searchField
            objectName: "controlCenterNetworkSearchField"
            Layout.fillWidth: true
            placeholderText: i18nc("@label:textbox", "Search networks…") // qmllint disable unqualified
            Accessible.name: placeholderText
            inputMethodHints: Qt.ImhNoPredictiveText
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Kirigami.Units.cornerRadius * 2.5
            color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.78)
            border.width: 1
            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.16)

            // The desktop style keeps its scrollbar on the trailing edge and
            // reserves its column without Plasma's decorative separator. Keep
            // the style's own bar so its geometry and padding stay together.
            Controls.ScrollView {
                id: networkScroll

                objectName: "controlCenterNetworkScrollView"
                anchors.fill: parent
                anchors.margins: Kirigami.Units.mediumSpacing

                ListView {
                    id: networkList
                    objectName: "controlCenterNetworkList"
                    model: root.adapter.model
                    boundsBehavior: Flickable.StopAtBounds
                    spacing: Kirigami.Units.smallSpacing
                    section.property: "Section"
                    section.delegate: PlasmaExtras.ListSectionHeader {
                        id: sectionHeader
                        required property string section
                        width: networkList.width
                        text: sectionHeader.section
                    }
                    delegate: ControlCenterNetworkDelegate {
                        required property var model
                        width: networkList.width
                        network: model
                        adapter: root.adapter
                        searchText: searchField.text
                    }

                    PlasmaExtras.PlaceholderMessage {
                        anchors.centerIn: parent
                        width: Math.min(parent.width,
                            Kirigami.Units.gridUnit * 24)
                        visible: networkList.count === 0
                            || !root.adapter.wifiEnabled
                        iconName: root.adapter.wifiEnabled
                            ? "edit-none" : "network-wireless-off"
                        text: root.adapter.wifiEnabled
                            ? i18nc("@info", "No available networks") // qmllint disable unqualified
                            : i18nc("@info", "Wi-Fi is turned off") // qmllint disable unqualified
                        explanation: root.adapter.wifiEnabled
                            ? i18nc("@info", "Try scanning again or open Network Settings.") // qmllint disable unqualified
                            : i18nc("@info", "Turn on Wi-Fi to search for networks.") // qmllint disable unqualified
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        if (adapter.wifiEnabled && adapter.wifiHardwareEnabled
                && !adapter.scanning) {
            adapter.requestScan()
        }
    }
}
