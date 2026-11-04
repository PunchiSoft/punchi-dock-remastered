// SPDX-License-Identifier: GPL-3.0-or-later
// Grid reaches the browser through its own model (gridItems -> apps), so it
// needs its own contract: the child pane must list the entered directory and
// never the snapshot the container keeps for its own surface.
import QtQuick
import QtQuick.Window
import QtCore
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase
    name: "FolderNavigationGrid"
    when: windowShown
    visible: true
    width: 1100
    height: 700
    readonly property string fixture: StandardPaths.writableLocation(
        StandardPaths.RuntimeLocation) + "/navigation"
    // Mirrors a container that followed its folder long enough to store a
    // snapshot, which is what used to leak into the child pane.
    readonly property var storedSnapshot: [
        {"name": "document.txt"},
        {"name": "many"}
    ]

    Components.FolderPopup {
        id: popup
        animationStyle: "none"
        profileScale: 1
        maximumAvailableWidth: 1000
        maximumAvailableHeight: 600
        layoutMode: "grid"
        folderItem: ({name: "Fixture", sourceType: "folder",
            sourcePath: testCase.fixture, layout: "grid",
            browseSubfolders: true, apps: testCase.storedSnapshot})
    }

    function entryNames(items) {
        const names = []
        const source = items || []
        for (let index = 0; index < source.length; ++index) {
            const row = source[index]
            if (!row || row._punchiOpenLocationAction) {
                continue
            }
            names.push(String(row.name))
        }
        return names.join(",")
    }

    function modelNames(model) {
        if (!model) {
            return ""
        }
        const names = []
        for (let index = 0; index < model.count; ++index) {
            names.push(String(model.get(index).name))
        }
        return names.join(",")
    }

    function entry(model, name) {
        for (let index = 0; index < model.count; ++index) {
            if (model.get(index).name === name) {
                return {"data": model.get(index), "index": index}
            }
        }
        fail("Missing fixture entry: " + name)
        return null
    }

    function settle(model) {
        tryCompare(model, "loading", false, 5000)
        compare(model.error, "")
    }

    function pane() {
        const loader = findChild(popup, "folderNavigationPaneLoader")
        tryVerify(function() { return loader.item !== null })
        return loader.item
    }

    function open(entryName) {
        const row = entry(popup.directoryModel, entryName)
        const grid = findChild(popup, "folderPopupGridView")
        grid.positionViewAtIndex(row.index, GridView.Contain)
        let delegate = null
        tryVerify(function() {
            delegate = findChild(popup, "folderPopupDelegate-" + row.index)
            return delegate !== null
        })
        waitForRendering(delegate)
        const pointer = findChild(popup, "folderPopupPointer-" + row.index)
        mouseMove(pointer, pointer.width / 2, pointer.height / 2)
        mouseClick(pointer, pointer.width / 2, pointer.height / 2)
    }

    function init() {
        failOnWarning(/.?/)
        popup.sessionActive = false
        popup.layoutMode = "grid"
        popup.maximumAvailableWidth = 1000
        popup.folderItem = ({name: "Fixture", sourceType: "folder",
            sourcePath: testCase.fixture, layout: "grid",
            browseSubfolders: true, apps: testCase.storedSnapshot})
        popup.sessionActive = true
        settle(popup.navigationController.rootModel)
        tryVerify(function() { return popup.itemCount > 0 })
    }

    function cleanup() {
        popup.sessionActive = false
    }

    function test_gridChildPaneListsTheEnteredDirectory() {
        open("one")
        tryCompare(popup, "lateralNavigation", true)
        settle(popup.navigationController.childModel)
        const view = pane()
        tryVerify(function() { return view.itemCount > 0 })
        const rendered = entryNames(view.gridItems)
        compare(rendered, modelNames(popup.navigationController.childModel))
        verify(rendered.indexOf("two") !== -1)
        // The snapshot of the container above must never stand in for the child.
        verify(rendered.indexOf("document.txt") === -1)
        verify(rendered.indexOf("many") === -1)
        compare(view.folderPath, popup.navigationController.childModel.location)
    }

    function test_gridEmptyChildShowsNoSnapshotRows() {
        open("empty")
        tryCompare(popup, "lateralNavigation", true)
        settle(popup.navigationController.childModel)
        const view = pane()
        compare(view.itemCount, 0)
        verify(entryNames(view.gridItems).indexOf("document.txt") === -1)
    }
}
