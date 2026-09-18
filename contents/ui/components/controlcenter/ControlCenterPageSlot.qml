// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.kirigami as Kirigami

// Viewport for one Control Center page.
//
// The page change reuses the model of the revealable rows: a single progress
// value drives height, offset and opacity, so the outgoing page compresses and
// slides away while the incoming page expands over the space it releases. There
// is no timer: the transition is declarative, interruptible, retargetable and
// reduced-motion aware.
//
// The slot clips a plain container, not a layout, so every page assigned to it
// must fill that container explicitly (`anchors.fill: parent`). A page that does
// not fill it keeps its implicit size —zero for an unsized `FocusScope`— and
// disappears from the Control Center.
Item {
    id: root

    default property alias contentData: contentHost.data
    // True for the page the Control Center is currently showing.
    property bool current: false
    property bool motionEnabled: true
    // Height the page occupies once expanded. It comes from the container so
    // every page uses the same reference in both presentations.
    property real fullHeight: 0
    property real progress: current ? 1.0 : 0.0
    property int transitionDuration: motionEnabled
        ? Math.max(1, Math.round(Kirigami.Units.longDuration * 0.9)) : 1

    readonly property bool animationRunning: slotAnimation.running

    signal transitionFinished(bool current)

    visible: progress > 0.001
    // A page that is leaving must not accept focus or input while it shrinks.
    enabled: current
    clip: true
    height: Math.max(0, root.fullHeight * root.progress)
    opacity: root.progress
    // The incoming page sits above the outgoing one, so it lands over the space
    // the previous page is releasing instead of waiting for it to finish.
    z: root.current ? 1 : 0

    transform: Translate {
        y: (1.0 - root.progress) * Kirigami.Units.gridUnit
    }

    Behavior on progress {
        enabled: root.motionEnabled && root.transitionDuration > 0

        NumberAnimation {
            id: slotAnimation

            duration: root.transitionDuration
            easing.type: root.current ? Easing.OutCubic : Easing.InCubic
            onRunningChanged: {
                const target = root.current ? 1.0 : 0.0
                if (!running
                        && Math.abs(root.progress - target) < 0.001) {
                    root.transitionFinished(root.current)
                }
            }
        }
    }

    onCurrentChanged: {
        if (!motionEnabled) {
            Qt.callLater(function() {
                root.transitionFinished(root.current)
            })
        }
    }

    Item {
        id: contentHost

        // The page keeps its full height and the slot clips it, so the content
        // compresses visually without recalculating its inner layouts.
        width: root.width
        height: root.fullHeight
    }
}
