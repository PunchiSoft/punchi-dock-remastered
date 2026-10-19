// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import "../contents/ui/components/TaskContextActions.js" as TaskContextActions

TestCase {
    id: testCase
    name: "TaskContextActions"

    readonly property var labels: ({
        "moveToDesktop": "Move to Desktop",
        "moveToCurrentDesktop": "Move to Current Desktop",
        "allDesktops": "All Desktops",
        "newDesktop": "New Desktop",
        "more": "More",
        "move": "Move",
        "resize": "Resize",
        "maximize": "Maximize",
        "restoreFromMaximized": "Restore from maximized",
        "minimize": "Minimize",
        "restore": "Restore",
        "keepAbove": "Keep above",
        "doNotKeepAbove": "Do not keep above",
        "keepBelow": "Keep below",
        "doNotKeepBelow": "Do not keep below",
        "fullscreen": "Full screen",
        "exitFullscreen": "Exit full screen",
        "noBorder": "No Titlebar and Frame",
        "hideFromCapture": "Hide from Screencast",
        "close": "Close"
    })

    function snapshot(overrides) {
        const base = {
            "window": true,
            "taskRow": 3,
            "movable": true,
            "resizable": true,
            "maximizable": true,
            "maximized": false,
            "minimizable": true,
            "minimized": false,
            "keepAbove": false,
            "keepBelow": false,
            "fullscreenable": true,
            "fullscreen": false,
            "desktopChangeable": true,
            "onAllDesktops": false,
            "virtualDesktops": ["d1"],
            "desktops": [
                {"id": "d1", "name": "Desktop 1", "current": true},
                {"id": "d2", "name": "Desktop 2", "current": false}
            ],
            "currentDesktop": "d1",
            "canSetNoBorder": true,
            "noBorder": false,
            "canHideFromCapture": true,
            "excludedFromCapture": false,
            "closable": true
        }
        const result = Object.assign({}, base)
        if (overrides) {
            for (const key in overrides) {
                result[key] = overrides[key]
            }
        }
        return result
    }

    function actionByName(actions, name) {
        for (let index = 0; index < actions.length; index++) {
            if (actions[index].name === name) {
                return actions[index]
            }
        }
        return null
    }

    function test_singleWindowOffersDesktopMoreAndClose() {
        const actions = TaskContextActions.windowActions(snapshot(), labels, true)
        compare(actions.length, 3)
        compare(actions[0].kind, "submenu")
        compare(actions[0].name, "Move to Desktop")
        compare(actions[1].name, "More")
        compare(actions[2].operation, "close")
        compare(actions[2].destructive, true)
    }

    function test_multiWindowOmitsSingularClose() {
        const actions = TaskContextActions.windowActions(snapshot(), labels, false)
        compare(actions.length, 2)
        compare(actionByName(actions, "More") !== null, true)
        compare(actionByName(actions, "Close"), null)
    }

    function test_desktopSubmenuMarksCurrentAllAndOtherDesktops() {
        const actions = TaskContextActions.windowActions(snapshot(), labels, true)
        const desktopMenu = actions[0]
        compare(desktopMenu.children.length, 4)
        compare(desktopMenu.children[0].operation, "moveToDesktop")
        compare(desktopMenu.children[0].checked, true)
        compare(desktopMenu.children[0].enabled, false)
        compare(desktopMenu.children[1].allDesktops, true)
        compare(desktopMenu.children[1].checked, false)
        compare(desktopMenu.children[2].desktopId, "d2")
        compare(desktopMenu.children[2].checked, false)
        compare(desktopMenu.children[3].operation, "newVirtualDesktop")

        const onAll = TaskContextActions.windowActions(snapshot({
            "onAllDesktops": true,
            "virtualDesktops": []
        }), labels, true)
        compare(onAll[0].children[0].checked, false)
        compare(onAll[0].children[1].checked, true)
        compare(onAll[0].children[2].checked, false)
    }

    function test_singleDesktopHidesMoveToDesktop() {
        const actions = TaskContextActions.windowActions(snapshot({
            "desktops": [{"id": "d1", "name": "Desktop 1", "current": true}]
        }), labels, true)
        compare(actions.length, 2)
        compare(actions[0].name, "More")
    }

    function test_moreOnlyExposesLiveCapabilities() {
        const actions = TaskContextActions.windowActions(snapshot({
            "movable": false,
            "resizable": false,
            "maximizable": false,
            "minimizable": false,
            "fullscreenable": false,
            "canSetNoBorder": false,
            "canHideFromCapture": false
        }), labels, true)
        const more = actions[1]
        compare(more.children.length, 2)
        compare(more.children[0].operation, "toggleKeepAbove")
        compare(more.children[1].operation, "toggleKeepBelow")
    }

    function test_oldPlasmaHidesNewerWindowOptions() {
        const actions = TaskContextActions.windowActions(snapshot({
            "canSetNoBorder": false,
            "canHideFromCapture": false
        }), labels, true)
        const operations = []
        for (let index = 0; index < actions[1].children.length; index++) {
            operations.push(actions[1].children[index].operation)
        }
        compare(operations.indexOf("toggleNoBorder"), -1)
        compare(operations.indexOf("toggleExcludeFromCapture"), -1)
    }

    function test_nonWindowProducesNoActions() {
        compare(TaskContextActions.windowActions(snapshot({"window": false}),
            labels, true).length, 0)
    }
}
