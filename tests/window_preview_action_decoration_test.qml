// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase
    name: "WindowPreviewActionDecoration"
    when: windowShown
    visible: true
    width: 640
    height: 480

    readonly property string fixturePath: Qt.resolvedUrl("fixtures/decoration-close.svg")
        .toString().replace("file://", "")

    Component {
        id: decoratedButton
        Components.WindowPreviewActionButton {
            x: 30
            y: 30
            text: "Close window"
            icon.name: "window-close"
            icon.width: 16
            icon.height: 16
            decorationRole: "close"
            decorationImagePath: testCase.fixturePath
            decorationButtonSize: Qt.size(16, 16)
        }
    }
    Component {
        id: fallbackButton
        Components.WindowPreviewActionButton {
            x: 30
            y: 30
            text: "Minimize window"
            icon.name: "go-down"
            icon.width: 16
            icon.height: 16
            decorationRole: "minimize"
        }
    }
    Component {
        id: inactiveWindowButton
        Components.WindowPreviewActionButton {
            x: 30
            y: 30
            text: "Minimize window"
            icon.name: "go-down"
            icon.width: 16
            icon.height: 16
            decorationRole: "minimize"
            decorationImagePath: testCase.fixturePath
            decorationButtonSize: Qt.size(16, 16)
            decorationActive: false
        }
    }
    SignalSpy { id: clickSpy; signalName: "clicked" }
    SignalSpy { id: activateSpy; signalName: "activateRequested" }

    Component {
        id: cardComponent
        Components.WindowPreviewCard {
            width: 320
            height: 240
            liveThumbnailEnabled: false
            windowData: ({
                "row": 0, "title": "Fixture window", "active": true,
                "minimizable": true, "minimized": false,
                "maximizable": true, "maximized": true, "closable": true
            })
        }
    }

    function initTestCase() {
        nativePopupTestSupport.allowNativePopupPlatformWarnings()
    }

    function expectPrefix(button, prefix, message) {
        tryCompare(button, "renderedPrefix", prefix, 5000, message)
    }

    function init() {
        failOnWarning(/.?/)
        mouseMove(testCase, 620, 450)
        clickSpy.target = null
        clickSpy.clear()
        activateSpy.target = null
        activateSpy.clear()
    }

    function test_pointerStatesUseTheActiveResource() {
        const button = createTemporaryObject(decoratedButton, testCase)
        verify(button !== null)
        tryCompare(button, "usingDecoration", true)
        expectPrefix(button, "active", "The resting window is active")
        compare(button.contentItem.implicitWidth, 16,
            "The decoration button size must govern the glyph")
        verify(Qt.colorEqual(button.background.color, "transparent"),
            "The decoration brings its own background")
        button.forceActiveFocus(Qt.TabFocusReason)
        compare(button.renderedPrefix, "active", "Keyboard focus is not hover")
        mouseMove(button, button.width / 2, button.height / 2)
        expectPrefix(button, "hover", "Entering the control shows the hover resource")
        mousePress(button, button.width / 2, button.height / 2)
        expectPrefix(button, "pressed", "Pressing shows the pressed resource")
        mouseRelease(button, button.width / 2, button.height / 2)
        expectPrefix(button, "hover", "Releasing the pointer keeps the hover resource")
        mouseMove(testCase, 620, 450)
        expectPrefix(button, "active", "Leaving the control restores the rest state")
    }

    function test_inactiveWindowKeepsItsRestAndHoversActively() {
        const button = createTemporaryObject(inactiveWindowButton, testCase)
        verify(button !== null)
        tryCompare(button, "usingDecoration", true)
        expectPrefix(button, "inactive",
            "At rest the glyph respects the window's inactive state")
        button.forceActiveFocus(Qt.TabFocusReason)
        compare(button.renderedPrefix, "inactive",
            "Keyboard focus must not simulate hover")
        mouseMove(button, button.width / 2, button.height / 2)
        expectPrefix(button, "hover",
            "Hovering an inactive window uses its active hover resource")
        mousePress(button, button.width / 2, button.height / 2)
        expectPrefix(button, "pressed", "A pointer press reads as active")
        mouseRelease(button, button.width / 2, button.height / 2)
        expectPrefix(button, "hover", "Releasing keeps the active hover resource")
        mouseMove(testCase, 620, 450)
        expectPrefix(button, "inactive",
            "Leaving the control returns to the rest state")
        button.enabled = false
        expectPrefix(button, "deactivated-inactive",
            "A disabled control keeps the deactivated resource")
        mouseMove(button, button.width / 2, button.height / 2)
        expectPrefix(button, "deactivated-inactive",
            "A disabled control never adopts the hover resource")
    }

    function test_missingResourceKeepsThePlasmaControl() {
        const button = createTemporaryObject(fallbackButton, testCase)
        verify(button !== null)
        compare(button.usingDecoration, false)
        compare(button.decorationImagePath, "")
        mouseMove(button, button.width / 2, button.height / 2)
        verify(button.highlightedContent)
        wait(200)
        verify(!Qt.colorEqual(button.background.color, "transparent"),
            "The Plasma highlight fill must remain for the fallback")
        compare(button.icon.name, "go-down",
            "The functional icon must survive the refactor")
    }

    function test_actionAndAccessibilitySurvive() {
        const button = createTemporaryObject(decoratedButton, testCase)
        verify(button !== null)
        clickSpy.target = button
        mouseClick(button, button.width / 2, button.height / 2)
        compare(clickSpy.count, 1)
        button.forceActiveFocus(Qt.TabFocusReason)
        verify(button.highlightedContent,
            "Keyboard focus must keep highlighting the control")
        compare(String(button.Accessible.name), "Close window")
    }

    function test_cardRoutesTheRoleFromTheWindowState() {
        const card = createTemporaryObject(cardComponent, testCase)
        verify(card !== null)
        const minimize = findChild(card, "previewMinimizeButton")
        const maximize = findChild(card, "previewMaximizeButton")
        const close = findChild(card, "previewCloseButton")
        verify(minimize && maximize && close)
        compare(findChild(card, "previewPresentButton"), null,
            "The separate bring-to-front control must stay removed")
        compare(minimize.decorationRole, "minimize")
        compare(maximize.decorationRole, "restore",
            "A maximized window must offer the restore glyph")
        compare(close.decorationRole, "close")
        verify(minimize.decorationActive, "The window is active in the decoration")
        compare(maximize.x, minimize.x + minimize.width + 2,
            "The row must not keep an empty slot for the removed control")
        compare(close.x, maximize.x + maximize.width + 2,
            "The remaining controls must stay adjacent")
        card.windowData = ({
            "row": 0, "title": "Fixture window", "active": true,
            "minimizable": true, "minimized": true,
            "maximizable": true, "maximized": false, "closable": true
        })
        compare(minimize.decorationRole, "restore",
            "A minimized window must offer the restore glyph")
        compare(maximize.decorationRole, "maximize")
    }

    function test_pointerHoverDoesNotActivateTheWindow() {
        const card = createTemporaryObject(cardComponent, testCase)
        verify(card !== null)
        card.windowData = ({
            "row": 0, "title": "Fixture window", "active": false,
            "minimizable": true, "minimized": false,
            "maximizable": true, "maximized": false, "closable": true
        })
        activateSpy.target = card
        activateSpy.clear()
        const close = findChild(card, "previewCloseButton")
        verify(close !== null)
        mouseMove(card, card.width / 2, card.height / 2)
        mouseMove(close, close.width / 2, close.height / 2)
        wait(150)
        compare(activateSpy.count, 0, "Pointing must not activate the window")
        compare(card.windowData.active, false,
            "The window state must not change while pointing")
    }
}
