pragma ComponentBehavior: Bound

import QtQuick
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase

    name: "AppActionsPopupRuntime"
    when: windowShown
    width: 480
    height: 320

    SignalSpy {
        id: actionTriggeredSpy
        target: popup
        signalName: "actionTriggered"
    }

    Components.AppActionsPopup {
        id: popup

        itemName: "Test application"
        actions: [
            {
                "name": "Open",
                "detail": "Ctrl+O",
                "icon": "document-open",
                "kind": "activate",
                "enabled": true
            },
            {
                "name": "Menu mode",
                "detail": "Normal",
                "icon": "view-grid",
                "kind": "submenu",
                "enabled": true,
                "children": [
                    {
                        "name": "Normal",
                        "kind": "setMode",
                        "enabled": true,
                        "checked": true
                    },
                    {
                        "name": "Full screen",
                        "kind": "setMode",
                        "enabled": true,
                        "checked": false
                    }
                ]
            },
            {
                "name": "Disabled",
                "icon": "process-stop",
                "kind": "activate",
                "enabled": false
            }
        ]
        rowHeight: 52
        iconSize: 30
        textShadowsEnabled: false
    }

    function actionList() {
        return findChild(popup, "appActionsActionList")
    }

    function init() {
        failOnWarning(/.?/)
    }

    function test_delegateResolvesBoundOuterScope() {
        const list = actionList()
        verify(list !== null)
        tryVerify(() => list.itemAtIndex(0) !== null)
        tryVerify(() => list.itemAtIndex(2) !== null)

        const firstDelegate = list.itemAtIndex(0)
        const submenuDelegate = list.itemAtIndex(1)
        const disabledDelegate = list.itemAtIndex(2)
        compare(firstDelegate.objectName, "appActionsActionDelegate")
        compare(firstDelegate.width, list.width)
        compare(firstDelegate.height, popup.effectiveRowHeight)
        compare(firstDelegate.icon.width, popup.effectiveIconSize)
        compare(firstDelegate.icon.height, popup.effectiveIconSize)
        compare(firstDelegate.text, "Open")
        verify(firstDelegate.enabled)
        verify(submenuDelegate.enabled)
        verify(!disabledDelegate.enabled)

        firstDelegate.clicked()
        compare(actionTriggeredSpy.count, 1)
        compare(actionTriggeredSpy.signalArguments[0][0].name, "Open")

        submenuDelegate.clicked()
        compare(actionTriggeredSpy.count, 1)
        verify(popup.subMenuOpen)
        compare(popup.subMenuTitle, "Menu mode")
        tryVerify(() => list.itemAtIndex(0) !== null)
        compare(list.itemAtIndex(0).text, "Normal")
        verify(list.itemAtIndex(0).checked)

        popup.closeSubMenu()
        verify(!popup.subMenuOpen)
    }
}
