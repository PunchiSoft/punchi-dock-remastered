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
    property int labelFontSize: Math.max(10, Math.round(iconSize * 0.22))
    property string indicatorType: "line"
    property string indicatorPosition: "bottom"
    property int indicatorThickness: 4
    property real indicatorOpacity: 1.0
    property int highQualityIconSize: Math.min(512, Math.max(iconSize, Math.ceil(iconSize * Math.max(1, hoverScaleSetting) * 1.12)))
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
    readonly property real baseItemExtent: Math.max(iconSize, implicitWidth - 12)
    readonly property real labelAreaHeight: showPersistentLabel && !separatorItem && !spacerItem ? (labelFontSize + 12) : 0
    readonly property real visualAreaHeight: iconSize + 12
    property real clickAnimationScale: 1.0
    property real waveScale: {
        if (itemType === "calendar") {
            return 1.0
        }

        if (hoverAnimationMode === "none") {
            return 1.0
        }

        var activeIndex = hoveredIndex >= 0 ? hoveredIndex : lastHoveredIndex
        var activeOffset = hoveredIndex >= 0 ? dockItemContainer.parent.mouseOffset : lastMouseOffset

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
        
        var step = baseItemExtent + 8
        var radius = Math.max(iconSize * 2.25, step * 1.85)
        
        var mousePos = (activeIndex * step) + (activeOffset * step)
        var itemPos = itemIndex * step
        
        var distance = Math.abs(itemPos - mousePos)
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
        if (!inPanel || hoverTravel <= 0.0) {
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
        if (!inPanel) {
            return -hoverTravel
        }
        if (panelLocation === PlasmaCore.Types.TopEdge) {
            return hoverTravel
        }
        if (panelLocation === PlasmaCore.Types.BottomEdge) {
            return -hoverTravel
        }
        return 0.0
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
    property int popupDirection: Qt.BottomEdge
    property bool customSeparatorEnabled: false
    property var separatorTheme: ({})
    readonly property Item dockWrapperItem: dockItemContainer.parent && dockItemContainer.parent.parent ? dockItemContainer.parent.parent : null
    readonly property bool verticalPopupFlow: popupDirection === Qt.TopEdge || popupDirection === Qt.BottomEdge
    readonly property real popupAnchorExtent: Math.max(1, Math.min(width, iconSize + 12))
    readonly property Item popupAnchorItem: popupAnchorProxy
    readonly property Item taskGeometryItem: taskGeometryProxy
    readonly property bool containsMouse: mouseArea.containsMouse
    readonly property bool separatorItem: itemType === "separator"
    readonly property bool spacerItem: itemType === "spacer"
    readonly property bool activeTaskItem: itemType === "app" && (taskIsActive || taskIndicatorCount > 0)
    readonly property bool showAnyTooltip: !separatorItem
        && !spacerItem
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

    function focusItem() {
        mouseArea.forceActiveFocus(Qt.OtherFocusReason)
    }
    // Keep layout container measurements fully static to prevent jitter.
    implicitWidth: separatorItem
        ? Math.max(10, Math.ceil(separatorThickness + 4))
        : (spacerItem
            ? Math.max(12, iconSize * 0.5)
            : Math.max(iconSize + 12,
                showPersistentLabel ? Math.round(iconSize * 1.85) : 0))
    implicitHeight: visualAreaHeight + labelAreaHeight
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
        verticalPanel: dockItemContainer.inPanel
            && (dockItemContainer.panelLocation === PlasmaCore.Types.LeftEdge
                || dockItemContainer.panelLocation === PlasmaCore.Types.RightEdge)
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
                font.pixelSize: 14
                font.weight: Font.Normal
                anchors.horizontalCenter: parent.horizontalCenter
            }

            PlasmaExtras.ShadowedLabel {
                text: currentDate
                font.pixelSize: 9
                opacity: 0.68
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        Rectangle {
            visible: dockItemContainer.separatorItem
                && !dockItemContainer.customSeparatorEnabled
            width: dockItemContainer.separatorThickness
            height: dockItemContainer.separatorLength
            radius: dockItemContainer.separatorThickness / 2
            anchors.centerIn: parent
            color: Kirigami.Theme.textColor
            opacity: 0.34
        }

        ThemedSeparator {
            visible: dockItemContainer.separatorItem
                && dockItemContainer.customSeparatorEnabled
            anchors.centerIn: parent
            width: dockItemContainer.separatorThickness
            height: dockItemContainer.separatorLength
            availableLength: visualArea.height
            renderedThickness: dockItemContainer.separatorThickness
            maximumGlowSize: dockItemContainer.separatorGlowSize
            theme: dockItemContainer.separatorTheme
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
            position: indicatorPosition
            thickness: indicatorThickness
            indicatorOpacity: dockItemContainer.indicatorOpacity
            iconSize: iconSize
        }
    }

    Item {
        id: taskGeometryProxy
        anchors.fill: visualArea
    }

    Controls.Label {
        id: persistentLabel
        visible: showPersistentLabel && !separatorItem && !spacerItem
        anchors.top: visualArea.bottom
        anchors.topMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 6
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: dockItemContainer.localizedItemName
        font.pixelSize: labelFontSize
        color: Kirigami.Theme.textColor
        opacity: mouseArea.containsMouse || taskIsActive ? 1.0 : 0.88
    }

    Item {
        id: popupAnchorProxy
        parent: dockWrapperItem
        visible: false
        width: verticalPopupFlow ? dockItemContainer.popupAnchorExtent : (dockWrapperItem ? dockWrapperItem.width : dockItemContainer.width)
        height: verticalPopupFlow ? (dockWrapperItem ? dockWrapperItem.height : dockItemContainer.height) : dockItemContainer.implicitHeight
        x: verticalPopupFlow
            ? ((dockItemContainer.parent ? dockItemContainer.parent.x : 0)
                + dockItemContainer.x
                + Math.round((dockItemContainer.width - width) / 2))
            : 0
        y: verticalPopupFlow
            ? 0
            : ((dockItemContainer.parent ? dockItemContainer.parent.y : 0) + dockItemContainer.y)
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
        hoverEnabled: !separatorItem && !spacerItem
        activeFocusOnTab: true
        Accessible.role: separatorItem || spacerItem ? Accessible.StaticText : Accessible.Button
        Accessible.name: dockItemContainer.localizedItemName
        // qmllint disable unqualified
        Accessible.description: dockItemContainer.mediaHoverControlsEnabled
            ? i18nc("@info:accessible", "Press M to open media controls")
            : ""
        // qmllint enable unqualified
        acceptedButtons: separatorItem || spacerItem
            ? Qt.NoButton
            : ((itemType === "trash" || supportsContextMenu)
                ? Qt.LeftButton | Qt.RightButton
                : Qt.LeftButton)
        
        onContainsMouseChanged: {
            if (separatorItem || spacerItem || itemType === "calendar") {
                if (!containsMouse && dockItemContainer.parent.hoveredIndex === itemIndex) {
                    dockItemContainer.parent.hoveredIndex = -1
                    dockItemContainer.parent.mouseOffset = 0.0
                }
                return
            }
            if (containsMouse) {
                dockItemContainer.parent.hoveredIndex = itemIndex
                dockItemContainer.hoverEntered(dockItemContainer)
            } else if (dockItemContainer.parent.hoveredIndex === itemIndex) {
                dockItemContainer.parent.hoveredIndex = -1
                dockItemContainer.parent.mouseOffset = 0.0
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
                // Range from -0.5 (left) to 0.5 (right).
                dockItemContainer.parent.mouseOffset = (mouse.x - (width / 2)) / width
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
        enabled: itemType === "trash"
        onDropped: function(drop) {
            if (drop.hasUrls) {
                dockItemContainer.parent.trashUrlsDropped(drop.urls)
            }
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
