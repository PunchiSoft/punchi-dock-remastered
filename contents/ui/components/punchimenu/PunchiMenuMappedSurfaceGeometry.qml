import QtQuick

QtObject {
    id: root

    required property Item targetItem
    required property Item surfaceItem
    required property Item backgroundItem
    property real translationX: 0
    property real translationY: 0
    property real leftInset: 0
    property real topInset: 0
    property real rightInset: 0
    property real bottomInset: 0

    readonly property point backgroundMaskOffset: {
        // mapToItem() does not invalidate a binding when an ancestor transform
        // changes. Read every transformation input explicitly so the mask
        // reaches the final window-client origin after the reveal animation.
        const geometryValues = [
            root.targetItem.x, root.targetItem.y,
            root.surfaceItem.x, root.surfaceItem.y,
            root.surfaceItem.width, root.surfaceItem.height,
            root.surfaceItem.scale, root.surfaceItem.transformOrigin,
            root.translationX, root.translationY,
            root.backgroundItem.x, root.backgroundItem.y,
            root.backgroundItem.width, root.backgroundItem.height
        ]
        if (geometryValues.some(value => !Number.isFinite(value))) {
            return Qt.point(0, 0)
        }
        const scenePosition = root.backgroundItem.mapToItem(
            null, Qt.point(0, 0))
        return Qt.point(Math.round(scenePosition.x),
            Math.round(scenePosition.y))
    }

    readonly property rect effectiveBackdropGeometry: {
        // The modal veil is a rectangle, unlike the exact blur QRegion, but
        // both start from the same effective themed surface delimited by inset.
        const geometryValues = [
            root.targetItem.x, root.targetItem.y,
            root.targetItem.width, root.targetItem.height,
            root.surfaceItem.x, root.surfaceItem.y,
            root.surfaceItem.width, root.surfaceItem.height,
            root.surfaceItem.scale, root.surfaceItem.transformOrigin,
            root.translationX, root.translationY,
            root.backgroundItem.x, root.backgroundItem.y,
            root.backgroundItem.width, root.backgroundItem.height,
            root.leftInset, root.topInset,
            root.rightInset, root.bottomInset
        ]
        const hasValidGeometry = geometryValues.every(
            value => Number.isFinite(value))
        const hasValidInsets = hasValidGeometry
            && root.leftInset >= 0 && root.topInset >= 0
            && root.rightInset >= 0 && root.bottomInset >= 0
            && root.leftInset + root.rightInset < root.backgroundItem.width
            && root.topInset + root.bottomInset < root.backgroundItem.height
        if (!hasValidInsets) {
            return Qt.rect(0, 0,
                root.targetItem.width, root.targetItem.height)
        }
        const topLeft = root.backgroundItem.mapToItem(root.targetItem,
            Qt.point(root.leftInset, root.topInset))
        const bottomRight = root.backgroundItem.mapToItem(root.targetItem,
            Qt.point(root.backgroundItem.width - root.rightInset,
                root.backgroundItem.height - root.bottomInset))
        return Qt.rect(
            Math.round(Math.min(topLeft.x, bottomRight.x)),
            Math.round(Math.min(topLeft.y, bottomRight.y)),
            Math.max(0, Math.round(Math.abs(bottomRight.x - topLeft.x))),
            Math.max(0, Math.round(Math.abs(bottomRight.y - topLeft.y))))
    }
}
