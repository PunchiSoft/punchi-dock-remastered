// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

FocusScope {
    id: root

    property var volumeAdapter: null
    property var brightnessAdapter: null
    property var networkAdapter: null
    property var bluetoothAdapter: null
    property var themeAdapter: null
    property var nightLightAdapter: null
    property var notificationModel: null
    property int unreadNotificationCount: 0
    property int expiredNotificationCount: 0
    property bool notificationServiceValid: false
    property bool doNotDisturbAvailable: false
    property bool doNotDisturbActive: false
    property bool motionEnabled: true
    readonly property bool wideLayout:
        width >= Kirigami.Units.gridUnit * 48

    signal networkRequested()
    signal bluetoothRequested()
    signal doNotDisturbRequested()
    signal themeToggleRequested()
    signal nightLightToggleRequested()
    signal nightLightStrengthPreviewRequested(int strength)
    signal nightLightStrengthPreviewStopped()
    signal nightLightStrengthModified(int strength)
    signal notificationCloseRequested(int index)
    signal clearNotificationsRequested()
    signal settingsRequested(string section)
    signal applicationRequested(string application)

    function focusFirstControl() {
        wifiTile.forceActiveFocus(Qt.PopupFocusReason)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        GridLayout {
            id: quickControls

            Layout.fillWidth: true
            columns: root.wideLayout ? 2 : 1
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.largeSpacing

            GridLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                columns: width >= Kirigami.Units.gridUnit * 26 ? 2 : 1
                columnSpacing: Kirigami.Units.mediumSpacing
                rowSpacing: Kirigami.Units.mediumSpacing

                ControlCenterShortcutTile {
                    id: wifiTile
                    Layout.fillWidth: true
                    text: i18nc("@action:button", "Wi-Fi") // qmllint disable unqualified
                    description: root.networkAdapter
                        ? (root.networkAdapter.wifiEnabled
                            ? i18nc("@info:status", "On — view networks") // qmllint disable unqualified
                            : i18nc("@info:status", "Off — view networks")) // qmllint disable unqualified
                        : i18nc("@info", "Network controls unavailable") // qmllint disable unqualified
                    iconName: root.networkAdapter
                        && root.networkAdapter.wifiEnabled
                        ? "network-wireless-on" : "network-wireless-off"
                    onClicked: root.networkRequested()
                }

                ControlCenterShortcutTile {
                    id: bluetoothTile
                    Layout.fillWidth: true
                    text: i18nc("@action:button", "Bluetooth") // qmllint disable unqualified
                    // The translation helpers are supplied by the plasmoid context.
                    // qmllint disable unqualified
                    description: !root.bluetoothAdapter
                        ? i18nc("@info", "Bluetooth controls unavailable")
                        : !root.bluetoothAdapter.hasAdapter
                            ? i18nc("@info:status", "No Bluetooth adapters")
                            : !root.bluetoothAdapter.bluetoothEnabled
                                ? i18nc("@info:status", "Off — view devices")
                                : root.bluetoothAdapter.connectedCount > 0
                                    ? i18np("%1 device connected",
                                        "%1 devices connected",
                                        root.bluetoothAdapter.connectedCount)
                                    : i18nc("@info:status", "On — view devices")
                    // qmllint enable unqualified
                    iconName: root.bluetoothAdapter
                        && root.bluetoothAdapter.connectedCount > 0
                        ? "network-bluetooth-activated-symbolic"
                        : root.bluetoothAdapter
                            && root.bluetoothAdapter.bluetoothEnabled
                            ? "network-bluetooth-symbolic"
                            : "network-bluetooth-inactive-symbolic"
                    onClicked: root.bluetoothRequested()
                }

                ControlCenterShortcutTile {
                    id: doNotDisturbTile
                    objectName: "controlCenterDoNotDisturbTile"
                    Layout.fillWidth: true
                    enabled: root.doNotDisturbAvailable
                    checkable: true
                    checked: root.doNotDisturbActive
                    text: i18nc("@action:button", "Do Not Disturb") // qmllint disable unqualified
                    description: !root.doNotDisturbAvailable
                        ? i18nc("@info", "Notification service unavailable") // qmllint disable unqualified
                        : root.doNotDisturbActive
                            ? i18nc("@info:status", "On — suppress notification popups") // qmllint disable unqualified
                            : i18nc("@info:status", "Off — allow notification popups") // qmllint disable unqualified
                    iconName: root.doNotDisturbActive
                        ? "notifications-disabled" : "notification-inactive"
                    trailingIconName: root.doNotDisturbActive
                        ? "checkmark-symbolic" : "go-next-symbolic"
                    onClicked: root.doNotDisturbRequested()
                }

                ControlCenterShortcutTile {
                    id: updatesTile

                    objectName: "controlCenterUpdatesTile"
                    Layout.fillWidth: true
                    text: i18nc("@action:button", "Updates") // qmllint disable unqualified
                    description: i18nc("@info", "Manage system updates") // qmllint disable unqualified
                    iconName: "update-low"
                    onClicked: root.applicationRequested("updates")
                }

            }

            ColumnLayout {
                Layout.fillWidth: !root.wideLayout
                Layout.preferredWidth: Kirigami.Units.gridUnit * 22
                Layout.maximumWidth: root.wideLayout
                    ? Kirigami.Units.gridUnit * 22 : Number.POSITIVE_INFINITY
                Layout.alignment: Qt.AlignTop | Qt.AlignRight
                spacing: Kirigami.Units.mediumSpacing

                ControlCenterControlCard {
                    id: brightnessCard
                    objectName: "controlCenterBrightnessCard"
                    Layout.fillWidth: true
                    title: i18nc("@title", "Display") // qmllint disable unqualified
                    iconName: "video-display-brightness"
                    value: root.brightnessAdapter
                        ? root.brightnessAdapter.value : 0
                    controlAvailable: root.brightnessAdapter
                        ? root.brightnessAdapter.available : false
                    settingsActionName: i18nc("@action:button", "Open display settings") // qmllint disable unqualified
                    onValueModified: function(value) {
                        if (root.brightnessAdapter) {
                            root.brightnessAdapter.setValue(value)
                        }
                    }
                    onSettingsRequested: root.settingsRequested("display")
                }

                ControlCenterControlCard {
                    id: volumeCard
                    objectName: "controlCenterVolumeCard"
                    Layout.fillWidth: true
                    title: i18nc("@title", "Sound") // qmllint disable unqualified
                    iconName: root.volumeAdapter && root.volumeAdapter.muted
                        ? "audio-volume-muted" : "audio-volume-high"
                    value: root.volumeAdapter ? root.volumeAdapter.value : 0
                    controlAvailable: root.volumeAdapter
                        ? root.volumeAdapter.available : false
                    iconActionEnabled: true
                    iconActionName: root.volumeAdapter
                        && root.volumeAdapter.muted
                        ? i18nc("@action:button", "Unmute") // qmllint disable unqualified
                        : i18nc("@action:button", "Mute") // qmllint disable unqualified
                    settingsActionName: i18nc("@action:button", "Open sound settings") // qmllint disable unqualified
                    onValueModified: function(value) {
                        if (root.volumeAdapter) {
                            root.volumeAdapter.setValue(value)
                        }
                    }
                    onIconActionTriggered: {
                        if (root.volumeAdapter) {
                            root.volumeAdapter.toggleMuted()
                        }
                    }
                    onSettingsRequested: root.settingsRequested("sound")
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.columnSpan: root.wideLayout ? 2 : 1
                spacing: Kirigami.Units.mediumSpacing

                Item {
                    Layout.fillWidth: true
                }

                ControlCenterQuickActionButton {
                    id: themeButton

                    objectName: "controlCenterThemeButton"
                    enabled: !root.themeAdapter
                        || !root.themeAdapter.busy
                    checkable: true
                    checked: root.themeAdapter
                        ? root.themeAdapter.darkMode : false
                    text: i18nc("@action:button", "Light and dark mode") // qmllint disable unqualified
                    description: !root.themeAdapter
                            || !root.themeAdapter.available
                        ? i18nc("@info", "Open appearance settings") // qmllint disable unqualified
                        : checked
                            ? i18nc("@action:button", "Switch to light mode") // qmllint disable unqualified
                            : i18nc("@action:button", "Switch to dark mode") // qmllint disable unqualified
                    iconName: checked
                        ? "weather-clear-night" : "weather-clear"
                    onClicked: root.themeToggleRequested()
                }

                ControlCenterQuickActionButton {
                    id: nightLightButton

                    objectName: "controlCenterNightLightButton"
                    enabled: !root.nightLightAdapter
                        || !root.nightLightAdapter.busy
                    checkable: true
                    checked: root.nightLightAdapter
                        && root.nightLightAdapter.available
                        && root.nightLightAdapter.configured
                    text: i18nc("@action:button", "Night Light") // qmllint disable unqualified
                    description: !root.nightLightAdapter
                            || !root.nightLightAdapter.available
                        ? i18nc("@info", "Open Night Light settings") // qmllint disable unqualified
                        : !root.nightLightAdapter.configured
                            ? i18nc("@action:button", "Turn on Night Light") // qmllint disable unqualified
                            : root.nightLightAdapter.inhibited
                                && !root.nightLightAdapter.ownsInhibition
                                ? i18nc("@info:status", "Paused by another application") // qmllint disable unqualified
                                : root.nightLightAdapter.inhibited
                                    ? i18nc("@info:status", "Night Light is paused") // qmllint disable unqualified
                                    : i18nc("@action:button", "Turn off Night Light") // qmllint disable unqualified
                    iconName: checked && !root.nightLightAdapter.inhibited
                        ? "redshift-status-on" : "redshift-status-off"
                    onClicked: root.nightLightToggleRequested()
                }

                ControlCenterQuickActionButton {
                    id: calculatorButton

                    objectName: "controlCenterCalculatorButton"
                    text: i18nc("@action:button", "Calculator") // qmllint disable unqualified
                    iconName: "accessories-calculator"
                    onClicked: root.applicationRequested("calculator")
                }

                ControlCenterQuickActionButton {
                    id: screenshotPlaceholderButton

                    objectName: "controlCenterScreenshotPlaceholderButton"
                    enabled: false
                    text: i18nc("@action:button", "Screenshot") // qmllint disable unqualified
                    iconName: "spectacle"
                }
            }

            ControlCenterNightLightStrength {
                objectName: "controlCenterNightLightStrengthControl"
                Layout.fillWidth: true
                Layout.columnSpan: root.wideLayout ? 2 : 1
                visible: root.nightLightAdapter
                    && root.nightLightAdapter.available
                strength: root.nightLightAdapter
                    ? root.nightLightAdapter.strength : 0
                controlAvailable: root.nightLightAdapter
                    && root.nightLightAdapter.available
                    && root.nightLightAdapter.configured
                    && !root.nightLightAdapter.inhibited
                    && !root.nightLightAdapter.busy
                settingsActionName: i18nc("@action:button", "Configure Night Light") // qmllint disable unqualified
                onPreviewRequested: function(strength) {
                    root.nightLightStrengthPreviewRequested(strength)
                }
                onPreviewStopped: root.nightLightStrengthPreviewStopped()
                onStrengthModified: function(strength) {
                    root.nightLightStrengthModified(strength)
                }
                onSettingsRequested: root.settingsRequested("nightlight")
            }
        }

        Rectangle {
            id: notificationsSection

            objectName: "controlCenterNotificationsSection"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Kirigami.Units.gridUnit * 12
            radius: Kirigami.Units.cornerRadius * 2.5
            color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.78)
            border.width: 1
            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.16)
            Accessible.role: Accessible.Pane
            Accessible.name: i18nc("@title", "Notifications") // qmllint disable unqualified

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.mediumSpacing

                RowLayout {
                    Layout.fillWidth: true

                    Controls.Label {
                        text: i18nc("@title", "Notifications") // qmllint disable unqualified
                        font.bold: true
                    }

                    Controls.Label {
                        Layout.fillWidth: true
                        visible: root.unreadNotificationCount > 0
                        // The translation helper is supplied by the plasmoid context.
                        // qmllint disable unqualified
                        text: i18np("%1 unread notification",
                            "%1 unread notifications",
                            root.unreadNotificationCount)
                        // qmllint enable unqualified
                        font: Kirigami.Theme.smallFont
                        opacity: 0.72
                    }

                    PlasmaComponents.Button {
                        id: clearNotificationsButton
                        visible: root.expiredNotificationCount > 0
                        text: i18n("Clear") // qmllint disable unqualified
                        icon.name: "edit-clear-history"
                        onClicked: root.clearNotificationsRequested()
                    }

                    PlasmaComponents.Button {
                        id: notificationSettingsButton
                        text: i18nc("@action:button", "Notification settings") // qmllint disable unqualified
                        icon.name: "configure"
                        onClicked: root.settingsRequested("notifications")
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ListView {
                        id: notificationList
                        objectName: "controlCenterNotificationList"
                        anchors.fill: parent
                        activeFocusOnTab: count > 0
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.notificationModel
                        delegate: ControlCenterNotificationDelegate {
                            required property int index

                            onCloseRequested:
                                root.notificationCloseRequested(index)
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: Kirigami.Units.mediumSpacing
                        visible: notificationList.count === 0

                        Kirigami.Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Kirigami.Units.iconSizes.large
                            height: width
                            source: root.notificationServiceValid
                                ? "notification-inactive"
                                : "notifications-disabled"
                            opacity: 0.72
                            Accessible.ignored: true
                        }

                        Controls.Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            // The translation helper is supplied by the plasmoid context.
                            // qmllint disable unqualified
                            text: root.notificationServiceValid
                                ? i18nc("@info", "No notifications")
                                : i18nc("@info", "Notification service unavailable")
                            // qmllint enable unqualified
                            opacity: 0.72
                        }
                    }
                }
            }
        }
    }
}
