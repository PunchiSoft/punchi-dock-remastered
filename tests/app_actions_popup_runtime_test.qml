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

    function test_delegateResolvesBoundOuterScope() {
        const list = actionList()
        verify(list !== null)
        tryVerify(() => list.itemAtIndex(0) !== null)
        tryVerify(() => list.itemAtIndex(1) !== null)

        const firstDelegate = list.itemAtIndex(0)
        const secondDelegate = list.itemAtIndex(1)
        compare(firstDelegate.objectName, "appActionsActionDelegate")
        compare(firstDelegate.width, list.width)
        compare(firstDelegate.height, popup.effectiveRowHeight)
        compare(firstDelegate.icon.width, popup.effectiveIconSize)
        compare(firstDelegate.icon.height, popup.effectiveIconSize)
        compare(firstDelegate.text, "Open")
        verify(firstDelegate.enabled)
        verify(!secondDelegate.enabled)

        firstDelegate.clicked()
        compare(actionTriggeredSpy.count, 1)
        compare(actionTriggeredSpy.signalArguments[0][0].name, "Open")
    }
}
