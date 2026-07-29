import QtQuick
import org.kde.pipewire as PipeWire
import org.kde.taskmanager as TaskManager

PipeWire.PipeWireSourceItem {
    id: root

    property string windowUuid: ""
    readonly property bool hasThumbnail: root.ready
    readonly property bool supportsObjectSerial: "objectSerial" in root
        && "objectSerial" in screencastingRequest

    anchors.fill: parent
    nodeId: root.supportsObjectSerial ? 0 : screencastingRequest.nodeId

    Binding {
        target: root
        property: "objectSerial"
        value: screencastingRequest.objectSerial
        when: root.supportsObjectSerial
        restoreMode: Binding.RestoreBindingOrValue
    }

    TaskManager.ScreencastingRequest {
        id: screencastingRequest

        uuid: root.windowUuid
    }
}
