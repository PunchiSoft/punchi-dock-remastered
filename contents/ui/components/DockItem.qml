import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras

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

    readonly property string effectiveIndicatorPosition: {
        return indicatorPosition === "top" ? "top" : "bottom"
    }

    readonly property string localizedItemName: {
        if (itemType === "trash" && itemName === "Trash") {
            return i18n("Trash")
        }
        if (itemType === "calendar" && itemName === "Calendar") {
            return i18n("Calendar")
        }
        if (itemType === "note" && itemName === "Quick Note") {
            return i18nc("@title", "Quick Note")
        }
        return itemName
    }

    property int itemIndex: -1
    property int hoveredIndex: -1
    
    // Wave animation state.
    property real hoverZoomProgress: 0.0
    property int lastHoveredIndex: -1
    property real lastMouseOffset: 0.0

    // Wave geometry follows the original project while preserving smooth transitions.
    property real hoverScaleSetting: 1.35
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
    property real entryOpacity: 1.0
    property real entryScale: 1.0
    property bool positionAnimationReady: false
    property bool showPersistentLabel: false
    property bool textShadowsEnabled: true
    property int labelFontSize: Math.max(10, Math.round(iconSize * 0.22))
    property string indicatorType: "line"
    property string indicatorPosition: "bottom"
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
            return mediaMainAxisLength + 12
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
        if (itemType === "calendar" || itemType === "media") {
            return 1.0
        }

        if (hoverAnimationMode === "none") {
            return 1.0
        }

        var activeIndex = hoveredIndex >= 0 ? hoveredIndex : lastHoveredIndex
        var pointerPosition = hoveredIndex >= 0
            ? Number(dockItemContainer.layoutController.pointerPrimaryAxis)
            : Number(dockItemContainer.layoutController.lastPointerPrimaryAxis)

        if (activeIndex === -1 || hoverZoomProgress <= 0.0) {
            return 1.0
        }

        if (hoverAnimationMode === "single") {
            return itemIndex === activeIndex
                ? 1.0 + (hoverScaleSetting - 1.0) * hoverZoomProgress
                : 1.0
        }

        if (hoverAnimationMode === "paragraph") {
            var indexDistance = Math.abs(itemIndex - activeIndex)
            var paragraphInfluences = [1.0, 0.62, 0.28]
            if (indexDistance >= paragraphInfluences.length) {
                return 1.0
            }
            return 1.0 + (hoverScaleSetting - 1.0) * paragraphInfluences[indexDistance] * hoverZoomProgress
        }
        
        if (!Number.isFinite(pointerPosition) || pointerPosition < 0) {
            return 1.0
        }

        var radius = Math.max(iconSize * 2.25, (iconSize + 20) * 1.85)
        var itemCenterPoint = dockItemContainer.mapToItem(
            dockItemContainer.layoutController,
            dockItemContainer.width / 2,
            dockItemContainer.height / 2)
        var itemCenter = verticalPanelMode ? itemCenterPoint.y : itemCenterPoint.x
        var distance = Math.abs(itemCenter - pointerPosition)
        if (distance >= radius) return 1.0
        
        var influence = 1.0 - (distance / radius)
        return 1.0 + (hoverScaleSetting - 1.0) * (influence * influence) * hoverZoomProgress
    }

    property bool inPanel: false
    property int panelLocation: PlasmaCore.Types.BottomEdge
    readonly property int tooltipLocation: {
        return panelLocation
    }
    readonly property real hoverTravel: waveScale <= 1.0 ? 0.0 : Math.round(iconSize * 0.32 * ((waveScale - 1.0) / hoverScaleDelta))
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
    property bool externalDropActivationEnabled: false
    property int externalDropActivationDelay: 1600
    property var externalDropActivator: null
    property string externalDropState: "none"
    property real externalDropActivationProgress: 0
    property bool customSeparatorEnabled: false
    property var separatorTheme: ({})
    readonly property Item taskGeometryItem: taskGeometryProxy
    readonly property bool containsMouse: mouseArea.containsMouse
    readonly property bool separatorItem: itemType === "separator"
    readonly property bool spacerItem: itemType === "spacer"
    readonly property bool mediaItem: itemType === "media"
    readonly property bool activeTaskItem: itemType === "app" && (taskIsActive || taskIndicatorCount > 0)
    readonly property bool showAnyTooltip: !separatorItem
        && !spacerItem
        && !mediaItem
        && itemName.length > 0
        && !suppressTooltip
        && !activeTaskItem
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
        running: itemType === "calendar"
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var date = new Date()
            var hh = String(date.getHours()).padStart(2, '0')
            var mm = String(date.getMinutes()).padStart(2, '0')
            var dd = String(date.getDate()).padStart(2, '0')
            var mo = String(date.getMonth() + 1).padStart(2, '0')
            currentTime = hh + ":" + mm
            currentDate = dd + "/" + mo
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
    signal hoverEntered(var visualParent)
    signal hoverExited(var visualParent)
    signal taskMinimized(int itemIndex)
    signal externalUrlsDropped(var urls, var visualParent)
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

    // Keep layout container measurements fully static to prevent jitter.
    implicitWidth: verticalPanelMode
        ? Math.max(iconSize + 12, !mediaItem && showPersistentLabel ? Math.round(iconSize * 1.85) : 0)
        : (separatorItem
            ? Math.max(10, Math.ceil(separatorThickness + 4))
            : (spacerItem
                ? Math.max(12, iconSize * 0.5)
                : (mediaItem
                    ? mediaMainAxisLength + 12
                    : Math.max(iconSize + 12,
                        showPersistentLabel ? Math.round(iconSize * 1.85) : 0))))
    implicitHeight: verticalPanelMode
        ? (separatorItem
            ? Math.max(10, Math.ceil(separatorThickness + 4))
            : (spacerItem
                ? Math.max(12, iconSize * 0.5)
                : (mediaItem
                    ? mediaMainAxisLength + 12
                    : (visualAreaHeight + labelAreaHeight))))
        : (visualAreaHeight + labelAreaHeight)
    opacity: entryOpacity

    Behavior on x {
        enabled: dockItemContainer.positionAnimationReady
            && dockItemContainer.positionTransitionEnabled
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on y {
        enabled: dockItemContainer.positionAnimationReady
            && dockItemContainer.positionTransitionEnabled
        NumberAnimation {
            duration: Kirigami.Units.longDuration
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
            duration: Kirigami.Units.longDuration
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: dockItemContainer
            property: "entryScale"
            to: 1.0
            duration: Kirigami.Units.longDuration
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: hoverBackground
        anchors.fill: parent
        visible: dockItemContainer.showItemHoverBackground
            && !dockItemContainer.separatorItem
            && !dockItemContainer.spacerItem
            && !dockItemContainer.mediaItem
            && dockItemContainer.itemType !== "calendar"
        radius: 8
        color: Kirigami.Theme.highlightColor
        opacity: mouseArea.containsMouse || dockItemContainer.taskIsActive
            ? 0.2
            : 0.0
        Behavior on opacity {
            enabled: hoverBackground.visible
            NumberAnimation { duration: 150 }
        }
    }

    Rectangle {
        z: 8
        anchors.fill: parent
        visible: dockItemContainer.externalDropState !== "none"
        radius: 8
        color: dockItemContainer.externalDropState !== "rejected"
            ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                Kirigami.Theme.highlightColor.g,
                Kirigami.Theme.highlightColor.b, 0.22)
            : Qt.rgba(Kirigami.Theme.negativeTextColor.r,
                Kirigami.Theme.negativeTextColor.g,
                Kirigami.Theme.negativeTextColor.b, 0.18)
        border.width: 2
        border.color: dockItemContainer.externalDropState !== "rejected"
            ? Kirigami.Theme.highlightColor
            : Kirigami.Theme.negativeTextColor

        Kirigami.Icon {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 3
            width: Math.max(14, dockItemContainer.iconSize * 0.34)
            height: width
            source: dockItemContainer.externalDropState === "rejected"
                ? "dialog-warning-symbolic"
                : (dockItemContainer.externalDropState === "activated"
                    ? "go-up-symbolic" : "document-open-symbolic")
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
            y: minimizeItemReaction.verticalOffset
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

        Kirigami.Icon {
            id: itemIcon
            z: 1
            anchors.centerIn: parent
            width: highQualityIconSize
            height: highQualityIconSize
            source: iconName
            visible: itemType !== "calendar" && !separatorItem && !spacerItem
                && !dockItemContainer.mediaItem

            scale: highQualityIconScale * waveScale
            transform: Translate {
                x: hoverOffsetX
                y: hoverOffsetY
            }
        }

        Column {
            id: calendarText
            anchors.centerIn: parent
            visible: itemType === "calendar"
            spacing: 1

            scale: waveScale
            transform: Translate {
                x: hoverOffsetX
                y: hoverOffsetY
            }

            PlasmaExtras.ShadowedLabel {
                text: currentTime
                renderShadow: dockItemContainer.textShadowsEnabled
                font.pixelSize: Math.round(14 * dockItemContainer.timeTextScale)
                font.weight: Font.Normal
                anchors.horizontalCenter: parent.horizontalCenter
            }

            PlasmaExtras.ShadowedLabel {
                text: currentDate
                renderShadow: dockItemContainer.textShadowsEnabled
                font.pixelSize: Math.round(9 * dockItemContainer.dateTextScale)
                opacity: 0.68
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        ThemedSeparator {
            visible: dockItemContainer.separatorItem
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
            anchors.fill: parent
            visible: itemType === "app"
                && taskIndicatorCount > 0
            count: taskIndicatorCount
            active: taskIsActive
            demandsAttention: taskDemandsAttention
            type: indicatorType
            position: effectiveIndicatorPosition
            thickness: indicatorThickness
            indicatorOpacity: dockItemContainer.indicatorOpacity
            iconSize: iconSize
        }

        WindowCountBadge {
            z: 3
            anchors.fill: parent
            count: taskIndicatorCount
            iconSize: iconSize
            demandsAttention: taskDemandsAttention
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
                : dockItemContainer.mediaMainAxisLength
            height: dockItemContainer.verticalPanelMode
                ? dockItemContainer.mediaMainAxisLength
                : dockItemContainer.iconSize
            visible: dockItemContainer.mediaItem
            controller: dockItemContainer.mediaController
            iconSize: dockItemContainer.iconSize
            vertical: dockItemContainer.verticalPanelMode
            motionEnabled: dockItemContainer.mediaMotionEnabled
            contextMenuEnabled: dockItemContainer.supportsContextMenu
            launchAvailable: dockItemContainer.mediaLaunchAvailable
            defaultPlayerName: dockItemContainer.mediaDefaultPlayerName
            defaultPlayerIcon: dockItemContainer.mediaDefaultPlayerIcon
            textMode: dockItemContainer.mediaTextMode
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
        }
    }

    Item {
        id: taskGeometryProxy
        anchors.fill: visualArea
    }

    PlasmaExtras.ShadowedLabel {
        id: persistentLabel
        visible: showPersistentLabel && !separatorItem && !spacerItem
            && !dockItemContainer.mediaItem
        anchors.top: visualArea.bottom
        anchors.topMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 6
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: dockItemContainer.localizedItemName
        renderShadow: dockItemContainer.textShadowsEnabled
        font.pixelSize: labelFontSize
        opacity: mouseArea.containsMouse || taskIsActive ? 1.0 : 0.88
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
        hoverEnabled: !separatorItem && !spacerItem
        activeFocusOnTab: true
        Accessible.role: separatorItem || spacerItem
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
            if (dockItemContainer.externalDropState === "rejected") {
                return i18nc("@info:accessible", "This file drop cannot be accepted")
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
        acceptedButtons: separatorItem || spacerItem
            ? Qt.NoButton
            : ((itemType === "trash" || supportsContextMenu)
                ? Qt.LeftButton | Qt.RightButton
                : Qt.LeftButton)
        
        onContainsMouseChanged: {
            if (separatorItem || spacerItem || itemType === "calendar") {
                if (!containsMouse && dockItemContainer.layoutController.hoveredIndex === itemIndex) {
                    dockItemContainer.layoutController.hoveredIndex = -1
                    dockItemContainer.layoutController.mouseOffset = 0.0
                }
                return
            }
            if (containsMouse) {
                dockItemContainer.layoutController.hoveredIndex = itemIndex
                const centerPoint = dockItemContainer.mapToItem(
                    dockItemContainer.layoutController,
                    dockItemContainer.width / 2,
                    dockItemContainer.height / 2)
                const center = dockItemContainer.verticalPanelMode
                    ? centerPoint.y
                    : centerPoint.x
                dockItemContainer.layoutController.pointerPrimaryAxis = center
                dockItemContainer.layoutController.lastPointerPrimaryAxis = center
                dockItemContainer.hoverEntered(dockItemContainer)
            } else if (dockItemContainer.layoutController.hoveredIndex === itemIndex) {
                dockItemContainer.layoutController.hoveredIndex = -1
                dockItemContainer.layoutController.mouseOffset = 0.0
                dockItemContainer.hoverExited(dockItemContainer)
            } else {
                dockItemContainer.hoverExited(dockItemContainer)
            }
        }
        
        onPositionChanged: function(mouse) {
            if (separatorItem || spacerItem || itemType === "calendar") {
                return
            }
            if (containsMouse) {
                const point = dockItemContainer.mapToItem(
                    dockItemContainer.layoutController, mouse.x, mouse.y)
                const position = dockItemContainer.verticalPanelMode ? point.y : point.x
                dockItemContainer.layoutController.pointerPrimaryAxis = position
                dockItemContainer.layoutController.lastPointerPrimaryAxis = position
            }
        }
        
        onClicked: function(mouse) {
            if (separatorItem || spacerItem) {
                return
            }
            if (mouse.button === Qt.RightButton) {
                dockItemContainer.contextMenuRequested(dockItemContainer, false)
            } else {
                if (clickEffect === "pulse") {
                    clickPulseAnimation.restart()
                } else if (clickEffect === "bounce") {
                    clickBounceAnimation.restart()
                } else if (clickEffect === "press") {
                    clickPressAnimation.restart()
                }
                dockItemContainer.itemClicked(itemCommand)
            }
        }
        Keys.onReturnPressed: if (!separatorItem && !spacerItem) dockItemContainer.itemClicked(itemCommand)
        Keys.onSpacePressed: if (!separatorItem && !spacerItem) dockItemContainer.itemClicked(itemCommand)
        Keys.onPressed: function(event) {
            if (dockItemContainer.mediaHoverControlsEnabled
                    && event.key === Qt.Key_M
                    && event.modifiers === Qt.NoModifier) {
                dockItemContainer.mediaControlsRequested(dockItemContainer)
                event.accepted = true
                return
            }
            if ((itemType === "trash" || supportsContextMenu) && (event.key === Qt.Key_Menu
                    || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier)))) {
                dockItemContainer.contextMenuRequested(dockItemContainer, true)
                event.accepted = true
            }
        }
    }

    DropArea {
        anchors.fill: parent
        enabled: dockItemContainer.itemType === "trash"
            || dockItemContainer.externalDropEnabled

        onEntered: function(drag) {
            if (!drag.hasUrls) {
                drag.accepted = false
                return
            }
            if (dockItemContainer.itemType === "trash") {
                drag.accept()
                return
            }
            const validation = dockItemContainer.validateExternalDrop(drag.urls)
            drag.accepted = validation.accepted
            dockItemContainer.externalDropState = validation.accepted
                ? "acceptable" : "rejected"
            if (validation.accepted) {
                dockItemContainer.beginExternalDropActivation()
            }
        }

        onExited: {
            dockItemContainer.cancelExternalDropActivation()
            dockItemContainer.externalDropState = "none"
        }

        onDropped: function(drop) {
            dockItemContainer.cancelExternalDropActivation()
            if (dockItemContainer.itemType === "trash" && drop.hasUrls) {
                dockItemContainer.layoutController.trashUrlsDropped(drop.urls)
                dockItemContainer.externalDropState = "none"
                return
            }
            const validation = dockItemContainer.validateExternalDrop(
                drop.hasUrls ? drop.urls : [])
            drop.accepted = validation.accepted
            if (!validation.accepted) {
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
