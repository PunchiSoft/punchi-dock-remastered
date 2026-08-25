import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

QtObject {
    id: root

    property bool inPanel: false
    property bool hiddenByVirtualDesktop: false
    property bool verticalPanel: false
    property bool horizontalPanel: false
    property int panelLocation: PlasmaCore.Types.BottomEdge
    property int configuredIconSize: 48
    property int configuredIconSpacing: 8
    property string configuredPanelLengthMode: "fit"
    property string configuredPanelAlignmentMode: "start"
    property int folderPopupDistancePercent: 0
    property int contextMenuDistancePercent: 0
    property real panelHoverScale: 1.0
    property bool dockShowLabels: false
    property int dockLabelAreaHeight: 0
    property var dockItems: []
    property bool mediaItemExpanded: true
    property int visibleTaskCount: 0
    property int overflowTaskCount: 0
    property int totalDynamicGroups: 0
    property bool dynamicApplicationsMoveModeActive: false
    property rect availableScreenRect: Qt.rect(0, 0, 800, 640)
    property var floatingAnchor: null
    property int floatingScreenEdge: PlasmaCore.Types.LeftEdge
    property real hostHeight: 0
    property var panelWindow: null
    property var containment: null

    readonly property PopupSpacingMetrics popupSpacingMetrics:
        PopupSpacingMetrics {}

    readonly property int dockSpacing: {
        const spacing = Number(root.configuredIconSpacing)
        return Math.round(Math.max(0, Math.min(24,
            Number.isFinite(spacing) ? spacing : 8)))
    }
    readonly property int dockBackgroundHorizontalPadding: 10
    readonly property int dockBackgroundVerticalPadding: 12
    readonly property int floatingExtraWidth: 48
    readonly property int floatingExtraHeight: 32
    readonly property int effectivePanelLocation: root.inPanel
        ? root.panelLocation
        : root.floatingScreenEdge

    function updateFloatingScreenEdge(anchor) {
        const target = anchor || root.floatingAnchor
        if (root.inPanel || !target) {
            return
        }

        try {
            const centerPoint = Qt.point(Math.max(0, Number(target.width || 0)) / 2,
                Math.max(0, Number(target.height || 0)) / 2)
            const center = typeof target.mapToGlobal === "function"
                ? target.mapToGlobal(centerPoint)
                : target.mapToScene(centerPoint)
            if (root.verticalPanel) {
                const screenCenterX = Number(root.availableScreenRect.x || 0)
                    + (Math.max(0, Number(root.availableScreenRect.width || 0)) / 2)
                root.floatingScreenEdge = center.x <= screenCenterX
                    ? PlasmaCore.Types.LeftEdge
                    : PlasmaCore.Types.RightEdge
            } else {
                const screenCenterY = Number(root.availableScreenRect.y || 0)
                    + (Math.max(0, Number(root.availableScreenRect.height || 0)) / 2)
                root.floatingScreenEdge = center.y <= screenCenterY
                    ? PlasmaCore.Types.TopEdge
                    : PlasmaCore.Types.BottomEdge
            }
        } catch (error) {
            root.floatingScreenEdge = root.panelLocation
        }
    }

    onFloatingAnchorChanged: updateFloatingScreenEdge(root.floatingAnchor)
    onAvailableScreenRectChanged: updateFloatingScreenEdge(root.floatingAnchor)
    onVerticalPanelChanged: updateFloatingScreenEdge(root.floatingAnchor)
    readonly property bool topPanel: effectivePanelLocation === PlasmaCore.Types.TopEdge
    readonly property bool bottomPanel: effectivePanelLocation === PlasmaCore.Types.BottomEdge
    readonly property bool leftPanel: effectivePanelLocation === PlasmaCore.Types.LeftEdge
    readonly property bool rightPanel: effectivePanelLocation === PlasmaCore.Types.RightEdge

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
    readonly property int spectrumOriginEdge: {
        if (topPanel) {
            return Qt.TopEdge
        }
        if (bottomPanel) {
            return Qt.BottomEdge
        }
        if (leftPanel) {
            return Qt.LeftEdge
        }
        if (rightPanel) {
            return Qt.RightEdge
        }
        return Qt.BottomEdge
    }
    readonly property int popupMargin: root.inPanel ? 2 : 10
    readonly property int maximumAdaptivePopupGap:
        root.popupSpacingMetrics.maximumGap
    readonly property int folderPopupGap:
        root.popupGapForPercent(root.folderPopupDistancePercent)
    readonly property int contextMenuGap:
        root.popupGapForPercent(root.contextMenuDistancePercent)
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
    readonly property int mediaItemMainAxisLength: Math.round(Math.max(120,
        Math.min(320, effectiveIconSize * 4.2)))
    readonly property int compactMediaItemMainAxisLength: Math.round(Math.max(120,
        Math.min(240, effectiveIconSize * 2.9)))
    readonly property bool panelFillLengthEnabled: root.inPanel
        && panelUsesFillAvailable
        && !root.hiddenByVirtualDesktop
        && root.configuredPanelLengthMode === "fill"
    readonly property int panelItemWidth: Math.ceil(Math.max(effectiveIconSize + 12,
        root.dockShowLabels ? effectiveIconSize * 1.85 : 0))
    readonly property int panelItemHeight: Math.ceil(effectiveIconSize + 12
        + root.dockLabelAreaHeight)
    readonly property int dynamicApplicationsMoveHandleExtent: Math.ceil(
        root.verticalPanel ? root.panelItemHeight
            : Math.max(root.effectiveIconSize
                + Kirigami.Units.smallSpacing * 2,
                root.effectiveIconSize * 3.6))
    readonly property int panelHoverCrossAxisExtent: Math.ceil(root.horizontalPanel
        ? (effectiveIconSize * root.panelHoverScale) + 12 + root.dockLabelAreaHeight
        : Math.max(panelItemWidth, (effectiveIconSize * root.panelHoverScale) + 12))

    function normalizedMediaTextMode(item) {
        const mode = item ? String(item.mediaTextMode || "automatic") : "automatic"
        return mode === "always" || mode === "hidden" ? mode : "automatic"
    }

    function normalizedPopupDistancePercent(value) {
        return root.popupSpacingMetrics.normalizedPercent(value)
    }

    function popupGapForPercent(value) {
        return root.popupSpacingMetrics.gapForPercent(value)
    }

    function mediaMetadataVisibleForItem(item) {
        const mode = root.normalizedMediaTextMode(item)
        return mode === "always"
            || (mode === "automatic"
                && (!root.verticalPanel
                    || root.effectiveIconSize >= Kirigami.Units.gridUnit * 5))
    }

    function mediaItemMainAxisLengthForItem(item) {
        if (item && String(item.mediaDisplayMode || "normal") !== "compact") {
            return root.mediaMetadataVisibleForItem(item)
                ? root.mediaItemMainAxisLength
                : root.compactMediaItemMainAxisLength
        }
        if (!root.mediaItemExpanded) {
            return root.effectiveIconSize
        }
        return root.mediaMetadataVisibleForItem(item)
            ? root.mediaItemMainAxisLength
            : root.compactMediaItemMainAxisLength
    }

    function panelMainAxisExtentForDockItem(item) {
        const itemType = item && item.type ? String(item.type) : "app"
        if (itemType === "dynamic-applications"
                && root.dynamicApplicationsMoveModeActive) {
            return root.dynamicApplicationsMoveHandleExtent
        }
        if (itemType === "separator" || itemType === "dynamic-applications") {
            return 10
        }
        if (itemType === "spacer") {
            return Math.max(12, effectiveIconSize * 0.5)
        }
        if (itemType === "media") {
            return root.mediaItemMainAxisLengthForItem(item) + 12
        }
        return root.verticalPanel ? panelItemHeight : panelItemWidth
    }

    readonly property int panelFixedContentLength: {
        let extent = 0
        const items = root.dockItems || []
        for (let index = 0; index < items.length; index++) {
            extent += root.panelMainAxisExtentForDockItem(items[index])
        }
        return Math.ceil(extent + (Math.max(0, items.length - 1) * dockSpacing))
    }
    readonly property int renderedDynamicItemCount: root.visibleTaskCount
        + (root.overflowTaskCount > 0 ? 1 : 0)
    readonly property int panelCompactContentLength: {
        const boundarySpacing = root.dockItems.length > 0 && renderedDynamicItemCount > 0
            ? dockSpacing
            : 0
        const dynamicItemExtent = root.verticalPanel ? panelItemHeight : panelItemWidth
        const dynamicLength = renderedDynamicItemCount > 0
            ? (renderedDynamicItemCount * dynamicItemExtent)
                + (Math.max(0, renderedDynamicItemCount - 1) * dockSpacing)
            : 0
        return Math.ceil(panelFixedContentLength + boundarySpacing + dynamicLength)
    }
    readonly property int panelMinimumContentLength: {
        const hasDynamicGroups = root.totalDynamicGroups > 0
        const boundarySpacing = root.dockItems.length > 0 && hasDynamicGroups ? dockSpacing : 0
        const dynamicItemExtent = root.verticalPanel ? panelItemHeight : panelItemWidth
        return Math.ceil(panelFixedContentLength + boundarySpacing
            + (hasDynamicGroups ? dynamicItemExtent : 0))
    }
    readonly property int panelContentLength: panelFillLengthEnabled
        ? panelMinimumContentLength
        : Math.max(root.verticalPanel ? panelItemHeight : panelItemWidth,
            panelCompactContentLength)
    readonly property int panelMinimumWidth: root.hiddenByVirtualDesktop
        ? 0
        : Math.ceil((root.verticalPanel
            ? panelHoverCrossAxisExtent
            : panelContentLength) + (dockBackgroundHorizontalPadding * 2))
    readonly property int panelMinimumHeight: root.hiddenByVirtualDesktop
        ? 0
        : Math.ceil(root.verticalPanel
            ? panelContentLength + (dockBackgroundVerticalPadding * 2)
            : panelItemHeight + (root.inPanel ? 0 : (dockBackgroundVerticalPadding * 2)))
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
    readonly property int taskPopupReservedVerticalExtent:
        root.inPanel && !root.verticalPanel ? panelPreferredHeight : 0
    readonly property int taskPopupAvailableHeight: Math.max(240,
        Number(root.availableScreenRect.height || 640)
            - taskPopupReservedVerticalExtent - 24)
    readonly property int taskPopupAvailableWidth: Math.max(280,
        Number(root.availableScreenRect.width || 800) - 48)
}
