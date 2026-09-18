// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

// Catalog tile: a card-shaped button whose content stays optically centered.
// The add affordance travels as a badge attached to the icon instead of a third
// text line, so the tile reads as one control and the label keeps its space.
Controls.AbstractButton {
    id: root

    property string itemType: ""
    property string iconName: "application-x-executable"
    property string accessibleDescription: ""
    property string tooltipText: ""
    readonly property string dragKind: "catalog"
    // Focus is painted only when it arrived from keyboard navigation, following
    // the focus-visible criterion documented in
    // docs/Referencias/referencia-estados-interaccion-kde.md. A programmatic
    // focus (Qt.PopupFocusReason, Qt.OtherFocusReason) or a pointer focus must
    // not light the tile. The name avoids shadowing Qt's FINAL
    // Control.visualFocus property.
    readonly property bool keyboardFocusVisible: activeFocus
        && [Qt.TabFocusReason, Qt.BacktabFocusReason,
            Qt.ShortcutFocusReason].includes(focusReason)
    readonly property bool motionEnabled: Kirigami.Units.longDuration > 0
    readonly property real badgeSize:
        Math.round(Kirigami.Units.iconSizes.small * 0.9)

    signal dragStarted()
    signal dragFinished()

    implicitWidth: Kirigami.Units.gridUnit * 7
    implicitHeight: Kirigami.Units.gridUnit * 5
    padding: Math.round(Kirigami.Units.gridUnit * 0.35)
    hoverEnabled: true
    activeFocusOnTab: true
    Accessible.name: text
    Accessible.description: accessibleDescription

    Drag.active: false
    Drag.source: root
    Drag.keys: ["punchi-config-catalog-item"]
    Drag.supportedActions: Qt.CopyAction
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2

    // Pressure feedback matches the shared interactive profile of the project.
    scale: root.down && root.motionEnabled ? 0.97 : 1.0

    Behavior on scale {
        enabled: root.motionEnabled
        NumberAnimation {
            duration: Kirigami.Units.shortDuration
            easing.type: Easing.OutCubic
        }
    }

    background: Rectangle {
        radius: Kirigami.Units.cornerRadius * 2
        color: root.down || dragHandler.active
            ? Qt.alpha(Kirigami.Theme.highlightColor, 0.24)
            : (root.hovered || root.keyboardFocusVisible
                ? Qt.alpha(Kirigami.Theme.highlightColor, 0.20)
                : Qt.alpha(Kirigami.Theme.backgroundColor, 0.42))
        border.width: root.keyboardFocusVisible ? 2 : 1
        border.color: root.keyboardFocusVisible || dragHandler.active
            ? Kirigami.Theme.highlightColor
            : Qt.alpha(Kirigami.Theme.textColor, 0.28)
    }

    contentItem: Item {
        Column {
            id: contentColumn

            anchors.centerIn: parent
            width: parent.width
            spacing: Kirigami.Units.smallSpacing

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Kirigami.Units.iconSizes.medium
                height: width

                Kirigami.Icon {
                    anchors.fill: parent
                    source: root.iconName
                    isMask: root.iconName.indexOf("-symbolic") >= 0
                    opacity: root.enabled ? 1.0 : 0.5
                }

                Rectangle {
                    id: addBadge

                    width: root.badgeSize
                    height: width
                    radius: width / 2
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: -Math.round(width * 0.18)
                    anchors.bottomMargin: -Math.round(width * 0.18)
                    color: Kirigami.Theme.highlightColor
                    opacity: root.enabled ? 1.0 : 0.4
                    Accessible.ignored: true

                    Controls.Label {
                        anchors.centerIn: parent
                        text: "+"
                        color: Kirigami.Theme.highlightedTextColor
                        font.pixelSize: Math.round(addBadge.height * 0.72)
                        Accessible.ignored: true
                    }
                }
            }

            Controls.Label {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                maximumLineCount: 1
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                text: root.text
                color: root.enabled
                    ? Kirigami.Theme.textColor
                    : Kirigami.Theme.disabledTextColor
            }
        }
    }

    DragHandler {
        id: dragHandler
        target: null
        enabled: root.enabled
        onActiveChanged: {
            if (active) {
                root.Drag.active = true
                root.dragStarted()
            } else {
                if (root.Drag.active) {
                    root.Drag.drop()
                }
                root.dragFinished()
            }
        }
    }

    // Plasma renders this tooltip in its own dialog window, so the text is not
    // clipped by the bounds of the configuration surface. It stays available
    // for an unavailable tile too, because the reason is communicated here.
    PlasmaCore.ToolTipArea {
        id: tileToolTip

        objectName: "itemsConfigurationTileToolTip"
        anchors.fill: parent
        active: !dragHandler.active
            && (root.tooltipText.length > 0
                || root.accessibleDescription.length > 0)
        mainText: root.tooltipText.length > 0
            ? root.tooltipText : root.text
        subText: root.tooltipText.length > 0
            ? "" : root.accessibleDescription
        icon: root.iconName
    }

    // The keyboard tooltip follows the same focus-visible criterion: opening the
    // configuration window grants programmatic focus and must not pop a tooltip.
    // The shared Plasma tooltip dialog serves one area at a time, so showing it
    // for a focus the user did not ask for made it fight the hovered tile
    // (ToolTipArea keeps a single static ToolTipDialog).
    onKeyboardFocusVisibleChanged: {
        if (keyboardFocusVisible) {
            tileToolTip.showToolTip()
        } else if (!tileToolTip.containsMouse) {
            tileToolTip.hideImmediately()
        }
    }
}
