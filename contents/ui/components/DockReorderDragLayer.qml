import QtQuick
import org.kde.kirigami as Kirigami

// Lightweight visual transport for persistent Dock item reordering. The
// actual model move remains owned by DockItemsController. It carries only the
// icon at full opacity and natural size, so the element under the pointer reads
// as the grabbed item itself, the way the native icon-only task manager does.
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

        // The icon hangs from the pointer by its top-left corner, exactly like
        // the native drag pixmap, so it reads as grabbed instead of centred.
        readonly property real proxyExtent: Math.max(24, Number(root.iconSize))

        x: root.pointerPosition.x
        y: root.pointerPosition.y
        width: proxyExtent
        height: proxyExtent
        visible: root.active
        opacity: root.active ? 1.0 : 0.0

        Kirigami.Icon {
            anchors.fill: parent
            source: root.iconName
            Accessible.ignored: true
        }

        Behavior on opacity {
            enabled: root.motionEnabled
            NumberAnimation {
                duration: Kirigami.Units.shortDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}
