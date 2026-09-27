// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtTest
import "../contents/ui/config" as Config

// Transactional contract of the draft the «Add item» dialog builds.
//
// The draft must stay outside the dock item list until it is accepted, so these
// cases check that opening, switching type and cancelling leave the list, the
// selection and the configuration untouched, and that accepting emits a finished
// element exactly once without persisting anything.
TestCase {
    id: testCase

    name: "ItemDraftController"
    when: windowShown

    readonly property var sampleItems: [
        {"type": "media", "name": "Media player", "icon": "emblem-music-symbolic"}
    ]

    Config.ItemDraftController {
        id: controller

        items: []
        defaultTrashEmptySound: "/usr/share/sounds/punchi/trash-empty.ogg"
    }

    SignalSpy {
        id: acceptedSpy
        target: controller
        signalName: "itemAccepted"
    }

    SignalSpy {
        id: cancelledSpy
        target: controller
        signalName: "cancelled"
    }

    SignalSpy {
        id: typeChangeSpy
        target: controller
        signalName: "typeChangeConfirmationRequested"
    }

    function clearSpies() {
        acceptedSpy.clear()
        cancelledSpy.clear()
        typeChangeSpy.clear()
    }

    function init() {
        failOnWarning(/.?/)
        controller.items = []
        controller.cancel()
        clearSpies()
    }

    function test_openingKeepsTheDockListAndTheSelectionUntouched() {
        const itemsBefore = controller.items
        controller.open("app")
        wait(0)

        verify(controller.draft !== null, "Opening must build a draft")
        compare(String(controller.draft.type), "app")
        compare(controller.items, itemsBefore,
            "Opening must not replace the dock item list")
        compare(controller.items.length, 0,
            "Opening must not insert anything into the dock item list")
        compare(acceptedSpy.count, 0, "Opening must not announce an element")
        compare(cancelledSpy.count, 0, "Opening must not cancel anything")
    }

    function test_anApplicationNeedsACommandBeforeItIsValid() {
        controller.open("app")
        wait(0)

        compare(controller.draftValid, false,
            "A new application has no command yet")
        compare(controller.invalidReason, "app-command")

        controller.draft.command = "firefox"
        compare(controller.draftValid, false,
            "A plain write into the draft must not refresh the validity on its own")

        controller.markEdited()
        compare(controller.draftValid, true,
            "The form announces its writes, so the validity follows")
        compare(controller.invalidReason, "")
    }

    function test_openApplicationsIsValidWithoutACommand() {
        controller.open("dynamic-applications")
        wait(0)

        compare(controller.draftValid, true,
            "The marker is not a launcher and must not require a command")
        verify(controller.draft.command === undefined)
        compare(controller.accept(), true)
        compare(acceptedSpy.count, 1)
        const finished = acceptedSpy.signalArguments[0][0]
        compare(String(finished.type), "dynamic-applications")
        compare(String(finished.name), "Open applications")
        verify(finished.command === undefined,
            "Accepting must not invent a launcher command")
    }

    function test_aFolderAsksForItsSourceBeforeItIsValid() {
        controller.open("folder")
        wait(0)

        compare(controller.draftValid, true,
            "A manual container needs nothing else")

        controller.draft.sourceType = "folder"
        controller.markEdited()
        compare(controller.invalidReason, "folder-path")

        controller.draft.sourcePath = "~/Downloads"
        controller.markEdited()
        compare(controller.draftValid, true)

        controller.draft.sourceType = "category"
        controller.draft.sourceCategory = ""
        controller.markEdited()
        compare(controller.invalidReason, "folder-category")
    }

    function test_anEditedDraftAsksBeforeChangingType() {
        controller.open("app")
        controller.draft.command = "firefox"
        controller.markEdited()
        wait(0)

        compare(controller.requestType("note"), false,
            "Changing type with data must not discard the draft silently")
        compare(typeChangeSpy.count, 1)
        compare(String(controller.draftType), "app",
            "The draft must keep its type until the user confirms")

        controller.confirmTypeChange("note")
        compare(String(controller.draftType), "note")
        compare(controller.draftValid, true, "A note is valid with its defaults")
        compare(typeChangeSpy.count, 1, "Confirming must not ask again")
    }

    function test_aCleanDraftChangesTypeWithoutAsking() {
        controller.open("app")
        wait(0)

        compare(controller.requestType("spacer"), true)
        compare(typeChangeSpy.count, 0)
        compare(String(controller.draftType), "spacer")
    }

    function test_cancellingDiscardsEverything() {
        controller.open("app")
        controller.draft.command = "firefox"
        controller.markEdited()
        wait(0)

        controller.cancel()
        wait(0)

        compare(controller.draft, null, "Cancelling must drop the draft")
        compare(String(controller.draftType), "")
        compare(cancelledSpy.count, 1)
        compare(acceptedSpy.count, 0, "Cancelling must never announce an element")
        compare(controller.items.length, 0)
    }

    function test_acceptingAnnouncesTheFinishedElementOnce() {
        controller.open("app")
        controller.draft.command = "firefox"
        controller.draft.name = "Firefox"
        controller.markEdited()
        wait(0)

        compare(controller.accept(), true)
        wait(0)

        compare(acceptedSpy.count, 1, "Accepting must announce the element once")
        const finished = acceptedSpy.signalArguments[0][0]
        compare(String(finished.type), "app")
        compare(String(finished.command), "firefox")
        compare(String(finished.name), "Firefox")
        compare(controller.draft, null,
            "Accepting must leave the controller without a draft")
        compare(controller.items.length, 0,
            "The controller must not insert the element: that belongs to the page")
    }

    function test_anInvalidDraftIsNeverAccepted() {
        controller.open("app")
        wait(0)

        compare(controller.draftValid, false)
        compare(controller.accept(), false)
        compare(acceptedSpy.count, 0)
        verify(controller.draft !== null,
            "A rejected accept must keep the draft so the user can fix it")
    }

    function test_aSingletonAlreadyInTheDockCannotBeAddedAgain() {
        controller.items = testCase.sampleItems
        wait(0)

        compare(controller.isTypeAvailable("media"), false)
        verify(String(controller.unavailableReason("media")).length > 0,
            "A disabled type must explain why")

        controller.open("media")
        compare(String(controller.draftType) !== "media", true,
            "Opening on a taken singleton must move to an available type")

        controller.startDraft("media")
        compare(controller.accept(), false,
            "The controller must reject the duplicate even behind the selector")
        compare(acceptedSpy.count, 0)
    }

    function test_aNewDraftInvalidatesTheOlderGeneration() {
        const first = controller.startDraft("app")
        compare(controller.isCurrent(first), true)

        const second = controller.startDraft("note")
        compare(second > first, true)
        compare(controller.isCurrent(first), false,
            "An answer of the previous draft must be discarded")
        compare(controller.isCurrent(second), true)

        controller.cancel()
        compare(controller.isCurrent(second), false,
            "Closing the dialog must invalidate the pending answers too")
    }

    function test_externalAnswersBelongToOneGenerationAndType() {
        const generation = controller.open("app")
        const requestId = controller.beginExternalOperation(
            "application-search", "application", {})
        verify(requestId > 0)
        verify(controller.externalOperationMatches(
            "application-search", requestId))

        controller.confirmTypeChange("note")
        compare(controller.pendingExternalOperation, null,
            "Changing type must invalidate the pending answer")
        compare(controller.applyDiscoveredApplication(generation, {
            "name": "Late", "command": "late"
        }), false)
        compare(String(controller.draftType), "note")
        verify(controller.draft.command === undefined)
    }

    function test_discoveryAndContainerDropOnlyMutateTheDraft() {
        const appGeneration = controller.open("app")
        compare(controller.applyDiscoveredApplication(appGeneration, {
            "name": "Firefox",
            "description": "Browser",
            "icon": "firefox",
            "command": "firefox",
            "storageId": "firefox.desktop",
            "appId": "firefox"
        }), true)
        compare(String(controller.draft.command), "firefox")
        compare(String(controller.draft.storageId), "firefox.desktop")
        compare(controller.items.length, 0)

        const folderGeneration = controller.startDraft("folder")
        const drop = controller.addDroppedApplication(folderGeneration, {
            "storageId": "org.kde.dolphin.desktop",
            "appId": "org.kde.dolphin",
            "name": "Dolphin",
            "icon": "system-file-manager",
            "command": "dolphin"
        })
        compare(drop.changed, true)
        compare(controller.draft.apps.length, 1)
        compare(String(controller.draft.apps[0].name), "Dolphin")
        compare(controller.items.length, 0,
            "External operations must never insert a provisional dock item")
    }
}
