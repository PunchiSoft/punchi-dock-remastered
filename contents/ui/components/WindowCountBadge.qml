import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property int count: 0
    property int iconSize: 48
    property bool demandsAttention: false
    property bool badgeEnabled: false
    property bool groupingEnabled: false
    property string position: "top-right"
    property string emblemColor: ""
    property real emblemOpacity: 1.0
    property real emblemScale: 1.0

    readonly property bool visibleBadge: badgeEnabled && groupingEnabled && count >= 2
    readonly property bool topAnchored: position === "top-left" || position === "top-right"
    readonly property bool bottomAnchored: position === "bottom-left" || position === "bottom-right"
    readonly property bool leftAnchored: position === "top-left" || position === "bottom-left"
    readonly property bool rightAnchored: position === "top-right" || position === "bottom-right"
    readonly property string displayCount: count > 9 ? "9+" : String(count)
    readonly property string normalizedEmblemColor: {
        const value = String(root.emblemColor || "").trim()
        return /^#[0-9a-fA-F]{6}$/.test(value) ? value : ""
    }
    readonly property real safeEmblemOpacity: {
        const value = Number(root.emblemOpacity)
        return Number.isFinite(value) ? Math.max(0.6, Math.min(1.0, value)) : 1.0
    }
    readonly property real safeEmblemScale: {
        const value = Number(root.emblemScale)
        return Number.isFinite(value) ? Math.max(0.8, Math.min(1.2, value)) : 1.0
    }
    readonly property int baseBadgeHeight: Math.max(14, Math.round(root.iconSize * 0.34))
    readonly property int maximumBadgeHeight: Math.max(14, Math.round(Math.min(
        root.iconSize,
        root.width > 0 ? root.width : root.iconSize,
        root.height > 0 ? root.height : root.iconSize) * 0.48))
    readonly property int effectiveBadgeHeight: Math.max(12, Math.min(
        root.maximumBadgeHeight,
        Math.round(root.baseBadgeHeight * root.safeEmblemScale)))
    readonly property int effectiveHorizontalPadding: Math.max(6,
        Math.round(8 * root.safeEmblemScale))
    readonly property color resolvedBgColor: root.demandsAttention
        ? Kirigami.Theme.negativeTextColor
        : (root.normalizedEmblemColor.length > 0
            ? root.normalizedEmblemColor
            : Kirigami.Theme.highlightColor)
    readonly property color resolvedTextColor: {
        if (root.demandsAttention || root.normalizedEmblemColor.length === 0) {
            return Kirigami.Theme.highlightedTextColor
        }

        let baseTextColor = Kirigami.Theme.textColor
        if (Kirigami.ColorUtils.brightnessForColor(root.resolvedBgColor)
                === Kirigami.ColorUtils.brightnessForColor(baseTextColor)) {
            baseTextColor = Kirigami.ColorUtils.brightnessForColor(root.resolvedBgColor)
                === Kirigami.ColorUtils.Light ? "black" : "white"
        }
        return Kirigami.ColorUtils.linearInterpolation(
            baseTextColor, root.resolvedBgColor, 0.17)
    }

    visible: root.visibleBadge

    Rectangle {
        id: badge
        width: Math.max(height, countLabel.implicitWidth + root.effectiveHorizontalPadding)
        height: root.effectiveBadgeHeight
        opacity: root.safeEmblemOpacity
        x: root.leftAnchored
            ? 1
            : (root.rightAnchored
                ? Math.max(1, root.width - width - 1)
                : Math.round((root.width - width) / 2))
        y: root.topAnchored
            ? 1
            : (root.bottomAnchored
                ? Math.max(1, root.height - height - 1)
                : Math.round((root.height - height) / 2))
        radius: height / 2
        color: root.resolvedBgColor
        border.width: 1
        border.color: Kirigami.Theme.backgroundColor

        Text {
            id: countLabel
            anchors.centerIn: parent
            text: root.displayCount
            color: root.resolvedTextColor
            font.bold: true
            font.pixelSize: Math.max(9,
                Math.round(root.iconSize * 0.19 * root.safeEmblemScale))
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
