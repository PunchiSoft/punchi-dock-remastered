// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtTest
import QtQuick.Controls as Controls
import "../contents/ui/config" as Config
import "../contents/ui/config/code/configItems.js" as ConfigItemsJS

// Integration of the media player and trash options panels with the «Add item»
// dialog.
//
// The dialog resolves the editor key the catalogue names for the drafted type and
// loads the matching panel; the panel announces what the user asked for and the
// dialog writes it into the draft through the controller, which keeps the only copy
// of the data and applies the canonical rules of `configItems.js`. Accepting is the
// only path that delivers the element, so cancelling and changing type must leave no
// value of the panel behind.
TestCase {
    id: testCase

    name: "ItemConfigurationMediaTrashPanels"
    when: windowShown

    readonly property string defaultTrashSound: "/usr/share/sounds/punchi/default.ogg"

    readonly property var discoveredApplications: [
        {
            "storageId": "org.example.Alpha.desktop",
            "name": "Alpha",
            "icon": "alpha-icon"
        },
        {
            "storageId": "org.example.Zeta.desktop",
            "name": "Zeta",
            "icon": "zeta-icon"
        }
    ]

    Config.ItemDraftController {
        id: controller

        items: []
        defaultTrashEmptySound: testCase.defaultTrashSound
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
        id: iconSpy
        target: dialog
        signalName: "iconPickerRequested"
    }

    SignalSpy {
        id: soundPickerSpy
        target: dialog
        signalName: "soundPickerRequested"
    }

    SignalSpy {
        id: soundPreviewSpy
        target: dialog
        signalName: "soundPreviewRequested"
    }

    function init() {
        failOnWarning(/.?/)
        controller.items = []
        controller.cancel()
        dialog.mediaApplications = []
        acceptedSpy.clear()
        iconSpy.clear()
        soundPickerSpy.clear()
        soundPreviewSpy.clear()
        // The item a loader drops is deleted one event loop turn later, so no panel
        // of the previous case may stay in the tree.
        waitForEmptyTree()
    }

    function mediaPanel() {
        return findChild(dialog, "itemConfigurationMediaPanel")
    }

    function trashPanel() {
        return findChild(dialog, "itemConfigurationTrashPanel")
    }

    function treeIsSettled() {
        const key = String(controller.draftType)
        const media = mediaPanel() !== null
        const trash = trashPanel() !== null
        if (key === "media") {
            return media && !trash
        }
        if (key === "trash") {
            return trash && !media
        }
        return !media && !trash
    }

    function waitForEmptyTree() {
        tryVerify(function() {
            return mediaPanel() === null && trashPanel() === null
        }, 2000, "No options panel may stay in the tree")
    }

    function openFor(type) {
        dialog.openFor(type)
        tryVerify(function() {
            return dialog.opened
        }, 2000, "The dialog must open")
        tryVerify(function() {
            return treeIsSettled()
        }, 2000, "The options panel of the type must be created")
    }

    function mediaSelector() {
        return findChild(mediaPanel(), "mediaPlayerSelector")
    }

    function mediaTextMode() {
        return findChild(mediaPanel(), "mediaTextModeSelector")
    }

    function mediaDisplayMode() {
        return findChild(mediaPanel(), "mediaDisplayModeSelector")
    }

    function mediaDelay() {
        return findChild(mediaPanel(), "mediaAutoCollapseDelaySpinBox")
    }

    function choosePlayer(storageId) {
        const panel = mediaPanel()
        const combo = findChild(panel, "mediaPlayerSelector")
        for (let index = 0; index < panel.playerOptions.length; index++) {
            if (String(panel.playerOptions[index].storageId) === String(storageId)) {
                combo.activated(index)
                return
            }
        }
        verify(false, "The player must be offered by the panel: " + storageId)
    }

    function draftValue(name) {
        return controller.draft === null ? undefined : controller.draft[name]
    }

    // A real click flips the switch and then announces it; the panel answers the
    // announcement, so the case reproduces both steps.
    function toggle(button) {
        button.checked = !button.checked
        button.clicked()
    }

    function test_theCatalogKeyDecidesWhichPanelIsLoaded() {
        openFor("media")
        verify(mediaPanel() !== null, "The media type must load its options panel")
        compare(trashPanel(), null, "Only the panel of the drafted type may load")
        compare(dialog.editorKey, "media-options")

        dialog.cancelDraft()
        tryVerify(function() {
            return !dialog.opened
        })
        waitForEmptyTree()

        openFor("trash")
        verify(trashPanel() !== null, "The trash type must load its options panel")
        compare(mediaPanel(), null, "The panel of the previous type must be gone")
        compare(dialog.editorKey, "trash-options")

        dialog.cancelDraft()
        tryVerify(function() {
            return !dialog.opened
        })
        waitForEmptyTree()

        openFor("punchimenu")
        compare(mediaPanel(), null, "Another type must not load these panels")
        compare(trashPanel(), null)
    }

    function test_theTrashPanelShowsAndWritesTheDraft() {
        openFor("trash")
        const panel = trashPanel()
        verify(panel !== null)

        compare(controller.draftEdited, false,
            "Showing the draft must not mark it as edited")
        compare(String(panel.nameText), "Trash",
            "The panel shows the name of the draft")
        compare(panel.showStateChecked, true,
            "A new trash element shows its state")
        compare(panel.acceptDropsChecked, true)
        compare(String(panel.soundFileName), "default.ogg",
            "The shown sound name comes from the canonical helper")
        compare(String(panel.soundPath), testCase.defaultTrashSound)

        const revision = controller.draftRevision
        const nameField = findChild(panel, "trashNameField")
        nameField.text = "Papelera"
        nameField.editingFinished()
        compare(String(draftValue("name")), "Papelera",
            "The panel writes only through the controller")
        compare(controller.draftEdited, true)
        verify(controller.draftRevision > revision)

        findChild(panel, "trashShowStateCheckBox").clicked()
        compare(draftValue("showState"), true,
            "Emitting the click alone does not flip the switch")
        toggle(findChild(panel, "trashShowStateCheckBox"))
        compare(draftValue("showState"), false,
            "The switch must reach the draft")
        toggle(findChild(panel, "trashAcceptDropsCheckBox"))
        compare(draftValue("acceptDrops"), false)
    }

    function test_theTrashSoundResetWritesTheDefault() {
        openFor("trash")
        controller.setDraftValues({"emptySound": "/tmp/other.ogg"})
        tryVerify(function() {
            return String(trashPanel().soundFileName) === "other.ogg"
        }, 2000, "The panel must show the sound that was written")

        findChild(trashPanel(), "trashSoundResetButton").clicked()
        compare(String(draftValue("emptySound")), testCase.defaultTrashSound,
            "Resetting must write the default sound into the draft")
        tryVerify(function() {
            return String(trashPanel().soundFileName) === "default.ogg"
        }, 2000, "The panel must show the default sound again")
    }

    function test_theMediaPanelWritesTheDraftWithCanonicalRules() {
        openFor("media")
        const panel = mediaPanel()
        verify(panel !== null)
        compare(controller.draftEdited, false)
        verify(draftValue("mediaTextMode") === undefined,
            "A new media element keeps the defaults absent")

        dialog.mediaApplications = testCase.discoveredApplications
        tryVerify(function() {
            return panel.playerOptions.length === 3
        }, 2000, "The panel must offer the discovered applications")

        choosePlayer("org.example.Zeta.desktop")
        compare(String(draftValue("defaultPlayerStorageId")),
            "org.example.Zeta.desktop")
        compare(String(draftValue("defaultPlayerName")), "Zeta")
        compare(String(draftValue("defaultPlayerIcon")), "zeta-icon")
        compare(String(draftValue("name")), "Media player",
            "The canonical rule renames the element")
        compare(String(draftValue("icon")), "emblem-music-symbolic")

        const textMode = mediaTextMode()
        textMode.currentIndex = 1
        textMode.activated(1)
        compare(String(draftValue("mediaTextMode")), "always")

        textMode.currentIndex = 0
        textMode.activated(0)
        verify(draftValue("mediaTextMode") === undefined,
            "Going back to the default must remove the field, not store it")

        const displayMode = mediaDisplayMode()
        displayMode.currentIndex = 1
        displayMode.activated(1)
        compare(String(draftValue("mediaDisplayMode")), "compact")

        const delay = mediaDelay()
        verify(delay.visible, "The delay is offered in compact mode")
        delay.value = 7
        delay.valueModified()
        compare(Number(draftValue("mediaAutoCollapseDelaySeconds")), 7,
            "The delay must reach the draft")

        findChild(panel, "openPlayerMinimizedCheckBox").clicked()
        verify(draftValue("openPlayerMinimized") === undefined,
            "The switch is off in the panel, so nothing is stored")

        choosePlayer("")
        verify(draftValue("defaultPlayerStorageId") === undefined,
            "Choosing Automatic must remove the stored player")
        verify(draftValue("openPlayerMinimized") === undefined,
            "The canonical rule drops the switch without a player")
    }

    function test_aLateApplicationListDoesNotChoose() {
        openFor("media")
        const panel = mediaPanel()
        verify(panel !== null)
        const revision = controller.draftRevision

        dialog.mediaApplications = testCase.discoveredApplications
        tryVerify(function() {
            return panel.playerOptions.length === 3
        }, 2000, "The panel must rebuild its options from the late list")
        compare(controller.draftRevision, revision,
            "A list that arrives late must not write the draft")
        compare(controller.draftEdited, false,
            "A list that arrives late is not a choice of the user")
        compare(mediaSelector().currentIndex, 0,
            "Without a stored player the automatic entry stays selected")
    }

    function test_cancellingDiscardsTheValuesOfThePanel() {
        const itemsBefore = controller.items
        openFor("trash")
        findChild(trashPanel(), "trashNameField").text = "Papelera"
        findChild(trashPanel(), "trashNameField").editingFinished()
        compare(String(draftValue("name")), "Papelera")

        dialog.cancelDraft()
        tryVerify(function() {
            return controller.draft === null
        }, 2000, "Cancelling must drop the draft")
        waitForEmptyTree()
        compare(controller.items, itemsBefore,
            "Cancelling must not touch the dock item list")
        compare(acceptedSpy.count, 0)

        openFor("trash")
        compare(String(draftValue("name")), "Trash",
            "A new draft must start from the defaults again")
    }

    function test_changingTypeDiscardsTheValuesOfThePanel() {
        openFor("trash")
        findChild(trashPanel(), "trashNameField").text = "Papelera"
        findChild(trashPanel(), "trashNameField").editingFinished()
        compare(String(draftValue("name")), "Papelera")

        dialog.requestType("media")
        compare(dialog.pendingTypeChange, "media",
            "An edited draft must ask before changing type")
        dialog.confirmTypeChange()
        tryVerify(function() {
            return treeIsSettled()
        }, 2000, "The panel of the new type must replace the previous one")

        compare(String(draftValue("type")), "media")
        verify(draftValue("emptySound") === undefined,
            "No value of the previous type may survive")
        compare(String(draftValue("name")), "Media player",
            "The new type must start from its own defaults")
        compare(trashPanel(), null)
    }

    function test_acceptingDeliversTheValuesOfThePanel() {
        openFor("trash")
        findChild(trashPanel(), "trashNameField").text = "Papelera"
        findChild(trashPanel(), "trashNameField").editingFinished()
        toggle(findChild(trashPanel(), "trashShowStateCheckBox"))
        verify(dialog.acceptDraft())
        compare(acceptedSpy.count, 1, "Accepting must announce exactly one element")
        const trash = acceptedSpy.signalArguments[0][0]
        compare(String(trash.type), "trash")
        compare(String(trash.name), "Papelera")
        compare(trash.showState, false)
        compare(String(trash.emptySound), testCase.defaultTrashSound)

        openFor("media")
        dialog.mediaApplications = testCase.discoveredApplications
        tryVerify(function() {
            return mediaPanel().playerOptions.length === 3
        }, 2000, "The panel must offer the discovered applications")
        choosePlayer("org.example.Alpha.desktop")
        const displayMode = mediaDisplayMode()
        displayMode.currentIndex = 1
        displayMode.activated(1)
        verify(dialog.acceptDraft())
        compare(acceptedSpy.count, 2)
        const media = acceptedSpy.signalArguments[1][0]
        compare(String(media.type), "media")
        compare(String(media.defaultPlayerStorageId), "org.example.Alpha.desktop")
        compare(String(media.mediaDisplayMode), "compact")
        verify(media.mediaTextMode === undefined,
            "The default must stay absent in the finished element")
    }

    function test_theExternalRequestsStayUnconnected() {
        openFor("trash")
        const panel = trashPanel()
        findChild(panel, "trashSoundPickerButton").clicked()
        compare(soundPickerSpy.count, 1)
        findChild(panel, "trashSoundPreviewButton").clicked()
        compare(soundPreviewSpy.count, 1)
        findChild(panel, "trashEmptyIconButton").clicked()
        compare(iconSpy.count, 1)
        compare(iconSpy.signalArguments[0][0], "trash")
        findChild(panel, "trashFullIconButton").clicked()
        compare(iconSpy.count, 2)
        compare(iconSpy.signalArguments[1][0], "trashFull")

        verify(dialog.opened, "Nothing else may happen: the pickers are not opened")
        compare(controller.draftEdited, false,
            "Asking for a picker is not an edit of the draft")
        compare(acceptedSpy.count, 0)
    }

    function test_panelsSurviveCreationAndDestruction() {
        const types = ["media", "trash", "media", "app", "trash", "media"]
        for (let index = 0; index < types.length; index++) {
            openFor(types[index])
            if (String(types[index]) === "media") {
                verify(mediaPanel() !== null, "The media panel must load again")
                verify(trashPanel() === null)
            } else if (String(types[index]) === "trash") {
                verify(trashPanel() !== null, "The trash panel must load again")
                verify(mediaPanel() === null)
            } else {
                verify(mediaPanel() === null && trashPanel() === null,
                    "A type without an options panel must show none")
            }
            dialog.cancelDraft()
            tryVerify(function() {
                return !dialog.opened
            }, 2000, "The dialog must close")
            waitForEmptyTree()
        }
    }
}
