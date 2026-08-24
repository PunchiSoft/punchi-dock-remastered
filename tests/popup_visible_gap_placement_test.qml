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

    PunchiMenuNormalPlacement {
        id: placement
        inPanel: true
        placementMode: "anchored"
        availableScreenRect: Qt.rect(0, 0, 1000, 800)
        screenGeometry: Qt.rect(0, 0, 1000, 800)
        panelWindow: panelWindow
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
        placement.panelGap = 0
    }

    function verifyVisibleGap(edge, expectedGap) {
        placement.panelLocation = edge
        placement.panelGap = expectedGap

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

    function test_zeroPercentJoinsEffectiveSurfacesOnEveryEdge() {
        verifyVisibleGap(PlasmaCore.Types.TopEdge, 0)
        verifyVisibleGap(PlasmaCore.Types.BottomEdge, 0)
        verifyVisibleGap(PlasmaCore.Types.LeftEdge, 0)
        verifyVisibleGap(PlasmaCore.Types.RightEdge, 0)
    }

    function test_configuredGapStartsAtEffectiveSurfaceEdges() {
        verifyVisibleGap(PlasmaCore.Types.TopEdge, 10)
        verifyVisibleGap(PlasmaCore.Types.BottomEdge, 10)
        verifyVisibleGap(PlasmaCore.Types.LeftEdge, 10)
        verifyVisibleGap(PlasmaCore.Types.RightEdge, 10)
    }

    function test_popupIsCenteredOnHorizontalDockItem() {
        verifyVisibleGap(PlasmaCore.Types.BottomEdge, 0)
        const anchorCenter = itemAnchor.mapToGlobal(
            Qt.point(itemAnchor.width / 2, itemAnchor.height / 2))
        compare(placement.calculatePosition().x,
            Math.round(anchorCenter.x - placement.menuWidth / 2))
    }

    function test_popupIsCenteredOnVerticalDockItem() {
        verifyVisibleGap(PlasmaCore.Types.LeftEdge, 0)
        const anchorCenter = itemAnchor.mapToGlobal(
            Qt.point(itemAnchor.width / 2, itemAnchor.height / 2))
        compare(placement.calculatePosition().y,
            Math.round(anchorCenter.y - placement.menuHeight / 2))
    }
}
