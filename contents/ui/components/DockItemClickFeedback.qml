import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property string effect: "none"
    property bool feedbackEnabled: true
    property bool pressed: false
    property bool motionEnabled: Kirigami.Units.longDuration > 1
    property int motionSpeedPercent: 100
    property int iconSize: 48
    property real direction: -1

    readonly property int duration: Math.round(Kirigami.Units.longDuration
        * 100 / Math.max(50, Math.min(150, motionSpeedPercent)))
    readonly property bool running: bounceAnimation.running
        || pulseAnimation.running || pressAnimation.running
    readonly property real visualScale: animationScale
    readonly property real horizontalOffset: 0
    readonly property real verticalOffset: bounceProgress * iconSize * 0.45 * direction
    readonly property real visualOpacity: feedbackEnabled && pressed && effect !== "none"
        ? 0.72 : 1.0
    property real animationScale: 1
    readonly property real bounceProgress: bounceAnimation.progress

    visible: false
    Accessible.ignored: true

    onEffectChanged: reset()
    onFeedbackEnabledChanged: if (!feedbackEnabled) reset()
    onMotionEnabledChanged: if (!motionEnabled) reset()
    onDirectionChanged: reset()

    function reset() {
        bounceAnimation.reset()
        pulseAnimation.stop()
        pressAnimation.stop()
        animationScale = 1
    }

    function play() {
        // Coalesce repeated feedback, while the caller still performs every action.
        if (!feedbackEnabled || !motionEnabled || running) {
            return
        }
        if (effect === "bounce") {
            bounceAnimation.play()
        } else if (effect === "pulse") {
            pulseAnimation.start()
        } else if (effect === "press") {
            pressAnimation.start()
        }
    }

    TwoHopBounce {
        id: bounceAnimation
        duration: root.duration
    }

    SequentialAnimation {
        id: pulseAnimation
        NumberAnimation {
            target: root
            property: "animationScale"
            to: 0.9
            duration: Math.round(root.duration * 0.275)
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "animationScale"
            to: 1
            duration: Math.round(root.duration * 0.7)
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: pressAnimation
        NumberAnimation {
            target: root
            property: "animationScale"
            to: 0.86
            duration: Math.round(root.duration * 0.3)
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "animationScale"
            to: 1
            duration: Math.round(root.duration * 0.475)
            easing.type: Easing.OutCubic
        }
    }
}
