// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Window
import QtCore
import QtTest
import org.kde.kirigami as Kirigami
import "../contents/ui/components" as Components

TestCase {
    id: testCase
    name: "FolderNavigationCloseMotion"
    when: windowShown
    visible: true
    width: 1100
    height: 700
    readonly property string fixture: StandardPaths.writableLocation(StandardPaths.RuntimeLocation) + "/navigation"

    Components.FolderPopup {
        id: popup
        profileScale: 1
        maximumAvailableWidth: 1000
        maximumAvailableHeight: 600
        layoutMode: "list"
        folderItem: ({name: "Fixture", sourceType: "folder", sourcePath: testCase.fixture,
            browseSubfolders: true, apps: []})
    }
    SignalSpy { id: closeSpy; target: popup; signalName: "closeRequested" }
    function settle(model) {
        tryCompare(model, "loading", false, 5000)
        compare(model.error, "")
    }
    function entry(name) {
        const model = popup.navigationController.rootModel
        for (let i = 0; i < model.count; ++i) {
            if (model.get(i).name === name) {
                return {data: model.get(i), index: i}
            }
        }
        fail("Missing fixture directory: " + name)
        return null
    }
    function enter(name) {
        const row = entry(name)
        verify(popup.navigationController.enter(row.data, row.index, 0, true))
    }
    function loader() { return findChild(popup, "folderNavigationPaneLoader") }
    function closeButton() { return findChild(popup, "folderPopupCloseButton") }
    function verifyCloseEdge() {
        const button = closeButton()
        const position = button.mapToItem(popup, 0, 0)
        fuzzyCompare(position.x + button.width + popup.classicMargin, popup.width, 1)
        verify(button.visible)
    }
    function initTestCase() {
        testCase.Window.window.width = 1100
        testCase.Window.window.height = 700
    }
    function init() {
        failOnWarning(/.?/)
        popup.sessionActive = false
        popup.animationStyle = "none"
        popup.maximumAvailableWidth = 1000
        popup.layoutMode = "list"
        popup.sessionActive = true
        settle(popup.navigationController.rootModel)
        tryCompare(popup, "lateralRevealProgress", 0)
        // Begin from a painted root listing; cancellation below still occurs
        // while the child pane is being created and its reveal is in flight.
        waitForRendering(popup)
        closeSpy.clear()
    }
    function cleanup() {
        popup.sessionActive = false
        popup.animationStyle = "none"
        tryCompare(loader(), "active", false)
        tryCompare(popup.navigationController.childModel, "count", 0)
    }
    function test_close_global_data() { return [{tag: "list", mode: "list"}, {tag: "detail", mode: "detailed"}] }
    function test_close_global(data) {
        popup.layoutMode = data.mode
        verifyCloseEdge()
        const initialX = closeButton().x
        enter("one")
        settle(popup.navigationController.childModel)
        tryCompare(popup, "lateralRevealProgress", 1)
        verifyCloseEdge()
        verify(closeButton().x > initialX + popup.presentationWidth)
        verify(loader().item !== null)
        compare(findChild(loader().item, "folderPopupCloseButton").visible, false)
        compare(loader().item.headerCloseButtonReserve, closeButton().width)
        mouseClick(closeButton())
        compare(closeSpy.count, 1)
        loader().item.forceActiveFocus()
        keyClick(Qt.Key_Escape)
        compare(closeSpy.count, 2)
        popup.navigationController.back()
        verifyCloseEdge()
        fuzzyCompare(closeButton().x, initialX, 1)
    }
    function test_shared_progress_and_retained_exit() {
        popup.animationStyle = "scale"
        verify(popup.navigationMotionEnabled)
        const initialWidth = popup.width
        const initialListWidth = findChild(popup, "folderPopupGridView").width
        enter("many")
        tryVerify(function() { return popup.lateralRevealProgress > 0 && popup.lateralRevealProgress < 1 })
        verify(popup.width > initialWidth)
        verify(popup.width < initialWidth * 2 + Kirigami.Units.smallSpacing)
        verifyCloseEdge()
        compare(findChild(popup, "folderPopupGridView").width, initialListWidth)
        fuzzyCompare(loader().opacity, popup.lateralRevealProgress, 0.001)
        settle(popup.navigationController.childModel)
        tryCompare(popup, "lateralRevealProgress", 1)
        const child = loader().item
        const model = popup.navigationController.childModel
        const childCount = model.count
        const title = child.headerTitle
        popup.navigationController.back()
        tryVerify(function() { return popup.lateralRevealProgress > 0 && popup.lateralRevealProgress < 1 })
        compare(loader().item, child)
        compare(loader().enabled, false)
        compare(child.headerTitle, title)
        compare(model.count, childCount)
        verifyCloseEdge()
        tryCompare(popup, "lateralRevealProgress", 0)
        tryCompare(loader(), "item", null)
        compare(model.count, 0)
        compare(popup.width, initialWidth)
        tryVerify(function() { return findChild(popup, "folderPopupPointer-" + findChild(popup, "folderPopupGridView").currentIndex).activeFocus })
    }
    function test_reverse_without_geometry_jump() {
        popup.animationStyle = "scale"
        enter("one")
        tryVerify(function() { return popup.lateralRevealProgress > 0 && popup.lateralRevealProgress < 1 })
        const openingWidth = popup.width
        const child = loader().item
        popup.navigationController.back()
        fuzzyCompare(popup.width, openingWidth, 1)
        compare(loader().item, child)
        const closingWidth = popup.width
        enter("one")
        fuzzyCompare(popup.width, closingWidth, 1)
        compare(loader().item, child)
        tryCompare(popup, "lateralRevealProgress", 1)
        verifyCloseEdge()
        tryVerify(function() { return findChild(child, "folderPopupPointer-" + findChild(child, "folderPopupGridView").currentIndex).activeFocus })
    }
    function test_cancel_mid_transition() {
        popup.animationStyle = "scale"
        enter("one")
        tryVerify(function() { return popup.lateralRevealProgress > 0 && popup.lateralRevealProgress < 1 })
        popup.sessionActive = false
        compare(popup.navigationController.childModel.count, 0)
        tryCompare(loader(), "active", false)
        tryCompare(popup, "lateralRevealProgress", 0)
        popup.sessionActive = true
        settle(popup.navigationController.rootModel)
        enter("empty")
        tryCompare(popup, "lateralRevealProgress", 1)
        settle(popup.navigationController.childModel)
        compare(loader().item.itemCount, 0)
        verifyCloseEdge()
    }
    function test_disable_motion_mid_transition() {
        popup.animationStyle = "scale"
        enter("one")
        tryVerify(function() { return popup.lateralRevealProgress > 0 && popup.lateralRevealProgress < 1 })
        popup.animationStyle = "none"
        compare(popup.lateralRevealProgress, 1)
        verifyCloseEdge()
        popup.animationStyle = "scale"
        compare(popup.lateralRevealProgress, 1)
        popup.animationStyle = "none"
        popup.navigationController.back()
        compare(popup.lateralRevealProgress, 0)
        tryCompare(loader(), "active", false)
    }
    function test_theme_motion_contract() {
        // The instant CTest registration selects this function alone; the
        // animated registration executes the complete case. Check the actual
        // theme duration so a fixture that fails to apply its profile cannot pass.
        const instantProfile = Qt.application.arguments.indexOf(
            "FolderNavigationCloseMotion::test_theme_motion_contract") >= 0
        if (instantProfile) {
            compare(Kirigami.Units.longDuration, 1)
        } else {
            verify(Kirigami.Units.longDuration > 1)
        }
        popup.animationStyle = "scale"
        enter("empty")
        if (Kirigami.Units.longDuration <= 1) {
            compare(popup.navigationMotionEnabled, false)
            compare(popup.lateralRevealProgress, 1)
            verifyCloseEdge()
            popup.navigationController.back()
            compare(popup.lateralRevealProgress, 0)
        } else {
            compare(popup.navigationMotionEnabled, true)
            tryVerify(function() { return popup.lateralRevealProgress > 0 && popup.lateralRevealProgress < 1 })
            verifyCloseEdge()
            tryCompare(popup, "lateralRevealProgress", 1)
        }
    }
    function test_narrow_switch_and_empty() {
        enter("empty")
        settle(popup.navigationController.childModel)
        verifyCloseEdge()
        popup.maximumAvailableWidth = 350
        compare(popup.narrowNavigation, true)
        compare(popup.lateralRevealProgress, 0)
        tryCompare(loader(), "active", false)
        verifyCloseEdge()
        compare(popup.itemCount, 0)
        popup.maximumAvailableWidth = 1000
        compare(popup.lateralRevealProgress, 1)
        verifyCloseEdge()
        compare(loader().item.headerTitle, popup.navigationController.breadcrumb)
    }
}
