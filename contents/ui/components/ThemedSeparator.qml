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

    readonly property string effectiveStyle: style
    readonly property real effectiveThickness: Math.max(1, thickness)
    readonly property real effectiveLength: (effectiveStyle === "dot" || effectiveStyle === "square" || effectiveStyle === "star")
        ? (effectiveStyle === "star" ? Math.max(12, effectiveThickness * 2.5) : effectiveThickness)
        : Math.max(effectiveThickness, Math.round(availableLength * lengthRatio))
    readonly property real effectiveRadius: effectiveStyle === "dot" || effectiveStyle === "pill"
        ? effectiveThickness / 2
        : (effectiveStyle === "square" ? 0 : Math.min(effectiveThickness / 2, Number(theme.radius || 0)))

    implicitWidth: effectiveThickness
    implicitHeight: effectiveLength
    opacity: customOpacity

    // Subtle glow layer when enabled
    Rectangle {
        visible: root.glowEnabled
        anchors.centerIn: parent
        width: root.effectiveThickness + 8
        height: root.effectiveLength + 8
        radius: Math.min(width / 2, root.effectiveRadius + 4)
        color: Kirigami.Theme.highlightColor
        opacity: 0.25
        antialiasing: true
    }

    // Main separator surface
    Item {
        anchors.fill: parent

        // Standard geometric shapes (line, dot, square, pill)
        Rectangle {
            anchors.fill: parent
            visible: root.effectiveStyle !== "star"
            color: theme.color || Kirigami.Theme.textColor
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
    }
}
