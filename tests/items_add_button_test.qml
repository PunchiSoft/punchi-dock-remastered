// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtTest
import org.kde.kirigami as Kirigami
import "../contents/ui/config" as Config

TestCase {
    id: testCase

    name: "ItemsAddButton"
    when: windowShown
    property var hostWindowUnderTest: null

    QtObject {
        id: controllerStub

        property var items: []
        property int selectedIndex: -1
        property real listRowHeight: Kirigami.Units.gridUnit * 2.4
        property real listFooterHeight: Kirigami.Units.gridUnit * 2.4
        property real listFramePadding: Kirigami.Units.largeSpacing * 2
        property real listScrollGutter: Kirigami.Units.gridUnit * 1.6

        function selectItem() {}
        function moveSelectedItem() {}
        function canConfigureSelectedItem() { return false }
        function configureSelectedItem() {}
        function removeSelectedItem() {}
        function selectedConfigureTitle() { return "" }
        function iconPreviewSource() { return "" }
    }

    ListModel { id: itemModelStub }
    Timer { id: statusTimerStub }

    Component {
        id: windowComponent

        Window {
            width: 900
            height: 600
            visible: true

            property alias view: mainView

            Config.ConfigItemsMainView {
                id: mainView
                anchors.fill: parent
                controller: controllerStub
                itemModel: itemModelStub
                statusHideTimer: statusTimerStub
            }
        }
    }

    function init() {
        failOnWarning(/.?/)
        hostWindowUnderTest = createTemporaryObject(windowComponent, testCase)
        verify(hostWindowUnderTest !== null)
        wait(0)
    }

    function cleanup() {
        if (hostWindowUnderTest) {
            const target = hostWindowUnderTest
            hostWindowUnderTest = null
            target.destroy()
            wait(0)
        }
    }

    function test_buttonEmitsOneIntentAndReceivesRestoredFocus() {
        const view = hostWindowUnderTest.view
        const button = findChild(view, "addDockItemButton")
        verify(button !== null)
        compare(String(button.icon.name), "list-add-symbolic")
        verify(String(button.text).length > 0)
        verify(button.activeFocusOnTab)

        const spy = signalSpyComponent.createObject(testCase, {
            "target": view,
            "signalName": "addItemRequested"
        })
        verify(spy !== null)
        button.clicked()
        compare(spy.count, 1)

        view.focusAddItemButton()
        tryVerify(function() {
            return button.activeFocus
        }, 2000, "Closing the dialog must be able to restore button focus")
        spy.destroy()
    }

    Component {
        id: signalSpyComponent
        SignalSpy {}
    }
}
