import QtQuick
import org.kde.plasma.core as PlasmaCore

QtObject {
    id: root

    property bool inPanel: false
    property int panelLocation: PlasmaCore.Types.BottomEdge
    property rect availableScreenRect: Qt.rect(0, 0, 1, 1)
    property rect screenGeometry: Qt.rect(0, 0, 1, 1)
    property var itemAnchor: null
    property var floatingDockAnchor: null
    property var panelWindow: null
    property real menuWidth: 1
    property real menuHeight: 1
    property real panelGap: 0
    property real floatingGap: 0
    property real screenInset: 0

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

    function globalItemRect(item) {
        if (!item || typeof item.mapToGlobal !== "function") {
            return Qt.rect(0, 0, 0, 0)
        }

        try {
            const firstPoint = item.mapToGlobal(Qt.point(0, 0))
            const secondPoint = item.mapToGlobal(Qt.point(
                Math.max(0, root.finiteNumber(item.width, 0)),
                Math.max(0, root.finiteNumber(item.height, 0))))
            const left = Math.min(firstPoint.x, secondPoint.x)
            const top = Math.min(firstPoint.y, secondPoint.y)
            return Qt.rect(left, top,
                Math.abs(secondPoint.x - firstPoint.x),
                Math.abs(secondPoint.y - firstPoint.y))
        } catch (error) {
            return Qt.rect(0, 0, 0, 0)
        }
    }

    function globalWindowRect(window) {
        if (!window) {
            return Qt.rect(0, 0, 0, 0)
        }

        const rectangle = Qt.rect(
            root.finiteNumber(window.x, 0),
            root.finiteNumber(window.y, 0),
            Math.max(0, root.finiteNumber(window.width, 0)),
            Math.max(0, root.finiteNumber(window.height, 0)))
        return root.validRect(rectangle) ? rectangle : Qt.rect(0, 0, 0, 0)
    }

    function absoluteAvailableRect() {
        const available = root.availableScreenRect
        const screen = root.screenGeometry
        if (root.validRect(available) && root.validRect(screen)) {
            return Qt.rect(screen.x + available.x, screen.y + available.y,
                available.width, available.height)
        }
        if (root.validRect(screen)) {
            return screen
        }
        return root.validRect(available) ? available : Qt.rect(0, 0, 1, 1)
    }

    function surfaceRect(anchorRectangle) {
        if (root.inPanel) {
            const panelRectangle = root.globalWindowRect(root.panelWindow)
            if (root.validRect(panelRectangle)) {
                return panelRectangle
            }
        } else {
            const dockRectangle = root.globalItemRect(root.floatingDockAnchor)
            if (root.validRect(dockRectangle)) {
                return dockRectangle
            }
        }
        return anchorRectangle
    }

    function clamp(value, minimum, maximum) {
        return Math.max(minimum, Math.min(Math.max(minimum, maximum), value))
    }

    function calculatePosition() {
        const available = root.absoluteAvailableRect()
        let anchorRectangle = root.globalItemRect(root.itemAnchor)
        const fallbackSurface = root.surfaceRect(anchorRectangle)
        if (!root.validRect(anchorRectangle)) {
            anchorRectangle = root.validRect(fallbackSurface)
                ? fallbackSurface : available
        }
        const surface = root.validRect(fallbackSurface)
            ? fallbackSurface : anchorRectangle
        const width = Math.max(1, root.finiteNumber(root.menuWidth, 1))
        const height = Math.max(1, root.finiteNumber(root.menuHeight, 1))
        const gap = Math.max(0, root.inPanel
            ? root.finiteNumber(root.panelGap, 0)
            : root.finiteNumber(root.floatingGap, 0))
        const inset = Math.max(0, root.finiteNumber(root.screenInset, 0))
        const availableCenterX = available.x + available.width / 2
        const availableCenterY = available.y + available.height / 2
        const anchorCenterX = anchorRectangle.x + anchorRectangle.width / 2
        const anchorCenterY = anchorRectangle.y + anchorRectangle.height / 2
        let targetX = anchorRectangle.x
        let targetY = anchorRectangle.y

        if (root.panelLocation === PlasmaCore.Types.TopEdge
                || root.panelLocation === PlasmaCore.Types.BottomEdge) {
            targetX = anchorCenterX <= availableCenterX
                ? anchorRectangle.x
                : anchorRectangle.x + anchorRectangle.width - width
            targetY = root.panelLocation === PlasmaCore.Types.TopEdge
                ? surface.y + surface.height + gap
                : surface.y - height - gap
        } else {
            targetX = root.panelLocation === PlasmaCore.Types.LeftEdge
                ? surface.x + surface.width + gap
                : surface.x - width - gap
            targetY = anchorCenterY <= availableCenterY
                ? anchorRectangle.y
                : anchorRectangle.y + anchorRectangle.height - height
        }

        const minimumX = available.x + inset
        const minimumY = available.y + inset
        const maximumX = available.x + available.width - inset - width
        const maximumY = available.y + available.height - inset - height
        return Qt.point(
            Math.round(root.clamp(targetX, minimumX, maximumX)),
            Math.round(root.clamp(targetY, minimumY, maximumY)))
    }
}
