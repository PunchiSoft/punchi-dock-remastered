#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MAIN = (ROOT / "contents/ui/main.qml").read_text(encoding="utf-8")
LOGIC = (ROOT / "contents/code/logic.js").read_text(encoding="utf-8")
PALETTE = (ROOT / "contents/ui/config/AddItemPalette.qml").read_text(
    encoding="utf-8"
)
CONFIG_ITEMS = (
    ROOT / "contents/ui/config/code/configItems.js"
).read_text(encoding="utf-8")
WORKFLOW = (
    ROOT / "contents/ui/config/code/configItemsWorkflowHelper.js"
).read_text(encoding="utf-8")
DOCK_ITEM = (ROOT / "contents/ui/components/DockItem.qml").read_text(
    encoding="utf-8"
)
BACKDROP = (
    ROOT / "contents/ui/components/PunchiFullscreenBackdrop.qml"
).read_text(encoding="utf-8")
PUNCHIMENU = (
    ROOT / "contents/ui/components/punchimenu/PunchiMenuOverlay.qml"
).read_text(encoding="utf-8")
OVERLAY = (
    ROOT / "contents/ui/components/controlcenter/ControlCenterOverlay.qml"
).read_text(encoding="utf-8")
RIGHT_RAIL = (
    ROOT / "contents/ui/components/controlcenter/ControlCenterRightRail.qml"
).read_text(encoding="utf-8")
LAYOUT_METRICS = (
    ROOT / "contents/ui/components/controlcenter/ControlCenterLayoutMetrics.js"
).read_text(encoding="utf-8")
CONTROLLER = (
    ROOT / "contents/ui/components/ControlCenterController.qml"
).read_text(encoding="utf-8")
HOME_PAGE = (
    ROOT / "contents/ui/components/controlcenter/ControlCenterHomePage.qml"
).read_text(encoding="utf-8")
SHORTCUT_TILE = (
    ROOT / "contents/ui/components/controlcenter/ControlCenterShortcutTile.qml"
).read_text(encoding="utf-8")
EXPANDABLE_SECTION = (
    ROOT
    / "contents/ui/components/controlcenter/ControlCenterExpandableSection.qml"
).read_text(encoding="utf-8")
NOTIFICATION_DELEGATE = (
    ROOT
    / "contents/ui/components/controlcenter/ControlCenterNotificationDelegate.qml"
).read_text(encoding="utf-8")
CONTROL_CARD = (
    ROOT / "contents/ui/components/controlcenter/ControlCenterControlCard.qml"
).read_text(encoding="utf-8")
QUICK_ACTION = (
    ROOT
    / "contents/ui/components/controlcenter/ControlCenterQuickActionButton.qml"
).read_text(encoding="utf-8")
NIGHT_LIGHT_STRENGTH = (
    ROOT
    / "contents/ui/components/controlcenter/ControlCenterNightLightStrength.qml"
).read_text(encoding="utf-8")
THEME_ADAPTER = (
    ROOT / "src/controlcenterthemeadapter.cpp"
).read_text(encoding="utf-8")
NIGHT_LIGHT_ADAPTER = (
    ROOT / "src/controlcenternightlightadapter.cpp"
).read_text(encoding="utf-8")
VOLUME_OSD_ADAPTER = (
    ROOT / "src/controlcentervolumeosdadapter.cpp"
).read_text(encoding="utf-8")
VOLUME_ADAPTER = (
    ROOT / "contents/ui/components/controlcenter/ControlCenterVolumeAdapter.qml"
).read_text(encoding="utf-8")
BRIGHTNESS_ADAPTER = (
    ROOT / "contents/ui/components/controlcenter/ControlCenterBrightnessAdapter.qml"
).read_text(encoding="utf-8")
NETWORK_ADAPTER = (
    ROOT / "contents/ui/components/controlcenter/ControlCenterNetworkAdapter.qml"
).read_text(encoding="utf-8")
NETWORK_PAGE = (
    ROOT / "contents/ui/components/controlcenter/ControlCenterNetworkPage.qml"
).read_text(encoding="utf-8")
BLUETOOTH_ADAPTER = (
    ROOT / "contents/ui/components/controlcenter/ControlCenterBluetoothAdapter.qml"
).read_text(encoding="utf-8")
BLUETOOTH_PAGE = (
    ROOT / "contents/ui/components/controlcenter/ControlCenterBluetoothPage.qml"
).read_text(encoding="utf-8")
PAGE_HEADER = (
    ROOT / "contents/ui/components/controlcenter/ControlCenterPageHeader.qml"
).read_text(encoding="utf-8")
AUDIO_PAGE = (
    ROOT / "contents/ui/components/controlcenter/ControlCenterAudioPage.qml"
).read_text(encoding="utf-8")
AUDIO_ITEM = (
    ROOT / "contents/ui/components/controlcenter/ControlCenterAudioItem.qml"
).read_text(encoding="utf-8")
BLUETOOTH_DELEGATE = (
    ROOT / "contents/ui/components/controlcenter/ControlCenterBluetoothDelegate.qml"
).read_text(encoding="utf-8")
PASSWORD_SURFACE = (
    ROOT / "contents/ui/components/controlcenter/ControlCenterNetworkPasswordSurface.qml"
).read_text(encoding="utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


require(
    '"control-center"' in LOGIC.split("singletonDockItemTypes", 1)[1],
    "The Control Center item must be a singleton persistent type.",
)
require(
    '"type": "control-center"' in PALETTE
    and 'hasItemType("control-center")' in PALETTE
    and 'hasItemType("control-center")' in WORKFLOW,
    "The item palette must add at most one Control Center item.",
)
require(
    'if (type === "control-center")' in CONFIG_ITEMS
    and '"name": "Control Center"' in CONFIG_ITEMS
    and '"icon": "preferences-system"' in CONFIG_ITEMS
    and "function pruneControlCenter(item)" in CONFIG_ITEMS,
    "The configuration layer must create and preserve a canonical item.",
)
require(
    'itemType === "control-center"' in DOCK_ITEM
    and 'i18nc("@title", "Control Center")' in DOCK_ITEM,
    "The dock delegate must expose an interactive and localized item.",
)
require(
    "function toggleControlCenter(anchorItem)" in MAIN
    and "controlCenterFullscreenDialogComponent.createObject(root)" in MAIN
    and 'objectName: "controlCenterFullscreenDialog"' in MAIN
    and "location: PlasmaCore.Types.Floating" in MAIN
    and "width: Screen.width" in MAIN
    and "height: Screen.height" in MAIN
    and "function openWithReveal()" in MAIN
    and "function closeWithFade()" in MAIN
    and "function closeImmediately()" in MAIN,
    "The click path must own a lazy full-screen Plasma dialog lifecycle.",
)
require(
    "Punchi.BlurBehindController" in BACKDROP
    and "fullWindow: true" in BACKDROP
    and "enabled: root.active && root.blurEnabled" in BACKDROP
    and "Components.PunchiFullscreenBackdrop" in PUNCHIMENU
    and "Components.PunchiFullscreenBackdrop" in OVERLAY,
    "PunchiMenu and Control Center must share the same full-screen backdrop.",
)
require(
    "id: closeTimer" in OVERLAY
    and "controlCenterOpen = false" in OVERLAY
    and "root.closeFinished()" in OVERLAY
    and "onCloseFinished: controlCenterDialog.closeImmediately()" in MAIN,
    "The dialog must stay visible until the overlay fade-out completes.",
)
for section, module in {
    "network": "kcm_networkmanagement",
    "bluetooth": "kcm_bluetooth",
    "sound": "kcm_pulseaudio",
    "display": "kcm_kscreen",
    "notifications": "kcm_notifications",
    "appearance": "kcm_lookandfeel",
    "nightlight": "kcm_nightlight",
}.items():
    require(
        f'case "{section}":' in CONTROLLER and f'"{module}"' in CONTROLLER,
        f"The {section} shortcut must target its official KDE KCM.",
    )

require(
    "KCMUtils.KCMLauncher.openSystemSettings(moduleName)" in CONTROLLER
    and "QProcess" not in CONTROLLER
    and "execute" not in CONTROLLER,
    "System settings must open through KCMUtils without shell execution.",
)
require(
    'case "updates":' in CONTROLLER
    and '"org.kde.discover.desktop", "Updates"' in CONTROLLER
    and 'case "calculator":' in CONTROLLER
    and '"org.kde.kcalc.desktop"' in CONTROLLER
    and "applicationLauncher: systemDiscovery" in MAIN
    and "launchApplicationByCommand" not in CONTROLLER
    and "QProcess" not in CONTROLLER,
    "Quick applications must use closed KService identities and Discover's official action.",
)
require(
    "NotificationManager.Notifications" in OVERLAY
    and "unreadNotificationsCount" in OVERLAY
    and "ControlCenterNotificationDelegate" in HOME_PAGE
    and "NotificationManager.Server.valid" in OVERLAY,
    "The surface must consume the public Plasma notification model reactively.",
)
require(
    "required property bool closable" in NOTIFICATION_DELEGATE
    and "signal closeRequested()" in NOTIFICATION_DELEGATE
    and 'objectName: "notificationCloseButton"' in NOTIFICATION_DELEGATE
    and "visible: root.closable" in NOTIFICATION_DELEGATE
    and "onClicked: root.closeRequested()" in NOTIFICATION_DELEGATE
    and "signal notificationCloseRequested(int index)" in HOME_PAGE
    and "signal clearNotificationsRequested()" in HOME_PAGE
    and "root.notificationCloseRequested(index)" in HOME_PAGE
    and "root.clearNotificationsRequested()" in HOME_PAGE
    and "notificationHistory.close(" in OVERLAY
    and "NotificationManager.Notifications.ClearExpired" in OVERLAY,
    "Notification history must expose official close and clear actions.",
)
require(
    'objectName: "controlCenterNotificationsSection"' in HOME_PAGE
    and "Layout.fillHeight: true" in HOME_PAGE
    and "Layout.minimumHeight: Kirigami.Units.gridUnit * 12" in HOME_PAGE
    and "ControlCenterExpandableSection" not in HOME_PAGE
    and "notificationsExpanded" not in HOME_PAGE
    and "collapseNotifications" not in OVERLAY
    and 'objectName: "controlCenterNotificationsTile"' not in HOME_PAGE
    and 'text: i18nc("@title", "Notifications")' in HOME_PAGE
    and 'i18np("%1 unread notification"' in HOME_PAGE,
    "Notification history must always occupy the remaining home-page height.",
)
require(
    "Behavior on expansionProgress" in EXPANDABLE_SECTION
    and "Easing.OutCubic" in EXPANDABLE_SECTION
    and "Easing.InCubic" in EXPANDABLE_SECTION
    and "Translate" in EXPANDABLE_SECTION
    and "motionEnabled" in EXPANDABLE_SECTION
    and "Timer" not in EXPANDABLE_SECTION,
    "The accordion must use a reduced-motion-aware declarative transition.",
)
for label in (
    "Wi-Fi",
    "Bluetooth",
    "Sound",
    "Display",
    "Notifications",
    "Do Not Disturb",
    "Updates",
    "Calculator",
    "Screenshot",
    "Light and dark mode",
    "Night Light",
):
    require(
        f'"{label}"' in HOME_PAGE,
        f"The basic surface is missing the {label} access.",
    )

require(
    "ControlCenterQuickActionButton" in HOME_PAGE
    and 'objectName: "controlCenterUpdatesTile"' in HOME_PAGE
    and 'root.applicationRequested("updates")' in HOME_PAGE
    and 'root.applicationRequested("calculator")' in HOME_PAGE
    and 'objectName: "controlCenterScreenshotPlaceholderButton"' in HOME_PAGE
    and 'objectName: "controlCenterThemeButton"' in HOME_PAGE
    and 'objectName: "controlCenterNightLightButton"' in HOME_PAGE
    and 'objectName: "controlCenterDoNotDisturbTile"' in HOME_PAGE
    and "enabled: false" in HOME_PAGE
    and "Accessible.name: text" in QUICK_ACTION
    and "Accessible.description: description" in QUICK_ACTION
    and "Accessible.checkable: root.checkable" in QUICK_ACTION
    and "Accessible.checked: root.checked" in QUICK_ACTION
    and QUICK_ACTION.count("Kirigami.Units.gridUnit * 3") == 2
    and "Kirigami.Units.iconSizes.medium" in QUICK_ACTION
    and "ControlCenterNightLightStrength" in HOME_PAGE
    and 'objectName: "controlCenterNightLightStrengthSlider"'
    in NIGHT_LIGHT_STRENGTH
    and 'i18nc("@label", "Night Light intensity")'
    in NIGHT_LIGHT_STRENGTH
    and "from: 0" in NIGHT_LIGHT_STRENGTH
    and "to: 100" in NIGHT_LIGHT_STRENGTH
    and 'icon.name: "configure"' in NIGHT_LIGHT_STRENGTH
    and "leftPadding: Kirigami.Units.largeSpacing" in SHORTCUT_TILE
    and "rightPadding: Kirigami.Units.largeSpacing" in SHORTCUT_TILE,
    "The compact actions must be accessible, theme-aware, and keep Screenshot inert.",
)

require(
    'QStandardPaths::findExecutable(QStringLiteral("plasma-apply-lookandfeel"))'
    in THEME_ADAPTER
    and 'm_process->start(m_executablePath, {QStringLiteral("--apply"), targetThemeId})'
    in THEME_ADAPTER
    and '"DefaultLightLookAndFeel"' in THEME_ADAPTER
    and '"DefaultDarkLookAndFeel"' in THEME_ADAPTER
    and 'QStringLiteral("/bin/sh")' not in THEME_ADAPTER
    and 'QStringLiteral("-c")' not in THEME_ADAPTER
    and "QDBusConnection::sessionBus().asyncCall" in NIGHT_LIGHT_ADAPTER
    and "toggleEnabled()" in NIGHT_LIGHT_ADAPTER
    and 'group.writeEntry("Active", false, KConfig::Notify)'
    in NIGHT_LIGHT_ADAPTER
    and 'group.writeEntry("Active", true, KConfig::Notify)'
    in NIGHT_LIGHT_ADAPTER
    and 'group.writeEntry("Mode", s_constantMode, KConfig::Notify)'
    in NIGHT_LIGHT_ADAPTER
    and 'group.writeEntry("NightTemperature", temperature, KConfig::Notify)'
    in NIGHT_LIGHT_ADAPTER
    and 'nightLightCall(QStringLiteral("preview"))'
    in NIGHT_LIGHT_ADAPTER
    and 'nightLightCall(QStringLiteral("stopPreview"))'
    in NIGHT_LIGHT_ADAPTER
    and "root.nightLightAdapter.toggleEnabled()" in OVERLAY
    and "root.nightLightAdapter.refresh()" in OVERLAY
    and 'group.isEntryImmutable("Active")' in NIGHT_LIGHT_ADAPTER
    and 'group.isEntryImmutable("NightTemperature")' in NIGHT_LIGHT_ADAPTER
    and 'nightLightCall(QStringLiteral("inhibit"))'
    in NIGHT_LIGHT_ADAPTER
    and 'nightLightCall(QStringLiteral("uninhibit"))'
    in NIGHT_LIGHT_ADAPTER
    and "m_inhibitionCookie" in NIGHT_LIGHT_ADAPTER
    and "QProcess" not in NIGHT_LIGHT_ADAPTER,
    "Theme and Night Light must use native KDE contracts without shell commands.",
)

require(
    "org.kde.plasma.private" not in OVERLAY
    and "org.kde.plasma.private" not in CONTROLLER,
    "Optional private backends must not be root load-time dependencies.",
)
require(
    'source: Qt.resolvedUrl("ControlCenterVolumeAdapter.qml")' in OVERLAY
    and 'source: Qt.resolvedUrl("ControlCenterBrightnessAdapter.qml")' in OVERLAY
    and 'source: Qt.resolvedUrl("ControlCenterNetworkAdapter.qml")' in OVERLAY
    and 'source: Qt.resolvedUrl("ControlCenterBluetoothAdapter.qml")' in OVERLAY
    and "active: root.providersActive" in OVERLAY,
    "System integrations must remain isolated behind deferred loaders.",
)
require(
    "BluezQt.Manager.bluetoothOperational" in BLUETOOTH_ADAPTER
    and "BluezQt.Manager.bluetoothBlocked" in BLUETOOTH_ADAPTER
    and "BluezQt.Manager.rfkill.state" in BLUETOOTH_ADAPTER
    and "PlasmaBt.DevicesProxyModel" in BLUETOOTH_ADAPTER
    and "PlasmaBt.SharedDevicesStateProxyModel" in BLUETOOTH_ADAPTER
    and "connectToDevice" in BLUETOOTH_ADAPTER
    and "disconnectFromDevice" in BLUETOOTH_ADAPTER
    and "registerConnectingCallForDeviceUbi" in BLUETOOTH_ADAPTER
    and "registerDisconnectingCallForDeviceUbi" in BLUETOOTH_ADAPTER
    and "PlasmaBt.LaunchApp.launchWizard()" in BLUETOOTH_ADAPTER,
    "The Bluetooth adapter must reproduce BlueDevil's state and action contract.",
)
require(
    'currentPage = "bluetooth"' in OVERLAY
    and "ControlCenterBluetoothPage" in OVERLAY
    and "ControlCenterBluetoothDelegate" in BLUETOOTH_PAGE
    and 'section.property: "Section"' in BLUETOOTH_PAGE
    and "ConnectionFailed" in BLUETOOTH_DELEGATE
    and "Battery.percentage" in BLUETOOTH_DELEGATE
    and "ControlCenterPageHeader" in BLUETOOTH_PAGE
    and "ControlCenterPageHeader" in NETWORK_PAGE
    and 'headerObjectName: "controlCenterBluetoothHeader"' in BLUETOOTH_PAGE
    and 'headerObjectName: "controlCenterNetworkHeader"' in NETWORK_PAGE
    and "ColumnLayout" in PAGE_HEADER
    and PAGE_HEADER.count("RowLayout") == 2
    and "display: PlasmaComponents.AbstractButton.IconOnly" in PAGE_HEADER
    and "elide: Text.ElideRight" in PAGE_HEADER
    and 'onBluetoothRequested: root.showBluetoothPage()' in OVERLAY,
    "Bluetooth must open a responsive internal paired-device view with live status.",
)
require(
    "PlasmaVolume.PreferredDevice.sink" in VOLUME_ADAPTER
    and "PlasmaVolume.PulseAudio.NormalVolume" in VOLUME_ADAPTER
    and "sink.volume =" in VOLUME_ADAPTER
    and "sink.muted =" in VOLUME_ADAPTER,
    "The volume adapter must control the preferred Plasma audio sink.",
)
require(
    "PlasmaVolume.SinkModel" in VOLUME_ADAPTER
    and "PlasmaVolume.SourceModel" in VOLUME_ADAPTER
    and "PlasmaVolume.SinkInputModel" in VOLUME_ADAPTER
    and "PlasmaVolume.SourceOutputModel" in VOLUME_ADAPTER
    and "PlasmaVolume.PulseObjectFilterModel" in VOLUME_ADAPTER
    and "PlasmaVolume.ListItemMenu" in VOLUME_ADAPTER
    and "PlasmaVolume.GlobalConfig" in VOLUME_ADAPTER
    and "PlasmaVolume.GlobalService.globalMuteSinks()" in VOLUME_ADAPTER
    and "PlasmaVolume.GlobalService.globalMuteSources()" in VOLUME_ADAPTER
    and "globalConfig.save()" in VOLUME_ADAPTER
    and "function openItemOptions" in VOLUME_ADAPTER,
    "The deferred audio adapter must follow plasma-pa's device, stream, and menu contract.",
)
require(
    'currentPage = "sound"' in OVERLAY
    and "ControlCenterAudioPage" in OVERLAY
    and "onSoundRequested: root.showSoundPage()" in OVERLAY
    and 'Controls.TabButton {' in AUDIO_PAGE
    and 'i18nc("@title:tab", "Devices")' in AUDIO_PAGE
    and 'i18nc("@title:tab", "Applications")' in AUDIO_PAGE
    and "root.adapter.outputDevicesModel" in AUDIO_PAGE
    and "root.adapter.inputDevicesModel" in AUDIO_PAGE
    and "root.adapter.playbackStreamsModel" in AUDIO_PAGE
    and "root.adapter.recordingStreamsModel" in AUDIO_PAGE
    and "ControlCenterAudioItem" in AUDIO_PAGE
    and "setDefaultDevice" in AUDIO_ITEM
    and "toggleObjectMuted" in AUDIO_ITEM
    and "setObjectValue" in AUDIO_ITEM
    and "openItemOptions" in AUDIO_ITEM
    and 'objectName: "controlCenterNavigationActionButton"' in CONTROL_CARD,
    "Sound must open an accessible internal Devices/Applications page with native interactions.",
)
require(
    'KSharedConfig::openConfig(QStringLiteral("plasmaparc"))'
    in VOLUME_OSD_ADAPTER
    and 's_volumeOsdKey = "VolumeOsd"' in VOLUME_OSD_ADAPTER
    and 'group.writeEntry(s_volumeOsdKey, updatedVisibility, KConfig::Notify)'
    in VOLUME_OSD_ADAPTER
    and "KConfigWatcher::configChanged" in VOLUME_OSD_ADAPTER
    and '"MuteOsd"' not in VOLUME_OSD_ADAPTER
    and 'secondaryActionIconName: volumeCard.secondaryActionChecked'
    in HOME_PAGE
    and '? "view-visible" : "view-hidden"' in HOME_PAGE
    and 'onVolumeOsdToggleRequested: root.toggleVolumeOsd()' in OVERLAY,
    "The Sound card must toggle only Plasma's global volume OSD through KConfig.",
)
require(
    "Brightness.ScreenBrightnessControl" in BRIGHTNESS_ADAPTER
    and "screenControl.displays" in BRIGHTNESS_ADAPTER
    and "screenControl.setBrightness" in BRIGHTNESS_ADAPTER
    and 'displays.KItemModels.KRoleNames.role("displayName")'
    in BRIGHTNESS_ADAPTER
    and 'displays.KItemModels.KRoleNames.role("brightness")'
    in BRIGHTNESS_ADAPTER
    and 'displays.KItemModels.KRoleNames.role("maxBrightness")'
    in BRIGHTNESS_ADAPTER
    and "function onRowsMoved()" in BRIGHTNESS_ADAPTER,
    "The brightness adapter must follow PowerDevil's model-attached role contract.",
)
require(
    re.search(
        r"(?<!\.)KItemModels\.KRoleNames\.role\(", BRIGHTNESS_ADAPTER
    )
    is None,
    "KRoleNames must never be resolved without the displays model attachment.",
)
require(
    "PlasmaNM.NetworkModel" in NETWORK_ADAPTER
    and "PlasmaNM.MobileProxyModel" in NETWORK_ADAPTER
    and "PlasmaNM.EnabledConnections" in NETWORK_ADAPTER
    and "PlasmaNM.Handler" in NETWORK_ADAPTER
    and "activateConnection" in NETWORK_ADAPTER
    and "deactivateConnection" in NETWORK_ADAPTER
    and "addAndActivateConnection" in NETWORK_ADAPTER
    and "requestScan" in NETWORK_ADAPTER,
    "The internal network page must use Plasma NetworkManager models and handler.",
)
require(
    'currentPage = "network"' in OVERLAY
    and "ControlCenterNetworkPage" in OVERLAY
    and "ControlCenterNetworkDelegate" in NETWORK_PAGE
    and 'placeholderText: i18nc("@label:textbox", "Search networks…")'
    in NETWORK_PAGE,
    "Clicking Wi-Fi must navigate to a searchable internal network view.",
)
require(
    "echoMode: TextInput.Password" in PASSWORD_SURFACE
    and "passwordField.clear()" in PASSWORD_SURFACE
    and "snapshotNetwork" in NETWORK_ADAPTER
    and "console." not in PASSWORD_SURFACE
    and "console." not in NETWORK_ADAPTER,
    "Wi-Fi credentials must remain ephemeral and must never be logged.",
)
require(
    "ControlCenterControlCard" in HOME_PAGE
    and "onValueModified" in HOME_PAGE
    and "Layout.alignment: Qt.AlignTop | Qt.AlignRight" in HOME_PAGE
    and "Layout.preferredWidth: Kirigami.Units.gridUnit * 22" in HOME_PAGE
    and "width >= Kirigami.Units.gridUnit * 48" in HOME_PAGE
    and 'objectName: "controlCenterMainContent"' in OVERLAY
    and "ControlCenterRightRail" in OVERLAY
    and "anchors.top: parent.top" in RIGHT_RAIL
    and "anchors.right: parent.right" in RIGHT_RAIL
    and "anchors.topMargin: root.edgeMargin" in RIGHT_RAIL
    and "anchors.rightMargin: root.edgeMargin" in RIGHT_RAIL
    and "LayoutMetrics.availableWidth(" in RIGHT_RAIL
    and "LayoutMetrics.availableHeight(" in RIGHT_RAIL
    and "function edgeMargin(gridUnit)" in LAYOUT_METRICS
    and "function minimumRailWidth(gridUnit)" in LAYOUT_METRICS
    and "function maximumRailWidth(gridUnit)" in LAYOUT_METRICS
    and "function targetRailWidth(containerWidth)" in LAYOUT_METRICS
    and "return width / 3" in LAYOUT_METRICS
    and "function availableWidth(containerWidth, gridUnit)" in LAYOUT_METRICS
    and "function availableHeight(containerHeight, gridUnit)" in LAYOUT_METRICS
    and "anchors.centerIn: parent" not in OVERLAY,
    "Direct controls must use KUnits, stay top-right, and respond on narrow screens.",
)
require(
    "PlasmaComponents.Slider" in CONTROL_CARD
    and "Accessible.name: root.title" in CONTROL_CARD
    and "Kirigami.Units.cornerRadius * 2.5" in CONTROL_CARD,
    "The macOS-inspired control card must remain a native accessible Plasma control.",
)
