// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtTest
import "../contents/ui/config" as Config
import "../contents/ui/config/components" as ConfigComponents
import "../contents/ui/config/code/configItemsController.js" as ControllerJS

// Behaviour of the trash options panel and its parity with the dialog that hosts
// it.
//
// The panel is a passive component: the values it shows arrive through its
// properties and the user interaction is announced through its signals. The dialog
// keeps the page controller to resolve the two sound names it shows and its public
// API, but it hands the panel plain values. The keyboard is used where the control
// announces a modification only through a real interaction.
TestCase {
    id: testCase

    name: "TrashOptionsPanel"
    when: windowShown

    SignalSpy {
        id: panelFormSpy
        signalName: "formChanged"
    }

    SignalSpy {
        id: panelEmptyIconSpy
        signalName: "emptyIconPickerRequested"
    }

    SignalSpy {
        id: panelFullIconSpy
        signalName: "fullIconPickerRequested"
    }

    SignalSpy {
        id: panelPreviewSpy
        signalName: "soundPreviewRequested"
    }

    SignalSpy {
        id: panelResetSpy
        signalName: "soundResetRequested"
    }

    SignalSpy {
        id: panelPickerSpy
        signalName: "soundPickerRequested"
    }

    SignalSpy {
        id: dialogFormSpy
        signalName: "formChanged"
    }

    // Stand-in for the page: the dialog only reads the selected type, the default
    // sound and the helper that turns a path into a visible name.
    QtObject {
        id: pageController

        property string selectedItemType: "trash"
        property string defaultTrashEmptySound: "/usr/share/sounds/punchi/default.ogg"

        function fileName(path) {
            return ControllerJS.fileName(path)
        }
    }

    Component {
        id: windowComponent

        Window {
            id: hostWindow

            property alias panel: optionsPanel
            property alias dialog: trashDialog

            width: 760
            height: 620
            visible: true

            Config.TrashOptionsPanel {
                id: optionsPanel
                anchors.left: parent.left
                anchors.top: parent.top
                width: 460
            }

            ConfigComponents.TrashDialog {
                id: trashDialog
                controller: pageController
                width: 700
            }
        }
    }

    function init() {
        failOnWarning(/.?/)
        pageController.selectedItemType = "trash"
        panelFormSpy.clear()
        panelEmptyIconSpy.clear()
        panelFullIconSpy.clear()
        panelPreviewSpy.clear()
        panelResetSpy.clear()
        panelPickerSpy.clear()
        dialogFormSpy.clear()
    }

    function attachPanelSpies(panel) {
        panelFormSpy.target = panel
        panelEmptyIconSpy.target = panel
        panelFullIconSpy.target = panel
        panelPreviewSpy.target = panel
        panelResetSpy.target = panel
        panelPickerSpy.target = panel
        dialogFormSpy.target = null
    }

    // Panel the dialog hosts: the cases about the public API read it there, because
    // that is where the dialog forwards its values. A dialog is a popup, so its
    // content exists once it has been opened.
    function hostedPanel(dialog) {
        dialog.open()
        tryVerify(function() {
            return dialog.visible
        }, 2000, "The dialog must open")
        const panel = findChild(dialog, "trashOptionsPanel")
        verify(panel !== null, "The dialog must host the options panel")
        return panel
    }

    function fieldOf(panel, objectName) {
        return findChild(panel, objectName)
    }

    function test_panelAndDialogShowTheSameValues() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const dialog = host.dialog
        const panel = hostedPanel(dialog)

        // The panel keeps no opinion of its own: it shows what its caller gives it,
        // which is what the dialog and the draft decide.
        compare(panel.nameText, "")
        compare(panel.emptyIconText, "")
        compare(panel.fullIconText, "")
        compare(panel.showStateChecked, false)
        compare(panel.acceptDropsChecked, false)
        compare(panel.editable, true)

        dialog.nameText = "Papelera"
        dialog.emptyIconText = "user-trash"
        dialog.fullIconText = "user-trash-full"
        dialog.showStateChecked = false
        dialog.acceptDropsChecked = false
        compare(panel.nameText, "Papelera",
            "Writing the dialog must reach the panel")
        compare(panel.emptyIconText, "user-trash")
        compare(panel.fullIconText, "user-trash-full")
        compare(panel.showStateChecked, false)
        compare(panel.acceptDropsChecked, false)
        compare(fieldOf(panel, "trashNameField").text, "Papelera",
            "The panel must show the name it was given")
        compare(fieldOf(panel, "trashShowStateCheckBox").checked, false,
            "The panel must show the state it was given")
    }

    function test_dialogResolvesTheSoundNameAndFallsBackToTheDefault() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const dialog = host.dialog
        const panel = hostedPanel(dialog)

        compare(dialog.soundPath, "/usr/share/sounds/punchi/default.ogg",
            "The dialog starts with the sound a new element ships with")
        compare(panel.defaultSoundFileName, "default.ogg",
            "The name of the default sound comes from the page helper")

        dialog.soundPath = "/usr/share/sounds/freedesktop/stereo/bell.oga"
        compare(panel.soundPath, "/usr/share/sounds/freedesktop/stereo/bell.oga")
        compare(panel.soundFileName, "bell.oga",
            "The shown name must come from the page helper")
        compare(fieldOf(panel, "trashEmptySoundField").text, "bell.oga")

        dialog.soundPath = ""
        compare(String(dialog.soundPath), "/usr/share/sounds/punchi/default.ogg",
            "An empty sound falls back to the default one")
        compare(panel.soundFileName, "default.ogg")

        pageController.selectedItemType = "media"
        compare(panel.editable, false,
            "The form is only editable for a trash element")
        pageController.selectedItemType = "trash"
        compare(panel.editable, true)
    }

    function test_thePanelAnnouncesEachRequestOnce() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel
        attachPanelSpies(panel)

        fieldOf(panel, "trashEmptyIconButton").clicked()
        compare(panelEmptyIconSpy.count, 1)
        fieldOf(panel, "trashFullIconButton").clicked()
        compare(panelFullIconSpy.count, 1)
        fieldOf(panel, "trashSoundPreviewButton").clicked()
        compare(panelPreviewSpy.count, 1)
        fieldOf(panel, "trashSoundResetButton").clicked()
        compare(panelResetSpy.count, 1)
        fieldOf(panel, "trashSoundPickerButton").clicked()
        compare(panelPickerSpy.count, 1)

        compare(panelFormSpy.count, 0,
            "Asking for a picker is not a change of the form")
    }

    function test_editingTheFormAnnouncesAChangeOnce() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel
        attachPanelSpies(panel)
        host.requestActivate()
        tryVerify(function() {
            return host.active
        }, 2000, "The window must be active to receive keys")

        const nameField = fieldOf(panel, "trashNameField")
        verify(nameField !== null, "The name field must exist")
        nameField.text = "Papelera"
        nameField.forceActiveFocus()
        tryVerify(function() {
            return nameField.activeFocus
        }, 2000, "The field must take the focus to be typed into")
        keyClick(Qt.Key_Return)
        compare(panelFormSpy.count, 1, "One edit, one announcement")
        compare(panel.nameText, "Papelera", "The panel shows what the user typed")

        const showState = fieldOf(panel, "trashShowStateCheckBox")
        verify(showState !== null, "The state switch must exist")
        showState.clicked()
        compare(panelFormSpy.count, 2)
        compare(panel.showStateChecked, false,
            "The switch keeps the choice of the user")

        const acceptDrops = fieldOf(panel, "trashAcceptDropsCheckBox")
        acceptDrops.clicked()
        compare(panelFormSpy.count, 3)
        compare(panel.acceptDropsChecked, false)
    }

    function test_externalValuesAreShownWithoutAnnouncing() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel
        attachPanelSpies(panel)

        panel.nameText = "Papelera"
        compare(fieldOf(panel, "trashNameField").text, "Papelera",
            "A value set from outside must reach the field")
        panel.emptyIconText = "user-trash"
        compare(fieldOf(panel, "trashEmptyIconField").text, "user-trash")
        panel.fullIconText = "user-trash-full"
        compare(fieldOf(panel, "trashFullIconField").text, "user-trash-full")
        panel.showStateChecked = false
        compare(fieldOf(panel, "trashShowStateCheckBox").checked, false,
            "A value set from outside must reach the switch")
        panel.showStateChecked = true
        compare(fieldOf(panel, "trashShowStateCheckBox").checked, true)
        panel.soundFileName = "other.ogg"
        compare(fieldOf(panel, "trashEmptySoundField").text, "other.ogg")

        compare(panelFormSpy.count, 0,
            "A value set from outside is not an edit of the user")
        compare(panelResetSpy.count, 0)
    }

    function test_dialogForwardsWhatThePanelAnnounces() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const dialog = host.dialog
        dialogFormSpy.target = dialog
        const panel = hostedPanel(dialog)

        const nameField = fieldOf(panel, "trashNameField")
        nameField.text = "Papelera"
        nameField.editingFinished()
        compare(dialogFormSpy.count, 1,
            "The dialog must forward the change of the form exactly once")
        compare(dialog.nameText, "Papelera",
            "The dialog answers with the value the panel holds")

        fieldOf(panel, "trashSoundPickerButton").clicked()
        compare(panelPickerSpy.count, 0,
            "The panel of the dialog is not spied here")
    }

    function test_controlsStayInteractiveAndAccessible() {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        const panel = host.panel
        attachPanelSpies(panel)

        const picker = fieldOf(panel, "trashSoundPickerButton")
        compare(picker.Accessible.name, "Choose sound",
            "An icon-only button must announce what it does")
        mouseClick(picker)
        compare(panelPickerSpy.count, 1,
            "A real click must ask for the sound picker once")

        const preview = fieldOf(panel, "trashSoundPreviewButton")
        compare(preview.Accessible.name, "Test sound")
        mouseClick(preview)
        compare(panelPreviewSpy.count, 1)

        const emptyIcon = fieldOf(panel, "trashEmptyIconButton")
        compare(emptyIcon.Accessible.name, "Choose icon")
        compare(fieldOf(panel, "trashNameField").enabled, true,
            "The form stays editable for a trash element")
    }
}
