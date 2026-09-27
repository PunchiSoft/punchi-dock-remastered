// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Window
import QtTest
import org.kde.kirigami as Kirigami
import "../contents/ui/components/controlcenter" as ControlCenter

// The Wi-Fi row of the Control Center home page opens its own submenu in place
// and the rest of the page leaves the frame through the bottom edge. Reported by
// the user: "se muevan hacia fuera del marco y no sean visibles".
TestCase {
    id: testCase

    name: "ControlCenterNetworkSubmenu"
    when: windowShown
    property var hostWindowUnderTest: null

    SignalSpy {
        id: toggleSpy
        signalName: "networkSubmenuToggleRequested"
    }

    SignalSpy {
        id: settingsSpy
        signalName: "settingsRequested"
    }

    Component {
        id: windowComponent

        Window {
            id: hostWindow
            width: 640
            height: 900
            visible: true

            property alias page: homePage
            property alias fakeAdapter: networkAdapter

            QtObject {
                id: networkAdapter

                property bool wifiEnabled: true
                property bool wifiHardwareEnabled: true
                property bool scanning: false
                property int scanRequests: 0
                property int connectionChanges: 0
                property var model: ListModel {
                    ListElement {
                        ItemUniqueName: "Punchi Wi-Fi"
                        Name: "Punchi Wi-Fi"
                        ConnectionIcon: "network-wireless-connected-100"
                        SecurityTypeString: "WPA2"
                        Section: "Connected"
                        ConnectionState: 2
                    }
                    ListElement {
                        ItemUniqueName: "Guest"
                        Name: "Guest"
                        ConnectionIcon: "network-wireless-available"
                        SecurityTypeString: "Open"
                        Section: "Available"
                        ConnectionState: 4
                    }
                }

                function requestScan() {
                    scanRequests++
                    return true
                }

                function setWifiEnabled(enabled) {
                    wifiEnabled = enabled
                    return true
                }

                function isActivated(network) {
                    return network.ConnectionState === 2
                }

                function isBusy(network) {
                    return false
                }

                function changeConnectionState(network, password) {
                    connectionChanges++
                    return true
                }
            }

            QtObject {
                id: themeAdapter

                property bool available: true
                property bool darkMode: false
                property bool busy: false
            }

            QtObject {
                id: nightLightAdapter

                property bool available: true
                property bool configured: true
                property bool inhibited: false
                property bool ownsInhibition: false
                property bool busy: false
                property int strength: 36
            }

            ListModel {
                id: notificationModel
            }

            ControlCenter.ControlCenterHomePage {
                id: homePage

                anchors.fill: parent
                networkAdapter: networkAdapter
                themeAdapter: themeAdapter
                nightLightAdapter: nightLightAdapter
                notificationModel: notificationModel
            }
        }
    }

    function init() {
        failOnWarning(/.?/)
        toggleSpy.clear()
        settingsSpy.clear()
    }

    function viewportTopOf(item, viewport) {
        return item.mapToItem(viewport, 0, 0).y
    }

    // The scroll view of the surface provides its own bar, so it has no name of
    // ours to search for: a bar is the child that carries a position, a size and
    // a policy.
    function scrollBarOf(scrollView) {
        const children = scrollView.children
        for (let index = 0; index < children.length; ++index) {
            const child = children[index]
            if (child && child.toString().indexOf("ScrollBar") !== -1) {
                return child
            }
        }
        return null
    }

    function test_tileRevealsTheSubmenuAndPushesTheRestOutOfTheFrame() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)
        // The layout needs a rendered frame before its geometry is meaningful.
        waitForRendering(hostWindow.contentItem)
        const page = hostWindow.page
        const scrollView = findChild(page, "controlCenterHomeScrollView")
        const submenu = findChild(page, "controlCenterNetworkSubmenu")
        const notifications = findChild(page,
            "controlCenterNotificationsSection")
        const tile = findChild(page, "controlCenterWifiTile")
        const leavingTile = findChild(page, "controlCenterDoNotDisturbTile")
        const leavingCard = findChild(page, "controlCenterBrightnessCard")
        const secondaryTiles = findChild(page, "controlCenterSecondaryTiles")
        const controlCards = findChild(page, "controlCenterControlCards")
        const quickActions = findChild(page, "controlCenterQuickActionsRow")
        const updatesTile = findChild(page, "controlCenterUpdatesTile")
        const themeButton = findChild(page, "controlCenterThemeButton")
        verify(scrollView !== null)
        verify(submenu !== null)
        verify(notifications !== null)
        verify(tile !== null)
        verify(leavingTile !== null)
        verify(leavingCard !== null)
        verify(secondaryTiles !== null)
        verify(controlCards !== null)
        verify(quickActions !== null)
        verify(updatesTile !== null)
        verify(themeButton !== null)

        // Resting state: no section, the whole page reachable and where it was.
        verify(!submenu.visible)
        verify(scrollView.interactive)
        verify(notifications.visible)
        const restingCardTop = viewportTopOf(leavingCard, scrollView)
        const restingNotificationsTop = viewportTopOf(notifications, page)
        const restingNotificationsHeight = notifications.height

        // The row announces itself as the control that shows a section. Its click
        // path is covered where the page already proves that quick controls are
        // actionable: tests/control_center_home_notifications_expansion_test.qml.
        verify(tile.expandable)
        verify(!tile.expanded)

        // The overlay owns the state, so the test drives it as the overlay does.
        page.networkSubmenuOpen = true
        verify(tile.expanded)
        tryCompare(submenu, "expansionProgress", 1, 4000)
        verify(submenu.visible)

        // The section fills the band down to the pinned notifications …
        tryVerify(function() {
            return viewportTopOf(submenu, page) + submenu.height
                <= viewportTopOf(notifications, page) + 0.5
        })
        tryVerify(function() {
            return Math.abs(submenu.height - submenu.expandedHeight) <= 0.5
        }, 4000)
        // … the marked row and the control cards leave the viewport …
        tryVerify(function() {
            return viewportTopOf(leavingCard, scrollView)
                >= scrollView.height - 0.5
        })
        tryVerify(function() {
            return viewportTopOf(leavingTile, scrollView)
                >= scrollView.height - 0.5
        })
        // … and the notifications keep both their place and their size.
        verify(notifications.visible)
        fuzzyCompare(notifications.height, restingNotificationsHeight, 0.5)
        fuzzyCompare(viewportTopOf(notifications, page),
            restingNotificationsTop, 0.5)
        // Content that is meant to be out of the frame must not be reachable.
        verify(!scrollView.interactive)
        compare(scrollView.contentY, 0)
        verify(!secondaryTiles.enabled)
        verify(!controlCards.enabled)
        verify(!quickActions.enabled)
        verify(secondaryTiles.Accessible.ignored)
        verify(controlCards.Accessible.ignored)
        verify(quickActions.Accessible.ignored)
        verify(!updatesTile.enabled)
        verify(!themeButton.enabled)
        // The visible scroll belongs to the list of networks, inside its own
        // surface; the page bar is off because its viewport is locked.
        const homeBar = findChild(scrollView, "controlCenterHomeScrollBar")
        verify(homeBar !== null, "the home viewport owns a named scroll bar")
        compare(homeBar.policy, Controls.ScrollBar.AlwaysOff)
        const networkList = findChild(page, "controlCenterNetworkList")
        verify(networkList !== null)
        const networkScroll = findChild(page, "controlCenterNetworkScrollView")
        verify(networkScroll !== null)
        // The list is sized to the area the bar leaves free. A bar declared by
        // the page stayed at the origin of the surface and left the rows without
        // their column, so the placement and the reserved column are asserted
        // here and not only the existence of the bar.
        const networkBar = scrollBarOf(networkScroll)
        verify(networkBar !== null, "the network scroll view owns a bar")
        verify(networkBar.x >= networkScroll.width - networkBar.width - 0.5,
            "the bar sits on the trailing edge of the surface: x="
                + networkBar.x + " width=" + networkBar.width + " surface="
                + networkScroll.width)
        fuzzyCompare(networkScroll.rightPadding,
            networkBar.visible ? networkBar.width : 0, 0.5)
        verify(networkList.width + networkScroll.rightPadding
            <= networkScroll.width + 0.5,
            "the list never reaches under the bar: list=" + networkList.width
                + " padding=" + networkScroll.rightPadding + " surface="
                + networkScroll.width)

        page.networkSubmenuOpen = false
        tryCompare(submenu, "expansionProgress", 0, 4000)
        tryCompare(scrollView, "interactive", true)
        verify(secondaryTiles.enabled)
        verify(controlCards.enabled)
        verify(quickActions.enabled)
        verify(!secondaryTiles.Accessible.ignored)
        verify(!controlCards.Accessible.ignored)
        verify(!quickActions.Accessible.ignored)
        // Everything comes back to where it was, and the row that opened the
        // section recovers the focus.
        wait(400)
        const returnedCardTop = viewportTopOf(leavingCard, scrollView)
        verify(Math.abs(returnedCardTop - restingCardTop) <= 0.5,
            "the leavers return to their resting position: resting="
                + restingCardTop + " now=" + returnedCardTop)
        fuzzyCompare(notifications.height, restingNotificationsHeight, 0.5)
        compare(homeBar.policy, Controls.ScrollBar.AsNeeded)
        tryVerify(function() {
            return tile.activeFocus
        })
    }

    function test_missingAdapterOpensSettingsWithoutBuildingAnEmptySubmenu() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)
        waitForRendering(hostWindow.contentItem)
        const page = hostWindow.page
        const tile = findChild(page, "controlCenterWifiTile")
        const submenu = findChild(page, "controlCenterNetworkSubmenu")
        verify(tile !== null)
        verify(submenu !== null)
        verify(tile.width > 0)
        page.networkAdapter = null
        toggleSpy.target = page
        settingsSpy.target = page

        mouseClick(tile, tile.width / 2, tile.height / 2)
        compare(toggleSpy.count, 0)
        compare(settingsSpy.count, 1)
        compare(settingsSpy.signalArguments[0][0], "network")
        page.networkSubmenuOpen = true
        compare(submenu.expansionProgress, 0)
        verify(!tile.expanded)
        verify(findChild(submenu, "controlCenterNetworkHeader") === null)
    }

    function test_errorRemainsOnWifiTileAfterTheSubmenuCloses() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)
        const page = hostWindow.page
        const tile = findChild(page, "controlCenterWifiTile")
        const submenu = findChild(page, "controlCenterNetworkSubmenu")
        verify(tile !== null)
        verify(submenu !== null)
        page.motionEnabled = false
        page.networkSubmenuOpen = true
        compare(submenu.expansionProgress, 1)
        page.networkSubmenuOpen = false
        compare(submenu.expansionProgress, 0)
        page.networkErrorMessage = "Connection failed"
        compare(tile.description, "Connection failed")
    }

    function test_interruptedRevealAndResizeSettleWithoutLeavingControlsHidden() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)
        waitForRendering(hostWindow.contentItem)
        const page = hostWindow.page
        const row = findChild(page, "controlCenterPrimaryTileRow")
        const tile = findChild(page, "controlCenterWifiTile")
        const submenu = findChild(page, "controlCenterNetworkSubmenu")
        const secondaryTiles = findChild(page, "controlCenterSecondaryTiles")
        verify(row !== null)
        verify(tile !== null)
        verify(submenu !== null)
        verify(secondaryTiles !== null)

        page.networkSubmenuOpen = true
        wait(30)
        page.networkSubmenuOpen = false
        wait(30)
        page.networkSubmenuOpen = true
        hostWindow.width = 520
        tryCompare(submenu, "expansionProgress", 1, 4000)
        fuzzyCompare(tile.width, row.width, 0.5)
        verify(!secondaryTiles.enabled)

        page.networkSubmenuOpen = false
        tryCompare(submenu, "expansionProgress", 0, 4000)
        fuzzyCompare(tile.width, row.restingTileWidth, 0.5)
        verify(secondaryTiles.enabled)
        tryVerify(function() { return tile.activeFocus })
    }

    function test_theOpenSectionLeavesOneTileAsItsTitle() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)
        waitForRendering(hostWindow.contentItem)
        const page = hostWindow.page
        const row = findChild(page, "controlCenterPrimaryTileRow")
        const survivor = findChild(page, "controlCenterWifiTile")
        const neighbour = findChild(page, "controlCenterBluetoothTile")
        const submenu = findChild(page, "controlCenterNetworkSubmenu")
        verify(row !== null)
        verify(survivor !== null)
        verify(neighbour !== null)
        verify(submenu !== null)

        // Resting state: the row is wide enough for both tiles and both are in
        // place and in reach.
        verify(row.width >= Kirigami.Units.gridUnit * 26,
            "the row under test arranges two tiles side by side: row="
                + row.width)
        fuzzyCompare(survivor.x, 0, 0.5)
        verify(Math.abs(neighbour.x - (survivor.x + survivor.width
            + row.gap)) <= 0.5,
            "the tiles share the row while the section is closed: neighbour="
                + neighbour.x + " survivor=" + survivor.width)
        compare(neighbour.opacity, 1)
        verify(neighbour.visible)
        verify(neighbour.enabled)
        const restingRowHeight = row.height
        verify(restingRowHeight > 0)

        page.networkSubmenuOpen = true
        tryCompare(submenu, "expansionProgress", 1, 4000)

        // One tile is left and it holds the whole row, which is what turns it into
        // the title of the section below; the height of the row does not change,
        // so nothing under it moves while the width is handed over.
        fuzzyCompare(survivor.width, row.width, 0.5)
        fuzzyCompare(row.height, restingRowHeight, 0.5)
        // The neighbour left through the right edge of the row: it is out of the
        // frame, out of the pointer and out of the accessible tree.
        verify(neighbour.x >= row.width,
            "the neighbour ends clear of the row instead of over the survivor: x="
                + neighbour.x + " row=" + row.width)
        compare(neighbour.opacity, 0)
        verify(!neighbour.visible)
        verify(!neighbour.enabled)
        verify(neighbour.Accessible.ignored)

        page.networkSubmenuOpen = false
        tryCompare(submenu, "expansionProgress", 0, 4000)
        wait(400)
        // Closing gives the neighbour back its half of the row.
        fuzzyCompare(row.height, restingRowHeight, 0.5)
        fuzzyCompare(survivor.width, (row.width - row.gap) / 2, 0.5)
        fuzzyCompare(neighbour.x, survivor.width + row.gap, 0.5)
        verify(neighbour.visible)
        verify(neighbour.enabled)
        fuzzyCompare(neighbour.opacity, 1, 0.001)
    }

    function test_theRowKeepsBothTilesAdjacentWhileItMorphs() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)
        waitForRendering(hostWindow.contentItem)
        const page = hostWindow.page
        const row = findChild(page, "controlCenterPrimaryTileRow")
        const survivor = findChild(page, "controlCenterWifiTile")
        const neighbour = findChild(page, "controlCenterBluetoothTile")
        const submenu = findChild(page, "controlCenterNetworkSubmenu")
        verify(row !== null)
        verify(survivor !== null)
        verify(neighbour !== null)
        verify(submenu !== null)

        // With the animation off the reveal can be held at a value, so the frames
        // the user sees while the row turns from two tiles into one can be checked
        // one by one. Driving the progress directly replaces its binding, which is
        // why this is the only statement of its kind in the suite.
        page.motionEnabled = false
        page.networkSubmenuOpen = true
        const samples = [0.2, 0.4, 0.6, 0.8]
        for (let index = 0; index < samples.length; index++) {
            submenu.expansionProgress = samples[index]
            waitForRendering(hostWindow.contentItem)

            // The survivor grows and the neighbour travels the same distance, so
            // the two tiles are always one gap apart: the row never shows a hole
            // between them and one never covers the other.
            fuzzyCompare(neighbour.x, survivor.width + row.gap, 0.5)
            verify(survivor.width >= row.restingTileWidth - 0.5)
            verify(survivor.width <= row.width + 0.5)
        }
    }

    function test_inlineModeKeepsTheActionsWithoutANavigationRow() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)
        const page = hostWindow.page
        const submenu = findChild(page, "controlCenterNetworkSubmenu")
        verify(submenu !== null)

        page.networkSubmenuOpen = true
        tryVerify(function() {
            return findChild(submenu, "controlCenterNetworkHeader") !== null
        })

        const header = findChild(submenu, "controlCenterNetworkHeader")
        const navigationRow = findChild(header,
            "controlCenterNetworkNavigationRow")
        const actionsRow = findChild(header, "controlCenterNetworkActionsRow")
        const toggle = findChild(header, "controlCenterWifiSwitch")
        verify(navigationRow !== null)
        verify(actionsRow !== null)
        verify(toggle !== null)
        // The tile closes the section, so the inline section has no back button
        // and does not repeat the title.
        verify(!navigationRow.visible)
        verify(actionsRow.visible)
        verify(findChild(page, "controlCenterNetworkSearchField") !== null)

        // The first control of the inline section is the one that heads it.
        tryCompare(toggle, "activeFocus", true, 4000)
    }

    function test_downArrowFromExpandedTileEntersTheNetworkControls() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)
        const page = hostWindow.page
        const tile = findChild(page, "controlCenterWifiTile")
        const submenu = findChild(page, "controlCenterNetworkSubmenu")
        verify(tile !== null)
        verify(submenu !== null)
        page.motionEnabled = false
        page.networkSubmenuOpen = true
        tryVerify(function() {
            return findChild(submenu, "controlCenterWifiSwitch") !== null
        })
        const toggle = findChild(submenu, "controlCenterWifiSwitch")
        tryCompare(toggle, "activeFocus", true)
        tile.forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_Down)
        tryCompare(toggle, "activeFocus", true)
        verify(toggle.visualFocus,
            "focus reason=" + toggle.focusReason)
    }

    function test_keyboardOpeningKeepsVisibleFocusInsideTheSubmenu() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)
        waitForRendering(hostWindow.contentItem)
        const page = hostWindow.page
        const submenu = findChild(page, "controlCenterNetworkSubmenu")
        const tile = findChild(page, "controlCenterWifiTile")
        verify(submenu !== null)
        verify(tile !== null)
        page.motionEnabled = false
        toggleSpy.target = page
        page.focusFirstControl()
        verify(tile.activeFocus)
        keyClick(Qt.Key_Return)
        compare(toggleSpy.count, 1)
        verify(page.networkKeyboardEntry)

        // The overlay owns this state in production and responds to the signal.
        page.networkSubmenuOpen = true
        tryVerify(function() {
            return findChild(submenu, "controlCenterWifiSwitch") !== null
        })
        const toggle = findChild(submenu, "controlCenterWifiSwitch")
        verify(toggle !== null)
        tryCompare(toggle, "activeFocus", true)
        verify(toggle.visualFocus)
        verify(!page.networkKeyboardEntry)

        page.networkSubmenuOpen = false
        tryCompare(submenu, "expansionProgress", 0)
        wait(0)
        page.focusFirstControl()
        keyClick(Qt.Key_Space)
        compare(toggleSpy.count, 2)
        verify(page.networkKeyboardEntry)
    }

    function test_pointerOpeningDoesNotInheritAnEarlierKeyboardFocus() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)
        waitForRendering(hostWindow.contentItem)
        const page = hostWindow.page
        const tile = findChild(page, "controlCenterWifiTile")
        verify(tile !== null)
        toggleSpy.target = page
        tile.forceActiveFocus(Qt.TabFocusReason)
        verify(tile.visualFocus)
        mouseClick(tile, tile.width / 2, tile.height / 2)
        compare(toggleSpy.count, 1)
        verify(!page.networkKeyboardEntry)
    }

    function test_reducedMotionReachesTheFinalStateWithoutTravelling() {
        const hostWindow = createTemporaryObject(windowComponent, testCase)
        verify(hostWindow !== null)
        hostWindowUnderTest = hostWindow
        tryCompare(hostWindow, "visible", true)
        const page = hostWindow.page
        const scrollView = findChild(page, "controlCenterHomeScrollView")
        const submenu = findChild(page, "controlCenterNetworkSubmenu")
        const notifications = findChild(page,
            "controlCenterNotificationsSection")
        verify(scrollView !== null)
        verify(submenu !== null)
        verify(notifications !== null)
        const restingTop = viewportTopOf(notifications, page)

        page.motionEnabled = false
        page.networkSubmenuOpen = true

        // No animator is left running: the state is final in the same frame.
        compare(submenu.expansionProgress, 1)
        tryVerify(function() {
            return viewportTopOf(notifications, page) <= submenu.mapToItem(
                page, 0, submenu.height).y
        })

        page.networkSubmenuOpen = false
        compare(submenu.expansionProgress, 0)
        tryVerify(function() {
            return Math.abs(viewportTopOf(notifications, page)
                - restingTop) <= 0.5
        })
    }
}
