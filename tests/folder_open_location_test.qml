// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtTest
import org.kde.kirigami as Kirigami
import "../contents/ui/components" as Components

TestCase {
    id: testCase

    name: "FolderOpenLocation"
    when: windowShown
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

    function actionSlot() {
        let slot = null
        tryVerify(function() {
            slot = findChild(folderPopup, "folderOpenLocationSlot")
            return slot !== null
        })
        return slot
    }

    function fanAction() {
        let action = null
        tryVerify(function() {
            action = findChild(folderPopup, "folderFanLocationAction")
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

    function init() {
        failOnWarning(/.?/)
        folderPopup.layoutMode = "fan"
        folderPopup.popupDirection = Qt.TopEdge
        folderPopup.folderOpenerName = ""
        folderPopup.profileFanScrollEnabled = false
        folderPopup.folderItem = ({
            name: "Home",
            icon: "user-home",
            apps: sampleApps
        })
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
        compare(fanView.visibleItemRows, 8)
        compare(fanView.overflowItemCount, 4)
        compare(fanView.omittedItemCount, 4)
        // The static fan really truncates its model, so the four entries the
        // row announces are not reachable inside the popup and the row is the
        // only way to them.
        compare(fanView.effectiveScrollEnabled, false)
        compare(fanView.displayedItemCount, 8)
        compare(findChild(folderPopup, "folderFanDelegate-8"), null,
            "An omitted entry must not keep a delegate")
        const fanList = findChild(folderPopup, "folderFanList")
        compare(fanList.interactive, false)

        const action = fanAction()
        const label = findChild(action, "folderFanLocationLabel")
        verify(label !== null)
        compare(String(label.text), "4 more in Dolphin",
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
        verify(String(action.Accessible.description).indexOf("4") >= 0,
            "The description must tell how many entries are left out: "
                + action.Accessible.description)

        // Without a known file manager the count stands alone, so the row never
        // shows a dangling destination.
        folderPopup.folderOpenerName = ""
        tryVerify(function() {
            return String(label.text) === "4 more"
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

    function test_otherPresentationsKeepTheChromeAction() {
        folderPopup.layoutMode = "grid"
        folderPopup.folderItem = folderWithLocation()
        wait(0)

        // The grid has no arc to close, so the action is chrome of the popup and
        // the fan keeps waiting for a folder.
        verify(folderPopup.openLocationRowHeight > 0)
        verify(actionRow().enabled)
        verify(actionSlot().parent !== null)
        compare(findChild(folderPopup, "folderFanLocationAction"), null)
    }

    // The chrome action of grid, list and detailed shows the glyph of the
    // reference —a disc of the themed surface with an arrow inside— and names
    // the file manager the desktop opens a folder with, so it reads like the
    // closing row of the fan instead of reading like the container.
    function test_theChromeActionNamesTheFileManager() {
        folderPopup.layoutMode = "grid"
        folderPopup.folderOpenerName = ""
        folderPopup.folderItem = folderWithLocation()
        wait(0)

        const label = findChild(folderPopup, "folderOpenLocationLabel")
        verify(label !== null, "The chrome action needs its own caption")
        compare(String(label.text), "Open",
            "Without a known file manager the caption stays a short action word")

        folderPopup.folderOpenerName = "Dolphin"
        tryVerify(function() {
            return String(label.text) === "Open in Dolphin"
        })

        // The container's icon is not used here any more: the row is an action.
        compare(findChild(folderPopup, "folderOpenLocationIcon"), null,
            "The chrome action must not show the icon of the container")
        const glyph = findChild(folderPopup, "folderOpenLocationGlyph")
        verify(glyph !== null, "The chrome action needs the glyph of the reference")
        const disc = findChild(folderPopup, "folderOpenLocationDisc")
        verify(disc !== null, "The glyph needs the disc of the reference")
        compare(String(disc.color),
            String(Qt.alpha(Kirigami.Theme.backgroundColor, 0.88)),
            "The glyph disc must be the same themed surface as the fan glyph")
        const arrow = findChild(folderPopup, "folderOpenLocationArrow")
        verify(arrow !== null, "The glyph needs the arrow of the reference")
        compare(arrow.source, "go-next-symbolic",
            "One action must keep one glyph in the chrome and in the fan")

        // The three presentations without an arc share this row, and none of them
        // falls back to the fan.
        for (let index = 0; index < 2; index++) {
            folderPopup.layoutMode = index === 0 ? "list" : "detailed"
            wait(0)
            verify(folderPopup.openLocationRowHeight > 0,
                "The " + folderPopup.layoutMode
                    + " presentation must keep the row")
            compare(String(findChild(folderPopup,
                    "folderOpenLocationLabel").text), "Open in Dolphin",
                "The " + folderPopup.layoutMode
                    + " presentation must share the caption of the action")
            compare(findChild(folderPopup, "folderFanLocationAction"), null,
                "Only the fan presentation may render the fan action")
        }

        // The fan keeps its own closing row: the chrome row of the other
        // presentations reserves no height there.
        folderPopup.layoutMode = "fan"
        wait(0)
        compare(folderPopup.openLocationRowHeight, 0,
            "The fan must not reserve the height of the chrome row")
    }
}
