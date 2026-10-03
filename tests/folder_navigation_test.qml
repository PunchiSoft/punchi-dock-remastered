// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Window
import QtCore
import QtTest
import org.punchi.dock as Punchi
import "../contents/ui/components" as Components

TestCase {
    id: testCase
    name: "FolderNavigation"
    when: windowShown
    visible: true
    width: 1100
    height: 700
    readonly property string fixture: StandardPaths.writableLocation(StandardPaths.RuntimeLocation) + "/navigation"
    Components.FolderPopup {
        id: popup
        animationStyle: "none"
        profileScale: 1
        maximumAvailableWidth: 1000
        maximumAvailableHeight: 600
        layoutMode: "list"
        folderItem: ({name: "Fixture", sourceType: "folder", sourcePath: testCase.fixture,
            browseSubfolders: true, apps: []})
    }
    Punchi.FolderNavigationModel { id: isolatedModel }
    SignalSpy { id: launchSpy; target: popup; signalName: "appLaunched" }
    SignalSpy { id: locationSpy; target: popup; signalName: "openLocationRequested" }
    SignalSpy { id: closeSpy; target: popup; signalName: "closeRequested" }
    function entry(model, name) {
        for (let i = 0; i < model.count; ++i) {
            if (model.get(i).name === name) { return {data: model.get(i), index: i} }
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
    function activate(view, name, keyboard) {
        const row = entry(view.directoryModel, name)
        const grid = findChild(view, "folderPopupGridView")
        grid.positionViewAtIndex(row.index, GridView.Contain)
        let delegate = null
        tryVerify(function() {
            delegate = findChild(view, "folderPopupDelegate-" + row.index)
            return delegate !== null
        })
        waitForRendering(delegate)
        if (keyboard) {
            delegate.forceActiveFocus()
            keyClick(Qt.Key_Right)
        } else {
            const pointer = findChild(view, "folderPopupPointer-" + row.index)
            mouseMove(pointer, pointer.width / 2, pointer.height / 2)
            mouseClick(pointer, pointer.width / 2, pointer.height / 2)
        }
    }
    function initTestCase() {
        testCase.Window.window.width = 1100
        testCase.Window.window.height = 700
    }
    function init() {
        failOnWarning(/.?/)
        popup.sessionActive = false
        popup.layoutMode = "list"
        popup.maximumAvailableWidth = 1000
        popup.folderItem = {name: "Fixture", sourceType: "folder", sourcePath: fixture,
            browseSubfolders: true, apps: []}
        popup.sessionActive = true
        settle(popup.navigationController.rootModel)
        tryVerify(function() { return popup.itemCount > 0 })
        launchSpy.clear(); locationSpy.clear(); closeSpy.clear()
        isolatedModel.enabled = false
        isolatedModel.rootPath = fixture
    }
    function cleanup() { popup.sessionActive = false; isolatedModel.enabled = false }
    function test_lateral_keyboard_back_and_depth() {
        activate(popup, "one", true)
        tryCompare(popup, "lateralNavigation", true)
        settle(popup.navigationController.childModel)
        compare(launchSpy.count, 0)
        compare(popup.navigationDepth, 1)
        activate(pane(), "two", false)
        settle(popup.navigationController.childModel)
        compare(popup.navigationDepth, 2)
        activate(pane(), "three", true)
        settle(popup.navigationController.childModel)
        compare(popup.navigationDepth, 3)
        compare(entry(pane().directoryModel, "four").data.navigable, false)
        activate(pane(), "four", false)
        compare(launchSpy.count, 1)
        mouseClick(findChild(pane(), "folderNavigationBack"))
        settle(popup.navigationController.childModel)
        compare(popup.navigationDepth, 2)
        const restored = entry(pane().directoryModel, "three")
        tryCompare(findChild(pane(), "folderPopupGridView"), "currentIndex", restored.index)
        popup.navigationController.back()
        settle(popup.navigationController.childModel)
        popup.navigationController.back()
        tryCompare(popup, "lateralNavigation", false)
        compare(popup.navigationDepth, 0)
        tryCompare(findChild(popup, "folderPopupGridView"), "currentIndex",
            entry(popup.directoryModel, "one").index)
    }
    function test_narrow_detail_and_empty_folder() {
        popup.layoutMode = "detailed"
        popup.maximumAvailableWidth = 350
        activate(popup, "empty", false)
        settle(popup.navigationController.childModel)
        tryCompare(popup, "narrowNavigation", true)
        compare(popup.itemCount, 0)
        compare(popup.folderPath, popup.navigationController.childModel.location)
        const emptyView = findChild(popup, "folderPopupGridView")
        tryCompare(emptyView, "count", 1)
        const emptyAction = findChild(popup, "folderOpenLocationRow")
        verify(emptyAction !== null)
        compare(emptyAction.index, 0)
        compare(emptyAction.parent, emptyView.contentItem)
        compare(popup.openLocationRowHeight, 0)
        mouseClick(findChild(popup, "folderOpenLocationAction"))
        compare(locationSpy.count, 1)
        compare(locationSpy.signalArguments[0][0], popup.folderPath)
        mouseClick(findChild(popup, "folderNavigationBack"))
        tryCompare(popup, "narrowNavigation", false)
        activate(popup, "document.txt", false)
        compare(launchSpy.count, 1)
    }
    function test_scroll_restore_and_session_cancel() {
        const grid = findChild(popup, "folderPopupGridView")
        const row = entry(popup.directoryModel, "many")
        grid.positionViewAtIndex(row.index, GridView.Contain)
        waitForRendering(grid)
        const before = grid.contentY
        activate(popup, "many", false)
        settle(popup.navigationController.childModel)
        compare(popup.navigationController.childModel.count, 80)
        const child = pane()
        const childView = findChild(child, "folderPopupGridView")
        tryCompare(childView, "count", 81)
        childView.positionViewAtIndex(80, GridView.Contain)
        tryVerify(function() { return findChild(child, "folderOpenLocationRow") !== null })
        const finalAction = findChild(child, "folderOpenLocationRow")
        compare(finalAction.index, 80)
        compare(finalAction.parent, childView.contentItem)
        const childPointer = findChild(child, "folderOpenLocationAction")
        childPointer.forceActiveFocus()
        keyClick(Qt.Key_Return)
        compare(locationSpy.count, 1)
        compare(locationSpy.signalArguments[0][0], child.folderPath)
        popup.navigationController.back()
        tryCompare(grid, "currentIndex", row.index)
        tryCompare(grid, "contentY", before)
        popup.sessionActive = false
        compare(popup.navigationController.rootModel.count, 0)
        compare(popup.navigationController.childModel.loading, false)
    }
    function test_native_bounds_and_cancellation() {
        isolatedModel.enabled = true
        settle(isolatedModel)
        compare(entry(isolatedModel, "escape").data.navigable, false)
        isolatedModel.location = fixture + "/one"
        settle(isolatedModel)
        compare(entry(isolatedModel, "cycle").data.navigable, false)
        isolatedModel.location = fixture
        settle(isolatedModel)
        const original = isolatedModel.location
        isolatedModel.location = fixture + "/../outside"
        compare(isolatedModel.location, original)
        isolatedModel.location = fixture + "/one/two/three/four"
        compare(isolatedModel.location, original)
        isolatedModel.location = "https://example.com/"
        compare(isolatedModel.location, original)
        for (let i = 0; i < isolatedModel.count; ++i) { verify(!isolatedModel.get(i).name.startsWith(".")) }
        isolatedModel.location = fixture + "/many"
        settle(isolatedModel)
        compare(isolatedModel.count, 80)
        isolatedModel.reload()
        isolatedModel.enabled = false
        compare(isolatedModel.loading, false)
        compare(isolatedModel.count, 0)
    }
    function test_reactive_settings_and_recreation() {
        activate(popup, "one", false)
        settle(popup.navigationController.childModel)
        popup.folderItem = {name: "Fixture", sourceType: "folder", sourcePath: fixture,
            browseSubfolders: false, apps: []}
        tryCompare(popup, "navigationActive", false)
        compare(popup.navigationDepth, 0)
        compare(popup.navigationController.childModel.count, 0)
        popup.folderItem = {name: "Fixture", sourceType: "folder", sourcePath: fixture,
            browseSubfolders: true, apps: []}
        settle(popup.navigationController.rootModel)
        popup.layoutMode = "grid"
        compare(popup.navigationActive, false)
        popup.layoutMode = "fan"
        compare(popup.navigationActive, false)
        popup.layoutMode = "list"
        settle(popup.navigationController.rootModel)
        for (let i = 0; i < 3; ++i) {
            const instance = Qt.createQmlObject('import QtQuick; import "../contents/ui/components" as C; C.FolderPopup { layoutMode: "list"; animationStyle: "none" }', testCase)
            instance.folderItem = popup.folderItem
            instance.destroy()
        }
    }
}
