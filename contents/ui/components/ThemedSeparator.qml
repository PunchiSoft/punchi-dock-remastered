pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property var theme: ({})
    property real availableLength: 0
    property string style: String(theme.style || "line")
    property real thickness: Number(theme.thickness || 2)
    property real lengthRatio: Number(theme.lengthRatio || 0.72)
    property real customOpacity: Number(theme.opacity === undefined ? 0.34 : theme.opacity)
    property bool glowEnabled: theme.glowEnabled === true || (theme.glow && theme.glow.size > 0)
    property bool verticalPanel: false

    readonly property var supportedStyles: [
        "line", "dot", "square", "capsule", "star", "diamond", "ring",
        "doubleLine", "chevron"
    ]
    readonly property string requestedStyle: style === "pill" ? "capsule" : style
    readonly property string effectiveStyle: root.supportedStyles.indexOf(root.requestedStyle) >= 0
        ? root.requestedStyle
        : "line"
    readonly property real requestedThickness: Math.max(1, thickness)
    readonly property real effectiveThickness: root.availableLength > 0
        ? Math.min(root.requestedThickness, root.availableLength)
        : root.requestedThickness
    readonly property bool compactMarker: [
        "dot", "square", "star", "diamond", "ring", "chevron"
    ].indexOf(root.effectiveStyle) >= 0
    readonly property real decorativeMarkerSize: Math.max(
        Kirigami.Units.smallSpacing * 2, root.effectiveThickness * 2.5)
    readonly property real effectiveLength: root.compactMarker
        ? ((root.effectiveStyle === "dot" || root.effectiveStyle === "square")
            ? root.effectiveThickness : root.decorativeMarkerSize)
        : Math.max(effectiveThickness, Math.round(availableLength * lengthRatio))
    readonly property real doubleLineStroke: root.availableLength > 0
        ? Math.max(1, Math.min(root.effectiveThickness, root.availableLength / 3))
        : root.effectiveThickness
    readonly property real doubleLineGap: root.doubleLineStroke
    readonly property real effectiveCrossLength: root.compactMarker
        ? root.effectiveLength
        : (root.effectiveStyle === "doubleLine"
            ? root.doubleLineStroke * 2 + root.doubleLineGap
            : root.effectiveThickness)
    readonly property real effectiveRadius: root.effectiveStyle === "dot"
        || root.effectiveStyle === "capsule"
        ? root.effectiveThickness / 2
        : (root.effectiveStyle === "square" ? 0 : Math.min(
            root.effectiveThickness / 2, Number(theme.radius || 0)))
    readonly property color effectiveColor: theme.color || Kirigami.Theme.textColor

    implicitWidth: root.verticalPanel ? root.effectiveLength : root.effectiveCrossLength
    implicitHeight: root.verticalPanel ? root.effectiveCrossLength : root.effectiveLength
    opacity: customOpacity

    // Subtle glow layer when enabled
    Rectangle {
        visible: root.glowEnabled
        anchors.centerIn: parent
        width: parent.width + Kirigami.Units.smallSpacing * 2
        height: parent.height + Kirigami.Units.smallSpacing * 2
        radius: Math.min(width, height) / 2
        color: Kirigami.Theme.highlightColor
        opacity: 0.25
        antialiasing: true
    }

    // Main separator surface
    Item {
        anchors.fill: parent

        // Standard geometric shapes (line, dot, square, capsule)
        Rectangle {
            anchors.fill: parent
            visible: ["line", "dot", "square", "capsule"].indexOf(root.effectiveStyle) >= 0
            color: root.effectiveColor
            radius: root.effectiveRadius
            antialiasing: true
        }

        // Star shape using Kirigami theme symbolic icon
        Kirigami.Icon {
            anchors.centerIn: parent
            visible: root.effectiveStyle === "star"
            width: root.effectiveLength
            height: root.effectiveLength
            source: "favorite-symbolic"
        }

        Rectangle {
            anchors.centerIn: parent
            visible: root.effectiveStyle === "diamond"
            width: root.effectiveLength / Math.SQRT2
            height: width
            color: root.effectiveColor
            rotation: 45
            antialiasing: true
        }

        Rectangle {
            anchors.fill: parent
            visible: root.effectiveStyle === "ring"
            color: "transparent"
            radius: Math.min(width, height) / 2
            border.width: Math.max(1, Math.min(root.effectiveThickness,
                root.effectiveLength / 3))
            border.color: root.effectiveColor
            antialiasing: true
        }

        Item {
            anchors.fill: parent
            visible: root.effectiveStyle === "doubleLine"

            Repeater {
                model: 2

                delegate: Rectangle {
                    required property int index

                    x: root.verticalPanel
                        ? 0
                        : (index === 0 ? 0 : parent.width - width)
                    y: root.verticalPanel
                        ? (index === 0 ? 0 : parent.height - height)
                        : 0
                    width: root.verticalPanel ? parent.width : root.doubleLineStroke
                    height: root.verticalPanel ? root.doubleLineStroke : parent.height
                    radius: root.doubleLineStroke / 2
                    color: root.effectiveColor
                    antialiasing: true
                }
            }
        }

        Item {
            anchors.centerIn: parent
            visible: root.effectiveStyle === "chevron"
            width: root.effectiveLength
            height: root.effectiveLength
            rotation: root.verticalPanel ? 90 : 0

            Repeater {
                model: 2

                delegate: Rectangle {
                    required property int index

                    readonly property real armLength: parent.width * 0.66

                    x: (parent.width - armLength) / 2
                    y: parent.height * (index === 0 ? 0.28 : 0.72)
                        - root.effectiveThickness / 2
                    width: armLength
                    height: root.effectiveThickness
                    radius: height / 2
                    color: root.effectiveColor
                    rotation: index === 0 ? 45 : -45
                    antialiasing: true
                }
            }
        }
    }
}
