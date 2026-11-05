// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtTest
import "../contents/ui/components" as Components
import "../contents/ui/config/code/configItems.js" as Items

// The fan is the only folder presentation that declares how many entries it
// leaves out, so a single container may choose that amount. The dock value
// stays as the way back: the menu must offer both, mark the current choice and
// forward it with the identity of the container the menu was opened on.
TestCase {
    id: testCase
    name: "FolderFanVisibleRows"

    property var fanFolder: ({
        "type": "folder",
        "name": "Projects",
        "icon": "folder",
        "layout": "fan",
        "sourceType": "manual",
        "apps": []
    })

    // A container that points at a real folder: it is the only kind that can
    // decide its own scrolling, because only it has a closing row that opens
    // the entries the fan would leave out.
    property var folderContainer: ({
        "type": "folder",
        "name": "Projects",
        "icon": "folder",
        "layout": "fan",
        "sourceType": "folder",
        "sourcePath": "/home/user/Projects",
        "apps": []
    })

    property var gridFolder: ({
        "type": "folder",
        "name": "Projects",
        "icon": "folder",
        "layout": "grid",
        "sourceType": "manual",
        "apps": []
    })

    QtObject {
        id: fakeTaskController

        function dockItemApplicationId() { return "" }
        function dockItemLauncherUrl() { return "" }
    }

    QtObject {
        id: fakeDockItemsController

        property var dockItems: [testCase.fanFolder]
        property int callCount: 0
        property int lastTargetIndex: -1
        property int lastRows: -1
        property string lastExpectedFolderText: ""
        property int scrollCallCount: 0
        property var lastScroll: undefined
        property string lastScrollExpectedFolderText: ""

        function canonicalJsonText(value) {
            return JSON.stringify(value)
        }

        function setFolderFanVisibleRows(targetIndex, rows, expectedFolderText) {
            callCount++
            lastTargetIndex = targetIndex
            lastRows = rows
            lastExpectedFolderText = expectedFolderText
            return true
        }

        function setFolderFanScroll(targetIndex, value, expectedFolderText) {
            scrollCallCount++
            lastTargetIndex = targetIndex
            lastScroll = value
            lastScrollExpectedFolderText = expectedFolderText
            return true
        }
    }

    Components.DockContextActionsController {
        id: contextController
        taskController: fakeTaskController
        dockItemsController: fakeDockItemsController
        folderFanScrollEnabled: false
        configureDockHandler: function() { return true }
    }

    function init() {
        failOnWarning(/.?/)
        contextController.verticalDock = false
        contextController.folderFanScrollEnabled = false
        fakeDockItemsController.dockItems = [fanFolder]
        fakeDockItemsController.callCount = 0
        fakeDockItemsController.lastTargetIndex = -1
        fakeDockItemsController.lastRows = -1
        fakeDockItemsController.lastExpectedFolderText = ""
        fakeDockItemsController.scrollCallCount = 0
        fakeDockItemsController.lastScroll = undefined
        fakeDockItemsController.lastScrollExpectedFolderText = ""
    }

    function visibleItemsAction(actions) {
        for (let index = 0; index < actions.length; index++) {
            if (actions[index].name === "Visible items") {
                return actions[index]
            }
        }
        return null
    }

    function scrollingAction(actions) {
        for (let index = 0; index < actions.length; index++) {
            if (actions[index].name === "Scrolling") {
                return actions[index]
            }
        }
        return null
    }

    function scrollRowFor(children, value) {
        for (let index = 0; index < children.length; index++) {
            const stored = children[index].scroll
            if (value === null ? stored === null : stored === value) {
                return children[index]
            }
        }
        return null
    }

    function rowFor(children, rows) {
        for (let index = 0; index < children.length; index++) {
            if (children[index].rows === rows) {
                return children[index]
            }
        }
        return null
    }

    function test_normalizationKeepsTheSafeRange() {
        compare(Items.minimumFanVisibleRows(), 3)
        compare(Items.maximumFanVisibleRows(), 8)

        compare(Items.normalizedFanVisibleRows(undefined), 0)
        compare(Items.normalizedFanVisibleRows(null), 0)
        compare(Items.normalizedFanVisibleRows(""), 0)
        compare(Items.normalizedFanVisibleRows("many"), 0)
        compare(Items.normalizedFanVisibleRows(0), 0)
        compare(Items.normalizedFanVisibleRows(-3), 0)

        // Below the floor the value becomes the floor instead of losing the
        // container choice, and above it the ceiling is the last row that fits.
        compare(Items.normalizedFanVisibleRows(1), 3)
        compare(Items.normalizedFanVisibleRows(2), 3)
        compare(Items.normalizedFanVisibleRows(3), 3)
        compare(Items.normalizedFanVisibleRows(6.4), 6)
        compare(Items.normalizedFanVisibleRows(8), 8)
        compare(Items.normalizedFanVisibleRows(40), 8)
    }

    function test_containerChoiceWinsAndTheDockValueFollows() {
        compare(Items.fanRowLimitFor({"fanVisibleRows": 4}, 7), 4)
        compare(Items.fanRowLimitFor({}, 7), 7)
        compare(Items.fanRowLimitFor({"fanVisibleRows": 0}, 7), 7)
        compare(Items.fanRowLimitFor({"fanVisibleRows": 40}, 7), 8)
        // Neither side of the precedence can fall below the safe range.
        compare(Items.fanRowLimitFor({"fanVisibleRows": 1}, 7), 3)
        compare(Items.fanRowLimitFor({}, 2), 3)
        // A dock that never stored a value keeps the historical default.
        compare(Items.fanRowLimitFor({}, 0), 6)
        compare(Items.fanRowLimitFor(null, undefined), 6)
    }

    function test_pruneKeepsAValidChoiceAndDropsTheRest() {
        const kept = { "type": "folder", "fanVisibleRows": 5 }
        Items.pruneFolder(kept)
        compare(kept.fanVisibleRows, 5)

        const clamped = { "type": "folder", "fanVisibleRows": 40 }
        Items.pruneFolder(clamped)
        compare(clamped.fanVisibleRows, 8)

        const raised = { "type": "folder", "fanVisibleRows": 1 }
        Items.pruneFolder(raised)
        compare(raised.fanVisibleRows, 3)

        const dropped = { "type": "folder", "fanVisibleRows": 0 }
        Items.pruneFolder(dropped)
        verify(dropped.fanVisibleRows === undefined)

        const unusable = { "type": "folder", "fanVisibleRows": "many" }
        Items.pruneFolder(unusable)
        verify(unusable.fanVisibleRows === undefined)
    }

    function test_setterStoresAndRemovesTheOverride() {
        const items = [fanFolder]

        const applied = Items.setFolderFanVisibleRows(items, 0, 4)
        verify(applied.changed)
        compare(applied.items[0].fanVisibleRows, 4)
        // The array the caller owns is never mutated in place.
        verify(items[0].fanVisibleRows === undefined)

        const repeated = Items.setFolderFanVisibleRows(applied.items, 0, 4)
        compare(repeated.status, "unchanged")

        const cleared = Items.setFolderFanVisibleRows(applied.items, 0, 0)
        verify(cleared.changed)
        verify(cleared.items[0].fanVisibleRows === undefined)
    }

    function test_setterRejectsForeignTargets() {
        compare(Items.setFolderFanVisibleRows([fanFolder], 3, 4).status,
            "invalid-target")
        compare(Items.setFolderFanVisibleRows([{ "type": "app" }], 0, 4).status,
            "invalid-target")
        compare(Items.setFolderFanVisibleRows(null, 0, 4).status,
            "invalid-target")
    }

    function test_leavingTheContainerDropsTheChoice() {
        // The amount describes a fan container. Turning that item into another
        // type must not carry a key that no consumer reads.
        const chosen = Object.assign({}, fanFolder, { "fanVisibleRows": 5 })
        const converted = Items.setItemMode([chosen], 0, "app")
        verify(converted[0].fanVisibleRows === undefined)
    }

    function test_fanMenuOffersDefaultAndTheSafeRange() {
        const actions = contextController.actionsForItem(fanFolder, [], "pinned", 0)
        const submenu = visibleItemsAction(actions)
        verify(submenu !== null)
        compare(submenu.kind, "submenu")
        compare(submenu.children.length, 7)

        // A container that never chose an amount says so with the first row.
        const defaultRow = submenu.children[0]
        compare(defaultRow.kind, "setFolderFanVisibleRows")
        compare(defaultRow.name, "Default")
        verify(defaultRow.checked)
        verify(defaultRow.exclusive)

        for (let rows = 3; rows <= 8; rows++) {
            const row = rowFor(submenu.children, rows)
            verify(row !== null)
            compare(row.kind, "setFolderFanVisibleRows")
            compare(row.name, rows + " items")
            verify(!row.checked)
            verify(row.exclusive)
        }
        // The unsafe range is not offered at all.
        compare(rowFor(submenu.children, 1), null)
        compare(rowFor(submenu.children, 2), null)
    }

    function test_theStoredChoiceIsTheCheckedRow() {
        const chosen = Object.assign({}, fanFolder, { "fanVisibleRows": 3 })
        const actions = contextController.actionsForItem(chosen, [], "pinned", 0)
        const submenu = visibleItemsAction(actions)
        verify(submenu !== null)

        verify(!submenu.children[0].checked)
        verify(rowFor(submenu.children, 3).checked)
        verify(!rowFor(submenu.children, 4).checked)

        // A stored value below the safe range marks the floor, not a row the
        // menu no longer offers.
        const legacy = Object.assign({}, fanFolder, { "fanVisibleRows": 1 })
        const legacyMenu = visibleItemsAction(
            contextController.actionsForItem(legacy, [], "pinned", 0))
        verify(legacyMenu !== null)
        verify(!legacyMenu.children[0].checked)
        verify(rowFor(legacyMenu.children, 3).checked)
    }

    function test_theRowForwardsTheChoiceAndTheIdentity() {
        const actions = contextController.actionsForItem(fanFolder, [], "pinned", 0)
        const submenu = visibleItemsAction(actions)

        verify(contextController.triggerAction(rowFor(submenu.children, 4)))
        compare(fakeDockItemsController.callCount, 1)
        compare(fakeDockItemsController.lastTargetIndex, 0)
        compare(fakeDockItemsController.lastRows, 4)
        compare(fakeDockItemsController.lastExpectedFolderText,
            JSON.stringify(fanFolder))
    }

    function test_theDefaultRowClearsInsteadOfCopyingTheDockValue() {
        const chosen = Object.assign({}, fanFolder, { "fanVisibleRows": 3 })
        const actions = contextController.actionsForItem(chosen, [], "pinned", 0)
        const submenu = visibleItemsAction(actions)

        verify(!submenu.children[0].checked)
        verify(rowFor(submenu.children, 3).checked)
        verify(contextController.triggerAction(submenu.children[0]))
        compare(fakeDockItemsController.callCount, 1)
        compare(fakeDockItemsController.lastRows, 0)
    }

    function test_scrollNormalizationKeepsAFalseChoice() {
        compare(Items.normalizedFanScroll(true), true)
        compare(Items.normalizedFanScroll(false), false)
        compare(Items.normalizedFanScroll(undefined), null)
        compare(Items.normalizedFanScroll(null), null)
        compare(Items.normalizedFanScroll("true"), null)

        // A stored false is a real choice, not a missing value.
        compare(Items.fanScrollFor({"fanScrollEnabled": false}, true), false)
        compare(Items.fanScrollFor({"fanScrollEnabled": true}, false), true)
        compare(Items.fanScrollFor({}, true), true)
        compare(Items.fanScrollFor({}, false), false)
        compare(Items.fanScrollFor(null, undefined), false)
    }

    function test_scrollSetterStoresTheChoice() {
        const items = [fanFolder]

        const allowed = Items.setFolderFanScroll(items, 0, true)
        verify(allowed.changed)
        compare(allowed.items[0].fanScrollEnabled, true)
        verify(items[0].fanScrollEnabled === undefined)

        const refused = Items.setFolderFanScroll(allowed.items, 0, false)
        verify(refused.changed)
        compare(refused.items[0].fanScrollEnabled, false)

        const repeated = Items.setFolderFanScroll(refused.items, 0, false)
        compare(repeated.status, "unchanged")

        // Only a real choice is stored: the menu offers two states and nothing
        // else, so a non boolean never reaches the model.
        compare(Items.setFolderFanScroll(refused.items, 0, null).status,
            "invalid-value")
        compare(Items.setFolderFanScroll(refused.items, 0, "yes").status,
            "invalid-value")
    }

    function test_scrollSetterRejectsForeignTargets() {
        compare(Items.setFolderFanScroll([fanFolder], 5, true).status,
            "invalid-target")
        compare(Items.setFolderFanScroll([{ "type": "app" }], 0, true).status,
            "invalid-target")
    }

    function test_pruneKeepsAStoredScrollChoice() {
        const kept = { "type": "folder", "fanScrollEnabled": false }
        Items.pruneFolder(kept)
        compare(kept.fanScrollEnabled, false)

        const unusable = { "type": "folder", "fanScrollEnabled": "yes" }
        Items.pruneFolder(unusable)
        verify(unusable.fanScrollEnabled === undefined)
    }

    function test_leavingTheContainerDropsTheScrollChoice() {
        const chosen = Object.assign({}, folderContainer, {
            "fanScrollEnabled": true
        })
        const converted = Items.setItemMode([chosen], 0, "app")
        verify(converted[0].fanScrollEnabled === undefined)
    }

    function test_scrollingMenuOffersTwoStates() {
        const actions = contextController.actionsForItem(folderContainer, [],
            "pinned", 0)
        const submenu = scrollingAction(actions)
        verify(submenu !== null)
        compare(submenu.kind, "submenu")
        compare(submenu.children.length, 2)

        compare(submenu.children[0].name, "Allow")
        compare(submenu.children[1].name, "Don't allow")

        for (let index = 0; index < submenu.children.length; index++) {
            verify(submenu.children[index].enabled,
                "A container with a folder decides its own scrolling")
            verify(submenu.children[index].exclusive)
            compare(submenu.children[index].kind, "setFolderFanScroll")
        }
    }

    function test_scrollingMenuMarksTheDockValueUntilTheContainerChooses() {
        const actions = contextController.actionsForItem(folderContainer, [],
            "pinned", 0)
        const submenu = scrollingAction(actions)
        // The dock value is false in the fixture, so that is what is marked.
        verify(scrollRowFor(submenu.children, false).checked)
        verify(!scrollRowFor(submenu.children, true).checked)

        contextController.folderFanScrollEnabled = true
        const dockOn = scrollingAction(contextController.actionsForItem(
            folderContainer, [], "pinned", 0))
        verify(scrollRowFor(dockOn.children, true).checked)
        verify(!scrollRowFor(dockOn.children, false).checked)
    }

    function test_scrollingMarksTheStoredChoiceOverTheDockValue() {
        contextController.folderFanScrollEnabled = true

        const refuse = Object.assign({}, folderContainer, {
            "fanScrollEnabled": false
        })
        const refuseMenu = scrollingAction(
            contextController.actionsForItem(refuse, [], "pinned", 0))
        verify(!scrollRowFor(refuseMenu.children, true).checked)
        verify(scrollRowFor(refuseMenu.children, false).checked)

        const allow = Object.assign({}, folderContainer, {
            "fanScrollEnabled": true
        })
        const allowMenu = scrollingAction(
            contextController.actionsForItem(allow, [], "pinned", 0))
        verify(scrollRowFor(allowMenu.children, true).checked)
        verify(!scrollRowFor(allowMenu.children, false).checked)
    }

    function test_scrollingRowsForwardTheChoiceAndTheIdentity() {
        const actions = contextController.actionsForItem(folderContainer, [],
            "pinned", 0)
        const submenu = scrollingAction(actions)

        verify(contextController.triggerAction(
            scrollRowFor(submenu.children, false)))
        compare(fakeDockItemsController.scrollCallCount, 1)
        compare(fakeDockItemsController.lastScroll, false)
        compare(fakeDockItemsController.lastScrollExpectedFolderText,
            JSON.stringify(folderContainer))

        verify(contextController.triggerAction(
            scrollRowFor(submenu.children, true)))
        compare(fakeDockItemsController.scrollCallCount, 2)
        compare(fakeDockItemsController.lastScroll, true)
    }

    function test_aContainerWithoutFolderHidesTheScrollingChoice() {
        // No closing row could open the entries a static fan omits, so the fan
        // always scrolls and there is nothing to choose. The choice is absent
        // instead of a disabled control, while the amount stays available
        // because it still sizes the band.
        const actions = contextController.actionsForItem(fanFolder, [], "pinned", 0)
        compare(scrollingAction(actions), null)
        verify(visibleItemsAction(actions) !== null)
    }

    function test_otherLayoutsDoNotOfferTheFanChoices() {
        const actions = contextController.actionsForItem(gridFolder, [], "pinned", 0)
        compare(visibleItemsAction(actions), null)
        compare(scrollingAction(actions), null)
    }

    function test_aVerticalDockDoesNotOfferTheFanChoices() {
        // A vertical dock resolves the fan to the grid, so both choices would
        // be controls with no visible effect.
        contextController.verticalDock = true
        const actions = contextController.actionsForItem(fanFolder, [], "pinned", 0)
        compare(visibleItemsAction(actions), null)
        compare(scrollingAction(actions), null)
    }
}
