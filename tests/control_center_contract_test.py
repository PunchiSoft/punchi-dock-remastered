#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MAIN = (ROOT / "contents/ui/main.qml").read_text(encoding="utf-8")
LOGIC = (ROOT / "contents/code/logic.js").read_text(encoding="utf-8")
ITEM_CATALOG = (ROOT / "contents/ui/config/code/itemTypeCatalog.js").read_text(
    encoding="utf-8"
)
ITEM_DRAFT_CONTROLLER = (
    ROOT / "contents/ui/config/ItemDraftController.qml"
).read_text(encoding="utf-8")
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
FLOATING_GEOMETRY = (
    ROOT
    / "contents/ui/components/controlcenter/ControlCenterFloatingGeometry.qml"
).read_text(encoding="utf-8")
CONTROL_CENTER_DIALOG = (
    ROOT / "contents/ui/config/components/ControlCenterDialog.qml"
).read_text(encoding="utf-8")
CONTROL_CENTER_OPTIONS_PANEL = (
    ROOT / "contents/ui/config/ControlCenterOptionsPanel.qml"
).read_text(encoding="utf-8")
CONTROLLER = (
    ROOT / "contents/ui/components/ControlCenterController.qml"
).read_text(encoding="utf-8")
DOCK_ITEMS_CONTROLLER = (
    ROOT / "contents/ui/components/DockItemsController.qml"
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
HOVER_REVEAL = (
    ROOT
    / "contents/ui/components/controlcenter/ControlCenterHoverReveal.qml"
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
APPLICATION_PLACEHOLDER = (
    ROOT
    / "contents/ui/components/controlcenter/ControlCenterApplicationPlaceholderButton.qml"
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
BLUETOOTH_COMPATIBILITY = (
    ROOT
    / "contents/ui/components/controlcenter/ControlCenterBluetoothCompatibility.js"
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
NETWORK_DELEGATE = (
    ROOT / "contents/ui/components/controlcenter/ControlCenterNetworkDelegate.qml"
).read_text(encoding="utf-8")
BLUETOOTH_DELEGATE = (
    ROOT / "contents/ui/components/controlcenter/ControlCenterBluetoothDelegate.qml"
).read_text(encoding="utf-8")
PASSWORD_SURFACE = (
    ROOT / "contents/ui/components/controlcenter/ControlCenterNetworkPasswordSurface.qml"
).read_text(encoding="utf-8")
PAGE_SLOT = (
    ROOT / "contents/ui/components/controlcenter/ControlCenterPageSlot.qml"
).read_text(encoding="utf-8")
NETWORK_SUBMENU = (
    ROOT
    / "contents/ui/components/controlcenter/ControlCenterNetworkSubmenu.qml"
).read_text(encoding="utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


require(
    '"control-center"' in LOGIC.split("singletonDockItemTypes", 1)[1],
    "The Control Center item must be a singleton persistent type.",
)
require(
    'entry("control-center"' in ITEM_CATALOG
    and 'root.isSingletonType(type) && root.hasItemType(type)'
    in ITEM_DRAFT_CONTROLLER,
    "The canonical selector and draft controller must reject a second Control Center item.",
)
require(
    'if (type === "control-center")' in CONFIG_ITEMS
    and '"name": "Control Center"' in CONFIG_ITEMS
    and '"icon": "preferences-system"' in CONFIG_ITEMS
    and "function pruneControlCenter(item)" in CONFIG_ITEMS,
    "The configuration layer must create and preserve a canonical item.",
)
require(
    "function normalizedControlCenterMode(value)" in CONFIG_ITEMS
    and '["fullScreen", "floating"]' in CONFIG_ITEMS
    and '"controlCenterMode": "floating"' in CONFIG_ITEMS
    and "function openControlCenterDialog(index)" in WORKFLOW
    and "function setControlCenterMode(mode)" in WORKFLOW
    and 'selectedItemType === "control-center"' in WORKFLOW
    # The mode control lives in the options panel extracted from the dialog; the
    # dialog keeps its public API and hosts that panel.
    and 'objectName: "controlCenterModeCombo"' in CONTROL_CENTER_OPTIONS_PANEL
    and "contentItem: ControlCenterOptionsPanel {" in CONTROL_CENTER_DIALOG
    and "property string controlCenterMode" in CONTROL_CENTER_DIALOG,
    "The item editor must expose a closed, per-item Control Center mode.",
)
require(
    "function setControlCenterMode(mode)" in DOCK_ITEMS_CONTROLLER
    and "ConfigItemsJS.normalizedControlCenterMode(mode)"
    in DOCK_ITEMS_CONTROLLER
    and "root.syncDockItemsConfiguration()" in DOCK_ITEMS_CONTROLLER,
    "Control Center mode changes must persist through the reactive dock controller.",
)
require(
    'itemType === "control-center"' in DOCK_ITEM
    and 'i18nc("@title", "Control Center")' in DOCK_ITEM,
    "The dock delegate must expose an interactive and localized item.",
)
require(
    "function toggleControlCenter(anchorItem)" in MAIN
    and "controlCenterFloatingDialogComponent" in MAIN
    and "controlCenterFullscreenDialogComponent" in MAIN
    and "component.createObject(root)" in MAIN
    and 'objectName: "controlCenterFullscreenDialog"' in MAIN
    and 'objectName: "controlCenterFloatingDialog"' in MAIN
    and "location: PlasmaCore.Types.Floating" in MAIN
    and "width: Screen.width" in MAIN
    and "height: Screen.height" in MAIN
    and "function openWithReveal()" in MAIN
    and "function closeWithFade()" in MAIN
    and "function closeImmediately()" in MAIN,
    "The click path must own a lazy full-screen Plasma dialog lifecycle.",
)
require(
    "Punchi.BlurBehindController" in MAIN
    and "maskSource: controlCenterFloatingOverlay.backgroundBlurMaskSource"
    in MAIN
    and "useMaskSourceInsets: true" in MAIN
    and "maskOffset: controlCenterFloatingOverlay.backgroundBlurMaskOffset"
    in MAIN
    and 'imagePath: "widgets/background"' in OVERLAY
    and "PunchiMenuComponents.PunchiMenuMappedSurfaceGeometry" in OVERLAY,
    "Floating mode must reuse the themed PunchiMenu mask and inset blur contract.",
)
require(
    "function positionFor(windowWidth, windowHeight)" in FLOATING_GEOMETRY
    and "LayoutMetrics.availableWidth(" in FLOATING_GEOMETRY
    and "LayoutMetrics.availableHeight(" in FLOATING_GEOMETRY
    and "absoluteAvailableRect" in FLOATING_GEOMETRY,
    "Floating mode must derive its size from the full-screen rail and active screen.",
)
require(
    # One driver for the surface: opacity, scale and travel derive from it, so the
    # panel cannot cross-fade while it travels and no second animator can
    # disagree with the entrance. Reported as unconvincing by the user.
    "property real revealProgress: controlCenterOpen ? 1.0 : 0.0" in OVERLAY
    and "Behavior on revealProgress" in OVERLAY
    and "Behavior on opacity" not in OVERLAY
    and "Behavior on x" not in OVERLAY
    and "Behavior on scale" not in OVERLAY
    and "revealProgress > 0.001" in OVERLAY
    and "Easing.OutCubic" in OVERLAY
    and "root.motionEnabled" in OVERLAY,
    "The Control Center surface must reveal itself from a single progress "
    "driver.",
)
require(
    # Floating: anchored reveal from the docked corner, without fading the panel.
    "import \"ControlCenterRevealMetrics.js\" as RevealMetrics" in OVERLAY
    and "RevealMetrics.revealOpacity(root.revealProgress)" in OVERLAY
    and "RevealMetrics.revealScale(root.revealProgress," in OVERLAY
    and "readonly property int revealOrigin: Item.TopRight" in OVERLAY
    and "transformOrigin: root.revealOrigin" in OVERLAY
    and "opacity: root.floatingMode" in OVERLAY
    and "scale: root.floatingMode" in OVERLAY
    # Full screen keeps the travel: a full-height rail must not be scaled.
    and "RevealMetrics.revealTravel(root.revealProgress," in OVERLAY
    and "transform: Translate" in OVERLAY
    and "Kirigami.Units.gridUnit * 4" in OVERLAY,
    "Floating mode must reveal the panel from its docked corner, while the "
    "full-screen rail keeps its horizontal travel.",
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
    # The notifications are the primary area of the home page: they keep the
    # remaining height at the foot of the frame instead of scrolling away with the
    # quick controls, and they stay there while a section opens.
    and "anchors.bottom: parent.bottom" in HOME_PAGE
    and "height: root.notificationsArea" in HOME_PAGE
    and "readonly property real minimumNotificationsHeight:" in HOME_PAGE
    and "homeLayout.implicitHeight - Kirigami.Units.largeSpacing" in HOME_PAGE
    and "anchors.bottomMargin: root.notificationsArea" in HOME_PAGE
    and "heldNotificationsHeight = notificationsArea" in HOME_PAGE
    and "ControlCenterExpandableSection" not in HOME_PAGE
    and "notificationsExpanded" not in HOME_PAGE
    and "collapseNotifications" not in OVERLAY
    and 'objectName: "controlCenterNotificationsTile"' not in HOME_PAGE
    and 'text: i18nc("@title", "Notifications")' in HOME_PAGE
    and 'i18np("%1 unread notification"' in HOME_PAGE,
    "Notification history must always occupy the remaining home-page height at "
    "the foot of the frame.",
)
require(
    "ControlCenterHoverReveal" in HOME_PAGE
    and "nightLightButton.hovered" in HOME_PAGE
    and "nightLightButton.activeFocus" in HOME_PAGE
    and "ControlCenterExpandableSection" in HOVER_REVEAL
    and "property bool revealRequested" in HOVER_REVEAL
    and "property bool interacting" in HOVER_REVEAL
    and "property bool usable" in HOVER_REVEAL
    and "property int collapseDelay" in HOVER_REVEAL
    and "Kirigami.Units.shortDuration" in HOVER_REVEAL
    and "readonly property bool interacting" in NIGHT_LIGHT_STRENGTH
    and "strengthSlider.hovered" in NIGHT_LIGHT_STRENGTH
    and "settingsButton.hovered" in NIGHT_LIGHT_STRENGTH,
    "The extra night-light row must reveal on pointer or keyboard focus, stay "
    "open while used and reuse the shared expandable transition.",
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
    # The strip derives its capacity from the real width: the fixed controls stay
    # and the remaining positions reuse the project's empty "add" slot.
    and "readonly property int quickActionFixedCount: 3" in HOME_PAGE
    and "readonly property int quickActionMinimumCount: 4" in HOME_PAGE
    and "readonly property int quickActionMaximumCount: 8" in HOME_PAGE
    and "LayoutMetrics.quickActionCapacity(" in HOME_PAGE
    and "LayoutMetrics.quickActionSpacing(" in HOME_PAGE
    and "model: quickActionsRow.emptySlotCount" in HOME_PAGE
    and HOME_PAGE.count("ControlCenterApplicationPlaceholderButton {") == 1
    and "applicationPlaceholderCount" not in HOME_PAGE
    and 'objectName: "controlCenterQuickActionsRow"' in HOME_PAGE
    and 'iconName: "list-add-symbolic"' in APPLICATION_PLACEHOLDER
    and "enabled: false" in APPLICATION_PLACEHOLDER
    and "Accessible.ignored: true" in APPLICATION_PLACEHOLDER
    and 'objectName: "controlCenterThemeButton"' in HOME_PAGE
    and 'objectName: "controlCenterNightLightButton"' in HOME_PAGE
    and 'objectName: "controlCenterDoNotDisturbTile"' in HOME_PAGE
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
    "The compact actions must be accessible, theme-aware, and keep app placeholders inert.",
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
    and "BluetoothCompatibility.registerPendingCall" in BLUETOOTH_ADAPTER
    and "registerConnectingCallForDeviceUbi" in BLUETOOTH_COMPATIBILITY
    and "registerDisconnectingCallForDeviceUbi" in BLUETOOTH_COMPATIBILITY
    and "registerPendingCallForDeviceUbi" in BLUETOOTH_COMPATIBILITY
    and "function registerPendingCall" in BLUETOOTH_COMPATIBILITY
    and '"disconnecting"' in BLUETOOTH_ADAPTER
    and "SharedDevicesStateProxyModel.disconnecting" not in BLUETOOTH_ADAPTER
    and "PlasmaBt.LaunchApp.launchWizard()" in BLUETOOTH_ADAPTER,
    "The Bluetooth adapter must normalize modern and legacy BlueDevil contracts.",
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
    "StackLayout" not in OVERLAY
    and OVERLAY.count("ControlCenterPageSlot {") == 4
    and 'objectName: "controlCenterHomePageSlot"' in OVERLAY
    and 'objectName: "controlCenterNetworkPageSlot"' in OVERLAY
    and 'objectName: "controlCenterBluetoothPageSlot"' in OVERLAY
    and 'objectName: "controlCenterAudioPageSlot"' in OVERLAY
    and 'current: root.currentPage === "home"' in OVERLAY
    and 'current: root.currentPage === "network"' in OVERLAY
    and 'current: root.currentPage === "bluetooth"' in OVERLAY
    and 'current: root.currentPage === "sound"' in OVERLAY
    and "motionEnabled: root.motionEnabled" in OVERLAY
    and "fullHeight: pageHost.height" in OVERLAY
    and OVERLAY.count("anchors.top: parent.top") == 4
    and "function settlePage(pageName)" in OVERLAY
    and "typeof target.focusFirstControl === \"function\"" in OVERLAY
    and "root.networkPage.focusFirstControl()" not in OVERLAY
    and "root.bluetoothPage.focusFirstControl()" not in OVERLAY
    and "root.audioPage.focusFirstControl()" not in OVERLAY
    and OVERLAY.count("settlePage(") == 5
    and "property real progress: current ? 1.0 : 0.0" in PAGE_SLOT
    and "Behavior on progress" in PAGE_SLOT
    and "signal transitionFinished(bool current)" in PAGE_SLOT
    and OVERLAY.count("onTransitionFinished") == 4
    and OVERLAY.count("root.settlePage(") == 4
    and "property bool current: false" in PAGE_SLOT
    and "property bool motionEnabled: true" in PAGE_SLOT
    and "property real fullHeight: 0" in PAGE_SLOT
    and "visible: progress > 0.001" in PAGE_SLOT
    and "enabled: current" in PAGE_SLOT
    and "z: root.current ? 1 : 0" in PAGE_SLOT
    and "clip: true" in PAGE_SLOT
    and "Timer" not in PAGE_SLOT
    and "Kirigami.Units.longDuration" in PAGE_SLOT
    and "Kirigami.Units.gridUnit" in PAGE_SLOT
    # The slot clips a plain container, so every page must fill it; an unsized
    # FocusScope page left the Control Center empty once before.
    and re.search(
        r"ControlCenterHomePage \{\n\s+id: homePage[\s\S]{0,240}?"
        r"anchors\.fill: parent",
        OVERLAY,
    )
    is not None
    and all(
        re.search(
            r"id: %s\n[\s\S]{0,240}?anchors\.fill: parent" % loader,
            OVERLAY,
        )
        is not None
        for loader in (
            "networkPageLoader",
            "bluetoothPageLoader",
            "audioPageLoader",
        )
    ),
    "Both Control Center directions must share one declarative, interruptible page transition.",
)
require(
    all(
        "readonly property bool feedbackActive" in source
        and "Behavior on color" in source
        and "Behavior on opacity" in source
        and "Behavior on border.color" in source
        and "ColorAnimation {" in source
        and "Math.max(1, Kirigami.Units.shortDuration)" in source
        and "Math.round(Kirigami.Units.shortDuration * 0.8)" in source
        # The focus ring must stay immediate: it cannot wait for a transition.
        and "Behavior on border.width" not in source
        for source in (SHORTCUT_TILE, QUICK_ACTION)
    ),
    "Control Center tiles and quick actions must transition hover, press and "
    "selection feedback on the theme duration while keeping the focus ring "
    "immediate.",
)
require(
    "StackLayout" not in AUDIO_PAGE
    and AUDIO_PAGE.count("ControlCenterPageSlot {") == 2
    and 'objectName: "controlCenterAudioDevicesSlot"' in AUDIO_PAGE
    and 'objectName: "controlCenterAudioApplicationsSlot"' in AUDIO_PAGE
    and "current: tabBar.currentIndex === 0" in AUDIO_PAGE
    and "current: tabBar.currentIndex === 1" in AUDIO_PAGE
    and "motionEnabled: root.motionEnabled" in AUDIO_PAGE
    and "property bool motionEnabled: true" in AUDIO_PAGE
    # The slot clips a plain container, so both tab views must fill it.
    and AUDIO_PAGE.count("anchors.fill: parent") >= 2
    and "motionEnabled: root.motionEnabled" in OVERLAY,
    "Both audio tabs must share the Control Center page transition model.",
)
require(
    all(
        "MouseArea {" in source
        # The tile owns hover from an area stacked above the content, because the
        # icon and the labels claim hover for themselves when the pointer area
        # stays behind them. Reported by the user.
        and "rowHovered: rowHoverArea.containsMouse" in source
        and "acceptedButtons: Qt.NoButton" in source
        and "z: 1" in source
        and "onWheel: function(wheel)" in source
        and "wheel.accepted = false" in source
        # Press target for the free space of the tile, behind the content so the
        # button keeps its own press.
        and "acceptedButtons: Qt.LeftButton" in source
        and "hoverEnabled: true" in source
        and "containsMouse" in source
        # One tile, one hover state: the labelled button must not claim hover.
        and "hoverEnabled: false" in source
        and "|| stateButton.hovered" not in source
        and "cursorShape: Qt.PointingHandCursor" in source
        # One accessible control per action: both row areas stay ignored.
        and source.count("Accessible.ignored: true") >= 2
        and "Behavior on color" in source
        and "ColorAnimation {" in source
        and "Math.max(1, Kirigami.Units.shortDuration)" in source
        and "Behavior on border.width" not in source
        for source in (NETWORK_DELEGATE, BLUETOOTH_DELEGATE)
    )
    and 'changeConnectionState(root.network, "")' in NETWORK_DELEGATE
    and "onClicked: root.requestToggle()" in BLUETOOTH_DELEGATE,
    "The network and Bluetooth rows are single tiles: one hover state and one "
    "press target for the free space, for the same action as their explicit "
    "button, which stays the accessible control without claiming hover.",
)
require(
    "add: Transition {" in HOME_PAGE
    and "remove: Transition {" in HOME_PAGE
    and 'property: "opacity"' in HOME_PAGE
    and "displaced: Transition" not in HOME_PAGE,
    "Notification entry and removal fade only; positions must not animate.",
)
require(
    "Kirigami.Units.longDuration > 1" in OVERLAY,
    "The reduce-motion criterion must be able to become false in Plasma.",
)
require(
    # The Wi-Fi row opens its own section in place instead of replacing the page,
    # and the rest of the home page leaves the frame through its bottom edge.
    "property bool networkSubmenuOpen: false" in HOME_PAGE
    and "signal networkSubmenuToggleRequested()" in HOME_PAGE
    and "objectName: \"controlCenterWifiTile\"" in HOME_PAGE
    and "expandable: true" in HOME_PAGE
    and "expanded: root.networkSubmenuOpen" in HOME_PAGE
    and "root.networkSubmenuToggleRequested()" in HOME_PAGE
    and 'root.settingsRequested("network")' in HOME_PAGE
    and "ControlCenterNetworkSubmenu {" in HOME_PAGE
    # The section takes exactly the height left below itself, so the remaining
    # content starts at the bottom edge of the frame and stops being visible.
    and "topInViewport:" in HOME_PAGE
    and "quickControls.y + y - homeScrollView.contentY" in HOME_PAGE
    and "expandedHeight: Math.max(0," in HOME_PAGE
    and "homeScrollView.height - topInViewport" in HOME_PAGE
    # Content that left the frame must not be reachable while it is hidden.
    and "interactive: networkSubmenu.expansionProgress < 0.001" in HOME_PAGE
    and "homeScrollView.contentY = 0" in HOME_PAGE
    and "networkSubmenu.focusFirstControl(reason)" in HOME_PAGE
    and "wifiTile.forceActiveFocus" in HOME_PAGE
    # The Wi-Fi/Bluetooth row is the anchor; the marked row (Do Not Disturb and
    # Updates) is declared after the section, so opening it pushes that row out of
    # the frame together with the control cards and the quick actions.
    and HOME_PAGE.index("id: networkSubmenu")
    < HOME_PAGE.index("id: doNotDisturbTile")
    and HOME_PAGE.index("id: doNotDisturbTile")
    < HOME_PAGE.index("id: brightnessCard"),
    "The Wi-Fi row must reveal its own submenu in place and push the marked row "
    "and the control cards out of the frame.",
)
require(
    # The row of primary tiles is laid out by hand so the reveal of a section can
    # take the neighbour tile out of it and hand its width to the tile that stays:
    # the survivor reads as the title of the open section instead of a control next
    # to another one. One progress drives both motions, so the row turns from two
    # tiles into one in a single deformation, in both directions.
    'objectName: "controlCenterPrimaryTileRow"' in HOME_PAGE
    and 'objectName: "controlCenterBluetoothTile"' in HOME_PAGE
    and "LayoutMetrics.restingTileWidth(" in HOME_PAGE
    and "LayoutMetrics.primaryTileWidth(width, gap, stacked," in HOME_PAGE
    and "LayoutMetrics.leavingTileX(width, gap, stacked, progress)" in HOME_PAGE
    and "LayoutMetrics.primaryRowHeight(tileHeight," in HOME_PAGE
    and "readonly property real progress:" in HOME_PAGE
    and "networkSubmenu.expansionProgress" in HOME_PAGE
    # The departing tile leaves the pointer, the keyboard and the accessible tree
    # with the same progress that moves it, and the row clips it at its edge.
    and "enabled: primaryRow.progress <= 0.001" in HOME_PAGE
    and "activeFocusOnTab: primaryRow.progress <= 0.001" in HOME_PAGE
    and "Accessible.ignored: primaryRow.progress > 0.001" in HOME_PAGE
    and "clip: true" in HOME_PAGE
    # The morph reads the section animation: it adds no second animator and no
    # timing value of its own to the same reveal.
    and "Behavior on" not in HOME_PAGE
    and "function restingTileWidth(rowWidth, spacing)" in LAYOUT_METRICS
    and "function primaryTileWidth(rowWidth, spacing, stacked, progress)"
    in LAYOUT_METRICS
    and "function leavingTileX(rowWidth, spacing, stacked, progress)"
    in LAYOUT_METRICS
    and "function primaryRowHeight(tileHeight, spacing, stacked, progress)"
    in LAYOUT_METRICS,
    "Opening a section must leave one tile in the row, holding the whole width as "
    "the title of that section, with the geometry read from the reveal progress "
    "alone.",
)
require(
    # One expansion primitive, reused: the section owns the animator, so the
    # submenu adds no second one and no new timing values.
    NETWORK_SUBMENU.startswith(
        "// SPDX-License-Identifier: GPL-2.0-or-later")
    and "ControlCenterExpandableSection {" in NETWORK_SUBMENU
    and "Behavior on" not in NETWORK_SUBMENU
    and "NumberAnimation" not in NETWORK_SUBMENU
    and "active: root.adapter !== null && root.expansionProgress > 0.001"
    in NETWORK_SUBMENU
    and "inlineMode: true" in NETWORK_SUBMENU
    and "ControlCenterNetworkPage {" in NETWORK_SUBMENU,
    "The inline submenu must reuse the existing expansion primitive and build "
    "its page only while it is on screen.",
)
require(
    # Inline presentation: the row that opened the section closes it, so the
    # navigation row disappears and the actions stay.
    "property bool inlineMode: false" in NETWORK_PAGE
    and "navigationRowVisible: !root.inlineMode" in NETWORK_PAGE
    and "pageHeader.focusFirstControl(reason)" in NETWORK_PAGE
    and "property bool navigationRowVisible: true" in PAGE_HEADER
    and "visible: root.navigationRowVisible" in PAGE_HEADER
    and "function focusFirstControl(reason)" in PAGE_HEADER,
    "The inline page must drop its navigation row and keep its actions.",
)
require(
    # The visible scroll of an open section belongs to the list of networks and
    # stays inside its surface; the page bar switches off because the page cannot
    # scroll while the content leaves the frame. A ScrollView reserves the bar its
    # own column, so it never covers a row of the list.
    'objectName: "controlCenterHomeScrollBar"' in HOME_PAGE
    and "policy: networkSubmenu.expansionProgress > 0.001" in HOME_PAGE
    and "? Controls.ScrollBar.AlwaysOff : Controls.ScrollBar.AsNeeded"
    in HOME_PAGE
    and "Controls.ScrollView {" in NETWORK_PAGE
    and "PlasmaComponents.ScrollView {" not in NETWORK_PAGE
    # The bar is never declared by this page: the scroll view provides it already
    # placed on the trailing edge and reserving its column. A bar declared here
    # stayed at the origin and left the rows without their column, which is the
    # defect reported in docs/revisiones/revision-2026-09-18-scroll-lista-redes-y-botones.md.
    and "ScrollBar.vertical:" not in NETWORK_PAGE
    and 'objectName: "controlCenterNetworkScrollView"' in NETWORK_PAGE,
    "The scrollbar of an open section must live inside the network list "
    "without covering it.",
)
require(
    # The overlay owns the section state so Escape, page changes and activation
    # errors agree on who is on screen.
    "property bool networkSubmenuOpen: false" in OVERLAY
    and "root.networkSubmenuOpen = false" in OVERLAY
    and "networkSubmenuOpen: root.networkSubmenuOpen" in OVERLAY
    and "onNetworkSubmenuToggleRequested:" in OVERLAY
    and "if (currentPage !== \"home\") {" in OVERLAY
    and "homePage.showNetworkError(message)" in OVERLAY
    and 'root.networkErrorMessage = String(message || "")' in OVERLAY
    and 'active: (root.currentPage === "network"' in OVERLAY
    and '|| networkPageSlot.progress > 0.001)' in OVERLAY,
    "The overlay must own the inline submenu state.",
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
    and "wired: false" not in NETWORK_ADAPTER
    and '"wired" in mobileProxyModel' in NETWORK_ADAPTER
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
    and "anchors.topMargin: root.floatingMode ? 0 : root.edgeMargin" in RIGHT_RAIL
    and "anchors.rightMargin: root.floatingMode ? 0 : root.edgeMargin" in RIGHT_RAIL
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
