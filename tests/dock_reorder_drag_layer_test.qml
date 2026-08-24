import QtQuick
import QtQuick.Window
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase

    name: "DockReorderDragLayer"
    when: windowShown

    Component {
        id: windowComponent

        Window {
            id: hostWindow
            width: 480
            height: 240
            visible: true

            property alias dragLayer: dragLayer

            Components.DockReorderDragLayer {
                id: dragLayer
                anchors.fill: parent
                iconName: ""
                iconSize: 48
                motionEnabled: false
            }
        }
    }

    function init() {
        failOnWarning(/.?/)
    }

    function test_proxyTracksPointerAndResetsVisibility() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        tryCompare(hostWindow, "visible", true)

        const layer = hostWindow.dragLayer
        const proxy = findChild(layer, "dockReorderDragProxy")
        verify(proxy !== null)
        verify(!layer.visible)

        layer.pointerPosition = Qt.point(180, 96)
        layer.active = true
        tryCompare(layer, "visible", true)
        tryCompare(proxy, "visible", true)
        compare(Math.round(proxy.x + proxy.width / 2), 180)
        compare(Math.round(proxy.y + proxy.height / 2), 96)
        compare(proxy.scale, 1.0)

        layer.pointerPosition = Qt.point(310, 144)
        compare(Math.round(proxy.x + proxy.width / 2), 310)
        compare(Math.round(proxy.y + proxy.height / 2), 144)

        layer.active = false
        tryCompare(layer, "visible", false)
        verify(!proxy.visible)
    }
}
