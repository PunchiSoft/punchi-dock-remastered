pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property var theme: ({})
    property real availableLength: 0
    property string style: String(root.effectiveTheme.style || "line")
    property real thickness: Number(root.effectiveTheme.thickness || 2)
    property real lengthRatio: Number(root.effectiveTheme.lengthRatio || 0.72)
    property real customOpacity: Number(root.effectiveTheme.opacity === undefined
        ? 0.34
        : root.effectiveTheme.opacity)
    property bool glowEnabled: root.effectiveTheme.glowEnabled === true
        || (root.effectiveTheme.glow !== undefined
            && root.effectiveTheme.glow !== null
            && Number(root.effectiveTheme.glow.size) > 0)
    property bool verticalPanel: false

    readonly property var effectiveTheme: root.theme && typeof root.theme === "object"
        ? root.theme
        : ({})
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
            root.effectiveThickness / 2, Number(root.effectiveTheme.radius || 0)))
    readonly property color effectiveColor: root.effectiveTheme.color
        || Kirigami.Theme.textColor

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
            id: doubleLineSurface

            anchors.fill: parent
            visible: root.effectiveStyle === "doubleLine"

            Rectangle {
                x: 0
                y: 0
                width: root.verticalPanel
                    ? doubleLineSurface.width
                    : root.doubleLineStroke
                height: root.verticalPanel
                    ? root.doubleLineStroke
                    : doubleLineSurface.height
                radius: root.doubleLineStroke / 2
                color: root.effectiveColor
                antialiasing: true
            }

            Rectangle {
                x: root.verticalPanel ? 0 : doubleLineSurface.width - width
                y: root.verticalPanel ? doubleLineSurface.height - height : 0
                width: root.verticalPanel
                    ? doubleLineSurface.width
                    : root.doubleLineStroke
                height: root.verticalPanel
                    ? root.doubleLineStroke
                    : doubleLineSurface.height
                radius: root.doubleLineStroke / 2
                color: root.effectiveColor
                antialiasing: true
            }
        }

        Item {
            id: chevronSurface

            anchors.centerIn: parent
            visible: root.effectiveStyle === "chevron"
            width: root.effectiveLength
            height: root.effectiveLength
            rotation: root.verticalPanel ? 90 : 0

            Rectangle {
                readonly property real armLength: chevronSurface.width * 0.66

                x: (chevronSurface.width - armLength) / 2
                y: chevronSurface.height * 0.28 - root.effectiveThickness / 2
                width: armLength
                height: root.effectiveThickness
                radius: height / 2
                color: root.effectiveColor
                rotation: 45
                antialiasing: true
            }

            Rectangle {
                readonly property real armLength: chevronSurface.width * 0.66

                x: (chevronSurface.width - armLength) / 2
                y: chevronSurface.height * 0.72 - root.effectiveThickness / 2
                width: armLength
                height: root.effectiveThickness
                radius: height / 2
                color: root.effectiveColor
                rotation: -45
                antialiasing: true
            }
        }
    }
}
