// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtTest
import "../contents/ui/config" as Config

// Integration of the calendar options panel with the «Add item» dialog.
//
// The dialog resolves the editor key the catalogue names for the drafted type—one
// key and one map only—and loads the panel for the calendar. The panel is filled by
// the dialog without announcing anything, and what the user does is written into the
// draft through the controller, which applies the canonical rules of
// `configItems.js`. Accepting is the only path that delivers the element, so
// cancelling and changing type must leave no value of the panel behind.
TestCase {
    id: testCase

    name: "ItemConfigurationCalendarPanel"
    when: windowShown

    Config.ItemDraftController {
        id: controller

        items: []
    }

    Config.ItemConfigurationDialog {
        id: dialog

        draftController: controller
    }

    SignalSpy {
        id: acceptedSpy
        target: controller
        signalName: "itemAccepted"
    }

    SignalSpy {
        id: colorSpy
        target: dialog
        signalName: "colorPickerRequested"
    }

    function init() {
        failOnWarning(/.?/)
        controller.items = []
        controller.cancel()
        acceptedSpy.clear()
        colorSpy.clear()
        waitForEmptyTree()
    }

    function calendarPanel() {
        return findChild(dialog, "itemConfigurationCalendarPanel")
    }

    function waitForEmptyTree() {
        tryVerify(function() {
            return calendarPanel() === null
        }, 2000, "No calendar panel may stay in the tree")
    }

    function openFor(type) {
        dialog.openFor(type)
        tryVerify(function() {
            return dialog.opened
        }, 2000, "The dialog must open")
    }

    function control(objectName) {
        const panel = calendarPanel()
        return panel === null ? null : findChild(panel, objectName)
    }

    function draftValue(name) {
        return controller.draft === null ? undefined : controller.draft[name]
    }

    function colorMode() {
        const panel = calendarPanel()
        return panel === null ? null : findChild(panel, "timedTextColorControl")
    }

    function test_thePanelIsLoadedOnlyForTheCalendar() {
        openFor("calendar")
        const panel = calendarPanel()
        verify(panel !== null, "The calendar must load its options panel")
        compare(dialog.editorKey, "calendar-options",
            "The catalogue keeps a single key for this editor")
        compare(String(panel.selectedItemType), "calendar",
            "The new dialog only builds calendars")

        dialog.cancelDraft()
        tryVerify(function() {
            return !dialog.opened
        })
        waitForEmptyTree()

        openFor("app")
        compare(calendarPanel(), null,
            "A type without this panel must not load it")
        dialog.cancelDraft()
        tryVerify(function() {
            return !dialog.opened
        })
        waitForEmptyTree()

        openFor("trash")
        compare(calendarPanel(), null,
            "Another type with its own panel must not load the calendar one")
    }

    function test_initialSynchronizationIsNotAnEdit() {
        openFor("calendar")
        const panel = calendarPanel()
        verify(panel !== null)
        compare(controller.draftEdited, false,
            "Showing the draft must not mark it as edited")

        compare(String(panel.itemNameControl.text), "Calendar",
            "The panel shows the name of the draft")
        compare(String(panel.calendarFormatControl.editText), "HH:mm")
        compare(Number(panel.calendarTimeTextScaleControl.value), 1.0,
            "An absent scale reads as its canonical default")
        compare(Number(panel.calendarDateTextScaleControl.value), 1.0)
        compare(panel.calendarTextShadowsControl.checked, true,
            "Shadows are on unless the element says otherwise")
        compare(panel.calendarShowWeekNumbersControl.checked, true)
        compare(Number(panel.calendarPopupScaleControl.value), 1.0)
        compare(String(panel.calendarTextColorControl.text), "",
            "Without a chosen colour the theme applies")
    }

    function test_aRealEditWritesTheDraftWithCanonicalRules() {
        openFor("calendar")
        const panel = calendarPanel()
        const revision = controller.draftRevision

        const nameField = findChild(panel, "timedNameField")
        nameField.text = "Mi calendario"
        nameField.editingFinished()
        compare(String(draftValue("name")), "Mi calendario",
            "The panel writes only through the controller")
        compare(controller.draftEdited, true)
        verify(controller.draftRevision > revision)

        const shadows = findChild(panel, "calendarTextShadowsCheckBox")
        shadows.checked = false
        shadows.toggled()
        compare(draftValue("calendarTextShadowsEnabled"), false)

        const weekNumbers = findChild(panel, "calendarShowWeekNumbersCheckBox")
        weekNumbers.checked = false
        weekNumbers.toggled()
        compare(draftValue("showWeekNumbers"), false)

        const timeScale = findChild(panel, "calendarTimeTextScaleSlider")
        timeScale.value = 1.35
        compare(Number(draftValue("timeTextScale")), 1.35)
        const dateScale = findChild(panel, "calendarDateTextScaleSlider")
        dateScale.value = 1.2
        compare(Number(draftValue("dateTextScale")), 1.2)
        const popupScale = findChild(panel, "calendarPopupScaleSlider")
        popupScale.value = 1.45
        compare(Number(draftValue("popupScale")), 1.45)

        // The canonical rule of the type owns the range: the draft is clamped even if
        // a value arrives out of it.
        controller.setDraftValues({"popupScale": 9.0})
        controller.pruneDraft()
        compare(Number(draftValue("popupScale")), 3.0,
            "The canonical rule clamps the popup scale")
        controller.setDraftValues({"timeTextScale": 0.1})
        controller.pruneDraft()
        compare(Number(draftValue("timeTextScale")), 0.75,
            "The canonical rule clamps the text scale")
    }

    function test_theFormatIsPersistedAsWrittenAndAsSelected() {
        openFor("calendar")
        const panel = calendarPanel()
        const format = findChild(panel, "calendarFormatCombo")

        format.editText = "hh:mm AP"
        format.accepted()
        compare(String(draftValue("format")), "hh:mm AP",
            "A written format reaches the draft")

        format.currentIndex = 3
        format.activated(3)
        compare(String(draftValue("format")), "dd/MM/yyyy",
            "A selected format reaches the draft")
        compare(String(format.editText), "dd/MM/yyyy",
            "Selecting an entry writes it into the field")
    }

    function test_theColorRequestStaysAnAnnouncement() {
        openFor("calendar")
        const colorModeControl = colorMode()
        verify(colorModeControl !== null, "The panel must offer the colour control")

        colorModeControl.colorRequested()
        compare(colorSpy.count, 1, "The request must be announced exactly once")
        compare(colorSpy.signalArguments[0][0], "text",
            "The request must name the target the page expects")
        verify(dialog.opened, "The picker is not opened yet")
        compare(controller.draftEdited, false,
            "Asking for a colour is not an edit of the draft")

        controller.setDraftValues({"color": "#ff8800"})
        tryVerify(function() {
            return String(calendarPanel().calendarTextColorControl.text) === "#ff8800"
        }, 2000, "A colour written anywhere must reach the panel")
        const revision = controller.draftRevision
        colorModeControl.themeRequested()
        compare(String(draftValue("color")), "",
            "Returning to the theme clears the value")
        verify(controller.draftRevision > revision,
            "Returning to the theme is one edit")
    }

    function test_cancellingDiscardsTheValuesOfThePanel() {
        const itemsBefore = controller.items
        openFor("calendar")
        const nameField = findChild(calendarPanel(), "timedNameField")
        nameField.text = "Mi calendario"
        nameField.editingFinished()
        findChild(calendarPanel(), "calendarPopupScaleSlider").value = 2.0
        compare(String(draftValue("name")), "Mi calendario")

        dialog.cancelDraft()
        tryVerify(function() {
            return controller.draft === null
        }, 2000, "Cancelling must drop the draft")
        waitForEmptyTree()
        compare(controller.items, itemsBefore,
            "Cancelling must not touch the dock item list")
        compare(acceptedSpy.count, 0)

        openFor("calendar")
        compare(String(draftValue("name")), "Calendar",
            "A new draft must start from the defaults again")
        compare(Number(calendarPanel().calendarPopupScaleControl.value), 1.0)
    }

    function test_changingTypeDiscardsTheValuesOfThePanel() {
        openFor("calendar")
        const nameField = findChild(calendarPanel(), "timedNameField")
        nameField.text = "Mi calendario"
        nameField.editingFinished()
        verify(controller.draftEdited)

        dialog.requestType("trash")
        compare(dialog.pendingTypeChange, "trash",
            "An edited draft must ask before changing type")
        dialog.confirmTypeChange()
        tryVerify(function() {
            return calendarPanel() === null
        }, 2000, "The calendar panel must be gone")

        compare(String(draftValue("type")), "trash")
        verify(draftValue("format") === undefined,
            "No value of the calendar may survive")
        verify(draftValue("popupScale") === undefined)
        compare(String(draftValue("name")), "Trash",
            "The new type must start from its own defaults")
    }

    function test_acceptingDeliversTheValuesOfThePanel() {
        openFor("calendar")
        const panel = calendarPanel()
        const nameField = findChild(panel, "timedNameField")
        nameField.text = "Mi calendario"
        nameField.editingFinished()
        const format = findChild(panel, "calendarFormatCombo")
        format.editText = "dd/MM/yyyy HH:mm"
        format.accepted()
        panel.calendarTextColorControl.text = "#336699"
        findChild(panel, "calendarTimeTextScaleSlider").value = 1.15
        findChild(panel, "calendarDateTextScaleSlider").value = 1.05
        const shadows = findChild(panel, "calendarTextShadowsCheckBox")
        shadows.checked = false
        shadows.toggled()
        const weekNumbers = findChild(panel, "calendarShowWeekNumbersCheckBox")
        weekNumbers.checked = false
        weekNumbers.toggled()
        findChild(panel, "calendarPopupScaleSlider").value = 1.5

        verify(dialog.acceptDraft())
        compare(acceptedSpy.count, 1, "Accepting must announce exactly one element")
        const calendar = acceptedSpy.signalArguments[0][0]
        compare(String(calendar.type), "calendar")
        compare(String(calendar.name), "Mi calendario")
        compare(String(calendar.color), "#336699")
        compare(String(calendar.format), "dd/MM/yyyy HH:mm")
        compare(Number(calendar.timeTextScale), 1.15)
        compare(Number(calendar.dateTextScale), 1.05)
        compare(calendar.calendarTextShadowsEnabled, false)
        compare(calendar.showWeekNumbers, false)
        compare(Number(calendar.popupScale), 1.5)
        verify(calendar.width === undefined && calendar.height === undefined,
            "The calendar must not carry the fields of the clock")
    }

    function test_thePanelSurvivesCreationAndDestruction() {
        const types = ["calendar", "trash", "calendar", "app", "calendar"]
        for (let index = 0; index < types.length; index++) {
            openFor(types[index])
            if (String(types[index]) === "calendar") {
                verify(calendarPanel() !== null,
                    "The calendar panel must load again")
            } else {
                verify(calendarPanel() === null,
                    "Only the calendar loads this panel")
            }
            dialog.cancelDraft()
            tryVerify(function() {
                return !dialog.opened
            }, 2000, "The dialog must close")
            waitForEmptyTree()
        }
    }
}
