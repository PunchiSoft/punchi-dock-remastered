import QtQuick
import QtQuick.Shapes as Shapes
import org.kde.kirigami as Kirigami

// Comic-style tail of the folder popup.
//
// It is a plain triangle: its base corners sit on the effective background edge
// of the card, so the outline meets the popup edge without any step, and only the
// tip that points at the dock keeps a rounded corner. The outline is drawn here
// on purpose, because a theme frame only carries convex corners and its corner
// radius could follow no other outline than its own.
//
// What still comes from the theme is its material: the fill is the theme
// background colour the popup draws with and uses the same opacity. Frame
// insets locate the effective card edge but do not define the triangle size or
// its tip radius; those remain proportional to the dock item.
//
// Sizes stay proportional: the base is as wide as the dock item the tail points
// at, so the tail follows the icon size and the dock scale the user configured.
// No absolute length is fixed here.
Item {
    id: root

    // Edge of the dock the tail points at.
    property int location: Qt.BottomEdge
    // Insets of that frame, in logical pixels.
    property real frameInsetLeft: 0
    property real frameInsetTop: 0
    property real frameInsetRight: 0
    property real frameInsetBottom: 0
    // Opacity the popup background is drawn with, shared so both surfaces read
    // as one piece.
    property real surfaceOpacity: 1
    // Extent of the dock item the tail points at. The tail is proportional to it
    // instead of to an invented size, so it follows the icon size and the dock
    // scale the user configured.
    property real anchorExtent: 0
    // Position of the tip along the surface axis, in window coordinates. A
    // non-finite value centers the tail on the surface.
    property real tipOffset: NaN
    property bool constrainTip: false

    readonly property bool horizontal: root.location === Qt.TopEdge
        || root.location === Qt.BottomEdge
    // True when the band sits before the frame on its axis, that is, on the top
    // or on the left of the window.
    readonly property bool bandOnStart: root.location === Qt.TopEdge
        || root.location === Qt.LeftEdge
    readonly property real safeOpacity: {
        const requested = Number(root.surfaceOpacity)
        return Number.isFinite(requested)
            ? Math.max(0, Math.min(1, requested))
            : 1
    }
    // Inset of the frame on the side the tail leaves from. That band is where the
    // theme draws the border projection and the shadow, so the effective
    // background starts inside it: the tail has to start there too, which is the
    // edge the user sees and the edge the blur region is measured against.
    readonly property real dockInset: root.location === Qt.TopEdge
        ? Math.max(0, root.frameInsetTop)
        : root.location === Qt.BottomEdge
            ? Math.max(0, root.frameInsetBottom)
            : root.location === Qt.LeftEdge
                ? Math.max(0, root.frameInsetLeft)
                : Math.max(0, root.frameInsetRight)
    readonly property real safeAnchorExtent: {
        const requested = Number(root.anchorExtent)
        return Number.isFinite(requested) && requested > 0
            ? requested : Kirigami.Units.gridUnit * 2
    }
    // A compact share of the dock item keeps the pointer legible without making
    // it dominate the card edge. The inset never imposes a wider minimum.
    readonly property real tailWidthRatio: 0.55
    readonly property real tailBase: Math.max(1,
        root.safeAnchorExtent * root.tailWidthRatio)
    readonly property real halfBase: root.tailBase / 2
    // The visible triangle stays wider than deep so the card sits closer to the
    // dock and the pointer reads as a callout instead of a hanging pennant.
    readonly property real tailDepthRatio: 0.55
    // Depth of the tail, measured from the effective background edge of the card.
    readonly property real protrusion: Math.max(1,
        root.tailBase * root.tailDepthRatio)
    // Part of that depth which falls outside the frame rectangle. The surface
    // grows exactly this much, so the tip lands on the surface edge and the
    // distance the dock keeps is the one the user configured.
    readonly property real windowGrowth: Math.max(0,
        root.protrusion - root.dockInset)
    // Radius of the tip only. It follows the base rather than the frame inset,
    // keeping the point compact across themes with different shadow bands.
    readonly property real tipRadiusRatio: 0.08
    readonly property real tipRadius: Math.max(1,
        Math.min(root.tailBase * root.tipRadiusRatio, root.protrusion / 3))
    readonly property real tipPosition: {
        const requested = Number(root.tipOffset)
        if (Number.isFinite(requested)) {
            if (!root.constrainTip) {
                return requested
            }
            const extent = root.horizontal ? root.width : root.height
            const startInset = root.horizontal ? root.frameInsetLeft : root.frameInsetTop
            const endInset = root.horizontal ? root.frameInsetRight : root.frameInsetBottom
            const clearance = root.halfBase + Kirigami.Units.smallSpacing
            const minimum = Math.min(extent / 2, Math.max(0, startInset) + clearance)
            const maximum = Math.max(minimum, extent - Math.max(0, endInset) - clearance)
            return Math.max(minimum, Math.min(maximum, requested))
        }
        return root.horizontal ? root.width / 2 : root.height / 2
    }
    readonly property real flankLength: Math.sqrt(
        root.halfBase * root.halfBase + root.protrusion * root.protrusion)
    // The tip radius measured along each flank, which is where the curve meets
    // the straight part of the flank.
    readonly property real tipAlongAxis:
        root.tipRadius * root.halfBase / root.flankLength
    readonly property real tipAlongDepth:
        root.tipRadius * root.protrusion / root.flankLength

    // Maps a point given along the card edge and away from it, so a single
    // outline builder covers the four dock edges.
    function mapPoint(alongAxis, depth) {
        if (root.location === Qt.TopEdge) {
            return Qt.point(alongAxis, root.height - depth)
        }
        if (root.location === Qt.LeftEdge) {
            return Qt.point(root.width - depth, alongAxis)
        }
        if (root.location === Qt.RightEdge) {
            return Qt.point(depth, alongAxis)
        }
        return Qt.point(alongAxis, depth)
    }

    function command(letter, point) {
        return letter + " " + point.x.toFixed(2) + " " + point.y.toFixed(2) + " "
    }

    function coordinate(point) {
        return point.x.toFixed(2) + " " + point.y.toFixed(2) + " "
    }

    function quadraticPoint(start, control, end, progress) {
        const inverse = 1 - progress
        return Qt.point(
            inverse * inverse * start.x
                + 2 * inverse * progress * control.x
                + progress * progress * end.x,
            inverse * inverse * start.y
                + 2 * inverse * progress * control.y
                + progress * progress * end.y)
    }

    // Polygon of the same filled silhouette used by the vector path. KWin
    // consumes integer QRegions, so a short subdivision of the rounded tip is
    // enough to preserve the visible curve without widening blur to the whole
    // rectangular band around the tail.
    readonly property int blurTipCurveSegmentCount: 8
    readonly property var blurRegionPolygon: {
        const tip = root.tipPosition
        const half = root.halfBase
        const depth = root.protrusion
        const baseLeft = root.mapPoint(tip - half, 0)
        const tipLeft = root.mapPoint(tip - root.tipAlongAxis,
            depth - root.tipAlongDepth)
        const apex = root.mapPoint(tip, depth)
        const tipRight = root.mapPoint(tip + root.tipAlongAxis,
            depth - root.tipAlongDepth)
        const baseRight = root.mapPoint(tip + half, 0)
        const points = [baseLeft, tipLeft]
        for (let segment = 1;
             segment <= root.blurTipCurveSegmentCount; ++segment) {
            points.push(root.quadraticPoint(tipLeft, apex, tipRight,
                segment / root.blurTipCurveSegmentCount))
        }
        points.push(baseRight)
        return points
    }

    // Triangle outline, open on the card edge: from the left base corner, along the
    // flank, around the rounded tip, and back symmetrically to the right base
    // corner.
    readonly property string tailOutline: {
        const tip = root.tipPosition
        const half = root.halfBase
        const depth = root.protrusion
        const left = tip - half
        const right = tip + half
        const baseLeft = root.mapPoint(left, 0)
        const tipLeft = root.mapPoint(tip - root.tipAlongAxis,
            depth - root.tipAlongDepth)
        const apex = root.mapPoint(tip, depth)
        const tipRight = root.mapPoint(tip + root.tipAlongAxis,
            depth - root.tipAlongDepth)
        const baseRight = root.mapPoint(right, 0)
        return root.command("M", baseLeft)
            + root.command("L", tipLeft)
            + root.command("Q", apex) + root.coordinate(tipRight)
            + root.command("L", baseRight)
    }

    Shapes.Shape {
        anchors.fill: parent
        opacity: root.safeOpacity
        // The diagonals of the triangle are drawn through one multisampled
        // surface, the same pass the shaped theme surfaces use for their edges.
        // It is the cheap, project-approved way to avoid a jagged outline; a
        // shader would only be needed for an effect this edge does not require.
        layer.enabled: true
        layer.samples: 8
        layer.smooth: true
        Accessible.ignored: true

        // Filled silhouette, closed along the card edge so the fill reaches it
        // and covers the border strip the theme draws just outside the card.
        Shapes.ShapePath {
            fillColor: Kirigami.Theme.backgroundColor
            strokeColor: "transparent"
            strokeWidth: 0

            PathSvg {
                path: root.tailOutline + "Z"
            }
        }

        // Outline of the flanks and the tip only. The card edge keeps the border
        // the theme draws for the card itself.
        Shapes.ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(Kirigami.Theme.textColor.r,
                Kirigami.Theme.textColor.g,
                Kirigami.Theme.textColor.b, 0.2)
            strokeWidth: 1
            capStyle: Shapes.ShapePath.FlatCap
            joinStyle: Shapes.ShapePath.RoundJoin

            PathSvg {
                path: root.tailOutline
            }
        }
    }
}
