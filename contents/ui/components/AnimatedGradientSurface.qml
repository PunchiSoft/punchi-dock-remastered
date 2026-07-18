import QtQuick
import QtQuick.Shapes as Shapes
import org.kde.kirigami as Kirigami

Item {
    id: root

    property var gradientStops: []
    property string gradientDirection: "horizontal"
    property string flowDirection: "forward"
    property int flowDuration: 16000
    property real radius: 0
    property real borderWidth: 0
    property color borderColor: "transparent"

    readonly property bool horizontal: gradientDirection === "horizontal"
    readonly property real pathInset: borderWidth / 2
    readonly property real safeRadius: Math.max(0, Math.min(radius,
        (width - pathInset * 2) / 2, (height - pathInset * 2) / 2))
    readonly property real signedProgress: flowDirection === "reverse"
        ? flowProgress : -flowProgress
    readonly property real flowOffset: signedProgress
        * (horizontal ? width : height)
    readonly property string surfacePath: roundedRectanglePath()

    property real flowProgress: 0

    function coordinate(value) {
        return Number(value).toFixed(2)
    }

    function gradientStop(index) {
        if (gradientStops.length === 0) {
            return {
                "position": index === 0 ? 0 : 1,
                "color": "transparent"
            }
        }
        return gradientStops[Math.min(index, gradientStops.length - 1)]
    }

    function roundedRectanglePath() {
        const left = pathInset
        const right = Math.max(left, width - pathInset)
        const top = pathInset
        const bottom = Math.max(top, height - pathInset)
        const corner = safeRadius
        return "M " + coordinate(left + corner) + " " + coordinate(top)
            + " L " + coordinate(right - corner) + " " + coordinate(top)
            + " Q " + coordinate(right) + " " + coordinate(top)
            + " " + coordinate(right) + " " + coordinate(top + corner)
            + " L " + coordinate(right) + " " + coordinate(bottom - corner)
            + " Q " + coordinate(right) + " " + coordinate(bottom)
            + " " + coordinate(right - corner) + " " + coordinate(bottom)
            + " L " + coordinate(left + corner) + " " + coordinate(bottom)
            + " Q " + coordinate(left) + " " + coordinate(bottom)
            + " " + coordinate(left) + " " + coordinate(bottom - corner)
            + " L " + coordinate(left) + " " + coordinate(top + corner)
            + " Q " + coordinate(left) + " " + coordinate(top)
            + " " + coordinate(left + corner) + " " + coordinate(top)
            + " Z"
    }

    NumberAnimation on flowProgress {
        from: 0
        to: 1
        duration: Math.max(6000, root.flowDuration)
        loops: Animation.Infinite
        running: root.visible
            && root.width > 0
            && root.height > 0
            && Kirigami.Units.longDuration > 1
    }

    Shapes.Shape {
        anchors.fill: parent
        layer.enabled: false

        Shapes.ShapePath {
            strokeWidth: root.borderWidth
            strokeColor: root.borderColor
            joinStyle: Shapes.ShapePath.RoundJoin
            fillGradient: Shapes.LinearGradient {
                spread: Shapes.ShapeGradient.RepeatSpread
                x1: root.horizontal ? root.flowOffset : 0
                y1: root.horizontal ? 0 : root.flowOffset
                x2: root.horizontal ? root.flowOffset + root.width : 0
                y2: root.horizontal ? 0 : root.flowOffset + root.height

                GradientStop { position: Number(root.gradientStop(0).position); color: root.gradientStop(0).color }
                GradientStop { position: Number(root.gradientStop(1).position); color: root.gradientStop(1).color }
                GradientStop { position: Number(root.gradientStop(2).position); color: root.gradientStop(2).color }
                GradientStop { position: Number(root.gradientStop(3).position); color: root.gradientStop(3).color }
                GradientStop { position: Number(root.gradientStop(4).position); color: root.gradientStop(4).color }
                GradientStop { position: Number(root.gradientStop(5).position); color: root.gradientStop(5).color }
                GradientStop { position: Number(root.gradientStop(6).position); color: root.gradientStop(6).color }
                GradientStop { position: Number(root.gradientStop(7).position); color: root.gradientStop(7).color }
            }

            PathSvg {
                path: root.surfacePath
            }
        }
    }
}
