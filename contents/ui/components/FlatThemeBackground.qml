import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property var theme: ({})

    readonly property var surface: theme && theme.surface ? theme.surface : ({})
    readonly property var gradientData: surface.gradient ? surface.gradient : ({})
    readonly property var gradientStops: gradientData.stops ? gradientData.stops : []
    readonly property var borderData: surface.border ? surface.border : ({})
    readonly property var shadowData: theme && theme.shadow ? theme.shadow : ({})
    readonly property color surfaceColor: surface.color || "transparent"
    readonly property real surfaceRadius: Number(surface.radius || 0)
    readonly property string gradientDirection: String(gradientData.direction || "vertical")
    readonly property real shadowSize: Number(shadowData.size || 0)
    readonly property real shadowXOffset: Number(shadowData.xOffset || 0)
    readonly property real shadowYOffset: Number(shadowData.yOffset || 0)

    function gradientStop(index) {
        if (gradientStops.length === 0) {
            return {
                "position": index === 0 ? 0 : 1,
                "color": surfaceColor
            }
        }
        return gradientStops[Math.min(index, gradientStops.length - 1)]
    }

    Kirigami.ShadowedRectangle {
        anchors {
            fill: parent
            leftMargin: root.shadowSize + Math.max(0, -root.shadowXOffset)
            rightMargin: root.shadowSize + Math.max(0, root.shadowXOffset)
            topMargin: root.shadowSize + Math.max(0, -root.shadowYOffset)
            bottomMargin: root.shadowSize + Math.max(0, root.shadowYOffset)
        }
        color: root.surfaceColor
        radius: root.surfaceRadius
        shadow.size: root.shadowSize
        shadow.xOffset: root.shadowXOffset
        shadow.yOffset: root.shadowYOffset
        shadow.color: root.shadowData.color || "transparent"

        Rectangle {
            anchors.fill: parent
            color: root.surfaceColor
            radius: root.surfaceRadius
            antialiasing: true
            border.width: Number(root.borderData.width || 0)
            border.color: root.borderData.color || "transparent"

            gradient: Gradient {
                orientation: root.gradientDirection === "horizontal"
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
        }
    }
}
