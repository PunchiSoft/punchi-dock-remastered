// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtTest
import "../contents/ui/config" as Config
import "../contents/ui/config/components" as ConfigComponents

// Behaviour of the Control Center options panel and its parity with the dialog
// that hosts it.
//
// The panel is a passive component: it receives through its property the value it
// shows and announces through its signal what the user asked for. The activation
// of the combo is simulated by emitting the signal the control itself emits when
// the user picks an item—which is the exact contract the panel responds to—and
// one case also clicks the control to prove it is really interactive.
TestCase {
    id: testCase

    name: "ControlCenterOptionsPanel"
    when: windowShown

    SignalSpy {
        id: panelSpy
        signalName: "controlCenterModeSelected"
    }

    SignalSpy {
        id: dialogSpy
        signalName: "controlCenterModeSelected"
    }

    Component {
        id: windowComponent

        Window {
            id: hostWindow

            property alias panel: optionsPanel
            property alias dialog: modeDialog

            width: 640
            height: 360
            visible: true

            Config.ControlCenterOptionsPanel {
                id: optionsPanel
                anchors.left: parent.left
                anchors.top: parent.top
                width: 420
            }

            ConfigComponents.ControlCenterDialog {
                id: modeDialog
                width: 420
            }
        }
    }

    readonly property var expectedValues: ["fullScreen", "floating"]

    function init() {
        failOnWarning(/.?/)
        panelSpy.clear()
        dialogSpy.clear()
    }

    function panelCombo(panel) {
        return findChild(panel, "controlCenterModeCombo")
    }

    function optionValues(panel) {
        return panel.modeOptions.map(function(option) {
            return String(option.value)
        })
    }

    function optionTexts(panel) {
        return panel.modeOptions.map(function(option) {
            return String(option.text)
        })
    }

    function test_panelAndDialogShowTheSameModes() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel
        const dialog = host.dialog

        compare(optionValues(panel), testCase.expectedValues,
            "The panel owns the list of modes")
        compare(optionTexts(panel), ["Full screen", "Floating"],
            "The visible texts of the modes live in the panel")
        compare(optionValues(dialog), optionValues(panel),
            "The dialog must not keep a second list of modes")
        compare(optionTexts(dialog), optionTexts(panel),
            "The dialog must not keep a second copy of the texts")
        compare(panel.controlCenterMode, "floating",
            "The default mode is the one of a new item")
    }

    function test_externalValueMovesTheSelectionWithoutAnnouncing() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel
        panelSpy.target = panel
        const combo = panelCombo(panel)
        verify(combo !== null)

        compare(combo.currentIndex, panel.modeIndex("floating"))

        panel.controlCenterMode = "fullScreen"
        compare(combo.currentIndex, 0,
            "A value set from outside must reach the shown selection")
        compare(panelSpy.count, 0,
            "A value set from outside is not a choice of the user")

        panel.controlCenterMode = "unsupported"
        compare(combo.currentIndex, 1,
            "An unknown mode falls back to the default of the panel")
        compare(panelSpy.count, 0)
    }

    function test_userActivationAnnouncesExactlyOneIntention() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel
        panelSpy.target = panel
        const combo = panelCombo(panel)

        combo.activated(0)
        compare(panelSpy.count, 1, "One activation, one intention")
        compare(panelSpy.signalArguments[0][0], "fullScreen")
        compare(panel.controlCenterMode, "floating",
            "The panel writes nothing: the value belongs to its caller")

        panel.controlCenterMode = "fullScreen"
        compare(panelSpy.count, 1,
            "Following the intention of the caller must not announce it again")
    }

    function test_dialogKeepsItsPublicApiAndForwardsThePanel() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const dialog = host.dialog
        dialogSpy.target = dialog

        compare(dialog.objectName, "controlCenterConfigDialog",
            "The object name the page tracks is kept")
        compare(dialog.title, "Configure Control Center", "The title is kept")
        compare(dialog.modal, true, "The dialog is still modal")

        dialog.controlCenterMode = "fullScreen"
        dialog.selectorWidth = 120
        compare(dialog.controlCenterMode, "fullScreen")
        compare(dialog.selectorWidth, 120)
        compare(dialog.modeIndex("fullScreen"), 0,
            "The dialog keeps its helper and answers with the list of the panel")
        compare(dialog.modeIndex("unknown"), 1)
        compare(optionValues(dialog), testCase.expectedValues)

        dialog.open()
        tryVerify(function() {
            return dialog.visible
        }, 2000, "The dialog must open")
        const combo = panelCombo(dialog)
        verify(combo !== null, "The dialog must host the panel")
        compare(combo.currentIndex, 0,
            "Opening must show the mode of the dialog")

        combo.activated(1)
        compare(dialogSpy.count, 1,
            "The dialog must forward the intention of the panel exactly once")
        compare(dialogSpy.signalArguments[0][0], "floating")
        compare(dialog.controlCenterMode, "floating",
            "The dialog must update its own state with what it forwards")

        dialog.controlCenterMode = "fullScreen"
        dialog.synchronizeModeSelection()
        compare(combo.currentIndex, 0,
            "The synchronization helper keeps working through the panel")
        compare(dialogSpy.count, 1)
        dialog.close()
    }

    function test_reopeningSynchronizesTheShownSelection() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const dialog = host.dialog
        dialogSpy.target = dialog

        for (let index = 0; index < testCase.expectedValues.length; index++) {
            dialog.controlCenterMode = testCase.expectedValues[index]
            dialog.open()
            tryVerify(function() {
                return dialog.visible
            }, 2000, "The dialog must open")
            const combo = panelCombo(dialog)
            verify(combo !== null)
            compare(combo.currentIndex, dialog.modeIndex(dialog.controlCenterMode),
                "Opening must show the mode it was given")
            dialog.close()
            tryVerify(function() {
                return !dialog.visible
            }, 2000, "The dialog must close")
        }

        compare(dialogSpy.count, 0,
            "Showing a value must never be announced as a choice")
    }

    function test_controlsStayInteractiveAndAccessible() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel
        panelSpy.target = panel

        const combo = panelCombo(panel)
        verify(combo !== null)
        compare(combo.Accessible.name, "Control Center display mode",
            "The mode control keeps its accessible name")
        compare(combo.activeFocusOnTab, true,
            "The mode control stays reachable with the keyboard")

        mouseClick(combo)
        wait(20)
        verify(combo.popup.visible, "A click must open the list of modes")
        combo.popup.close()
        wait(20)
        compare(panelSpy.count, 0, "Opening the list is not a choice yet")
    }
}
