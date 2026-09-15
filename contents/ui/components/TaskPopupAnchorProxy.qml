import QtQuick

Item {
    id: root

    property rect sourceGeometry: Qt.rect(0, 0, 0, 0)
    property real popupWidth: 0
    property real popupHeight: 0
    property bool popupOnHorizontalEdge: true

    readonly property PopupAnchorMetrics anchorMetrics: PopupAnchorMetrics {}

    readonly property bool geometryReady: width > 0 && height > 0

    enabled: false
    opacity: 0
    visible: geometryReady
    z: -1

    onPopupWidthChanged: root.applyGeometry()
    onPopupHeightChanged: root.applyGeometry()
    onPopupOnHorizontalEdgeChanged: root.applyGeometry()

    function applyGeometry() {
        if (sourceGeometry.width <= 0 || sourceGeometry.height <= 0) {
            return false
        }

        const effectiveWidth = popupOnHorizontalEdge
            ? root.anchorMetrics.centeredExtent(sourceGeometry.width, popupWidth)
            : sourceGeometry.width
        const effectiveHeight = popupOnHorizontalEdge
            ? sourceGeometry.height
            : root.anchorMetrics.centeredExtent(sourceGeometry.height, popupHeight)

        root.x = sourceGeometry.x
            - (effectiveWidth - sourceGeometry.width) / 2
        root.y = sourceGeometry.y
            - (effectiveHeight - sourceGeometry.height) / 2
        root.width = effectiveWidth
        root.height = effectiveHeight
        return true
    }

    function configureForPopup(width, height, horizontalEdge) {
        root.popupWidth = Math.max(0, Number(width) || 0)
        root.popupHeight = Math.max(0, Number(height) || 0)
        root.popupOnHorizontalEdge = horizontalEdge !== false
        return root.applyGeometry()
    }

    function geometryFor(sourceItem) {
        if (!sourceItem || !root.parent
                || typeof sourceItem.mapToItem !== "function") {
            return Qt.rect(0, 0, 0, 0)
        }

        const sourceWidth = Number(sourceItem.width)
        const sourceHeight = Number(sourceItem.height)
        if (!Number.isFinite(sourceWidth) || sourceWidth <= 0
                || !Number.isFinite(sourceHeight) || sourceHeight <= 0) {
            return Qt.rect(0, 0, 0, 0)
        }

        let mappedGeometry
        try {
            mappedGeometry = sourceItem.mapToItem(root.parent,
                Qt.rect(0, 0, sourceWidth, sourceHeight))
        } catch (error) {
            return Qt.rect(0, 0, 0, 0)
        }

        const mappedX = Number(mappedGeometry.x)
        const mappedY = Number(mappedGeometry.y)
        const mappedWidth = Number(mappedGeometry.width)
        const mappedHeight = Number(mappedGeometry.height)
        if (!Number.isFinite(mappedX) || !Number.isFinite(mappedY)
                || !Number.isFinite(mappedWidth) || mappedWidth <= 0
                || !Number.isFinite(mappedHeight) || mappedHeight <= 0) {
            return Qt.rect(0, 0, 0, 0)
        }

        return Qt.rect(mappedX, mappedY, mappedWidth, mappedHeight)
    }

    function captureGeometry(geometry) {
        const mappedX = Number(geometry ? geometry.x : Number.NaN)
        const mappedY = Number(geometry ? geometry.y : Number.NaN)
        const mappedWidth = Number(geometry ? geometry.width : Number.NaN)
        const mappedHeight = Number(geometry ? geometry.height : Number.NaN)
        if (!Number.isFinite(mappedX) || !Number.isFinite(mappedY)
                || !Number.isFinite(mappedWidth) || mappedWidth <= 0
                || !Number.isFinite(mappedHeight) || mappedHeight <= 0) {
            return false
        }

        root.sourceGeometry = Qt.rect(mappedX, mappedY,
            mappedWidth, mappedHeight)
        return root.applyGeometry()
    }

    function capture(sourceItem) {
        return root.captureGeometry(root.geometryFor(sourceItem))
    }

    function clear() {
        root.sourceGeometry = Qt.rect(0, 0, 0, 0)
        root.popupWidth = 0
        root.popupHeight = 0
        root.x = 0
        root.y = 0
        root.width = 0
        root.height = 0
    }
}
