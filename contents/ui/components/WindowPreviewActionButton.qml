pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore

PlasmaComponents.ToolButton {
    id: root

    property bool destructive: false
    property int visualRadius: Kirigami.Units.cornerRadius
    readonly property color accentColor: destructive
        ? Kirigami.Theme.negativeTextColor
        : Kirigami.Theme.highlightColor
    readonly property bool highlightedContent: enabled
        && (hovered || pressed || activeFocus || actionToolTip.containsMouse)

    implicitWidth: 28
    implicitHeight: 28
    padding: 2
    focusPolicy: Qt.StrongFocus
    display: PlasmaComponents.AbstractButton.IconOnly
    opacity: enabled ? 1.0 : 0.38
    Accessible.name: text
    Accessible.role: Accessible.Button
    icon.color: destructive
        ? Kirigami.Theme.negativeTextColor
        : Kirigami.Theme.textColor

    background: Rectangle {
        radius: root.visualRadius
        color: !root.highlightedContent
            ? "transparent"
            : Qt.alpha(root.accentColor, root.pressed ? 0.32 : 0.22)
        border.width: root.activeFocus ? 2
            : (root.hovered || actionToolTip.containsMouse ? 1 : 0)
        border.color: root.accentColor
        antialiasing: true
        Accessible.ignored: true

        Behavior on color {
            ColorAnimation {
                duration: Math.max(80,
                    Math.min(140, Kirigami.Units.shortDuration))
            }
        }
    }

    PlasmaCore.ToolTipArea {
        id: actionToolTip
        anchors.fill: parent
        active: root.enabled && root.visible && root.text.length > 0
        mainText: root.text
    }

    HoverHandler {
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
    }

    onActiveFocusChanged: {
        if (activeFocus) {
            actionToolTip.showToolTip()
        } else if (!actionToolTip.containsMouse) {
            actionToolTip.hideImmediately()
        }
    }
}
