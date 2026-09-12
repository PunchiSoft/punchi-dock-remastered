// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtTest
import org.kde.kirigami as Kirigami
import "../contents/ui/components" as Components

TestCase {
    id: testCase

    name: "MediaDockItemMorph"
    when: windowShown
    property var hostWindowUnderTest: null

    Component {
        id: windowComponent

        Window {
            id: hostWindow
            width: 640
            height: 180
            visible: true

            property alias dockItem: mediaDelegate

            Item {
                id: layoutStub

                anchors.fill: parent
                property real columnSpacing: 4
                property real rowSpacing: 4
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
                    id: mediaDelegate

                    anchors.centerIn: parent
                    layoutController: layoutStub
                    itemType: "media"
                    itemIndex: 0
                    iconSize: 38
                    hoverScaleSetting: 1.5
                    hoverAnimationMode: "single"
                    mediaDisplayMode: "compact"
                    mediaMotionEnabled: false
                    mediaAutoCollapseDelaySeconds: 30
                    mediaDefaultPlayerIcon: "emblem-music-symbolic"
                    animateEntry: false
                    entryOpacity: 1.0
                }
            }
        }
    }

    function init() {
        failOnWarning(/.?/)
    }

    function cleanup() {
        if (hostWindowUnderTest) {
            const hostWindow = hostWindowUnderTest
            hostWindowUnderTest = null
            hostWindow.close()
            wait(0)
            hostWindow.destroy()
            wait(0)
        }
    }

    function createHost() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)
        const mediaItem = findChild(hostWindow.dockItem, "mediaDockItem")
        const compactIcon = findChild(hostWindow.dockItem,
            "compactMediaPlayerIcon")
        verify(mediaItem !== null)
        verify(compactIcon !== null)
        return {
            "window": hostWindow,
            "dockItem": hostWindow.dockItem,
            "mediaItem": mediaItem,
            "compactIcon": compactIcon
        }
    }

    function test_compactIconKeepsConfiguredSize() {
        const host = createHost()
        const dockItem = host.dockItem
        const mediaItem = host.mediaItem
        const compactIcon = host.compactIcon

        mediaItem.expanded = false
        wait(0)

        compare(mediaItem.collapseProgress, 1.0)
        compare(mediaItem.currentMainAxisLength, dockItem.iconSize)
        compare(compactIcon.width, dockItem.highQualityIconSize)
        fuzzyCompare(compactIcon.width * compactIcon.scale,
            dockItem.iconSize, 0.01)
    }

    function test_onlyCollapsedMediaUsesDockZoom() {
        const host = createHost()
        const dockItem = host.dockItem
        const mediaItem = host.mediaItem

        dockItem.hoveredIndex = 0
        dockItem.hoverZoomProgress = 1.0

        mediaItem.expanded = true
        wait(0)
        compare(dockItem.waveScale, 1.0)
        compare(mediaItem.visualScale, 1.0)

        mediaItem.expanded = false
        wait(0)
        compare(dockItem.waveScale, 1.5)
        compare(mediaItem.visualScale, 1.5)
        compare(mediaItem.scale, 1.5)
    }

    function test_morphProgressRetargetsSmoothly() {
        if (Kirigami.Units.longDuration === 0) {
            skip("The runtime requests reduced motion")
        }

        const host = createHost()
        const dockItem = host.dockItem
        const mediaItem = host.mediaItem

        mediaItem.expanded = false
        compare(mediaItem.collapseProgress, 1.0)
        dockItem.mediaMotionEnabled = true

        mediaItem.expanded = true
        wait(60)
        verify(mediaItem.collapseProgress > 0.0)
        verify(mediaItem.collapseProgress < 1.0)
        const expandingProgress = mediaItem.collapseProgress

        mediaItem.expanded = false
        wait(60)
        verify(mediaItem.collapseProgress > expandingProgress)
        tryCompare(mediaItem, "collapseProgress", 1.0, 1000)
        compare(mediaItem.currentMainAxisLength, dockItem.iconSize)
        compare(mediaItem.compactContentOpacity, 1.0)
        compare(mediaItem.expandedContentOpacity, 0.0)
    }

    function test_disabledMotionChangesStateImmediately() {
        const host = createHost()
        const mediaItem = host.mediaItem

        mediaItem.expanded = false
        compare(mediaItem.collapseProgress, 1.0)
        mediaItem.expanded = true
        compare(mediaItem.collapseProgress, 0.0)
        compare(mediaItem.compactContentOpacity, 0.0)
        compare(mediaItem.expandedContentOpacity, 1.0)
    }
}
