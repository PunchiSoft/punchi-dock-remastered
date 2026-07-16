import QtQuick
import QtQuick.Shapes as Shapes

Item {
    id: root

    property var theme: ({})

    readonly property var surface: theme.surface || ({})
    readonly property var surfaceGradient: surface.gradient || ({})
    readonly property var surfaceGradientStops: surfaceGradient.stops || []
    readonly property var surfaceBorder: surface.border || ({})
    readonly property var shadowData: theme.shadow || ({})
    readonly property var shelfData: theme.shelf || ({})
    readonly property var geometry: shelfData.geometry || ({})
    readonly property var edgeData: shelfData.edge || ({})
    readonly property var edgeGradient: edgeData.gradient || ({})
    readonly property var edgeGradientStops: edgeGradient.stops || []
    readonly property var edgeBorder: edgeData.border || ({})
    readonly property var rimData: shelfData.rim || ({})
    readonly property var rimGlow: rimData.glow || ({})
    readonly property color sheenColor: surfaceBorder.color || "white"
    readonly property color rimGlowColor: rimGlow.color || "transparent"

    readonly property real shadowSize: Number(shadowData.size || 0)
    readonly property real shadowXOffset: Number(shadowData.xOffset || 0)
    readonly property real shadowYOffset: Number(shadowData.yOffset || 0)
    readonly property real edgeDepth: Number(geometry.edgeDepth || 18)
    readonly property real rimThickness: Number(geometry.rimThickness || 3)
    readonly property real horizontalInset: Number(geometry.horizontalInset || 4)
    readonly property real topDepthRatio: Number(geometry.topDepthRatio || 0.56)
    readonly property real backInset: Number(geometry.backInset || 20)
    readonly property real sideBevel: Number(geometry.sideBevel || 5)
    readonly property real rimGlowSize: Math.max(0, Number(rimGlow.size || 0))
    readonly property real rimGlowHorizontalExtent: Math.min(3,
        rimGlowSize * 0.25)
    readonly property real rimOpacity: Number(
        rimData.opacity === undefined ? 1 : rimData.opacity)
    readonly property real leftReserve: shadowSize + Math.max(0, -shadowXOffset)
    readonly property real rightReserve: shadowSize + Math.max(0, shadowXOffset)
    readonly property real topReserve: shadowSize + Math.max(0, -shadowYOffset)
    readonly property real bottomReserve: shadowSize + Math.max(0, shadowYOffset)
    readonly property real shelfX: leftReserve + horizontalInset
    readonly property real shelfWidth: Math.max(1, width - leftReserve
        - rightReserve - (horizontalInset * 2))
    readonly property real frontY: height - bottomReserve - edgeDepth
    readonly property real availableTopDepth: Math.max(1, frontY - topReserve)
    readonly property real topDepth: Math.max(12, availableTopDepth * topDepthRatio)
    readonly property real backY: Math.max(topReserve, frontY - topDepth)
    readonly property real safeBackInset: Math.min(backInset, shelfWidth * 0.24)
    readonly property real safeSideBevel: Math.min(sideBevel, shelfWidth * 0.08)

    function surfaceStop(index) {
        if (surfaceGradientStops.length === 0) {
            return {
                "position": index === 0 ? 0 : 1,
                "color": surface.color || "transparent"
            }
        }
        return surfaceGradientStops[Math.min(index, surfaceGradientStops.length - 1)]
    }

    function edgeStop(index) {
        if (edgeGradientStops.length === 0) {
            return {
                "position": index === 0 ? 0 : 1,
                "color": edgeData.color || "transparent"
            }
        }
        return edgeGradientStops[Math.min(index, edgeGradientStops.length - 1)]
    }

    Shapes.Shape {
        id: shadowPlane
        anchors.fill: parent
        z: -1
        opacity: root.shadowSize > 0 ? 0.34 : 0
        layer.enabled: false

        Shapes.ShapePath {
            strokeWidth: 0
            fillColor: root.shadowData.color || "transparent"
            startX: root.shelfX + root.safeBackInset + root.shadowXOffset
            startY: root.backY + root.shadowYOffset + 2

            PathLine {
                x: root.shelfX + root.shelfWidth - root.safeBackInset + root.shadowXOffset
                y: root.backY + root.shadowYOffset + 2
            }
            PathLine {
                x: root.shelfX + root.shelfWidth + root.shadowXOffset
                y: root.frontY + root.edgeDepth + root.shadowYOffset
            }
            PathLine {
                x: root.shelfX + root.shadowXOffset
                y: root.frontY + root.edgeDepth + root.shadowYOffset
            }
            PathLine {
                x: root.shelfX + root.safeBackInset + root.shadowXOffset
                y: root.backY + root.shadowYOffset + 2
            }
        }
    }

    Shapes.Shape {
        id: topPlane
        anchors.fill: parent
        z: 0
        layer.enabled: false

        Shapes.ShapePath {
            strokeWidth: Number(root.surfaceBorder.width || 0)
            strokeColor: root.surfaceBorder.color || "transparent"
            joinStyle: Shapes.ShapePath.RoundJoin
            fillGradient: Shapes.LinearGradient {
                x1: root.shelfX
                y1: root.backY
                x2: root.shelfX
                y2: root.frontY

                GradientStop { position: Number(root.surfaceStop(0).position); color: root.surfaceStop(0).color }
                GradientStop { position: Number(root.surfaceStop(1).position); color: root.surfaceStop(1).color }
                GradientStop { position: Number(root.surfaceStop(2).position); color: root.surfaceStop(2).color }
                GradientStop { position: Number(root.surfaceStop(3).position); color: root.surfaceStop(3).color }
                GradientStop { position: Number(root.surfaceStop(4).position); color: root.surfaceStop(4).color }
                GradientStop { position: Number(root.surfaceStop(5).position); color: root.surfaceStop(5).color }
                GradientStop { position: Number(root.surfaceStop(6).position); color: root.surfaceStop(6).color }
                GradientStop { position: Number(root.surfaceStop(7).position); color: root.surfaceStop(7).color }
            }
            startX: root.shelfX + root.safeBackInset
            startY: root.backY

            PathLine {
                x: root.shelfX + root.shelfWidth - root.safeBackInset
                y: root.backY
            }
            PathLine {
                x: root.shelfX + root.shelfWidth
                y: root.frontY
            }
            PathLine {
                x: root.shelfX
                y: root.frontY
            }
            PathLine {
                x: root.shelfX + root.safeBackInset
                y: root.backY
            }
        }
    }

    Shapes.Shape {
        anchors.fill: parent
        z: 0.5
        layer.enabled: false

        Shapes.ShapePath {
            strokeWidth: 0
            fillGradient: Shapes.LinearGradient {
                x1: root.shelfX
                y1: root.backY
                x2: root.shelfX
                y2: root.frontY

                GradientStop {
                    position: 0
                    color: Qt.rgba(root.sheenColor.r, root.sheenColor.g,
                        root.sheenColor.b, 0.22)
                }
                GradientStop {
                    position: 0.5
                    color: Qt.rgba(root.sheenColor.r, root.sheenColor.g,
                        root.sheenColor.b, 0.06)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(root.sheenColor.r, root.sheenColor.g,
                        root.sheenColor.b, 0)
                }
            }
            startX: root.shelfX + root.safeBackInset
            startY: root.backY

            PathLine {
                x: root.shelfX + root.shelfWidth - root.safeBackInset
                y: root.backY
            }
            PathLine {
                x: root.shelfX + root.shelfWidth
                y: root.frontY
            }
            PathLine {
                x: root.shelfX
                y: root.frontY
            }
            PathLine {
                x: root.shelfX + root.safeBackInset
                y: root.backY
            }
        }
    }

    Shapes.Shape {
        id: frontEdge
        anchors.fill: parent
        z: 1
        layer.enabled: false

        Shapes.ShapePath {
            strokeWidth: Number(root.edgeBorder.width || 0)
            strokeColor: root.edgeBorder.color || "transparent"
            joinStyle: Shapes.ShapePath.RoundJoin
            fillGradient: Shapes.LinearGradient {
                x1: root.shelfX
                y1: root.frontY
                x2: root.shelfX
                y2: root.frontY + root.edgeDepth

                GradientStop { position: Number(root.edgeStop(0).position); color: root.edgeStop(0).color }
                GradientStop { position: Number(root.edgeStop(1).position); color: root.edgeStop(1).color }
                GradientStop { position: Number(root.edgeStop(2).position); color: root.edgeStop(2).color }
                GradientStop { position: Number(root.edgeStop(3).position); color: root.edgeStop(3).color }
                GradientStop { position: Number(root.edgeStop(4).position); color: root.edgeStop(4).color }
                GradientStop { position: Number(root.edgeStop(5).position); color: root.edgeStop(5).color }
                GradientStop { position: Number(root.edgeStop(6).position); color: root.edgeStop(6).color }
                GradientStop { position: Number(root.edgeStop(7).position); color: root.edgeStop(7).color }
            }
            startX: root.shelfX
            startY: root.frontY

            PathLine {
                x: root.shelfX + root.shelfWidth
                y: root.frontY
            }
            PathLine {
                x: root.shelfX + root.shelfWidth - root.safeSideBevel
                y: root.frontY + root.edgeDepth
            }
            PathLine {
                x: root.shelfX + root.safeSideBevel
                y: root.frontY + root.edgeDepth
            }
            PathLine {
                x: root.shelfX
                y: root.frontY
            }
        }
    }

    Shapes.Shape {
        anchors.fill: parent
        z: 2
        opacity: 0.34
        layer.enabled: false

        Shapes.ShapePath {
            strokeWidth: 0
            fillColor: Qt.lighter(root.edgeData.color || "transparent", 1.28)
            startX: root.shelfX
            startY: root.frontY

            PathLine {
                x: root.shelfX + root.safeSideBevel
                y: root.frontY + root.edgeDepth
            }
            PathLine {
                x: root.shelfX + root.safeSideBevel + 3
                y: root.frontY + root.edgeDepth
            }
            PathLine {
                x: root.shelfX + 3
                y: root.frontY
            }
            PathLine {
                x: root.shelfX
                y: root.frontY
            }
        }

        Shapes.ShapePath {
            strokeWidth: 0
            fillColor: Qt.darker(root.edgeData.color || "transparent", 1.32)
            startX: root.shelfX + root.shelfWidth
            startY: root.frontY

            PathLine {
                x: root.shelfX + root.shelfWidth - root.safeSideBevel
                y: root.frontY + root.edgeDepth
            }
            PathLine {
                x: root.shelfX + root.shelfWidth - root.safeSideBevel - 3
                y: root.frontY + root.edgeDepth
            }
            PathLine {
                x: root.shelfX + root.shelfWidth - 3
                y: root.frontY
            }
            PathLine {
                x: root.shelfX + root.shelfWidth
                y: root.frontY
            }
        }
    }

    Shapes.Shape {
        anchors.fill: parent
        z: 2.5
        layer.enabled: false

        Shapes.ShapePath {
            strokeWidth: 1
            strokeColor: root.edgeBorder.color || "transparent"
            fillColor: "transparent"
            startX: root.shelfX + root.safeSideBevel + 1
            startY: root.frontY + root.edgeDepth - 1.5

            PathLine {
                x: root.shelfX + root.shelfWidth
                    - root.safeSideBevel - 1
                y: root.frontY + root.edgeDepth - 1.5
            }
        }
    }

    Rectangle {
        visible: root.rimGlowSize > 0
        x: root.shelfX - root.rimGlowHorizontalExtent
        y: root.frontY - (root.rimThickness / 2) - root.rimGlowSize
        width: root.shelfWidth + (root.rimGlowHorizontalExtent * 2)
        height: root.rimThickness + (root.rimGlowSize * 2)
        z: 2.9
        radius: Math.min(height / 2, root.rimGlowSize)
        color: "transparent"
        opacity: root.rimOpacity
        antialiasing: true

        gradient: Gradient {
            orientation: Gradient.Vertical

            GradientStop {
                position: 0
                color: Qt.rgba(root.rimGlowColor.r, root.rimGlowColor.g,
                    root.rimGlowColor.b, 0)
            }
            GradientStop {
                position: 0.38
                color: Qt.rgba(root.rimGlowColor.r, root.rimGlowColor.g,
                    root.rimGlowColor.b, root.rimGlowColor.a * 0.12)
            }
            GradientStop {
                position: 0.5
                color: Qt.rgba(root.rimGlowColor.r, root.rimGlowColor.g,
                    root.rimGlowColor.b, root.rimGlowColor.a * 0.34)
            }
            GradientStop {
                position: 0.62
                color: Qt.rgba(root.rimGlowColor.r, root.rimGlowColor.g,
                    root.rimGlowColor.b, root.rimGlowColor.a * 0.12)
            }
            GradientStop {
                position: 1
                color: Qt.rgba(root.rimGlowColor.r, root.rimGlowColor.g,
                    root.rimGlowColor.b, 0)
            }
        }
    }

    Rectangle {
        x: root.shelfX
        y: root.frontY - (root.rimThickness / 2)
        width: root.shelfWidth
        height: root.rimThickness
        z: 3
        radius: height / 2
        color: root.rimData.color || "transparent"
        opacity: root.rimOpacity
        antialiasing: true
    }

    Rectangle {
        x: root.shelfX + root.safeBackInset
        y: root.backY
        width: Math.max(1, root.shelfWidth - (root.safeBackInset * 2))
        height: 1
        z: 4
        color: root.surfaceBorder.color || "transparent"
        opacity: 0.5
    }
}
