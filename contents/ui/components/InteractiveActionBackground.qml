import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: root

    property bool hovered: false
    property bool focused: false
    property bool pressed: false
    property bool destructive: false
    // 0 derives the subtle menu-like corner from the height; pass a value for
    // chip-like or circular surfaces.
    property int visualRadius: 0
    property bool motionEnabled: Kirigami.Units.longDuration > 0

    readonly property color baseColor: destructive
        ? Kirigami.Theme.negativeTextColor
        : Kirigami.Theme.highlightColor

    // Mirrors the platform menu selection: ~30 % fill while the pointer is on
    // the row, a heavier fill while pressed.
    color: (hovered || focused || pressed)
        ? Qt.rgba(baseColor.r, baseColor.g, baseColor.b, pressed ? 0.38 : 0.30)
        : "transparent"
    border.color: baseColor
    border.width: focused ? 2 : hovered ? 1 : 0

    radius: visualRadius > 0 ? visualRadius : Math.max(2,
        Math.round(height / 10))
    antialiasing: true
    Accessible.ignored: true

    Behavior on color {
        enabled: root.motionEnabled
        ColorAnimation {
            duration: Kirigami.Units.shortDuration
        }
    }
}
