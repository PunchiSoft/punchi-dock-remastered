import QtQuick

QtObject {
    id: root

    property real requestedScale: 1.0
    property real minimumScale: 0.75
    property real maximumScale: 1.5
    property real baseSize: 0
    property real minimumSize: 0
    property real availableWidth: -1
    property real availableHeight: -1

    readonly property real safeScale: {
        const requestedValue = Number(requestedScale)
        const minimumValue = Number.isFinite(Number(minimumScale))
            ? Math.max(0, Number(minimumScale)) : 0
        const maximumValue = Number.isFinite(Number(maximumScale))
            ? Math.max(minimumValue, Number(maximumScale)) : minimumValue
        return Number.isFinite(requestedValue)
            ? Math.max(minimumValue, Math.min(maximumValue, requestedValue))
            : Math.max(minimumValue, Math.min(maximumValue, 1.0))
    }
    readonly property real desiredSize: {
        const requestedBase = Number(baseSize)
        const requestedMinimum = Number(minimumSize)
        const safeBase = Number.isFinite(requestedBase)
            ? Math.max(0, requestedBase) : 0
        const safeMinimum = Number.isFinite(requestedMinimum)
            ? Math.max(0, requestedMinimum) : 0
        return Math.max(safeMinimum, safeBase * safeScale)
    }
    readonly property int effectiveSize: {
        const requestedWidth = Number(availableWidth)
        const requestedHeight = Number(availableHeight)
        const widthLimit = Number.isFinite(requestedWidth)
            && requestedWidth >= 0 ? requestedWidth : Number.POSITIVE_INFINITY
        const heightLimit = Number.isFinite(requestedHeight)
            && requestedHeight >= 0 ? requestedHeight : Number.POSITIVE_INFINITY
        const availableSize = Math.min(widthLimit, heightLimit)
        if (availableSize <= 0) {
            return 0
        }
        return Math.round(Number.isFinite(availableSize)
            ? Math.min(desiredSize, availableSize) : desiredSize)
    }
}
