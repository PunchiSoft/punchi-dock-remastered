import QtQuick
import org.kde.pipewire as PipeWire
import org.kde.taskmanager as TaskManager

PipeWire.PipeWireSourceItem {
    id: root

    property string windowUuid: ""
    readonly property bool hasThumbnail: root.ready

    anchors.fill: parent
    nodeId: screencastingRequest.nodeId

    TaskManager.ScreencastingRequest {
        id: screencastingRequest

        uuid: root.windowUuid
    }
}
