import QtQuick
import org.kde.plasma.core as PlasmaCore

QtObject {
    id: root

    property bool inPanel: false
    property bool hiddenByVirtualDesktop: false
    property bool verticalPanel: false
    property bool horizontalPanel: false
    property int panelLocation: PlasmaCore.Types.BottomEdge
    property int configuredIconSize: 48
    property string configuredPanelLengthMode: "fit"
    property int folderPopupExtraDistance: 0
    property real panelHoverScale: 1.0
    property bool dockShowLabels: false
    property int dockLabelAreaHeight: 0
    property var dockItems: []
    property int visibleTaskCount: 0
    property int overflowTaskCount: 0
    property int totalDynamicGroups: 0
    property rect availableScreenRect: Qt.rect(0, 0, 800, 640)
    property real hostHeight: 0
    property var panelWindow: null
    property var containment: null

    readonly property int dockSpacing: 8
    readonly property int dockBackgroundHorizontalPadding: 18
    readonly property int dockBackgroundVerticalPadding: 12
    readonly property int floatingExtraWidth: 48
    readonly property int floatingExtraHeight: 32
    readonly property bool topPanel: panelLocation === PlasmaCore.Types.TopEdge
    readonly property bool bottomPanel: panelLocation === PlasmaCore.Types.BottomEdge
    readonly property bool leftPanel: panelLocation === PlasmaCore.Types.LeftEdge
    readonly property bool rightPanel: panelLocation === PlasmaCore.Types.RightEdge

    readonly property int detectedPanelLengthMode: {
        try {
            if (!root.inPanel || !root.panelWindow
                    || typeof root.panelWindow["lengthMode"] === "undefined") {
                return -1
            }
            const lengthMode = Number(root.panelWindow["lengthMode"])
            return Number.isFinite(lengthMode) ? lengthMode : -1
        } catch (error) {
            return -1
        }
    }
    readonly property bool panelUsesFillAvailable: detectedPanelLengthMode === 0
    readonly property int popupDirection: {
        if (topPanel) {
            return Qt.BottomEdge
        }
        if (bottomPanel) {
            return Qt.TopEdge
        }
        if (leftPanel) {
            return Qt.RightEdge
        }
        if (rightPanel) {
            return Qt.LeftEdge
        }
        return Qt.TopEdge
    }
    readonly property int popupMargin: root.inPanel ? 2 : 10
    readonly property int folderPopupMargin: popupMargin
        + Math.max(0, Math.min(32, Number(root.folderPopupExtraDistance || 0)))
    readonly property int detectedPanelThickness: {
        try {
            if (!root.containment) {
                return 0
            }

            const thickness = root.verticalPanel
                ? Math.max(0, Number(root.containment["width"] || 0))
                : Math.max(0, Number(root.containment["height"] || 0))
            return thickness > 0 ? thickness : 0
        } catch (error) {
            return 0
        }
    }
    readonly property int panelCrossAxisPadding: root.verticalPanel
        ? (dockBackgroundHorizontalPadding * 2)
        : (dockBackgroundVerticalPadding * 2)
    readonly property int effectivePanelIconLimit: detectedPanelThickness > 0
        ? Math.max(32, detectedPanelThickness - panelCrossAxisPadding - 12)
        : Math.max(32, root.configuredIconSize)
    readonly property int effectivePanelBaseIconLimit: detectedPanelThickness > 0
        ? Math.max(24, Math.floor(effectivePanelIconLimit / root.panelHoverScale))
        : Math.max(32, root.configuredIconSize)
    readonly property int effectiveIconSize: root.inPanel
        ? Math.min(root.configuredIconSize, effectivePanelBaseIconLimit)
        : root.configuredIconSize
    readonly property bool panelFillLengthEnabled: root.inPanel
        && root.horizontalPanel
        && panelUsesFillAvailable
        && !root.hiddenByVirtualDesktop
        && root.configuredPanelLengthMode === "fill"
    readonly property int panelItemWidth: Math.ceil(Math.max(effectiveIconSize + 12,
        root.dockShowLabels ? effectiveIconSize * 1.85 : 0))
    readonly property int panelItemHeight: Math.ceil(effectiveIconSize + 12
        + root.dockLabelAreaHeight)
    readonly property int panelHoverCrossAxisExtent: Math.ceil(root.horizontalPanel
        ? (effectiveIconSize * root.panelHoverScale) + 12 + root.dockLabelAreaHeight
        : Math.max(panelItemWidth, (effectiveIconSize * root.panelHoverScale) + 12))

    function panelWidthForDockItem(item) {
        const itemType = item && item.type ? String(item.type) : "app"
        if (itemType === "separator") {
            return 10
        }
        if (itemType === "spacer") {
            return Math.max(12, effectiveIconSize * 0.5)
        }
        return panelItemWidth
    }

    readonly property int panelFixedContentWidth: {
        let extent = 0
        const items = root.dockItems || []
        for (let index = 0; index < items.length; index++) {
            extent += root.panelWidthForDockItem(items[index])
        }
        return Math.ceil(extent + (Math.max(0, items.length - 1) * dockSpacing))
    }
    readonly property int renderedDynamicItemCount: root.visibleTaskCount
        + (root.overflowTaskCount > 0 ? 1 : 0)
    readonly property int panelCompactContentWidth: {
        const boundarySpacing = root.dockItems.length > 0 && renderedDynamicItemCount > 0
            ? dockSpacing
            : 0
        const dynamicWidth = renderedDynamicItemCount > 0
            ? (renderedDynamicItemCount * panelItemWidth)
                + (Math.max(0, renderedDynamicItemCount - 1) * dockSpacing)
            : 0
        return Math.ceil(panelFixedContentWidth + boundarySpacing + dynamicWidth)
    }
    readonly property int panelMinimumContentWidth: {
        const hasDynamicGroups = root.totalDynamicGroups > 0
        const boundarySpacing = root.dockItems.length > 0 && hasDynamicGroups ? dockSpacing : 0
        return Math.ceil(panelFixedContentWidth + boundarySpacing
            + (hasDynamicGroups ? panelItemWidth : 0))
    }
    readonly property int panelContentWidth: panelFillLengthEnabled
        ? panelMinimumContentWidth
        : Math.max(panelItemWidth, panelCompactContentWidth)
    readonly property int panelContentHeight: panelItemHeight
    readonly property int panelMinimumWidth: root.hiddenByVirtualDesktop
        ? 0
        : Math.ceil((root.verticalPanel
            ? Math.max(panelContentWidth, panelHoverCrossAxisExtent)
            : panelContentWidth) + (dockBackgroundHorizontalPadding * 2))
    readonly property int panelMinimumHeight: root.hiddenByVirtualDesktop
        ? 0
        : Math.ceil(root.horizontalPanel
            ? panelContentHeight
            : panelContentHeight + (dockBackgroundVerticalPadding * 2))
    readonly property int panelPreferredWidth: root.hiddenByVirtualDesktop ? 0 : panelMinimumWidth
    readonly property int panelPreferredHeight: root.hiddenByVirtualDesktop ? 0 : panelMinimumHeight
    readonly property real panelReflectionAvailableExtent: {
        if (!root.inPanel || !root.horizontalPanel) {
            return -1
        }

        const allocatedHeight = Math.max(panelItemHeight,
            root.hostHeight > 0 ? root.hostHeight : panelPreferredHeight)
        const outerBottomMargin = Math.max(0, (allocatedHeight - panelItemHeight) / 2)
        const itemBottomMargin = Math.max(0, (panelItemHeight - effectiveIconSize) / 2)
        return outerBottomMargin + itemBottomMargin
    }
    readonly property int taskPopupAvailableHeight: Math.max(240,
        Number(root.availableScreenRect.height || 640)
            - (root.inPanel ? panelPreferredHeight : 0) - 24)
    readonly property int taskPopupAvailableWidth: Math.max(280,
        Number(root.availableScreenRect.width || 800) - 48)
}
