// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase
    name: "AppActionsPopupSections"
    when: windowShown
    visible: true
    width: 420
    height: 320

    readonly property var menuActions: [
        {"name": "Places", "kind": "section", "enabled": false},
        {"name": "Home", "icon": "folder-home", "kind": "openFilePlace", "enabled": true},
        {"name": "Actions", "kind": "section", "enabled": false},
        {"name": "Open", "icon": "document-open", "kind": "activate", "enabled": true},
        {"name": "Close", "icon": "window-close", "kind": "close", "enabled": true}
    ]

    Components.AppActionsPopup {
        id: popup
        anchors.fill: parent
        itemName: "Example"
        actions: testCase.menuActions
        rowHeight: 38
        iconSize: 20
    }

    function actionList() {
        return findChild(popup, "appActionsActionList")
    }

    function init() {
        failOnWarning(/.?/)
        popup.actions = testCase.menuActions
        popup.resetSubMenu()
    }

    function test_sectionRowsAreInertAndUseNativeMetrics() {
        compare(popup.displayedActionCount, 3)
        verify(popup.sectionRowHeight < popup.effectiveRowHeight)

        const list = actionList()
        verify(list !== null)
        tryVerify(() => list.itemAtIndex(4) !== null)

        const placesHeader = list.itemAtIndex(0)
        const actionsHeader = list.itemAtIndex(2)
        compare(placesHeader.objectName, "appActionsActionDelegate")
        compare(placesHeader.height, popup.sectionRowHeight)
        compare(actionsHeader.height, popup.sectionRowHeight)
        verify(!placesHeader.enabled)
        compare(placesHeader.text, "Places")
    }

    function test_keyboardNavigationSkipsSections() {
        const list = actionList()
        verify(list !== null)
        tryVerify(() => list.itemAtIndex(4) !== null)

        list.currentIndex = 1
        popup.moveSelection(1, -1)
        compare(list.currentIndex, 1)

        popup.moveSelection(1, 1)
        compare(list.currentIndex, 3)

        popup.moveSelection(3, 1)
        compare(list.currentIndex, 4)

        popup.moveSelection(4, 1)
        compare(list.currentIndex, 4)

        popup.moveSelection(4, -1)
        compare(list.currentIndex, 3)
    }

    function test_viewportReservesSectionHeight() {
        compare(popup.viewportHeightForRows(3),
            popup.sectionRowHeight * 2 + popup.effectiveRowHeight * 3)
    }
}
