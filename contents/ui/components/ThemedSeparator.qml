pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property var theme: ({})
    property real availableLength: 0
    property real renderedThickness: Number(theme.thickness || 2)
    property real maximumGlowSize: -1

    readonly property string separatorStyle: String(theme.style || "line")
    readonly property real separatorThickness: Math.max(1, renderedThickness)
    readonly property real separatorLength: separatorStyle === "dot"
        ? separatorThickness
        : Math.max(separatorThickness,
            Math.round(availableLength * Number(theme.lengthRatio || 0.72)))
    readonly property real separatorRadius: separatorStyle === "dot"
        ? separatorThickness / 2
        : Math.min(separatorThickness / 2, Number(theme.radius || 0))
    readonly property var gradientData: theme.gradient || ({})
    readonly property var gradientStops: gradientData.stops || []
    readonly property var borderData: theme.border || ({})
    readonly property var glowData: theme.glow || ({})
    readonly property real glowSize: maximumGlowSize >= 0
        ? Math.min(Number(glowData.size || 0), maximumGlowSize)
        : Number(glowData.size || 0)
    readonly property color glowColor: glowData.color || "transparent"
    readonly property real horizontalGlowExtent: Math.min(glowSize,
        Math.max(2, separatorThickness * 1.5))
    readonly property var patternData: theme.pattern || ({})
    readonly property string patternStyle: String(patternData.style || "none")
    readonly property color patternPrimaryColor: patternData.primaryColor || "white"
    readonly property color patternSecondaryColor: patternData.secondaryColor || "transparent"
    readonly property real patternSegmentSize: Number(patternData.segmentSize || 4)
    readonly property real patternGapSize: Number(patternData.gapSize || 4)
    readonly property real patternThickness: Number(patternData.thickness || 2)

    implicitWidth: separatorThickness
    implicitHeight: separatorLength
    opacity: Number(theme.opacity === undefined ? 1 : theme.opacity)

    function gradientStop(index) {
        if (gradientStops.length === 0) {
            return {
                "position": index === 0 ? 0 : 1,
                "color": theme.color || "transparent"
            }
        }
        return gradientStops[Math.min(index, gradientStops.length - 1)]
    }

    Rectangle {
        visible: root.glowSize > 0
        x: -root.horizontalGlowExtent
        y: -root.glowSize
        width: root.width + (root.horizontalGlowExtent * 2)
        height: root.height + (root.glowSize * 2)
        radius: Math.min(width / 2,
            root.separatorRadius + root.horizontalGlowExtent)
        color: root.glowColor
        opacity: 0.1
        antialiasing: true
    }

    Rectangle {
        readonly property real horizontalExtent:
            root.horizontalGlowExtent * 0.66
        readonly property real verticalExtent: root.glowSize * 0.66

        visible: root.glowSize > 0
        x: -horizontalExtent
        y: -verticalExtent
        width: root.width + (horizontalExtent * 2)
        height: root.height + (verticalExtent * 2)
        radius: Math.min(width / 2,
            root.separatorRadius + horizontalExtent)
        color: root.glowColor
        opacity: 0.14
        antialiasing: true
    }

    Rectangle {
        readonly property real horizontalExtent:
            root.horizontalGlowExtent * 0.33
        readonly property real verticalExtent: root.glowSize * 0.33

        visible: root.glowSize > 0
        x: -horizontalExtent
        y: -verticalExtent
        width: root.width + (horizontalExtent * 2)
        height: root.height + (verticalExtent * 2)
        radius: Math.min(width / 2,
            root.separatorRadius + horizontalExtent)
        color: root.glowColor
        opacity: 0.18
        antialiasing: true
    }

    Item {
        id: separatorSurface
        anchors.fill: parent

        Rectangle {
            id: separatorFill
            anchors.fill: parent
            color: root.theme.color || "transparent"
            radius: root.separatorRadius
            antialiasing: true
            clip: true

            gradient: Gradient {
                orientation: String(root.gradientData.direction || "vertical") === "horizontal"
                    ? Gradient.Horizontal
                    : Gradient.Vertical

                GradientStop {
                    position: Number(root.gradientStop(0).position)
                    color: root.gradientStop(0).color
                }
                GradientStop {
                    position: Number(root.gradientStop(1).position)
                    color: root.gradientStop(1).color
                }
                GradientStop {
                    position: Number(root.gradientStop(2).position)
                    color: root.gradientStop(2).color
                }
                GradientStop {
                    position: Number(root.gradientStop(3).position)
                    color: root.gradientStop(3).color
                }
                GradientStop {
                    position: Number(root.gradientStop(4).position)
                    color: root.gradientStop(4).color
                }
                GradientStop {
                    position: Number(root.gradientStop(5).position)
                    color: root.gradientStop(5).color
                }
                GradientStop {
                    position: Number(root.gradientStop(6).position)
                    color: root.gradientStop(6).color
                }
                GradientStop {
                    position: Number(root.gradientStop(7).position)
                    color: root.gradientStop(7).color
                }
            }

            Rectangle {
                anchors.fill: parent
                visible: root.patternStyle === "hazard"
                color: root.patternSecondaryColor
            }

            Item {
                anchors.fill: parent
                visible: root.patternStyle === "hazard"
                clip: true

                Repeater {
                    model: Math.ceil((separatorFill.height + separatorFill.width)
                        / Math.max(1, root.patternSegmentSize + root.patternGapSize)) + 3

                    Rectangle {
                        required property int index
                        width: separatorFill.width * 2.5
                        height: root.patternSegmentSize
                        x: -separatorFill.width * 0.75
                        y: (index - 1) * (root.patternSegmentSize + root.patternGapSize)
                        color: root.patternPrimaryColor
                        rotation: -45
                        antialiasing: true
                    }
                }
            }

            Item {
                anchors.fill: parent
                visible: root.patternStyle === "dashed"
                clip: true

                Repeater {
                    model: Math.ceil(separatorFill.height
                        / Math.max(1, root.patternSegmentSize + root.patternGapSize))

                    Rectangle {
                        required property int index
                        width: separatorFill.width
                        height: root.patternSegmentSize
                        x: 0
                        y: index * (root.patternSegmentSize + root.patternGapSize)
                        color: root.patternPrimaryColor
                    }
                }
            }

            Rectangle {
                visible: root.patternStyle === "centerLine"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: Math.round(parent.height * 0.2)
                anchors.bottomMargin: Math.round(parent.height * 0.2)
                width: Math.min(parent.width, root.patternThickness)
                radius: width / 2
                color: root.patternPrimaryColor

                gradient: Gradient {
                    orientation: Gradient.Vertical

                    GradientStop {
                        position: 0
                        color: Qt.rgba(root.patternPrimaryColor.r,
                            root.patternPrimaryColor.g,
                            root.patternPrimaryColor.b, 0)
                    }
                    GradientStop {
                        position: 0.5
                        color: root.patternPrimaryColor
                    }
                    GradientStop {
                        position: 1
                        color: Qt.rgba(root.patternPrimaryColor.r,
                            root.patternPrimaryColor.g,
                            root.patternPrimaryColor.b, 0)
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: root.separatorRadius
            antialiasing: true
            border.width: Number(root.borderData.width || 0)
            border.color: root.borderData.color || "transparent"
        }
    }
}
