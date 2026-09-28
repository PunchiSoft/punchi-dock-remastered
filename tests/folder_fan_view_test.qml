// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtTest
import "../contents/ui/components" as Components

TestCase {
    id: testCase

    name: "FolderFanView"
    when: windowShown
    width: 480
    height: 420

    property var sampleApps: [
        {name: "One", icon: "folder", command: "one"},
        {name: "Two documents", icon: "folder", command: "two"},
        {name: "Three", icon: "folder", command: "three"},
        {name: "Four", icon: "folder", command: "four"},
        {name: "Five", icon: "folder", command: "five"}
    ]

    Window {
        id: hostWindow
        width: 480
        height: 420
        visible: true

        Components.FolderFanView {
            id: fanView
            anchors.centerIn: parent
            width: 360
            height: implicitHeight
            apps: testCase.sampleApps
            iconSize: 40
            rowLimit: 3
            popupDirection: Qt.TopEdge
            revealProgress: 1
        }
    }

    SignalSpy {
        id: launchSpy
        target: fanView
        signalName: "appLaunched"
    }

    SignalSpy {
        id: contextSpy
        target: fanView
        signalName: "appContextMenuRequested"
    }

    SignalSpy {
        id: closeSpy
        target: fanView
        signalName: "closeRequested"
    }

    function delegateAt(index) {
        let delegate = null
        tryVerify(function() {
            delegate = findChild(fanView, "folderFanDelegate-" + index)
            return delegate !== null
        })
        return delegate
    }

    // The list animates displaced rows and recreates delegates after a model
    // reset, so a measurement taken right after a change can catch a row mid
    // transition. Wait for the rows to stop moving before asserting geometry.
    function settleLayout() {
        let previous = Number.NaN
        tryVerify(function() {
            const current = delegateAt(2).y
            const stable = current === previous
            previous = current
            return stable
        })
    }

    // Geometry is always read through a fresh lookup: a delegate captured before
    // a model reset can be a stale, already destroyed object.
    function rowOffsetY(index) {
        const list = findChild(fanView, "folderFanList")
        const delegate = findChild(fanView,
            "folderFanDelegate-" + index)
        return delegate.mapToItem(list.contentItem, 0, 0).y
    }


    function iconOffsetX(index) {
        const icon = findChild(fanView, "folderFanIcon-" + index)
        return icon.mapToItem(null, 0, 0).x
    }

    function fuzzyCompare(actual, expected, message) {
        verify(Math.abs(actual - expected) < 0.001,
            message + ": actual=" + actual + " expected=" + expected)
    }

    function makeApps(count) {
        const list = []
        for (let index = 0; index < count; index++) {
            list.push({
                name: "Item " + index,
                icon: "folder",
                command: "item" + index
            })
        }
        return list
    }

    // Long names widen the pill, which is what makes the far end of a long arc
    // fly outside its own row band.
    function makeNamedApps(count, name) {
        const list = []
        for (let index = 0; index < count; index++) {
            list.push({
                name: name + " " + index,
                icon: "folder",
                command: "item" + index
            })
        }
        return list
    }

    function init() {
        failOnWarning(/.?/)
        tryCompare(hostWindow, "visible", true)
        hostWindow.requestActivate()
        tryCompare(hostWindow, "active", true)
        fanView.rowLimit = 3
        fanView.popupDirection = Qt.TopEdge
        fanView.motionEnabled = true
        fanView.revealProgress = 1
        fanView.apps = sampleApps
        fanView.iconSize = 40
        fanView.showLabels = true
        fanView.maximumContentHeight = 0
        fanView.folderPath = ""
        fanView.folderOpenerName = ""
        fanView.scrollEnabled = false
        launchSpy.clear()
        contextSpy.clear()
        closeSpy.clear()
        fanView.focusFirstItem(Qt.OtherFocusReason)
        const list = findChild(fanView, "folderFanList")
        if (list) {
            list.positionViewAtBeginning()
        }
        wait(0)
    }

    function test_geometryUsesVisibleRowsAndViewportCurve() {
        compare(fanView.itemCount, 5)
        compare(fanView.visibleRowCount, 3)
        // The band and the reserve the leaning pills need add up to the height
        // the fan declares. A three-row fan leans so little that its pills stay
        // inside their own band, so there is nothing to reserve.
        compare(fanView.implicitHeight, fanView.bandHeight
            + fanView.leadingOverhang + fanView.trailingOverhang)
        compare(fanView.leadingOverhang, 0)
        compare(fanView.trailingOverhang, 0)
        verify(fanView.scrollRequired)

        const first = delegateAt(0)
        const second = delegateAt(1)
        const third = delegateAt(2)
        verify(first.curveOffset > second.curveOffset)
        verify(second.curveOffset > third.curveOffset)
        verify(first.iconPosition > third.iconPosition)
        verify(first.iconPosition > fanView.width / 2)
        fuzzyCompare(third.iconPosition + fanView.iconSize / 2,
            fanView.originIconCenterX,
            "The panel-facing icon must define the fan origin")
        verify(fanView.curveAmplitude > 0,
            "A three-row fan must still follow its arc")
        // The reference law: the sag is the second order of the same angle that
        // turns the cards, so a three-row fan is shallow instead of curling.
        fuzzyCompare(fanView.curveAmplitude, fanView.rowHeight
            * (fanView.rowSagPerPitch * fanView.arcRowSpan
                + fanView.rowSagPerPitchSquared
                    * fanView.arcRowSpan * fanView.arcRowSpan),
            "The sag must follow the reference arc")

        const firstPill = findChild(first, "folderFanPill-0")
        const secondPill = findChild(second, "folderFanPill-1")
        const firstLabel = findChild(first, "folderFanLabel-0")
        const secondLabel = findChild(second, "folderFanLabel-1")
        verify(firstPill !== null)
        verify(secondPill !== null)
        // A pill hugs its own name, so its width follows its own text.
        verify(secondPill.width > firstPill.width,
            "A pill must hug the name it carries")
        verify(secondLabel.width > firstLabel.width,
            "Fan labels must size to their own text instead of forming rows")
        fanView.popupDirection = Qt.RightEdge
        tryVerify(function() {
            return first.iconPosition < fanView.width / 2
        })
    }

    function test_longNameKeepsFullSourceInsideCappedPill() {
        const longName = "An extraordinarily long application name"
        fanView.apps = makeNamedApps(3, longName)
        settleLayout()

        const first = delegateAt(0)
        const pill = findChild(first, "folderFanPill-0")
        const label = findChild(first, "folderFanLabel-0")
        verify(pill !== null)
        verify(label !== null)
        verify(label.overflowing,
            "A long fan name must use the shared elided viewport")
        verify(pill.width <= fanView.itemLabelWidthLimit + 0.5,
            "A long name must not widen its pill beyond the resting cap")
        compare(label.text, longName + " 0",
            "The marquee source must retain the complete accessible name")
    }

    function test_curveOriginFollowsThePanelFacingEdge() {
        const first = delegateAt(0)
        const third = delegateAt(2)

        fanView.popupDirection = Qt.TopEdge
        tryVerify(function() {
            return first.curveOffset > third.curveOffset
        })
        fuzzyCompare(third.curveOffset, 0,
            "A popup opening upward must start at its bottom row")
        verify(fanView.revealOffsetYForItem(first.y) > 0)
        fuzzyCompare(fanView.revealOffsetYForItem(third.y), 0,
            "The bottom source row must not move away from the launcher")

        fanView.popupDirection = Qt.BottomEdge
        tryVerify(function() {
            return third.curveOffset > first.curveOffset
        })
        fuzzyCompare(first.curveOffset, 0,
            "A popup opening downward must start at its top row")
        fuzzyCompare(fanView.revealOffsetYForItem(first.y), 0,
            "The top source row must not move away from the launcher")
        verify(fanView.revealOffsetYForItem(third.y) < 0)
    }

    function test_curveSagFollowsTheReferenceLaw() {
        fanView.showLabels = false
        const counts = [3, 4, 6, 8]
        const samples = []
        for (let index = 0; index < counts.length; index++) {
            const count = counts[index]
            fanView.rowLimit = Math.min(8, count)
            fanView.apps = makeApps(count)
            wait(0)
            const visibleRows = fanView.visibleRowCount
            verify(visibleRows >= 1)
            const span = fanView.arcRowSpan
            const sag = fanView.requestedCurveAmplitude
            fuzzyCompare(sag, fanView.rowHeight
                * (fanView.rowSagPerPitch * span
                    + fanView.rowSagPerPitchSquared * span * span),
                "The sag must follow the reference arc: rows=" + visibleRows)
            // The deformity this locks out: a fan that curls more than its own
            // pitch. The reference stays below one pitch (0.91 for its nine
            // rows) while the previous law reached 1.41.
            verify(sag <= fanView.rowHeight * 1.0 + 0.001,
                "The arc must not curl more than its own pitch: rows="
                    + visibleRows + " sag=" + sag)
            fuzzyCompare(fanView.farEndLeanDegrees,
                span * fanView.rowArcStepDegrees,
                "The lean must repeat the angular step of one row")
            samples.push({rows: visibleRows, sag: sag})
        }

        for (let index = 1; index < samples.length; index++) {
            verify(samples[index].sag >= samples[index - 1].sag - 0.001,
                "More visible rows must never shrink the arc: "
                    + samples[index - 1].rows + " -> " + samples[index].rows)
        }
        verify(samples[samples.length - 1].sag > samples[0].sag,
            "A long fan must open wider than a short one: "
                + samples[0].sag + " vs " + samples[samples.length - 1].sag)

        // The reference proportion for the nine rows of its capture: roughly
        // 0.9 pitch of sag, which is audible as a curve and not as a curl.
        fanView.rowLimit = 8
        fanView.apps = makeApps(9)
        wait(0)
        const nineRowSag = fanView.rowHeight * 1.0
        verify(fanView.requestedCurveAmplitude <= nineRowSag + 0.001)
        verify(fanView.requestedCurveAmplitude
                > fanView.rowHeight * 0.6,
            "Eight visible rows must curve visibly: "
                + fanView.requestedCurveAmplitude)
    }

    function test_arcOpensOutwardAndLeansIconsAlongTheCurve() {
        fanView.popupDirection = Qt.TopEdge
        fanView.motionEnabled = true
        fanView.revealProgress = 1

        const first = delegateAt(0)
        const second = delegateAt(1)
        const third = delegateAt(2)

        // The arc is one law for position and lean: every row sits on the circle
        // whose angular step turns its card.
        const row = fanView.normalizedDistanceForItem(second.y)
            * fanView.arcRowSpan
        fuzzyCompare(second.curveOffset, fanView.rowHeight
            * (fanView.rowSagPerPitch * row
                + fanView.rowSagPerPitchSquared * row * row),
            "The fan must place each row on the reference arc")
        verify(second.curveOffset < fanView.curveAmplitude * 0.5,
            "A short arc must keep the origin items aligned")

        // The icon at the panel-facing end stays upright and unshifted.
        fuzzyCompare(third.curveOffset, 0,
            "The origin item must stay on the base column")
        fuzzyCompare(third.rowLean, 0,
            "The origin row must stay upright")
        verify(first.rowLean > second.rowLean)
        verify(second.rowLean > third.rowLean)
        fuzzyCompare(first.rowLean, fanView.farEndLeanDegrees,
            "The far end of the arc must reach the lean of that end")

        // A popup opening downward mirrors the lean instead of reusing it,
        // and moves its origin to the top row.
        fanView.popupDirection = Qt.BottomEdge
        tryVerify(function() {
            return third.curveOffset > first.curveOffset
        })
        fuzzyCompare(first.curveOffset, 0,
            "A popup opening downward must start on its top row")
        fuzzyCompare(first.rowLean, 0,
            "The origin row must stay upright in both directions")
        fuzzyCompare(third.rowLean, -fanView.farEndLeanDegrees,
            "The mirrored arc must lean the opposite way")
    }

    // The room a leaning pill needs is the flight of its far end outside its own
    // row band. That flight belongs to the end the arc opens towards, and the
    // list keeps it as content of its head or its tail, so the band and the
    // reserve add up to the viewport: no half row is left over and no pill is
    // clipped by the edge of the list.
    function test_theReserveFollowsTheArcEndAndStaysInsideTheList() {
        const list = findChild(fanView, "folderFanList")
        fanView.iconSize = 48
        fanView.rowLimit = 8
        fanView.popupDirection = Qt.TopEdge

        // A short fan leans too little to leave its own band.
        fanView.apps = makeNamedApps(3,
            "Documentos del proyecto compartido")
        settleLayout()
        compare(fanView.visibleRowCount, 3)
        compare(fanView.leadingOverhang, 0)
        compare(fanView.trailingOverhang, 0)
        compare(list.height, fanView.bandHeight,
            "Without flight the list must hold its band only")
        compare(list.contentHeight, list.height,
            "A fan that shows every entry must not scroll")

        // A long one does fly, and only towards the end it opens to.
        fanView.folderPath = "~"
        fanView.apps = makeNamedApps(12,
            "Documentos del proyecto compartido")
        settleLayout()
        compare(fanView.visibleRowCount, 9)
        verify(fanView.leadingOverhang > 0,
            "The far end of a long arc must reserve its flight: "
                + fanView.leadingOverhang)
        verify(fanView.leadingOverhang < fanView.rowHeight,
            "The reserve must be a flight, not a whole row: "
                + fanView.leadingOverhang)
        compare(fanView.trailingOverhang, 0,
            "The border that faces the panel needs no reserve")
        compare(list.height, fanView.bandHeight + fanView.leadingOverhang,
            "The reserve must be part of what the list occupies")
        // The list rests with its band after the reserve, so the leaning pill of
        // the band's first row paints inside the list instead of being clipped by
        // its edge, and the last row of the band ends exactly at the other edge
        // instead of leaving a half row visible.
        compare(list.contentY,
            -(fanView.leadingOverhang + fanView.bandStartOffset),
            "The list must rest with its band after the reserve")
        const action = findChild(fanView, "folderFanLocationAction")
        verify(action !== null, "The container must close the arc with a row")
        compare(action.mapToItem(list, 0, 0).y, fanView.leadingOverhang,
            "The band must start after the reserve")
        const bandLastRow = findChild(fanView, "folderFanDelegate-" + 7)
        verify(bandLastRow !== null)
        compare(bandLastRow.mapToItem(list, 0, 0).y + bandLastRow.height,
            list.height,
            "The last row of the band must end at the edge of the list")

        // The mirror: a popup opening downwards reserves its own end instead.
        fanView.popupDirection = Qt.BottomEdge
        tryVerify(function() {
            return fanView.trailingOverhang > 0
        })
        compare(fanView.leadingOverhang, 0,
            "A mirrored arc must not reserve the end it leaves")
        verify(fanView.trailingOverhang < fanView.rowHeight,
            "The mirrored reserve must stay below one row: "
                + fanView.trailingOverhang)
    }

    // The arc shows the rows the available height fits, instead of asking for a
    // frame taller than the space it is given. The reserve grows with the row
    // count, so the count is the largest one whose reserve, band and closing row
    // fit together, and the arc re-derives from whatever is left.
    function test_theCeilingReducesTheVisibleRows() {
        fanView.iconSize = 48
        fanView.rowLimit = 8
        fanView.popupDirection = Qt.TopEdge
        fanView.apps = makeNamedApps(12,
            "Documentos del proyecto compartido")
        fanView.maximumContentHeight = 0
        settleLayout()
        compare(fanView.visibleRowCount, 8,
            "Without a ceiling the fan shows the rows it is configured with")

        const ceiling = fanView.rowHeight * 4
        fanView.maximumContentHeight = ceiling
        tryVerify(function() {
            return fanView.visibleRowCount < 8
        })
        verify(fanView.visibleRowCount >= 1,
            "The fan must keep at least one row: " + fanView.visibleRowCount)
        verify(fanView.implicitHeight <= ceiling + 0.001,
            "The fan must never ask for more height than it is given: "
                + fanView.implicitHeight + " > " + ceiling)
        compare(fanView.bandHeight,
            fanView.visibleRowCount * fanView.rowHeight)
        compare(fanView.arcRowSpan, fanView.visibleRowCount - 1,
            "The arc must re-derive from the rows that are left")
        // Whatever the ceiling, the reserve stays the flight of that arc and
        // never hides a row behind an edge.
        const list = findChild(fanView, "folderFanList")
        compare(list.height, fanView.bandHeight + fanView.leadingOverhang
            + fanView.trailingOverhang)
    }

    function test_everyRowKeepsItsNameOnOneLine() {
        fanView.popupDirection = Qt.TopEdge
        fanView.showLabels = true
        fanView.rowLimit = 6
        // The last entry is wider than the envelope and is a single word, so the
        // fan has to cut it by character before it reaches the pill.
        fanView.apps = [
            {name: "Writer", icon: "folder"},
            {name: "Calc", icon: "folder"},
            {name: "Impress", icon: "folder"},
            {name: "Draw", icon: "folder"},
            {name: "LibreOffice Math", icon: "folder"},
            {name: "UnbrokenApplicationNameThatCannotFitInsideTheEnvelope",
                icon: "folder"}
        ]
        wait(0)

        // Every pill keeps a fixed single-line viewport. Long source names are
        // preserved by the shared label and elided inside that viewport.
        for (let index = 0; index < fanView.itemCount; index++) {
            const label = findChild(fanView, "folderFanLabel-" + index)
            const pill = findChild(fanView, "folderFanPill-" + index)
            const icon = findChild(fanView, "folderFanIcon-" + index)
            verify(label !== null, "Missing fan label " + index)
            verify(pill !== null, "Missing fan pill " + index)
            verify(icon !== null, "Missing fan icon " + index)
            verify(label.viewportWidth <= label.width,
                "Fan label " + index + " exceeds its fixed viewport")
            verify(label.height <= pill.height,
                "Fan label " + index + " exceeds its one-line pill")
            // The pill is the text plus its own padding, nothing else: the icon
            // has no surface of its own, exactly as in the reference.
            compare(pill.width, label.width
                    + fanView.labelHorizontalPadding * 2,
                "A pill must hug the name it carries")
            compare(pill.height, fanView.labelHeight,
                "A pill must be as tall as the text it carries")
            compare(icon.parent, pill.parent,
                "The icon must sit beside its pill, never inside it")
            verify(pill.x + pill.width <= icon.x - fanView.iconSpacing
                    + 0.001,
                "Fan pill " + index + " must end next to its own icon")
        }

        const oversized = findChild(fanView, "folderFanLabel-5")
        compare(oversized.text,
            "UnbrokenApplicationNameThatCannotFitInsideTheEnvelope")
        verify(oversized.overflowing,
            "A name wider than the envelope must be visually elided")

        const fitting = findChild(fanView, "folderFanLabel-3")
        compare(fitting.text, "Draw",
            "A label that fits must be shown complete")
        verify(findChild(fanView, "folderFanPill-3").width
                < fanView.maximumRowWidth,
            "A short name must not fill the whole row envelope")
    }

    function test_revealSweepsFromThePanelFacingItem() {
        fanView.popupDirection = Qt.TopEdge
        fanView.motionEnabled = true
        fanView.revealProgress = 1
        wait(0)

        const far = delegateAt(0)
        const middle = delegateAt(1)
        const origin = delegateAt(2)

        fuzzyCompare(origin.itemRevealProgress, 1,
            "The origin item must settle with the shared progress")
        fuzzyCompare(far.itemRevealProgress, 1,
            "The far end must settle with the shared progress")

        fanView.revealProgress = 0
        wait(0)
        fuzzyCompare(far.itemRevealProgress, 0,
            "A closed fan must not reveal any item")

        fanView.revealProgress = 0.5
        wait(0)
        verify(origin.itemRevealProgress > middle.itemRevealProgress)
        verify(middle.itemRevealProgress > far.itemRevealProgress)
        verify(far.itemRevealProgress > 0,
            "Every item must start moving without an idle wait")
        verify(far.itemRevealProgress < 1,
            "The far end must still be settling halfway through")

        // Opening downwards moves the origin to the top row, and the sweep has
        // to follow it instead of keeping a fixed row order.
        fanView.revealProgress = 1
        fanView.popupDirection = Qt.BottomEdge
        wait(0)
        fanView.revealProgress = 0.5
        wait(0)
        verify(delegateAt(0).itemRevealProgress
            > delegateAt(2).itemRevealProgress,
            "The sweep must follow the mirrored origin")
        fanView.revealProgress = 1
    }

    function test_highlightWrapsTheIconInsideItsRow() {
        fanView.showLabels = true
        fanView.popupDirection = Qt.TopEdge
        wait(0)

        const first = delegateAt(0)
        const highlight = findChild(first, "folderFanHighlight-0")
        const row = findChild(first, "folderFanRowContent-0")
        const pill = findChild(first, "folderFanPill-0")
        verify(highlight !== null)
        verify(row !== null)
        verify(pill !== null)

        compare(pill.height, fanView.labelHeight,
            "The pill must be as tall as the text it carries")
        fuzzyCompare(pill.radius, pill.height / 2,
            "The pill must be a full pill")
        // The highlight follows the text silhouette it wraps, and it lives in
        // the row, so it leans with its own entry.
        fuzzyCompare(fanView.highlightRadius, fanView.labelHeight / 2,
            "The highlight radius must derive from the text height")
        fuzzyCompare(highlight.radius, fanView.highlightRadius,
            "The highlight must use the derived radius")
        verify(highlight.radius < highlight.height / 2,
            "The highlight must not become a full pill")
        compare(highlight.parent, row,
            "The highlight must live inside the row it marks")

        const smallRadius = fanView.highlightRadius
        fanView.iconSize = 60
        wait(0)
        verify(fanView.highlightRadius > smallRadius,
            "A derived radius must scale with the icon size")
        verify(fanView.highlightRadius < highlight.height / 2,
            "The scaled highlight must stay below a full pill")
    }

    function test_implicitWidthContainsLabelsIconsAndCurve() {
        const expectedWidth = Math.ceil(fanView.contentPadding * 2
            + fanView.desiredLabelWidth + fanView.labelSpacing
            + fanView.iconSize + fanView.requestedCurveAmplitude)
        compare(fanView.implicitWidth, expectedWidth)
        verify(fanView.maximumNaturalLabelWidth > 0)
        compare(fanView.iconSpacing, fanView.labelSpacing)
        // One name is capped so a single long entry cannot widen the popup, and
        // the widest row is its pill, the gap and its icon.
        verify(fanView.desiredLabelWidth <= fanView.maximumLabelWidth)
        compare(fanView.maximumRowWidth, fanView.iconSize
            + fanView.iconSpacing + fanView.desiredLabelWidth)

        fanView.showLabels = false
        compare(fanView.desiredLabelWidth, 0)
        compare(fanView.implicitWidth, Math.ceil(
            fanView.contentPadding * 2 + fanView.iconSize
                + fanView.requestedCurveAmplitude))
        fanView.showLabels = true
    }

    function test_everyRowTurnsAroundItsIconCentre() {
        fanView.popupDirection = Qt.TopEdge
        fanView.showLabels = true
        fanView.rowLimit = 3
        settleLayout()

        for (let index = 0; index < fanView.itemCount; index++) {
            const delegate = delegateAt(index)
            const row = findChild(delegate, "folderFanRowContent-" + index)
            const icon = findChild(delegate, "folderFanIcon-" + index)
            verify(row !== null, "Missing fan row " + index)
            verify(row.transform !== null && row.transform.length === 1,
                "A row must carry exactly one rotation")
            const rotation = row.transform[0]
            compare(rotation.angle, delegate.rowLean,
                "The row must turn with the lean of its entry")
            // The pivot is the centre of the icon, so the icon stays exactly on
            // the arc the reference captures measure.
            fuzzyCompare(rotation.origin.x, icon.x + fanView.iconSize / 2,
                "The row must turn around the centre of its icon")
            fuzzyCompare(rotation.origin.y, row.height / 2,
                "The row must turn around its own vertical centre")
            compare(icon.rotation, 0,
                "The icon must not lean on its own")
            // The name keeps its own pill, inside the row of its own entry and
            // beside its own icon, never inside a surface shared with the icon.
            const pill = findChild(delegate, "folderFanPill-" + index)
            verify(pill !== null, "Missing fan pill " + index)
            compare(pill.parent, row,
                "The pill must live in the row of its own entry")
            compare(findChild(delegate, "folderFanLabel-" + index).parent,
                pill, "The name must live in the pill that carries it")
            compare(icon.parent, row,
                "The icon must live in the row, outside the pill")
            verify(pill.x + pill.width <= icon.x - fanView.iconSpacing + 0.001,
                "The pill must end next to its own icon")
        }

        const leaning = delegateAt(0)
        verify(Math.abs(leaning.rowLean) > 0,
            "The far end of the arc must lean")
        const row = findChild(leaning, "folderFanRowContent-0")
        compare(row.transform[0].angle, leaning.rowLean)
        compare(findChild(leaning, "folderFanLabel-0").rotation, 0,
            "The name must lean with its row, not on its own")
    }

    // The pills of two neighbouring entries must never touch. Now that the pill
    // hugs its own text and the row pivots on its icon, that is the relation the
    // reference capture satisfies with its own air between rows, and it is what
    // the shared container used to break.
    function test_pillsNeverOverlapTheirNeighbour() {
        fanView.showLabels = true
        fanView.popupDirection = Qt.TopEdge
        fanView.rowLimit = 6

        const checkPills = function(context) {
            for (let index = 0; index + 1 < fanView.visibleRowCount; index++) {
                const lower = pillCorners(index)
                const upper = pillCorners(index + 1)
                verify(!rectanglesOverlap(lower, upper),
                    "Two neighbouring pills must never overlap (" + context
                        + ", rows " + index + "/" + (index + 1) + ")")
            }
        }

        // A name long enough to reach the cap is the worst case: the pill is as
        // wide as the fan allows, sits furthest from the pivot and leans as far
        // as the arc asks.
        fanView.apps = [
            {name: "AnExtremelyLongFolderNameThatCannotFitAtAll",
                icon: "folder"},
            {name: "Two", icon: "folder"},
            {name: "Three", icon: "folder"},
            {name: "Four", icon: "folder"},
            {name: "Five", icon: "folder"},
            {name: "Six", icon: "folder"}
        ]
        settleLayout()
        compare(fanView.desiredLabelWidth, fanView.maximumLabelWidth,
            "A long name must be capped by the fan")
        compare(fanView.rowHeight, fanView.preferredRowHeight,
            "The pitch must be the one the fan asks for")
        verify(fanView.contentHeight + fanView.rowAir
                <= fanView.preferredRowHeight,
            "The pitch must hold the content plus the air between two rows")
        checkPills("long name")

        // Short names must not change the lean of the arc, only the width of
        // their own pill.
        const cappedLean = Math.abs(delegateAt(0).rowLean)
        fanView.apps = [
            {name: "One", icon: "folder"},
            {name: "Two", icon: "folder"},
            {name: "Three", icon: "folder"},
            {name: "Four", icon: "folder"},
            {name: "Five", icon: "folder"},
            {name: "Six", icon: "folder"}
        ]
        settleLayout()
        verify(fanView.desiredLabelWidth < fanView.maximumLabelWidth,
            "A short name must not be capped")
        fuzzyCompare(Math.abs(delegateAt(0).rowLean), cappedLean,
            "A short name must not change the lean of the arc")
        checkPills("short name")
    }

    // Corners of a pill in list coordinates, so the check follows the same
    // transform the scene applies instead of a re-derived rectangle.
    function pillCorners(index) {
        const list = findChild(fanView, "folderFanList")
        const pill = findChild(delegateAt(index), "folderFanPill-" + index)
        const points = [[0, 0], [pill.width, 0],
            [pill.width, pill.height], [0, pill.height]]
        return points.map(function(point) {
            return pill.mapToItem(list.contentItem, point[0], point[1])
        })
    }

    // Separating axis test: two convex rectangles overlap only when every axis
    // of both silhouettes finds the projections intersecting.
    function rectanglesOverlap(first, second) {
        const axes = []
        const silhouettes = [first, second]
        for (let s = 0; s < silhouettes.length; s++) {
            for (let i = 0; i < 2; i++) {
                const from = silhouettes[s][i]
                const to = silhouettes[s][i + 1]
                const edgeX = to.x - from.x
                const edgeY = to.y - from.y
                const length = Math.sqrt(edgeX * edgeX + edgeY * edgeY)
                axes.push({x: -edgeY / length, y: edgeX / length})
            }
        }
        for (let a = 0; a < axes.length; a++) {
            const axis = axes[a]
            let lowestFirst = Infinity
            let highestFirst = -Infinity
            let lowestSecond = Infinity
            let highestSecond = -Infinity
            for (let p = 0; p < first.length; p++) {
                const projection = first[p].x * axis.x + first[p].y * axis.y
                lowestFirst = Math.min(lowestFirst, projection)
                highestFirst = Math.max(highestFirst, projection)
            }
            for (let q = 0; q < second.length; q++) {
                const projection = second[q].x * axis.x + second[q].y * axis.y
                lowestSecond = Math.min(lowestSecond, projection)
                highestSecond = Math.max(highestSecond, projection)
            }
            if (highestFirst < lowestSecond || highestSecond < lowestFirst) {
                return false
            }
        }
        return true
    }

    function test_longNamesKeepTheirSourceAndUseTheSharedEllipsis() {
        fanView.showLabels = true
        fanView.apps = [
            {name: "Documents of the whole project", icon: "folder"},
            {name: "Two", icon: "folder"},
            {name: "Three", icon: "folder"}
        ]
        settleLayout()

        const label = findChild(fanView, "folderFanLabel-0")
        verify(label !== null)
        compare(label.text, "Documents of the whole project")
        verify(label.overflowing,
            "A capped name must activate the shared resting ellipsis")
        verify(label.viewportWidth <= label.maximumRestingWidth,
            "A capped name must stay within the calculated ten-glyph ceiling")

        // The full name stays available to readers.
        const delegate = delegateAt(0)
        compare(delegate.Accessible.name, "Documents of the whole project")

        // A name that fits is shown complete, without any cut mark.
        fanView.apps = [
            {name: "One", icon: "folder"},
            {name: "Two", icon: "folder"},
            {name: "Three", icon: "folder"}
        ]
        settleLayout()
        compare(findChild(fanView, "folderFanLabel-0").text, "One")
    }

    function test_pointerAndContextActionsKeepTheSharedModel() {
        const list = findChild(fanView, "folderFanList")
        verify(list !== null)
        compare(fanView.visible, true)
        compare(list.visible, true)
        verify(list.height > 0)
        compare(list.currentIndex, 0)
        const first = list.currentItem
        verify(first !== null)
        const pointer = findChild(first, "folderFanPointer-0")
        verify(pointer !== null)
        verify(first.visible)
        verify(pointer.visible)
        verify(pointer.width > 0)
        verify(pointer.height > 0)
        mouseMove(pointer, pointer.width / 2, pointer.height / 2)
        tryCompare(pointer, "containsMouse", true)
        mouseClick(pointer, pointer.width / 2, pointer.height / 2,
            Qt.LeftButton)
        tryCompare(launchSpy, "count", 1)
        compare(launchSpy.signalArguments[0][0].name, "One")

        mouseClick(pointer, pointer.width / 2, pointer.height / 2,
            Qt.RightButton)
        tryCompare(contextSpy, "count", 1)
        compare(contextSpy.signalArguments[0][0].name, "One")
    }

    function test_keyboardNavigationContextAndDismissal() {
        const list = findChild(fanView, "folderFanList")
        verify(list !== null)
        compare(list.currentIndex, 0)
        const first = list.currentItem
        verify(first !== null)
        first.forceActiveFocus(Qt.TabFocusReason)
        tryCompare(first, "activeFocus", true)

        keyClick(Qt.Key_Down)
        tryCompare(list, "currentIndex", 1)
        const second = list.currentItem
        verify(second !== null)
        tryCompare(second, "activeFocus", true)

        keyClick(Qt.Key_Menu)
        compare(contextSpy.count, 1)
        compare(contextSpy.signalArguments[0][0].name, "Two documents")

        keyClick(Qt.Key_Escape)
        compare(closeSpy.count, 1)
    }

    function test_reducedMotionAndModelRecreationAreSettled() {
        fanView.motionEnabled = false
        fanView.revealProgress = 0
        const first = delegateAt(0)
        compare(first.opacity, 1)

        fanView.apps = []
        wait(0)
        compare(fanView.itemCount, 0)
        verify(findChild(fanView, "folderFanDelegate-0") === null)

        fanView.apps = [{name: "Restored", icon: "folder"}]
        const restored = delegateAt(0)
        compare(restored.opacity, 1)
    }

    // Every item leaves the row that faces the panel, which is the dock icon,
    // and unfolds into its own arc position. This is what makes the fan read as
    // one structure opening instead of a list appearing in place.
    function test_itemsUnfoldFromTheAnchorRow() {
        fanView.popupDirection = Qt.TopEdge
        fanView.motionEnabled = true
        fanView.revealProgress = 1
        settleLayout()

        // A settled fan separates its rows: the anchor row is the one facing the
        // panel and the far end is the row that ends further away.
        const settledSpread = rowOffsetY(2) - rowOffsetY(0)
        verify(rowOffsetY(0) < rowOffsetY(1),
            "The settled arc must separate the rows vertically")
        verify(rowOffsetY(1) < rowOffsetY(2),
            "The anchor row must be the one nearest the panel")
        verify(settledSpread > fanView.rowHeight,
            "A settled fan must separate its rows by more than one row")

        fanView.revealProgress = 0
        wait(0)

        // Every item starts on the anchor row, so a closed fan has no vertical
        // spread at all: the fan unfolds out of the dock icon instead of
        // appearing in place. The spread is measured at a single instant, which
        // is what makes it independent from the list viewport.
        const closedSpread = rowOffsetY(2) - rowOffsetY(0)
        fuzzyCompare(closedSpread, 0,
            "A closed fan must collapse every row onto the anchor row")

        // The far item travels the whole arc, not a one-row nudge, and the
        // anchor row is the point every other row travels towards.
        fuzzyCompare(fanView.revealOffsetYForItem(0),
            fanView.anchorRowY,
            "The far row must travel from the anchor row")
        fuzzyCompare(fanView.revealOffsetYForItem(fanView.anchorRowY), 0,
            "The unfold must not displace the anchor row")
        verify(Math.abs(fanView.revealOffsetYForItem(0))
            > fanView.rowHeight,
            "The far item must travel further than a single row")

        // The horizontal convergence is asserted within a fraction of the icon:
        // the arc offset cancelled by the unfold is the whole sag.
        verify(Math.abs(delegateAt(0).curveOffset)
                >= fanView.requestedCurveAmplitude - 0.001,
            "The far row must carry the whole arc offset")
        verify(Math.abs(iconOffsetX(0) - iconOffsetX(2))
            < fanView.iconSize * 0.2,
            "A closed fan must converge on the anchor column as well")

        // The reveal is a pure function of the shared progress: a half open fan
        // differs from both ends of the travel, and returning to the same
        // progress rebuilds the same state instead of drifting.
        const closedScale = delegateAt(0).revealScale
        fanView.revealProgress = 0.5
        wait(0)
        const halfwayScale = delegateAt(0).revealScale
        verify(halfwayScale > closedScale && halfwayScale < 1,
            "A half open fan must be travelling between both states")

        fanView.revealProgress = 0
        wait(0)
        fanView.revealProgress = 0.5
        wait(0)
        fuzzyCompare(delegateAt(0).revealScale, halfwayScale,
            "Reversing the reveal must continue from the current state")

        fanView.revealProgress = 1
        wait(0)
        fuzzyCompare(delegateAt(0).revealScale, 1,
            "A finished reveal must settle every item")
    }

    // The unfold is supported by a light scale and opacity: never from zero, and
    // always settling on the plain interactive appearance.
    function test_unfoldSupportStaysLightAndSettles() {
        fanView.motionEnabled = true
        fanView.revealProgress = 1
        settleLayout()

        fanView.revealProgress = 0
        wait(0)

        verify(fanView.revealStartScale >= 0.88
            && fanView.revealStartScale <= 0.94,
            "The unfold must not start from zero scale")
        // The highlight keeps its own scale, so the applied value is the product
        // of both: the unfold never replaces the interactive appearance.
        fuzzyCompare(delegateAt(0).revealScale, fanView.revealStartScale,
            "The delegate must expose the unfold scale")
        fuzzyCompare(findChild(fanView, "folderFanRowContent-0").scale,
            fanView.revealStartScale
                * findChild(fanView, "folderFanHighlight-0").visualScale,
            "The row must carry the unfold scale")
        fuzzyCompare(delegateAt(0).opacity, fanView.revealStartOpacity,
            "The unfold must start from a light opacity")
        verify(delegateAt(0).opacity > 0.5,
            "The unfold must stay readable while it travels")

        // The name lives inside the pill of the row that carries the unfold, so
        // the text cannot be left behind while its entry travels and scales.
        compare(findChild(fanView, "folderFanLabel-0").parent,
            findChild(fanView, "folderFanPill-0"),
            "The name must live in the pill of its own entry")
        compare(findChild(fanView, "folderFanIcon-0").parent,
            findChild(fanView, "folderFanRowContent-0"),
            "The icon must live in the row of its own entry")

        fanView.revealProgress = 1
        wait(0)
        fuzzyCompare(delegateAt(0).revealScale, 1,
            "A settled item must drop the unfold scale")
        // Hover may start or settle its own pulse while this test changes the
        // shared reveal progress. Compare against the live interactive scale,
        // not against a value captured before that independent animation.
        fuzzyCompare(findChild(fanView, "folderFanRowContent-0").scale,
            findChild(fanView, "folderFanHighlight-0").visualScale,
            "A settled item must keep only the interactive scale")
        fuzzyCompare(delegateAt(0).opacity, 1,
            "A settled item must be fully opaque")

        fanView.motionEnabled = false
        fanView.revealProgress = 0
        wait(0)
        fuzzyCompare(delegateAt(0).revealScale, 1,
            "Reduced motion must skip the unfold scale")
        compare(delegateAt(0).opacity, 1)
    }


    // The marked element of an entry is its icon, not the icon plus the name.
    function test_highlightMarksOnlyTheIcon() {
        fanView.popupDirection = Qt.TopEdge
        wait(0)

        const delegate = delegateAt(0)
        const highlight = findChild(delegate, "folderFanHighlight-0")
        const icon = findChild(delegate, "folderFanIcon-0")
        const label = findChild(delegate, "folderFanLabel-0")
        verify(highlight !== null && icon !== null && label !== null)

        fuzzyCompare(highlight.x, icon.x - fanView.contentPadding,
            "The highlight must start at the icon")
        fuzzyCompare(highlight.width,
            fanView.iconSize + fanView.contentPadding * 2,
            "The highlight must cover the icon and nothing else")
        // Side independent: the name never enters the highlighted surface, on
        // either the left or the right of the icon.
        if (label.x > icon.x) {
            verify(highlight.x + highlight.width <= label.x + 0.001,
                "The highlight must not overlap the name")
        } else {
            verify(highlight.x >= label.x + label.width - 0.001,
                "The highlight must not overlap the name")
        }
        fuzzyCompare(highlight.radius, fanView.highlightRadius,
            "The highlight must keep the derived text curvature")
    }

    // The fan is static by default: its effective model really holds only the
    // entries the band shows, so the omitted ones are not merely out of sight.
    function test_theStaticFanTruncatesItsModelAndOmitsTheRest() {
        fanView.scrollEnabled = false
        fanView.rowLimit = 8
        fanView.maximumContentHeight = 0
        fanView.folderPath = "~"
        fanView.apps = makeApps(12)
        wait(0)

        compare(fanView.itemCount, 12,
            "The full model must stay available to the fan")
        compare(fanView.visibleItemRows, 8)
        compare(fanView.overflowItemCount, 4)
        compare(fanView.displayedItemCount, 8)
        compare(fanView.displayedApps.length, 8)
        compare(fanView.omittedItemCount, 4)
        compare(fanView.effectiveScrollEnabled, false)

        const list = findChild(fanView, "folderFanList")
        compare(list.count, 8, "The list must consume the effective model")
        compare(list.interactive, false)
        verify(findChild(fanView, "folderFanDelegate-7") !== null)
        compare(findChild(fanView, "folderFanDelegate-8"), null,
            "An omitted entry must not create a reachable delegate")
        compare(list.contentY, -(fanView.leadingOverhang
            + fanView.bandStartOffset),
            "The static fan must still rest on its reserve")

        const label = findChild(fanView, "folderFanLocationLabel")
        verify(label !== null)
        compare(String(label.text), "4 more",
            "The closing row must count the entries really omitted")
        const action = findChild(fanView, "folderFanLocationAction")
        verify(String(action.Accessible.description).indexOf("4") >= 0,
            "The description must announce the same count: "
                + action.Accessible.description)
    }

    // A static fan must not offer an indirect route back to the omitted entries:
    // the model does not hold them and the view refuses every scroll gesture.
    function test_theStaticFanRefusesEveryScrollRoute() {
        fanView.scrollEnabled = false
        fanView.rowLimit = 6
        fanView.maximumContentHeight = 0
        fanView.folderPath = "~"
        fanView.apps = makeApps(10)
        wait(0)

        const list = findChild(fanView, "folderFanList")
        compare(list.count, 6)
        compare(list.interactive, false)
        const restY = list.contentY

        // Neither a flick nor a wheel gesture can move a view that refuses to
        // be scrolled.
        list.flick(0, -600)
        wait(0)
        compare(list.contentY, restY,
            "A static fan must not move when flicked")

        // The keyboard ring stays inside the effective model and never scrolls.
        fanView.focusFirstItem(Qt.OtherFocusReason)
        tryVerify(function() {
            return list.currentItem !== null
                && list.currentItem.activeFocus
        })
        for (let step = 0; step < 8; step++) {
            keyClick(Qt.Key_Down)
            wait(0)
            verify(list.currentIndex >= 0 && list.currentIndex < list.count,
                "The keyboard must stay inside the effective model: "
                    + list.currentIndex)
        }
        compare(list.contentY, restY,
            "The keyboard must not scroll a static fan")
    }

    // The preference brings the previous behaviour back: the whole model is
    // reachable again, so the closing row must stop claiming an omission.
    function test_theScrollingFanKeepsEveryEntryAndOmitsNone() {
        fanView.scrollEnabled = true
        fanView.rowLimit = 8
        fanView.maximumContentHeight = 0
        fanView.folderPath = "~"
        fanView.apps = makeApps(12)
        wait(0)

        const list = findChild(fanView, "folderFanList")
        compare(fanView.displayedItemCount, 12)
        compare(list.count, 12)
        compare(list.interactive, true)
        compare(fanView.overflowItemCount, 4)
        compare(fanView.omittedItemCount, 0,
            "A scrolling fan omits nothing")
        verify(list.contentHeight > list.height,
            "A scrolling fan must hold more content than its viewport")

        const label = findChild(fanView, "folderFanLocationLabel")
        verify(label !== null)
        compare(String(label.text), "Open",
            "Without an omission the row only announces the action: "
                + label.text)
        const action = findChild(fanView, "folderFanLocationAction")
        compare(action.Accessible.description, "",
            "A scrolling fan must not announce an omission")

        // The entries beyond the band really become reachable inside the popup.
        list.positionViewAtIndex(11, ListView.End)
        tryVerify(function() {
            return list.contentY > -(fanView.leadingOverhang
                + fanView.bandStartOffset)
        })
        tryVerify(function() {
            return findChild(fanView, "folderFanDelegate-11") !== null
        })
    }

    // A container with a manual list has no folder to open, so a truncated fan
    // would leave its remaining entries unreachable. The fallback keeps the
    // scrolling effective while the preference stays stored as requested.
    function test_aContainerWithoutAFolderNeverLosesEntries() {
        fanView.scrollEnabled = false
        fanView.rowLimit = 8
        fanView.maximumContentHeight = 0
        fanView.folderPath = ""
        fanView.apps = makeApps(12)
        wait(0)

        const list = findChild(fanView, "folderFanList")
        compare(fanView.hasLocationAction, false)
        compare(fanView.scrollEnabled, false,
            "The preference itself must stay stored as requested")
        compare(fanView.overflowItemCount, 4)
        compare(fanView.effectiveScrollEnabled, true,
            "Without a folder the fan must keep scrolling")
        compare(fanView.displayedItemCount, 12)
        compare(list.count, 12)
        compare(list.interactive, true)
        compare(fanView.omittedItemCount, 0)
        compare(findChild(fanView, "folderFanLocationAction"), null,
            "No folder must not invent a closing row")
        // The whole model stays reachable: the view can still travel to the
        // entry the band does not show at rest.
        list.positionViewAtIndex(11, ListView.End)
        tryVerify(function() {
            return findChild(fanView, "folderFanDelegate-11") !== null
        })
    }

    // Applying the preference with the popup open must truncate or restore the
    // model in place, keeping a valid focus instead of closing the popup.
    function test_togglingThePreferenceReactsInPlace() {
        fanView.rowLimit = 8
        fanView.maximumContentHeight = 0
        fanView.folderPath = "~"
        fanView.apps = makeApps(12)
        fanView.scrollEnabled = true
        wait(0)

        const list = findChild(fanView, "folderFanList")
        compare(list.count, 12)
        fanView.focusLastItem(Qt.OtherFocusReason)
        tryCompare(list, "currentIndex", 11)

        fanView.scrollEnabled = false
        tryCompare(list, "count", 8)
        compare(fanView.omittedItemCount, 4)
        compare(list.interactive, false)
        tryVerify(function() {
            return list.currentIndex >= 0 && list.currentIndex < 8
        }, 5000, "A removed row cannot keep the focus: " + list.currentIndex)
        compare(list.contentY, -(fanView.leadingOverhang
            + fanView.bandStartOffset),
            "Turning the scroll off must restore the resting position")

        fanView.scrollEnabled = true
        tryCompare(list, "count", 12)
        compare(fanView.omittedItemCount, 0)
        compare(list.interactive, true)
    }

    // Losing the folder while the popup is open must not strand the entries:
    // the fallback turns the effective scrolling back on, and restoring the
    // folder truncates the model again.
    function test_changingTheFolderReconcilesTheEffectiveModel() {
        fanView.scrollEnabled = false
        fanView.rowLimit = 8
        fanView.maximumContentHeight = 0
        fanView.folderPath = "~"
        fanView.apps = makeApps(12)
        wait(0)

        const list = findChild(fanView, "folderFanList")
        compare(list.count, 8)
        compare(fanView.effectiveScrollEnabled, false)

        fanView.folderPath = ""
        tryCompare(list, "count", 12)
        compare(fanView.effectiveScrollEnabled, true,
            "Losing the folder must keep every entry reachable")
        compare(fanView.omittedItemCount, 0)
        tryVerify(function() {
            return findChild(fanView, "folderFanLocationAction") === null
        })

        fanView.folderPath = "~"
        tryCompare(list, "count", 8)
        compare(fanView.omittedItemCount, 4)
        compare(fanView.effectiveScrollEnabled, false)
    }

    // Degenerate models: an empty container and one that fits must never report
    // an omission, and the row limit decides the truncation in every panel
    // orientation.
    function test_theTruncationFollowsTheLimitAndTheModel() {        fanView.scrollEnabled = false
        fanView.maximumContentHeight = 0
        fanView.folderPath = "~"

        fanView.apps = []
        fanView.rowLimit = 8
        wait(0)
        compare(fanView.displayedItemCount, 0)
        compare(fanView.omittedItemCount, 0)
        const label = findChild(fanView, "folderFanLocationLabel")
        verify(label !== null)
        compare(String(label.text), "Open",
            "An empty container must not announce an omission")

        fanView.apps = makeApps(3)
        wait(0)
        compare(fanView.displayedItemCount, 3)
        compare(fanView.overflowItemCount, 0)
        compare(fanView.omittedItemCount, 0)

        fanView.apps = makeApps(5)
        fanView.rowLimit = 1
        wait(0)
        compare(fanView.visibleItemRows, 1)
        compare(fanView.displayedItemCount, 1)
        compare(fanView.omittedItemCount, 4)

        const directions = [Qt.TopEdge, Qt.BottomEdge, Qt.LeftEdge,
            Qt.RightEdge]
        for (let index = 0; index < directions.length; index++) {
            fanView.popupDirection = directions[index]
            fanView.rowLimit = 8
            wait(0)
            compare(fanView.displayedItemCount, 5,
                "A model that fits must not be truncated on the panel "
                    + directions[index])
            compare(fanView.omittedItemCount, 0)
            const action = findChild(fanView, "folderFanLocationAction")
            verify(action !== null,
                "The closing row must survive the orientation change")
        }
    }
}
