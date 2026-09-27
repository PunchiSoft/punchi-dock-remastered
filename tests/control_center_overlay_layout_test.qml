// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtTest
import "../contents/ui/components/controlcenter/ControlCenterLayoutMetrics.js" as LayoutMetrics
import "../contents/ui/components/controlcenter/ControlCenterRevealMetrics.js" as RevealMetrics
import "../contents/ui/components/controlcenter" as ControlCenter

TestCase {
    id: testCase

    name: "ControlCenterOverlayLayout"

    function init() {
        failOnWarning(/.?/)
    }

    function test_availableGeometryUsesKUnits() {
        const gridUnit = 18
        compare(LayoutMetrics.edgeMargin(gridUnit), 54)
        compare(LayoutMetrics.minimumRailWidth(gridUnit), 540)
        compare(LayoutMetrics.maximumRailWidth(gridUnit), 756)
        compare(LayoutMetrics.targetRailWidth(1920), 640)
        compare(LayoutMetrics.availableWidth(1920, gridUnit), 640)
        compare(LayoutMetrics.availableWidth(1440, gridUnit), 540)
        compare(LayoutMetrics.availableHeight(900, gridUnit), 792)

        compare(LayoutMetrics.availableWidth(760, gridUnit), 540)
        compare(LayoutMetrics.availableWidth(500, gridUnit), 392)
        compare(LayoutMetrics.availableHeight(640, gridUnit), 532)
        compare(LayoutMetrics.availableWidth(80, gridUnit), 0)
        compare(LayoutMetrics.availableHeight(80, gridUnit), 0)
    }

    function test_quickActionCapacityFollowsWidth() {
        const gridUnit = 18
        const cell = gridUnit * 3
        const spacing = gridUnit / 2
        const maximumSpacing = gridUnit * 2

        // Without a real width there is no capacity to report.
        compare(LayoutMetrics.quickActionCapacity(0, cell, spacing, 4, 8), 0)
        // Narrow strips keep the minimum so the row never loses its function.
        compare(LayoutMetrics.quickActionCapacity(200, cell, spacing, 4, 8), 4)
        // A floating rail at its minimum width already fits the whole row.
        compare(LayoutMetrics.quickActionCapacity(540, cell, spacing, 4, 8), 8)
        compare(LayoutMetrics.quickActionCapacity(756, cell, spacing, 4, 8), 8)
        // Wider surfaces stay capped instead of growing without limit.
        compare(LayoutMetrics.quickActionCapacity(1800, cell, spacing, 4, 8), 8)

        // The cells spread evenly and never end up below the theme spacing.
        fuzzyCompare(LayoutMetrics.quickActionSpacing(540, cell, 8, spacing,
            maximumSpacing), 108 / 7, 0.01)
        compare(LayoutMetrics.quickActionSpacing(200, cell, 4, spacing,
            maximumSpacing), spacing)
        // Above the cap the caller centers the group instead of stretching it.
        compare(LayoutMetrics.quickActionSpacing(1800, cell, 8, spacing,
            maximumSpacing), maximumSpacing)
        compare(LayoutMetrics.quickActionSpacing(0, cell, 1, spacing,
            maximumSpacing), spacing)
    }

    function test_primaryTileRowMorphsIntoOneTitle() {
        const rowWidth = 640
        const gap = 8
        const tileHeight = 90
        const resting = LayoutMetrics.restingTileWidth(rowWidth, gap)

        // Resting state: two tiles share the row with the gap between them.
        compare(resting, (rowWidth - gap) / 2)
        compare(LayoutMetrics.primaryTileWidth(rowWidth, gap, false, 0), resting)
        fuzzyCompare(LayoutMetrics.leavingTileX(rowWidth, gap, false, 0),
            resting + gap, 0.001)

        // Open: the survivor holds the whole row and the neighbour is clear of it,
        // so the tile that stays reads as the title of the section below.
        fuzzyCompare(LayoutMetrics.primaryTileWidth(rowWidth, gap, false, 1),
            rowWidth, 0.001)
        verify(LayoutMetrics.leavingTileX(rowWidth, gap, false, 1) >= rowWidth)

        // In between, the two tiles stay adjacent: the distance the survivor grows
        // is the distance the neighbour travels, so the row never shows a hole and
        // the tiles never overlap while it becomes a single tile.
        for (let step = 0; step <= 20; step++) {
            const progress = step / 20
            const survivorWidth = LayoutMetrics.primaryTileWidth(rowWidth, gap,
                false, progress)
            fuzzyCompare(LayoutMetrics.leavingTileX(rowWidth, gap, false,
                progress), survivorWidth + gap, 0.001)
            verify(survivorWidth >= resting)
            verify(survivorWidth <= rowWidth)
        }

        // Progress outside the interval is clamped instead of extrapolated, and an
        // unusable one falls back to the resting arrangement.
        compare(LayoutMetrics.primaryTileWidth(rowWidth, gap, false, -1), resting)
        fuzzyCompare(LayoutMetrics.primaryTileWidth(rowWidth, gap, false, 2),
            rowWidth, 0.001)
        compare(LayoutMetrics.primaryTileWidth(rowWidth, gap, false, NaN), resting)

        // Without a row there is nothing to divide between the tiles.
        compare(LayoutMetrics.primaryTileWidth(0, gap, false, 0.5), 0)
        compare(LayoutMetrics.leavingTileX(0, gap, false, 0.5), 0)
        compare(LayoutMetrics.primaryRowHeight(0, gap, true, 0.5), 0)

        // Tiles sharing the row keep it at the height of one tile.
        compare(LayoutMetrics.primaryRowHeight(tileHeight, gap, false, 0.5),
            tileHeight)
        // Stacked, the survivor already owns the whole width and the row gives back
        // the height of the tile that leaves.
        compare(LayoutMetrics.primaryTileWidth(rowWidth, gap, true, 0.5), rowWidth)
        compare(LayoutMetrics.primaryRowHeight(tileHeight, gap, true, 0),
            tileHeight * 2 + gap)
        compare(LayoutMetrics.primaryRowHeight(tileHeight, gap, true, 0.5),
            tileHeight + (tileHeight + gap) / 2)
        compare(LayoutMetrics.primaryRowHeight(tileHeight, gap, true, 1), tileHeight)
        verify(LayoutMetrics.leavingTileX(rowWidth, gap, true, 1) >= rowWidth)
    }

    Component {
        id: floatingGeometryComponent

        ControlCenter.ControlCenterFloatingGeometry {}
    }

    function test_floatingGeometryMatchesFullscreenRail() {
        const geometry = createTemporaryObject(
            floatingGeometryComponent, testCase, {
                "screenGeometry": Qt.rect(0, 0, 1920, 1080),
                "availableScreenRect": Qt.rect(0, 0, 1920, 1080),
                "gridUnit": 18
            })
        verify(geometry !== null)
        compare(geometry.contentWidth, 640)
        compare(geometry.contentHeight, 972)
        compare(geometry.positionFor(
            geometry.contentWidth, geometry.contentHeight),
            Qt.point(1226, 54))
    }

    function test_floatingGeometryUsesActiveScreenAndAvailableArea() {
        const geometry = createTemporaryObject(
            floatingGeometryComponent, testCase, {
                "screenGeometry": Qt.rect(1920, 0, 2560, 1440),
                "availableScreenRect": Qt.rect(0, 40, 2560, 1400),
                "gridUnit": 18
            })
        verify(geometry !== null)
        compare(geometry.contentWidth, 756)
        compare(geometry.contentHeight, 1332)
        compare(geometry.positionFor(
            geometry.contentWidth, geometry.contentHeight),
            Qt.point(3670, 54))
    }

    function test_verticalMarginsUseFullScreenAndFollowGridUnits() {
        const geometry = createTemporaryObject(
            floatingGeometryComponent, testCase, {
                "screenGeometry": Qt.rect(1920, -1080, 1920, 1080),
                "availableScreenRect": Qt.rect(0, 40, 1920, 900),
                "gridUnit": 18
            })
        verify(geometry !== null)
        for (const unit of [18, 24, 30]) {
            geometry.gridUnit = unit
            const position = geometry.positionFor(
                geometry.contentWidth, geometry.contentHeight)
            compare(position.y - geometry.screenGeometry.y, unit * 3)
            compare(geometry.screenGeometry.y + geometry.screenGeometry.height
                - position.y - geometry.contentHeight, unit * 3)
        }
        const nativeHeight = geometry.contentHeight + 10
        const nativePosition = geometry.positionFor(geometry.contentWidth, nativeHeight)
        compare(nativePosition.y - geometry.screenGeometry.y,
            geometry.screenGeometry.y + geometry.screenGeometry.height
                - nativePosition.y - nativeHeight)
    }

    function test_floatingGeometryShrinksOnlyWhenNecessary() {
        const geometry = createTemporaryObject(
            floatingGeometryComponent, testCase, {
                "screenGeometry": Qt.rect(0, 0, 500, 640),
                "availableScreenRect": Qt.rect(0, 0, 500, 640),
                "gridUnit": 18
            })
        verify(geometry !== null)
        compare(geometry.contentWidth, 392)
        compare(geometry.contentHeight, 532)
        compare(geometry.positionFor(
            geometry.contentWidth, geometry.contentHeight),
            Qt.point(54, 54))
    }

    function test_floatingSurfaceRevealsFromTheAnchoredCorner() {
        // Hidden at the start, fully visible before the motion ends, so the eye
        // follows a solid panel instead of a semi-transparent one.
        compare(RevealMetrics.revealOpacity(0), 0)
        fuzzyCompare(RevealMetrics.revealOpacity(0.4), 0.64, 0.0001)
        compare(RevealMetrics.revealOpacity(0.625), 1)
        compare(RevealMetrics.revealOpacity(1), 1)
        compare(RevealMetrics.revealOpacity(2), 1)
        // An unusable progress is read as a settled surface: never fade a visible
        // panel out by accident.
        compare(RevealMetrics.revealOpacity(NaN), 1)

        // The panel grows out of its corner and lands at its exact final size.
        fuzzyCompare(RevealMetrics.revealScale(0, 0.06), 0.94, 0.0001)
        fuzzyCompare(RevealMetrics.revealScale(0.5, 0.06), 0.97, 0.0001)
        compare(RevealMetrics.revealScale(1, 0.06), 1)
        // A delta outside the usable range cannot shrink the panel further.
        fuzzyCompare(RevealMetrics.revealScale(0, 0.5), 0.75, 0.0001)
        compare(RevealMetrics.revealScale(0, -1), 1)
        compare(RevealMetrics.revealScale(0, NaN), 1)
        compare(RevealMetrics.revealScale(NaN, 0.06), 1)

        // The full-screen rail keeps its travel and ends flush at zero.
        compare(RevealMetrics.revealTravel(0, 120), 120)
        compare(RevealMetrics.revealTravel(0.5, 120), 60)
        compare(RevealMetrics.revealTravel(1, 120), 0)
        compare(RevealMetrics.revealTravel(NaN, 120), 0)
        compare(RevealMetrics.revealTravel(0, NaN), 0)
    }
}
