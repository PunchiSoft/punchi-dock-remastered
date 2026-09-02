// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.components as PlasmaComponents
import ".." as Components

FocusScope {
    id: root

    required property var controller
    property var themeAdapter: null
    property var nightLightAdapter: null
    property bool controlCenterOpen: false
    property string pendingSettingsSection: ""
    property string pendingApplicationAction: ""
    property string currentPage: "home"

    readonly property bool motionEnabled: Kirigami.Units.longDuration > 0
    readonly property int animOpenDuration:
        Math.round(Kirigami.Units.longDuration * 1.1)
    readonly property int animCloseDuration: motionEnabled
        ? Math.max(1, Math.round(Kirigami.Units.shortDuration * 1.4))
        : 1
    readonly property int unreadNotificationCount:
        Math.max(0, notificationHistory.unreadNotificationsCount)
    readonly property bool doNotDisturbActive:
        NotificationManager.Server.valid
        && NotificationManager.Server.inhibited
    readonly property bool providersActive: visible
    readonly property var volumeAdapter: volumeProvider.status === Loader.Ready
        ? volumeProvider.item : null
    readonly property var brightnessAdapter:
        brightnessProvider.status === Loader.Ready
        ? brightnessProvider.item : null
    readonly property var networkAdapter: networkProvider.status === Loader.Ready
        ? networkProvider.item : null
    readonly property var bluetoothAdapter:
        bluetoothProvider.status === Loader.Ready
        ? bluetoothProvider.item : null
    readonly property ControlCenterNetworkPage networkPage:
        networkPageLoader.item as ControlCenterNetworkPage
    readonly property var bluetoothPage: bluetoothPageLoader.item

    signal closeFinished()

    objectName: "controlCenterOverlay"
    visible: controlCenterOpen || fullscreenBackdrop.opacity > 0.01
    enabled: controlCenterOpen
    Keys.onEscapePressed: handleEscape()

    NotificationManager.Notifications {
        id: notificationHistory

        showExpired: true
        showDismissed: true
        showJobs: false
        sortMode: NotificationManager.Notifications.SortByDate
        groupMode: NotificationManager.Notifications.GroupDisabled
        urgencies: NotificationManager.Notifications.LowUrgency
            | NotificationManager.Notifications.NormalUrgency
            | NotificationManager.Notifications.CriticalUrgency
    }

    NotificationManager.Settings {
        id: notificationSettings
    }

    Loader {
        id: volumeProvider
        active: root.providersActive
        asynchronous: false
        source: Qt.resolvedUrl("ControlCenterVolumeAdapter.qml")
    }

    Loader {
        id: brightnessProvider
        active: root.providersActive
        asynchronous: false
        source: Qt.resolvedUrl("ControlCenterBrightnessAdapter.qml")
    }

    Loader {
        id: networkProvider
        active: root.providersActive
        asynchronous: false
        source: Qt.resolvedUrl("ControlCenterNetworkAdapter.qml")
    }

    Loader {
        id: bluetoothProvider
        active: root.providersActive
        asynchronous: false
        source: Qt.resolvedUrl("ControlCenterBluetoothAdapter.qml")
    }

    function openOverlay() {
        closeTimer.stop()
        pendingSettingsSection = ""
        pendingApplicationAction = ""
        currentPage = "home"
        if (root.nightLightAdapter) {
            root.nightLightAdapter.refresh()
        }
        controlCenterOpen = true
        root.forceActiveFocus()
        Qt.callLater(function() {
            if (root.controlCenterOpen) {
                homePage.focusFirstControl()
            }
        })
    }

    function showNetworkPage() {
        if (!networkAdapter) {
            requestSettings("network")
            return
        }
        currentPage = "network"
        Qt.callLater(function() {
            if (root.controlCenterOpen && root.networkPage) {
                root.networkPage.focusFirstControl()
            }
        })
    }

    function showBluetoothPage() {
        if (!bluetoothAdapter) {
            requestSettings("bluetooth")
            return
        }
        currentPage = "bluetooth"
        Qt.callLater(function() {
            if (root.controlCenterOpen && root.bluetoothPage) {
                root.bluetoothPage.focusFirstControl()
            }
        })
    }

    function showHomePage() {
        currentPage = "home"
        Qt.callLater(function() {
            if (root.controlCenterOpen) {
                homePage.focusFirstControl()
            }
        })
    }

    function handleEscape() {
        if (passwordSurface.active) {
            passwordSurface.closeAndClear()
        } else if (currentPage === "network"
                || currentPage === "bluetooth") {
            showHomePage()
        } else {
            forceClose()
        }
    }

    function toggleDoNotDisturb() {
        if (!NotificationManager.Server.valid) {
            return
        }

        if (root.doNotDisturbActive) {
            notificationSettings.notificationsInhibitedUntil = undefined
            if (typeof notificationSettings.revokeApplicationInhibitions
                    === "function") {
                notificationSettings.revokeApplicationInhibitions()
            }
            if ("fullscreenFocused" in notificationSettings) {
                notificationSettings.fullscreenFocused = false
            }
            if ("screensMirrored" in notificationSettings) {
                notificationSettings.screensMirrored = false
            }
        } else {
            const inhibitedUntil = new Date()
            inhibitedUntil.setFullYear(inhibitedUntil.getFullYear() + 1)
            notificationSettings.notificationsInhibitedUntil = inhibitedUntil
        }
        notificationSettings.save()
    }

    function toggleTheme() {
        if (!root.themeAdapter || !root.themeAdapter.toggleMode()) {
            requestSettings("appearance")
        }
    }

    function toggleNightLight() {
        if (!root.nightLightAdapter
                || !root.nightLightAdapter.toggleEnabled()) {
            requestSettings("nightlight")
        }
    }

    function previewNightLightStrength(strength) {
        if (root.nightLightAdapter) {
            root.nightLightAdapter.previewStrength(strength)
        }
    }

    function setNightLightStrength(strength) {
        if (root.nightLightAdapter) {
            root.nightLightAdapter.setStrength(strength)
        }
    }

    function stopNightLightPreview() {
        if (root.nightLightAdapter) {
            root.nightLightAdapter.stopPreview()
        }
    }

    function requestSettings(section) {
        passwordSurface.closeAndClear()
        pendingApplicationAction = ""
        pendingSettingsSection = String(section || "")
        forceClose()
    }

    function requestApplication(action) {
        passwordSurface.closeAndClear()
        pendingSettingsSection = ""
        pendingApplicationAction = String(action || "")
        forceClose()
    }

    function forceClose() {
        if (!controlCenterOpen && closeTimer.running) {
            return
        }
        passwordSurface.closeAndClear()
        controlCenterOpen = false
        closeTimer.restart()
    }

    function resetOverlay() {
        closeTimer.stop()
        passwordSurface.closeAndClear()
        pendingSettingsSection = ""
        pendingApplicationAction = ""
        currentPage = "home"
        controlCenterOpen = false
    }

    Timer {
        id: closeTimer
        interval: root.animCloseDuration
        repeat: false
        onTriggered: {
            const section = root.pendingSettingsSection
            const application = root.pendingApplicationAction
            root.pendingSettingsSection = ""
            root.pendingApplicationAction = ""
            root.currentPage = "home"
            root.closeFinished()
            if (section.length > 0 && root.controller) {
                Qt.callLater(function() {
                    root.controller.openSettings(section)
                })
            } else if (application.length > 0 && root.controller) {
                Qt.callLater(function() {
                    root.controller.openApplication(application)
                })
            }
        }
    }

    Components.PunchiFullscreenBackdrop {
        id: fullscreenBackdrop
        anchors.fill: parent
        active: root.controlCenterOpen
        blurEnabled: true
        backgroundOpacity: 0.50
        motionEnabled: root.motionEnabled
        openDuration: root.animOpenDuration
        closeDuration: root.animCloseDuration
        onClicked: root.forceClose()
    }

    ControlCenterRightRail {
        id: mainContent
        objectName: "controlCenterMainContent"
        opacity: root.controlCenterOpen ? 1.0 : 0.0
        scale: root.controlCenterOpen ? 1.0 : 0.97
        transformOrigin: Item.Center

        Behavior on opacity {
            enabled: root.motionEnabled
            NumberAnimation {
                duration: root.controlCenterOpen
                    ? root.animOpenDuration : root.animCloseDuration
                easing.type: root.controlCenterOpen
                    ? Easing.OutCubic : Easing.InCubic
            }
        }

        Behavior on scale {
            enabled: root.motionEnabled
            NumberAnimation {
                duration: root.controlCenterOpen
                    ? root.animOpenDuration : root.animCloseDuration
                easing.type: root.controlCenterOpen
                    ? Easing.OutCubic : Easing.InCubic
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.mediumSpacing

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Controls.Label {
                        Layout.fillWidth: true
                        text: i18nc("@title", "Control Center") // qmllint disable unqualified
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.5
                        font.bold: true
                    }

                    Controls.Label {
                        Layout.fillWidth: true
                        // The translation helpers are supplied by the plasmoid context.
                        // qmllint disable unqualified
                        text: root.currentPage === "network"
                            ? i18nc("@info", "Choose and manage a Wi-Fi connection")
                            : root.currentPage === "bluetooth"
                                ? i18nc("@info", "Connect and manage paired Bluetooth devices")
                                : i18nc("@info", "Quick access to system status and settings")
                        // qmllint enable unqualified
                        opacity: 0.72
                    }
                }

                PlasmaComponents.ToolButton {
                    id: closeButton
                    icon.name: "window-close"
                    text: i18nc("@action:button", "Close") // qmllint disable unqualified
                    display: PlasmaComponents.AbstractButton.IconOnly
                    Accessible.name: text
                    onClicked: root.forceClose()

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.currentPage === "network" ? 1
                    : root.currentPage === "bluetooth" ? 2 : 0

                ControlCenterHomePage {
                    id: homePage
                    volumeAdapter: root.volumeAdapter
                    brightnessAdapter: root.brightnessAdapter
                    networkAdapter: root.networkAdapter
                    bluetoothAdapter: root.bluetoothAdapter
                    themeAdapter: root.themeAdapter
                    nightLightAdapter: root.nightLightAdapter
                    notificationModel: notificationHistory
                    unreadNotificationCount: root.unreadNotificationCount
                    expiredNotificationCount:
                        notificationHistory.expiredNotificationsCount
                    notificationServiceValid: NotificationManager.Server.valid
                    doNotDisturbAvailable: NotificationManager.Server.valid
                    doNotDisturbActive: root.doNotDisturbActive
                    motionEnabled: root.motionEnabled
                    onNetworkRequested: root.showNetworkPage()
                    onBluetoothRequested: root.showBluetoothPage()
                    onDoNotDisturbRequested: root.toggleDoNotDisturb()
                    onThemeToggleRequested: root.toggleTheme()
                    onNightLightToggleRequested: root.toggleNightLight()
                    onNightLightStrengthPreviewRequested: function(strength) {
                        root.previewNightLightStrength(strength)
                    }
                    onNightLightStrengthPreviewStopped:
                        root.stopNightLightPreview()
                    onNightLightStrengthModified: function(strength) {
                        root.setNightLightStrength(strength)
                    }
                    onNotificationCloseRequested: function(index) {
                        notificationHistory.close(
                            notificationHistory.index(index, 0))
                    }
                    onClearNotificationsRequested: notificationHistory.clear(
                        NotificationManager.Notifications.ClearExpired)
                    onSettingsRequested: function(section) {
                        root.requestSettings(section)
                    }
                    onApplicationRequested: function(application) {
                        root.requestApplication(application)
                    }
                }

                Loader {
                    id: networkPageLoader
                    active: root.networkAdapter !== null
                    asynchronous: false
                    sourceComponent: Component {
                        ControlCenterNetworkPage {
                            adapter: root.networkAdapter
                            onBackRequested: root.showHomePage()
                            onSettingsRequested: function(section) {
                                root.requestSettings(section)
                            }
                        }
                    }
                }

                Loader {
                    id: bluetoothPageLoader
                    active: root.currentPage === "bluetooth"
                        && root.bluetoothAdapter !== null
                    asynchronous: false
                    sourceComponent: Component {
                        ControlCenterBluetoothPage {
                            adapter: root.bluetoothAdapter
                            onBackRequested: root.showHomePage()
                            onSettingsRequested: function(section) {
                                root.requestSettings(section)
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: root.networkAdapter
        enabled: root.networkAdapter !== null

        function onPasswordRequested(network) {
            passwordSurface.openForNetwork(network)
        }

        function onActivationFailed(message) {
            if (root.networkPage) {
                root.networkPage.showError(message)
            }
        }
    }

    ControlCenterNetworkPasswordSurface {
        id: passwordSurface
        anchors.fill: parent
        z: 20
        adapter: root.networkAdapter
        motionEnabled: root.motionEnabled
    }
}
