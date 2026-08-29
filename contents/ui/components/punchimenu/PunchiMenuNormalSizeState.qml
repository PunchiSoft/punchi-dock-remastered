// SPDX-License-Identifier: GPL-2.0-or-later

import QtQml

QtObject {
    id: root

    property real configuredWidthPercent: 55
    property real configuredHeightPercent: 65
    property real screenWidth: 0
    property real screenHeight: 0
    property real availableWidth: 0
    property real availableHeight: 0
    property real screenMargin: 0
    property real contentMargin: 0
    property real minimumContentWidth: 1
    property real minimumContentHeight: 1

    property int appliedContentWidth: 1
    property int appliedContentHeight: 1

    function finitePositive(value, fallback) {
        const numericValue = Number(value)
        return Number.isFinite(numericValue) && numericValue > 0
            ? numericValue : fallback
    }

    function normalizedPercent(value, fallback) {
        const numericValue = Number(value)
        return Number.isFinite(numericValue)
            ? Math.max(1, Math.min(100, numericValue))
            : fallback
    }

    function contentDimension(screenDimension, availableDimension,
            minimumDimension, requestedPercent) {
        const safeMinimum = Math.max(1, Math.round(
            root.finitePositive(minimumDimension, 1)))
        const reservedSpace = Math.max(0, Number(root.screenMargin) || 0)
            + Math.max(0, Number(root.contentMargin) || 0) * 2
        const fallbackDimension = safeMinimum + reservedSpace
        const activeScreenDimension = root.finitePositive(
            screenDimension, root.finitePositive(
                availableDimension, fallbackDimension))
        const reportedAvailableDimension = root.finitePositive(
            availableDimension, activeScreenDimension)
        const boundedAvailableDimension = Math.min(
            activeScreenDimension, reportedAvailableDimension)
        const maximumContentDimension = Math.max(1,
            Math.round(boundedAvailableDimension - reservedSpace))
        const boundedMinimum = Math.min(
            safeMinimum, maximumContentDimension)
        const targetDimension = Math.round(activeScreenDimension
            * root.normalizedPercent(requestedPercent, 50) / 100)
        return Math.max(boundedMinimum,
            Math.min(maximumContentDimension, targetDimension))
    }

    function applyConfiguredDimensions() {
        root.appliedContentWidth = root.contentDimension(
            root.screenWidth, root.availableWidth,
            root.minimumContentWidth, root.configuredWidthPercent)
        root.appliedContentHeight = root.contentDimension(
            root.screenHeight, root.availableHeight,
            root.minimumContentHeight, root.configuredHeightPercent)
    }
}
