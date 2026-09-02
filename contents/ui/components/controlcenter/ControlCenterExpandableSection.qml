// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    default property alias contentData: contentHost.data
    property bool expanded: false
    property bool motionEnabled: true
    property real expandedHeight: 0
    property real expansionProgress: expanded ? 1.0 : 0.0
    property int transitionDuration: motionEnabled
        ? Math.max(1, Math.round(Kirigami.Units.longDuration * 0.9)) : 1
    readonly property bool animationRunning: expansionAnimation.running
    readonly property real contentOffset:
        (1.0 - expansionProgress) * Kirigami.Units.gridUnit

    signal transitionFinished(bool expanded)

    visible: expanded || expansionProgress > 0.001
    clip: true
    opacity: expansionProgress
    Layout.minimumHeight: 0
    Layout.preferredHeight: Math.max(0,
        root.expandedHeight * root.expansionProgress)
    Layout.maximumHeight: Layout.preferredHeight

    transform: Translate {
        y: root.contentOffset
    }

    Behavior on expansionProgress {
        enabled: root.motionEnabled && root.transitionDuration > 0

        NumberAnimation {
            id: expansionAnimation

            duration: root.transitionDuration
            easing.type: root.expanded ? Easing.OutCubic : Easing.InCubic
            onRunningChanged: {
                const target = root.expanded ? 1.0 : 0.0
                if (!running
                        && Math.abs(root.expansionProgress - target) < 0.001) {
                    root.transitionFinished(root.expanded)
                }
            }
        }
    }

    onExpandedChanged: {
        if (!motionEnabled) {
            Qt.callLater(function() {
                root.transitionFinished(root.expanded)
            })
        }
    }

    Item {
        id: contentHost
        anchors.fill: parent
    }
}
