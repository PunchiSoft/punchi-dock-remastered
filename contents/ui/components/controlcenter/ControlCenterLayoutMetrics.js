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
