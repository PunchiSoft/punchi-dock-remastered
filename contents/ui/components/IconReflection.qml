import QtQuick
import Qt5Compat.GraphicalEffects as GraphicalEffects
import org.kde.kirigami as Kirigami

Item {
    id: root

    property bool active: false
    property var iconSource: ""
    property real displaySize: 48
    property real horizontalOffset: 0
    property real sourceOverlapRatio: 0.08
    property real visibleRatio: 0.26

    readonly property real sourceOverlap: Math.max(1,
        displaySize * sourceOverlapRatio)
    readonly property real fadeMidpointRatio: sourceOverlapRatio
        + (visibleRatio * 0.46)
    readonly property real fadeEndRatio: Math.min(1,
        sourceOverlapRatio + visibleRatio)

    clip: true
    visible: active && width > 0 && height > 0

    Item {
        id: reflectionSource
        width: Math.max(1, root.displaySize)
        height: width
        visible: false

        Kirigami.Icon {
            anchors.fill: parent
            source: root.iconSource

            transform: Scale {
                origin.x: reflectionSource.width / 2
                origin.y: reflectionSource.height / 2
                yScale: -1
            }
        }
    }

    Item {
        id: fadeMask
        width: reflectionSource.width
        height: reflectionSource.height
        visible: false

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "white"
                }
                GradientStop {
                    position: root.sourceOverlapRatio
                    color: "white"
                }
                GradientStop {
                    position: root.fadeMidpointRatio
                    color: Qt.rgba(1, 1, 1, 0.46)
                }
                GradientStop {
                    position: root.fadeEndRatio
                    color: "transparent"
                }
                GradientStop {
                    position: 1
                    color: "transparent"
                }
            }
        }
    }

    GraphicalEffects.OpacityMask {
        width: reflectionSource.width
        height: reflectionSource.height
        x: Math.round((root.width - width) / 2 + root.horizontalOffset)
        y: 0
        source: reflectionSource
        maskSource: fadeMask
        cached: false
    }
}
