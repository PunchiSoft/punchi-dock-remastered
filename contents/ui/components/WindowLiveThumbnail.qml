pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects as Effects
import org.kde.kwindowsystem
import org.kde.pipewire as PipeWire
import org.kde.plasma.core as PlasmaCore
import org.kde.taskmanager as TaskManager

Item {
    id: root

    property string windowUuid: ""
    property var winId: 0
    property bool minimized: false
    property real cornerRadius: 0

    readonly property bool isWayland: KWindowSystem.isPlatformWayland
    readonly property bool isX11: KWindowSystem.isPlatformX11
    readonly property bool usesMinimizedFallback: root.isX11 && root.minimized
    property bool waylandThumbnailReady: false
    property bool x11ThumbnailReady: false

    readonly property bool hasThumbnail: (root.isWayland && root.waylandThumbnailReady)
        || (root.isX11 && root.x11ThumbnailReady)

    anchors.fill: parent

    Item {
        id: thumbnailContent

        anchors.fill: parent
        layer.enabled: root.hasThumbnail && root.cornerRadius > 0
        layer.effect: Effects.MultiEffect {
            maskEnabled: true
            maskSource: roundedMask
        }

        Loader {
            id: waylandLoader

            anchors.fill: parent
            active: root.isWayland && root.windowUuid.length > 0
            visible: root.isWayland

            sourceComponent: PipeWire.PipeWireSourceItem {
                id: waylandItem

                anchors.fill: parent
                nodeId: waylandItem.supportsObjectSerial ? 0 : screencastingRequest.nodeId
                readonly property bool supportsObjectSerial: "objectSerial" in waylandItem
                    && "objectSerial" in screencastingRequest

                Binding {
                    target: root
                    property: "waylandThumbnailReady"
                    value: waylandItem.ready
                    restoreMode: Binding.RestoreBindingOrValue
                }

                Binding {
                    target: waylandItem
                    property: "objectSerial"
                    value: screencastingRequest.objectSerial
                    when: waylandItem.supportsObjectSerial
                    restoreMode: Binding.RestoreBindingOrValue
                }

                TaskManager.ScreencastingRequest {
                    id: screencastingRequest

                    uuid: root.windowUuid
                }
            }
        }

        Loader {
            id: x11ThumbnailLoader

            anchors.fill: parent
            active: root.isX11 && !root.minimized && Number(root.winId) > 0
            visible: root.isX11

            sourceComponent: PlasmaCore.WindowThumbnail {
                id: x11Thumbnail

                anchors.fill: parent
                winId: Number(root.winId)
                readonly property bool hasThumbnail: paintedWidth > 0 && paintedHeight > 0

                Binding {
                    target: root
                    property: "x11ThumbnailReady"
                    value: x11Thumbnail.hasThumbnail
                    restoreMode: Binding.RestoreBindingOrValue
                }
            }
        }
    }

    Item {
        id: roundedMask

        anchors.fill: parent
        visible: false
        layer.enabled: true
        layer.samples: 8

        Rectangle {
            anchors.fill: parent
            radius: Math.max(0, root.cornerRadius)
            color: "white"
            antialiasing: true
        }
    }
}
