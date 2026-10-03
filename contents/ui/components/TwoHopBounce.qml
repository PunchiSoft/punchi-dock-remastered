import QtQuick

Item {
    id: root

    required property int duration
    property bool secondaryHopEnabled: true
    property real progress: 0
    readonly property bool running: hops.running || settling.running

    visible: false
    Accessible.ignored: true

    function play() {
        if (running || duration <= 0) {
            return
        }
        hops.start()
    }

    function settle(interval) {
        hops.stop()
        settling.duration = Math.max(0, interval)
        settling.start()
    }

    function reset() {
        hops.stop()
        settling.stop()
        progress = 0
    }

    SequentialAnimation {
        id: hops
        NumberAnimation {
            target: root
            property: "progress"
            to: 1
            duration: Math.round(root.duration * 1.4)
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "progress"
            to: 0
            duration: Math.round(root.duration * 1.2)
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: root
            property: "progress"
            to: root.secondaryHopEnabled ? 0.8 : 0
            duration: root.secondaryHopEnabled ? Math.round(root.duration * 1.25) : 0
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "progress"
            to: 0
            duration: root.secondaryHopEnabled ? Math.round(root.duration * 1.15) : 0
            easing.type: Easing.InQuad
        }
    }

    NumberAnimation {
        id: settling
        target: root
        property: "progress"
        to: 0
        easing.type: Easing.OutCubic
    }
}
