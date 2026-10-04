// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtCore
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase
    name: "FolderPopupScrollOrigin"
    when: windowShown
    visible: true
    width: 1100
    height: 700
    readonly property string fixture: StandardPaths.writableLocation(
        StandardPaths.RuntimeLocation) + "/navigation"
    property var host: null
    property int originalCacheBuffer: 0

    Component {
        id: hostComponent
        Components.GuardedPopupDialog {
            id: dialog
            hideOnWindowDeactivate: false
            property alias popup: content
            mainItem: Components.PopupAnimatedContent {
                id: animated
                popupVisible: dialog.visible
                animationStyle: "bounce"
                popupDirection: Qt.TopEdge
                Components.ContextSurfaceStack {
                    showMedia: false
                    contentGeometryTransitionsEnabled: false
                    backgroundImagePath: "widgets/background"
                    contentFramePaddingPercent: 2
                    edgeTailEnabled: true
                    edgeTailLocation: Qt.BottomEdge
                    edgeTailAnchorExtent: 48
                    Components.FolderPopup {
                        id: content
                        sessionActive: dialog.visible
                        profileScale: 1.1
                        profileRows: 4
                        maximumAvailableWidth: 1000
                        maximumAvailableHeight: 600
                        animationStyle: animated.animationStyle
                        revealProgress: animated.openingProgress
                    }
                }
            }
        }
    }
    SignalSpy {
        id: navigationSpy
        target: testCase.host ? testCase.host.popup : null
        signalName: "directoryActivated"
    }

    function initTestCase() {
        nativePopupTestSupport.allowNativePopupPlatformWarnings()
    }
    function init() {
        failOnWarning(/.?/)
        host = hostComponent.createObject(testCase)
        verify(host !== null)
        originalCacheBuffer = view(host.popup).cacheBuffer
        navigationSpy.clear()
    }
    function cleanup() {
        if (host) {
            host.closeSafely()
            host.destroy()
            host = null
        }
        // Drain object-bound deferred callbacks before the next host is created.
        wait(0)
    }
    function view(popup) {
        return findChild(popup, "folderPopupGridView")
    }
    function snapshot(grid) {
        const first = grid.itemAtIndex(0)
        return JSON.stringify({count: grid.count, originY: grid.originY,
            contentY: grid.contentY, contentHeight: grid.contentHeight,
            width: grid.width, height: grid.height, cellHeight: grid.cellHeight,
            firstY: first ? first.y : null})
    }
    function open(path, mode) {
        host.closeSafely()
        host.popup.layoutMode = mode
        host.popup.folderItem = {name: "Fixture", sourceType: "folder",
            sourcePath: path, browseSubfolders: true, apps: []}
        host.openSafely()
        tryCompare(host, "visible", true)
        tryCompare(host.popup.directoryModel, "loading", false, 5000)
        compare(host.popup.directoryModel.error, "")
        const expected = path.endsWith("/many") ? 80
            : (path.endsWith("/empty") ? 0 : 5)
        tryCompare(host.popup.directoryModel, "count", expected)
        tryCompare(view(host.popup), "count", expected + 1)
    }
    function visibleRow(grid, index) {
        const item = grid.itemAtIndex(index)
        return item !== null && item.visible && item.opacity > 0
            && item.y + item.height > grid.contentY
            && item.y < grid.contentY + grid.height
    }
    function verifyOpening() {
        const grid = view(host.popup)
        verify(waitForPolish(grid))
        tryVerify(function() {
            return visibleRow(grid, 0) && Math.abs(grid.contentY - grid.originY) <= 1
        }, 2000,
            "Initial row must appear without wheel input: " + snapshot(grid))
        fuzzyCompare(grid.contentY - grid.originY, 0, 1)
        compare(grid.currentIndex, 0)
        // Instant motion can finish painting during polish. Request a fresh
        // frame so this assertion does not wait for a nonexistent animation.
        host.update()
        verify(waitForRendering(grid))
    }
    function test_reopen_without_wheel_data() {
        return [{tag: "list", mode: "list"},
            {tag: "detail", mode: "detailed"}]
    }
    function test_reopen_without_wheel(data) {
        for (let cycle = 0; cycle < 16; ++cycle) {
            host.popup.profileScale = [1, 1.1, 1.25][cycle % 3]
            open(fixture + (cycle % 2 ? "/many" : ""), data.mode)
            verifyOpening()
            const grid = view(host.popup)
            grid.positionViewAtIndex(grid.count - 1, GridView.End)
            tryVerify(function() { return visibleRow(grid, grid.count - 1) })
            verify(grid.contentY - grid.originY > 0)
        }
    }
    function test_back_preserves_relative_scroll_data() {
        return [{tag: "lateral", availableWidth: 1000},
            {tag: "narrow", availableWidth: 350}]
    }
    function test_long_to_short_has_visible_rows_data() {
        return [{tag: "list", mode: "list"},
            {tag: "detail", mode: "detailed"}]
    }
    function test_long_to_short_has_visible_rows(data) {
        open(fixture + "/many", data.mode)
        const grid = view(host.popup)
        grid.positionViewAtIndex(grid.count - 1, GridView.End)
        tryVerify(function() { return visibleRow(grid, grid.count - 1) })
        open(fixture, data.mode)
        verifyOpening()
    }
    function test_back_preserves_relative_scroll(data) {
        // Warm up a long, scrolled listing before returning to the root. This
        // recreates a nonzero view origin without assigning a read-only property.
        open(fixture + "/many", "list")
        verifyOpening()
        const grid = view(host.popup)
        grid.positionViewAtIndex(grid.count - 1, GridView.End)
        tryVerify(function() { return visibleRow(grid, grid.count - 1) })
        host.popup.profileRows = 2
        host.popup.maximumAvailableWidth = data.availableWidth
        open(fixture, "list")
        verifyOpening()
        const model = host.popup.directoryModel
        let index = -1
        let expectedChildCount = 0
        for (let row = 0; row < model.count; ++row) {
            const entry = model.get(row)
            if (entry.navigable) {
                index = row
                expectedChildCount = entry.name === "many" ? 80
                    : (entry.name === "one" ? 2 : 0)
            }
        }
        verify(index >= 0)
        grid.positionViewAtIndex(index, GridView.End)
        tryVerify(function() { return visibleRow(grid, index) })
        verify(waitForPolish(grid))
        const relativeScroll = grid.contentY - grid.originY
        verify(relativeScroll > 0)
        const pointer = findChild(host.popup, "folderPopupPointer-" + index)
        verify(pointer !== null)
        mouseClick(pointer, pointer.width / 2, pointer.height / 2)
        compare(navigationSpy.count, 1)
        fuzzyCompare(navigationSpy.signalArguments[0][2], relativeScroll, 1)
        tryCompare(host.popup.navigationController.childModel, "loading", false)
        tryCompare(host.popup.navigationController.childModel, "count", expectedChildCount)
        host.popup.navigationController.back()
        tryCompare(host.popup, "navigationDepth", 0)
        tryCompare(grid, "currentIndex", index)
        tryVerify(function() {
            return Math.abs(grid.contentY - grid.originY - relativeScroll) <= 1
                && visibleRow(grid, index)
        }, 2000, "Back must restore the same relative scroll: " + snapshot(grid))
    }
    function test_valid_scroll_survives_geometry_change() {
        open(fixture + "/many", "list")
        verifyOpening()
        const grid = view(host.popup)
        grid.positionViewAtIndex(20, GridView.Beginning)
        tryVerify(function() { return visibleRow(grid, 20) })
        const previous = grid.contentY - grid.originY
        host.popup.profileRows = 3
        verify(waitForPolish(grid))
        fuzzyCompare(grid.contentY - grid.originY, previous, 1)
        verify(visibleRow(grid, 20))
    }
    function test_empty_and_mode_hot_refresh() {
        open(fixture + "/empty", "list")
        verifyOpening()
        const grid = view(host.popup)
        compare(grid.count, 1)
        verify(grid.itemAtIndex(0).isOpenLocationAction)
        compare(grid.cacheBuffer, 0)
        host.popup.layoutMode = "grid"
        tryCompare(host.popup, "navigationActive", false)
        compare(grid.cacheBuffer, originalCacheBuffer)
        host.popup.layoutMode = "detailed"
        tryCompare(host.popup.directoryModel, "loading", false)
        verifyOpening()
        compare(grid.cacheBuffer, 0)
    }
    function test_cancel_and_recreate() {
        for (let cycle = 0; cycle < 4; ++cycle) {
            host.popup.layoutMode = "list"
            host.popup.folderItem = {name: "Fixture", sourceType: "folder",
                sourcePath: fixture + "/many", browseSubfolders: true, apps: []}
            host.openSafely()
            host.closeSafely()
            host.destroy()
            host = null
            wait(0)
            host = hostComponent.createObject(testCase)
            verify(host !== null)
            open(fixture, "list")
            verifyOpening()
        }
    }
}
