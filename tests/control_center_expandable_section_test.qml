// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtTest
import "../contents/ui/components/controlcenter" as ControlCenter

TestCase {
    id: testCase

    name: "ControlCenterExpandableSection"
    when: windowShown
    property var hostWindowUnderTest: null

    Component {
        id: windowComponent

        Window {
            id: hostWindow
            width: 640
            height: 520
            visible: true

            property alias section: expandableSection

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                }

                ControlCenter.ControlCenterExpandableSection {
                    id: expandableSection
                    Layout.fillWidth: true
                    expandedHeight: 320
                    transitionDuration: 120

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
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

    function test_expandsAndCollapsesWithInterruptibleMotion() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)

        const section = hostWindow.section
        compare(section.visible, false)
        compare(section.expansionProgress, 0)

        section.expanded = true
        tryVerify(function() { return section.animationRunning })
        tryVerify(function() {
            return section.expansionProgress > 0
                && section.expansionProgress < 1
        })

        section.expanded = false
        tryCompare(section, "expansionProgress", 0, 500)
        compare(section.visible, false)
        compare(section.animationRunning, false)

        section.expanded = true
        tryCompare(section, "expansionProgress", 1, 500)
        compare(section.visible, true)
        compare(Math.round(section.height), 320)
        compare(section.contentOffset, 0)
    }

    function test_reducedMotionUpdatesImmediately() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)

        const section = hostWindow.section
        section.motionEnabled = false
        section.expanded = true
        wait(0)

        compare(section.expansionProgress, 1)
        compare(section.animationRunning, false)
        compare(section.contentOffset, 0)
    }
}
