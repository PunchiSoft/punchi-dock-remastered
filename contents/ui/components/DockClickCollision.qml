import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    required property Item layoutItem
    property bool verticalPanel: false
    property int motionSpeedPercent: 100
    readonly property bool motionEnabled: Kirigami.Units.longDuration > 1
    readonly property int beat: Math.round(Kirigami.Units.shortDuration * 100
        / Math.max(50, Math.min(150, motionSpeedPercent)))
    readonly property bool running: impact.running || settling.running
    property Item originItem: null
    property Item positiveItem: null
    property Item negativeItem: null
    property real originOffset: 0
    property real positiveOffset: 0
    property real negativeOffset: 0
    property real positiveReach: 0
    property real negativeReach: 0
    property real reactionDistance: 0
    property bool resetting: false

    visible: false
    Accessible.ignored: true

    onEnabledChanged: if (!enabled) reset()
    onMotionEnabledChanged: if (!motionEnabled) reset()
    onVerticalPanelChanged: reset()
    onOriginItemChanged: if (!originItem && running && !resetting) cancel()
    onPositiveItemChanged: if (!positiveItem && running && !resetting) cancel()
    onNegativeItemChanged: if (!negativeItem && running && !resetting) cancel()

    function reset() {
        resetting = true
        impact.stop()
        settling.stop()
        originOffset = 0
        positiveOffset = 0
        negativeOffset = 0
        originItem = null
        positiveItem = null
        negativeItem = null
        resetting = false
    }

    function cancel() {
        if (!running || resetting || settling.running) return
        resetting = true
        impact.stop()
        settling.start()
        resetting = false
    }

    function cancelFor(item) {
        if (item === originItem || item === positiveItem || item === negativeItem) {
            cancel()
        }
    }

    function reach(item, neighbor) {
        const minimum = item.iconSize * 0.16
        if (!neighbor) return minimum
        const a = item.collisionVisualBounds()
        const b = neighbor.collisionVisualBounds()
        const gap = verticalPanel
            ? Math.max(b.y - a.y - a.height, a.y - b.y - b.height)
            : Math.max(b.x - a.x - a.width, a.x - b.x - b.width)
        // Read geometry once per activation, never scan delegates per frame.
        return Math.min(item.iconSize * 0.45,
            Math.max(minimum, gap + reactionDistance * 0.7))
    }

    function play(item) {
        if (!enabled || !motionEnabled || running || !layoutItem
                || !item || !item.clickCollisionEligible) return
        const center = item.mapToItem(layoutItem, item.width / 2, item.height / 2)
        const primary = verticalPanel ? center.y : center.x
        const bounds = item.mapToItem(layoutItem, Qt.rect(0, 0, item.width, item.height))
        const crossStart = verticalPanel ? bounds.x : bounds.y
        const crossEnd = crossStart + (verticalPanel ? bounds.width : bounds.height)
        let before = null
        let after = null
        let beforeDistance = Infinity
        let afterDistance = Infinity
        for (const child of layoutItem.children) {
            if (!(child instanceof DockItem) || child === item
                    || !child.visible || child.width <= 0 || child.height <= 0) continue
            const candidate = child as DockItem
            const position = candidate.mapToItem(layoutItem,
                candidate.width / 2, candidate.height / 2)
            const candidateBounds = candidate.mapToItem(layoutItem,
                Qt.rect(0, 0, candidate.width, candidate.height))
            const candidateStart = verticalPanel ? candidateBounds.x : candidateBounds.y
            const candidateEnd = candidateStart
                + (verticalPanel ? candidateBounds.width : candidateBounds.height)
            if (Math.min(crossEnd, candidateEnd) <= Math.max(crossStart, candidateStart)) continue
            const distance = (verticalPanel ? position.y : position.x) - primary
            if (distance > 0 && distance < afterDistance) {
                after = candidate
                afterDistance = distance
            } else if (distance < 0 && -distance < beforeDistance) {
                before = candidate
                beforeDistance = -distance
            }
        }
        // Structural or disabled neighbors form a boundary rather than being skipped.
        originItem = item
        positiveItem = after && after.clickCollisionEligible ? after : null
        negativeItem = before && before.clickCollisionEligible ? before : null
        reactionDistance = item.iconSize * 0.07
        positiveReach = reach(item, positiveItem)
        negativeReach = reach(item, negativeItem)
        impact.start()
    }

    Connections {
        target: root.layoutItem
        function onChildrenChanged() { root.cancel() }
    }
    Connections {
        target: root.originItem
        function onXChanged() { root.cancel() }
        function onYChanged() { root.cancel() }
        function onWidthChanged() { root.cancel() }
        function onHeightChanged() { root.cancel() }
        function onParentChanged() { root.cancel() }
    }
    Connections {
        target: root.positiveItem
        function onXChanged() { root.cancel() }
        function onYChanged() { root.cancel() }
        function onWidthChanged() { root.cancel() }
        function onHeightChanged() { root.cancel() }
        function onParentChanged() { root.cancel() }
    }
    Connections {
        target: root.negativeItem
        function onXChanged() { root.cancel() }
        function onYChanged() { root.cancel() }
        function onWidthChanged() { root.cancel() }
        function onHeightChanged() { root.cancel() }
        function onParentChanged() { root.cancel() }
    }

    ParallelAnimation {
        id: impact
        onStopped: if (!root.resetting) root.reset()
        SequentialAnimation {
            NumberAnimation {
                target: root; property: "originOffset"; to: root.positiveReach
                duration: Math.round(root.beat * 0.8); easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: root; property: "originOffset"; to: -root.negativeReach
                duration: Math.round(root.beat * 1.6); easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root; property: "originOffset"; to: 0
                duration: Math.round(root.beat * 1.2); easing.type: Easing.InOutQuad
            }
        }
        SequentialAnimation {
            PauseAnimation { duration: Math.round(root.beat * 0.6) }
            NumberAnimation {
                target: root; property: "positiveOffset"
                to: root.positiveItem ? root.reactionDistance : 0
                duration: Math.round(root.beat * 0.6); easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: root; property: "positiveOffset"; to: 0
                duration: Math.round(root.beat * 0.95); easing.type: Easing.InOutQuad
            }
        }
        SequentialAnimation {
            PauseAnimation { duration: Math.round(root.beat * 2) }
            NumberAnimation {
                target: root; property: "negativeOffset"
                to: root.negativeItem ? -root.reactionDistance : 0
                duration: Math.round(root.beat * 0.6); easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: root; property: "negativeOffset"; to: 0
                duration: root.beat; easing.type: Easing.InOutQuad
            }
        }
    }
    ParallelAnimation {
        id: settling
        onStopped: if (!root.resetting) root.reset()
        NumberAnimation {
            target: root; property: "originOffset"; to: 0
            duration: root.beat; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root; property: "positiveOffset"; to: 0
            duration: root.beat; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root; property: "negativeOffset"; to: 0
            duration: root.beat; easing.type: Easing.OutCubic
        }
    }
}
