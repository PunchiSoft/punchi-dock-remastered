// SPDX-License-Identifier: GPL-2.0-or-later

import QtQml
import "ControlCenterLayoutMetrics.js" as LayoutMetrics

QtObject {
    id: root

    property rect screenGeometry: Qt.rect(0, 0, 1, 1)
    property rect availableScreenRect: Qt.rect(0, 0, 1, 1)
    property real gridUnit: 0

    readonly property real edgeMargin: LayoutMetrics.edgeMargin(root.gridUnit)
    readonly property rect absoluteAvailableRect:
        root.resolveAbsoluteAvailableRect()
    readonly property real referenceWidth: root.validRect(root.screenGeometry)
        ? Number(root.screenGeometry.width)
        : Number(root.absoluteAvailableRect.width)
    readonly property real referenceHeight: root.validRect(root.screenGeometry)
        ? Number(root.screenGeometry.height)
        : Number(root.absoluteAvailableRect.height)
    readonly property int contentWidth: root.boundedDimension(
        LayoutMetrics.availableWidth(root.referenceWidth, root.gridUnit),
        root.absoluteAvailableRect.width)
    readonly property int contentHeight: root.boundedDimension(
        LayoutMetrics.availableHeight(root.referenceHeight, root.gridUnit),
        root.absoluteAvailableRect.height)

    function finiteNumber(value, fallback) {
        const numericValue = Number(value)
        return Number.isFinite(numericValue) ? numericValue : fallback
    }

    function validRect(rectangle) {
        return rectangle
            && Number.isFinite(Number(rectangle.x))
            && Number.isFinite(Number(rectangle.y))
            && Number.isFinite(Number(rectangle.width))
            && Number.isFinite(Number(rectangle.height))
            && Number(rectangle.width) > 0
            && Number(rectangle.height) > 0
    }

    function resolveAbsoluteAvailableRect() {
        const available = root.availableScreenRect
        const screen = root.screenGeometry
        if (root.validRect(available) && root.validRect(screen)) {
            return Qt.rect(
                root.finiteNumber(screen.x, 0)
                    + root.finiteNumber(available.x, 0),
                root.finiteNumber(screen.y, 0)
                    + root.finiteNumber(available.y, 0),
                root.finiteNumber(available.width, 1),
                root.finiteNumber(available.height, 1))
        }
        if (root.validRect(screen)) {
            return screen
        }
        return root.validRect(available)
            ? available : Qt.rect(0, 0, 1, 1)
    }

    function boundedDimension(preferredDimension, availableDimension) {
        const margin = Math.max(0, root.finiteNumber(root.edgeMargin, 0))
        const maximum = Math.max(1, Math.round(
            root.finiteNumber(availableDimension, 1) - margin * 2))
        const preferred = Math.max(1, Math.round(
            root.finiteNumber(preferredDimension, maximum)))
        return Math.min(preferred, maximum)
    }

    function positionFor(windowWidth, windowHeight) {
        const available = root.absoluteAvailableRect
        const margin = Math.max(0, root.finiteNumber(root.edgeMargin, 0))
        const width = Math.max(1, root.finiteNumber(windowWidth,
            root.contentWidth))
        const height = Math.max(1, root.finiteNumber(windowHeight,
            root.contentHeight))
        const minimumX = available.x
        const minimumY = available.y
        const maximumX = available.x + available.width - width
        const maximumY = available.y + available.height - height
        const targetX = available.x + available.width - margin - width
        const targetY = available.y + margin
        return Qt.point(
            Math.round(Math.max(minimumX, Math.min(maximumX, targetX))),
            Math.round(Math.max(minimumY, Math.min(maximumY, targetY))))
    }
}
