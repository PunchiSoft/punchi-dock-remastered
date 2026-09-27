// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtTest
import org.kde.kirigami as Kirigami
import "../contents/ui/components/controlcenter" as ControlCenter

TestCase {
    id: testCase

    name: "ControlCenterHomeNotificationsPersistent"
    when: windowShown
    property var hostWindowUnderTest: null

    SignalSpy {
        id: applicationSpy
        signalName: "applicationRequested"
    }

    SignalSpy {
        id: doNotDisturbSpy
        signalName: "doNotDisturbRequested"
    }

    SignalSpy {
        id: themeSpy
        signalName: "themeToggleRequested"
    }

    SignalSpy {
        id: nightLightSpy
        signalName: "nightLightToggleRequested"
    }

    SignalSpy {
        id: nightLightStrengthSpy
        signalName: "nightLightStrengthModified"
    }

    SignalSpy {
        id: networkSubmenuSpy
        signalName: "networkSubmenuToggleRequested"
    }

    SignalSpy {
        id: settingsSpy
        signalName: "settingsRequested"
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

    Component {
        id: windowComponent

        Window {
            id: hostWindow
            width: 640
            height: 900
            visible: true

            property alias page: homePage

            ControlCenter.ControlCenterHomePage {
                id: homePage
                anchors.fill: parent
                motionEnabled: false
                notificationServiceValid: true
                doNotDisturbAvailable: true
                themeAdapter: fakeThemeAdapter
                nightLightAdapter: fakeNightLightAdapter
            }
        }
    }

    function init() {
        failOnWarning(/.?/)
        applicationSpy.clear()
        doNotDisturbSpy.clear()
        themeSpy.clear()
        nightLightSpy.clear()
        nightLightStrengthSpy.clear()
        settingsSpy.clear()
        fakeThemeAdapter.darkMode = false
        fakeThemeAdapter.busy = false
        fakeNightLightAdapter.inhibited = false
        fakeNightLightAdapter.ownsInhibition = false
        fakeNightLightAdapter.busy = false
        fakeNightLightAdapter.configured = true
        fakeNightLightAdapter.strength = 36
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

    function test_contentRemainsInsideViewportWhenHeightIsLimited() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        const page = hostWindow.page
        const section = findChild(page, "controlCenterNotificationsSection")
        hostWindow.height = 500
        wait(0)
        const viewport = findChild(page, "controlCenterHomeScrollView")
        verify(viewport !== null)
        // The notifications are pinned at the foot of the frame, so the quick
        // controls scroll in the area above them instead of taking the page.
        verify(viewport.height < page.height)
        compare(viewport.height, page.height - section.height
            - Kirigami.Units.largeSpacing)
        verify(viewport.clip)
        verify(viewport.contentHeight >= viewport.height)
        const flickable = viewport
        flickable.contentY = Math.max(0,
            flickable.contentHeight - flickable.height)
        wait(0)
        verify(section.mapToItem(page, 0, section.height).y <= page.height + 1)
        page.focusFirstControl()
        compare(viewport.contentY, 0)
        hostWindow.height = 750
        tryVerify(function() {
            return Math.abs(viewport.contentHeight - viewport.height) < 1
        })
        hostWindow.height = 1000
        tryVerify(function() {
            return Math.abs(viewport.contentHeight - viewport.height) < 1
        })
    }

    function test_arrowKeysFollowTheShortcutGridAndSkipUnavailableTiles() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)
        waitForRendering(hostWindow.contentItem)
        const page = hostWindow.page
        const wifi = findChild(page, "controlCenterWifiTile")
        const bluetooth = findChild(page, "controlCenterBluetoothTile")
        const doNotDisturb = findChild(page, "controlCenterDoNotDisturbTile")
        const updates = findChild(page, "controlCenterUpdatesTile")
        verify(wifi !== null)
        verify(bluetooth !== null)
        verify(doNotDisturb !== null)
        verify(updates !== null)

        page.focusFirstControl()
        verify(wifi.activeFocus)
        verify(!wifi.visualFocus)
        keyClick(Qt.Key_Right)
        tryCompare(bluetooth, "activeFocus", true)
        verify(bluetooth.visualFocus)
        keyClick(Qt.Key_Down)
        tryCompare(updates, "activeFocus", true)
        keyClick(Qt.Key_Left)
        tryCompare(doNotDisturb, "activeFocus", true)
        keyClick(Qt.Key_Up)
        tryCompare(wifi, "activeFocus", true)

        page.doNotDisturbAvailable = false
        keyClick(Qt.Key_Down)
        tryCompare(updates, "activeFocus", true)
        verify(!doNotDisturb.activeFocus)

        page.focusFirstControl()
        keyClick(Qt.Key_Tab)
        tryCompare(bluetooth, "activeFocus", true)
        verify(bluetooth.visualFocus)
        keyClick(Qt.Key_Tab, Qt.ShiftModifier)
        tryCompare(wifi, "activeFocus", true)
    }

    function test_arrowKeysFollowStackedTilesAndKeepFocusInView() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)
        hostWindow.width = 400
        hostWindow.height = 320
        waitForRendering(hostWindow.contentItem)
        const page = hostWindow.page
        const primaryRow = findChild(page, "controlCenterPrimaryTileRow")
        const scrollView = findChild(page, "controlCenterHomeScrollView")
        const wifi = findChild(page, "controlCenterWifiTile")
        const bluetooth = findChild(page, "controlCenterBluetoothTile")
        const doNotDisturb = findChild(page, "controlCenterDoNotDisturbTile")
        const updates = findChild(page, "controlCenterUpdatesTile")
        verify(primaryRow !== null)
        verify(scrollView !== null)
        verify(wifi !== null)
        verify(bluetooth !== null)
        verify(doNotDisturb !== null)
        verify(updates !== null)
        tryCompare(primaryRow, "stacked", true)

        page.focusFirstControl()
        keyClick(Qt.Key_Down)
        tryCompare(bluetooth, "activeFocus", true)
        keyClick(Qt.Key_Down)
        tryCompare(doNotDisturb, "activeFocus", true)
        keyClick(Qt.Key_Down)
        tryCompare(updates, "activeFocus", true)
        tryVerify(function() {
            return updates.mapToItem(scrollView, 0, updates.height).y
                <= scrollView.height + 0.5
        })
        keyClick(Qt.Key_Up)
        tryCompare(doNotDisturb, "activeFocus", true)
    }

    function test_historyIsPersistentAndQuickControlsRemainActionable() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)

        const page = hostWindow.page
        const dndTile = findChild(page, "controlCenterDoNotDisturbTile")
        const section = findChild(page,
            "controlCenterNotificationsSection")
        const updatesTile = findChild(page, "controlCenterUpdatesTile")
        const calculatorButton = findChild(page,
            "controlCenterCalculatorButton")
        const themeButton = findChild(page, "controlCenterThemeButton")
        const nightLightButton = findChild(page,
            "controlCenterNightLightButton")
        const brightnessCard = findChild(page, "controlCenterBrightnessCard")
        const strengthControl = findChild(page,
            "controlCenterNightLightStrengthControl")
        const strengthSlider = findChild(page,
            "controlCenterNightLightStrengthSlider")
        verify(dndTile !== null)
        verify(section !== null)
        verify(updatesTile !== null)
        verify(calculatorButton !== null)
        verify(themeButton !== null)
        verify(nightLightButton !== null)
        verify(brightnessCard !== null)
        verify(strengthControl !== null)
        verify(strengthSlider !== null)
        // The strip derives its capacity from its own width, so the number of
        // empty slots is data, not a constant.
        const quickActionsRow = findChild(page, "controlCenterQuickActionsRow")
        verify(quickActionsRow !== null)
        verify(waitForRendering(page))
        tryVerify(function() { return quickActionsRow.cellCount > 0 })
        verify(quickActionsRow.cellCount >= page.quickActionMinimumCount)
        verify(quickActionsRow.cellCount <= page.quickActionMaximumCount)
        compare(quickActionsRow.emptySlotCount,
            Math.max(0, quickActionsRow.cellCount - page.quickActionFixedCount))
        const placeholderButtons = []
        for (let index = 1; index <= quickActionsRow.emptySlotCount;
                ++index) {
            const placeholderButton = findChild(page,
                "controlCenterApplicationPlaceholderButton" + index)
            verify(placeholderButton !== null)
            placeholderButtons.push(placeholderButton)
            compare(placeholderButton.enabled, false)
            compare(placeholderButton.activeFocusOnTab, false)
            compare(placeholderButton.Accessible.ignored, true)
            compare(placeholderButton.iconName, "list-add-symbolic")
            compare(placeholderButton.implicitHeight,
                Kirigami.Units.gridUnit * 3)
            compare(placeholderButton.implicitWidth,
                placeholderButton.implicitHeight)
        }
        compare(placeholderButtons.length, quickActionsRow.emptySlotCount)
        compare(findChild(page, "controlCenterApplicationPlaceholderButton"
            + (quickActionsRow.emptySlotCount + 1)), null)
        verify(waitForRendering(page))
        for (let index = 1; index < placeholderButtons.length; ++index) {
            verify(placeholderButtons[index].x
                > placeholderButtons[index - 1].x)
            compare(placeholderButtons[index].y,
                placeholderButtons[0].y)
        }
        let finalPlaceholder = placeholderButtons[
            placeholderButtons.length - 1]
        verify(finalPlaceholder.mapToItem(page,
            finalPlaceholder.width, 0).x <= page.width + 1)

        const narrowCapacity = quickActionsRow.cellCount
        hostWindow.width = 900
        tryVerify(function() { return page.wideLayout })
        verify(waitForRendering(page))
        tryVerify(function() {
            return quickActionsRow.cellCount >= narrowCapacity
        })
        // The strip recomputes its empty slots instead of keeping the old ones.
        compare(quickActionsRow.emptySlotCount,
            Math.max(0, quickActionsRow.cellCount - page.quickActionFixedCount))
        const widenedPlaceholders = []
        for (let index = 1; index <= quickActionsRow.emptySlotCount; ++index) {
            const placeholderButton = findChild(page,
                "controlCenterApplicationPlaceholderButton" + index)
            verify(placeholderButton !== null)
            widenedPlaceholders.push(placeholderButton)
        }
        compare(widenedPlaceholders.length, quickActionsRow.emptySlotCount)
        finalPlaceholder = widenedPlaceholders[widenedPlaceholders.length - 1]
        verify(finalPlaceholder.mapToItem(page,
            finalPlaceholder.width, 0).x <= page.width + 1)
        compare(calculatorButton.implicitHeight,
            Kirigami.Units.gridUnit * 3)
        verify(calculatorButton.implicitHeight < brightnessCard.implicitHeight)
        compare(calculatorButton.implicitWidth,
            calculatorButton.implicitHeight)
        compare(strengthControl.visible, true)
        compare(strengthControl.controlAvailable, true)
        compare(strengthSlider.value, 36)
        compare(strengthSlider.Accessible.name, "Night Light intensity")
        compare(section.visible, true)
        tryVerify(function() { return section.height > 0 })
        compare(findChild(page, "controlCenterNotificationsTile"), null)
        compare(dndTile.Accessible.checkable, true)
        compare(dndTile.Accessible.checked, false)
        compare(themeButton.Accessible.checkable, true)
        compare(themeButton.Accessible.checked, false)
        compare(nightLightButton.Accessible.checkable, true)
        compare(nightLightButton.Accessible.checked, true)

        doNotDisturbSpy.target = page
        themeSpy.target = page
        nightLightSpy.target = page
        networkSubmenuSpy.target = page
        settingsSpy.target = page
        mouseClick(dndTile, dndTile.width / 2, dndTile.height / 2)
        compare(doNotDisturbSpy.count, 1)
        // With no network adapter, the Wi-Fi row offers Network Settings.
        const wifiTile = findChild(page, "controlCenterWifiTile")
        verify(wifiTile !== null)
        mouseClick(wifiTile, wifiTile.width / 2, wifiTile.height / 2)
        compare(networkSubmenuSpy.count, 0)
        compare(settingsSpy.count, 1)
        compare(settingsSpy.signalArguments[0][0], "network")
        mouseClick(themeButton, themeButton.width / 2,
            themeButton.height / 2)
        compare(themeSpy.count, 1)
        mouseClick(nightLightButton, nightLightButton.width / 2,
            nightLightButton.height / 2)
        compare(nightLightSpy.count, 1)

        nightLightStrengthSpy.target = page
        strengthControl.strengthModified(62)
        compare(nightLightStrengthSpy.count, 1)
        compare(nightLightStrengthSpy.signalArguments[0][0], 62)

        fakeNightLightAdapter.configured = false
        compare(strengthControl.controlAvailable, false)
        compare(nightLightButton.Accessible.checked, false)

        applicationSpy.target = page
        mouseClick(updatesTile, updatesTile.width / 2,
            updatesTile.height / 2)
        compare(applicationSpy.count, 1)
        compare(applicationSpy.signalArguments[0][0], "updates")

        mouseClick(calculatorButton, calculatorButton.width / 2,
            calculatorButton.height / 2)
        compare(applicationSpy.count, 2)
        compare(applicationSpy.signalArguments[1][0], "calculator")
    }

    function test_intensityRowRevealsOnlyWhileInteracting() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)

        const page = hostWindow.page
        const reveal = findChild(page,
            "controlCenterNightLightStrengthReveal")
        const nightLightButton = findChild(page,
            "controlCenterNightLightButton")
        const strengthSlider = findChild(page,
            "controlCenterNightLightStrengthSlider")
        const section = findChild(page,
            "controlCenterNotificationsSection")
        verify(reveal !== null)
        verify(nightLightButton !== null)
        verify(strengthSlider !== null)
        verify(section !== null)
        verify(waitForRendering(page))

        // The extra row stays collapsed until somebody asks for it.
        compare(reveal.expanded, false)
        compare(Math.round(reveal.height), 0)

        // Pointer over the trigger button reveals it.
        mouseMove(nightLightButton, nightLightButton.width / 2,
            nightLightButton.height / 2)
        tryCompare(reveal, "expanded", true)
        verify(waitForRendering(page))
        tryVerify(function() { return reveal.height > 0 })

        // The notification history keeps the remaining height and stays below.
        verify(section.y >= reveal.y + reveal.height - 1)

        // The pointer can travel onto the row itself and it stays open.
        mouseMove(strengthSlider, strengthSlider.width / 2,
            strengthSlider.height / 2)
        verify(waitForRendering(page))
        compare(reveal.expanded, true)

        // Leaving both collapses it again.
        mouseMove(page, page.width - 2, 2)
        tryVerify(function() { return !reveal.expanded }, 2000)

        // Keyboard focus on the trigger reveals it too: hover must not be the
        // only way in.
        nightLightButton.forceActiveFocus()
        tryCompare(reveal, "expanded", true)
        compare(reveal.revealRequested, true)
        nightLightButton.focus = false
        tryVerify(function() { return !reveal.expanded }, 2000)

        // A control that cannot be used never reveals.
        fakeNightLightAdapter.configured = false
        mouseMove(nightLightButton, nightLightButton.width / 2,
            nightLightButton.height / 2)
        verify(waitForRendering(page))
        compare(reveal.usable, false)
        compare(reveal.expanded, false)
    }
}
