import QtQuick
import QtTest
import "../contents/code/recentApplicationsPlacement.js" as Placement
import "../contents/ui/config/code/configItems.js" as Items
import "../contents/ui/config" as Config
import "../contents/ui/components" as Components

TestCase {
    name: "RecentApplicationsPlacement"
    when: windowShown
    visible: true
    width: 700
    height: 800

    function init() { failOnWarning(/.?/) }

    function fixtures() {
        return [{ type: "app", name: "First" },
            { type: "dynamic-applications", name: "Open applications" },
            { type: "trash", name: "Trash" }]
    }

    function test_enableDisableAndRestoreBetweenNeighbors() {
        const original = fixtures()
        let result = Placement.reconcile(original, true, "", 512)
        compare(Placement.markerIndex(result.items), 3)
        compare(original.length, 3)
        const moved = Items.moveItem(result.items, 3, 2).items
        result = Placement.reconcile(moved, false, result.position, 512)
        compare(Placement.markerIndex(result.items), -1)
        compare(JSON.stringify(result.items), JSON.stringify(original))
        const memory = result.position
        result = Placement.reconcile(result.items, true, memory, 512)
        compare(Placement.markerIndex(result.items), 2)
        compare(result.items[3].type, "trash")
        verify(!Placement.reconcile(result.items, true, result.position, 512).changed)
    }

    function test_deletedNeighborsUseNearestValidPosition() {
        const items = fixtures()
        items.splice(2, 0, { type: Placement.markerType })
        const memory = Placement.capture(items)
        compare(Placement.markerIndex(Placement.reconcile([items[3]], true, memory, 512).items), 0)
        compare(Placement.markerIndex(Placement.reconcile([items[1]], true, memory, 512).items), 1)
        compare(Placement.markerIndex(Placement.reconcile([], true, memory, 512).items), 0)
    }

    function test_invalidMemoryDuplicatesAndItemLimit() {
        for (const invalid of ["", "invalid", "null", "[]", '{"index":-2}']) {
            compare(Placement.markerIndex(Placement.reconcile(fixtures(), true, invalid, 512).items), 3)
        }
        const items = [{ type: Placement.markerType }, { type: Placement.markerType }]
        const result = Placement.reconcile(items, true, "", 512)
        compare(result.items.length, 1)
        compare(items.length, 2)
        compare(Placement.reconcile(items, false, "", 512).items.length, 0)
        const full = Placement.reconcile(fixtures(), true, "", 3)
        compare(full.errorCode, "maximumItemCount")
        compare(full.items.length, 3)
    }

    function test_visualOrderAroundOpenApplications_data() {
        return [
            { tag: "recent-first", recent: 0, dynamic: 2, slots: 3,
                persistent: [0, 3, 4, 6], recentStart: 0, dynamicStart: 4 },
            { tag: "recent-after-windows", recent: 2, dynamic: 0, slots: 3,
                persistent: [0, 2, 3, 6], recentStart: 3, dynamicStart: 0 },
            { tag: "recent-empty-before-windows", recent: 0, dynamic: 2, slots: 0,
                persistent: [0, 0, 1, 3], recentStart: 0, dynamicStart: 1 },
            { tag: "move-handle-keeps-its-slot", recent: 0, dynamic: 2, slots: 3,
                persistent: [0, 3, 4, 7], recentStart: 0, dynamicStart: 5,
                markerSlot: true }
        ]
    }

    function test_visualOrderAroundOpenApplications(data) {
        const markerSlot = data.markerSlot === true
        for (let index = 0; index < 4; index++) {
            compare(Placement.persistentVisualIndex(index, data.dynamic, 2,
                data.recent, data.slots, markerSlot), data.persistent[index])
        }
        compare(Placement.recentVisualIndex(data.recent, 4, data.dynamic, 2, 0,
            markerSlot), data.recentStart)
        compare(Placement.dynamicVisualIndex(data.dynamic, markerSlot, data.recent,
            data.slots, 0), data.dynamicStart)
    }

    Component { id: itemsPage; Config.ConfigItems {} }
    Component { id: geometryState; Components.DockGeometryState {} }

    function test_emptyMarkerReservesNoSpace_data() {
        return [{ tag: "horizontal-panel", panel: true, vertical: false },
            { tag: "vertical-panel", panel: true, vertical: true },
            { tag: "horizontal-floating", panel: false, vertical: false },
            { tag: "vertical-floating", panel: false, vertical: true }]
    }

    function test_emptyMarkerReservesNoSpace(data) {
        const geometry = createTemporaryObject(geometryState, this,
            { dockItems: fixtures(), inPanel: data.panel, verticalPanel: data.vertical,
                horizontalPanel: !data.vertical })
        verify(geometry)
        const originalLength = geometry.panelCompactContentLength
        const originalCount = geometry.visibleFixedDockItemCount
        geometry.dockItems = Placement.reconcile(fixtures(), true, "", 512).items
        compare(geometry.panelCompactContentLength, originalLength)
        compare(geometry.visibleFixedDockItemCount, originalCount)
    }

    function test_itemsDraftRemovalAndCancelRecreation() {
        const persisted = JSON.stringify(fixtures())
        let page = createTemporaryObject(itemsPage, this,
            { cfg_dockItemsJson: persisted, cfg_showRecentApplications: true })
        verify(page)
        compare(Placement.markerIndex(page.items), 3)
        page.setItems(Items.moveItem(page.items, 3, 1).items)
        compare(Placement.markerIndex(page.items), 1)
        const memory = page.cfg_recentApplicationsPosition
        page.selectItem(1)
        verify(page.canConfigureSelectedItem())
        page.removeSelectedItem()
        verify(!page.cfg_showRecentApplications)
        compare(Placement.markerIndex(page.items), -1)
        page.cfg_showRecentApplications = true
        compare(Placement.markerIndex(page.items), 1)
        page.destroy()
        // A cancelled draft never changes the configuration passed to a new page.
        page = createTemporaryObject(itemsPage, this,
            { cfg_dockItemsJson: persisted, cfg_showRecentApplications: false,
                cfg_recentApplicationsPosition: memory })
        compare(Placement.markerIndex(page.items), -1)
        page.cfg_showRecentApplications = true
        compare(Placement.markerIndex(page.items), 1)
    }
}
