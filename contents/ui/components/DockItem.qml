pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import "../../code/dockDropState.js" as DockDropState
import "punchimenu" as PunchiMenuComponents

Item {
    id: dockItemContainer
    
    property var iconName: ""
    property string itemName: ""
    property string itemCommand: ""
    property int iconSize: 48
    property real timeTextScale: 1.0
    property real dateTextScale: 1.0
    property string separatorStyleSetting: "line"
    property real separatorThicknessSetting: 2
    property real separatorLengthRatioSetting: 0.72
    property real separatorOpacitySetting: 0.34
    property bool separatorGlowSetting: false
    property bool separatorVisibleSetting: true

    readonly property string effectiveIndicatorPosition:
        indicatorPosition === "top" ? "top" : "bottom"

    // qmllint disable unqualified
    readonly property string localizedItemName: {
        if (itemType === "trash" && itemName === "Trash") {
            return i18n("Trash")
        }
        if (itemType === "calendar"
                && (itemName === "Calendar" || itemName === "Calendar/Clock")) {
            return i18n("Calendar/Clock")
        }
        if (itemType === "note" && itemName === "Quick Note") {
            return i18nc("@title", "Quick Note")
        }
        if (itemType === "punchimenu" && (itemName === "PunchiMenu" || !itemName)) {
            return i18nc("@title", "PunchiMenu")
        }
        if (itemType === "dynamic-applications") {
            return i18nc("@title", "Open applications")
        }
        return itemName
    }
    // qmllint enable unqualified

    property int itemIndex: -1
    property int hoveredIndex: -1
    
    // Wave animation state.
    property real hoverZoomProgress: 0.0
    property int lastHoveredIndex: -1
    property real lastMouseOffset: 0.0
    property real selectionPulseScale: 1.0
    // Wave geometry follows the original project while preserving smooth transitions.
    property real hoverScaleSetting: 1.65
    property string hoverAnimationMode: "wave"
    property string clickEffect: "none"
    property string windowMinimizeEffect: "none"
    property int taskMinimizedCount: 0
    property int minimizeReactionRevision: 0
    property int minimizeReactionTargetIndex: -1
    property int observedTaskCount: 0
    property int observedTaskMinimizedCount: 0
    property bool taskMinimizedTrackingReady: false
    property bool showItemHoverBackground: true
    property bool iconReflectionEnabled: false
    property real iconReflectionOpacity: 0.22
    property real iconReflectionAvailableExtent: -1
    property bool animateEntry: false
    property bool positionTransitionEnabled: false
    property bool persistentReorderEnabled: false
    property bool persistentPointerReorderEnabled: false
    property bool persistentReorderActive: false
    property bool persistentReorderSource: false
    property bool persistentReorderTarget: false
    property bool persistentReorderInsertAfter: false
    property int persistentModelIndex: -1
    property bool suppressClickAfterReorder: false
    property bool taskPopupTracksVisualArea: false
    property real entryOpacity: 1.0
    property real entryScale: 1.0
    property bool positionAnimationReady: false
    property bool showPersistentLabel: false
    property bool textShadowsEnabled: true
    property bool calendarTextShadowsEnabled: true
    property int labelFontSize: Math.max(10, Math.round(iconSize * 0.22))
    property string indicatorType: "line"
    property string indicatorPosition: "bottom"
    property string indicatorColor: ""
    property int indicatorThickness: 4
    property real indicatorOpacity: 1.0
    property bool windowCountBadgeEnabled: false
    property string windowCountBadgePosition: "top-right"
    property bool windowGroupingEnabled: false
    property string windowCountEmblemColor: ""
    property real windowCountEmblemOpacity: 1.0
    property real windowCountEmblemScale: 1.0
    property var mediaController: null
    property int mediaMainAxisLength: Math.round(Math.max(120,
        Math.min(320, iconSize * 4.2)))
    property bool mediaMotionEnabled: true
    property bool mediaLaunchAvailable: false
    property string mediaDefaultPlayerName: ""
    property string mediaDefaultPlayerIcon: ""
    property string mediaTextMode: "automatic"
    property string mediaDisplayMode: "normal"
    property int mediaAutoCollapseDelaySeconds: 3
    property int dockMotionSpeedPercent: 100
    readonly property int resolvedDockMotionSpeedPercent: Math.max(50,
        Math.min(150, Number.isFinite(dockMotionSpeedPercent)
            ? Math.round(dockMotionSpeedPercent)
            : 100))
    readonly property int dockMotionDuration: Math.round(
        Kirigami.Units.longDuration * 100 / resolvedDockMotionSpeedPercent)
    readonly property int selectionPulseDuration: Math.max(1,
        Math.round(dockMotionDuration * 2.25))
    readonly property real selectionPulsePeakScale:
        Math.max(1.0, hoverScaleSetting)
    readonly property int resolvedMediaAutoCollapseDelaySeconds: Math.max(0,
        Math.min(30, Number.isFinite(mediaAutoCollapseDelaySeconds)
            ? Math.round(mediaAutoCollapseDelaySeconds)
            : 3))
    readonly property real mediaCurrentMainAxisLength: mediaItem
        ? mediaDockItem.currentMainAxisLength
        : mediaMainAxisLength
    property var layoutController: parent
    property int highQualityIconSize: {
        const targetSize = Math.ceil(iconSize * Math.max(1.0, hoverScaleSetting))
        if (targetSize <= iconSize) {
            return iconSize
        }
        if (targetSize <= 64 && iconSize < 64) return 64
        if (targetSize <= 96) return 96
        if (targetSize <= 128) return 128
        if (targetSize <= 256) return 256
        return Math.min(512, targetSize)
    }
    property real highQualityIconScale: highQualityIconSize > 0 ? iconSize / highQualityIconSize : 1
    readonly property real hoverScaleDelta: Math.max(0.0001, hoverScaleSetting - 1.0)
    readonly property real waveSharedScaleDelta: Math.min(0.50,
        Math.max(0.0, hoverScaleSetting - 1.0))
    readonly property real wavePrimaryScaleDelta: Math.max(0.0,
        hoverScaleSetting - 1.0 - waveSharedScaleDelta)
    readonly property real waveLayoutSpacing: {
        if (!layoutController) {
            return Kirigami.Units.smallSpacing
        }
        const value = verticalPanelMode
            ? Number(layoutController.rowSpacing)
            : Number(layoutController.columnSpacing)
        return Number.isFinite(value) && value >= 0
            ? value : Kirigami.Units.smallSpacing
    }
    readonly property real waveCanonicalItemExtent: verticalPanelMode
        ? iconSize + 12 + (showPersistentLabel ? labelFontSize + 12 : 0)
        : Math.max(iconSize + 12,
            showPersistentLabel ? Math.round(iconSize * 1.85) : 0)
    readonly property real waveItemPitch: Math.max(1,
        (structuralWaveItem
            ? waveCanonicalItemExtent
            : (verticalPanelMode ? height : width)) + waveLayoutSpacing)
    readonly property point waveMappedCenter: {
        // Mapping also depends on the delegate position inside its layout.
        dockItemContainer.x
        dockItemContainer.y
        return layoutController
            ? mapToItem(layoutController, width / 2, height / 2)
            : Qt.point(0, 0)
    }
    readonly property real waveItemCenter: verticalPanelMode
        ? waveMappedCenter.y : waveMappedCenter.x
    readonly property real waveInfluenceRadius: Math.max(iconSize * 3.0,
        waveItemPitch * 2.75)
    readonly property real iconReflectionMaximumVisibleRatio: 0.26
    readonly property real iconReflectionDisplaySize: iconSize * waveScale
    readonly property real iconReflectionContainerScale:
        clickAnimationScale * entryScale
    readonly property real iconReflectionBottomDisplacement:
        (((iconReflectionDisplaySize / 2) + hoverOffsetY)
            * iconReflectionContainerScale) - (iconSize / 2)
    readonly property real iconReflectionUsableExtent:
        iconReflectionAvailableExtent < 0
            ? iconReflectionDisplaySize * iconReflectionMaximumVisibleRatio
            : Math.max(0, iconReflectionAvailableExtent
                - iconReflectionBottomDisplacement)
    readonly property real iconReflectionVisibleRatio: Math.max(0,
        Math.min(iconReflectionMaximumVisibleRatio,
            iconReflectionUsableExtent / Math.max(1,
                iconReflectionDisplaySize * iconReflectionContainerScale)))
    readonly property real baseItemExtent: Math.max(iconSize, (verticalPanelMode ? implicitHeight : implicitWidth) - 12)
    readonly property real labelAreaHeight: showPersistentLabel
        && !separatorItem && !spacerItem && !mediaItem
        ? (labelFontSize + 12)
        : 0
    // Use direct values for separators/spacers in vertical mode to avoid
    // a circular binding (implicitHeight depends on visualAreaHeight).
    readonly property real visualAreaHeight: {
        if (mediaItem && verticalPanelMode) {
            return mediaCurrentMainAxisLength + 12
        }
        if ((separatorItem || spacerItem) && verticalPanelMode) {
            return separatorItem
                ? Math.max(10, Math.ceil(separatorThickness + 4))
                : Math.max(12, iconSize * 0.5)
        }
        return iconSize + 12
    }
    property real clickAnimationScale: 1.0
    property real waveScale: {
        if (itemType === "calendar" || itemType === "media"
                || structuralWaveItem) {
            return 1.0
        }

        if (hoverAnimationMode === "none") {
            return 1.0
        }

        if (hoverAnimationMode === "selectionPulse") {
            return selectionPulseScale
        }

        var activeIndex = hoveredIndex >= 0 ? hoveredIndex : lastHoveredIndex
        var pointerPosition = hoveredIndex >= 0
            ? Number(dockItemContainer.layoutController.pointerPrimaryAxis)
            : Number(dockItemContainer.layoutController.lastPointerPrimaryAxis)

        if (activeIndex === -1 || hoverZoomProgress <= 0.0) {
            return 1.0
        }

        if (Kirigami.Units.longDuration === 0) {
            // Under Reduce Motion, restrict wave zoom to subtle instant scale on active item only
            if (itemIndex === activeIndex) {
                return 1.0 + Math.min(0.08, (hoverScaleSetting - 1.0) * 0.25)
            }
            return 1.0
        }

        if (hoverAnimationMode === "single" || hoverAnimationMode === "axisZoom") {
            return itemIndex === activeIndex
                ? 1.0 + (hoverScaleSetting - 1.0) * hoverZoomProgress
                : 1.0
        }

        if (!Number.isFinite(pointerPosition) || pointerPosition < 0) {
            return 1.0
        }

        // Keep the original cosine wave, extending its reach by one item.
        var radius = waveInfluenceRadius
        var itemCenterPoint = dockItemContainer.mapToItem(
            dockItemContainer.layoutController,
            dockItemContainer.width / 2,
            dockItemContainer.height / 2)
        var itemCenter = verticalPanelMode ? itemCenterPoint.y : itemCenterPoint.x
        var distance = Math.abs(itemCenter - pointerPosition)
        if (distance >= radius) return 1.0

        // Organic smooth cosine wave curve (0.5 * (1 + cos(pi * d / r)))
        var normalizedDistance = distance / radius
        var influence = 0.5 * (1.0 + Math.cos(Math.PI * normalizedDistance))
        var scale = 1.0 + waveSharedScaleDelta
            * influence * hoverZoomProgress

        // Values above 150% reinforce only the item directly under the
        // pointer. The compact cosine reaches zero at half a cell, so the
        // extra peak transfers continuously without enlarging neighbours.
        const primaryRadius = waveItemPitch * 0.5
        if (wavePrimaryScaleDelta > 0.0 && distance < primaryRadius) {
            const primaryDistance = distance / primaryRadius
            const primaryInfluence = 0.5
                * (1.0 + Math.cos(Math.PI * primaryDistance))
            scale += wavePrimaryScaleDelta
                * primaryInfluence * hoverZoomProgress
        }
        return scale
    }

    readonly property real waveMainAxisShift: {
        if (hoverAnimationMode !== "wave" || hoverZoomProgress <= 0.0
                || !layoutController) {
            return 0.0
        }

        if (Kirigami.Units.longDuration === 0) {
            return 0.0
        }

        const pointerPosition = hoveredIndex >= 0
            ? Number(layoutController.pointerPrimaryAxis)
            : Number(layoutController.lastPointerPrimaryAxis)
        if (!Number.isFinite(pointerPosition) || pointerPosition < 0) {
            return 0.0
        }

        const signedDistance = waveItemCenter - pointerPosition
        const distance = Math.abs(signedDistance)
        if (distance < 0.001) {
            return 0.0
        }

        const normalizedDistance = Math.min(1.0,
            distance / waveInfluenceRadius)
        const integratedInfluence = waveInfluenceRadius
            * (0.5 * normalizedDistance
                + Math.sin(Math.PI * normalizedDistance) / (2.0 * Math.PI))
        const maximumExpansion = iconSize
            * waveSharedScaleDelta * hoverZoomProgress
        const shift = maximumExpansion * integratedInfluence / waveItemPitch
        const directionalShift = signedDistance < 0.0 ? -shift : shift
        return directionalShift
    }

    function updateWavePointer(localX, localY) {
        if (!layoutController || !Number.isFinite(Number(localX))
                || !Number.isFinite(Number(localY))) {
            return
        }
        const point = mapToItem(layoutController, Number(localX), Number(localY))
        const position = verticalPanelMode ? point.y : point.x
        layoutController.pointerPrimaryAxis = position
        layoutController.lastPointerPrimaryAxis = position
    }

    function shouldKeepWaveActiveAcrossLayoutGap() {
        if (hoverAnimationMode !== "wave" || !layoutController) {
            return false
        }
        try {
            return !!layoutController.wavePointerInsideLayout
        } catch (error) {
            return false
        }
    }

    function restartSelectionPulse() {
        selectionPulseAnimation.stop()
        selectionPulseScale = 1.0
        if (hoverAnimationMode !== "selectionPulse"
                || selectionPulsePeakScale <= 1.0
                || Kirigami.Units.longDuration === 0) {
            return
        }
        selectionPulseAnimation.start()
    }

    function resetSelectionPulse() {
        selectionPulseAnimation.stop()
        selectionPulseScale = 1.0
    }

    property bool inPanel: false
    property int panelLocation: PlasmaCore.Types.BottomEdge
    readonly property int tooltipLocation: {
        return panelLocation
    }
    readonly property real hoverTravel: {
        if (waveScale <= 1.0 || hoverAnimationMode === "axisZoom"
                || hoverAnimationMode === "selectionPulse") {
            return 0.0
        }
        if (hoverAnimationMode === "wave") {
            // Scaling is centered, so offset by exactly half of the growth to
            // keep the icon attached to the dock edge on either orientation.
            return iconSize * 0.5 * (waveScale - 1.0)
        }
        return Math.round(iconSize * 0.32
            * ((waveScale - 1.0) / hoverScaleDelta))
    }
    readonly property real hoverOffsetX: {
        if (!verticalPanelMode || hoverTravel <= 0.0) {
            return 0.0
        }
        if (panelLocation === PlasmaCore.Types.LeftEdge) {
            return hoverTravel
        }
        if (panelLocation === PlasmaCore.Types.RightEdge) {
            return -hoverTravel
        }
        return 0.0
    }
    readonly property real hoverOffsetY: {
        if (hoverTravel <= 0.0) {
            return 0.0
        }
        if (panelLocation === PlasmaCore.Types.TopEdge) {
            return hoverTravel
        }
        if (panelLocation === PlasmaCore.Types.BottomEdge) {
            return -hoverTravel
        }
        return !inPanel && !verticalPanelMode ? -hoverTravel : 0.0
    }

    property string itemType: "app"
    property string currentTime: "00:00"
    property string currentDate: "01/01"
    property int taskIndicatorCount: 0
    property bool taskIsActive: false
    property bool taskDemandsAttention: false
    property bool suppressTooltip: false
    property bool supportsContextMenu: false
    property bool mediaHoverControlsEnabled: false
    property bool externalDropEnabled: false
    property var externalDropValidator: null
    property bool launcherDropEnabled: false
    property var launcherDropValidator: null
    property bool launcherContainerDropTarget: false
    property bool launcherContainerDropEnabled: false
    property bool launcherDropInsertAfter: false
    property int launcherModelInsertionIndex: -1
    property string launcherDropApplicationName: ""
    property bool externalDropActivationEnabled: false
    property int externalDropActivationDelay: 250
    property var externalDropActivator: null
    property string externalDropState: "none"
    property real externalDropActivationProgress: 0
    property bool customSeparatorEnabled: false
    property var separatorTheme: ({})
    readonly property Item taskGeometryItem: taskGeometryProxy
    readonly property bool containsMouse: mouseArea.containsMouse
    readonly property bool separatorItem: itemType === "separator"
        || itemType === "dynamic-applications"
    readonly property bool spacerItem: itemType === "spacer"
    readonly property bool mediaItem: itemType === "media"
    readonly property bool overflowItem: itemType === "overflow"
    readonly property bool structuralWaveItem: separatorItem || spacerItem
    readonly property bool activeTaskItem: itemType === "app" && (taskIsActive || taskIndicatorCount > 0)
    readonly property bool supportsPopupSurface: supportsContextMenu
        || itemType === "app"
        || itemType === "folder"
        || itemType === "punchimenu"
        || itemType === "note"
        || itemType === "calendar"
        || itemType === "trash"
    readonly property bool isAnyPopupOrMenuOpen: {
        if (layoutController && layoutController.popupCoordinator) {
            const coordinator = layoutController.popupCoordinator
            const targetActive = coordinator.isPopupActiveForVisualParent
                && coordinator.isPopupActiveForVisualParent(dockItemContainer)
            const globalActive = !!coordinator.isAnyPopupActiveGlobally
            return targetActive || globalActive
        }
        return false
    }
    readonly property bool showAnyTooltip: false
    readonly property real requestedSeparatorThickness: customSeparatorEnabled
        ? Number(separatorTheme.thickness || 2)
        : 2
    readonly property real separatorThickness: Math.min(iconSize,
        requestedSeparatorThickness)
    readonly property var separatorGlow: separatorTheme.glow || ({})
    readonly property real requestedSeparatorGlowSize: customSeparatorEnabled
        ? Math.max(0, Number(separatorGlow.size || 0))
        : 0
    readonly property real separatorGlowSize: Math.min(
        requestedSeparatorGlowSize,
        Math.max(0, (iconSize - separatorThickness) / 2))
    readonly property real separatorBodyLengthLimit: Math.max(
        separatorThickness, iconSize - (separatorGlowSize * 2))
    readonly property real separatorLength: customSeparatorEnabled
        ? (String(separatorTheme.style || "line") === "dot"
            ? separatorThickness
            : Math.min(separatorBodyLengthLimit,
                Math.max(separatorThickness,
                    Math.round(iconSize
                        * Number(separatorTheme.lengthRatio || 0.72)))))
        : Math.max(20, Math.round(iconSize * 0.72))
    Timer {
        id: clockTimer
        interval: 1000
        running: dockItemContainer.itemType === "calendar"
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var date = new Date()
            var hh = String(date.getHours()).padStart(2, '0')
            var mm = String(date.getMinutes()).padStart(2, '0')
            var dd = String(date.getDate()).padStart(2, '0')
            var mo = String(date.getMonth() + 1).padStart(2, '0')
            dockItemContainer.currentTime = hh + ":" + mm
            dockItemContainer.currentDate = dd + "/" + mo
        }
    }

    Timer {
        id: minimizeStateEvaluationTimer
        interval: 0
        repeat: false
        onTriggered: {
            if (dockItemContainer.taskMinimizedTrackingReady
                    && dockItemContainer.taskIndicatorCount
                        === dockItemContainer.observedTaskCount
                    && dockItemContainer.taskMinimizedCount
                        > dockItemContainer.observedTaskMinimizedCount) {
                dockItemContainer.taskMinimized(dockItemContainer.itemIndex)
            }
            dockItemContainer.observedTaskCount = dockItemContainer.taskIndicatorCount
            dockItemContainer.observedTaskMinimizedCount
                = dockItemContainer.taskMinimizedCount
        }
    }

    signal itemClicked(string cmd)
    signal contextMenuRequested(var visualParent, bool keyboardInvoked)
    signal mediaControlsRequested(var visualParent)
    signal mediaExpansionChanged(bool expanded, int transitionDuration)
    signal hoverEntered(var visualParent)
    signal hoverExited(var visualParent)
    signal taskMinimized(int itemIndex)
    signal externalUrlsDropped(var urls, var visualParent)
    signal applicationLauncherDropped(var urls, int insertionIndex, var visualParent)
    signal applicationLauncherContainerDropped(var urls, var visualParent)
    signal persistentReorderPressStarted(var visualParent)
    signal persistentReorderStarted(int modelIndex, var visualParent)
    signal persistentReorderMoved(real x, real y)
    signal persistentReorderFinished()
    signal persistentReorderCanceled()
    signal persistentKeyboardMoveRequested(int modelIndex, int delta)
    signal mediaLaunchRequested()
    signal mediaPlaybackLaunchRequested()

    function focusItem() {
        if (dockItemContainer.mediaItem) {
            mediaDockItem.focusFirstControl()
        } else {
            mouseArea.forceActiveFocus(Qt.OtherFocusReason)
        }
    }

    function validateExternalDrop(urls) {
        if (!dockItemContainer.externalDropEnabled
                || typeof dockItemContainer.externalDropValidator !== "function") {
            return { "accepted": false, "errorCode": "applicationUnavailable" }
        }
        return dockItemContainer.externalDropValidator(urls || [])
    }

    function validateLauncherDrop(urls) {
        if (!dockItemContainer.launcherDropEnabled
                || typeof dockItemContainer.launcherDropValidator !== "function") {
            return { "accepted": false, "errorCode": "applicationUnavailable" }
        }
        return dockItemContainer.launcherDropValidator(urls || [])
    }

    function hasPunchiLauncherMarker(event) {
        return event && event.formats
            && event.formats.indexOf("application/x-punchi-launcher") >= 0
    }

    function mayContainApplicationLauncher(event) {
        if (!dockItemContainer.launcherDropEnabled || !event
                || !event.hasUrls) {
            return false
        }
        if (dockItemContainer.hasPunchiLauncherMarker(event)) {
            return true
        }
        const urls = event.urls || []
        return urls.length === 1
            && /\.desktop$/i.test(String(urls[0] || ""))
    }

    function isApplicationLauncherDrag(event, validation) {
        return dockItemContainer.launcherDropEnabled && event && event.hasUrls
            && (dockItemContainer.hasPunchiLauncherMarker(event)
                || (validation && validation.accepted))
    }

    function updateLauncherDropPosition(x, y) {
        dockItemContainer.launcherDropInsertAfter = dockItemContainer.verticalPanelMode
            ? y >= dockItemContainer.height / 2
            : x >= dockItemContainer.width / 2
    }

    function maintainLauncherDropAcceptance(event) {
        if (!event) {
            return false
        }
        const accepted = DockDropState.launcherDropAcceptance(
            dockItemContainer.externalDropState)
        if (accepted === undefined) {
            return false
        }
        event.accepted = accepted
        return accepted
    }

    function launcherInsertionIndex() {
        const baseIndex = dockItemContainer.launcherModelInsertionIndex >= 0
            ? dockItemContainer.launcherModelInsertionIndex
            : dockItemContainer.itemIndex
        return Math.max(0, baseIndex
            + (dockItemContainer.launcherDropInsertAfter ? 1 : 0))
    }

    function beginExternalDropActivation() {
        dockItemContainer.cancelExternalDropActivation()
        if (!dockItemContainer.externalDropActivationEnabled
                || typeof dockItemContainer.externalDropActivator !== "function") {
            return
        }
        dockItemContainer.externalDropState = "activationPending"
        externalDropActivationProgressAnimation.restart()
        externalDropActivationTimer.restart()
    }

    function cancelExternalDropActivation() {
        externalDropActivationTimer.stop()
        externalDropActivationProgressAnimation.stop()
        dockItemContainer.externalDropActivationProgress = 0
    }

    onExternalDropEnabledChanged: {
        if (!dockItemContainer.externalDropEnabled) {
            dockItemContainer.cancelExternalDropActivation()
            dockItemContainer.externalDropState = "none"
        }
    }

    readonly property bool verticalPanelMode: panelLocation === PlasmaCore.Types.LeftEdge
        || panelLocation === PlasmaCore.Types.RightEdge
    readonly property Item taskPopupAnchorItem: taskPopupTracksVisualArea
        ? visualArea : null
    readonly property bool launcherDropPlaceholderVisible:
        externalDropState === "launcherAcceptable"
    readonly property bool externalDropRejected:
        externalDropState === "rejected"
        || externalDropState === "launcherContainmentRejected"
    readonly property real launcherDropLayoutSpacing: {
        if (!layoutController) {
            return Kirigami.Units.smallSpacing
        }
        const value = verticalPanelMode
            ? Number(layoutController.rowSpacing)
            : Number(layoutController.columnSpacing)
        return Number.isFinite(value) && value >= 0
            ? value : Kirigami.Units.smallSpacing
    }
    readonly property real launcherDropPlaceholderMainExtent: verticalPanelMode
        ? Math.max(iconSize + 12, visualAreaHeight + labelAreaHeight)
        : Math.max(iconSize + 12,
            showPersistentLabel ? Math.round(iconSize * 1.85) : 0)
    readonly property real launcherDropReservedExtent:
        launcherDropPlaceholderMainExtent + launcherDropLayoutSpacing

    Layout.leftMargin: launcherDropPlaceholderVisible
        && !verticalPanelMode && !launcherDropInsertAfter
        ? launcherDropReservedExtent : 0
    Layout.rightMargin: launcherDropPlaceholderVisible
        && !verticalPanelMode && launcherDropInsertAfter
        ? launcherDropReservedExtent : 0
    Layout.topMargin: launcherDropPlaceholderVisible
        && verticalPanelMode && !launcherDropInsertAfter
        ? launcherDropReservedExtent : 0
    Layout.bottomMargin: launcherDropPlaceholderVisible
        && verticalPanelMode && launcherDropInsertAfter
        ? launcherDropReservedExtent : 0

    // Keep layout container measurements fully static to prevent jitter.
    implicitWidth: verticalPanelMode
        ? Math.max(iconSize + 12, !mediaItem && showPersistentLabel ? Math.round(iconSize * 1.85) : 0)
        : (separatorItem
            ? Math.max(10, Math.ceil(separatorThickness + 4))
            : (spacerItem
                ? Math.max(12, iconSize * 0.5)
                : (mediaItem
                    ? mediaCurrentMainAxisLength + 12
                    : Math.max(iconSize + 12,
                        showPersistentLabel ? Math.round(iconSize * 1.85) : 0))))
    implicitHeight: verticalPanelMode
        ? (separatorItem
            ? Math.max(10, Math.ceil(separatorThickness + 4))
            : (spacerItem
                ? Math.max(12, iconSize * 0.5)
                : (mediaItem
                    ? mediaCurrentMainAxisLength + 12
                    : (visualAreaHeight + labelAreaHeight))))
        : (visualAreaHeight + labelAreaHeight)
    opacity: entryOpacity * (persistentReorderSource ? 0.28 : 1.0)

    Behavior on x {
        enabled: dockItemContainer.positionAnimationReady
            && (dockItemContainer.positionTransitionEnabled
                || (dockItemContainer.layoutController
                    && (dockItemContainer.layoutController.mediaMorphActive
                        || (dockItemContainer.layoutController.launcherDropTransitionActive
                            && Kirigami.Units.longDuration > 0))))
        NumberAnimation {
            duration: dockItemContainer.dockMotionDuration
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on y {
        enabled: dockItemContainer.positionAnimationReady
            && (dockItemContainer.positionTransitionEnabled
                || (dockItemContainer.layoutController
                    && (dockItemContainer.layoutController.mediaMorphActive
                        || (dockItemContainer.layoutController.launcherDropTransitionActive
                            && Kirigami.Units.longDuration > 0))))
        NumberAnimation {
            duration: dockItemContainer.dockMotionDuration
            easing.type: Easing.InOutCubic
        }
    }

    Component.onCompleted: {
        dockItemContainer.observedTaskCount = dockItemContainer.taskIndicatorCount
        dockItemContainer.observedTaskMinimizedCount
            = dockItemContainer.taskMinimizedCount
        if (dockItemContainer.animateEntry) {
            dockItemContainer.entryOpacity = 0.0
            dockItemContainer.entryScale = 0.88
            entryAnimation.restart()
        }
        Qt.callLater(function() {
            dockItemContainer.positionAnimationReady = true
            dockItemContainer.taskMinimizedTrackingReady = true
        })
    }

    onTaskIndicatorCountChanged: minimizeStateEvaluationTimer.restart()
    onTaskMinimizedCountChanged: minimizeStateEvaluationTimer.restart()

    MinimizeItemReaction {
        id: minimizeItemReaction
        mode: dockItemContainer.windowMinimizeEffect
        itemIndex: dockItemContainer.itemIndex
        targetIndex: dockItemContainer.minimizeReactionTargetIndex
        revision: dockItemContainer.minimizeReactionRevision
        iconSize: dockItemContainer.iconSize
        verticalPanel: dockItemContainer.verticalPanelMode
        bounceDirection: dockItemContainer.panelLocation === PlasmaCore.Types.RightEdge
            || dockItemContainer.panelLocation === PlasmaCore.Types.BottomEdge
            ? -1
            : 1
        reactionEnabled: !dockItemContainer.separatorItem
            && !dockItemContainer.spacerItem
    }

    ParallelAnimation {
        id: entryAnimation

        NumberAnimation {
            target: dockItemContainer
            property: "entryOpacity"
            to: 1.0
            duration: dockItemContainer.dockMotionDuration
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: dockItemContainer
            property: "entryScale"
            to: 1.0
            duration: dockItemContainer.dockMotionDuration
            easing.type: Easing.OutCubic
        }
    }

    Item {
        id: hoverBackground
        anchors.fill: parent
        readonly property bool pointerHighlighted: mouseArea.containsMouse
            || (dockItemContainer.hoverAnimationMode === "wave"
                && dockItemContainer.hoveredIndex
                    === dockItemContainer.itemIndex)
        visible: dockItemContainer.showItemHoverBackground
            && !dockItemContainer.separatorItem
            && !dockItemContainer.spacerItem
            && !dockItemContainer.mediaItem
            && dockItemContainer.itemType !== "calendar"
        transformOrigin: Item.Center
        scale: dockItemContainer.waveScale
        transform: Translate {
            x: dockItemContainer.hoverOffsetX
                + (dockItemContainer.hoverAnimationMode === "wave"
                    && !dockItemContainer.verticalPanelMode
                    ? dockItemContainer.waveMainAxisShift : 0.0)
            y: dockItemContainer.hoverOffsetY
                + (dockItemContainer.hoverAnimationMode === "wave"
                    && dockItemContainer.verticalPanelMode
                    ? dockItemContainer.waveMainAxisShift : 0.0)
        }

        PunchiMenuComponents.PunchiMenuItemHighlight {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            hovered: hoverBackground.pointerHighlighted
            selected: hoverBackground.pointerHighlighted
            focused: mouseArea.activeFocus
            pressed: mouseArea.pressed
            motionEnabled: Kirigami.Units.longDuration > 0
        }
    }

    Rectangle {
        id: persistentReorderInsertionIndicator
        z: 9
        visible: dockItemContainer.persistentReorderTarget
        radius: Math.min(width, height) / 2
        color: Kirigami.Theme.highlightColor
        width: dockItemContainer.verticalPanelMode
            ? Math.max(12, dockItemContainer.width * 0.72)
            : Math.max(3, Math.round(Kirigami.Units.smallSpacing / 2))
        height: dockItemContainer.verticalPanelMode
            ? Math.max(3, Math.round(Kirigami.Units.smallSpacing / 2))
            : Math.max(12, dockItemContainer.height * 0.72)
        x: dockItemContainer.verticalPanelMode
            ? Math.round((dockItemContainer.width - width) / 2)
            : (dockItemContainer.persistentReorderInsertAfter
                ? dockItemContainer.width - width / 2 : -width / 2)
        y: dockItemContainer.verticalPanelMode
            ? (dockItemContainer.persistentReorderInsertAfter
                ? dockItemContainer.height - height / 2 : -height / 2)
            : Math.round((dockItemContainer.height - height) / 2)
    }

    Rectangle {
        z: 8
        anchors.fill: parent
        visible: dockItemContainer.externalDropState !== "none"
            && dockItemContainer.externalDropState !== "launcherAcceptable"
        radius: 8
        color: !dockItemContainer.externalDropRejected
            ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                Kirigami.Theme.highlightColor.g,
                Kirigami.Theme.highlightColor.b, 0.22)
            : Qt.rgba(Kirigami.Theme.negativeTextColor.r,
                Kirigami.Theme.negativeTextColor.g,
                Kirigami.Theme.negativeTextColor.b, 0.18)
        border.width: 2
        border.color: !dockItemContainer.externalDropRejected
            ? Kirigami.Theme.highlightColor
            : Kirigami.Theme.negativeTextColor

        Kirigami.Icon {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 3
            width: Math.max(14, dockItemContainer.iconSize * 0.34)
            height: width
            source: dockItemContainer.externalDropRejected
                ? "dialog-warning-symbolic"
                : (dockItemContainer.externalDropState === "activated"
                    ? "go-up-symbolic"
                    : (dockItemContainer.externalDropState
                            === "launcherContainmentAcceptable"
                        ? "folder-add-symbolic" : "document-open-symbolic"))
        }

        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: parent.width * dockItemContainer.externalDropActivationProgress
            height: Math.max(2, Math.round(Kirigami.Units.smallSpacing / 2))
            visible: dockItemContainer.externalDropState === "activationPending"
            radius: height / 2
            color: Kirigami.Theme.highlightedTextColor
        }
    }

    Rectangle {
        id: launcherDropPlaceholder
        z: 9
        visible: dockItemContainer.launcherDropPlaceholderVisible
        color: Qt.rgba(Kirigami.Theme.highlightColor.r,
            Kirigami.Theme.highlightColor.g,
            Kirigami.Theme.highlightColor.b, 0.22)
        radius: 8
        border.width: 2
        border.color: Kirigami.Theme.highlightColor
        width: dockItemContainer.verticalPanelMode
            ? dockItemContainer.width
            : dockItemContainer.launcherDropPlaceholderMainExtent
        height: dockItemContainer.verticalPanelMode
            ? dockItemContainer.launcherDropPlaceholderMainExtent
            : dockItemContainer.height
        x: dockItemContainer.verticalPanelMode
            ? Math.round((dockItemContainer.width - width) / 2)
            : (dockItemContainer.launcherDropInsertAfter
                ? dockItemContainer.width
                    + dockItemContainer.launcherDropLayoutSpacing / 2
                : -dockItemContainer.launcherDropReservedExtent
                    + dockItemContainer.launcherDropLayoutSpacing / 2)
        y: dockItemContainer.verticalPanelMode
            ? (dockItemContainer.launcherDropInsertAfter
                ? dockItemContainer.height
                    + dockItemContainer.launcherDropLayoutSpacing / 2
                : -dockItemContainer.launcherDropReservedExtent
                    + dockItemContainer.launcherDropLayoutSpacing / 2)
            : Math.round((dockItemContainer.height - height) / 2)
        Accessible.ignored: true

        Kirigami.Icon {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 3
            width: Math.max(14, dockItemContainer.iconSize * 0.34)
            height: width
            source: "list-add-symbolic"
            color: Kirigami.Theme.highlightColor
            Accessible.ignored: true
        }
    }

    NumberAnimation {
        id: externalDropActivationProgressAnimation
        target: dockItemContainer
        property: "externalDropActivationProgress"
        from: 0
        to: 1
        duration: dockItemContainer.externalDropActivationDelay
        easing.type: Easing.Linear
    }

    Timer {
        id: externalDropActivationTimer
        interval: dockItemContainer.externalDropActivationDelay
        repeat: false
        onTriggered: {
            const activated = typeof dockItemContainer.externalDropActivator === "function"
                && dockItemContainer.externalDropActivator()
            dockItemContainer.externalDropActivationProgress = activated ? 1 : 0
            dockItemContainer.externalDropState = activated ? "activated" : "acceptable"
        }
    }

    Item {
        id: visualArea
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: dockItemContainer.visualAreaHeight
        scale: dockItemContainer.clickAnimationScale * dockItemContainer.entryScale
        transform: Translate {
            x: minimizeItemReaction.horizontalOffset
                + (dockItemContainer.verticalPanelMode
                    ? 0.0 : dockItemContainer.waveMainAxisShift)
            y: minimizeItemReaction.verticalOffset
                + (dockItemContainer.verticalPanelMode
                    ? dockItemContainer.waveMainAxisShift : 0.0)
        }

        IconReflection {
            id: iconReflection
            z: 0
            active: dockItemContainer.iconReflectionEnabled
                && dockItemContainer.iconReflectionVisibleRatio > 0.025
                && dockItemContainer.itemType !== "calendar"
                && !dockItemContainer.separatorItem
                && !dockItemContainer.spacerItem
                && !dockItemContainer.mediaItem
            iconSource: dockItemContainer.iconName
            displaySize: dockItemContainer.iconReflectionDisplaySize
            visibleRatio: dockItemContainer.iconReflectionVisibleRatio
            horizontalOffset: dockItemContainer.hoverOffsetX
            opacity: Math.max(0.05, Math.min(0.50,
                dockItemContainer.iconReflectionOpacity))
            width: parent.width
            height: Math.max(1, displaySize
                * (sourceOverlapRatio + visibleRatio))
            x: 0
            y: (parent.height / 2) + (displaySize / 2)
                + dockItemContainer.hoverOffsetY - sourceOverlap
        }

        Item {
            id: overflowTile
            z: 1
            anchors.centerIn: parent
            width: dockItemContainer.iconSize
            height: width
            visible: dockItemContainer.overflowItem
            transformOrigin: Item.Center
            scale: dockItemContainer.waveScale
            transform: Translate {
                x: dockItemContainer.hoverOffsetX
                y: dockItemContainer.hoverOffsetY
            }
            Accessible.ignored: true

            Rectangle {
                id: overflowTileBackground
                anchors.fill: parent
                radius: Kirigami.Units.cornerRadius * 1.5
                color: Kirigami.Theme.highlightColor
                opacity: mouseArea.containsMouse || mouseArea.activeFocus
                    ? 1.0 : 0.82
                Accessible.ignored: true
            }

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Math.max(16, dockItemContainer.iconSize * 0.48)
                height: width
                source: dockItemContainer.iconName
                color: Kirigami.Theme.highlightedTextColor
                Accessible.ignored: true
            }
        }

        Kirigami.Icon {
            id: itemIcon
            z: 1
            anchors.centerIn: parent
            width: dockItemContainer.highQualityIconSize
            height: dockItemContainer.highQualityIconSize
            source: dockItemContainer.iconName
            visible: dockItemContainer.itemType !== "calendar" && !dockItemContainer.separatorItem && !dockItemContainer.spacerItem
                && !dockItemContainer.overflowItem
                && !dockItemContainer.mediaItem

            scale: dockItemContainer.highQualityIconScale * dockItemContainer.waveScale
            transform: Translate {
                x: dockItemContainer.hoverOffsetX
                y: dockItemContainer.hoverOffsetY
            }
        }

        Column {
            id: calendarText
            anchors.centerIn: parent
            visible: dockItemContainer.itemType === "calendar"
            spacing: 1

            scale: dockItemContainer.waveScale
            transform: Translate {
                x: dockItemContainer.hoverOffsetX
                y: dockItemContainer.hoverOffsetY
            }

            PlasmaExtras.ShadowedLabel {
                text: dockItemContainer.currentTime
                renderShadow: dockItemContainer.calendarTextShadowsEnabled
                font.pixelSize: Math.round(14 * dockItemContainer.timeTextScale)
                font.weight: Font.Normal
                anchors.horizontalCenter: parent.horizontalCenter
            }

            PlasmaExtras.ShadowedLabel {
                text: dockItemContainer.currentDate
                renderShadow: dockItemContainer.calendarTextShadowsEnabled
                font.pixelSize: Math.round(9 * dockItemContainer.dateTextScale)
                opacity: 0.68
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        ThemedSeparator {
            visible: dockItemContainer.separatorItem
                && dockItemContainer.separatorVisibleSetting
            anchors.centerIn: parent
            theme: dockItemContainer.customSeparatorEnabled
                ? dockItemContainer.separatorTheme : ({})
            verticalPanel: dockItemContainer.verticalPanelMode
            availableLength: dockItemContainer.verticalPanelMode
                ? visualArea.width : visualArea.height
            style: dockItemContainer.customSeparatorEnabled && dockItemContainer.separatorTheme.style ? dockItemContainer.separatorTheme.style : dockItemContainer.separatorStyleSetting
            thickness: dockItemContainer.customSeparatorEnabled && dockItemContainer.separatorTheme.thickness ? dockItemContainer.separatorTheme.thickness : dockItemContainer.separatorThicknessSetting
            lengthRatio: dockItemContainer.customSeparatorEnabled && dockItemContainer.separatorTheme.lengthRatio ? dockItemContainer.separatorTheme.lengthRatio : dockItemContainer.separatorLengthRatioSetting
            customOpacity: dockItemContainer.separatorOpacitySetting
            glowEnabled: dockItemContainer.separatorGlowSetting || (dockItemContainer.customSeparatorEnabled && dockItemContainer.separatorGlowSize > 0)
        }

        TaskIndicator {
            z: 2
            anchors.centerIn: parent
            width: dockItemContainer.iconSize
            height: dockItemContainer.iconSize
            visible: dockItemContainer.itemType === "app"
                && dockItemContainer.taskIndicatorCount > 0
            count: dockItemContainer.taskIndicatorCount
            active: dockItemContainer.taskIsActive
            demandsAttention: dockItemContainer.taskDemandsAttention
            type: dockItemContainer.indicatorType
            position: dockItemContainer.effectiveIndicatorPosition
            customColor: dockItemContainer.indicatorColor.length > 0
                ? dockItemContainer.indicatorColor
                : "transparent"
            thickness: dockItemContainer.indicatorThickness
            indicatorOpacity: dockItemContainer.indicatorOpacity
            iconSize: dockItemContainer.iconSize
            transformOrigin: Item.Center
            scale: dockItemContainer.waveScale
            transform: Translate {
                x: dockItemContainer.hoverOffsetX
                y: dockItemContainer.hoverOffsetY
            }
        }

        WindowCountBadge {
            z: 3
            anchors.fill: parent
            count: dockItemContainer.taskIndicatorCount
            iconSize: dockItemContainer.iconSize
            demandsAttention: dockItemContainer.taskDemandsAttention
            badgeEnabled: dockItemContainer.windowCountBadgeEnabled
            groupingEnabled: dockItemContainer.windowGroupingEnabled
            position: dockItemContainer.windowCountBadgePosition
            emblemColor: dockItemContainer.windowCountEmblemColor
            emblemOpacity: dockItemContainer.windowCountEmblemOpacity
            emblemScale: dockItemContainer.windowCountEmblemScale
        }

        MediaDockItem {
            id: mediaDockItem
            anchors.centerIn: parent
            width: dockItemContainer.verticalPanelMode
                ? dockItemContainer.iconSize
                : currentMainAxisLength
            height: dockItemContainer.verticalPanelMode
                ? currentMainAxisLength
                : dockItemContainer.iconSize
            visible: dockItemContainer.mediaItem
            controller: dockItemContainer.mediaController
            iconSize: dockItemContainer.iconSize
            vertical: dockItemContainer.verticalPanelMode
            motionEnabled: dockItemContainer.mediaMotionEnabled
            motionSpeedPercent: dockItemContainer.resolvedDockMotionSpeedPercent
            autoCollapseDelaySeconds: dockItemContainer.resolvedMediaAutoCollapseDelaySeconds
            contextMenuEnabled: dockItemContainer.supportsContextMenu
            launchAvailable: dockItemContainer.mediaLaunchAvailable
            defaultPlayerName: dockItemContainer.mediaDefaultPlayerName
            defaultPlayerIcon: dockItemContainer.mediaDefaultPlayerIcon
            textMode: dockItemContainer.mediaTextMode
            displayMode: dockItemContainer.mediaDisplayMode
            expandedMainAxisLength: dockItemContainer.mediaMainAxisLength
            onLaunchRequested: dockItemContainer.mediaLaunchRequested()
            onPlaybackLaunchRequested: dockItemContainer.mediaPlaybackLaunchRequested()
            onContextMenuRequested: function(keyboardInvoked) {
                dockItemContainer.contextMenuRequested(dockItemContainer, keyboardInvoked)
            }
            onHoverChanged: function(hovered) {
                if (hovered) {
                    dockItemContainer.layoutController.hoveredIndex = dockItemContainer.itemIndex
                    const centerPoint = dockItemContainer.mapToItem(
                        dockItemContainer.layoutController,
                        dockItemContainer.width / 2,
                        dockItemContainer.height / 2)
                    const center = dockItemContainer.verticalPanelMode
                        ? centerPoint.y
                        : centerPoint.x
                    dockItemContainer.layoutController.pointerPrimaryAxis = center
                    dockItemContainer.layoutController.lastPointerPrimaryAxis = center
                } else if (dockItemContainer.layoutController.hoveredIndex === dockItemContainer.itemIndex) {
                    dockItemContainer.layoutController.hoveredIndex = -1
                }
            }
            onExpansionChanged: function(expanded, transitionDuration) {
                dockItemContainer.mediaExpansionChanged(expanded, transitionDuration)
            }
        }
    }

    Item {
        id: taskGeometryProxy
        anchors.fill: visualArea
    }

    PlasmaExtras.ShadowedLabel {
        id: persistentLabel
        visible: dockItemContainer.showPersistentLabel && !dockItemContainer.separatorItem && !dockItemContainer.spacerItem
            && !dockItemContainer.mediaItem
        anchors.top: visualArea.bottom
        anchors.topMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 6
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: dockItemContainer.localizedItemName
        renderShadow: dockItemContainer.textShadowsEnabled
        font.pixelSize: dockItemContainer.labelFontSize
        opacity: mouseArea.containsMouse || dockItemContainer.taskIsActive ? 1.0 : 0.88
        transform: Translate {
            x: dockItemContainer.verticalPanelMode
                ? 0.0 : dockItemContainer.waveMainAxisShift
            y: dockItemContainer.verticalPanelMode
                ? dockItemContainer.waveMainAxisShift : 0.0
        }
    }

    SequentialAnimation {
        id: selectionPulseAnimation
        running: false

        NumberAnimation {
            target: dockItemContainer
            property: "selectionPulseScale"
            to: dockItemContainer.selectionPulsePeakScale
            duration: Math.round(dockItemContainer.selectionPulseDuration * 0.45)
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: dockItemContainer
            property: "selectionPulseScale"
            to: 0.97
            duration: Math.round(dockItemContainer.selectionPulseDuration * 0.25)
            easing.type: Easing.InOutCubic
        }

        NumberAnimation {
            target: dockItemContainer
            property: "selectionPulseScale"
            to: 1.0
            duration: Math.round(dockItemContainer.selectionPulseDuration * 0.30)
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: clickPulseAnimation
        running: false
        PropertyAnimation {
            target: dockItemContainer
            property: "clickAnimationScale"
            to: 0.9
            duration: 55
            easing.type: Easing.OutCubic
        }
        PropertyAnimation {
            target: dockItemContainer
            property: "clickAnimationScale"
            to: 1.0
            duration: 140
            easing.type: Easing.OutBack
        }
    }

    SequentialAnimation {
        id: clickBounceAnimation
        running: false
        PropertyAnimation {
            target: dockItemContainer
            property: "clickAnimationScale"
            to: 0.92
            duration: 45
            easing.type: Easing.OutQuad
        }
        PropertyAnimation {
            target: dockItemContainer
            property: "clickAnimationScale"
            to: 1.08
            duration: 110
            easing.type: Easing.OutQuad
        }
        PropertyAnimation {
            target: dockItemContainer
            property: "clickAnimationScale"
            to: 1.0
            duration: 130
            easing.type: Easing.OutBack
        }
    }

    SequentialAnimation {
        id: clickPressAnimation
        running: false
        PropertyAnimation {
            target: dockItemContainer
            property: "clickAnimationScale"
            to: 0.86
            duration: 60
            easing.type: Easing.OutCubic
        }
        PropertyAnimation {
            target: dockItemContainer
            property: "clickAnimationScale"
            to: 1.0
            duration: 95
            easing.type: Easing.OutCubic
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: !dockItemContainer.mediaItem
        hoverEnabled: !dockItemContainer.persistentReorderActive
            && !dockItemContainer.separatorItem
            && !dockItemContainer.spacerItem
        activeFocusOnTab: true
        preventStealing: dockItemContainer.persistentReorderSource
        cursorShape: dockItemContainer.persistentReorderSource
            ? Qt.ClosedHandCursor : Qt.ArrowCursor
        Accessible.role: (dockItemContainer.separatorItem || dockItemContainer.spacerItem)
                && !dockItemContainer.persistentReorderEnabled
            ? Accessible.StaticText : Accessible.Button
        Accessible.name: dockItemContainer.localizedItemName
        // qmllint disable unqualified
        Accessible.description: {
            if (dockItemContainer.externalDropState === "activationPending") {
                return i18nc("@info:accessible", "Keep holding to bring %1 to the front",
                    dockItemContainer.localizedItemName)
            }
            if (dockItemContainer.externalDropState === "activated") {
                return i18nc("@info:accessible", "%1 is now in front; release to open the local files",
                    dockItemContainer.localizedItemName)
            }
            if (dockItemContainer.externalDropState === "acceptable") {
                return i18nc("@info:accessible", "Release to open local files with %1",
                    dockItemContainer.localizedItemName)
            }
            if (dockItemContainer.externalDropState === "launcherAcceptable") {
                return i18nc("@info:accessible", "Release to insert %1 in the Dock",
                    dockItemContainer.launcherDropApplicationName.length > 0
                        ? dockItemContainer.launcherDropApplicationName
                        : i18n("Application"))
            }
            if (dockItemContainer.externalDropState
                    === "launcherContainmentAcceptable") {
                return i18nc("@info:accessible", "Release to add %1 to %2",
                    dockItemContainer.launcherDropApplicationName.length > 0
                        ? dockItemContainer.launcherDropApplicationName
                        : i18n("Application"),
                    dockItemContainer.localizedItemName)
            }
            if (dockItemContainer.externalDropState
                    === "launcherContainmentRejected") {
                return i18nc("@info:accessible",
                    "%1 is updated automatically and cannot accept applications",
                    dockItemContainer.localizedItemName)
            }
            if (dockItemContainer.externalDropRejected) {
                return i18nc("@info:accessible", "This file drop cannot be accepted")
            }
            if (dockItemContainer.persistentPointerReorderEnabled) {
                return i18nc("@info:accessible",
                    "Press and hold to move this Dock item. Use Control+Shift with an arrow key to move it from the keyboard.")
            }
            if (dockItemContainer.persistentReorderEnabled) {
                return i18nc("@info:accessible",
                    "Use Control+Shift with an arrow key to move this Dock item.")
            }
            if (dockItemContainer.windowCountBadgeEnabled
                    && dockItemContainer.windowGroupingEnabled
                    && dockItemContainer.taskIndicatorCount >= 2) {
                if (dockItemContainer.mediaHoverControlsEnabled) {
                    return i18np("%1 open window. Press M to open media controls.",
                        "%1 open windows. Press M to open media controls.",
                        dockItemContainer.taskIndicatorCount)
                }
                return i18np("%1 open window", "%1 open windows",
                    dockItemContainer.taskIndicatorCount)
            }
            return dockItemContainer.mediaHoverControlsEnabled
                ? i18nc("@info:accessible", "Press M to open media controls")
                : ""
        }
        // qmllint enable unqualified
        acceptedButtons: (dockItemContainer.separatorItem || dockItemContainer.spacerItem)
                && !dockItemContainer.persistentReorderEnabled
            ? Qt.NoButton
            : ((dockItemContainer.itemType === "trash" || dockItemContainer.supportsContextMenu)
                ? Qt.LeftButton | Qt.RightButton
                : Qt.LeftButton)
        
        onContainsMouseChanged: {
            if (dockItemContainer.separatorItem || dockItemContainer.spacerItem || dockItemContainer.itemType === "calendar") {
                if (!containsMouse && dockItemContainer.layoutController.hoveredIndex === dockItemContainer.itemIndex) {
                    dockItemContainer.layoutController.hoveredIndex = -1
                    dockItemContainer.layoutController.mouseOffset = 0.0
                }
                return
            }
            if (containsMouse) {
                dockItemContainer.restartSelectionPulse()
                dockItemContainer.layoutController.hoveredIndex = dockItemContainer.itemIndex
                dockItemContainer.updateWavePointer(
                    mouseArea.mouseX, mouseArea.mouseY)
                dockItemContainer.hoverEntered(dockItemContainer)
            } else if (dockItemContainer.layoutController.hoveredIndex === dockItemContainer.itemIndex) {
                dockItemContainer.resetSelectionPulse()
                if (!dockItemContainer.shouldKeepWaveActiveAcrossLayoutGap()) {
                    dockItemContainer.layoutController.hoveredIndex = -1
                    dockItemContainer.layoutController.mouseOffset = 0.0
                }
                dockItemContainer.hoverExited(dockItemContainer)
            } else {
                dockItemContainer.resetSelectionPulse()
                dockItemContainer.hoverExited(dockItemContainer)
            }
        }
        
        onPositionChanged: function(mouse) {
            if (dockItemContainer.persistentReorderSource && pressed) {
                dockItemContainer.persistentReorderMoved(mouse.x, mouse.y)
            }
            if (dockItemContainer.separatorItem || dockItemContainer.spacerItem || dockItemContainer.itemType === "calendar") {
                return
            }
            if (containsMouse) {
                dockItemContainer.updateWavePointer(mouse.x, mouse.y)
            }
        }

        onPressed: function(mouse) {
            if (mouse.button === Qt.LeftButton
                    && dockItemContainer.persistentPointerReorderEnabled
                    && !dockItemContainer.persistentReorderActive) {
                dockItemContainer.persistentReorderPressStarted(
                    dockItemContainer)
            }
            if (mouse.button === Qt.RightButton) {
                dockItemContainer.contextMenuRequested(dockItemContainer, false)
            }
        }

        onPressAndHold: function(mouse) {
            if (mouse.button !== Qt.LeftButton
                    || !dockItemContainer.persistentPointerReorderEnabled
                    || dockItemContainer.persistentReorderActive) {
                return
            }
            dockItemContainer.persistentReorderStarted(
                dockItemContainer.persistentModelIndex, dockItemContainer)
            if (dockItemContainer.persistentReorderSource) {
                dockItemContainer.suppressClickAfterReorder = true
                mouse.accepted = true
                mouseArea.forceActiveFocus(Qt.MouseFocusReason)
                dockItemContainer.persistentReorderMoved(mouse.x, mouse.y)
            }
        }

        onReleased: {
            if (dockItemContainer.persistentReorderSource) {
                dockItemContainer.persistentReorderFinished()
            }
        }

        onCanceled: {
            if (dockItemContainer.persistentReorderSource) {
                dockItemContainer.persistentReorderCanceled()
            }
        }
        
        onClicked: function(mouse) {
            if (dockItemContainer.suppressClickAfterReorder) {
                dockItemContainer.suppressClickAfterReorder = false
                return
            }
            if (dockItemContainer.separatorItem || dockItemContainer.spacerItem) {
                return
            }
            if (mouse.button === Qt.RightButton) {
                return
            }
            if (dockItemContainer.clickEffect === "pulse") {
                clickPulseAnimation.restart()
            } else if (dockItemContainer.clickEffect === "bounce") {
                clickBounceAnimation.restart()
            } else if (dockItemContainer.clickEffect === "press") {
                clickPressAnimation.restart()
            }
            dockItemContainer.itemClicked(dockItemContainer.itemCommand)
        }
        Keys.onReturnPressed: if (!dockItemContainer.separatorItem && !dockItemContainer.spacerItem) dockItemContainer.itemClicked(dockItemContainer.itemCommand)
        Keys.onSpacePressed: if (!dockItemContainer.separatorItem && !dockItemContainer.spacerItem) dockItemContainer.itemClicked(dockItemContainer.itemCommand)
        Keys.onPressed: function(event) {
            if (dockItemContainer.persistentReorderSource
                    && event.key === Qt.Key_Escape) {
                dockItemContainer.suppressClickAfterReorder = true
                dockItemContainer.persistentReorderCanceled()
                event.accepted = true
                return
            }
            const reorderModifiers = Qt.ControlModifier | Qt.ShiftModifier
            if (dockItemContainer.persistentReorderEnabled
                    && event.modifiers === reorderModifiers) {
                const previousKey = dockItemContainer.verticalPanelMode
                    ? Qt.Key_Up : Qt.Key_Left
                const nextKey = dockItemContainer.verticalPanelMode
                    ? Qt.Key_Down : Qt.Key_Right
                if (event.key === previousKey || event.key === nextKey) {
                    dockItemContainer.persistentKeyboardMoveRequested(
                        dockItemContainer.persistentModelIndex,
                        event.key === previousKey ? -1 : 1)
                    event.accepted = true
                    return
                }
            }
            if (dockItemContainer.mediaHoverControlsEnabled
                    && event.key === Qt.Key_M
                    && event.modifiers === Qt.NoModifier) {
                dockItemContainer.mediaControlsRequested(dockItemContainer)
                event.accepted = true
                return
            }
            if ((dockItemContainer.itemType === "trash" || dockItemContainer.supportsContextMenu) && (event.key === Qt.Key_Menu
                    || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier)))) {
                dockItemContainer.contextMenuRequested(dockItemContainer, true)
                event.accepted = true
            }
        }
    }

    DropArea {
        id: externalDropArea
        anchors.fill: parent
        anchors.leftMargin: dockItemContainer.launcherDropPlaceholderVisible
            && !dockItemContainer.verticalPanelMode
            && !dockItemContainer.launcherDropInsertAfter
            ? -dockItemContainer.launcherDropReservedExtent : 0
        anchors.rightMargin: dockItemContainer.launcherDropPlaceholderVisible
            && !dockItemContainer.verticalPanelMode
            && dockItemContainer.launcherDropInsertAfter
            ? -dockItemContainer.launcherDropReservedExtent : 0
        anchors.topMargin: dockItemContainer.launcherDropPlaceholderVisible
            && dockItemContainer.verticalPanelMode
            && !dockItemContainer.launcherDropInsertAfter
            ? -dockItemContainer.launcherDropReservedExtent : 0
        anchors.bottomMargin: dockItemContainer.launcherDropPlaceholderVisible
            && dockItemContainer.verticalPanelMode
            && dockItemContainer.launcherDropInsertAfter
            ? -dockItemContainer.launcherDropReservedExtent : 0
        enabled: dockItemContainer.itemType === "trash"
            || dockItemContainer.externalDropEnabled
            || dockItemContainer.launcherDropEnabled

        onContainsDragChanged: {
            if (!containsDrag) {
                dockItemContainer.cancelExternalDropActivation()
                dockItemContainer.externalDropState = "none"
                dockItemContainer.launcherDropApplicationName = ""
                if (dockItemContainer.layoutController) {
                    dockItemContainer.layoutController.launcherDropTransitionActive = false
                }
            }
        }

        onEntered: function(drag) {
            const launcherCandidate
                = dockItemContainer.mayContainApplicationLauncher(drag)
            const launcherValidation = launcherCandidate
                ? dockItemContainer.validateLauncherDrop(drag.urls)
                : { "accepted": false }
            if (dockItemContainer.isApplicationLauncherDrag(
                    drag, launcherValidation)) {
                dockItemContainer.cancelExternalDropActivation()
                dockItemContainer.launcherDropApplicationName
                    = String(launcherValidation.name || "")
                if (!launcherValidation.accepted) {
                    drag.accepted = false
                    dockItemContainer.externalDropState = "rejected"
                    return
                }
                drag.accepted = true
                if (dockItemContainer.launcherContainerDropTarget) {
                    dockItemContainer.externalDropState
                        = dockItemContainer.launcherContainerDropEnabled
                            ? "launcherContainmentAcceptable"
                            : "launcherContainmentRejected"
                } else {
                    const position = externalDropArea.mapToItem(
                        dockItemContainer, drag.x, drag.y)
                    dockItemContainer.updateLauncherDropPosition(
                        position.x, position.y)
                    dockItemContainer.externalDropState = "launcherAcceptable"
                    if (dockItemContainer.layoutController) {
                        dockItemContainer.layoutController.launcherDropTransitionActive = true
                    }
                }
                return
            }
            if (dockItemContainer.itemType !== "trash"
                    && !dockItemContainer.externalDropEnabled) {
                drag.accepted = false
                return
            }
            if (!drag.hasUrls) {
                drag.accepted = false
                return
            }
            drag.accept()
            dockItemContainer.externalDropState = "acceptable"
            if (dockItemContainer.itemType !== "trash") {
                dockItemContainer.beginExternalDropActivation()
            }
        }

        onPositionChanged: function(drag) {
            if (dockItemContainer.externalDropState === "launcherAcceptable") {
                const position = externalDropArea.mapToItem(
                    dockItemContainer, drag.x, drag.y)
                dockItemContainer.updateLauncherDropPosition(
                    position.x, position.y)
            }
            dockItemContainer.maintainLauncherDropAcceptance(drag)
        }

        onExited: {
            dockItemContainer.cancelExternalDropActivation()
            dockItemContainer.externalDropState = "none"
            dockItemContainer.launcherDropApplicationName = ""
            if (dockItemContainer.layoutController) {
                dockItemContainer.layoutController.launcherDropTransitionActive = false
            }
        }

        onDropped: function(drop) {
            dockItemContainer.cancelExternalDropActivation()
            const launcherCandidate
                = dockItemContainer.mayContainApplicationLauncher(drop)
            const launcherValidation = launcherCandidate
                ? dockItemContainer.validateLauncherDrop(drop.urls)
                : { "accepted": false }
            if (dockItemContainer.isApplicationLauncherDrag(
                    drop, launcherValidation)) {
                drop.accepted = launcherValidation.accepted
                if (launcherValidation.accepted
                        && dockItemContainer.launcherContainerDropTarget) {
                    dockItemContainer.applicationLauncherContainerDropped(
                        drop.urls, dockItemContainer)
                } else if (launcherValidation.accepted) {
                    const position = externalDropArea.mapToItem(
                        dockItemContainer, drop.x, drop.y)
                    dockItemContainer.updateLauncherDropPosition(
                        position.x, position.y)
                    dockItemContainer.applicationLauncherDropped(
                        drop.urls, dockItemContainer.launcherInsertionIndex(),
                        dockItemContainer)
                }
                dockItemContainer.externalDropState = "none"
                dockItemContainer.launcherDropApplicationName = ""
                if (dockItemContainer.layoutController) {
                    dockItemContainer.layoutController.launcherDropTransitionActive = false
                }
                return
            }
            if (dockItemContainer.itemType !== "trash"
                    && !dockItemContainer.externalDropEnabled) {
                drop.accepted = false
                dockItemContainer.externalDropState = "none"
                return
            }
            if (dockItemContainer.itemType === "trash" && drop.hasUrls) {
                dockItemContainer.layoutController.trashUrlsDropped(drop.urls)
                dockItemContainer.externalDropState = "none"
                return
            }
            dockItemContainer.externalUrlsDropped(
                drop.hasUrls ? drop.urls : [], dockItemContainer)
            dockItemContainer.externalDropState = "none"
        }
    }
    Timer {
        id: tooltipDelayTimer
        interval: 700
        running: dockItemContainer.showAnyTooltip && mouseArea.containsMouse
    }

    Component {
        id: textTooltipComponent

        ColumnLayout {
            spacing: 4

            Controls.Label {
                text: dockItemContainer.localizedItemName
                color: Kirigami.Theme.textColor
                font.bold: true
            }
        }
    }

    PlasmaCore.Dialog {
        id: tooltipDialog
        visualParent: dockItemContainer
        location: dockItemContainer.tooltipLocation
        type: PlasmaCore.Dialog.Tooltip
        visible: dockItemContainer.showAnyTooltip && mouseArea.containsMouse && !tooltipDelayTimer.running
        flags: Qt.ToolTip | Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus

        mainItem: Item {
            implicitWidth: tooltipContentLoader.implicitWidth
            implicitHeight: tooltipContentLoader.implicitHeight

            Loader {
                id: tooltipContentLoader
                anchors.fill: parent
                sourceComponent: textTooltipComponent
            }
        }
    }
}
