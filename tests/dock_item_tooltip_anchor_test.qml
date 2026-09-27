// SPDX-License-Identifier: GPL-2.0-or-later

// Plasma places the floating label of a dock item against the scene rect of its
// visual parent and does not follow that item afterwards. The label must
// therefore be anchored to the icon the dock draws, not to the item's layout
// rect: the zoom scales the icon about its centre and shifts it along both axes
// while the item keeps its geometry. These tests compare the anchor with the
// icon's painted rect, derived from the icon itself.
// The exact match is the settled state, with `entryScale`,
// `clickAnimationScale` and the reaction offsets back at 1 and 0.

import QtQuick
import QtQuick.Window
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase

    name: "DockItemTooltipAnchor"
    when: windowShown

    Component {
        id: windowComponent

        Window {
            id: hostWindow
            width: 240
            height: 200
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
                    itemName: "LibreOffice"
                    itemType: "folder"
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

    // Painted rect of an icon, in the item's coordinates. The icon is scaled
    // about its own centre, so mapping that centre and growing the size by
    // `scale` reproduces what is on screen.
    function iconVisibleRect(dockItem, icon) {
        const center = icon.mapToItem(dockItem, icon.width / 2, icon.height / 2)
        const width = icon.width * icon.scale
        const height = icon.height * icon.scale
        return Qt.rect(center.x - width / 2, center.y - height / 2,
            width, height)
    }

    function anchorRect(dockItem, anchor) {
        const origin = anchor.mapToItem(dockItem, 0, 0)
        return Qt.rect(origin.x, origin.y, anchor.width, anchor.height)
    }

    function verifyAnchorMatchesIcon(dockItem) {
        const icon = findChild(dockItem, "dockItemIcon")
        const anchor = findChild(dockItem, "dockItemTooltipAnchor")
        verify(icon !== null)
        verify(anchor !== null)

        const expected = iconVisibleRect(dockItem, icon)
        const actual = anchorRect(dockItem, anchor)
        fuzzyCompare(actual.x, expected.x, 0.01)
        fuzzyCompare(actual.y, expected.y, 0.01)
        fuzzyCompare(actual.width, expected.width, 0.01)
        fuzzyCompare(actual.height, expected.height, 0.01)
    }

    function test_anchorMatchesTheIconAtRest() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        tryCompare(hostWindow, "visible", true)

        verifyAnchorMatchesIcon(hostWindow.dockItem)
    }

    function test_anchorFollowsTheZoom() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        tryCompare(hostWindow, "visible", true)

        const dockItem = hostWindow.dockItem
        dockItem.waveScale = 1.5
        // The dock shifts the icon towards the panel edge while it grows, so the
        // anchor cannot keep the item's resting position either.
        verify(Math.abs(dockItem.hoverOffsetY) > 0.0)
        verifyAnchorMatchesIcon(dockItem)
    }
}
