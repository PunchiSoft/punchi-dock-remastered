pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
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
    property bool spatialBounceEnabled: false
    property real openingProgress: 0
    property bool openingPending: false
    property bool closing: false
    property bool progressResetActive: false

    readonly property Item contentItem: animatedSurface.children.length > 0
        ? animatedSurface.children[0]
        : null
    readonly property real intensityFactor: Math.max(10,
        Math.min(200, animationIntensityPercent)) / 100
    readonly property int animationDuration: Kirigami.Units.longDuration > 1
        ? Math.round(Kirigami.Units.longDuration * 100
            / Math.max(10, Math.min(200, animationSpeedPercent)))
        : 0
    readonly property bool spatialBounceActive: spatialBounceEnabled
        && animationStyle === "bounce" && animationDuration > 0
    readonly property real bounceDistance: spatialBounceActive
        ? Math.round(Kirigami.Units.gridUnit * intensityFactor) : 0
    readonly property real bounceHorizontalMargin: spatialBounceActive
        && (popupDirection === Qt.LeftEdge || popupDirection === Qt.RightEdge)
        ? bounceDistance : 0
    readonly property real bounceVerticalMargin: spatialBounceActive
        && (popupDirection === Qt.TopEdge || popupDirection === Qt.BottomEdge)
        ? bounceDistance : 0
    // Exits run on a shorter budget than entries, as the shared motion doctrine
    // requires. The factor scales the same theme-derived duration, so the user
    // animation speed preference keeps governing both directions.
    readonly property real closingDurationFactor: 0.65
    readonly property int effectiveAnimationDuration: root.closing
        ? Math.round(root.animationDuration * root.closingDurationFactor)
        : root.animationDuration
    readonly property real slideDistance: Math.round(Kirigami.Units.gridUnit * root.intensityFactor)
    readonly property real initialOpacity: Math.max(0, 1 - (0.95 * root.intensityFactor))
    readonly property real safeImplicitWidth: Number.isFinite(root.implicitWidth)
        ? Math.max(1, root.implicitWidth)
        : 1
    readonly property real safeImplicitHeight: Number.isFinite(root.implicitHeight)
        ? Math.max(1, root.implicitHeight)
        : 1
    // Geometry inputs for surfaces that map a blur mask to window-client
    // coordinates. mapToItem() does not invalidate a binding when an ancestor
    // transform changes, so the mask origin reads these values explicitly and
    // follows the reveal animation until it settles.
    readonly property Item transformSurfaceItem: animatedSurface
    readonly property real contentTranslationX: slideX
    readonly property real contentTranslationY: slideY

    signal closeAnimationFinished()
    readonly property real slideX: {
        if (spatialBounceActive) {
            return bounceHorizontalMargin * spatialBounce.progress
                * (popupDirection === Qt.LeftEdge ? -1 : 1)
        }
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
        if (spatialBounceActive) {
            return bounceVerticalMargin * spatialBounce.progress
                * (popupDirection === Qt.TopEdge ? -1 : 1)
        }
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

    implicitWidth: (contentItem ? contentItem.implicitWidth : 0) + bounceHorizontalMargin
    implicitHeight: (contentItem ? contentItem.implicitHeight : 0) + bounceVerticalMargin
    // PlasmaQuick::Dialog asserts on a zero-sized mainItem before it can map
    // the window. Keep the real geometry valid while guarded dialogs wait for
    // their content's implicit geometry to become ready.
    width: root.safeImplicitWidth
    height: root.safeImplicitHeight
    Layout.minimumWidth: implicitWidth
    Layout.maximumWidth: implicitWidth
    Layout.minimumHeight: implicitHeight
    Layout.maximumHeight: implicitHeight

    function beginOpening() {
        if (!popupVisible || !openingPending) {
            return
        }

        openingPending = false
        openingFallback.stop()
        openingProgress = 1
        if (spatialBounceActive) {
            spatialBounce.play()
        }
    }

    function finishClosing() {
        if (!closing || openingProgress > 0.001 || spatialBounce.running) {
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
        if (spatialBounceActive) {
            spatialBounce.settle(effectiveAnimationDuration)
        }
        if (animationStyle === "none" || animationDuration <= 0
                || openingProgress <= 0.001) {
            spatialBounce.reset()
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
        spatialBounce.reset()

        if (!popupVisible) {
            resetOpeningProgress(0)
            return
        }

        if (animationStyle === "none" || animationDuration <= 0) {
            resetOpeningProgress(1)
            return
        }

        // Present the initial state once before starting, otherwise complex popup
        // contents can consume the complete animation while their window maps.
        resetOpeningProgress(0)
        openingPending = true
        openingFallback.restart()
    }

    function resetOpeningProgress(value) {
        progressResetActive = true
        openingProgress = value
        progressResetActive = false
    }

    onPopupVisibleChanged: scheduleOpening()
    onAnimationStyleChanged: {
        if (popupVisible && !closing) {
            scheduleOpening()
        }
    }
    onSpatialBounceActiveChanged: {
        if (!spatialBounceActive) {
            spatialBounce.reset()
        }
    }
    onAnimationDurationChanged: {
        if (animationDuration <= 0 && popupVisible) {
            openingFallback.stop()
            openingPending = false
            spatialBounce.reset()
            resetOpeningProgress(closing ? 0 : 1)
            if (closing) {
                Qt.callLater(root.finishClosing)
            }
        }
    }
    Component.onCompleted: scheduleOpening()

    readonly property TwoHopBounce bounceMotion: TwoHopBounce {
        id: spatialBounce
        // A popup uses one hop within the surface's opening budget.
        secondaryHopEnabled: false
        duration: Math.round(root.animationDuration * 0.4)
        onRunningChanged: {
            if (!running && root.closing) {
                root.finishClosing()
            }
        }
    }

    Behavior on openingProgress {
        enabled: !root.progressResetActive && root.popupVisible
            && root.animationStyle !== "none"

        NumberAnimation {
            id: revealAnimation
            duration: root.effectiveAnimationDuration
            easing.type: root.closing
                ? Easing.InCubic
                : (root.animationStyle === "bounce" && !root.spatialBounceActive
                    ? Easing.OutBack
                    : Easing.OutCubic)
            easing.overshoot: root.animationStyle === "bounce"
                ? 1 + (0.45 * root.intensityFactor)
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
        // popupDirection is the growth direction, opposite to the dock edge.
        x: root.popupDirection === Qt.LeftEdge ? root.bounceHorizontalMargin : 0
        y: root.popupDirection === Qt.TopEdge ? root.bounceVerticalMargin : 0
        width: root.width - root.bounceHorizontalMargin
        height: root.height - root.bounceVerticalMargin
        transformOrigin: {
            if (root.popupDirection === Qt.BottomEdge) {
                return Item.Bottom
            }
            if (root.popupDirection === Qt.TopEdge) {
                return Item.Top
            }
            if (root.popupDirection === Qt.LeftEdge) {
                return Item.Left
            }
            if (root.popupDirection === Qt.RightEdge) {
                return Item.Right
            }
            return Item.Center
        }
        opacity: root.animationStyle === "none"
            ? 1
            : Math.min(1, root.initialOpacity
                + (root.openingProgress * (1 - root.initialOpacity)))
        scale: root.animationStyle === "scale"
            ? 1 - (0.16 * root.intensityFactor * (1 - root.openingProgress))
            : root.animationStyle === "bounce" && !root.spatialBounceActive
                ? 1 - (0.22 * root.intensityFactor * (1 - root.openingProgress))
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
