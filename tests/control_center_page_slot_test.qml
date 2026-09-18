// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtTest
import "../contents/ui/components/controlcenter" as ControlCenter

TestCase {
    id: testCase

    name: "ControlCenterPageSlot"
    when: windowShown
    property var hostWindowUnderTest: null

    SignalSpy {
        id: transitionSpy
        signalName: "transitionFinished"
    }

    Component {
        id: windowComponent

        Window {
            id: hostWindow
            width: 400
            height: 600
            visible: true

            property alias slot: pageSlot

            Item {
                id: slotHost
                anchors.fill: parent

                ControlCenter.ControlCenterPageSlot {
                    id: pageSlot
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    fullHeight: slotHost.height

                    Item {
                        id: payload
                        objectName: "pageSlotPayload"
                        width: parent.width
                        height: parent.height
                    }
                }
            }
        }
    }

    QtObject {
        id: fakeThemeAdapter
        property bool available: true
        property bool darkMode: false
        property bool busy: false
    }

    QtObject {
        id: fakeNightLightAdapter
        property bool available: true
        property bool configured: true
        property bool inhibited: false
        property bool ownsInhibition: false
        property bool busy: false
        property int strength: 36
    }

    // Mirrors how the overlay composes a real page: an unsized FocusScope that
    // must fill the slot, otherwise the Control Center shows an empty area.
    Component {
        id: realPageComponent

        Window {
            id: realPageWindow
            width: 400
            height: 600
            visible: true

            property alias slot: realPageSlot
            property alias page: realHomePage

            ControlCenter.ControlCenterPageSlot {
                id: realPageSlot
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                fullHeight: realPageWindow.height
                motionEnabled: false
                current: true

                ControlCenter.ControlCenterHomePage {
                    id: realHomePage
                    anchors.fill: parent
                    motionEnabled: false
                    notificationServiceValid: true
                    doNotDisturbAvailable: true
                    themeAdapter: fakeThemeAdapter
                    nightLightAdapter: fakeNightLightAdapter
                }
            }
        }
    }

    function init() {
        failOnWarning(/.?/)
        transitionSpy.clear()
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

    function createSlot() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        transitionSpy.target = hostWindow.slot
        return hostWindow.slot
    }

    function test_enteringPageExpandsAndReportsCompletion() {
        const slot = createSlot()
        const payload = findChild(slot, "pageSlotPayload")
        verify(payload !== null)
        compare(slot.progress, 0)
        compare(slot.enabled, false)
        compare(slot.visible, false)

        slot.current = true
        tryCompare(slot, "progress", 1)
        compare(slot.enabled, true)
        compare(slot.visible, true)
        compare(slot.height, slot.fullHeight)
        compare(slot.opacity, 1)
        compare(slot.z, 1)
        tryCompare(transitionSpy, "count", 1)
        compare(transitionSpy.signalArguments[0][0], true)
        // The page keeps its full height and the slot clips it, so the content is
        // compressed visually instead of being re-laid out.
        compare(payload.height, slot.fullHeight)
    }

    function test_leavingPageCompressesAndStopsAcceptingInput() {
        const slot = createSlot()
        slot.current = true
        tryCompare(slot, "progress", 1)
        transitionSpy.clear()

        slot.current = false
        compare(slot.enabled, false)
        tryCompare(slot, "progress", 0)
        compare(slot.visible, false)
        compare(slot.height, 0)
        compare(slot.opacity, 0)
        compare(slot.z, 0)
        tryCompare(transitionSpy, "count", 1)
        compare(transitionSpy.signalArguments[0][0], false)
    }

    function test_transitionRetargetsWithoutGettingStuck() {
        const slot = createSlot()
        const payload = findChild(slot, "pageSlotPayload")

        slot.current = true
        // Reverse the direction while the page is still expanding.
        wait(Math.max(1, Math.floor(slot.transitionDuration / 3)))
        verify(slot.progress > 0)
        verify(slot.progress < 1)
        verify(slot.animationRunning)
        slot.current = false

        tryCompare(slot, "progress", 0)
        compare(slot.animationRunning, false)
        compare(slot.enabled, false)
        compare(slot.visible, false)
        // The outgoing page never gets a chance to resize its own content.
        compare(payload.height, slot.fullHeight)
        tryCompare(transitionSpy, "count", 1)
        compare(transitionSpy.signalArguments[0][0], false)
    }

    function test_reducedMotionCompletesWithoutAnimation() {
        const slot = createSlot()
        slot.motionEnabled = false

        slot.current = true
        wait(0)
        compare(slot.progress, 1)
        compare(slot.animationRunning, false)
        compare(slot.height, slot.fullHeight)
        // The completion signal still arrives, so focus can be handed over.
        tryCompare(transitionSpy, "count", 1)
        compare(transitionSpy.signalArguments[0][0], true)
    }

    function test_realPageFillsTheSlotInsteadOfCollapsing() {
        const hostWindow = createTemporaryObject(realPageComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        wait(0)

        const slot = hostWindow.slot
        const page = hostWindow.page
        compare(slot.fullHeight, hostWindow.height)
        verify(slot.progress > 0.99)
        // A page with no size would leave the Control Center empty.
        compare(page.width, slot.width)
        compare(page.height, slot.fullHeight)
        verify(page.width > 0)
        verify(page.height > 0)

        const viewport = findChild(page, "controlCenterHomeScrollView")
        verify(viewport !== null)
        verify(viewport.width > 0)
        verify(viewport.height > 0)
        verify(findChild(page, "controlCenterQuickActionsRow") !== null)
    }
}
