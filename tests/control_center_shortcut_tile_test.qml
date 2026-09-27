// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtTest
import org.kde.kirigami as Kirigami
import "../contents/ui/components/controlcenter" as ControlCenter

TestCase {
    id: testCase

    name: "ControlCenterShortcutTile"
    when: windowShown
    property var hostWindowUnderTest: null

    SignalSpy {
        id: clickedSpy
        signalName: "clicked"
    }

    Component {
        id: windowComponent

        Window {
            id: hostWindow
            width: 480
            height: 320
            visible: true

            property alias tile: shortcutTile
            property alias focusSink: focusSink

            Item {
                id: focusSink
                width: 1
                height: 1
            }

            ControlCenter.ControlCenterShortcutTile {
                id: shortcutTile
                anchors.centerIn: parent
                width: 260
                text: "Wi-Fi"
                description: "Open network connections"
                iconName: "network-wireless"
                badgeText: "3"
            }
        }
    }

    function init() {
        failOnWarning(/.?/)
        clickedSpy.clear()
    }

    function cleanup() {
        clickedSpy.target = null
        if (hostWindowUnderTest) {
            const hostWindow = hostWindowUnderTest
            hostWindowUnderTest = null
            hostWindow.close()
            wait(0)
            hostWindow.destroy()
            wait(0)
        }
    }

    function test_pointerAndKeyboardActivateTheSameAction() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)

        const tile = hostWindow.tile
        clickedSpy.target = tile
        mouseClick(tile, tile.width / 2, tile.height / 2)
        compare(clickedSpy.count, 1)

        tile.forceActiveFocus(Qt.TabFocusReason)
        tryVerify(function() { return tile.activeFocus })
        keyClick(Qt.Key_Space)
        compare(clickedSpy.count, 2)
        keyClick(Qt.Key_Return)
        compare(clickedSpy.count, 3)
        keyClick(Qt.Key_Enter)
        compare(clickedSpy.count, 4)
        compare(tile.Accessible.name, "Wi-Fi")
        compare(tile.Accessible.description, "Open network connections")
        compare(tile.leftPadding, Kirigami.Units.largeSpacing)
        compare(tile.rightPadding, Kirigami.Units.largeSpacing)
        compare(tile.topPadding, Kirigami.Units.mediumSpacing)
        compare(tile.bottomPadding, Kirigami.Units.mediumSpacing)
        verify(tile.contentItem.x >= tile.leftPadding)
        verify(tile.contentItem.width <= tile.availableWidth)
    }

    function test_programmaticFocusIsNeutralAndKeyboardFocusHasAnOutline() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)
        const tile = hostWindow.tile
        const restingColor = tile.background.color

        tile.forceActiveFocus(Qt.PopupFocusReason)
        verify(tile.activeFocus)
        verify(!tile.visualFocus)
        compare(tile.background.border.width, 1)
        compare(tile.background.color, restingColor)
        mouseMove(tile, tile.width / 2, tile.height / 2)
        tryCompare(tile, "hovered", true)
        compare(tile.background.color, restingColor)

        hostWindow.focusSink.forceActiveFocus(Qt.OtherFocusReason)
        verify(!tile.activeFocus)
        tile.forceActiveFocus(Qt.TabFocusReason)
        verify(tile.visualFocus,
            "focus reason=" + tile.focusReason + " active=" + tile.activeFocus)
        compare(tile.background.border.width, 2)
        compare(tile.background.color, restingColor)
        compare(tile.Accessible.role, Accessible.Button)
        compare(tile.Accessible.focused, true)
    }
}
