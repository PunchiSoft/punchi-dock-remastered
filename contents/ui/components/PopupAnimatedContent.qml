pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami

Item {
    id: root

    default property alias contentData: animatedSurface.data
    property bool popupVisible: false
    property string animationStyle: "scale"
    property int animationSpeedPercent: 100
    property int animationIntensityPercent: 100
    property int popupDirection: Qt.BottomEdge
    property real openingProgress: 0
    property bool openingPending: false
    property bool closing: false

    readonly property Item contentItem: animatedSurface.children.length > 0
        ? animatedSurface.children[0]
        : null
    readonly property real intensityFactor: Math.max(10,
        Math.min(200, animationIntensityPercent)) / 100
    readonly property int animationDuration: Kirigami.Units.longDuration > 1
        ? Math.round(Kirigami.Units.longDuration * 100
            / Math.max(10, Math.min(200, animationSpeedPercent)))
        : 0
    readonly property real slideDistance: Kirigami.Units.smallSpacing * 2
        * intensityFactor
    readonly property real initialOpacity: Math.max(0, 1 - (0.72 * intensityFactor))

    signal closeAnimationFinished()
    readonly property real slideX: {
        if (animationStyle !== "slide") {
            return 0
        }
        if (popupDirection === Qt.RightEdge) {
            return -slideDistance * (1 - openingProgress)
        }
        if (popupDirection === Qt.LeftEdge) {
            return slideDistance * (1 - openingProgress)
        }
        return 0
    }
    readonly property real slideY: {
        if (animationStyle !== "slide") {
            return 0
        }
        if (popupDirection === Qt.BottomEdge) {
            return -slideDistance * (1 - openingProgress)
        }
        if (popupDirection === Qt.TopEdge) {
            return slideDistance * (1 - openingProgress)
        }
        return 0
    }

    implicitWidth: contentItem ? contentItem.implicitWidth : 0
    implicitHeight: contentItem ? contentItem.implicitHeight : 0
    width: implicitWidth
    height: implicitHeight

    function beginOpening() {
        if (!popupVisible || !openingPending) {
            return
        }

        openingPending = false
        openingFallback.stop()
        openingProgress = 1
    }

    function finishClosing() {
        if (!closing) {
            return
        }
        closeAnimationFinished()
        closing = false
    }

    function beginClosing() {
        if (!popupVisible || closing) {
            return
        }
        openingFallback.stop()
        openingPending = false
        closing = true
        if (animationStyle === "none" || animationDuration <= 0
                || openingProgress <= 0.001) {
            openingProgress = 0
            Qt.callLater(function() {
                root.finishClosing()
            })
            return
        }
        openingProgress = 0
    }

    function cancelClosing() {
        if (!closing) {
            return
        }
        closing = false
        if (popupVisible) {
            openingProgress = 1
        }
    }

    function scheduleOpening() {
        openingFallback.stop()
        openingPending = false
        closing = false

        if (!popupVisible) {
            openingProgress = 0
            return
        }

        if (animationStyle === "none" || animationDuration <= 0) {
            openingProgress = 1
            return
        }

        // Present the initial state once before starting, otherwise complex popup
        // contents can consume the complete animation while their window maps.
        openingProgress = 0
        openingPending = true
        openingFallback.restart()
    }

    onPopupVisibleChanged: scheduleOpening()
    onAnimationStyleChanged: {
        if (popupVisible && !closing) {
            scheduleOpening()
        }
    }
    Component.onCompleted: scheduleOpening()

    Behavior on openingProgress {
        enabled: root.popupVisible && root.animationStyle !== "none"

        NumberAnimation {
            duration: root.animationDuration
            easing.type: root.closing
                ? Easing.InCubic
                : (root.animationStyle === "bounce"
                    ? Easing.OutBack
                    : Easing.OutCubic)
            easing.overshoot: root.animationStyle === "bounce"
                ? 1 + (1.2 * root.intensityFactor)
                : 1.70158
            onRunningChanged: {
                if (!running && root.closing && root.openingProgress <= 0.001) {
                    root.finishClosing()
                }
            }
        }
    }

    Connections {
        target: root.Window.window
        enabled: root.openingPending

        function onFrameSwapped() {
            root.beginOpening()
        }
    }

    Timer {
        id: openingFallback
        interval: Math.max(80, Kirigami.Units.shortDuration)
        repeat: false
        onTriggered: root.beginOpening()
    }

    Item {
        id: animatedSurface
        anchors.fill: parent
        opacity: root.animationStyle === "none"
            ? 1
            : Math.min(1, root.initialOpacity
                + (root.openingProgress * (1 - root.initialOpacity)))
        scale: root.animationStyle === "scale"
            ? 1 - (0.04 * root.intensityFactor * (1 - root.openingProgress))
            : root.animationStyle === "bounce"
                ? 1 - (0.06 * root.intensityFactor * (1 - root.openingProgress))
                : 1
        transform: Translate {
            x: root.slideX
            y: root.slideY
        }
    }

    Binding {
        target: root.contentItem
        property: "width"
        value: animatedSurface.width
        when: root.contentItem !== null
    }

    Binding {
        target: root.contentItem
        property: "height"
        value: animatedSurface.height
        when: root.contentItem !== null
    }
}
