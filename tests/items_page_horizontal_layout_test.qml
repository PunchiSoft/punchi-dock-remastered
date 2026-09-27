// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Window
import QtTest
import org.kde.kirigami as Kirigami
import "../contents/ui/config" as Config

// Horizontal behaviour of the Items page: the dock item list keeps a bounded
// share of the width, the reserved area takes the rest, both stop at their
// minimum, and the list-owned add action remains available at every width.
TestCase {
    id: testCase

    name: "ItemsPageHorizontalLayout"
    when: windowShown
    property var hostWindowUnderTest: null

    // The page only needs the controller metrics and the members the list reads.
    QtObject {
        id: controllerStub

        property var items: []
        property int selectedIndex: -1
        property string selectedItemType: "app"
        property real listRowHeight: Kirigami.Units.gridUnit * 2.4
        property real listFooterHeight: Kirigami.Units.gridUnit * 2.4
        property real listFramePadding: Kirigami.Units.largeSpacing * 2
        property real listScrollGutter: Kirigami.Units.gridUnit * 1.6

        function hasItemType() {
            return false
        }

        function selectItem() {
        }

        function moveSelectedItem() {
        }

        function canConfigureSelectedItem() {
            return false
        }

        function configureSelectedItem() {
        }

        function removeSelectedItem() {
        }

        function selectedConfigureTitle() {
            return ""
        }

        function iconPreviewSource() {
            return ""
        }
    }

    ListModel {
        id: itemModelStub
    }

    Timer {
        id: statusTimerStub
    }

    Component {
        id: windowComponent

        Window {
            id: hostWindow

            width: 1000
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
    }

    function cleanup() {
        if (hostWindowUnderTest) {
            const target = hostWindowUnderTest
            hostWindowUnderTest = null
            target.destroy()
            wait(0)
        }
    }

    function createView(hostWidth) {
        const host = createTemporaryObject(windowComponent, testCase)
        verify(host !== null)
        hostWindowUnderTest = host
        host.width = hostWidth
        wait(0)
        return host.view
    }

    function findByName(item, name) {
        if (!item) {
            return null
        }
        if (item.objectName === name) {
            return item
        }
        const children = item.children
        for (let index = 0; index < children.length; index++) {
            const found = findByName(children[index], name)
            if (found) {
                return found
            }
        }
        return null
    }

    function test_wide_host_gives_the_rest_to_the_configuration_panel() {
        const view = createView(1000)
        const list = findByName(view, "dockItemListEditor")
        const reserved = findByName(view, "itemConfigurationReservedArea")
        verify(list !== null, "the dock item list must exist")
        verify(reserved !== null, "the reserved area must exist")
        compare(list.width, Kirigami.Units.gridUnit * 16)
        verify(reserved.width > list.width,
            "the configuration panel must own the remaining width")
        compare(Math.round(list.width + reserved.width
            + Kirigami.Units.smallSpacing), Math.round(view.width))
    }

    function test_narrow_host_keeps_both_minimums_and_still_fits() {
        const view = createView(520)
        const list = findByName(view, "dockItemListEditor")
        const reserved = findByName(view, "itemConfigurationReservedArea")
        verify(list !== null)
        verify(reserved !== null)
        // The column is fixed at the width its compact toolbar needs, so both
        // minimums survive a narrow host without squeezing either panel.
        compare(list.width, Kirigami.Units.gridUnit * 16)
        verify(reserved.width >= Kirigami.Units.gridUnit * 12)
        compare(Math.round(list.width + reserved.width
            + Kirigami.Units.smallSpacing), Math.round(view.width))
    }

    function test_widening_gives_the_new_space_to_the_configuration_panel() {
        const view = createView(520)
        const list = findByName(view, "dockItemListEditor")
        const reserved = findByName(view, "itemConfigurationReservedArea")
        verify(list !== null)
        verify(reserved !== null)
        const narrowReserved = reserved.width
        hostWindowUnderTest.width = 1400
        wait(0)
        compare(list.width, Kirigami.Units.gridUnit * 16)
        verify(reserved.width > narrowReserved,
            "widening the page must widen the configuration panel")
        compare(Math.round(list.width + reserved.width
            + Kirigami.Units.smallSpacing), Math.round(view.width))
    }

    function test_body_does_not_demand_more_height_than_the_page() {
        const view = createView(1000)
        verify(view.height <= hostWindowUnderTest.height + 0.5,
            "the page must fit the area it was given")
        verify(view.implicitHeight <= view.height + 0.5,
            "the body must not demand more height than it has; the configuration"
                + " panel scrolls inside instead of stretching the page")
    }

    function test_add_action_stays_compact_when_the_page_grows() {
        const view = createView(560)
        const button = findByName(view, "addDockItemButton")
        verify(button !== null, "the single add action must exist")
        verify(button.visible)
        verify(button.enabled)
        verify(button.parent !== view,
            "the add action must live inside the dock item editor")
        compare(button.display, Controls.AbstractButton.IconOnly,
            "the compact toolbar must preserve the action without clipping text")
        hostWindowUnderTest.width = 1600
        wait(0)
        // The column no longer grows with the page, so the toolbar stays compact
        // and the label keeps living in the tooltip and in the accessible name.
        compare(button.display, Controls.AbstractButton.IconOnly,
            "the fixed column must keep the add action compact")
        verify(String(button.text).length > 0,
            "the compact action must still carry its label for assistive tech")
        verify(String(button.Accessible.name).length > 0,
            "the compact action must still publish an accessible name")
    }
}
