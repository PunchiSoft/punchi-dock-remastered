// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

import "ControlCenterLayoutMetrics.js" as LayoutMetrics

FocusScope {
    id: root

    property var volumeAdapter: null
    property var brightnessAdapter: null
    property var networkAdapter: null
    property var bluetoothAdapter: null
    property var themeAdapter: null
    property var nightLightAdapter: null
    property var volumeOsdAdapter: null
    property var notificationModel: null
    property int unreadNotificationCount: 0
    property int expiredNotificationCount: 0
    property bool notificationServiceValid: false
    property bool doNotDisturbAvailable: false
    property bool doNotDisturbActive: false
    property bool motionEnabled: true
    property string networkErrorMessage: ""
    property bool networkKeyboardEntry: false
    // The inline Wi-Fi submenu is page state, not layout state: the overlay owns
    // it so Escape, focus and the page transitions can coordinate with it.
    property bool networkSubmenuOpen: false
    // The notifications are the primary area of the home page, so they stay at the
    // foot of the frame instead of travelling with the quick controls: opening a
    // section must never hide them. Their area is measured from the resting
    // layout and then held, because the content that leaves changes the layout.
    readonly property real minimumNotificationsHeight:
        Kirigami.Units.gridUnit * 8
    property real heldNotificationsHeight: -1
    readonly property real notificationsArea: {
        if (networkSubmenu.expansionProgress > 0.001
                && heldNotificationsHeight >= 0) {
            return heldNotificationsHeight
        }
        return Math.max(minimumNotificationsHeight, height
            - homeLayout.implicitHeight - Kirigami.Units.largeSpacing)
    }
    // The quick-action strip keeps three non-removable controls —theme, Night
    // Light and the initial Calculator entry— and fills the rest of its width
    // with empty positions, so its capacity follows the width it really has.
    readonly property int quickActionFixedCount: 3
    readonly property int quickActionMinimumCount: 4
    readonly property int quickActionMaximumCount: 8
    readonly property bool wideLayout:
        width >= Kirigami.Units.gridUnit * 48

    signal networkRequested()
    // The tile opens the submenu in place; the page path stays available as the
    // programmable entry while the inline presentation is on trial.
    signal networkSubmenuToggleRequested()
    signal bluetoothRequested()
    signal doNotDisturbRequested()
    signal themeToggleRequested()
    signal nightLightToggleRequested()
    signal nightLightStrengthPreviewRequested(int strength)
    signal nightLightStrengthPreviewStopped()
    signal nightLightStrengthModified(int strength)
    signal volumeOsdToggleRequested()
    signal soundRequested()
    signal notificationCloseRequested(int index)
    signal clearNotificationsRequested()
    signal settingsRequested(string section)
    signal applicationRequested(string application)

    function focusFirstControl() {
        networkKeyboardEntry = false
        homeScrollView.contentY = 0
        wifiTile.forceActiveFocus(Qt.PopupFocusReason)
    }

    // Arrows follow the tile grid as it is laid out. Tab remains available for
    // the card controls, sliders, quick actions and notifications below it.
    function navigateShortcutTile(source, event) {
        event.accepted = false
        const key = event.key
        if (key !== Qt.Key_Left && key !== Qt.Key_Right
                && key !== Qt.Key_Up && key !== Qt.Key_Down) {
            return
        }

        if (networkSubmenu.expansionProgress > 0.001) {
            if (source === wifiTile && key === Qt.Key_Down
                    && networkSubmenu.focusFirstControl(Qt.TabFocusReason)) {
                event.accepted = true
            }
            return
        }

        const tiles = [wifiTile, bluetoothTile, doNotDisturbTile, updatesTile]
        const index = tiles.indexOf(source)
        if (index < 0) {
            return
        }
        const columns = primaryRow.stacked ? 1 : 2
        const step = key === Qt.Key_Left || key === Qt.Key_Up ? -1 : 1
        let candidate = index + step * (key === Qt.Key_Left
            || key === Qt.Key_Right ? 1 : columns)
        while (candidate >= 0 && candidate < tiles.length) {
            let target = tiles[candidate]
            if (!target.enabled || !target.visible) {
                if ((key === Qt.Key_Up || key === Qt.Key_Down)
                        && columns === 2) {
                    const neighborIndex = candidate + (index % 2 === 0 ? 1 : -1)
                    const neighbor = tiles[neighborIndex]
                    if (neighbor && neighbor.enabled && neighbor.visible) {
                        target = neighbor
                    }
                }
            }
            if (target.enabled && target.visible) {
                const top = target.mapToItem(homeLayout, 0, 0).y
                const bottom = target.mapToItem(homeLayout, 0, target.height).y
                const maxScroll = Math.max(0,
                    homeScrollView.contentHeight - homeScrollView.height)
                if (top < homeScrollView.contentY) {
                    homeScrollView.contentY = Math.max(0, top)
                } else if (bottom > homeScrollView.contentY
                        + homeScrollView.height) {
                    homeScrollView.contentY = Math.min(maxScroll,
                        bottom - homeScrollView.height)
                }
                target.forceActiveFocus(Qt.TabFocusReason)
                event.accepted = true
                return
            }
            candidate += step * (key === Qt.Key_Left
                || key === Qt.Key_Right ? 1 : columns)
        }
    }

    function showNetworkError(message) {
        networkSubmenu.showError(message)
    }

    onNetworkSubmenuOpenChanged: {
        if (networkSubmenuOpen) {
            // Taken before the layout reacts, so the notifications keep exactly the
            // area they have while nothing is open.
            heldNotificationsHeight = notificationsArea
            // The reveal is measured from the top of the frame, so the page has to
            // rest at its starting scroll position before the section grows.
            homeScrollView.contentY = 0
        }
    }

    Rectangle {
        id: notificationsSection

        objectName: "controlCenterNotificationsSection"
        // Deliberately outside the scrolling layout: the notifications keep
        // their place at the foot of the frame while a section opens and
        // pushes the quick controls out through the top of their viewport.
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.notificationsArea
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
                    // Entry and removal fade only: animating the positions
                    // of a list that can grow would cost per delegate.
                    add: Transition {
                        NumberAnimation {
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: Math.max(1,
                                Kirigami.Units.shortDuration)
                        }
                    }
                    remove: Transition {
                        NumberAnimation {
                            property: "opacity"
                            to: 0
                            duration: Math.max(1,
                                Kirigami.Units.shortDuration)
                        }
                    }
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

    Flickable {
        id: homeScrollView

        objectName: "controlCenterHomeScrollView"
        anchors.fill: parent
        // The quick controls scroll above the pinned notifications area.
        anchors.bottomMargin: root.notificationsArea
            + Kirigami.Units.largeSpacing
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: homeLayout.height
        // While the submenu is on screen the rest of the page sits outside the
        // frame on purpose, so the reader cannot scroll back into content that is
        // meant to be hidden. The section owns the only scroll that matters then.
        interactive: networkSubmenu.expansionProgress < 0.001
        Controls.ScrollBar.vertical: PlasmaComponents.ScrollBar {
            objectName: "controlCenterHomeScrollBar"
            // While a section is open the page cannot scroll: the content below
            // leaves the frame on purpose, so a bar here would promise movement
            // that the locked viewport does not deliver. The scroll of that state
            // belongs to the section's own list.
            policy: networkSubmenu.expansionProgress > 0.001
                ? Controls.ScrollBar.AlwaysOff : Controls.ScrollBar.AsNeeded
        }

        ColumnLayout {
            id: homeLayout

            width: homeScrollView.width
            height: Math.max(homeScrollView.height, implicitHeight)
            spacing: Kirigami.Units.largeSpacing

            GridLayout {
                id: quickControls

                Layout.fillWidth: true
                columns: root.wideLayout ? 2 : 1
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.largeSpacing

                // The row of the primary tiles is laid out by hand, not by a
                // GridLayout: opening the Wi-Fi section drops the tile next to it,
                // and a layout would place the survivor in the same frame it hides
                // the other, which cannot be animated. With the geometry computed
                // from the reveal progress, the row changes from two tiles to one
                // in a single deformation, in either direction and through an
                // interruption.
                //
                // Cost: the two tiles move with x and opacity, and only the width
                // of the survivor and, when the tiles are stacked, the height of
                // the row are sizes. Neither cascades: the tiles sit outside every
                // layout that could read their width, and the row changes height
                // inside a reveal that is already re-laying out the page each
                // frame, so it costs no extra pass.
                Item {
                    id: primaryRow

                    objectName: "controlCenterPrimaryTileRow"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    // Two tiles share the row only while it is wide enough for
                    // both; below that the survivor already owns the full width.
                    readonly property bool stacked:
                        width < Kirigami.Units.gridUnit * 26
                    readonly property real gap: Kirigami.Units.mediumSpacing
                    // The section below owns the animation and this row follows it,
                    // so the morph adds no animator, no duration and no easing of
                    // its own.
                    readonly property real progress:
                        networkSubmenu.expansionProgress
                    readonly property real tileHeight: wifiTile.implicitHeight
                    readonly property real restingTileWidth:
                        LayoutMetrics.restingTileWidth(width, gap)
                    readonly property real tileWidth:
                        LayoutMetrics.primaryTileWidth(width, gap, stacked,
                            progress)
                    readonly property real leavingTileX:
                        LayoutMetrics.leavingTileX(width, gap, stacked, progress)

                    implicitHeight: LayoutMetrics.primaryRowHeight(tileHeight,
                        gap, stacked, progress)
                    // The tile that leaves is cut at the edge of the row instead of
                    // sliding over the content that follows it.
                    clip: true

                    ControlCenterShortcutTile {
                        id: wifiTile
                        objectName: "controlCenterWifiTile"
                        // The survivor of the open section. Taking the whole row is
                        // what turns the tile into the title of the section below;
                        // its content narrows and widens with it, which is the only
                        // size that moves inside this row.
                        x: 0
                        y: 0
                        width: primaryRow.tileWidth
                        height: primaryRow.tileHeight
                        text: i18nc("@action:button", "Wi-Fi") // qmllint disable unqualified
                        description: root.networkErrorMessage.length > 0
                            && !root.networkSubmenuOpen
                            ? root.networkErrorMessage
                            : root.networkAdapter
                                ? (root.networkAdapter.wifiEnabled
                                    ? i18nc("@info:status", "On — view networks") // qmllint disable unqualified
                                    : i18nc("@info:status", "Off — view networks")) // qmllint disable unqualified
                                : i18nc("@info", "Network controls unavailable") // qmllint disable unqualified
                        iconName: root.networkAdapter
                            && root.networkAdapter.wifiEnabled
                            ? "network-wireless-on" : "network-wireless-off"
                        expandable: true
                        expanded: root.networkSubmenuOpen
                            && root.networkAdapter !== null
                        navigationHandler: root.navigateShortcutTile
                        onKeyboardActivationStarted:
                            root.networkKeyboardEntry = true
                        onClicked: {
                            if (root.networkAdapter) {
                                root.networkSubmenuToggleRequested()
                            } else {
                                root.networkKeyboardEntry = false
                                root.settingsRequested("network")
                            }
                        }
                    }

                    ControlCenterShortcutTile {
                        id: bluetoothTile
                        objectName: "controlCenterBluetoothTile"
                        // The neighbour of the open section keeps its resting width
                        // and travels exactly the distance the survivor grows, so
                        // the two tiles stay side by side while the row becomes one
                        // tile, without a hole or an overlap between them.
                        x: primaryRow.leavingTileX
                        y: primaryRow.stacked
                            ? primaryRow.tileHeight + primaryRow.gap : 0
                        width: primaryRow.stacked
                            ? primaryRow.width : primaryRow.restingTileWidth
                        height: primaryRow.tileHeight
                        opacity: 1 - primaryRow.progress
                        // It leaves the pointer, the tab order and the accessible
                        // tree with the same progress that moves it, and comes back
                        // the moment the section starts to close.
                        visible: primaryRow.progress < 1
                        enabled: primaryRow.progress <= 0.001
                        activeFocusOnTab: primaryRow.progress <= 0.001
                        Accessible.ignored: primaryRow.progress > 0.001
                        navigationHandler: root.navigateShortcutTile
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

                }


                // The network submenu opens directly under the row that asked for
                // it and pushes the rest of the page downwards. It takes exactly
                // the height left below itself, so the remaining content starts at
                // the bottom edge of the frame and stops being visible. Reported
                // by the user.
                ControlCenterNetworkSubmenu {
                    id: networkSubmenu

                    objectName: "controlCenterNetworkSubmenu"
                    Layout.fillWidth: true
                    Layout.columnSpan: root.wideLayout ? 2 : 1
                    adapter: root.networkAdapter
                    motionEnabled: root.motionEnabled
                    expanded: root.networkSubmenuOpen
                        && root.networkAdapter !== null
                    // Distance from the top of the frame to the top of the section,
                    // read from the layout instead of assumed, so the section ends
                    // exactly at the bottom edge of the panel and the rest of the
                    // page leaves it for good.
                    readonly property real topInViewport:
                        quickControls.y + y - homeScrollView.contentY
                    expandedHeight: Math.max(0,
                        homeScrollView.height - topInViewport)
                    onSettingsRequested: function(section) {
                        root.settingsRequested(section)
                    }
                    onTransitionFinished: function(expanded) {
                        if (!root.enabled || !root.visible) {
                            return
                        }
                        const reason = root.networkKeyboardEntry
                            ? Qt.TabFocusReason : Qt.PopupFocusReason
                        if (expanded) {
                            networkSubmenu.focusFirstControl(reason)
                        } else {
                            wifiTile.forceActiveFocus(reason)
                        }
                        root.networkKeyboardEntry = false
                    }
                }

                GridLayout {
                    id: secondaryTiles
                    objectName: "controlCenterSecondaryTiles"

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    enabled: networkSubmenu.expansionProgress <= 0.001
                    Accessible.ignored:
                        networkSubmenu.expansionProgress > 0.001
                    columns: width >= Kirigami.Units.gridUnit * 26 ? 2 : 1
                    columnSpacing: Kirigami.Units.mediumSpacing
                    rowSpacing: Kirigami.Units.mediumSpacing

                    ControlCenterShortcutTile {
                        id: doNotDisturbTile
                        objectName: "controlCenterDoNotDisturbTile"
                        Layout.fillWidth: true
                        enabled: root.doNotDisturbAvailable
                        navigationHandler: root.navigateShortcutTile
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
                        navigationHandler: root.navigateShortcutTile
                        text: i18nc("@action:button", "Updates") // qmllint disable unqualified
                        description: i18nc("@info", "Manage system updates") // qmllint disable unqualified
                        iconName: "update-low"
                        onClicked: root.applicationRequested("updates")
                    }

                }

                ColumnLayout {
                    id: controlCards
                    objectName: "controlCenterControlCards"

                    Layout.fillWidth: !root.wideLayout
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 22
                    Layout.maximumWidth: root.wideLayout
                        ? Kirigami.Units.gridUnit * 22 : Number.POSITIVE_INFINITY
                    Layout.alignment: Qt.AlignTop | Qt.AlignRight
                    enabled: networkSubmenu.expansionProgress <= 0.001
                    Accessible.ignored:
                        networkSubmenu.expansionProgress > 0.001
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
                        iconName: root.volumeAdapter
                            ? root.volumeAdapter.deviceIconName
                            : "audio-volume-high"
                        value: root.volumeAdapter ? root.volumeAdapter.value : 0
                        controlAvailable: root.volumeAdapter
                            ? root.volumeAdapter.available : false
                        iconActionEnabled: true
                        iconActionName: root.volumeAdapter
                            && root.volumeAdapter.muted
                            ? i18nc("@action:button", "Unmute") // qmllint disable unqualified
                            : i18nc("@action:button", "Mute") // qmllint disable unqualified
                        secondaryActionVisible: root.volumeOsdAdapter !== null
                        secondaryActionEnabled: !!root.volumeOsdAdapter
                            && root.volumeOsdAdapter.writable
                        secondaryActionCheckable: true
                        secondaryActionChecked: root.volumeOsdAdapter
                            ? root.volumeOsdAdapter.osdVisible : false
                        secondaryActionIconName: volumeCard.secondaryActionChecked
                            ? "view-visible" : "view-hidden"
                        secondaryActionName: volumeCard.secondaryActionChecked
                            ? i18nc("@action:button", "Hide Plasma volume indicator") // qmllint disable unqualified
                            : i18nc("@action:button", "Show Plasma volume indicator") // qmllint disable unqualified
                        // The translation helper is supplied by the plasmoid context.
                        // qmllint disable unqualified
                        secondaryActionDescription: i18nc(
                            "@info:accessibility",
                            "Changes the volume indicator for all Plasma controls and multimedia keys")
                        // qmllint enable unqualified
                        navigationActionVisible: true
                        navigationActionEnabled: root.volumeAdapter !== null
                        navigationActionIconName: "view-media-equalizer"
                        // qmllint disable unqualified
                        navigationActionName: i18nc(
                            "@action:button", "Manage audio devices and applications")
                        // qmllint enable unqualified
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
                        onSecondaryActionTriggered:
                            root.volumeOsdToggleRequested()
                        onNavigationRequested: root.soundRequested()
                        onSettingsRequested: root.settingsRequested("sound")
                    }
                }

                RowLayout {
                    id: quickActionsRow

                    objectName: "controlCenterQuickActionsRow"
                    Layout.fillWidth: true
                    Layout.columnSpan: root.wideLayout ? 2 : 1
                    enabled: networkSubmenu.expansionProgress <= 0.001
                    Accessible.ignored:
                        networkSubmenu.expansionProgress > 0.001
                    // The width comes from the scroll view, which the surface
                    // sizes, so filling empty slots never feeds back into the
                    // layout that decides how many of them fit.
                    readonly property int cellCount: LayoutMetrics.quickActionCapacity(
                        homeScrollView.width, Kirigami.Units.gridUnit * 3,
                        Kirigami.Units.mediumSpacing, root.quickActionMinimumCount,
                        root.quickActionMaximumCount)
                    readonly property int emptySlotCount: Math.max(0,
                        cellCount - root.quickActionFixedCount)
                    spacing: LayoutMetrics.quickActionSpacing(homeScrollView.width,
                        Kirigami.Units.gridUnit * 3, cellCount,
                        Kirigami.Units.mediumSpacing,
                        Kirigami.Units.largeSpacing * 2)

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

                    // The empty positions reuse the placeholder already present in
                    // the project; their number follows the width of the strip.
                    Repeater {
                        model: quickActionsRow.emptySlotCount

                        delegate: ControlCenterApplicationPlaceholderButton {
                            required property int index

                            objectName: "controlCenterApplicationPlaceholderButton"
                                + (index + 1)
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }

                ControlCenterHoverReveal {
                    objectName: "controlCenterNightLightStrengthReveal"
                    Layout.fillWidth: true
                    Layout.columnSpan: root.wideLayout ? 2 : 1
                    visible: root.nightLightAdapter
                        && root.nightLightAdapter.available
                    motionEnabled: root.motionEnabled
                    expandedHeight: strengthControl.implicitHeight
                    revealRequested: nightLightButton.hovered
                        || nightLightButton.activeFocus
                    interacting: strengthControl.interacting
                    usable: strengthControl.controlAvailable

                    ControlCenterNightLightStrength {
                        id: strengthControl

                        objectName: "controlCenterNightLightStrengthControl"
                        width: parent.width
                        height: implicitHeight
                        anchors.verticalCenter: parent.verticalCenter
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
            }

        }
    }
}
