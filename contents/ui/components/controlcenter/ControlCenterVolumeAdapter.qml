// SPDX-License-Identifier: GPL-2.0-or-later

import QtQml
import org.kde.plasma.private.volume as PlasmaVolume

QtObject {
    id: root

    property bool showVirtualDevices: false

    // plasma-pa exports these runtime types, but its installed qmltypes omits
    // them. Keep all private API use isolated in this deferred adapter.
    // qmllint disable unresolved-type missing-property import
    readonly property var sink: PlasmaVolume.PreferredDevice.sink
    readonly property real normalVolume: PlasmaVolume.PulseAudio.NormalVolume
    readonly property real maximalVolume:
        PlasmaVolume.PulseAudio.MaximalVolume

    readonly property var sinkModel: PlasmaVolume.SinkModel {}
    readonly property var sourceModel: PlasmaVolume.SourceModel {}
    readonly property var sinkInputModel: PlasmaVolume.SinkInputModel {}
    readonly property var sourceOutputModel: PlasmaVolume.SourceOutputModel {}
    readonly property var cardModel: PlasmaVolume.CardModel {}

    readonly property var outputDevicesModel:
        PlasmaVolume.PulseObjectFilterModel {
            sourceModel: root.sinkModel
            filterOutInactiveDevices: true
            filterVirtualDevices: !root.showVirtualDevices
        }
    readonly property var inputDevicesModel:
        PlasmaVolume.PulseObjectFilterModel {
            sourceModel: root.sourceModel
            filterOutInactiveDevices: true
            filterVirtualDevices: !root.showVirtualDevices
        }
    readonly property var playbackStreamsModel:
        PlasmaVolume.PulseObjectFilterModel {
            sourceModel: root.sinkInputModel
            filters: [
                { role: "VirtualStream", value: false },
                {
                    role: "Client",
                    value: function(client) {
                        return !client || client.name !== "libcanberra"
                    }
                }
            ]
        }
    readonly property var recordingStreamsModel:
        PlasmaVolume.PulseObjectFilterModel {
            sourceModel: root.sourceOutputModel
            filters: [
                { role: "VirtualStream", value: false }
            ]
        }

    readonly property var globalConfig: PlasmaVolume.GlobalConfig {}
    readonly property var itemMenu: PlasmaVolume.ListItemMenu {}
    readonly property int sinkItemType: PlasmaVolume.ListItemMenu.Sink
    readonly property int sinkInputItemType:
        PlasmaVolume.ListItemMenu.SinkInput
    readonly property int sourceItemType: PlasmaVolume.ListItemMenu.Source
    readonly property int sourceOutputItemType:
        PlasmaVolume.ListItemMenu.SourceOutput
    // qmllint enable unresolved-type missing-property import

    readonly property bool available: sink !== null && normalVolume > 0
    readonly property bool muted: available ? Boolean(sink.muted) : false
    readonly property int value: available
        ? Math.max(0, Math.min(100,
            Math.round(Number(sink.volume) / normalVolume * 100.0)))
        : 0
    readonly property string deviceDescription: sink && sink.description
        ? String(sink.description) : ""
    readonly property string speakerVolumeIconName: {
        if (value > 66) {
            return "audio-volume-high"
        }
        if (value > 33) {
            return "audio-volume-medium"
        }
        if (value > 0) {
            return "audio-volume-low"
        }
        return "audio-volume-muted"
    }

    readonly property string rawDeviceIconName: {
        if (!available || !sink) {
            return speakerVolumeIconName
        }
        if (sink.formFactor) {
            const form = String(sink.formFactor).toLowerCase()
            if (form.indexOf("headphone") !== -1 || form.indexOf("headset") !== -1) {
                return "audio-headphones"
            }
            if (form.indexOf("tv") !== -1 || form.indexOf("display") !== -1) {
                return "video-television"
            }
        }
        if (sink.icon && String(sink.icon).length > 0) {
            const iconStr = String(sink.icon)
            if (iconStr !== "audio-speakers" && iconStr !== "audio-volume-high") {
                return iconStr
            }
        }
        if (sink.iconName && String(sink.iconName).length > 0) {
            const iconNameStr = String(sink.iconName)
            if (iconNameStr !== "audio-speakers" && iconNameStr !== "audio-volume-high") {
                return iconNameStr
            }
        }
        return speakerVolumeIconName
    }
    readonly property string deviceIconName: available
        ? (muted || value === 0 ? "audio-volume-muted" : rawDeviceIconName)
        : "audio-volume-muted"
    readonly property bool raiseMaximumVolume:
        Boolean(globalConfig.raiseMaximumVolume)
    readonly property bool raiseMaximumVolumeWritable:
        !Boolean(globalConfig.isRaiseMaximumVolumeImmutable)
    readonly property bool globalMuteSinks:
        Boolean(globalConfig.globalMuteSinks)
    readonly property bool globalMuteSources:
        Boolean(globalConfig.globalMuteSources)
    readonly property int maximumPercentage: raiseMaximumVolume
        && normalVolume > 0
        ? Math.max(100, Math.round(maximalVolume / normalVolume * 100.0))
        : 100

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

    function percentageFor(audioObject) {
        if (!audioObject || normalVolume <= 0) {
            return 0
        }
        return Math.max(0, Math.min(maximumPercentage,
            Math.round(Number(audioObject.volume) / normalVolume * 100.0)))
    }

    function setObjectValue(audioObject, percentage) {
        if (!audioObject || normalVolume <= 0) {
            return false
        }
        const boundedValue = Math.max(0, Math.min(maximumPercentage,
            Math.round(Number(percentage))))
        audioObject.volume = Math.round(
            normalVolume * boundedValue / 100.0)
        audioObject.muted = boundedValue === 0
        return true
    }

    function toggleObjectMuted(audioObject) {
        if (!audioObject) {
            return false
        }
        audioObject.muted = !audioObject.muted
        return true
    }

    function setDefaultDevice(audioObject) {
        if (!audioObject) {
            return false
        }
        audioObject.default = true
        return true
    }

    function setRaiseMaximumVolume(enabled) {
        if (!raiseMaximumVolumeWritable) {
            return false
        }
        globalConfig.raiseMaximumVolume = Boolean(enabled)
        return true
    }

    function toggleGlobalMuteSinks() {
        // qmllint disable unresolved-type missing-property
        PlasmaVolume.GlobalService.globalMuteSinks()
        // qmllint enable unresolved-type missing-property
    }

    function toggleGlobalMuteSources() {
        // qmllint disable unresolved-type missing-property
        PlasmaVolume.GlobalService.globalMuteSources()
        // qmllint enable unresolved-type missing-property
    }

    function openItemOptions(audioObject, itemType, sourceModel,
            visualParent) {
        if (!audioObject || !visualParent || itemMenu.visible) {
            return false
        }
        itemMenu.pulseObject = audioObject
        itemMenu.itemType = itemType
        itemMenu.sourceModel = sourceModel || null
        itemMenu.cardModel = cardModel
        itemMenu.visualParent = visualParent
        if (!itemMenu.hasContent) {
            return false
        }
        itemMenu.openRelative()
        return true
    }
}
