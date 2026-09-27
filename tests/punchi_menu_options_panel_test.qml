// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtTest
import "../contents/ui/config" as Config
import "../contents/ui/config/components" as ConfigComponents

// Behaviour of the PunchiMenu options panel and its parity with the dialog that
// hosts it.
//
// The panel is a passive component: it receives through its properties the values
// it shows and announces through its signals what the user asked for. The
// activation of the combo is simulated by emitting the signal the control itself
// emits when the user picks an item—which is the exact contract the panel
// responds to—and one case also clicks the control to prove it is really
// interactive.
TestCase {
    id: testCase

    name: "PunchiMenuOptionsPanel"
    when: windowShown

    SignalSpy {
        id: panelModeSpy
        signalName: "menuModeSelected"
    }

    SignalSpy {
        id: panelIconSpy
        signalName: "iconPickerRequested"
    }

    SignalSpy {
        id: dialogModeSpy
        signalName: "menuModeSelected"
    }

    SignalSpy {
        id: dialogIconSpy
        signalName: "iconPickerRequested"
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

            Config.PunchiMenuOptionsPanel {
                id: optionsPanel
                anchors.left: parent.left
                anchors.top: parent.top
                width: 420
            }

            ConfigComponents.PunchiMenuDialog {
                id: modeDialog
                width: 420
            }
        }
    }

    readonly property var expectedValues: ["fullScreen", "normal", "compact"]

    function init() {
        failOnWarning(/.?/)
        panelModeSpy.clear()
        panelIconSpy.clear()
        dialogModeSpy.clear()
        dialogIconSpy.clear()
    }

    function panelCombo(panel) {
        return findChild(panel, "punchiMenuModeCombo")
    }

    function panelIconButton(panel) {
        return findChild(panel, "punchiMenuIconButton")
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
        compare(optionTexts(panel), ["Full screen", "Normal", "Compact"],
            "The visible texts of the modes live in the panel")
        compare(optionValues(dialog), optionValues(panel),
            "The dialog must not keep a second list of modes")
        compare(optionTexts(dialog), optionTexts(panel),
            "The dialog must not keep a second copy of the texts")
        compare(panel.menuMode, "normal", "The default mode is the one of a new item")
        compare(panel.iconName, "start-here-kde",
            "The default icon is the one of a new item")
    }

    function test_externalValueMovesTheSelectionWithoutAnnouncing() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel
        panelModeSpy.target = panel
        const combo = panelCombo(panel)
        verify(combo !== null)

        compare(combo.currentIndex, panel.modeIndex("normal"))

        panel.menuMode = "compact"
        compare(combo.currentIndex, 2,
            "A value set from outside must reach the shown selection")
        compare(panelModeSpy.count, 0,
            "A value set from outside is not a choice of the user")

        panel.menuMode = "fullScreen"
        compare(combo.currentIndex, 0)
        compare(panelModeSpy.count, 0)

        panel.menuMode = "unsupported"
        compare(combo.currentIndex, 0,
            "An unknown mode falls back to the first entry of the panel")
        compare(panelModeSpy.count, 0)
    }

    function test_userActivationAnnouncesExactlyOneIntention() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel
        panelModeSpy.target = panel
        const combo = panelCombo(panel)

        combo.activated(2)
        compare(panelModeSpy.count, 1, "One activation, one intention")
        compare(panelModeSpy.signalArguments[0][0], "compact")
        compare(panel.menuMode, "normal",
            "The panel writes nothing: the value belongs to its caller")

        combo.activated(0)
        compare(panelModeSpy.count, 2)
        compare(panelModeSpy.signalArguments[1][0], "fullScreen")

        panel.menuMode = combo.model[combo.currentIndex].value
        compare(panelModeSpy.count, 2,
            "Following the intention of the caller must not announce it again")
    }

    function test_dialogKeepsItsPublicApiAndForwardsThePanel() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const dialog = host.dialog
        dialogModeSpy.target = dialog
        dialogIconSpy.target = dialog

        compare(dialog.title, "Configure PunchiMenu", "The title is kept")
        compare(dialog.modal, true, "The dialog is still modal")

        dialog.menuMode = "compact"
        dialog.iconName = "folder"
        dialog.selectorWidth = 120
        compare(dialog.menuMode, "compact")
        compare(dialog.iconName, "folder")
        compare(dialog.selectorWidth, 120)
        compare(dialog.modeIndex("fullScreen"), 0,
            "The dialog keeps its helper and answers with the list of the panel")
        compare(optionValues(dialog), testCase.expectedValues)

        dialog.open()
        tryVerify(function() {
            return dialog.visible
        }, 2000, "The dialog must open")
        const combo = panelCombo(dialog)
        verify(combo !== null, "The dialog must host the panel")
        compare(combo.currentIndex, 2,
            "Opening must show the mode of the dialog")

        combo.activated(1)
        compare(dialogModeSpy.count, 1,
            "The dialog must forward the intention of the panel exactly once")
        compare(dialogModeSpy.signalArguments[0][0], "normal")
        compare(dialog.menuMode, "normal",
            "The dialog must update its own state with what it forwards")

        const iconButton = panelIconButton(dialog)
        verify(iconButton !== null, "The dialog must host the icon button")
        iconButton.clicked()
        compare(dialogIconSpy.count, 1,
            "The request for an icon must keep being announced once")
        dialog.close()
    }

    function test_reopeningSynchronizesTheShownSelection() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const dialog = host.dialog
        dialogModeSpy.target = dialog

        for (let index = 0; index < 3; index++) {
            dialog.menuMode = testCase.expectedValues[index]
            dialog.open()
            tryVerify(function() {
                return dialog.visible
            }, 2000, "The dialog must open")
            const combo = panelCombo(dialog)
            verify(combo !== null)
            compare(combo.currentIndex, dialog.modeIndex(dialog.menuMode),
                "Opening must show the mode it was given")
            dialog.close()
            tryVerify(function() {
                return !dialog.visible
            }, 2000, "The dialog must close")
        }

        compare(dialogModeSpy.count, 0,
            "Showing a value must never be announced as a choice")
    }

    function test_controlsStayInteractiveAndAccessible() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel
        panelModeSpy.target = panel
        panelIconSpy.target = panel

        const combo = panelCombo(panel)
        const iconButton = panelIconButton(panel)
        verify(combo !== null)
        verify(iconButton !== null)
        compare(combo.Accessible.name, "PunchiMenu display mode",
            "The mode control keeps its accessible name")
        compare(iconButton.Accessible.name, "Choose PunchiMenu icon")
        verify(String(iconButton.Accessible.description).length > 0,
            "The icon button must describe the current icon")
        compare(combo.activeFocusOnTab, true,
            "The mode control stays reachable with the keyboard")

        mouseClick(combo)
        wait(20)
        verify(combo.popup.visible,
            "A click must open the list of modes")
        combo.popup.close()
        wait(20)
        compare(panelModeSpy.count, 0,
            "Opening the list is not a choice yet")

        mouseClick(iconButton)
        compare(panelIconSpy.count, 1,
            "A real click on the icon button must ask for the icon picker once")
    }
}
