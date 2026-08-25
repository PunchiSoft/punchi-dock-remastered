import QtQuick
import QtTest
import org.kde.plasma.core as PlasmaCore
import "../contents/ui/components/punchimenu"

TestCase {
    id: testCase
    name: "PopupVisibleGapPlacement"

    QtObject {
        id: panelWindow
        property real x: 0
        property real y: 0
        property real width: 1000
        property real height: 40
    }

    Item {
        id: itemAnchor
        x: 480
        y: 380
        width: 40
        height: 40
    }

    Item {
        id: floatingDockAnchor
        x: 0
        y: 700
        width: 1000
        height: 80
    }

    PunchiMenuNormalPlacement {
        id: placement
        inPanel: true
        placementMode: "anchored"
        availableScreenRect: Qt.rect(0, 0, 1000, 800)
        screenGeometry: Qt.rect(0, 0, 1000, 800)
        panelWindow: panelWindow
        floatingDockAnchor: floatingDockAnchor
        itemAnchor: itemAnchor
        menuWidth: 200
        menuHeight: 100
        panelGap: 0
        themeFrameLeftMargin: 12
        themeFrameTopMargin: 12
        themeFrameRightMargin: 12
        themeFrameBottomMargin: 12
        surfaceFrameLeftMargin: 8
        surfaceFrameTopMargin: 8
        surfaceFrameRightMargin: 8
        surfaceFrameBottomMargin: 8
    }

    function init() {
        failOnWarning(/.?/)
        placement.inPanel = true
        placement.panelGap = 0
        placement.floatingGap = 0
        placement.menuWidth = 200
        placement.menuHeight = 100
        placement.horizontalAnchorWidth = placement.menuWidth
    }

    function verifyVisibleGap(edge, requestedGap, expectedGap) {
        placement.panelLocation = edge
        placement.panelGap = requestedGap

        if (edge === PlasmaCore.Types.TopEdge) {
            panelWindow.x = 0
            panelWindow.y = 0
            panelWindow.width = 1000
            panelWindow.height = 40
            itemAnchor.x = 480
            itemAnchor.y = 0
        } else if (edge === PlasmaCore.Types.BottomEdge) {
            panelWindow.x = 0
            panelWindow.y = 760
            panelWindow.width = 1000
            panelWindow.height = 40
            itemAnchor.x = 480
            itemAnchor.y = 760
        } else if (edge === PlasmaCore.Types.LeftEdge) {
            panelWindow.x = 0
            panelWindow.y = 0
            panelWindow.width = 40
            panelWindow.height = 800
            itemAnchor.x = 0
            itemAnchor.y = 380
        } else {
            panelWindow.x = 960
            panelWindow.y = 0
            panelWindow.width = 40
            panelWindow.height = 800
            itemAnchor.x = 960
            itemAnchor.y = 380
        }

        const position = placement.calculatePosition()
        if (edge === PlasmaCore.Types.TopEdge) {
            const dockVisibleBottom = panelWindow.y + panelWindow.height
                - placement.surfaceFrameBottomMargin
            const popupVisibleTop = position.y
                + placement.themeFrameTopMargin
            compare(popupVisibleTop - dockVisibleBottom, expectedGap)
        } else if (edge === PlasmaCore.Types.BottomEdge) {
            const dockVisibleTop = panelWindow.y
                + placement.surfaceFrameTopMargin
            const popupVisibleBottom = position.y + placement.menuHeight
                - placement.themeFrameBottomMargin
            compare(dockVisibleTop - popupVisibleBottom, expectedGap)
        } else if (edge === PlasmaCore.Types.LeftEdge) {
            const dockVisibleRight = panelWindow.x + panelWindow.width
                - placement.surfaceFrameRightMargin
            const popupVisibleLeft = position.x
                + placement.themeFrameLeftMargin
            compare(popupVisibleLeft - dockVisibleRight, expectedGap)
        } else {
            const dockVisibleLeft = panelWindow.x
                + placement.surfaceFrameLeftMargin
            const popupVisibleRight = position.x + placement.menuWidth
                - placement.themeFrameRightMargin
            compare(dockVisibleLeft - popupVisibleRight, expectedGap)
        }
    }

    function test_zeroPercentKeepsThemedMinimumGapOnPanels() {
        const minimumGap = placement.minimumPanelGap
        verifyVisibleGap(PlasmaCore.Types.TopEdge, 0, minimumGap)
        verifyVisibleGap(PlasmaCore.Types.BottomEdge, 0, minimumGap)
        verifyVisibleGap(PlasmaCore.Types.LeftEdge, 0, minimumGap)
        verifyVisibleGap(PlasmaCore.Types.RightEdge, 0, minimumGap)
    }

    function test_configuredGapStartsAtEffectiveSurfaceEdges() {
        verifyVisibleGap(PlasmaCore.Types.TopEdge, 10, 10)
        verifyVisibleGap(PlasmaCore.Types.BottomEdge, 10, 10)
        verifyVisibleGap(PlasmaCore.Types.LeftEdge, 10, 10)
        verifyVisibleGap(PlasmaCore.Types.RightEdge, 10, 10)
    }

    function test_zeroPercentStillJoinsEffectiveFloatingSurfaces() {
        placement.inPanel = false
        placement.panelLocation = PlasmaCore.Types.BottomEdge
        placement.floatingGap = 0

        const position = placement.calculatePosition()
        const floatingDockRect = placement.globalItemRect(floatingDockAnchor)
        const dockVisibleTop = floatingDockRect.y
            + placement.surfaceFrameTopMargin
        const popupVisibleBottom = position.y + placement.menuHeight
            - placement.themeFrameBottomMargin
        compare(dockVisibleTop - popupVisibleBottom, 0)
    }

    function test_popupIsCenteredOnHorizontalDockItem() {
        verifyVisibleGap(PlasmaCore.Types.BottomEdge, 0,
            placement.minimumPanelGap)
        const anchorCenter = itemAnchor.mapToGlobal(
            Qt.point(itemAnchor.width / 2, itemAnchor.height / 2))
        compare(placement.calculatePosition().x,
            Math.round(anchorCenter.x - placement.menuWidth / 2))
    }

    function test_popupIsCenteredOnVerticalDockItem() {
        verifyVisibleGap(PlasmaCore.Types.LeftEdge, 0,
            placement.minimumPanelGap)
        const anchorCenter = itemAnchor.mapToGlobal(
            Qt.point(itemAnchor.width / 2, itemAnchor.height / 2))
        compare(placement.calculatePosition().y,
            Math.round(anchorCenter.y - placement.menuHeight / 2))
    }

    function test_inlineExpansionKeepsPrimarySurfaceAnchored() {
        verifyVisibleGap(PlasmaCore.Types.BottomEdge, 0,
            placement.minimumPanelGap)
        const collapsedX = placement.calculatePosition().x

        placement.horizontalAnchorWidth = placement.menuWidth
        placement.menuWidth = 440
        const expandedX = placement.calculatePosition().x
        const anchorCenter = itemAnchor.mapToGlobal(
            Qt.point(itemAnchor.width / 2, itemAnchor.height / 2))

        compare(expandedX, collapsedX)
        compare(expandedX + placement.horizontalAnchorWidth / 2,
            Math.round(anchorCenter.x))

        placement.menuWidth = placement.horizontalAnchorWidth
        compare(placement.calculatePosition().x, collapsedX)
    }

    function test_inlineExpansionStillClampsFullWindowToScreen() {
        verifyVisibleGap(PlasmaCore.Types.BottomEdge, 0,
            placement.minimumPanelGap)
        itemAnchor.x = 880
        placement.horizontalAnchorWidth = placement.menuWidth
        placement.menuWidth = 440

        const expandedX = placement.calculatePosition().x
        compare(expandedX, 560)
        compare(expandedX + placement.menuWidth, 1000)
    }
}
