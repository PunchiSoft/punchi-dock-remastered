import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property string mode: "none"
    property int itemIndex: -1
    property int targetIndex: -1
    property int revision: 0
    property int iconSize: 48
    property bool verticalPanel: false
    property real bounceDirection: -1
    property bool reactionEnabled: true

    property real displacement: 0
    property bool ready: false

    readonly property int indexDistance: Math.abs(itemIndex - targetIndex)
    readonly property bool bounceAlongHorizontalAxis: verticalPanel
    readonly property real rippleDirection: itemIndex < targetIndex
        ? -1
        : 1
    readonly property real bounceAmplitude: Math.max(5, Math.round(iconSize * 0.18))
    readonly property real rippleAmplitude: Math.max(3,
        Math.round(iconSize * 0.15 * Math.max(0.32, 1 - (indexDistance * 0.34))))
    readonly property real horizontalOffset: mode === "slowBounce"
        ? (bounceAlongHorizontalAxis ? displacement * bounceDirection : 0)
        : (mode === "lateralRipple" && !verticalPanel
            ? displacement * rippleDirection
            : 0)
    readonly property real verticalOffset: mode === "slowBounce"
        ? (!bounceAlongHorizontalAxis ? displacement * bounceDirection : 0)
        : (mode === "lateralRipple" && verticalPanel
            ? displacement * rippleDirection
            : 0)

    visible: false

    Component.onCompleted: Qt.callLater(function() {
        root.ready = true
    })

    onRevisionChanged: startReaction()
    onModeChanged: stopReaction()

    Connections {
        target: Kirigami.Units

        function onLongDurationChanged() {
            if (Kirigami.Units.longDuration <= 0) {
                root.stopReaction()
            }
        }
    }

    SequentialAnimation {
        id: slowBounceAnimation

        NumberAnimation {
            target: root
            property: "displacement"
            to: root.bounceAmplitude
            duration: Math.round(Kirigami.Units.longDuration * 0.7)
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "displacement"
            to: -root.bounceAmplitude * 0.24
            duration: Math.round(Kirigami.Units.longDuration * 0.85)
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: root
            property: "displacement"
            to: 0
            duration: Math.round(Kirigami.Units.longDuration * 0.75)
            easing.type: Easing.OutBack
        }
    }

    SequentialAnimation {
        id: lateralRippleAnimation

        PauseAnimation {
            duration: Math.round(root.indexDistance * Kirigami.Units.shortDuration * 0.45)
        }
        NumberAnimation {
            target: root
            property: "displacement"
            to: root.rippleAmplitude
            duration: Math.round(Kirigami.Units.shortDuration * 0.75)
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "displacement"
            to: -root.rippleAmplitude * 0.45
            duration: Kirigami.Units.shortDuration
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: root
            property: "displacement"
            to: 0
            duration: Kirigami.Units.longDuration
            easing.type: Easing.OutBack
        }
    }

    function stopReaction() {
        slowBounceAnimation.stop()
        lateralRippleAnimation.stop()
        displacement = 0
    }

    function startReaction() {
        stopReaction()
        if (!ready || !reactionEnabled || mode === "none"
                || itemIndex < 0 || targetIndex < 0
                || Kirigami.Units.longDuration <= 0) {
            return
        }

        if (mode === "slowBounce" && indexDistance === 0) {
            slowBounceAnimation.restart()
        } else if (mode === "lateralRipple" && indexDistance <= 2) {
            lateralRippleAnimation.restart()
        }
    }
}
