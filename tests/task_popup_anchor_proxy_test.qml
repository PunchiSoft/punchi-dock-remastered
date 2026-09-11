import QtQuick
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase

    name: "TaskPopupAnchorProxy"
    when: windowShown

    Item {
        id: host

        anchors.fill: parent

        Components.TaskPopupAnchorProxy {
            id: proxy
        }
    }

    Component {
        id: sourceComponent

        Item {
            x: 73
            y: 41
            width: 52
            height: 38
        }
    }

    property var sourceItem: null

    function init() {
        failOnWarning(/.?/)
        proxy.clear()
        sourceItem = sourceComponent.createObject(host)
        verify(sourceItem !== null)
    }

    function cleanup() {
        if (sourceItem) {
            sourceItem.destroy()
            sourceItem = null
        }
        proxy.clear()
        wait(0)
    }

    function test_snapshotSurvivesSourceDestruction() {
        verify(proxy.capture(sourceItem))
        compare(proxy.x, 73)
        compare(proxy.y, 41)
        compare(proxy.width, 52)
        compare(proxy.height, 38)
        verify(proxy.geometryReady)

        sourceItem.destroy()
        sourceItem = null
        wait(0)

        compare(proxy.x, 73)
        compare(proxy.y, 41)
        compare(proxy.width, 52)
        compare(proxy.height, 38)
        verify(proxy.geometryReady)
    }

    function test_invalidCapturePreservesLastValidGeometry() {
        verify(proxy.capture(sourceItem))

        sourceItem.width = 0
        verify(!proxy.capture(sourceItem))

        compare(proxy.x, 73)
        compare(proxy.y, 41)
        compare(proxy.width, 52)
        compare(proxy.height, 38)
    }

    function test_popupExtentPreservesAnchorCenter_data() {
        return [
            { tag: "horizontal", horizontalEdge: true,
                popupWidth: 120, popupHeight: 100 },
            { tag: "vertical", horizontalEdge: false,
                popupWidth: 120, popupHeight: 100 }
        ]
    }

    function test_popupExtentPreservesAnchorCenter(data) {
        verify(proxy.capture(sourceItem))
        const sourceCenter = Qt.point(
            proxy.sourceGeometry.x + proxy.sourceGeometry.width / 2,
            proxy.sourceGeometry.y + proxy.sourceGeometry.height / 2)

        verify(proxy.configureForPopup(data.popupWidth,
            data.popupHeight, data.horizontalEdge))

        compare(proxy.x + proxy.width / 2, sourceCenter.x)
        compare(proxy.y + proxy.height / 2, sourceCenter.y)
        if (data.horizontalEdge) {
            verify(proxy.width / 3 > data.popupWidth / 2)
            compare(proxy.height, proxy.sourceGeometry.height)
        } else {
            verify(proxy.height / 3 > data.popupHeight / 2)
            compare(proxy.width, proxy.sourceGeometry.width)
        }
    }
}
