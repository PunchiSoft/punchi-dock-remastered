// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtQuick.Controls as Controls
import QtTest
import "../contents/ui/config" as Config
import "../contents/ui/config/components" as ConfigComponents

// Behaviour of the timed options panel and its parity with the dialog that hosts it.
//
// The panel is a passive component: the caller pushes the values it shows into the
// controls and the user interaction is announced through its signals. The dialog
// keeps the page as its controller, so the case uses a stand-in that records what the
// dialog asks of it.
TestCase {
    id: testCase

    name: "TimedOptionsPanel"
    when: windowShown

    SignalSpy {
        id: panelFormSpy
        signalName: "formChanged"
    }

    SignalSpy {
        id: panelColorSpy
        signalName: "colorRequested"
    }

    // Stand-in for the page: the dialog only reads the selected type, the editable
    // state, its own size, the synchronization flag and the title, and asks it to
    // apply the form or to open the colour dialog.
    QtObject {
        id: pageController

        property string selectedItemType: "calendar"
        property int selectedIndex: 0
        property bool syncing: false
        property real width: 900
        property real height: 700
        property int applyCount: 0
        property int colorRequestCount: 0
        property string lastColorTarget: ""

        function selectedConfigureTitle() {
            return "Configure calendar"
        }

        function applyItemForm() {
            applyCount += 1
        }

        function openTimedColorDialog(target) {
            colorRequestCount += 1
            lastColorTarget = String(target)
        }
    }

    Component {
        id: windowComponent

        Window {
            id: hostWindow

            property alias panel: optionsPanel
            property alias dialog: timedDialog

            width: 820
            height: 700
            visible: true

            Config.TimedOptionsPanel {
                id: optionsPanel
                anchors.left: parent.left
                anchors.top: parent.top
                width: 520
            }

            ConfigComponents.TimedDialog {
                id: timedDialog
                controller: pageController
            }
        }
    }

    function init() {
        failOnWarning(/.?/)
        pageController.selectedItemType = "calendar"
        pageController.selectedIndex = 0
        pageController.syncing = false
        pageController.applyCount = 0
        pageController.colorRequestCount = 0
        pageController.lastColorTarget = ""
        panelFormSpy.clear()
        panelColorSpy.clear()
    }

    function attachPanelSpies(panel) {
        panelFormSpy.target = panel
        panelColorSpy.target = panel
    }

    function control(panel, objectName) {
        return findChild(panel, objectName)
    }

    function colorModeControl(panel) {
        return findChild(panel, "timedTextColorControl")
    }

    function test_panelAndDialogShareTheSameControlsAndRanges() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const dialog = host.dialog
        dialog.open()
        tryVerify(function() {
            return dialog.visible
        }, 2000, "The dialog must open")
        const panel = findChild(dialog, "timedOptionsPanel")
        verify(panel !== null, "The dialog must host the options panel")

        // The dialog keeps its public API and points at the panel controls.
        compare(dialog.itemNameControl, panel.itemNameControl)
        compare(dialog.timedItemWidthControl, panel.timedItemWidthControl)
        compare(dialog.timedTextScaleControl, panel.timedTextScaleControl)
        compare(dialog.calendarItemHeightControl, panel.calendarItemHeightControl)
        compare(dialog.calendarFormatControl, panel.calendarFormatControl)
        compare(dialog.calendarTimeTextScaleControl, panel.calendarTimeTextScaleControl)
        compare(dialog.calendarDateTextScaleControl, panel.calendarDateTextScaleControl)
        compare(dialog.calendarTextShadowsControl, panel.calendarTextShadowsControl)
        compare(dialog.calendarShowWeekNumbersControl, panel.calendarShowWeekNumbersControl)
        compare(dialog.calendarPopupScaleControl, panel.calendarPopupScaleControl)
        compare(dialog.calendarTextColorControl, panel.calendarTextColorControl)
        // The four colour controls of the other targets stay as they were: null.
        compare(dialog.calendarBackgroundColorControl, null)
        compare(dialog.calendarAccentColorControl, null)
        compare(dialog.calendarBorderColorControl, null)
        compare(dialog.calendarRadiusControl, null)
        compare(String(dialog.title), "Configure calendar",
            "The title still comes from the page")
        compare(dialog.modal, true)
        compare(dialog.standardButtons, Controls.Dialog.Close)

        const width = control(panel, "timedItemWidthSpinBox")
        compare(width.from, 0)
        compare(width.to, 600)
        compare(width.stepSize, 10)
        compare(width.value, 0, "Zero means automatic")
        const timeScale = control(panel, "calendarTimeTextScaleSlider")
        compare(timeScale.from, 0.75)
        compare(timeScale.to, 2.0)
        compare(timeScale.stepSize, 0.05)
        const dateScale = control(panel, "calendarDateTextScaleSlider")
        compare(dateScale.from, 0.75)
        compare(dateScale.to, 2.0)
        const popupScale = control(panel, "calendarPopupScaleSlider")
        compare(popupScale.from, 0.5)
        compare(popupScale.to, 3.0)
        const legacyScale = control(panel, "timedTextScaleSlider")
        compare(legacyScale.from, 0.75)
        compare(legacyScale.to, 1.8)
        compare(control(panel, "calendarItemHeightSpinBox").from, 0)
        compare(control(panel, "calendarItemHeightSpinBox").to, 600)
        compare(control(panel, "calendarFormatCombo").model.length, 7,
            "The format list keeps its seven entries")
        dialog.close()
    }

    function test_synchronizationAnnouncesNothing() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel
        attachPanelSpies(panel)

        panel.synchronizeValues({
            "name": "Calendario",
            "color": "#ff8800",
            "format": "dd/MM/yyyy",
            "timeTextScale": 1.35,
            "dateTextScale": 1.2,
            "textShadowsEnabled": false,
            "showWeekNumbers": false,
            "popupScale": 1.4
        })

        compare(panel.itemNameControl.text, "Calendario")
        compare(panel.calendarTextColorControl.text, "#ff8800")
        compare(panel.calendarFormatControl.editText, "dd/MM/yyyy")
        compare(panel.calendarTimeTextScaleControl.value, 1.35)
        compare(panel.calendarDateTextScaleControl.value, 1.2)
        compare(panel.calendarTextShadowsControl.checked, false)
        compare(panel.calendarShowWeekNumbersControl.checked, false)
        compare(panel.calendarPopupScaleControl.value, 1.4)
        compare(panelFormSpy.count, 0,
            "A synchronization is not an edit of the user")
        compare(panelColorSpy.count, 0)
    }

    function test_eachRealEditAnnouncesOnce() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel
        attachPanelSpies(panel)
        host.requestActivate()
        tryVerify(function() {
            return host.active
        }, 2000, "The window must be active to receive keys")

        const nameField = control(panel, "timedNameField")
        nameField.text = "Calendario"
        nameField.forceActiveFocus()
        tryVerify(function() {
            return nameField.activeFocus
        }, 2000, "The field must take the focus")
        keyClick(Qt.Key_Return)
        compare(panelFormSpy.count, 1, "One edit, one announcement")

        const shadows = control(panel, "calendarTextShadowsCheckBox")
        const nextShadows = !shadows.checked
        shadows.checked = nextShadows
        shadows.toggled()
        compare(panelFormSpy.count, 2)
        compare(panel.calendarTextShadowsControl.checked, nextShadows,
            "The switch keeps the choice of the user")

        const weekNumbers = control(panel, "calendarShowWeekNumbersCheckBox")
        const nextWeekNumbers = !weekNumbers.checked
        weekNumbers.checked = nextWeekNumbers
        weekNumbers.toggled()
        compare(panelFormSpy.count, 3)
        compare(panel.calendarShowWeekNumbersControl.checked, nextWeekNumbers)

        // Assigning a value loads state; only the interaction signal announces an edit.
        const popupScale = control(panel, "calendarPopupScaleSlider")
        const announced = panelFormSpy.count
        popupScale.value = 1.4
        compare(panelFormSpy.count, announced,
            "A programmatic slider change must stay silent")
        popupScale.moved()
        compare(panelFormSpy.count, announced + 1,
            "One change of a slider, one announcement")
        compare(panel.calendarPopupScaleControl.value, 1.4)
    }

    function test_programmaticSliderChangesStaySilentEvenInHiddenDialog() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        attachPanelSpies(host.panel)
        const hiddenPanel = findChild(host.dialog, "timedOptionsPanel")
        verify(hiddenPanel !== null)
        compare(host.dialog.visible, false)
        pageController.selectedItemType = "app"
        const names = ["timedTextScaleSlider", "calendarTimeTextScaleSlider",
            "calendarDateTextScaleSlider", "calendarPopupScaleSlider"]
        for (let index = 0; index < names.length; ++index) {
            control(host.panel, names[index]).value = 1.35
            control(hiddenPanel, names[index]).value = 1.45
        }
        wait(0)
        compare(panelFormSpy.count, 0, "Loading slider values is not an edit")
        compare(pageController.applyCount, 0,
            "A hidden dialog must not apply its programmatic values")
    }

    function test_sliderKeyboardAndPointerInteractionAnnounceEdits() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        host.requestActivate()
        tryVerify(function() { return host.active })
        const panel = host.panel
        attachPanelSpies(panel)
        const names = ["calendarTimeTextScaleSlider", "calendarDateTextScaleSlider",
            "calendarPopupScaleSlider"]
        for (let index = 0; index < names.length; ++index) {
            const slider = control(panel, names[index])
            slider.value = 1.0
            slider.forceActiveFocus()
            tryVerify(function() { return slider.activeFocus })
            panelFormSpy.clear()
            keyClick(Qt.Key_Right)
            compare(panelFormSpy.count, 1, "A keyboard step announces one edit")
            verify(Math.abs(slider.value - 1.05) < 0.00001)
            panelFormSpy.clear()
            mouseClick(slider, slider.width * 0.8, slider.height / 2)
            verify(slider.value > 1.05, "The pointer must change the slider value")
            verify(panelFormSpy.count > 0, "Pointer interaction must announce the edit")
        }
    }

    function test_formatCanBeWrittenAndSelected() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel
        attachPanelSpies(panel)
        const format = control(panel, "calendarFormatCombo")

        format.editText = "hh:mm AP"
        format.accepted()
        compare(panelFormSpy.count, 1, "A written format is announced once")
        compare(panel.calendarFormatControl.editText, "hh:mm AP")

        format.currentIndex = 3
        format.activated(3)
        compare(panelFormSpy.count, 2, "A selected format is announced once")
        compare(panel.calendarFormatControl.editText, "dd/MM/yyyy",
            "Selecting an entry writes it into the field")
    }

    function test_customColorAndBackToTheTheme() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel
        attachPanelSpies(panel)
        const colorMode = colorModeControl(panel)

        // The holder is where the value lives: the caller writes it and the mode
        // control follows it.
        panel.calendarTextColorControl.text = "#336699"
        tryVerify(function() {
            return colorMode.customMode
        }, 2000, "A custom colour must be recognized")
        compare(colorMode.customColor, "#336699",
            "The mode control reads the value of the holder")

        // Asking for a custom colour is an intention, not a form change: the picker
        // belongs to whoever hosts the panel.
        compare(panelColorSpy.count, 0)
        colorMode.colorRequested()
        compare(panelColorSpy.count, 1)
        compare(panelColorSpy.signalArguments[0][0], "text",
            "The request names the target the page already knows")
        compare(panelFormSpy.count, 0,
            "Asking for a colour is not an edit yet")

        colorMode.themeRequested()
        compare(String(panel.calendarTextColorControl.text), "",
            "Returning to the theme clears the value")
        compare(panelFormSpy.count, 1,
            "Returning to the theme is exactly one edit")
    }

    function test_dialogForwardsTowardsThePage() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const dialog = host.dialog
        dialog.open()
        tryVerify(function() {
            return dialog.visible
        }, 2000, "The dialog must open")
        const panel = findChild(dialog, "timedOptionsPanel")

        const weekNumbers = control(panel, "calendarShowWeekNumbersCheckBox")
        const nextWeekNumbers = !weekNumbers.checked
        weekNumbers.checked = nextWeekNumbers
        weekNumbers.toggled()
        compare(pageController.applyCount, 1,
            "The dialog must ask the page to apply the form once")

        const colorMode = colorModeControl(panel)
        colorMode.colorRequested()
        compare(pageController.colorRequestCount, 1)
        compare(pageController.lastColorTarget, "text",
            "The dialog must open the colour dialog the panel requested")

        pageController.syncing = true
        panel.synchronizeValues({"popupScale": 2.0})
        compare(pageController.applyCount, 1,
            "A synchronization of the page must not be announced")
        pageController.syncing = false
        dialog.close()
    }

    function test_theClockShowsItsOwnControls() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel
        attachPanelSpies(panel)

        panel.selectedItemType = "clock"
        compare(control(panel, "timedItemWidthSpinBox").visible, true,
            "The clock shows the width of the item")
        compare(control(panel, "timedNameField").enabled, true)
        compare(control(panel, "calendarTextShadowsCheckBox").visible, false,
            "The shadows switch belongs to the calendar")

        panel.selectedItemType = "calendar"
        compare(control(panel, "timedItemWidthSpinBox").visible, false)
        compare(control(panel, "calendarTextShadowsCheckBox").visible, true)

        panel.editable = false
        compare(control(panel, "timedNameField").enabled, false,
            "A non editable element disables its form")
        compare(control(panel, "calendarTimeTextScaleSlider").enabled, false)
    }

    function test_rangesAndDefaultsOfThePanel() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel

        const timeScale = control(panel, "calendarTimeTextScaleSlider")
        timeScale.value = 0.1
        compare(timeScale.value, 0.75, "The scale clamps to its minimum")
        timeScale.value = 9.0
        compare(timeScale.value, 2.0, "The scale clamps to its maximum")

        const width = control(panel, "timedItemWidthSpinBox")
        width.value = 900
        compare(width.value, 600, "The width clamps to its maximum")
        width.value = -10
        compare(width.value, 0, "Zero is the automatic width")

        const legacyScale = control(panel, "timedTextScaleSlider")
        legacyScale.value = 9.0
        compare(legacyScale.value, 1.8)
        legacyScale.value = 0.1
        compare(legacyScale.value, 0.75)

        const format = control(panel, "calendarFormatCombo")
        compare(String(format.textFromValue ? "" : ""), "")
        compare(width.textFromValue(0, Qt.locale()), "Automatic",
            "The width shows its automatic label")
        compare(width.textFromValue(120, Qt.locale()), "120 px",
            "The width is shown in pixels")
    }
}
