import QtQuick
import org.kde.kirigami as Kirigami

// Shared lightweight highlight surface for PunchiMenu delegates.
Rectangle {
    id: root

    property bool hovered: false
    property bool selected: false
    property bool focused: false
    property bool pressed: false
    property bool circular: false
    property bool motionEnabled: true

    color: selected || focused ? Qt.alpha(Kirigami.Theme.highlightColor, 0.30)
        : hovered ? Qt.alpha(Kirigami.Theme.textColor, 0.09)
            : "transparent"
    border.color: focused || selected
        ? Kirigami.Theme.highlightColor
        : "transparent"
    border.width: focused ? 2 : selected ? 1 : 0
    radius: circular ? height / 2 : Kirigami.Units.cornerRadius * 1.5
    scale: pressed ? 0.97 : (selected || hovered || focused) ? 1.03 : 1.0
    antialiasing: true
    Accessible.ignored: true

    Behavior on color {
        enabled: root.motionEnabled
        ColorAnimation {
            duration: Math.max(80,
                Math.min(140, Kirigami.Units.shortDuration))
        }
    }

    Behavior on scale {
        enabled: root.motionEnabled
        NumberAnimation {
            duration: root.pressed ? 80 : 130
            easing.type: Easing.OutCubic
        }
    }
}
