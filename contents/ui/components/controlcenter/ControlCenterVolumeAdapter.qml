// SPDX-License-Identifier: GPL-2.0-or-later

import QtQml
import org.kde.plasma.private.volume as PlasmaVolume

QtObject {
    id: root

    // plasma-pa exports these runtime types, but its installed qmltypes omits
    // them. Keep the suppression limited to the two affected expressions.
    // qmllint disable unresolved-type missing-property
    readonly property var sink: PlasmaVolume.PreferredDevice.sink
    readonly property real normalVolume: PlasmaVolume.PulseAudio.NormalVolume
    // qmllint enable unresolved-type missing-property
    readonly property bool available: sink !== null && normalVolume > 0
    readonly property bool muted: available ? Boolean(sink.muted) : false
    readonly property int value: available
        ? Math.max(0, Math.min(100,
            Math.round(Number(sink.volume) / normalVolume * 100.0)))
        : 0

    function setValue(percentage) {
        if (!available) {
            return false
        }
        const boundedValue = Math.max(0, Math.min(100,
            Math.round(Number(percentage))))
        sink.volume = Math.round(normalVolume * boundedValue / 100.0)
        sink.muted = boundedValue === 0
        return true
    }

    function toggleMuted() {
        if (!available) {
            return false
        }
        sink.muted = !sink.muted
        return true
    }
}
