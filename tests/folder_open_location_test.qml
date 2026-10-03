// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtTest
import org.kde.kirigami as Kirigami
import "../contents/ui/components" as Components

TestCase {
    id: testCase

    name: "FolderOpenLocation"
    when: windowShown
    visible: true
    width: 640
    height: 480

    readonly property var sampleApps: [
        {name: "One", icon: "folder", command: "one"},
        {name: "Two", icon: "folder", command: "two"}
    ]

    Components.FolderPopup {
        id: folderPopup
        anchors.centerIn: parent
        animationStyle: "none"
        revealProgress: 1
        folderItem: ({
            name: "Home",
            icon: "user-home",
            apps: testCase.sampleApps
        })
    }

    SignalSpy {
        id: openSpy
        target: folderPopup
        signalName: "openLocationRequested"
    }

    function actionRow() {
        let row = null
        tryVerify(function() {
            row = findChild(folderPopup, "folderOpenLocationAction")
            return row !== null
        })
        return row
    }

    function fanAction() {
        let action = null
        tryVerify(function() {
            action = findChild(folderPopup, "folderFanLocationAction")
            return action !== null
        })
        return action
    }

    function gridAction() {
        let action = null
        tryVerify(function() {
            action = findChild(folderPopup, "folderGridOpenLocationAction")
            return action !== null
        })
        return action
    }

    function folderWithLocation() {
        return {
            name: "Home",
            icon: "user-home",
            sourcePath: "~",
            apps: sampleApps
        }
    }

    function folderWithGridCellCount(cellCount) {
        const apps = []
        // The last Grid cell belongs to the location action, as in the macOS
        // reference. Build only the application cells here.
        for (let index = 0; index < cellCount - 1; index++) {
            apps.push({
                name: "Entry " + index,
                icon: "folder",
                command: "entry" + index
            })
        }
        return {
            name: "Downloads",
            icon: "folder-download",
            sourcePath: "~/Downloads",
            apps: apps
        }
    }

    function folderWithAppsWithoutLocation(appCount) {
        const apps = []
        for (let index = 0; index < appCount; index++) {
            apps.push({
                name: "Entry " + index,
                icon: "folder",
                command: "entry" + index
            })
        }
        // No sourcePath: the container holds applications but cannot open a
        // folder, so it contributes no location cell to the Grid model.
        return {
            name: "Applications",
            icon: "folder-download",
            apps: apps
        }
    }

    function init() {
        failOnWarning(/.?/)
        // Restore the regular Array before re-enabling Fan. Some regression
        // cases deliberately inject only the indexed contract consumed by the
        // classic adapter and must not leak that test double into Fan bindings.
        folderPopup.folderItem = ({
            name: "Home",
            icon: "user-home",
            apps: sampleApps
        })
        folderPopup.layoutMode = "fan"
        folderPopup.popupDirection = Qt.TopEdge
        folderPopup.folderOpenerName = ""
        folderPopup.profileAutoLayout = true
        folderPopup.profileColumns = 3
        folderPopup.profileRows = 4
        folderPopup.profileFanScrollEnabled = false
        folderPopup.maximumAvailableWidth = 752
        folderPopup.maximumAvailableHeight = 640
        folderPopup.revealProgress = 1
        openSpy.clear()
        wait(0)
    }

    function test_withoutALocationTheFanDoesNotCloseWithAnAction() {
        compare(folderPopup.folderPathAvailable, false)
        compare(findChild(folderPopup, "folderFanLocationAction"), null,
            "A container without a folder must not close the arc with an action")
        const chromeAction = findChild(folderPopup, "folderOpenLocationAction")
        if (chromeAction !== null) {
            verify(!chromeAction.enabled,
                "The chrome action must stay inert while it has no folder")
        }
        compare(folderPopup.openLocationRowHeight, 0)
    }

    function test_theFanClosesWithTheActionAtItsFarEnd() {
        folderPopup.folderItem = folderWithLocation()
        wait(0)

        const fanView = findChild(folderPopup, "folderFanView")
        const action = fanAction()
        compare(fanView.folderPath, "~")
        verify(fanView.hasLocationAction)
        verify(action.enabled, "The action must react once the folder exists")
        verify(action.activeFocusOnTab, "The action must reach the focus chain")

        // The action is one more row of the arc: it never steals a row from the
        // items, so every entry the row limit allows stays visible.
        compare(fanView.visibleRowCount, fanView.itemCount + 1)
        compare(fanView.implicitHeight, fanView.bandHeight
            + fanView.leadingOverhang + fanView.trailingOverhang)

        // It sits at the far end and leans with the arc like any other row, and
        // with the full lean of that end.
        verify(Math.abs(action.rowLean) > 0,
            "The far end of the arc must lean: lean=" + action.rowLean)
        compare(Math.abs(action.rowLean), fanView.farEndLeanDegrees,
            "The closing row must reach the lean of the arc end")

        // Same visual language as an application entry: its own text in its own
        // pill beside the glyph. The label stays short because the glyph carries
        // the action, and the accessible name keeps describing what the row does.
        const label = findChild(action, "folderFanLocationLabel")
        verify(label !== null)
        compare(fanView.omittedItemCount, 0,
            "This container fits in the fan, so nothing is left out")
        compare(String(label.text), "Open",
            "The closing row must keep its own label short: " + label.text)
        compare(action.Accessible.name,
            "Open this folder in the file manager",
            "The closing row must describe its action for readers")

        const glyph = findChild(action, "folderFanLocationGlyph")
        verify(glyph !== null)
        verify(glyph.width > 0, "The action needs a glyph of its own")
        compare(glyph.rotation, 0,
            "The glyph must not lean on its own")

        // The closing row turns as one rigid group about the centre of its
        // glyph, exactly like an application row about its icon.
        const row = findChild(action, "folderFanLocationRowContent")
        const pill = findChild(action, "folderFanLocationPill")
        verify(row !== null, "The closing row needs its own container")
        verify(pill !== null, "The closing row needs its own pill")
        verify(row.transform !== null && row.transform.length === 1,
            "The row must carry exactly one rotation")
        compare(row.transform[0].angle, action.rowLean,
            "The row must turn with the lean of its end")
        compare(row.transform[0].origin.x,
            glyph.x + fanView.iconSize / 2,
            "The row must turn around the centre of its glyph")
        compare(pill.width, label.width
                + fanView.labelHorizontalPadding * 2,
            "The closing pill must hug its own caption")
        compare(label.parent, pill,
            "The caption must live in the pill that carries it")
        compare(glyph.parent, row,
            "The glyph must live in the row, outside the pill")

        // The glyph follows the reference: a disc that is the same themed
        // surface as the pill beside it, with an arrow pointing towards the
        // container it opens and the contrasting theme text colour, so it reads
        // on a light surface and on a dark one. It must stay nearly opaque: the
        // glyph has no pill behind it, so a translucent veil would dissolve
        // into whatever the desktop shows through the fan.
        const disc = findChild(action, "folderFanLocationDisc")
        verify(disc !== null)
        compare(String(disc.color),
            String(Qt.alpha(Kirigami.Theme.backgroundColor, 0.88)),
            "The glyph disc must be the same themed surface as the pill")
        verify(disc.color.a > 0.8,
            "The glyph disc must stay nearly opaque over the desktop: alpha="
                + disc.color.a)
        const arrow = findChild(action, "folderFanLocationArrow")
        verify(arrow !== null)
        compare(arrow.source, "go-next-symbolic")
        // The row is a button, so it must show the hand: the click belongs to
        // the delegate and the cursor is asked for with a hover handler.
        const cursor = findChild(action, "folderFanLocationCursor")
        verify(cursor !== null,
            "The closing row must ask for the hand cursor")
        compare(cursor.cursorShape, Qt.PointingHandCursor)
        verify(String(arrow.color) !== String(disc.color),
            "The arrow must contrast with the surface it sits on: arrow="
                + arrow.color + " disc=" + disc.color)
    }

    // More entries than the fan shows: the closing row announces the rest, the
    // way the macOS stack fan does, and its pill hosts that count without
    // eliding it.
    function test_theClosingRowCountsTheEntriesTheFanLeavesOut() {
        const apps = []
        for (let index = 0; index < 12; index++) {
            apps.push({
                name: "Entry " + index,
                icon: "folder",
                command: "entry" + index
            })
        }
        folderPopup.profileRows = 8
        folderPopup.folderOpenerName = "Dolphin"
        folderPopup.folderItem = {
            name: "Home",
            icon: "user-home",
            sourcePath: "~",
            apps: apps
        }
        wait(0)

        const fanView = findChild(folderPopup, "folderFanView")
        compare(fanView.itemCount, 12)
        verify(fanView.visibleItemRows > 0)
        verify(fanView.visibleItemRows <= folderPopup.profileRows,
            "The scaled fan must respect both the configured rows and screen ceiling")
        compare(fanView.overflowItemCount,
            fanView.itemCount - fanView.visibleItemRows)
        compare(fanView.omittedItemCount, fanView.overflowItemCount)
        // The static fan really truncates its model, so the entries the row
        // announces are not reachable inside the popup and the row is the only
        // way to them.
        compare(fanView.effectiveScrollEnabled, false)
        compare(fanView.displayedItemCount, fanView.visibleItemRows)
        compare(findChild(folderPopup,
            "folderFanDelegate-" + fanView.visibleItemRows), null,
            "An omitted entry must not keep a delegate")
        const fanList = findChild(folderPopup, "folderFanList")
        compare(fanList.interactive, false)

        const action = fanAction()
        const label = findChild(action, "folderFanLocationLabel")
        verify(label !== null)
        compare(String(label.text),
            fanView.overflowItemCount + " more in Dolphin",
            "The closing row must count what it leaves out and name where it "
                + "opens: " + label.text)
        verify(!String(label.text).includes("…"),
            "The count must never be elided: " + label.text)
        // The pill hugs the text it shows, so the count cannot be cut.
        verify(label.implicitWidth <= label.width + 0.5,
            "The count must fit inside its own pill: implicit="
                + label.implicitWidth + " width=" + label.width)
        verify(action.Accessible.name
                === "Open this folder in the file manager",
            "A count must not replace the accessible action")
        verify(String(action.Accessible.description).indexOf(
                String(fanView.overflowItemCount)) >= 0,
            "The description must tell how many entries are left out: "
                + action.Accessible.description)

        // Without a known file manager the count stands alone, so the row never
        // shows a dangling destination.
        folderPopup.folderOpenerName = ""
        tryVerify(function() {
            return String(label.text) === fanView.overflowItemCount + " more"
        })

        // Returning the scrolling restores the whole model and clears the
        // count: the four entries are reachable again, so nothing is omitted.
        folderPopup.profileFanScrollEnabled = true
        tryVerify(function() {
            return fanView.displayedItemCount === 12
        })
        compare(fanView.omittedItemCount, 0,
            "A scrolling fan must not claim an omission")
        compare(fanList.interactive, true)
        tryVerify(function() {
            return String(label.text) === "Open"
        }, 5000, "A fan that omits nothing must fall back to the short action "
            + "label: " + label.text)
        compare(action.Accessible.description, "",
            "A scrolling fan must not announce an omission")
    }

    function test_theActionClosesTheArcAwayFromThePanel() {
        folderPopup.folderItem = folderWithLocation()
        wait(0)

        const fanView = findChild(folderPopup, "folderFanView")
        compare(fanView.locationActionAtListStart, true,
            "With the popup opening upward the action must close the head")
        const action = fanAction()
        const originDelegate = findChild(folderPopup,
            "folderFanDelegate-" + (fanView.itemCount - 1))
        verify(originDelegate !== null)
        verify(action.y < originDelegate.y,
            "The action must sit beyond the items, away from the panel")
    }

    function test_activatingTheActionRequestsTheContainerFolder() {
        folderPopup.folderItem = folderWithLocation()
        wait(0)

        fanAction().clicked()
        tryVerify(function() {
            return openSpy.count === 1
        })
        compare(openSpy.signalArguments[0][0], "~")
    }

    function test_keyboardActivationRequestsTheContainerFolder() {
        folderPopup.folderItem = folderWithLocation()
        wait(0)

        const action = fanAction()
        action.forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_Return)
        tryVerify(function() {
            return openSpy.count === 1
        })
        compare(openSpy.signalArguments[0][0], "~")

        openSpy.clear()
        keyClick(Qt.Key_Space)
        tryVerify(function() {
            return openSpy.count === 1
        })
        compare(openSpy.signalArguments[0][0], "~")
    }

    function test_gridIntegratesTheLocationActionAsItsFinalCell() {
        folderPopup.layoutMode = "grid"
        folderPopup.folderOpenerName = "Dolphin"
        folderPopup.folderItem = folderWithLocation()
        wait(0)

        compare(folderPopup.openLocationRowHeight, 0,
            "Grid must not reserve a separate footer row")
        compare(folderPopup.classicItemCount, folderPopup.itemCount + 1,
            "Grid must append exactly one location action to its visible model")
        const action = gridAction()
        compare(action.index, folderPopup.itemCount,
            "The location action must be the final Grid cell")
        compare(String(findChild(action,
            "folderGridOpenLocationLabel").text), "Open in Dolphin")
        compare(findChild(action, "folderGridOpenLocationArrow").source,
            "go-next-symbolic")
        compare(findChild(folderPopup, "folderOpenLocationAction"), null,
            "Grid must not expose a second location action outside its model")
        compare(findChild(folderPopup, "folderFanLocationAction"), null)
    }

    function test_gridAutomaticallyMatchesTheReferenceCellDistribution() {
        folderPopup.layoutMode = "grid"
        folderPopup.maximumAvailableWidth = 752
        folderPopup.maximumAvailableHeight = 640

        const cases = [
            {cells: 7, columns: 4, rows: 2},
            {cells: 10, columns: 5, rows: 2},
            {cells: 13, columns: 5, rows: 3},
            {cells: 16, columns: 4, rows: 4},
            {cells: 19, columns: 5, rows: 4}
        ]
        for (let index = 0; index < cases.length; index++) {
            const expectation = cases[index]
            folderPopup.folderItem = folderWithGridCellCount(
                expectation.cells)
            tryCompare(folderPopup, "classicItemCount", expectation.cells)
            compare(folderPopup.gridColumnCount, expectation.columns,
                expectation.cells + " cells must use the reference column count")
            compare(folderPopup.classicRowCount, expectation.rows,
                expectation.cells + " cells must use the reference row count")
            verify(!folderPopup.scrollRequired,
                expectation.cells + " cells must fit without premature scrolling")
        }
    }

    // A container without a folder has no elastic cell, so the arrangement has
    // to close the rectangle with the applications alone instead of leaving the
    // last row half empty.
    function test_gridAutomaticallyOrdersAContainerWithoutALocationAction() {
        folderPopup.layoutMode = "grid"
        folderPopup.maximumAvailableWidth = 752
        folderPopup.maximumAvailableHeight = 640
        folderPopup.folderOpenerName = ""

        const cases = [
            {cells: 6, columns: 3, rows: 2},
            {cells: 8, columns: 4, rows: 2},
            {cells: 9, columns: 3, rows: 3},
            {cells: 10, columns: 5, rows: 2},
            {cells: 12, columns: 4, rows: 3}
        ]
        for (let index = 0; index < cases.length; index++) {
            const expectation = cases[index]
            folderPopup.folderItem = folderWithAppsWithoutLocation(
                expectation.cells)
            tryCompare(folderPopup, "classicItemCount", expectation.cells)
            compare(folderPopup.openLocationRowHeight, 0,
                "A container without a folder must not reserve a footer row")
            compare(folderPopup.gridColumnCount, expectation.columns,
                expectation.cells + " applications must fill the rectangle")
            compare(folderPopup.classicRowCount, expectation.rows,
                expectation.cells + " applications must use the closed shape")
            verify(!folderPopup.scrollRequired,
                expectation.cells + " applications must fit without premature scrolling")
        }
    }

    // Both container kinds share one cost function. The elastic cell of a folder
    // container is what tells them apart, so the same list of applications may
    // legitimately close in a different shape.
    function test_gridTellsBothContainerKindsApart() {
        folderPopup.layoutMode = "grid"
        folderPopup.maximumAvailableWidth = 752
        folderPopup.maximumAvailableHeight = 640

        folderPopup.folderItem = folderWithAppsWithoutLocation(6)
        tryCompare(folderPopup, "classicItemCount", 6)
        compare(folderPopup.gridColumnCount, 3,
            "Six applications alone close a rectangle of three columns")

        folderPopup.folderItem = ({
            "name": "Home",
            "icon": "user-home",
            "sourcePath": "~",
            "apps": folderWithAppsWithoutLocation(6).apps
        })
        tryCompare(folderPopup, "classicItemCount", 7)
        compare(folderPopup.gridColumnCount, 4,
            "The elastic location cell moves the same list to four columns")
    }

    function test_manualGridKeepsItsConfiguredRowsAndColumns() {
        folderPopup.layoutMode = "grid"
        folderPopup.profileAutoLayout = false
        folderPopup.profileColumns = 3
        folderPopup.profileRows = 2
        folderPopup.folderItem = folderWithGridCellCount(10)
        tryCompare(folderPopup, "classicItemCount", 10)

        compare(folderPopup.gridColumnCount, 3)
        compare(folderPopup.classicRowCount, 4)
        compare(folderPopup.visibleClassicRows, 2)
        verify(folderPopup.scrollRequired)

        folderPopup.profileAutoLayout = true
        tryCompare(folderPopup, "gridColumnCount", 5)
        compare(folderPopup.classicRowCount, 2)
        verify(!folderPopup.scrollRequired)

        folderPopup.profileAutoLayout = false
        tryCompare(folderPopup, "gridColumnCount", 3)
        compare(folderPopup.profileColumns, 3,
            "Automatic must not overwrite the manual column preference")
        compare(folderPopup.profileRows, 2,
            "Automatic must not overwrite the manual row preference")
    }

    function test_classicViewsRenderConfiguredApplications() {
        const modes = ["grid", "list", "detailed"]
        for (let index = 0; index < modes.length; index++) {
            folderPopup.layoutMode = modes[index]
            folderPopup.folderItem = {
                name: "LibreOffice",
                icon: "folder-documents",
                apps: sampleApps
            }
            tryCompare(folderPopup, "classicItemCount", 2)
            const firstDelegate = findChild(folderPopup,
                "folderPopupDelegate-0")
            verify(firstDelegate !== null,
                modes[index] + " must render the first configured application")
            compare(firstDelegate.displayName, "One")
        }
    }

    function test_classicAdapterKeepsTheConfigurationModelIdentity() {
        // A list supplied by another QML context can keep the indexed model
        // contract without passing this component's Array identity check. The
        // adapter must preserve that model instead of replacing it with [].
        const configuredApps = {
            0: {name: "Writer", icon: "libreoffice-writer",
                command: "libreoffice --writer"},
            1: {name: "Calc", icon: "libreoffice-calc",
                command: "libreoffice --calc"},
            length: 2
        }
        const modes = ["grid", "list", "detailed"]
        const classicView = findChild(folderPopup, "folderPopupGridView")
        verify(classicView !== null)
        for (let index = 0; index < modes.length; index++) {
            folderPopup.layoutMode = modes[index]
            folderPopup.folderItem = {
                name: "LibreOffice",
                icon: "folder-documents",
                apps: configuredApps
            }
            tryCompare(folderPopup, "classicItemCount", 2)
            compare(classicView.model, configuredApps,
                modes[index] + " must preserve the supplied model")
        }
    }

    function test_gridLocationActionSupportsPointerAndKeyboardActivation() {
        folderPopup.layoutMode = "grid"
        folderPopup.folderOpenerName = "Dolphin"
        folderPopup.folderItem = folderWithLocation()
        wait(0)

        gridAction().activate()
        tryCompare(openSpy, "count", 1)
        compare(openSpy.signalArguments[0][0], "~")

        openSpy.clear()
        const pointer = findChild(folderPopup,
            "folderGridOpenLocationPointer")
        verify(pointer !== null)
        pointer.forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_Return)
        tryCompare(openSpy, "count", 1)
        compare(openSpy.signalArguments[0][0], "~")

        openSpy.clear()
        keyClick(Qt.Key_Space)
        tryCompare(openSpy, "count", 1)
        compare(openSpy.signalArguments[0][0], "~")
        compare(pointer.Accessible.name, "Open in Dolphin")
        compare(pointer.Accessible.description,
            "Open this folder in the file manager")
    }

    function test_gridLocationDelegateCanBeDestroyedAndRecreated() {
        folderPopup.layoutMode = "grid"
        folderPopup.folderItem = folderWithLocation()
        tryVerify(function() {
            return findChild(folderPopup,
                "folderGridOpenLocationAction") !== null
        })

        folderPopup.folderItem = ({
            name: "Without location",
            icon: "folder",
            apps: sampleApps
        })
        tryVerify(function() {
            return findChild(folderPopup,
                "folderGridOpenLocationAction") === null
        })
        compare(folderPopup.classicItemCount, folderPopup.itemCount)

        folderPopup.layoutMode = "list"
        folderPopup.folderItem = folderWithLocation()
        wait(0)
        compare(findChild(folderPopup,
            "folderGridOpenLocationAction"), null)
        verify(actionRow().enabled)

        folderPopup.layoutMode = "grid"
        tryVerify(function() {
            return findChild(folderPopup,
                "folderGridOpenLocationAction") !== null
        })
        compare(folderPopup.classicItemCount, folderPopup.itemCount + 1)
    }

    function test_listAndDetailedAppendTheActionToTheCollection() {
        folderPopup.folderItem = folderWithLocation()
        for (const mode of ["list", "detailed"]) {
            folderPopup.layoutMode = mode
            folderPopup.folderOpenerName = ""
            const pointer = actionRow()
            const grid = findChild(folderPopup, "folderPopupGridView")
            const row = findChild(folderPopup, "folderOpenLocationRow")
            compare(folderPopup.openLocationRowHeight, 0,
                "The action must not reserve a fixed footer")
            compare(folderPopup.classicItemCount, folderPopup.itemCount + 1)
            tryCompare(grid, "count", folderPopup.itemCount + 1)
            compare(row.index, folderPopup.itemCount,
                "The location action must be the final collection row")
            compare(row.parent, grid.contentItem,
                "The action must scroll with the collection")
            compare(findChild(folderPopup, "folderOpenLocationSlot"), null)
            compare(String(findChild(row, "folderOpenLocationLabel").text), "Open")
            folderPopup.folderOpenerName = "Dolphin"
            compare(String(findChild(row, "folderOpenLocationLabel").text), "Open in Dolphin")
            verify(findChild(row, "folderOpenLocationGlyph") !== null)
            compare(String(findChild(row, "folderOpenLocationDisc").color),
                String(Qt.alpha(Kirigami.Theme.backgroundColor, 0.88)))
            compare(findChild(row, "folderOpenLocationArrow").source, "go-next-symbolic")
            verify(pointer.activeFocusOnTab)
            compare(pointer.Accessible.name, "Open in Dolphin")
            compare(pointer.Accessible.description, "Open this folder in the file manager")
            compare(findChild(folderPopup, "folderFanLocationAction"), null)

            const previous = findChild(folderPopup, "folderPopupPointer-1")
            previous.forceActiveFocus()
            keyClick(Qt.Key_Down)
            tryCompare(grid, "currentIndex", row.index)
            tryCompare(pointer, "activeFocus", true)
            openSpy.clear()
            keyClick(Qt.Key_Return)
            compare(openSpy.count, 1)
            compare(openSpy.signalArguments[0][0], "~")
            keyClick(Qt.Key_Up)
            tryCompare(grid, "currentIndex", 1)
            tryCompare(previous, "activeFocus", true)
            openSpy.clear()
            waitForRendering(pointer)
            mouseMove(pointer, pointer.width / 2, pointer.height / 2)
            mouseClick(pointer, pointer.width / 2, pointer.height / 2)
            tryCompare(openSpy, "count", 1)
            compare(openSpy.signalArguments[0][0], "~")
            compare(grid.currentIndex, row.index)
        }
        for (const mode of ["fan", "grid"]) {
            folderPopup.layoutMode = mode
            wait(0)
            compare(folderPopup.openLocationRowHeight, 0)
            compare(findChild(folderPopup, "folderOpenLocationAction"), null)
        }
    }

    function test_listAndDetailedScrollToTheFinalAction() {
        for (const mode of ["list", "detailed"]) {
            folderPopup.layoutMode = mode
            folderPopup.profileAutoLayout = false
            folderPopup.profileRows = 3
            folderPopup.maximumAvailableHeight = 300
            folderPopup.folderItem = folderWithGridCellCount(25)
            const grid = findChild(folderPopup, "folderPopupGridView")
            tryCompare(grid, "count", 25)
            verify(folderPopup.scrollRequired)
            grid.positionViewAtBeginning()
            let first = null
            tryVerify(function() {
                first = findChild(folderPopup, "folderPopupPointer-0")
                return first !== null
            })
            waitForRendering(first)
            first.forceActiveFocus()
            for (let index = 1; index < grid.count; ++index) {
                keyClick(Qt.Key_Down)
                tryCompare(grid, "currentIndex", index)
            }
            const row = findChild(folderPopup, "folderOpenLocationRow")
            const pointer = actionRow()
            compare(row.index, 24)
            tryCompare(pointer, "activeFocus", true)
            verify(grid.contentY > 0)
            const position = row.mapToItem(grid, 0, 0)
            verify(position.y >= -1 && position.y + row.height <= grid.height + 1,
                "The final action must fit inside the scrolled viewport")
            openSpy.clear()
            keyClick(Qt.Key_Space)
            compare(openSpy.count, 1)
            compare(openSpy.signalArguments[0][0], "~/Downloads")
        }
    }
}
