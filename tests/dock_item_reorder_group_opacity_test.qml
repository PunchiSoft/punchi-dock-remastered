import QtQuick
import QtQuick.Window
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase

    name: "DockItemReorderGroupOpacity"
    when: windowShown

    Component {
        id: windowComponent

        Window {
            width: 240
            height: 160
            visible: true

            property alias dockItem: dockItem

            Item {
                id: layoutStub

                anchors.fill: parent

                property real columnSpacing: 0
                property real rowSpacing: 0
                property bool mediaMorphActive: false
                property bool launcherDropTransitionActive: false
                property int hoveredIndex: -1
                property real mouseOffset: 0
                property real pointerPrimaryAxis: -1
                property real lastPointerPrimaryAxis: -1
                property bool wavePointerInsideLayout: false
                property var popupCoordinator: null

                signal trashUrlsDropped(var urls)

                Components.DockItem {
                    id: dockItem

                    anchors.centerIn: parent
                    layoutController: layoutStub
                    iconName: ""
                    itemName: "Test application"
                    itemCommand: "true"
                    iconSize: 48
                    animateEntry: false
                    entryOpacity: 1.0
                }
            }
        }
    }

    function init() {
        failOnWarning(/.?/)
    }

    function test_groupUsesAndRestoresSourceOpacity() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        tryCompare(hostWindow, "visible", true)

        const dockItem = hostWindow.dockItem
        fuzzyCompare(dockItem.opacity, 1.0, 0.0001)

        dockItem.persistentReorderGroupMember = true
        fuzzyCompare(dockItem.opacity, 0.28, 0.0001)

        dockItem.persistentReorderGroupMember = false
        dockItem.persistentReorderSource = true
        fuzzyCompare(dockItem.opacity, 0.28, 0.0001)

        dockItem.persistentReorderSource = false
        fuzzyCompare(dockItem.opacity, 1.0, 0.0001)
    }
}
