import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property bool active: false
    property bool demandsAttention: false
    property int count: 0
    property string type: "line"
    property string position: "bottom"
    property int thickness: 4
    property real indicatorOpacity: 1.0
    property color customColor: "transparent"
    property int iconSize: 48

    readonly property bool hiddenIndicator: type === "none" || count <= 0
    readonly property color resolvedColor: customColor.a > 0
        ? customColor
        : (demandsAttention ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.highlightColor)
    readonly property real stateOpacity: active || demandsAttention ? 1.0 : 0.5
    readonly property real resolvedOpacity: Math.max(0.0,
        Math.min(1.0, indicatorOpacity)) * stateOpacity
    readonly property real sizeHint: Math.max(2, thickness)
    readonly property real lineWidth: Math.max(0,
        Math.min(root.width - 12, Math.max(sizeHint * 2.5, 8 + Math.min(count, 3) * 5)))
    readonly property real dotSize: Math.max(sizeHint + 3, Math.min(iconSize * 0.18, 12))
    readonly property real ringSize: Math.min(root.width - 8, iconSize + 8)

    visible: !hiddenIndicator
    opacity: resolvedOpacity

    Rectangle {
        id: edgeIndicator
        visible: root.type === "line" || root.type === "dot" || root.type === "square"
        width: root.type === "line" ? root.lineWidth : root.dotSize + (root.type === "square" ? 2 : 0)
        height: root.type === "line" ? root.sizeHint : width
        x: Math.round((root.width - width) / 2)
        y: root.position === "top" ? 1 : Math.max(1, root.height - height - 1)
        radius: root.type === "square" ? Math.max(2, root.dotSize * 0.28) : height / 2
        color: root.resolvedColor
    }

    Rectangle {
        visible: root.type === "ring"
        width: root.ringSize
        height: root.ringSize
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)
        radius: width / 2
        color: "transparent"
        border.width: Math.max(1, Math.min(4, root.sizeHint))
        border.color: root.resolvedColor
    }
}
