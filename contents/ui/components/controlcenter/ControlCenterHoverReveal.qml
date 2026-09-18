// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.kirigami as Kirigami

// Reveal policy for one extra Control Center row.
//
// The transition itself belongs to ControlCenterExpandableSection: it is
// declarative, interruptible and reduced-motion aware. This component only owns
// the input policy, that is, when the pointer or the keyboard asks for the row
// and how long it stays open after the pointer leaves it so it can be reached.
//
// The row is never revealed by hover alone: the trigger button also has to be
// reachable by keyboard focus, otherwise the extra control would be
// unreachable without a pointer.
ControlCenterExpandableSection {
    id: root

    // The pointer is over the trigger button or the keyboard focus is on it.
    property bool revealRequested: false
    // The revealed row is being pointed at or used: pressed slider, focused
    // slider or focused action button. While true the row never collapses.
    property bool interacting: false
    // The revealed control can be used at all. When false the row never opens
    // and collapses immediately.
    property bool usable: true
    // Grace period that lets the pointer travel from the trigger to the row.
    property int collapseDelay: Kirigami.Units.shortDuration

    readonly property bool holdOpen: usable
        && (revealRequested || interacting)
    readonly property bool revealed: expanded

    expanded: holdOpen || collapseTimer.running

    onHoldOpenChanged: {
        if (holdOpen) {
            collapseTimer.stop()
        } else if (usable) {
            collapseTimer.restart()
        }
    }
    onUsableChanged: {
        if (!usable) {
            collapseTimer.stop()
        }
    }

    // Input-intent debounce, not an animation driver: the transition stays
    // declarative inside ControlCenterExpandableSection.
    Timer {
        id: collapseTimer

        interval: Math.max(0, root.collapseDelay)
    }
}
