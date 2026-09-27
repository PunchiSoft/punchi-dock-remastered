// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtTest
import QtQuick.Controls as Controls
import "../contents/ui/config" as Config

// Surface and lifecycle of the «Add item» dialog.
//
// The dialog owns the navigation, the focus and the Cancel path, and it owns no
// state of its own: the draft belongs to the controller. These cases check that
// opening changes nothing, that every way out without accepting discards the
// draft, that accepting announces exactly one finished element, and that the
// surface can be opened, closed, destroyed and recreated without a warning.
TestCase {
    id: testCase

    name: "ItemConfigurationDialog"
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
        id: closedSpy
        target: dialog
        signalName: "surfaceClosed"
    }

    function addButton() {
        return findChild(dialog, "itemConfigurationAddButton")
    }

    function cancelButton() {
        return findChild(dialog, "itemConfigurationCancelButton")
    }

    function init() {
        failOnWarning(/.?/)
        controller.items = []
        controller.cancel()
        acceptedSpy.clear()
        closedSpy.clear()
    }

    // The dialog builds and drops panels while it opens and closes, and a creation
    // can still be in flight when the last case ends. Qt warns about a creation
    // left in the process of being created if the engine is destroyed before the
    // event loop gives it its turn, so the test lets the tree settle first. The
    // warning appears only under load, which is why it is settled here and not
    // diagnosed case by case.
    function cleanupTestCase() {
        dialog.close()
        wait(0)
        wait(0)
    }

    function test_openingBuildsADraftWithoutTouchingConfiguration() {
        const itemsBefore = controller.items
        dialog.openFor("app")
        tryVerify(function() {
            return dialog.opened
        })

        verify(controller.draft !== null, "Opening must build a draft")
        compare(controller.items, itemsBefore,
            "Opening must not replace the dock item list")
        compare(Boolean(addButton().enabled), false,
            "An application without a command cannot be added yet")
        compare(acceptedSpy.count, 0)

        dialog.cancelDraft()
    }

    function test_cancellingLeavesNoElementAndNoState() {
        dialog.openFor("app")
        tryVerify(function() {
            return dialog.opened
        })
        const itemsBefore = controller.items

        cancelButton().clicked()
        tryVerify(function() {
            return !dialog.opened
        })
        tryVerify(function() {
            return controller.draft === null
        })

        compare(controller.draft, null, "Cancelling must drop the draft")
        compare(controller.items, itemsBefore)
        compare(acceptedSpy.count, 0)
        tryVerify(function() {
            return closedSpy.count === 1
        }, 2000, "The page must learn that the surface closed")
    }

    function test_closingTheSurfaceCancelsTheDraft() {
        dialog.openFor("app")
        tryVerify(function() {
            return dialog.opened
        })

        // Escape and the window close button end in the same closed handler.
        dialog.close()
        tryVerify(function() {
            return !dialog.opened
        })
        tryVerify(function() {
            return controller.draft === null
        })

        compare(acceptedSpy.count, 0,
            "Closing must never announce an element")
    }

    function test_acceptingAnnouncesOneElementAndCloses() {
        dialog.openFor("app")
        tryVerify(function() {
            return dialog.opened
        })

        controller.draft.command = "firefox"
        controller.draft.name = "Firefox"
        controller.markEdited()
        tryVerify(function() {
            return Boolean(addButton().enabled)
        })

        addButton().clicked()
        tryVerify(function() {
            return !dialog.opened
        })

        compare(acceptedSpy.count, 1, "Accepting must announce the element once")
        compare(String(acceptedSpy.signalArguments[0][0].command), "firefox")
        compare(controller.draft, null)
        compare(controller.items.length, 0,
            "The dialog must not insert the element itself")
    }

    function test_singletonRaceDisablesAddAndExplainsWhy() {
        dialog.openFor("media")
        tryVerify(function() {
            return dialog.opened
        })
        compare(String(controller.draftType), "media")
        verify(addButton().enabled)

        controller.items = [{"type": "media"}]
        tryVerify(function() {
            return !addButton().enabled
        }, 2000, "A singleton that appeared meanwhile must disable Add")
        const message = findChild(dialog,
            "itemConfigurationUnavailableMessage")
        verify(message !== null)
        tryVerify(function() {
            return message.visible && String(message.text).length > 0
        }, 2000, "The rejected singleton must expose its reason")
        compare(dialog.acceptDraft(), false)
        compare(acceptedSpy.count, 0)
        verify(controller.draft !== null,
            "A rejected confirmation must keep the draft visible")

        dialog.cancelDraft()
        controller.items = []
    }

    function test_changingTypeWithAnEditedDraftAsksFirst() {
        dialog.openFor("app")
        tryVerify(function() {
            return dialog.opened
        })

        // An edited draft cannot be replaced without an answer: the dialog offers
        // the discard instead of changing the type on its own.
        controller.draft.command = "firefox"
        controller.markEdited()
        dialog.requestType("note")
        compare(String(dialog.pendingTypeChange), "note")
        compare(String(controller.draftType), "app",
            "The draft must wait for the answer")

        findChild(dialog, "itemConfigurationKeepButton").clicked()
        compare(String(dialog.pendingTypeChange), "")
        compare(String(controller.draftType), "app",
            "Keeping the draft must not change its type")

        dialog.requestType("note")
        findChild(dialog, "itemConfigurationDiscardButton").clicked()
        compare(String(controller.draftType), "note")
        compare(String(dialog.pendingTypeChange), "")

        dialog.cancelDraft()
    }

    function test_openingClosingAndRecreatingKeepsNoState() {
        for (let round = 0; round < 3; round++) {
            dialog.openFor("note")
            tryVerify(function() {
                return dialog.opened
            })
            compare(String(controller.draftType), "note")
            dialog.cancelDraft()
            tryVerify(function() {
                return !dialog.opened
            })
            tryVerify(function() {
                return controller.draft === null
            })
        }

        // A second instance must be able to open and close in the same window.
        // It shares the controller with the first one, so this also checks that a
        // late close of the previous surface cannot discard the new draft.
        const second = secondDialogComponent.createObject(testCase)
        verify(second !== null, "The dialog must be instantiable again")
        second.draftController = controller
        second.openFor("separator")
        tryVerify(function() {
            return second.opened
        })
        compare(String(controller.draftType), "separator")
        second.cancelDraft()
        tryVerify(function() {
            return !second.opened
        })
        tryVerify(function() {
            return controller.draft === null
        })
        second.destroy()
    }

    Component {
        id: secondDialogComponent

        Config.ItemConfigurationDialog {}
    }

    readonly property var formTypes: [
        {"type": "app", "itemType": "app", "mode": "app"},
        {"type": "folder", "itemType": "folder", "mode": "container"},
        {"type": "note", "itemType": "note", "mode": "note"},
        {"type": "separator", "itemType": "separator", "mode": "separator"},
        {"type": "spacer", "itemType": "spacer", "mode": "spacer"},
        {"type": "dynamic-applications", "itemType": "dynamic-applications", "mode": "dynamic-applications"}
    ]

    function editorPanel() {
        return findChild(dialog, "itemConfigurationEditorPanel")
    }

    function typeSelector() {
        return findChild(dialog, "itemConfigurationTypeSelector")
    }

    function actionEditor() {
        return findChild(dialog, "itemConfigurationActionEditor")
    }

    function test_theApplicationFormKeepsLabelsBesideTheirFields() {
        dialog.openFor("app")
        tryVerify(function() {
            return dialog.opened
        })
        wait(0)

        const typeRow = findChild(editorPanel(), "itemEditorTypeRow")
        const aliasLabel = findChild(editorPanel(), "itemEditorAliasLabel")
        const aliasRow = findChild(editorPanel(), "itemEditorAliasRow")
        const nameLabel = findChild(editorPanel(), "itemEditorNameLabel")
        const nameRow = findChild(editorPanel(), "itemEditorNameRow")
        verify(typeRow !== null && aliasLabel !== null && aliasRow !== null)
        verify(nameLabel !== null && nameRow !== null)
        compare(typeRow.visible, false,
            "The hidden internal type selector must not leave an empty grid cell")
        verify(Math.abs((aliasLabel.y + aliasLabel.height / 2)
                - (aliasRow.y + aliasRow.height / 2)) <= 1,
            "Alias must stay on the same row as its editor")
        verify(aliasLabel.x < aliasRow.x,
            "Alias must precede its editor")
        verify(Math.abs((nameLabel.y + nameLabel.height / 2)
                - (nameRow.y + nameRow.height / 2)) <= 1,
            "Name must stay on the same row as its editor")
        verify(nameLabel.x < nameRow.x,
            "Name must precede its editor")

        dialog.cancelDraft()
    }

    function test_eachAvailableSelectorOptionLoadsItsConfiguration() {
        const expected = [
            {"type": "app", "mode": "app", "form": true},
            {"type": "folder", "mode": "container", "form": true},
            {"type": "note", "mode": "note", "form": true},
            {"type": "separator", "mode": "separator", "form": true},
            {"type": "spacer", "mode": "spacer", "form": true},
            {"type": "punchimenu", "mode": "app", "form": false},
            {"type": "control-center", "mode": "app", "form": false},
            {"type": "dynamic-applications", "mode": "dynamic-applications", "form": true},
            {"type": "media", "mode": "app", "form": false},
            {"type": "trash", "mode": "app", "form": false},
            {"type": "calendar", "mode": "app", "form": false}
        ]
        dialog.openFor("app")
        tryVerify(function() {
            return dialog.opened
        })

        for (let index = 0; index < expected.length; index++) {
            const entry = expected[index]
            const selectorIndex = typeSelector().indexOfType(entry.type)
            verify(selectorIndex >= 0, "The catalogue must expose " + entry.type)
            compare(typeSelector().requestIndex(selectorIndex), true,
                "The available row must request " + entry.type)
            tryCompare(controller, "draftType", entry.type)
            compare(String(typeSelector().selectedType), entry.type)
            compare(dialog.formEditorVisible, entry.form,
                "The correct editor kind must load for " + entry.type)
            if (entry.form) {
                compare(String(editorPanel().itemModeValue), entry.mode,
                    "The shared form must load the mode of " + entry.type)
            } else {
                verify(dialog.optionsPanelVisible,
                    "The extracted options panel must load for " + entry.type)
            }
        }

        dialog.cancelDraft()
    }

    function nestedModelCount() {
        return findChild(dialog, "itemConfigurationDraftArea") === null
            ? -1 : actionEditor().actionCount
    }

    function test_theApplicationActionsFollowTheDraft() {
        dialog.openFor("app")
        tryVerify(function() {
            return dialog.opened
        })
        editorPanel().appCommandText = "firefox"
        dialog.formChanged()

        actionEditor().actionsEnabledToggled(true)
        compare(controller.nestedCount(), 0)
        compare(controller.draftEdited, true)

        actionEditor().addActionRequested()
        compare(controller.nestedCount(), 1, "Adding must write the draft once")
        compare(dialog.selectedActionIndex, 0, "The new action must be selected")
        tryVerify(function() {
            return actionEditor().actionCount === 1
        }, 2000, "The projection must be rebuilt from the draft")

        actionEditor().actionNameText = "New window"
        actionEditor().actionCommandText = "firefox --new-window"
        actionEditor().actionFormChanged()
        compare(String(controller.draftArray("actions")[0].name), "New window")
        compare(String(controller.draftArray("actions")[0].command),
            "firefox --new-window")

        actionEditor().addActionRequested()
        compare(controller.nestedCount(), 2)
        actionEditor().actionNameText = "Second"
        actionEditor().actionFormChanged()
        actionEditor().moveActionRequested(-1)
        compare(String(controller.draftArray("actions")[0].name), "Second",
            "Moving must reorder the array of the draft")
        compare(dialog.selectedActionIndex, 0)

        actionEditor().removeActionRequested()
        compare(controller.nestedCount(), 1, "Removing must write the draft")
        tryVerify(function() {
            return actionEditor().actionCount === 1
        }, 2000, "The projection must follow the removal")

        actionEditor().actionPopupLimitRowsChecked = true
        actionEditor().actionPopupMaxVisibleRowsValue = 8
        actionEditor().actionPopupSettingsChanged()
        compare(Number(controller.draft.actionPopupMaxVisibleRows), 8)
        actionEditor().actionPopupLimitRowsChecked = false
        actionEditor().actionPopupSettingsChanged()
        compare(controller.draft.actionPopupMaxVisibleRows, undefined,
            "Clearing the limit must remove the field, not leave a stale value")

        dialog.cancelDraft()
        tryVerify(function() {
            return !dialog.opened
        })
    }

    function test_theContainerApplicationsFollowTheDraft() {
        dialog.openFor("folder")
        tryVerify(function() {
            return dialog.opened
        })
        compare(dialog.selectedActionIndex, -1)

        actionEditor().addActionRequested()
        compare(controller.nestedCount(), 1)
        actionEditor().actionNameText = "Files"
        actionEditor().actionCommandText = "dolphin"
        actionEditor().actionFormChanged()
        compare(String(controller.draftArray("apps")[0].name), "Files")

        actionEditor().addActionRequested()
        actionEditor().actionNameText = "Terminal"
        actionEditor().actionFormChanged()
        actionEditor().moveActionRequested(-1)
        compare(String(controller.draftArray("apps")[0].name), "Terminal")

        actionEditor().removeActionRequested()
        compare(controller.nestedCount(), 1)
        compare(String(controller.draftArray("apps")[0].name), "Files",
            "Removing must keep the other application of the draft")

        dialog.cancelDraft()
        tryVerify(function() {
            return !dialog.opened
        })
    }

    function test_onlyApplicationAndContainerShowTheNestedList() {
        const expected = [
            {"type": "app", "visible": true},
            {"type": "folder", "visible": true},
            {"type": "note", "visible": false},
            {"type": "spacer", "visible": false},
            {"type": "separator", "visible": false},
            {"type": "dynamic-applications", "visible": false}
        ]
        for (let index = 0; index < expected.length; index++) {
            dialog.openFor(expected[index].type)
            tryVerify(function() {
                return dialog.opened
            })
            compare(dialog.nestedEditorVisible, expected[index].visible,
                "The nested list must follow the type: " + expected[index].type)
            dialog.cancelDraft()
            tryVerify(function() {
                return !dialog.opened
            })
        }
    }

    function test_theInitialSynchronizationRebuildsTheProjectionWithoutEditing() {
        dialog.openFor("app")
        tryVerify(function() {
            return dialog.opened
        })
        compare(controller.draftEdited, false,
            "Showing the draft must not count as an edit")
        tryVerify(function() {
            return actionEditor().actionCount === controller.nestedCount()
        }, 2000, "The projection must follow the draft from the first moment")

        dialog.cancelDraft()
        tryVerify(function() {
            return !dialog.opened
        })
    }

    function test_changingTypeClearsTheNestedModelAndTheSelection() {
        dialog.openFor("app")
        tryVerify(function() {
            return dialog.opened
        })
        actionEditor().actionsEnabledToggled(true)
        actionEditor().addActionRequested()
        compare(dialog.selectedActionIndex, 0)

        dialog.requestType("spacer")
        findChild(dialog, "itemConfigurationDiscardButton").clicked()
        wait(0)

        compare(String(controller.draftType), "spacer")
        compare(dialog.selectedActionIndex, -1,
            "The selection must not survive a new draft")
        tryVerify(function() {
            return actionEditor().actionCount === 0
        }, 2000, "The projection must be rebuilt for the new draft")
        compare(controller.draftEdited, false)

        dialog.cancelDraft()
        tryVerify(function() {
            return !dialog.opened
        })
    }

    function test_cancellingDiscardsTheActionsOfTheDraft() {
        dialog.openFor("app")
        tryVerify(function() {
            return dialog.opened
        })
        editorPanel().appCommandText = "firefox"
        dialog.formChanged()
        actionEditor().actionsEnabledToggled(true)
        actionEditor().addActionRequested()
        const itemsBefore = controller.items

        dialog.cancelDraft()
        tryVerify(function() {
            return controller.draft === null
        })

        compare(dialog.selectedActionIndex, -1)
        tryVerify(function() {
            return actionEditor().actionCount === 0
        }, 2000, "The projection must be dropped with the draft")
        compare(controller.items, itemsBefore)
        compare(acceptedSpy.count, 0)
    }

    function test_acceptingEmitsOneCopyWithTheConfiguredArrays() {
        dialog.openFor("app")
        tryVerify(function() {
            return dialog.opened
        })
        editorPanel().appCommandText = "firefox"
        dialog.formChanged()
        actionEditor().actionsEnabledToggled(true)
        actionEditor().addActionRequested()
        actionEditor().actionNameText = "Private window"
        actionEditor().actionCommandText = "firefox --private-window"
        actionEditor().actionFormChanged()

        tryVerify(function() {
            return Boolean(addButton().enabled)
        })
        addButton().clicked()
        tryVerify(function() {
            return !dialog.opened
        })

        compare(acceptedSpy.count, 1)
        const snapshot = acceptedSpy.signalArguments[0][0]
        compare(String(snapshot.command), "firefox")
        compare(snapshot.actions.length, 1)
        compare(String(snapshot.actions[0].name), "Private window")
        compare(controller.items.length, 0)
    }

    function test_closingAndReopeningKeepsNoSelection() {
        dialog.openFor("app")
        tryVerify(function() {
            return dialog.opened
        })
        actionEditor().actionsEnabledToggled(true)
        actionEditor().addActionRequested()
        compare(dialog.selectedActionIndex, 0)

        dialog.close()
        tryVerify(function() {
            return !dialog.opened
        })
        tryVerify(function() {
            return dialog.selectedActionIndex === -1
        }, 2000, "Closing must forget the selection of the list")
    }

    function test_everyFormTypeShowsItsOwnFormWithoutASecondSelector() {
        for (let index = 0; index < formTypes.length; index++) {
            const expected = formTypes[index]
            dialog.openFor(expected.type)
            tryVerify(function() {
                return dialog.opened
            })
            verify(dialog.formEditorVisible,
                "The form of " + expected.type + " must be shown")

            const panel = editorPanel()
            verify(panel !== null, "The dialog must host the shared item form")
            compare(Boolean(panel.showTypeSelector), false,
                "The form must not offer a second type selector: " + expected.type)
            compare(String(panel.selectedItemType), expected.itemType,
                "The form must follow the type of the draft: " + expected.type)
            compare(String(panel.itemModeValue), expected.mode,
                "The form must show the fields of its type: " + expected.type)

            dialog.cancelDraft()
            tryVerify(function() {
                return !dialog.opened
            })
        }
    }

    function test_theInitialSynchronizationIsNotAnEdit() {
        dialog.openFor("note")
        tryVerify(function() {
            return dialog.opened
        })

        compare(controller.draftEdited, false,
            "Showing the draft in the form must not count as an edit")
        compare(String(editorPanel().appNameText), String(controller.draft.name),
            "The form must show the values of the draft")

        dialog.cancelDraft()
        tryVerify(function() {
            return !dialog.opened
        })
    }

    function test_editingThroughTheFormWritesOnlyIntoTheDraft() {
        dialog.openFor("app")
        tryVerify(function() {
            return dialog.opened
        })
        const itemsBefore = controller.items

        editorPanel().appNameText = "Firefox"
        editorPanel().appCommandText = "firefox"
        dialog.formChanged()
        wait(0)

        compare(String(controller.draft.name), "Firefox")
        compare(String(controller.draft.command), "firefox")
        compare(controller.draftEdited, true,
            "Editing the draft must mark it as edited")
        compare(controller.items, itemsBefore,
            "The form must not touch the dock item list")
        compare(controller.items.length, 0)

        dialog.cancelDraft()
        tryVerify(function() {
            return !dialog.opened
        })
    }

    function test_theTypeChangeConfirmationAlsoResetsTheForm() {
        dialog.openFor("note")
        tryVerify(function() {
            return dialog.opened
        })
        editorPanel().appNameText = "Draft name"
        dialog.formChanged()
        wait(0)
        compare(controller.draftEdited, true)

        dialog.requestType("spacer")
        compare(String(dialog.pendingTypeChange), "spacer",
            "An edited draft must ask before changing its type")
        findChild(dialog, "itemConfigurationDiscardButton").clicked()
        wait(0)

        compare(String(controller.draftType), "spacer")
        compare(controller.draftEdited, false,
            "A new draft must start clean")
        compare(String(editorPanel().selectedItemType), "spacer",
            "The form must follow the new draft")
        verify(String(editorPanel().appNameText) !== "Draft name",
            "The form must not keep the fields of the discarded draft")

        dialog.cancelDraft()
        tryVerify(function() {
            return !dialog.opened
        })
    }

    function test_cancellingDiscardsFieldsAndNestedArrays() {
        dialog.openFor("folder")
        tryVerify(function() {
            return dialog.opened
        })
        const itemsBefore = controller.items

        editorPanel().appNameText = "Container name"
        dialog.formChanged()
        controller.setDraftArray("apps", [{"name": "One", "command": "one"}])
        wait(0)
        compare(controller.draftArray("apps").length, 1,
            "The nested array must live in the draft")

        dialog.cancelDraft()
        tryVerify(function() {
            return controller.draft === null
        })

        compare(controller.items, itemsBefore)
        compare(controller.items.length, 0)
        compare(acceptedSpy.count, 0)
    }

    function test_acceptingEmitsOneSnapshotAndInsertsNothing() {
        dialog.openFor("spacer")
        tryVerify(function() {
            return dialog.opened
        })

        editorPanel().spacerSizeValue = 48
        dialog.formChanged()
        tryVerify(function() {
            return Boolean(addButton().enabled)
        })

        addButton().clicked()
        tryVerify(function() {
            return !dialog.opened
        })

        compare(acceptedSpy.count, 1, "The snapshot must be announced once")
        compare(Number(acceptedSpy.signalArguments[0][0].size), 48,
            "The snapshot must carry what the draft held")
        compare(controller.items.length, 0,
            "The dialog must not insert the element itself")
    }
}
