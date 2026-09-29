// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtTest
import "../contents/ui/config" as ConfigPages

TestCase {
    id: testCase

    name: "ConfigFolderPopupsAutoLayout"
    when: windowShown
    width: 640
    height: 760

    ConfigPages.ConfigFolderPopups {
        id: page
        width: 600
        height: implicitHeight
    }

    function init() {
        failOnWarning(/.?/)
        page.activeProfile = "grid"
        page.cfg_folderGridAutoLayout = true
        page.cfg_folderGridColumns = 3
        page.cfg_folderGridRows = 4
        wait(0)
    }

    function arrangementCombo() {
        let control = null
        tryVerify(function() {
            control = findChild(page, "gridArrangementCombo")
            return control !== null
        })
        return control
    }

    function columnsControl() {
        return findChild(page, "folderGridColumnsSpin")
    }

    function rowsControl() {
        return findChild(page, "folderPopupRowsSpin")
    }

    function test_automaticIsTheDefaultAndDisablesManualGeometry() {
        const combo = arrangementCombo()
        compare(page.cfg_folderGridAutoLayout, true)
        compare(combo.currentValue, true)
        verify(columnsControl() !== null)
        verify(rowsControl() !== null)
        compare(columnsControl().enabled, false)
        compare(rowsControl().enabled, false)
    }

    function test_manualRestoresTheStoredRowsAndColumns() {
        const combo = arrangementCombo()
        page.cfg_folderGridColumns = 6
        page.cfg_folderGridRows = 7
        page.cfg_folderGridAutoLayout = false
        tryCompare(combo, "currentIndex", 1)

        compare(columnsControl().enabled, true)
        compare(rowsControl().enabled, true)
        compare(page.cfg_folderGridColumns, 6)
        compare(page.cfg_folderGridRows, 7)

        page.cfg_folderGridAutoLayout = true
        tryCompare(combo, "currentIndex", 0)
        compare(page.cfg_folderGridColumns, 6,
            "Automatic must preserve the manual column value")
        compare(page.cfg_folderGridRows, 7,
            "Automatic must preserve the manual row value")
    }

    function test_selectorFeedsTheValueAppliedByTheKcm() {
        const combo = arrangementCombo()
        combo.activated(1)
        tryCompare(page, "cfg_folderGridAutoLayout", false)
        tryCompare(combo, "currentIndex", 1)

        combo.activated(0)
        tryCompare(page, "cfg_folderGridAutoLayout", true)
        tryCompare(combo, "currentIndex", 0)
    }

    function test_selectorIsKeyboardAccessible() {
        const combo = arrangementCombo()
        verify(String(combo.Accessible.name).length > 0)
        compare(combo.activeFocusOnTab, true)
    }
}
