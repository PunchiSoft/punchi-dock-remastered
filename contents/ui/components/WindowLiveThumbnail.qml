pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects as Effects
import org.kde.kwindowsystem
import org.kde.pipewire as PipeWire
import org.kde.taskmanager as TaskManager

Item {
    id: root

    property string windowUuid: ""
    property var winId: 0
    property bool minimized: false
    property real cornerRadius: 0

    readonly property bool isWayland: KWindowSystem.isPlatformWayland
    readonly property bool isX11: KWindowSystem.isPlatformX11
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

            // org.kde.pipewire ships an incomplete qmltypes on Debian/Plasma 6.3:
            // PipeWireSourceItem is not declared, so the type and its members
            // stay unresolved even though they exist at runtime.
            // qmllint disable import unresolved-type missing-property unqualified
            sourceComponent: PipeWire.PipeWireSourceItem {
                id: waylandItem

                anchors.fill: parent
                nodeId: waylandItem.supportsObjectSerial ? 0 : screencastingRequest.nodeId
                readonly property bool supportsObjectSerial: "objectSerial" in waylandItem
                    && "objectSerial" in screencastingRequest
                // Plasma versions before objectSerial use nodeId exclusively.
                readonly property var serialRequest: screencastingRequest

                Binding {
                    target: root
                    property: "waylandThumbnailReady"
                    value: waylandItem.ready
                    restoreMode: Binding.RestoreBindingOrValue
                }

                Binding {
                    target: waylandItem
                    property: "objectSerial"
                    value: waylandItem.supportsObjectSerial
                        ? waylandItem.serialRequest.objectSerial : 0
                    when: waylandItem.supportsObjectSerial
                    restoreMode: Binding.RestoreBindingOrValue
                }

                TaskManager.ScreencastingRequest {
                    id: screencastingRequest

                    uuid: root.windowUuid
                }
            }
            // qmllint enable import unresolved-type missing-property unqualified
        }

        Loader {
            id: x11ThumbnailLoader

            anchors.fill: parent
            active: root.isX11 && !root.minimized && Number(root.winId) > 0
            visible: root.isX11
            source: root.isX11 ? "X11WindowThumbnail.qml" : ""

            Binding {
                target: x11ThumbnailLoader.item
                property: "winId"
                value: Number(root.winId)
                when: x11ThumbnailLoader.status === Loader.Ready
                restoreMode: Binding.RestoreBindingOrValue
            }

            Binding {
                target: root
                property: "x11ThumbnailReady"
                value: x11ThumbnailLoader.item
                    // X11WindowThumbnail.qml defines this property; qmllint
                    // cannot infer properties across Loader.source.
                    // qmllint disable missing-property
                    ? x11ThumbnailLoader.item.hasThumbnail
                    : false
                when: x11ThumbnailLoader.status === Loader.Ready
                restoreMode: Binding.RestoreBindingOrValue
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
