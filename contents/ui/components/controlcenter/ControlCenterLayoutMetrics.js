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
