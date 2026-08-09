import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: root

    property bool hovered: false
    property bool focused: false
    property bool pressed: false
    property bool destructive: false
    property int visualRadius: 6
    property bool motionEnabled: Kirigami.Units.longDuration > 0

    readonly property color baseColor: destructive
        ? Kirigami.Theme.negativeTextColor
        : Kirigami.Theme.highlightColor

    color: (hovered || focused || pressed)
        ? Qt.rgba(baseColor.r, baseColor.g, baseColor.b, pressed ? 0.30 : 0.20)
        : "transparent"
    border.color: baseColor
    border.width: focused ? 2 : hovered ? 1 : 0

    radius: visualRadius
    antialiasing: true
    Accessible.ignored: true

    Behavior on color {
        enabled: root.motionEnabled
        ColorAnimation {
            duration: Kirigami.Units.shortDuration
        }
    }
}
