import QtQuick
import QtQuick.Shapes as Shapes

Item {
    id: root

    property var theme: ({})

    readonly property var surface: theme.surface || ({})
    readonly property var gradientData: surface.gradient || ({})
    readonly property var gradientStops: gradientData.stops || []
    readonly property var borderData: surface.border || ({})
    readonly property var shadowData: theme.shadow || ({})
    readonly property var shapeData: theme.shape || ({})
    readonly property string preset: String(shapeData.preset || "wave")
    readonly property real depthRatio: Number(shapeData.depthRatio || 0.1)
    readonly property int repetitions: Number(shapeData.repetitions || 4)
    readonly property real phase: Number(shapeData.phase || 0)
    readonly property real borderWidth: Number(borderData.width || 0)
    readonly property real shadowSize: Number(shadowData.size || 0)
    readonly property real shadowXOffset: Number(shadowData.xOffset || 0)
    readonly property real shadowYOffset: Number(shadowData.yOffset || 0)
    readonly property real leftReserve: shadowSize
        + Math.max(0, -shadowXOffset) + borderWidth
    readonly property real rightReserve: shadowSize
        + Math.max(0, shadowXOffset) + borderWidth
    readonly property real topReserve: shadowSize
        + Math.max(0, -shadowYOffset) + borderWidth
    readonly property real bottomReserve: shadowSize
        + Math.max(0, shadowYOffset) + borderWidth
    readonly property real pathLeft: leftReserve
    readonly property real pathRight: Math.max(pathLeft + 1, width - rightReserve)
    readonly property real pathTop: topReserve
    readonly property real pathBottom: Math.max(pathTop + 1, height - bottomReserve)
    readonly property real availableWidth: pathRight - pathLeft
    readonly property real availableHeight: pathBottom - pathTop
    readonly property real shapeDepth: Math.max(1, Math.min(
        Math.min(availableWidth, availableHeight) * depthRatio,
        Math.min(availableWidth, availableHeight) * 0.24))
    readonly property bool horizontal: availableWidth >= availableHeight
    readonly property string surfacePath: buildPath(0, 0)
    readonly property string shadowPath: buildPath(shadowXOffset, shadowYOffset)

    function coordinate(value) {
        return Number(value).toFixed(2)
    }

    function pointCommand(command, x, y) {
        return command + " " + coordinate(x) + " " + coordinate(y) + " "
    }

    function waveSign(index) {
        const angle = 2 * Math.PI * (index / repetitions + phase)
        return Math.sin(angle) >= 0 ? 1 : -1
    }

    function horizontalWavePath(left, right, top, bottom, depth, bubbles) {
        const topY = top + depth
        const bottomY = bottom - depth
        const startX = left + depth
        const endX = right - depth
        const segmentWidth = Math.max(1, (endX - startX) / repetitions)
        let path = pointCommand("M", startX, topY)

        for (let index = 0; index < repetitions; ++index) {
            const segmentStart = startX + segmentWidth * index
            const segmentEnd = index === repetitions - 1
                ? endX : segmentStart + segmentWidth
            if (bubbles) {
                path += pointCommand("Q", (segmentStart + segmentEnd) / 2, top)
                    + coordinate(segmentEnd) + " " + coordinate(topY) + " "
            } else {
                const controlY = topY + waveSign(index) * depth
                path += pointCommand("C", segmentStart + segmentWidth / 3, controlY)
                    + coordinate(segmentStart + segmentWidth * 2 / 3) + " "
                    + coordinate(controlY) + " "
                    + coordinate(segmentEnd) + " " + coordinate(topY) + " "
            }
        }

        path += pointCommand("L", right, top + depth * 2)
            + pointCommand("L", right, bottom - depth * 2)
            + pointCommand("L", endX, bottomY)

        for (let index = repetitions - 1; index >= 0; --index) {
            const segmentStart = startX + segmentWidth * index
            const segmentEnd = index === repetitions - 1
                ? endX : segmentStart + segmentWidth
            if (bubbles) {
                path += pointCommand("Q", (segmentStart + segmentEnd) / 2, bottom)
                    + coordinate(segmentStart) + " " + coordinate(bottomY) + " "
            } else {
                const controlY = bottomY - waveSign(index) * depth
                path += pointCommand("C", segmentEnd - segmentWidth / 3, controlY)
                    + coordinate(segmentStart + segmentWidth / 3) + " "
                    + coordinate(controlY) + " "
                    + coordinate(segmentStart) + " " + coordinate(bottomY) + " "
            }
        }

        return path + pointCommand("L", left, bottom - depth * 2)
            + pointCommand("L", left, top + depth * 2) + "Z"
    }

    function verticalWavePath(left, right, top, bottom, depth, bubbles) {
        const leftX = left + depth
        const rightX = right - depth
        const startY = top + depth
        const endY = bottom - depth
        const segmentHeight = Math.max(1, (endY - startY) / repetitions)
        let path = pointCommand("M", leftX, startY)
            + pointCommand("L", left + depth * 2, top)
            + pointCommand("L", right - depth * 2, top)
            + pointCommand("L", rightX, startY)

        for (let index = 0; index < repetitions; ++index) {
            const segmentStart = startY + segmentHeight * index
            const segmentEnd = index === repetitions - 1
                ? endY : segmentStart + segmentHeight
            if (bubbles) {
                path += pointCommand("Q", right, (segmentStart + segmentEnd) / 2)
                    + coordinate(rightX) + " " + coordinate(segmentEnd) + " "
            } else {
                const controlX = rightX - waveSign(index) * depth
                path += pointCommand("C", controlX, segmentStart + segmentHeight / 3)
                    + coordinate(controlX) + " "
                    + coordinate(segmentStart + segmentHeight * 2 / 3) + " "
                    + coordinate(rightX) + " " + coordinate(segmentEnd) + " "
            }
        }

        path += pointCommand("L", right - depth * 2, bottom)
            + pointCommand("L", left + depth * 2, bottom)
            + pointCommand("L", leftX, endY)

        for (let index = repetitions - 1; index >= 0; --index) {
            const segmentStart = startY + segmentHeight * index
            const segmentEnd = index === repetitions - 1
                ? endY : segmentStart + segmentHeight
            if (bubbles) {
                path += pointCommand("Q", left, (segmentStart + segmentEnd) / 2)
                    + coordinate(leftX) + " " + coordinate(segmentStart) + " "
            } else {
                const controlX = leftX + waveSign(index) * depth
                path += pointCommand("C", controlX, segmentEnd - segmentHeight / 3)
                    + coordinate(controlX) + " "
                    + coordinate(segmentStart + segmentHeight / 3) + " "
                    + coordinate(leftX) + " " + coordinate(segmentStart) + " "
            }
        }

        return path + "Z"
    }

    function cutCornerPath(left, right, top, bottom, depth) {
        return pointCommand("M", left + depth, top)
            + pointCommand("L", right - depth, top)
            + pointCommand("L", right, top + depth)
            + pointCommand("L", right, bottom - depth)
            + pointCommand("L", right - depth, bottom)
            + pointCommand("L", left + depth, bottom)
            + pointCommand("L", left, bottom - depth)
            + pointCommand("L", left, top + depth) + "Z"
    }

    function buildPath(xOffset, yOffset) {
        const left = pathLeft + xOffset
        const right = pathRight + xOffset
        const top = pathTop + yOffset
        const bottom = pathBottom + yOffset
        if (preset === "cutCorners") {
            return cutCornerPath(left, right, top, bottom, shapeDepth)
        }
        return horizontal
            ? horizontalWavePath(left, right, top, bottom, shapeDepth,
                preset === "bubbles")
            : verticalWavePath(left, right, top, bottom, shapeDepth,
                preset === "bubbles")
    }

    function gradientStop(index) {
        if (gradientStops.length === 0) {
            return {
                "position": index === 0 ? 0 : 1,
                "color": surface.color || "transparent"
            }
        }
        return gradientStops[Math.min(index, gradientStops.length - 1)]
    }

    Shapes.Shape {
        anchors.fill: parent
        visible: root.shadowSize > 0
        layer.enabled: false

        Shapes.ShapePath {
            strokeWidth: root.shadowSize * 2
            strokeColor: root.shadowData.color || "transparent"
            fillColor: root.shadowData.color || "transparent"

            PathSvg {
                path: root.shadowPath
            }
        }
    }

    Shapes.Shape {
        anchors.fill: parent
        layer.enabled: false

        Shapes.ShapePath {
            strokeWidth: root.borderWidth
            strokeColor: root.borderData.color || "transparent"
            joinStyle: Shapes.ShapePath.RoundJoin
            fillGradient: Shapes.LinearGradient {
                x1: root.pathLeft
                y1: root.pathTop
                x2: root.gradientData.direction === "horizontal"
                    ? root.pathRight : root.pathLeft
                y2: root.gradientData.direction === "horizontal"
                    ? root.pathTop : root.pathBottom

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
