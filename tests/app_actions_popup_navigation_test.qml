// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase
    name: "AppActionsPopupNavigation"
    when: windowShown
    visible: true
    width: 500
    height: 600

    readonly property var menuActions: [
        {
            "name": "Places",
            "kind": "submenu",
            "icon": "folder",
            "children": [
                {"name": "Home", "kind": "openFilePlace", "icon": "folder"},
                {
                    "name": "Devices",
                    "kind": "submenu",
                    "icon": "folder",
                    "children": [
                        {"name": "USB", "kind": "openFilePlace", "icon": "drive-removable-media"}
                    ]
                }
            ]
        },
        {"name": "Configure Dock", "kind": "configureDock", "icon": "preferences-system"}
    ]

    Components.AppActionsPopup {
        id: popup
        anchors.fill: parent
        itemName: "Example"
        actions: testCase.menuActions
    }

    function init() {
        popup.actions = testCase.menuActions
        waitForRendering(popup)
    }

    function test_nestedSubmenusReturnOneLevelAtATime() {
        compare(popup.subMenuOpen, false)
        compare(popup.displayedActions.length, 2)

        popup.openSubMenu(popup.actions[0])
        compare(popup.subMenuOpen, true)
        compare(popup.subMenuTitle, "Places")
        compare(popup.displayedActions.length, 3)
        compare(popup.displayedActions[0].kind, "back")
        compare(popup.displayedActions[1].name, "Home")

        popup.openSubMenu(popup.displayedActions[2])
        compare(popup.subMenuTitle, "Devices")
        compare(popup.displayedActions.length, 2)
        compare(popup.displayedActions[0].kind, "back")
        compare(popup.displayedActions[1].name, "USB")

        popup.closeSubMenu()
        compare(popup.subMenuTitle, "Places")
        compare(popup.displayedActions.length, 3)

        popup.closeSubMenu()
        compare(popup.subMenuOpen, false)
        compare(popup.subMenuTitle, "")
        compare(popup.displayedActions.length, 2)
    }

    function test_rootActionsChangeResetsTheWholeStack() {
        popup.openSubMenu(popup.actions[0])
        popup.openSubMenu(popup.displayedActions[2])
        compare(popup.subMenuTitle, "Devices")

        popup.actions = [{"name": "Only", "kind": "configureDock", "icon": "preferences-system"}]
        compare(popup.subMenuOpen, false)
        compare(popup.subMenuTitle, "")
        compare(popup.displayedActions.length, 1)
        compare(popup.displayedActions[0].name, "Only")
    }
}
