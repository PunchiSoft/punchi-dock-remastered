// SPDX-License-Identifier: GPL-2.0-or-later

.pragma library

function normalizedGridUnit(gridUnit) {
    const value = Number(gridUnit)
    return Number.isFinite(value) && value > 0 ? value : 0
}

function edgeMargin(gridUnit) {
    return normalizedGridUnit(gridUnit) * 3
}

function minimumRailWidth(gridUnit) {
    return normalizedGridUnit(gridUnit) * 30
}

function maximumRailWidth(gridUnit) {
    return normalizedGridUnit(gridUnit) * 42
}

function targetRailWidth(containerWidth) {
    const width = Math.max(0, Number(containerWidth) || 0)
    return width / 3
}

function availableWidth(containerWidth, gridUnit) {
    const margin = edgeMargin(gridUnit)
    const width = Math.max(0, Number(containerWidth) || 0)
    const usableWidth = Math.max(0, width - margin * 2)
    const minimumWidth = minimumRailWidth(gridUnit)
    const maximumWidth = maximumRailWidth(gridUnit)
    if (usableWidth === 0 || maximumWidth === 0) {
        return 0
    }
    const preferredWidth = Math.max(minimumWidth,
        Math.min(targetRailWidth(width), maximumWidth))
    return Math.min(usableWidth, preferredWidth)
}

function availableHeight(containerHeight, gridUnit) {
    const margin = edgeMargin(gridUnit)
    const height = Math.max(0, Number(containerHeight) || 0)
    return Math.max(0, height - margin * 2)
}

// Quick-action strip capacity.
//
// The strip keeps its non-removable controls at a fixed size and fills the rest
// of its width with empty positions, so how many controls it shows depends on the
// room it really has. The caller passes the theme metrics so this module does not
// duplicate them.

function quickActionCapacity(availableWidth, cellSize, minimumSpacing,
    minimumCount, maximumCount) {
    const width = Math.max(0, Number(availableWidth) || 0)
    const cell = Math.max(0, Number(cellSize) || 0)
    const spacing = Math.max(0, Number(minimumSpacing) || 0)
    const minimum = Math.max(1, Math.round(Number(minimumCount) || 0))
    const maximum = Math.max(minimum, Math.round(Number(maximumCount) || 0))
    if (cell === 0 || width === 0) {
        return 0
    }
    const rawCount = Math.floor((width + spacing) / (cell + spacing))
    return Math.max(minimum, Math.min(maximum, rawCount))
}

// Spacing that spreads the cells evenly over the width without ever going below
// the theme spacing or above the caller's cap; when the cap applies, the caller
// centers the group instead of stretching the gaps.
function quickActionSpacing(availableWidth, cellSize, count, minimumSpacing,
    maximumSpacing) {
    const width = Math.max(0, Number(availableWidth) || 0)
    const cell = Math.max(0, Number(cellSize) || 0)
    const items = Math.max(1, Math.round(Number(count) || 0))
    const minimum = Math.max(0, Number(minimumSpacing) || 0)
    const maximum = Math.max(minimum, Number(maximumSpacing) || minimum)
    if (items < 2 || cell === 0) {
        return minimum
    }
    const evenSpacing = (width - items * cell) / (items - 1)
    return Math.max(minimum, Math.min(maximum, evenSpacing))
}

// Primary tile row of the home page.
//
// The row holds the tile that expands a section next to the tile it cannot share
// the open state with. When the section opens, the neighbour leaves the row
// through its right edge and the surviving tile takes over the whole width, so it
// reads as the title of the section below instead of a control next to another
// one.
//
// Both motions are pure functions of the section reveal progress, with no animator
// and no timing of their own: the section owns the animation, and these follow it
// in both directions, at any speed and through an interruption. The distance the
// survivor grows and the distance the neighbour travels are the same, so the two
// tiles stay adjacent while the row turns into a single tile: one continuous
// deformation instead of two motions crossing each other. The tile that leaves
// ends exactly one gap beyond the row, which is outside the frame.

function clampProgress(progress) {
    const value = Number(progress)
    if (!Number.isFinite(value)) {
        return 0
    }
    return Math.max(0, Math.min(1, value))
}

function restingTileWidth(rowWidth, spacing) {
    const width = Math.max(0, Number(rowWidth) || 0)
    const gap = Math.max(0, Number(spacing) || 0)
    return Math.max(0, (width - gap) / 2)
}

// Width of the tile that outlives the section it opens. In the stacked
// arrangement it already owns the whole row, so only the progress of a row that
// holds two tiles changes its width.
function primaryTileWidth(rowWidth, spacing, stacked, progress) {
    const width = Math.max(0, Number(rowWidth) || 0)
    if (width === 0 || stacked) {
        return width
    }
    const gap = Math.max(0, Number(spacing) || 0)
    const restingWidth = restingTileWidth(width, gap)
    return restingWidth + clampProgress(progress) * (restingWidth + gap)
}

// Left edge of the tile that leaves the row with the section it does not open.
// It travels the same distance the surviving tile grows, so the two tiles never
// overlap and never leave a hole between them, and it ends clear of the row.
function leavingTileX(rowWidth, spacing, stacked, progress) {
    const width = Math.max(0, Number(rowWidth) || 0)
    if (width === 0) {
        return 0
    }
    const gap = Math.max(0, Number(spacing) || 0)
    const travelled = clampProgress(progress)
    if (stacked) {
        return travelled * (width + gap)
    }
    const restingWidth = restingTileWidth(width, gap)
    return restingWidth + gap + travelled * (restingWidth + gap)
}

// Height of the row. Two tiles stacked lose the height of the one that leaves, so
// the open section does not begin under a hole; when the tiles share the row, its
// height never depends on how many of them are still in it.
function primaryRowHeight(tileHeight, spacing, stacked, progress) {
    const height = Math.max(0, Number(tileHeight) || 0)
    if (height === 0 || !stacked) {
        return height
    }
    const gap = Math.max(0, Number(spacing) || 0)
    return height + (1 - clampProgress(progress)) * (height + gap)
}
