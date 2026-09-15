import QtQuick
import QtQuick.Window
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

    GuardedPopupDialog {
        id: folderPopup
        hideOnWindowDeactivate: false
        location: folderSpacing.location
        mainItem: PopupAnimatedContent {
            id: folderAnimation
            popupVisible: folderPopup.visible
            ContextSurfaceStack {
                contentGeometryTransitionsEnabled: false
                showMedia: false
                drawContentBackground: true
                backgroundImagePath: "widgets/background"
                contentFramePaddingPercent: 2
                FolderPopup {
                    id: folderContent
                    folderItem: ({name: "Test folder", apps: [
                        {name: "One", icon: "folder"},
                        {name: "Two", icon: "folder"},
                        {name: "Three", icon: "folder"}
                    ]})
                }
            }
        }
    }

    NativePopupSpacing {
        id: folderSpacing
        sourceAnchor: source
        popup: folderPopup
    }

    function init() {
        // Install after QtTest's logger: only the confirmed offscreen
        // native-window limitations are filtered; all other warnings fail.
        nativePopupTestSupport.allowNativePopupPlatformWarnings()
        failOnWarning(/.?/)
        popup.closeSafely()
        folderPopup.closeSafely()
        folderSpacing.sourceAnchor = source
        folderSpacing.preserveHorizontalAnchorCenter = false
        folderSpacing.gap = 0
        folderSpacing.location = PlasmaCore.Types.BottomEdge
        folderContent.layoutMode = "grid"
        folderContent.profileScale = 1
        spacing.sourceAnchor = source
        spacing.preserveHorizontalAnchorCenter = false
        spacing.gap = 0
        spacing.location = PlasmaCore.Types.BottomEdge
        anchorContainer.scale = 1
        anchorContainer.x = 200
        source.x = 50
        source.y = 50
        spacing.refreshAnchor()
    }

    function cleanup() {
        popup.closeSafely()
        folderPopup.closeSafely()
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

    function placeSource(globalX) {
        const screen = testCase.Screen
        const point = anchorContainer.mapFromGlobal(globalX,
            screen.virtualY + screen.height / 2 + 80)
        source.x = point.x - source.width / 2
        source.y = point.y - source.height / 2
        folderSpacing.refreshAnchor()
    }

    function verifyFolderCenter() {
        tryVerify(function() {
            const center = source.mapToGlobal(source.width / 2, source.height / 2)
            return Math.abs(folderPopup.x + folderPopup.width / 2 - center.x) <= 2
        }, 2000, "The native dialog must remain centered on its launcher")
    }

    function test_folderCenterNearScreenMiddle_data() {
        const rows = []
        for (const mode of ["grid", "list", "detailed"]) {
            for (const edge of [PlasmaCore.Types.BottomEdge, PlasmaCore.Types.TopEdge]) {
                for (const offset of [-60, 60]) {
                    rows.push({tag: mode + "-" + edge + "-" + offset,
                        mode: mode, edge: edge, offset: offset})
                }
            }
        }
        return rows
    }

    function test_folderCenterNearScreenMiddle(data) {
        folderContent.layoutMode = data.mode
        folderSpacing.location = data.edge
        const screen = testCase.Screen
        const screenCenter = screen.virtualX + screen.width / 2
        placeSource(screenCenter + data.offset)

        // Control: the unprotected native dialog reproduces the original bug.
        folderPopup.openSafely()
        tryCompare(folderPopup, "visible", true)
        tryCompare(folderAnimation, "openingProgress", 1)
        tryVerify(function() {
            return Math.abs(folderPopup.x + folderPopup.width / 2 - screenCenter) <= 2
        })
        verify(Math.abs(folderPopup.x + folderPopup.width / 2
            - source.mapToGlobal(source.width / 2, source.height / 2).x) > 40)

        folderPopup.closeSafely()
        folderSpacing.preserveHorizontalAnchorCenter = true
        folderSpacing.refreshAnchor()
        folderPopup.openSafely()
        tryCompare(folderPopup, "visible", true)
        verifyFolderCenter()
        tryCompare(folderAnimation, "openingProgress", 1)
        verifyFolderCenter()

        // Distance and size changes must not restore the screen-center snap.
        const baseY = folderPopup.y
        folderSpacing.gap = metrics.maximumGap
        tryCompare(folderPopup, "y", baseY
            + (data.edge === PlasmaCore.Types.BottomEdge ? -1 : 1) * metrics.maximumGap)
        verifyFolderCenter()
        folderContent.profileScale = 1.25
        verifyFolderCenter()
        folderSpacing.gap = 0
        tryCompare(folderPopup, "visualParent", folderSpacing)
        verifyFolderCenter()
        placeSource(screenCenter - data.offset)
        verifyFolderCenter()
        folderPopup.closeSafely()
        folderPopup.openSafely()
        tryCompare(folderAnimation, "openingProgress", 1)
        verifyFolderCenter()
    }

    function test_folderCenterClampsToScreenEdges() {
        const screen = testCase.Screen
        folderSpacing.preserveHorizontalAnchorCenter = true
        for (const center of [screen.virtualX + 24, screen.virtualX + screen.width - 24]) {
            placeSource(center)
            folderPopup.openSafely()
            tryCompare(folderPopup, "visible", true)
            tryCompare(folderAnimation, "openingProgress", 1)
            verify(folderPopup.x >= screen.virtualX)
            verify(folderPopup.x + folderPopup.width <= screen.virtualX + screen.width)
            verify(folderPopup.x <= center && folderPopup.x + folderPopup.width >= center)
            folderPopup.closeSafely()
        }
    }

    function test_horizontalOptInPreservesVerticalSpacing() {
        spacing.preserveHorizontalAnchorCenter = true
        for (const edge of [PlasmaCore.Types.LeftEdge, PlasmaCore.Types.RightEdge]) {
            spacing.location = edge
            spacing.gap = 0
            spacing.refreshAnchor()
            compare(popup.visualParent, source)
            spacing.gap = metrics.maximumGap
            spacing.refreshAnchor()
            compare(spacing.width, spacing.sourceGeometry.width)
            compare(spacing.height, spacing.sourceGeometry.height)
            compare(popup.visualParent, spacing)
        }
        spacing.preserveHorizontalAnchorCenter = false
    }
}
