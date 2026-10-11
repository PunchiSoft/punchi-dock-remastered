// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtCore
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase
    name: "FolderPopupVisibleFocus"
    when: windowShown
    visible: true
    width: 1000
    height: 700

    property var popup: null

    Controls.Button {
        id: focusSink
        text: "Focus sink"
    }

    Component {
        id: popupComponent
        Components.FolderPopup {
            x: 150
            y: 80
            animationStyle: "none"
            revealProgress: 1
            profileScale: 1
            profileColumns: 2
            profileAutoLayout: false
            folderItem: ({name: "Applications", apps: [
                {name: "First", icon: "folder", command: "first"},
                {name: "Second", icon: "folder", command: "second"}
            ]})
        }
    }

    SignalSpy { id: launchSpy; target: testCase.popup; signalName: "appLaunched" }

    function modes() {
        return [{tag: "grid", mode: "grid"}, {tag: "list", mode: "list"},
            {tag: "detail", mode: "detailed"}]
    }

    function entry(index) {
        let control = null
        tryVerify(function() {
            control = findChild(popup, "folderPopupPointer-" + index)
            return control !== null
        })
        return control
    }

    function highlight(index) {
        return findChild(popup, "folderPopupHighlight-" + index)
    }

    function open(mode) {
        popup = popupComponent.createObject(testCase, {layoutMode: mode})
        verify(popup !== null)
        waitForRendering(popup)
        entry(0)
        entry(1)
        focusSink.forceActiveFocus(Qt.OtherFocusReason)
        mouseMove(focusSink, 5, 5)
        launchSpy.clear()
    }

    function init() { failOnWarning(/.?/) }

    function cleanup() {
        focusSink.forceActiveFocus(Qt.OtherFocusReason)
        if (popup) {
            popup.destroy()
            popup = null
        }
        wait(0)
    }

    function test_automaticFocusDoesNotCompeteWithHover_data() { return modes() }
    function test_automaticFocusDoesNotCompeteWithHover(data) {
        open(data.mode)
        const first = entry(0)
        const second = entry(1)
        for (const reason of [Qt.PopupFocusReason, Qt.MouseFocusReason, Qt.OtherFocusReason]) {
            focusSink.forceActiveFocus(Qt.OtherFocusReason)
            first.forceActiveFocus(reason)
            tryCompare(first, "activeFocus", true)
            compare(highlight(0).focused, false)
            compare(highlight(0).border.width, 0)
            mouseMove(second, second.width / 2, second.height / 2)
            tryCompare(highlight(1), "hovered", true)
            compare(first.activeFocus, true, "Hover must preserve the logical focus")
            compare(highlight(0).hovered, false)
            compare(highlight(0).border.width, 0)
            compare(highlight(1).border.width, 0)
        }
        mouseClick(second, second.width / 2, second.height / 2)
        compare(launchSpy.count, 1)
        compare(launchSpy.signalArguments[0][0].name, "Second")
    }

    function test_tabAndArrowsKeepVisibleKeyboardFocus_data() { return modes() }
    function test_tabAndArrowsKeepVisibleKeyboardFocus(data) {
        open(data.mode)
        const first = entry(0)
        const second = entry(1)
        for (let step = 0; step < 6 && !first.activeFocus; ++step) {
            keyClick(Qt.Key_Tab)
        }
        tryCompare(first, "activeFocus", true)
        compare(highlight(0).focused, true)
        compare(highlight(0).border.width, 2)
        keyClick(Qt.Key_Down)
        tryCompare(second, "activeFocus", true)
        compare(highlight(1).border.width, 2)
        compare(highlight(0).border.width, 0)
        keyClick(Qt.Key_Up)
        tryCompare(first, "activeFocus", true)
        compare(highlight(0).border.width, 2)
        mouseMove(second, second.width / 2, second.height / 2)
        tryCompare(highlight(1), "hovered", true)
        compare(highlight(0).border.width, 2, "Real keyboard focus remains visible beside hover")
        keyClick(Qt.Key_Return)
        compare(launchSpy.count, 1)
        compare(launchSpy.signalArguments[0][0].name, "First")
    }

    function test_restorePreservesTheInputReason_data() { return modes() }

    function test_horizontalGridArrowsKeepVisibleFocus() {
        open("grid")
        entry(0).forceActiveFocus(Qt.OtherFocusReason)
        keyClick(Qt.Key_Right)
        tryCompare(entry(1), "activeFocus", true)
        compare(highlight(1).border.width, 2)
        keyClick(Qt.Key_Left)
        tryCompare(entry(0), "activeFocus", true)
        compare(highlight(0).border.width, 2)
    }

    function test_restorePreservesTheInputReason(data) {
        open(data.mode)
        popup.restoreView(0, 0)
        tryCompare(entry(0), "activeFocus", true)
        compare(highlight(0).border.width, 0)
        popup.restoreView(1, 0, Qt.TabFocusReason)
        tryCompare(entry(1), "activeFocus", true)
        compare(highlight(1).border.width, 2)
        popup.restoreView(0, 0, Qt.MouseFocusReason)
        tryCompare(entry(0), "activeFocus", true)
        compare(highlight(0).border.width, 0)
        compare(highlight(1).border.width, 0)
    }

    function test_directoryEntryAndBackPreserveVisibleFocus_data() {
        const rows = []
        for (const mode of ["list", "detailed"]) {
            for (const width of [350, 1000]) {
                for (const keyboard of [false, true]) {
                    rows.push({tag: mode + "-" + width + "-" + keyboard,
                        mode: mode, width: width, keyboard: keyboard})
                }
            }
        }
        return rows
    }

    function test_directoryEntryAndBackPreserveVisibleFocus(data) {
        const fixture = StandardPaths.writableLocation(StandardPaths.RuntimeLocation) + "/navigation"
        popup = popupComponent.createObject(testCase, {
            layoutMode: data.mode, maximumAvailableWidth: data.width,
            folderItem: {name: "Fixture", sourceType: "folder", sourcePath: fixture,
                browseSubfolders: true, apps: []}
        })
        verify(popup !== null)
        tryCompare(popup.navigationController.rootModel, "loading", false)
        compare(popup.navigationController.rootModel.error, "")
        let directoryIndex = -1
        for (let index = 0; index < popup.directoryModel.count; ++index) {
            if (popup.directoryModel.get(index).name === "one") { directoryIndex = index }
        }
        verify(directoryIndex >= 0)
        const grid = findChild(popup, "folderPopupGridView")
        grid.positionViewAtIndex(directoryIndex, GridView.Contain)
        const directory = entry(directoryIndex)
        waitForRendering(directory)
        if (data.keyboard) {
            directory.forceActiveFocus(Qt.OtherFocusReason)
            keyClick(Qt.Key_Return)
        } else {
            mouseClick(directory, directory.width / 2, directory.height / 2)
        }
        tryCompare(popup, "navigationDepth", 1)
        tryCompare(popup.navigationController.childModel, "loading", false)
        const loader = findChild(popup, "folderNavigationPaneLoader")
        if (data.width === 1000) { tryVerify(function() { return loader.item !== null }) }
        const child = data.width === 1000 ? loader.item : popup
        const childGrid = findChild(child, "folderPopupGridView")
        let childControl = null
        tryVerify(function() {
            childControl = findChild(child, "folderPopupPointer-" + childGrid.currentIndex)
            return childControl !== null && childControl.activeFocus
        })
        const childHighlight = findChild(child, "folderPopupHighlight-" + childGrid.currentIndex)
        compare(childHighlight.focused, data.keyboard)
        if (data.keyboard) {
            keyClick(Qt.Key_Left)
        } else {
            mouseClick(findChild(child, "folderNavigationBack"))
        }
        tryCompare(popup, "navigationDepth", 0)
        tryCompare(entry(directoryIndex), "activeFocus", true)
        compare(highlight(directoryIndex).focused, data.keyboard)
    }
}
