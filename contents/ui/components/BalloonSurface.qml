// SPDX-License-Identifier: GPL-2.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import org.kde.kirigami as Kirigami

// One continuous outline for a rounded surface and its dock-facing pointer.
// The component owns only the themed shape; content and interaction stay with
// the popup that places it.
Item {
    id: root

    property color fillColor: Kirigami.Theme.backgroundColor
    property color strokeColor: Qt.alpha(Kirigami.Theme.textColor, 0.2)
    property real borderWidth: Kirigami.Units.smallSpacing / 4
    property real cornerRadius: Kirigami.Units.cornerRadius * 2
    property real tailHeight: Kirigami.Units.largeSpacing
    property real tailBaseScale: 1
    property real tailTipRadius: 0
    property string tailEdge: "bottom"
    property real pointerX: width / 2
    property real pointerY: height / 2

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Accessible.ignored: true

    readonly property bool verticalTail: tailEdge === "left"
        || tailEdge === "right"
    readonly property real bodyHeight: verticalTail ? height : height - tailHeight
    readonly property real radius: Math.min(cornerRadius, bodyHeight / 2,
        (verticalTail ? width - tailHeight : width) / 2)
    readonly property real strokeInset: borderWidth / 2
    readonly property real pointerCenter: Math.max(radius + tailHeight,
        Math.min((verticalTail ? height : width) - radius - tailHeight,
            verticalTail ? pointerY : pointerX))
    readonly property real effectiveTailTipRadius: Math.max(0, Math.min(
        tailTipRadius, tailHeight * tailBaseScale * 0.75,
        tailHeight - strokeInset))

    Shape {
        id: outline

        width: root.verticalTail ? root.height : root.width
        height: root.verticalTail ? root.width : root.height
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        rotation: root.tailEdge === "left" ? 90
            : root.tailEdge === "right" ? -90
            : root.tailEdge === "top" ? 180 : 0
        layer.enabled: visible && width > 0 && height > 0
        layer.samples: 8
        layer.smooth: true
        Accessible.ignored: true

        readonly property real bodyHeight: height - root.tailHeight
        readonly property real pointerCenter: root.tailEdge === "right"
                || root.tailEdge === "top"
            ? width - root.pointerCenter : root.pointerCenter

        ShapePath {
            strokeWidth: root.borderWidth
            strokeColor: root.strokeColor
            fillColor: root.fillColor
            startX: root.radius
            startY: root.strokeInset

            PathLine {
                x: outline.width - root.radius
                y: root.strokeInset
            }
            PathQuad {
                x: outline.width - root.strokeInset
                y: root.radius
                controlX: outline.width - root.strokeInset
                controlY: root.strokeInset
            }
            PathLine {
                x: outline.width - root.strokeInset
                y: outline.bodyHeight - root.radius
            }
            PathQuad {
                x: outline.width - root.radius
                y: outline.bodyHeight
                controlX: outline.width - root.strokeInset
                controlY: outline.bodyHeight
            }
            PathLine {
                x: outline.pointerCenter + root.tailHeight * root.tailBaseScale
                y: outline.bodyHeight
            }
            PathQuad {
                x: outline.pointerCenter + root.effectiveTailTipRadius
                y: outline.height - root.strokeInset
                    - root.effectiveTailTipRadius
                controlX: root.effectiveTailTipRadius > 0
                    ? outline.pointerCenter
                        + root.tailHeight * root.tailBaseScale
                    : outline.pointerCenter + root.tailHeight / 2
                controlY: root.effectiveTailTipRadius > 0
                    ? outline.bodyHeight
                    : outline.bodyHeight
                        + (root.tailHeight - root.strokeInset) / 2
            }
            PathQuad {
                x: outline.pointerCenter - root.effectiveTailTipRadius
                y: outline.height - root.strokeInset
                    - root.effectiveTailTipRadius
                controlX: outline.pointerCenter
                controlY: outline.height - root.strokeInset
                    + root.effectiveTailTipRadius
            }
            PathQuad {
                x: outline.pointerCenter - root.tailHeight * root.tailBaseScale
                y: outline.bodyHeight
                controlX: root.effectiveTailTipRadius > 0
                    ? outline.pointerCenter
                        - root.tailHeight * root.tailBaseScale
                    : outline.pointerCenter - root.tailHeight / 2
                controlY: root.effectiveTailTipRadius > 0
                    ? outline.bodyHeight
                    : outline.bodyHeight
                        + (root.tailHeight - root.strokeInset) / 2
            }
            PathLine {
                x: root.radius
                y: outline.bodyHeight
            }
            PathQuad {
                x: root.strokeInset
                y: outline.bodyHeight - root.radius
                controlX: root.strokeInset
                controlY: outline.bodyHeight
            }
            PathLine {
                x: root.strokeInset
                y: root.radius
            }
            PathQuad {
                x: root.radius
                y: root.strokeInset
                controlX: root.strokeInset
                controlY: root.strokeInset
            }
        }
    }
}
