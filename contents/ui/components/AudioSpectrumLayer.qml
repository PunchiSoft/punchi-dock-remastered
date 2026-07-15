pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property var levels: []
    property bool active: false
    property real intensity: 0.35
    property bool usePlasmaTheme: true
    property int barCount: 12
    property bool vertical: false
    property int originEdge: Qt.BottomEdge
    property real edgeInset: 0
    property string barStyle: "edge"
    property string flowDirection: "none"
    property real flowOffset: 0

    readonly property var baseDisplayLevels: resolvedLevels(levels, barCount)
    readonly property var displayLevels: flowedLevels(baseDisplayLevels,
        flowOffset, flowDirection)
    readonly property bool centeredBars: barStyle === "centered"
    readonly property bool capsuleBars: barStyle === "capsules"
    readonly property bool pixelBars: barStyle === "pixel"
    readonly property bool barRendererVisible: ["edge", "centered", "capsules", "pixel"].indexOf(barStyle) >= 0
    readonly property bool cloudVisible: barStyle === "cloud"
    readonly property bool particlesVisible: barStyle === "particles"

    implicitWidth: 0
    implicitHeight: 0

    clip: true
    opacity: active ? Math.max(0.1, Math.min(0.6, intensity)) : 0
    visible: opacity > 0
    Accessible.ignored: true

    onLevelsChanged: advanceFlow()
    onFlowDirectionChanged: flowOffset = 0

    function resolvedLevels(source, requestedCount) {
        if (!source || source.length === 0) {
            return []
        }

        const count = Math.max(1, requestedCount)
        const resolved = []
        if (count <= source.length) {
            for (let group = 0; group < count; ++group) {
                const first = Math.floor(group * source.length / count)
                const end = Math.max(first + 1, Math.floor((group + 1) * source.length / count))
                let peak = 0
                for (let band = first; band < end; ++band) {
                    peak = Math.max(peak, Number(source[band] || 0))
                }
                resolved.push(peak)
            }
            return resolved
        }

        if (source.length === 1) {
            for (let index = 0; index < count; ++index) {
                resolved.push(Number(source[0] || 0))
            }
            return resolved
        }

        for (let index = 0; index < count; ++index) {
            const position = index * (source.length - 1) / Math.max(1, count - 1)
            const first = Math.floor(position)
            const second = Math.min(source.length - 1, first + 1)
            const fraction = position - first
            const smoothFraction = fraction * fraction * (3 - (2 * fraction))
            const firstLevel = Number(source[first] || 0)
            const secondLevel = Number(source[second] || 0)
            resolved.push(firstLevel + ((secondLevel - firstLevel) * smoothFraction))
        }
        return resolved
    }

    function advanceFlow() {
        if (!active || flowDirection === "none" || !levels || levels.length === 0) {
            return
        }

        let energy = 0
        for (let index = 0; index < levels.length; ++index) {
            energy += Math.max(0, Math.min(1, Number(levels[index] || 0)))
        }
        energy /= levels.length
        if (energy <= 0.02) {
            return
        }

        const count = Math.max(1, baseDisplayLevels.length)
        flowOffset = (flowOffset + ((energy - 0.02) * 0.45)) % count
    }

    function flowedLevels(source, offset, direction) {
        if (!source || source.length === 0 || direction === "none") {
            return source || []
        }

        const flowed = []
        const signedOffset = direction === "right" ? -offset : offset
        for (let index = 0; index < source.length; ++index) {
            let position = (index + signedOffset) % source.length
            if (position < 0) {
                position += source.length
            }
            const first = Math.floor(position)
            const second = (first + 1) % source.length
            const fraction = position - first
            flowed.push(Number(source[first] || 0) * (1 - fraction)
                + Number(source[second] || 0) * fraction)
        }
        return flowed
    }

    function resolvedColor(index, level) {
        if (usePlasmaTheme) {
            return Kirigami.Theme.highlightColor
        }

        const bandPhase = index / Math.max(1, displayLevels.length)
        const rhythmShift = Math.max(0, Math.min(1, level)) * 0.16
        return Qt.hsla((bandPhase + rhythmShift) % 1, 0.76, 0.58, 1)
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Kirigami.Units.shortDuration
            easing.type: Easing.OutCubic
        }
    }

    Grid {
        id: bars
        anchors.fill: parent
        anchors.leftMargin: !root.centeredBars && root.originEdge === Qt.LeftEdge ? root.edgeInset : 0
        anchors.rightMargin: !root.centeredBars && root.originEdge === Qt.RightEdge ? root.edgeInset : 0
        anchors.topMargin: !root.centeredBars && root.originEdge === Qt.TopEdge ? root.edgeInset : 0
        anchors.bottomMargin: !root.centeredBars && root.originEdge === Qt.BottomEdge ? root.edgeInset : 0
        readonly property real flowExtent: root.vertical ? height : width
        readonly property bool hasRoomForSpacing: flowExtent >= root.displayLevels.length * 2

        spacing: hasRoomForSpacing
            ? Math.max(1, Math.round(Kirigami.Units.smallSpacing / (root.capsuleBars ? 1 : 2)))
            : 0
        columns: root.vertical ? 1 : Math.max(1, root.displayLevels.length)
        rows: root.vertical ? Math.max(1, root.displayLevels.length) : 1
        visible: root.barRendererVisible

        readonly property real resolvedBarWidth: root.displayLevels.length > 0
            ? (root.vertical
                ? width
                : Math.max(1, (width - (spacing * (root.displayLevels.length - 1))) / root.displayLevels.length))
            : 0
        readonly property real resolvedBarHeight: root.displayLevels.length > 0
            ? (root.vertical
                ? Math.max(1, (height - (spacing * (root.displayLevels.length - 1))) / root.displayLevels.length)
                : height)
            : 0

        Repeater {
            model: root.displayLevels.length

            delegate: Item {
                id: barDelegate

                required property int index
                readonly property real level: Math.max(0, Math.min(1,
                    Number(root.displayLevels[index] || 0)))

                width: bars.resolvedBarWidth
                height: bars.resolvedBarHeight

                Rectangle {
                    x: root.vertical
                        ? (root.centeredBars
                            ? Math.round((parent.width - width) / 2)
                            : root.originEdge === Qt.RightEdge
                                ? parent.width - width
                                : 0)
                        : 0
                    y: !root.vertical
                        ? (root.centeredBars
                            ? Math.round((parent.height - height) / 2)
                            : root.originEdge === Qt.BottomEdge
                                ? parent.height - height
                                : 0)
                        : 0
                    width: root.vertical
                        ? Math.max(1, parent.width * (root.capsuleBars ? 0.12 + (barDelegate.level * 0.88) : barDelegate.level))
                        : parent.width
                    height: root.vertical
                        ? parent.height
                        : Math.max(1, parent.height * (root.capsuleBars ? 0.12 + (barDelegate.level * 0.88) : barDelegate.level))
                    radius: root.capsuleBars
                        ? Math.min(width, height) / 2
                        : Math.min(width / 2, Kirigami.Units.smallSpacing)
                    color: root.resolvedColor(barDelegate.index, barDelegate.level)
                    visible: !root.pixelBars
                }

                Repeater {
                    model: root.pixelBars ? 7 : 0

                    delegate: Rectangle {
                        id: pixelSegment

                        required property int index
                        readonly property real segmentGap: 1
                        readonly property real segmentWidth: root.vertical
                            ? Math.max(1, (barDelegate.width - (segmentGap * 6)) / 7)
                            : barDelegate.width
                        readonly property real segmentHeight: root.vertical
                            ? barDelegate.height
                            : Math.max(1, (barDelegate.height - (segmentGap * 6)) / 7)

                        x: root.vertical
                            ? (root.originEdge === Qt.RightEdge
                                ? barDelegate.width - ((index + 1) * segmentWidth) - (index * segmentGap)
                                : index * (segmentWidth + segmentGap))
                            : 0
                        y: root.vertical
                            ? 0
                            : (root.originEdge === Qt.BottomEdge
                                ? barDelegate.height - ((index + 1) * segmentHeight) - (index * segmentGap)
                                : index * (segmentHeight + segmentGap))
                        width: segmentWidth
                        height: segmentHeight
                        radius: Math.min(2, width / 3, height / 3)
                        color: root.resolvedColor(barDelegate.index, barDelegate.level)
                        opacity: 0.45 + (barDelegate.level * 0.55)
                        visible: index < Math.ceil(barDelegate.level * 7)
                    }
                }
            }
        }
    }

    Item {
        id: cloud
        anchors.fill: parent
        readonly property int blobCount: Math.min(12,
            Math.max(4, Math.round(root.displayLevels.length / 3)))
        visible: root.cloudVisible

        Repeater {
            model: cloud.blobCount

            delegate: Rectangle {
                id: cloudBlob

                required property int index
                readonly property int levelIndex: Math.max(0,
                    Math.min(root.displayLevels.length - 1,
                        Math.floor(index * root.displayLevels.length / cloud.blobCount)))
                readonly property real level: Math.max(0, Math.min(1,
                    Number(root.displayLevels[levelIndex] || 0)))
                readonly property real flowPosition: (index + 0.5) / cloud.blobCount
                readonly property real crossScale: 0.28 + (level * 0.72)

                x: root.vertical
                    ? Math.round((cloud.width - width) / 2)
                    : Math.round((cloud.width * flowPosition) - (width / 2))
                y: root.vertical
                    ? Math.round((cloud.height * flowPosition) - (height / 2))
                    : Math.round((cloud.height - height) / 2)
                width: root.vertical
                    ? Math.max(2, cloud.width * crossScale)
                    : Math.max(4, cloud.width / cloud.blobCount * 2.4)
                height: root.vertical
                    ? Math.max(4, cloud.height / cloud.blobCount * 2.4)
                    : Math.max(2, cloud.height * crossScale)
                radius: Math.min(width, height) / 2
                color: root.resolvedColor(levelIndex, level)
                opacity: 0.12 + (level * 0.5)

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.58
                    height: parent.height * 0.58
                    radius: Math.min(width, height) / 2
                    color: parent.color
                    opacity: 0.55
                }
            }
        }
    }

    Item {
        id: particles
        anchors.fill: parent
        anchors.leftMargin: root.originEdge === Qt.LeftEdge ? root.edgeInset : 0
        anchors.rightMargin: root.originEdge === Qt.RightEdge ? root.edgeInset : 0
        anchors.topMargin: root.originEdge === Qt.TopEdge ? root.edgeInset : 0
        anchors.bottomMargin: root.originEdge === Qt.BottomEdge ? root.edgeInset : 0
        readonly property int particleCount: Math.min(24,
            Math.max(8, root.displayLevels.length))
        visible: root.particlesVisible

        Repeater {
            model: particles.particleCount

            delegate: Rectangle {
                id: particle

                required property int index
                readonly property int levelIndex: Math.max(0,
                    Math.min(root.displayLevels.length - 1,
                        Math.floor(index * root.displayLevels.length / particles.particleCount)))
                readonly property real level: Math.max(0, Math.min(1,
                    Number(root.displayLevels[levelIndex] || 0)))
                readonly property real flowPosition: (index + 0.5) / particles.particleCount
                readonly property real crossExtent: root.vertical ? particles.width : particles.height
                readonly property real travelBias: 0.58 + (((index * 37) % 35) / 100)
                readonly property real travel: level * Math.max(0, crossExtent - size) * travelBias
                readonly property real size: Math.max(2,
                    Math.min(10, 2 + (level * crossExtent * 0.16)))

                x: root.vertical
                    ? (root.originEdge === Qt.RightEdge
                        ? particles.width - size - travel
                        : travel)
                    : Math.round((particles.width * flowPosition) - (size / 2))
                y: root.vertical
                    ? Math.round((particles.height * flowPosition) - (size / 2))
                    : (root.originEdge === Qt.BottomEdge
                        ? particles.height - size - travel
                        : travel)
                width: size
                height: size
                radius: size / 2
                color: root.resolvedColor(levelIndex, level)
                opacity: 0.12 + (level * 0.88)

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.45
                    height: width
                    radius: width / 2
                    color: Kirigami.Theme.backgroundColor
                    opacity: 0.42
                }
            }
        }
    }
}
