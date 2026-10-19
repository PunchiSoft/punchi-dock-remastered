// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

// Comic speech-balloon surface for the dock item tooltip. The silhouette keeps
// a rounded body and a directional tail while the fill and stroke follow the
// active Plasma window colors. The surface owns no text or interaction; the
// tooltip content places its label over it.
Item {
    id: root

    property string text: ""
    property string tailEdge: "bottom"
    property color fillColor: Kirigami.Theme.backgroundColor
    property color strokeColor: Qt.alpha(Kirigami.Theme.textColor, 0.2)
    property real borderWidth: Kirigami.Units.smallSpacing / 4
    property real cornerRadius: Kirigami.Units.cornerRadius * 2
    property real tailHeight: Kirigami.Units.largeSpacing
    property real padding: Kirigami.Units.largeSpacing
    property real tailBaseScale: 1
    property real tailTipRadius: 0
    property real pointerX: width / 2
    property real pointerY: height / 2

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Window

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
    readonly property real horizontalInset: verticalTail ? tailHeight : 0
    readonly property real verticalInset: verticalTail ? 0 : tailHeight
    readonly property font labelFont: {
        const value = Kirigami.Theme.defaultFont
        value.bold = true
        return value
    }

    TextMetrics {
        id: labelMetrics
        font: root.labelFont
        text: root.text
    }

    implicitWidth: Math.ceil(labelMetrics.advanceWidth) + padding * 2
        + horizontalInset
    implicitHeight: Math.ceil(labelMetrics.height) + padding * 2
        + verticalInset

    BalloonSurface {
        anchors.fill: parent
        fillColor: root.fillColor
        strokeColor: root.strokeColor
        borderWidth: root.borderWidth
        cornerRadius: root.cornerRadius
        tailHeight: root.tailHeight
        tailBaseScale: root.tailBaseScale
        tailTipRadius: root.tailTipRadius
        tailEdge: root.tailEdge
        pointerX: root.pointerX
        pointerY: root.pointerY
    }

    Controls.Label {
        id: label

        x: root.padding + (root.tailEdge === "left" ? root.tailHeight : 0)
        y: root.padding + (root.tailEdge === "top" ? root.tailHeight : 0)
        width: root.width - root.padding * 2
            - (root.verticalTail ? root.tailHeight : 0)
        height: root.height - root.padding * 2
            - (root.verticalTail ? 0 : root.tailHeight)
        text: root.text
        textFormat: Text.PlainText
        color: Kirigami.Theme.textColor
        font: root.labelFont
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
    }
}
