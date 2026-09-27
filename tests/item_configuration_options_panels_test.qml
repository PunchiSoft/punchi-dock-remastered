// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtTest
import QtQuick.Controls as Controls
import "../contents/ui/config" as Config

// Integration of the extracted options panels with the «Add item» dialog.
//
// The dialog resolves the editor key the catalogue names for the drafted type and
// loads the matching panel; the panel announces what the user asked for and the
// dialog writes it into the draft through the controller, which keeps the only copy
// of the data. Accepting is the only path that delivers the element, so cancelling
// and changing type must leave no value of the panel behind.
TestCase {
    id: testCase

    name: "ItemConfigurationOptionsPanels"
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
        id: iconSpy
        target: dialog
        signalName: "iconPickerRequested"
    }

    function init() {
        failOnWarning(/.?/)
        controller.items = []
        controller.cancel()
        acceptedSpy.clear()
        iconSpy.clear()
        // The item a loader drops is deleted one event loop turn later, so no
        // panel of the previous case may stay in the tree: a stale instance would
        // be found instead of the live one and would answer nothing.
        waitForEmptyTree()
    }

    function panelComboInPanel(panel) {
        const punchiMenu = findChild(panel, "punchiMenuModeCombo")
        return punchiMenu !== null
            ? punchiMenu : findChild(panel, "controlCenterModeCombo")
    }

    function punchiMenuPanel() {
        return findChild(dialog, "itemConfigurationPunchiMenuPanel")
    }

    function controlCenterPanel() {
        return findChild(dialog, "itemConfigurationControlCenterPanel")
    }

    function openFor(type) {
        dialog.openFor(type)
        tryVerify(function() {
            return dialog.opened
        }, 2000, "The dialog must open")
        // The loader creates and drops its item one event loop turn later, so the
        // tree is waited for before it is used.
        tryVerify(function() {
            return treeIsSettled()
        }, 2000, "The options panel of the type must be created or absent")
    }

    // True when the loaded panel matches the drafted type and no stale panel of
    // another type is still in the tree.
    function treeIsSettled() {
        const key = String(controller.draftType)
        const punchiMenu = punchiMenuPanel() !== null
        const controlCenter = controlCenterPanel() !== null
        if (key === "punchimenu") {
            return punchiMenu && !controlCenter
        }
        if (key === "control-center") {
            return controlCenter && !punchiMenu
        }
        return !punchiMenu && !controlCenter
    }

    function waitForEmptyTree() {
        tryVerify(function() {
            return punchiMenuPanel() === null && controlCenterPanel() === null
        }, 2000, "No options panel may stay in the tree")
    }

    // Index of a mode inside the model of a combo. The lookup is done by hand so
    // the case does not depend on the array helpers of a model read from QML.
    function modeIndexIn(combo, value) {
        const model = combo.model
        for (let index = 0; index < model.length; index++) {
            if (String(model[index].value) === String(value)) {
                return index
            }
        }
        return -1
    }

    function chooseMode(panel, value) {
        const combo = panelComboInPanel(panel)
        verify(combo !== null, "The panel must show its list of modes")
        const index = modeIndexIn(combo, value)
        verify(index >= 0, "The mode must be listed by the panel: " + value)
        combo.activated(index)
    }

    function test_theCatalogKeyDecidesWhichPanelIsLoaded() {
        openFor("punchimenu")
        const punchiMenu = punchiMenuPanel()
        verify(punchiMenu !== null,
            "The PunchiMenu type must load its options panel")
        compare(controlCenterPanel(), null,
            "Only the panel of the drafted type may be loaded")
        const combo = panelComboInPanel(punchiMenu)
        compare(combo.currentIndex, punchiMenu.modeIndex("normal"),
            "The panel must show the mode of a new item")

        dialog.cancelDraft()
        tryVerify(function() {
            return !dialog.opened
        })
        waitForEmptyTree()

        openFor("control-center")
        const controlCenter = controlCenterPanel()
        verify(controlCenter !== null,
            "The Control Center type must load its options panel")
        compare(punchiMenuPanel(), null,
            "The panel of the previous type must be gone")
        compare(panelComboInPanel(controlCenter).currentIndex,
            controlCenter.modeIndex("floating"),
            "The panel must show the mode of a new item")
    }

    function test_initialSynchronizationIsNotAnEdit() {
        openFor("punchimenu")
        verify(punchiMenuPanel() !== null)
        compare(controller.draftEdited, false,
            "Showing the draft must not mark it as edited")
        const revision = controller.draftRevision

        chooseMode(punchiMenuPanel(), "compact")
        compare(controller.draftEdited, true,
            "A choice of the user must mark the draft as edited")
        verify(controller.draftRevision > revision,
            "A choice of the user must bump the revision of the draft")
        compare(String(controller.draft.menuMode), "compact",
            "The panel writes only through the controller")
        compare(String(controller.draft.icon), "start-here-kde",
            "Choosing a mode must not touch the icon of the draft")
    }

    function test_aValueWrittenElsewhereReachesThePanel() {
        openFor("punchimenu")
        const panel = punchiMenuPanel()
        verify(panel !== null)
        const combo = panelComboInPanel(panel)

        controller.setDraftValues({"menuMode": "fullScreen"})
        tryVerify(function() {
            return combo.currentIndex === panel.modeIndex("fullScreen")
        }, 2000, "A value written from outside must reach the shown selection")
    }

    function test_cancellingDiscardsTheValuesOfThePanel() {
        const itemsBefore = controller.items
        openFor("punchimenu")
        chooseMode(punchiMenuPanel(), "compact")
        compare(String(controller.draft.menuMode), "compact")

        dialog.cancelDraft()
        tryVerify(function() {
            return controller.draft === null
        }, 2000, "Cancelling must drop the draft")
        waitForEmptyTree()
        compare(controller.items, itemsBefore,
            "Cancelling must not touch the dock item list")
        compare(acceptedSpy.count, 0)

        openFor("punchimenu")
        compare(String(controller.draft.menuMode), "normal",
            "A new draft must start from the defaults again")
        compare(panelComboInPanel(punchiMenuPanel()).currentIndex,
            punchiMenuPanel().modeIndex("normal"))
    }

    function test_changingTypeDiscardsTheValuesOfThePanel() {
        openFor("punchimenu")
        chooseMode(punchiMenuPanel(), "compact")
        compare(String(controller.draft.menuMode), "compact")

        dialog.requestType("control-center")
        compare(dialog.pendingTypeChange, "control-center",
            "An edited draft must ask before changing type")
        dialog.confirmTypeChange()
        tryVerify(function() {
            return treeIsSettled()
        }, 2000, "The panel of the new type must replace the previous one")

        const controlCenter = controlCenterPanel()
        verify(controlCenter !== null, "The new type must load its own panel")
        compare(punchiMenuPanel(), null, "The previous panel must be gone")
        compare(controller.draft.menuMode, undefined,
            "No value of the previous type may survive")
        compare(String(controller.draft.controlCenterMode), "floating",
            "The new type must start from its own defaults")
    }

    function test_acceptingDeliversTheValuesOfThePanel() {
        openFor("punchimenu")
        chooseMode(punchiMenuPanel(), "compact")
        verify(dialog.acceptDraft())
        compare(acceptedSpy.count, 1, "Accepting must announce exactly one element")
        const accepted = acceptedSpy.signalArguments[0][0]
        compare(String(accepted.type), "punchimenu")
        compare(String(accepted.menuMode), "compact",
            "The snapshot must carry the value the panel set")
        compare(String(accepted.icon), "start-here-kde",
            "The snapshot must keep the icon the panel shows")

        openFor("control-center")
        chooseMode(controlCenterPanel(), "fullScreen")
        verify(dialog.acceptDraft())
        compare(acceptedSpy.count, 2)
        const controlCenter = acceptedSpy.signalArguments[1][0]
        compare(String(controlCenter.type), "control-center")
        compare(String(controlCenter.controlCenterMode), "fullScreen",
            "The snapshot must carry the mode the panel set")
    }

    function test_theIconRequestStaysAnUnconnectedAnnouncement() {
        openFor("punchimenu")
        const panel = punchiMenuPanel()
        verify(panel !== null)
        const button = findChild(panel, "punchiMenuIconButton")
        verify(button !== null)
        button.clicked()
        compare(iconSpy.count, 1, "The request must be announced exactly once")
        compare(iconSpy.signalArguments[0][0], "punchimenu",
            "The request must name the target the page expects")
        verify(dialog.opened, "The picker is not opened yet: nothing else happens")
        compare(acceptedSpy.count, 0)
    }

    function test_panelsSurviveCreationAndDestruction() {
        const types = ["punchimenu", "control-center", "app", "punchimenu"]
        for (let index = 0; index < types.length; index++) {
            openFor(types[index])
            const punchiMenu = punchiMenuPanel()
            const controlCenter = controlCenterPanel()
            if (String(types[index]) === "punchimenu") {
                verify(punchiMenu !== null, "The panel must load again")
                verify(controlCenter === null)
            } else if (String(types[index]) === "control-center") {
                verify(controlCenter !== null, "The panel must load again")
                verify(punchiMenu === null)
            } else {
                verify(punchiMenu === null && controlCenter === null,
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
