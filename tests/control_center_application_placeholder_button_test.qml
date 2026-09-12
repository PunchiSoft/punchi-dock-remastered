// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtTest
import org.kde.kirigami as Kirigami
import "../contents/ui/components/controlcenter" as ControlCenter

TestCase {
    id: testCase

    name: "ControlCenterApplicationPlaceholderButton"
    when: windowShown
    property var hostWindowUnderTest: null

    Component {
        id: windowComponent

        Window {
            id: hostWindow
            width: 240
            height: 180
            visible: true

            property alias placeholder: applicationPlaceholder

            ControlCenter.ControlCenterApplicationPlaceholderButton {
                id: applicationPlaceholder
                anchors.centerIn: parent
            }
        }
    }

    function init() {
        failOnWarning(/.?/)
    }

    function cleanup() {
        if (hostWindowUnderTest) {
            const hostWindow = hostWindowUnderTest
            hostWindowUnderTest = null
            hostWindow.close()
            wait(0)
            hostWindow.destroy()
            wait(0)
        }
    }

    function test_placeholderIsVisualOnly() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)

        const placeholder = hostWindow.placeholder
        compare(placeholder.enabled, false)
        compare(placeholder.activeFocusOnTab, false)
        compare(placeholder.Accessible.ignored, true)
        compare(placeholder.iconName, "list-add-symbolic")
        compare(placeholder.implicitWidth, Kirigami.Units.gridUnit * 3)
        compare(placeholder.implicitHeight, placeholder.implicitWidth)
    }
}
