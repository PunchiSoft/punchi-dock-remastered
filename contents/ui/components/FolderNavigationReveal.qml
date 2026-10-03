// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root
    property bool expanded: false
    property bool motionEnabled: true
    property real progress: 0

    // Distinct instant states cancel an in-flight transition and commit its
    // destination immediately when the user's animation preference changes.
    state: expanded
        ? (motionEnabled ? "expanded" : "expandedInstant")
        : (motionEnabled ? "collapsed" : "collapsedInstant")
    states: [
        State {
            name: "expanded"
            PropertyChanges { root.progress: 1 }
        },
        State {
            name: "collapsed"
            PropertyChanges { root.progress: 0 }
        },
        State { name: "expandedInstant"; extend: "expanded" },
        State { name: "collapsedInstant"; extend: "collapsed" }
    ]
    transitions: Transition {
        to: "expanded,collapsed"
        // Match the Wi-Fi section's timing, without an independent animation
        // for the close control or either list.
        NumberAnimation {
            target: root
            property: "progress"
            duration: Math.round(Kirigami.Units.longDuration * 0.9)
            easing.type: root.expanded ? Easing.OutCubic : Easing.InCubic
        }
    }
}
