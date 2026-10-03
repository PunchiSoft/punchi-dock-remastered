// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase
    name: "DecorationCloseButton"
    when: windowShown
    visible: true
    width: 640
    height: 480

    Component {
        id: buttonComponent
        Components.DecorationCloseButton {
            x: 30
            y: 30
            decorationImagePath: Qt.resolvedUrl("fixtures/decoration-close.svg").toString().replace("file://", "")
            decorationActive: true
        }
    }
    Component {
        id: folderComponent
        Components.FolderPopup {
            profileScale: 1
            folderItem: ({name: "Fixture folder", apps: []})
        }
    }
    SignalSpy { id: clickSpy; signalName: "clicked" }
    SignalSpy { id: closeSpy; signalName: "closeRequested" }

    function init() {
        failOnWarning(/.?/)
        mouseMove(testCase, 620, 450)
        clickSpy.target = null
        clickSpy.clear()
        closeSpy.target = null
        closeSpy.clear()
    }

    function test_statesAndKeyboardFocusAreSeparate() {
        const button = createTemporaryObject(buttonComponent, testCase)
        verify(button !== null)
        tryCompare(button, "usingDecoration", true)
        tryCompare(button, "renderedPrefix", "active")
        button.forceActiveFocus(Qt.TabFocusReason)
        verify(button.visualFocus)
        compare(button.renderedPrefix, "active", "Keyboard focus is not hover")
        mouseMove(button, button.width / 2, button.height / 2)
        tryCompare(button, "renderedPrefix", "hover")
        mousePress(button, button.width / 2, button.height / 2)
        tryCompare(button, "renderedPrefix", "pressed")
        mouseRelease(button, button.width / 2, button.height / 2)
        button.decorationActive = false
        tryCompare(button, "renderedPrefix", "hover-inactive")
        mouseMove(testCase, 620, 450)
        tryCompare(button, "renderedPrefix", "inactive")
        button.enabled = false
        tryCompare(button, "renderedPrefix", "deactivated-inactive")
    }

    function test_clickAndKeyboardActivateExactlyOnce() {
        const button = createTemporaryObject(buttonComponent, testCase)
        verify(button !== null)
        clickSpy.target = button
        mouseClick(button, button.width / 2, button.height / 2)
        compare(clickSpy.count, 1)
        button.forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_Return)
        compare(clickSpy.count, 2)
        keyClick(Qt.Key_Space)
        compare(clickSpy.count, 3)
    }

    function test_missingResourceUsesFunctionalFallback() {
        const button = createTemporaryObject(buttonComponent, testCase)
        verify(button !== null)
        tryCompare(button, "usingDecoration", true)
        button.decorationImagePath = ""
        tryCompare(button, "usingDecoration", false)
        clickSpy.target = button
        mouseClick(button, button.width / 2, button.height / 2)
        compare(clickSpy.count, 1)
        button.decorationImagePath = Qt.resolvedUrl("fixtures/decoration-close.svg").toString().replace("file://", "")
        tryCompare(button, "usingDecoration", true)
    }

    function test_allClassicLayoutsCloseAndRecreate_data() {
        return [{tag: "grid", mode: "grid"}, {tag: "list", mode: "list"},
            {tag: "detailed", mode: "detailed"}]
    }
    function test_allClassicLayoutsCloseAndRecreate(data) {
        for (let cycle = 0; cycle < 3; cycle++) {
            const folder = folderComponent.createObject(testCase, {layoutMode: data.mode})
            verify(folder !== null)
            const button = findChild(folder, "folderPopupCloseButton")
            verify(button !== null)
            button.decorationImagePath = Qt.resolvedUrl("fixtures/decoration-close.svg").toString().replace("file://", "")
            button.decorationActive = true
            tryCompare(button, "usingDecoration", true)
            closeSpy.target = folder
            closeSpy.clear()
            mouseClick(button, button.width / 2, button.height / 2)
            compare(closeSpy.count, 1)
            button.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Return)
            compare(closeSpy.count, 2)
            closeSpy.target = null
            folder.destroy()
            wait(0)
        }
    }
}
