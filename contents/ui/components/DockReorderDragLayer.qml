import QtQuick
import org.kde.kirigami as Kirigami

// Lightweight visual transport for persistent Dock item reordering. The
// actual model move remains owned by DockItemsController. It carries only the
// icon so the element under the pointer reads as the item itself, the way the
// native icon-only task manager does, instead of as a floating card.
Item {
    id: root

    property bool active: false
    property point pointerPosition: Qt.point(0, 0)
    property string iconName: "application-x-executable"
    property int iconSize: 48
    property bool motionEnabled: true

    visible: active
    enabled: false
    Accessible.ignored: true

    Item {
        id: dragProxy
        objectName: "dockReorderDragProxy"

        readonly property real proxyExtent: Math.max(24,
            Number(root.iconSize) + Kirigami.Units.smallSpacing * 2)

        x: root.pointerPosition.x - width / 2
        y: root.pointerPosition.y - height / 2
        width: proxyExtent
        height: proxyExtent
        visible: root.active
        opacity: root.active ? 0.94 : 0.0
        scale: root.active && root.motionEnabled ? 1.06 : 1.0
        transformOrigin: Item.Center

        Kirigami.Icon {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            source: root.iconName
            Accessible.ignored: true
        }

        Behavior on scale {
            enabled: root.motionEnabled
            NumberAnimation {
                duration: Kirigami.Units.shortDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}
