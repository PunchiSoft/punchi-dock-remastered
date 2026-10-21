import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

// Transport used while the pointer leaves the dock surface. The panel window
// clips anything drawn past its bounds, so the floating icon is rendered by a
// small input-transparent window that follows the cursor, the same way the
// compositor draws the native drag pixmap. The dock item itself never leaves
// the panel.
PlasmaCore.Dialog {
    id: root

    property bool dragging: false
    property point pointerPosition: Qt.point(0, 0)
    property string iconName: "application-x-executable"
    property int iconSize: 48

    readonly property int extent: Math.max(24, Number(iconSize))

    type: PlasmaCore.Dialog.Tooltip
    flags: Qt.ToolTip | Qt.FramelessWindowHint | Qt.WindowTransparentForInput
        | Qt.WindowDoesNotAcceptFocus
    backgroundHints: PlasmaCore.Dialog.NoBackground
    location: PlasmaCore.Types.Floating
    visible: dragging
    x: Math.round(pointerPosition.x)
    y: Math.round(pointerPosition.y)

    mainItem: Item {
        width: root.extent
        height: root.extent

        Kirigami.Icon {
            anchors.fill: parent
            source: root.iconName
            Accessible.ignored: true
        }
    }
}
