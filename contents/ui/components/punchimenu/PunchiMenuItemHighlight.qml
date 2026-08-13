import QtQuick
import org.kde.kirigami as Kirigami

// Shared lightweight highlight surface for PunchiMenu delegates.
Rectangle {
    id: root

    property bool hovered: false
    property bool selected: false
    property bool focused: false
    property bool pressed: false
    property bool circular: false
    property bool motionEnabled: true
    property string animationMode: "pulse"
    property bool transformSelf: true
    property real motionScale: 1.0

    readonly property real visualScale: motionEnabled ? motionScale : 1.0

    function stopScaleAnimations() {
        individualAnimation.stop()
        settleAnimation.stop()
        pulseAnimation.stop()
        bounceAnimation.stop()
    }

    function updateHoverAnimation() {
        stopScaleAnimations()
        if (!motionEnabled || animationMode === "none") {
            motionScale = 1.0
            return
        }
        if (!hovered) {
            settleAnimation.restart()
            return
        }
        if (animationMode === "individual") {
            individualAnimation.restart()
        } else if (animationMode === "bounce") {
            bounceAnimation.restart()
        } else {
            pulseAnimation.restart()
        }
    }

    color: selected || focused || hovered
        ? Qt.alpha(Kirigami.Theme.highlightColor, 0.20)
        : "transparent"
    border.color: focused || selected
        ? Kirigami.Theme.highlightColor
        : "transparent"
    border.width: focused || selected ? 2 : 0
    radius: circular ? height / 2 : Kirigami.Units.cornerRadius * 2
    scale: transformSelf
        ? (motionEnabled && pressed && animationMode !== "none"
            ? 0.97 : visualScale)
        : 1.0
    antialiasing: true
    Accessible.ignored: true

    onHoveredChanged: updateHoverAnimation()
    onAnimationModeChanged: updateHoverAnimation()
    onMotionEnabledChanged: updateHoverAnimation()

    Behavior on color {
        enabled: root.motionEnabled
        ColorAnimation {
            duration: Math.max(80,
                Math.min(140, Kirigami.Units.shortDuration))
        }
    }

    NumberAnimation {
        id: individualAnimation
        target: root
        property: "motionScale"
        to: 1.03
        duration: 130
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: settleAnimation
        target: root
        property: "motionScale"
        to: 1.0
        duration: 100
        easing.type: Easing.OutCubic
    }

    SequentialAnimation {
        id: pulseAnimation

        NumberAnimation {
            target: root
            property: "motionScale"
            to: 1.03
            duration: 95
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "motionScale"
            to: 1.0
            duration: 125
            easing.type: Easing.InOutCubic
        }
    }

    SequentialAnimation {
        id: bounceAnimation

        NumberAnimation {
            target: root
            property: "motionScale"
            to: 1.03
            duration: 80
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "motionScale"
            to: 0.985
            duration: 70
            easing.type: Easing.InOutCubic
        }

        NumberAnimation {
            target: root
            property: "motionScale"
            to: 1.012
            duration: 65
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "motionScale"
            to: 1.0
            duration: 80
            easing.type: Easing.OutCubic
        }
    }
}
