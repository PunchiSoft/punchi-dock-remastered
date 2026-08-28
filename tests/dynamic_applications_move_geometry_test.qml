import QtQuick
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase

    name: "DynamicApplicationsMoveGeometry"

    Components.DockGeometryState {
        id: geometry
        inPanel: true
        horizontalPanel: true
        verticalPanel: false
        configuredIconSize: 48
        configuredIconSpacing: 8
        dockItems: [
            { "type": "app" },
            { "type": "dynamic-applications" },
            { "type": "trash" }
        ]
    }

    function init() {
        failOnWarning(/.?/)
        geometry.horizontalPanel = true
        geometry.verticalPanel = false
        geometry.dynamicApplicationsMoveModeActive = false
    }

    function test_horizontalMoveHandleReservesVisibleExtent() {
        const marker = geometry.dockItems[1]
        const compactLength = geometry.panelFixedContentLength
        compare(geometry.panelMainAxisExtentForDockItem(marker), 10)

        geometry.dynamicApplicationsMoveModeActive = true

        compare(geometry.panelMainAxisExtentForDockItem(marker),
            geometry.dynamicApplicationsMoveHandleExtent)
        verify(geometry.dynamicApplicationsMoveHandleExtent
            >= geometry.effectiveIconSize * 3.6)
        verify(geometry.panelFixedContentLength > compactLength)
    }

    function test_verticalMoveHandleUsesOneFullItemSlot() {
        geometry.horizontalPanel = false
        geometry.verticalPanel = true
        geometry.dynamicApplicationsMoveModeActive = true

        compare(geometry.panelMainAxisExtentForDockItem(
            geometry.dockItems[1]), geometry.panelItemHeight)
    }

    function test_itemThicknessControlsReservedExtent() {
        const customizedMarker = {
            "type": "dynamic-applications",
            "separatorAppearanceSource": "item",
            "separatorThickness": 16
        }

        compare(geometry.panelMainAxisExtentForDockItem(customizedMarker), 20)
    }
}
