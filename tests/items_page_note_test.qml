// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtTest
import org.kde.kirigami as Kirigami
import "../contents/ui/config" as Config
import "../contents/ui/config/code/itemNotes.js" as ItemNotes

// Note of the selected type in the Items page.
//
// The note lives in the right column and follows the selection: it appears for a
// type that has one, stays empty for the rest and reacts to a change of type. The
// cases never compare against a full sentence, because the harness can resolve a
// translated catalog; they check the shape, the type it names and its reactivity.
// The offscreen harness reports every item as not visible, so visibility is read
// through the text that decides it.
TestCase {
    id: testCase

    name: "ItemsPageNote"
    when: windowShown
    property var hostWindowUnderTest: null

    QtObject {
        id: controllerStub

        property var items: []
        property int selectedIndex: -1
        property string selectedItemType: "app"
        property real listRowHeight: Kirigami.Units.gridUnit * 2.4
        property real listFooterHeight: Kirigami.Units.gridUnit * 2.4
        property real listFramePadding: Kirigami.Units.largeSpacing * 2
        property real listScrollGutter: Kirigami.Units.gridUnit * 1.6

        function selectItem() {}
        function moveSelectedItem() {}
        function canConfigureSelectedItem() { return false }
        function configureSelectedItem() {}
        function removeSelectedItem() {}
        function selectedConfigureTitle() { return "" }
        function iconPreviewSource() { return "" }
    }

    ListModel { id: itemModelStub }
    Timer { id: statusTimerStub }

    Component {
        id: windowComponent

        Window {
            width: 1000
            height: 600
            visible: true

            property alias view: mainView

            Config.ConfigItemsMainView {
                id: mainView
                anchors.fill: parent
                controller: controllerStub
                itemModel: itemModelStub
                statusHideTimer: statusTimerStub
            }
        }
    }

    function init() {
        failOnWarning(/.?/)
        controllerStub.items = []
        controllerStub.selectedIndex = -1
        controllerStub.selectedItemType = "app"
        hostWindowUnderTest = createTemporaryObject(windowComponent, testCase)
        verify(hostWindowUnderTest !== null)
        wait(0)
    }

    function cleanup() {
        if (hostWindowUnderTest) {
            const target = hostWindowUnderTest
            hostWindowUnderTest = null
            target.destroy()
            wait(0)
        }
    }

    function noteText() {
        const note = findChild(hostWindowUnderTest.view, "itemTypeNote")
        verify(note !== null, "The note of the selected type must exist")
        return String(note.text)
    }

    // Every note opens with a short label in bold and continues in normal weight.
    // The checks are language independent: they look at the shape of the note, not
    // at a sentence that a catalogue could translate.
    function verifyNoteEmphasis(note) {
        compare(Boolean(note.font.bold), false,
            "The whole note must not be bold")
        compare(note.textFormat, Text.StyledText,
            "The note must carry its label through rich text")
        const boldRun = String(note.text).match(/<b>([^<]*)<\/b>/)
        verify(boldRun !== null,
            "The note must mark its label in bold: " + noteText())
        verify(boldRun[1].length <= 12,
            "Only a short label may be bold, not the sentence: " + boldRun[1])
        verify(String(note.Accessible.name).length > 0,
            "The note must expose its words to accessibility")
        compare(String(note.Accessible.name).indexOf("<"), -1,
            "The markup must not reach the accessible name: " + note.Accessible.name)
        compare(note.wrapMode, Text.WordWrap, "The note must wrap")
    }

    function test_thePunchiMenuNoteNamesTheTypeItDescribes() {
        controllerStub.selectedIndex = 0
        controllerStub.selectedItemType = "punchimenu"
        wait(0)

        const note = findChild(hostWindowUnderTest.view, "itemTypeNote")
        verify(note !== null)
        verify(noteText().length > 0, "A type with a note must show it")
        verify(noteText().indexOf("PunchiMenu") >= 0,
            "The note must name the type it describes: " + noteText())
        verifyNoteEmphasis(note)
    }

    function test_theApplicationNoteDescribesTheLauncher() {
        controllerStub.selectedIndex = 0
        controllerStub.selectedItemType = "app"
        wait(0)

        const note = findChild(hostWindowUnderTest.view, "itemTypeNote")
        verify(note !== null)
        verify(noteText().length > 0, "The launcher must have a note")
        compare(noteText(), String(ItemNotes.noteFor("app")),
            "The view must show the note the catalogue answers")
        verify(noteText() !== String(ItemNotes.noteFor("punchimenu")),
            "Two documented types must not share the same note")
        verifyNoteEmphasis(note)
    }

    function test_theContainerNoteExplainsItsContent() {
        controllerStub.selectedIndex = 0
        controllerStub.selectedItemType = "folder"
        wait(0)

        const note = findChild(hostWindowUnderTest.view, "itemTypeNote")
        verify(note !== null)
        verify(noteText().length > 0, "The Container must have a note")
        compare(noteText(), String(ItemNotes.noteFor("folder")),
            "The view must show the note the catalogue answers")
        verify(noteText() !== String(ItemNotes.noteFor("app"))
                && noteText() !== String(ItemNotes.noteFor("punchimenu")),
            "Two documented types must not share the same note")
        verifyNoteEmphasis(note)
    }

    function test_theOpenApplicationsNoteExplainsTheMarker() {
        controllerStub.selectedIndex = 0
        controllerStub.selectedItemType = "dynamic-applications"
        wait(0)

        const note = findChild(hostWindowUnderTest.view, "itemTypeNote")
        verify(note !== null)
        verify(noteText().length > 0, "Open applications must have a note")
        compare(noteText(), String(ItemNotes.noteFor("dynamic-applications")),
            "The view must show the note the catalogue answers")
        verify(noteText() !== String(ItemNotes.noteFor("app"))
                && noteText() !== String(ItemNotes.noteFor("folder"))
                && noteText() !== String(ItemNotes.noteFor("punchimenu")),
            "Two documented types must not share the same note")
        verifyNoteEmphasis(note)
    }

    function test_allKnownTypesHaveDistinctNotesWithValidEmphasis() {
        const types = [
            "app", "folder", "dynamic-applications", "punchimenu",
            "control-center", "calendar", "trash", "media", "note",
            "separator", "spacer"
        ]
        const seenNotes = {}

        for (let i = 0; i < types.length; i++) {
            const type = types[i]
            controllerStub.selectedIndex = 0
            controllerStub.selectedItemType = type
            wait(0)

            const note = findChild(hostWindowUnderTest.view, "itemTypeNote")
            verify(note !== null, "Note item must exist for " + type)
            const text = noteText()
            verify(text.length > 0, "Note text must not be empty for " + type)
            verify(!seenNotes[text], "Note for " + type + " must be unique")
            seenNotes[text] = true
            verifyNoteEmphasis(note)
        }
    }

    function test_aTypeWithoutANoteLeavesTheColumnEmpty() {
        controllerStub.selectedIndex = 0
        controllerStub.selectedItemType = "unknown-type"
        wait(0)

        compare(noteText(), "", "A type without a note must leave the column empty")
    }

    function test_theNoteFollowsTheSelection() {
        controllerStub.selectedIndex = 0
        controllerStub.selectedItemType = "punchimenu"
        wait(0)
        verify(noteText().length > 0)

        controllerStub.selectedItemType = "trash"
        wait(0)
        compare(noteText(), String(ItemNotes.noteFor("trash")),
            "Selecting trash must show trash note")

        controllerStub.selectedItemType = "unknown-type"
        wait(0)
        compare(noteText(), "", "Selecting an unknown type must clear the note")

        controllerStub.selectedItemType = "punchimenu"
        wait(0)
        verify(noteText().length > 0, "Returning to PunchiMenu must show it again")
    }

    function test_noSelectionKeepsTheNoteEmpty() {
        controllerStub.selectedItemType = "punchimenu"
        controllerStub.selectedIndex = -1
        wait(0)

        compare(noteText(), "",
            "A note must not describe a type the list has not selected")
    }

    function test_theCatalogueAnswersForTheTypeItKnows() {
        const knownTypes = [
            "punchimenu", "app", "folder", "dynamic-applications",
            "control-center", "calendar", "trash", "media", "note",
            "separator", "spacer"
        ]
        for (let i = 0; i < knownTypes.length; i++) {
            verify(String(ItemNotes.noteFor(knownTypes[i])).length > 0,
                "Catalogue must have a note for " + knownTypes[i])
        }
        compare(String(ItemNotes.noteFor("unknown-type")), "")
        compare(String(ItemNotes.noteFor("")), "")
    }
}
