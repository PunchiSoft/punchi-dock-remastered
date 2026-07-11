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
    readonly property real resolvedOpacity: Math.max(0.0, Math.min(1.0, indicatorOpacity)) * (active ? 1.0 : 0.72)
    readonly property real sizeHint: Math.max(2, thickness)
    readonly property real lineWidth: Math.min(root.width - 12, Math.max(sizeHint * 2.5, 8 + Math.min(count, 3) * 5))
    readonly property real dotSize: Math.max(sizeHint + 3, Math.min(iconSize * 0.18, 12))
    readonly property real ringSize: Math.min(root.width - 8, iconSize + 8)

    visible: !hiddenIndicator
    opacity: resolvedOpacity

    Rectangle {
        visible: root.type === "line"
        width: root.lineWidth
        height: root.sizeHint
        radius: height / 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: root.position === "bottom" ? parent.bottom : undefined
        anchors.bottomMargin: root.position === "bottom" ? 1 : 0
        anchors.top: root.position === "top" ? parent.top : undefined
        anchors.topMargin: root.position === "top" ? 1 : 0
        color: root.resolvedColor
    }

    Rectangle {
        visible: root.type === "dot"
        width: root.dotSize
        height: root.dotSize
        radius: width / 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: root.position === "bottom" ? parent.bottom : undefined
        anchors.bottomMargin: root.position === "bottom" ? 1 : 0
        anchors.top: root.position === "top" ? parent.top : undefined
        anchors.topMargin: root.position === "top" ? 1 : 0
        color: root.resolvedColor
    }

    Rectangle {
        visible: root.type === "square"
        width: root.dotSize + 2
        height: root.dotSize + 2
        radius: Math.max(2, root.dotSize * 0.28)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: root.position === "bottom" ? parent.bottom : undefined
        anchors.bottomMargin: root.position === "bottom" ? 1 : 0
        anchors.top: root.position === "top" ? parent.top : undefined
        anchors.topMargin: root.position === "top" ? 1 : 0
        color: root.resolvedColor
    }

    Rectangle {
        visible: root.type === "ring"
        width: root.ringSize
        height: root.ringSize
        radius: width / 2
        anchors.centerIn: parent
        color: "transparent"
        border.width: Math.max(1, Math.min(4, root.sizeHint))
        border.color: root.resolvedColor
    }
}
