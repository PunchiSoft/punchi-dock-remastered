import QtQuick
import QtTest
import org.kde.plasma.core as PlasmaCore
import "../contents/ui/components"

TestCase {
    id: testCase
    name: "NativePopupSpacing"
    when: windowShown
    width: 600
    height: 600

    Item {
        id: anchorContainer
        x: 200
        y: 200
        width: 200
        height: 200

        Item {
            id: source
            x: 50
            y: 50
            width: 48
            height: 48
        }
    }

    PopupSpacingMetrics { id: metrics }

    GuardedPopupDialog {
        id: popup
        hideOnWindowDeactivate: false
        location: spacing.location
        mainItem: Item {
            implicitWidth: 80
            implicitHeight: 60
            width: implicitWidth
            height: implicitHeight
        }
    }

    NativePopupSpacing {
        id: spacing
        sourceAnchor: source
        popup: popup
    }

    function init() {
        // Install after QtTest's logger: only the two confirmed offscreen
        // native-window limitations are filtered; all other warnings fail.
        nativePopupTestSupport.allowNativePopupPlatformWarnings()
        failOnWarning(/.?/)
        popup.closeSafely()
        spacing.sourceAnchor = source
        spacing.gap = 0
        spacing.location = PlasmaCore.Types.BottomEdge
        anchorContainer.scale = 1
        anchorContainer.x = 200
        spacing.refreshAnchor()
    }

    function cleanup() {
        popup.closeSafely()
    }

    function test_visibleDistance_data() {
        return [
            {tag: "bottom", edge: PlasmaCore.Types.BottomEdge, dx: 0, dy: -1},
            {tag: "top", edge: PlasmaCore.Types.TopEdge, dx: 0, dy: 1},
            {tag: "left", edge: PlasmaCore.Types.LeftEdge, dx: 1, dy: 0},
            {tag: "right", edge: PlasmaCore.Types.RightEdge, dx: -1, dy: 0}
        ]
    }

    function test_visibleDistance(data) {
        spacing.location = data.edge
        spacing.refreshAnchor()
        popup.openSafely()
        tryCompare(popup, "visible", true)
        compare(popup.visualParent, source)
        const initialX = popup.x
        const initialY = popup.y
        spacing.gap = metrics.gapForPercent(100)
        tryCompare(popup, "x", initialX + data.dx * metrics.maximumGap)
        tryCompare(popup, "y", initialY + data.dy * metrics.maximumGap)
        verify(popup.visible)
        spacing.gap = metrics.gapForPercent(50)
        tryCompare(popup, "x", initialX + data.dx * metrics.gapForPercent(50))
        tryCompare(popup, "y", initialY + data.dy * metrics.gapForPercent(50))
        spacing.gap = 0
        tryCompare(popup, "visualParent", source)
        tryCompare(popup, "x", initialX)
        tryCompare(popup, "y", initialY)
    }

    function test_scaledAncestorAndMovement() {
        spacing.gap = metrics.maximumGap
        anchorContainer.scale = 1.5
        const mapped = source.mapToItem(spacing.parent,
            Qt.rect(0, 0, source.width, source.height))
        compare(spacing.x, mapped.x)
        compare(spacing.y, mapped.y - metrics.maximumGap)
        compare(spacing.width, mapped.width)
        const previousX = spacing.x
        anchorContainer.x += metrics.maximumGap
        compare(spacing.x, previousX + metrics.maximumGap)
    }

    function test_anchorRemovalClosesPopup() {
        spacing.gap = metrics.maximumGap
        popup.openSafely()
        tryCompare(popup, "visible", true)
        spacing.sourceAnchor = null
        tryCompare(popup, "visible", false)
        compare(popup.visualParent, null)
        spacing.sourceAnchor = source
        spacing.refreshAnchor()
        popup.openSafely()
        tryCompare(popup, "visible", true)
        compare(popup.visualParent, spacing)
    }
}
