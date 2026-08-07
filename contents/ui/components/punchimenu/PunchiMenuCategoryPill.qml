import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.Chip {
    id: root

    required property string categoryKey
    required property string titleName
    required property int index
    property bool keyboardFocused: false
    property bool motionEnabled: true

    readonly property real minimumPillWidth: Kirigami.Units.gridUnit * 4.5
    readonly property real maximumPillWidth: Kirigami.Units.gridUnit * 10
    readonly property bool pointerHighlighted: enabled
        && (pointerHover.hovered || hovered || down)
    readonly property bool strongHighlight: keyboardFocused
        || pointerHighlighted

    width: Math.max(minimumPillWidth,
        Math.min(maximumPillWidth,
            labelItem.implicitWidth + Kirigami.Units.gridUnit * 2.2))
    height: Kirigami.Units.gridUnit * 2.1
    text: titleName
    display: Controls.AbstractButton.TextOnly
    closable: false
    activeFocusOnTab: false
    scale: down ? 0.98 : hovered ? 1.015 : 1.0

    Accessible.name: titleName
    Accessible.checked: checked
    Accessible.focused: keyboardFocused

    labelItem.maximumLineCount: 1
    labelItem.elide: Text.ElideRight
    labelItem.horizontalAlignment: Text.AlignHCenter
    labelItem.color: strongHighlight
        ? Kirigami.Theme.highlightedTextColor
        : Kirigami.Theme.textColor

    background: Rectangle {
        radius: height / 2
        color: root.strongHighlight
            ? Kirigami.Theme.highlightColor
            : root.checked
                ? Qt.alpha(Kirigami.Theme.highlightColor, 0.22)
                : Qt.alpha(Kirigami.Theme.backgroundColor, 0.55)
        border.color: root.strongHighlight || root.checked
            ? Kirigami.Theme.highlightColor
            : Qt.alpha(Kirigami.Theme.textColor, 0.24)
        border.width: root.keyboardFocused ? 2 : 1

        Behavior on color {
            enabled: root.motionEnabled
            ColorAnimation {
                duration: Math.max(90,
                    Math.min(150, Kirigami.Units.shortDuration))
            }
        }

        Behavior on border.color {
            enabled: root.motionEnabled
            ColorAnimation {
                duration: Math.max(90,
                    Math.min(150, Kirigami.Units.shortDuration))
            }
        }
    }

    HoverHandler {
        id: pointerHover
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
    }

    Behavior on scale {
        enabled: root.motionEnabled
        NumberAnimation {
            duration: Math.max(90,
                Math.min(140, Kirigami.Units.shortDuration))
            easing.type: Easing.OutCubic
        }
    }
}
