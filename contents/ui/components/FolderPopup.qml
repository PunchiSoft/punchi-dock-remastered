pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "punchimenu" as PunchiMenuComponents

Item {
    id: folderRoot
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    implicitWidth: layoutMode === "grid"
        ? Math.min(desiredGridWidth + scrollBarGutter, safeMaximumWidth)
        : (layoutMode === "fan"
            ? Math.min(fanView.implicitWidth + classicMargin * 2,
                safeMaximumWidth)
            : Math.min(Math.round(280 * effectiveScale), safeMaximumWidth))
    implicitHeight: classicPopupHeight
    width: implicitWidth
    height: implicitHeight

    // Properties injected by the main UI.
    property var folderItem: ({})
    property string layoutMode: "grid"
    property int profileIconSize: layoutMode === "grid" ? 36 : 32
    property int profileColumns: 3
    property int profileRows: 4
    property bool profileShowLabels: true
    property string profileFontFamily: ""
    property int profileFontSize: layoutMode === "grid" ? 9 : 10
    // Whether the fan may scroll. The fan is the only presentation whose model
    // is truncated when this is off, so the popup keeps the value and hands it
    // to the fan alone.
    property bool profileFanScrollEnabled: false
    property real profileScale: 1.0
    property bool showHeaderLabel: true
    property bool textShadowsEnabled: false
    // Amount of the text shadow of this popup, in percent. Zero removes it.
    property int textShadowPercent: 25
    property string animationStyle: "scale"
    property int animationIntensityPercent: 100
    property int popupDirection: Qt.BottomEdge
    property real revealProgress: 1.0
    property int maximumAvailableWidth: 752
    property int maximumAvailableHeight: 640
    // Height the display really offers the folder popup, floor included or not.
    // Zero means the popup only knows the shared ceiling.
    property int maximumSurfaceHeight: 0
    // Name of the file manager that opens a container, so the closing row of the
    // fan can name where it opens. Empty when the desktop association is unknown.
    property string folderOpenerName: ""

    // Folder the container points at, when it has one. Only a container bound to
    // a location can offer to open it, which is what the foot action does.
    readonly property string folderPath: String(folderItem.sourcePath || "").trim()
    readonly property bool folderPathAvailable: folderPath.length > 0

    // Quick access entries.
    property var apps: folderItem.apps || []
    property int itemCount: apps.length
    readonly property real effectiveScale: Math.max(0.5, Math.min(3.0,
        Number(profileScale || 1.0)))
    readonly property int classicMargin: Math.round(
        (layoutMode === "fan" ? 6 : 12) * effectiveScale)
    readonly property int classicSpacing: layoutMode === "fan"
        ? 0 : Math.round(8 * effectiveScale)
    readonly property int effectiveIconSize: Math.max(16, Math.min(192,
        Math.round(Number(profileIconSize || (layoutMode === "grid" ? 36 : 32)) * effectiveScale)))
    readonly property int configuredColumnCount: Math.max(1, Math.min(8,
        Number(profileColumns || 3)))
    readonly property int configuredRowLimit: Math.max(1, Math.min(8,
        Number(profileRows || 4)))
    readonly property bool showItemLabels: profileShowLabels
    readonly property string effectiveFontFamily:
        String(profileFontFamily || "").length > 0
            ? String(profileFontFamily)
            : (layoutMode === "grid"
                ? Kirigami.Theme.smallFont.family
                : Kirigami.Theme.defaultFont.family)
    readonly property int effectiveFontSize: Math.max(6, Math.min(36,
        Math.round(Number(profileFontSize || (layoutMode === "grid" ? 9 : 10)) * effectiveScale)))
    readonly property int gridCellWidth: showItemLabels
        ? Math.max(Math.round(80 * effectiveScale), effectiveIconSize + Math.round(24 * effectiveScale))
        : effectiveIconSize + Math.round(16 * effectiveScale)
    readonly property int classicCellHeight: !showItemLabels
        ? effectiveIconSize + Math.round(8 * effectiveScale)
        : (layoutMode === "fan"
            // A card is as tall as its icon plus the padding and the air the fan
            // asks for, so the pitch follows the card instead of a fixed inset.
            ? Math.max(Math.round(48 * effectiveScale),
                fanView.preferredRowHeight)
            : (layoutMode === "detailed"
            ? Math.max(Math.round(56 * effectiveScale), effectiveIconSize + effectiveFontSize + Math.round(8 * effectiveScale))
            : (layoutMode === "list"
                ? Math.max(Math.round(40 * effectiveScale), effectiveIconSize + Math.round(8 * effectiveScale))
                : effectiveIconSize + effectiveFontSize + Math.round(24 * effectiveScale))))
    readonly property int desiredGridWidth: classicMargin * 2
        + configuredColumnCount * gridCellWidth
    readonly property int safeMaximumWidth: Math.max(
        classicMargin * 2 + gridCellWidth,
        Number(maximumAvailableWidth || 752))
    readonly property int gridColumnsWithoutScrollBar: Math.max(1,
        Math.min(configuredColumnCount, Math.floor(
            (Math.min(desiredGridWidth, safeMaximumWidth)
                - classicMargin * 2) / gridCellWidth)))
    readonly property bool scrollRequired: layoutMode === "grid"
        ? itemCount > configuredRowLimit * gridColumnsWithoutScrollBar
        : itemCount > configuredRowLimit
    readonly property int scrollBarGutter: scrollRequired
        ? Math.ceil(verticalScrollBar.implicitWidth)
            + Kirigami.Units.smallSpacing
        : 0
    readonly property int classicContentWidth: implicitWidth
        - classicMargin * 2 - scrollBarGutter
    readonly property int gridColumnCount: layoutMode === "grid"
        ? Math.max(1, Math.min(configuredColumnCount,
            Math.floor(classicContentWidth / gridCellWidth)))
        : 1
    readonly property int classicRowCount: layoutMode === "grid"
        ? Math.ceil(itemCount / gridColumnCount)
        : itemCount
    readonly property int visibleClassicRows: layoutMode === "fan"
        ? fanView.visibleRowCount
        : Math.max(1, Math.min(classicRowCount, configuredRowLimit))
    readonly property bool effectiveShowHeaderLabel: showHeaderLabel
        && layoutMode !== "fan"
    // The chrome action belongs to the presentations that have no arc to close:
    // the fan carries the same action as its own far-end row.
    readonly property int openLocationRowHeight:
        folderPathAvailable && layoutMode !== "fan" ? classicCellHeight : 0
    readonly property int headerHeightEffect: effectiveShowHeaderLabel
        ? (classicHeader.implicitHeight + classicSpacing) : 0
    readonly property int classicChromeHeight: classicMargin * 2 + headerHeightEffect
        + (openLocationRowHeight > 0
            ? openLocationRowHeight + classicSpacing : 0)
    // The fan reserves inside its own list the room its leaning pills need, so
    // the popup takes the height the component declares instead of adding a
    // second reserve on top of it.
    readonly property int classicContentHeight: layoutMode === "fan"
        ? Math.ceil(fanView.implicitHeight)
        : visibleClassicRows * classicCellHeight
    readonly property int classicNaturalHeight: classicChromeHeight
        + classicContentHeight
    readonly property int configuredMaximumHeight: Math.max(0, Number(folderItem.popupMaxHeight || 0))
    readonly property int effectiveMaximumHeight: configuredMaximumHeight > 0
        ? Math.min(maximumAvailableHeight, Math.max(classicChromeHeight + classicCellHeight, configuredMaximumHeight))
        : maximumAvailableHeight
    // Content height the fan may use. The shared ceiling keeps a usability floor,
    // so the fan also receives the height the display really offers: with it, the
    // arc shows the rows that fit instead of asking for a frame taller than the
    // screen and having its far row cut.
    readonly property int fanContentCeiling: {
        const ceiling = maximumSurfaceHeight > 0
            ? Math.min(effectiveMaximumHeight, maximumSurfaceHeight)
            : effectiveMaximumHeight
        return Math.max(0, ceiling - classicChromeHeight)
    }
    readonly property int classicPopupHeight: Math.min(classicNaturalHeight, effectiveMaximumHeight)
    readonly property bool motionEnabled: Kirigami.Units.longDuration > 1
    readonly property bool revealMotionEnabled: motionEnabled
        && animationStyle !== "none"
    readonly property real safeRevealProgress: {
        if (!revealMotionEnabled) {
            return 1
        }
        const requestedProgress = Number(revealProgress)
        return Number.isFinite(requestedProgress)
            ? Math.max(0, Math.min(1, requestedProgress)) : 1
    }
    readonly property real animationIntensityFactor: {
        const requestedIntensity = Number(animationIntensityPercent)
        return Number.isFinite(requestedIntensity)
            ? Math.max(10, Math.min(200, requestedIntensity)) / 100
            : 1
    }
    readonly property real revealDistance: Math.round(
        Kirigami.Units.smallSpacing * animationIntensityFactor)
    readonly property int displacedDuration: motionEnabled
        ? Kirigami.Units.shortDuration : 0
    readonly property real fanOriginIconCenterX: classicMargin
        + fanView.originIconCenterX
    function revealOrder(index) {
        if (layoutMode !== "grid") {
            return index
        }
        const columns = Math.max(1, gridColumnCount)
        return Math.floor(index / columns) + (index % columns) * 0.25
    }

    function itemRevealProgress(index) {
        if (!revealMotionEnabled) {
            return 1
        }
        const delay = Math.min(0.18,
            revealOrder(index) * 0.025 * animationIntensityFactor)
        if (delay >= 1) {
            return safeRevealProgress >= 1 ? 1 : 0
        }
        return Math.max(0, Math.min(1,
            (safeRevealProgress - delay) / (1 - delay)))
    }

    function itemRevealOpacity(index) {
        if (!revealMotionEnabled) {
            return 1
        }
        const usesOpacity = animationStyle === "fade"
            || (layoutMode !== "grid"
                && (animationStyle === "scale"
                    || animationStyle === "bounce"))
        return usesOpacity
            ? 0.72 + itemRevealProgress(index) * 0.28
            : 1
    }

    function itemRevealScale(index) {
        if (!revealMotionEnabled || layoutMode !== "grid"
                || (animationStyle !== "scale"
                    && animationStyle !== "bounce")) {
            return 1
        }
        return 1 - 0.04 * animationIntensityFactor
            * (1 - itemRevealProgress(index))
    }

    function itemRevealOffsetX(index) {
        if (!revealMotionEnabled || animationStyle !== "slide") {
            return 0
        }
        const remainingProgress = 1 - itemRevealProgress(index)
        if (popupDirection === Qt.RightEdge) {
            return -revealDistance * remainingProgress
        }
        if (popupDirection === Qt.LeftEdge) {
            return revealDistance * remainingProgress
        }
        return 0
    }

    function itemRevealOffsetY(index) {
        if (!revealMotionEnabled || animationStyle !== "slide") {
            return 0
        }
        const remainingProgress = 1 - itemRevealProgress(index)
        if (popupDirection === Qt.BottomEdge) {
            return -revealDistance * remainingProgress
        }
        if (popupDirection === Qt.TopEdge) {
            return revealDistance * remainingProgress
        }
        return 0
    }

    // Signals for launching applications and closing the popup.
    signal appLaunched(var app)
    signal appContextMenuRequested(var app)
    signal closeRequested()
    // Requests the file manager to open the folder the container points at.
    signal openLocationRequested(string path)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: folderRoot.classicMargin
        spacing: folderRoot.classicSpacing

        // Folder title, centered on the popup and in the theme font weight. The
        // close button floats over the right end instead of taking room from the
        // centering, so the title reads as a header and not as the start of a row.
        Item {
            id: classicHeader
            visible: folderRoot.effectiveShowHeaderLabel
            Layout.fillWidth: true
            implicitHeight: Math.max(classicHeaderLabel.implicitHeight,
                classicCloseButton.height)
            PunchiMenuComponents.PunchiMenuTextShadowLabel {
                id: classicHeaderLabel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: folderRoot.folderItem.name || i18n("Folder") // qmllint disable unqualified
                horizontalAlignment: Text.AlignHCenter
                color: Kirigami.Theme.textColor
                shadowEnabled: folderRoot.textShadowsEnabled
                shadowPercent: folderRoot.textShadowPercent
                // Same type as the labels of the popup items and of the fan: the
                // same family and size, and the same DemiBold weight.
                font.family: folderRoot.effectiveFontFamily
                font.pointSize: folderRoot.effectiveFontSize
                font.weight: Font.DemiBold
            }
            // Close button.
            Rectangle {
                id: classicCloseButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                height: 20
                radius: 10
                color: closeMouse.containsMouse || closeMouse.activeFocus ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.backgroundColor
                PlasmaComponents.Label { text: "×"; anchors.centerIn: parent; color: Kirigami.Theme.textColor }
                MouseArea {
                    id: closeMouse
                    anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: i18n("Close") // qmllint disable unqualified
                    onClicked: folderRoot.closeRequested()
                    Keys.onReturnPressed: folderRoot.closeRequested()
                    Keys.onSpacePressed: folderRoot.closeRequested()
                }
            }
        }

        // Grid or list view.
        GridView {
            id: gridView
            objectName: "folderPopupGridView"
            visible: folderRoot.layoutMode !== "fan"
            Layout.fillWidth: true
            Layout.fillHeight: true
            // Keep cellWidth from producing scrollbars or horizontal clipping.
            cellWidth: folderRoot.layoutMode === "list"
                || folderRoot.layoutMode === "detailed"
                ? gridView.width - folderRoot.scrollBarGutter
                : folderRoot.gridCellWidth
            cellHeight: folderRoot.classicCellHeight
            model: folderRoot.layoutMode !== "fan" ? folderRoot.apps : []
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Controls.ScrollBar.vertical: Controls.ScrollBar {
                id: verticalScrollBar
                policy: folderRoot.scrollRequired
                    ? Controls.ScrollBar.AsNeeded
                    : Controls.ScrollBar.AlwaysOff
            }

            move: Transition {
                enabled: folderRoot.motionEnabled

                ParallelAnimation {
                    NumberAnimation {
                        property: "x"
                        duration: folderRoot.displacedDuration
                        easing.type: Easing.InOutCubic
                    }
                    NumberAnimation {
                        property: "y"
                        duration: folderRoot.displacedDuration
                        easing.type: Easing.InOutCubic
                    }
                }
            }

            moveDisplaced: Transition {
                enabled: folderRoot.motionEnabled

                ParallelAnimation {
                    NumberAnimation {
                        property: "x"
                        duration: folderRoot.displacedDuration
                        easing.type: Easing.InOutCubic
                    }
                    NumberAnimation {
                        property: "y"
                        duration: folderRoot.displacedDuration
                        easing.type: Easing.InOutCubic
                    }
                }
            }

            delegate: Item {
                id: appDelegate
                required property var modelData
                required property int index

                objectName: "folderPopupDelegate-" + index
                readonly property real revealOffsetX:
                    folderRoot.itemRevealOffsetX(index)
                readonly property real revealOffsetY:
                    folderRoot.itemRevealOffsetY(index)
                width: gridView.cellWidth
                height: gridView.cellHeight
                opacity: folderRoot.itemRevealOpacity(index)
                scale: folderRoot.itemRevealScale(index)
                transform: Translate {
                    x: appDelegate.revealOffsetX
                    y: appDelegate.revealOffsetY
                }

                Item {
                    id: itemContentContainer
                    anchors.fill: parent
                    scale: folderRoot.motionEnabled && itemMouse.pressed
                        ? 0.97 : itemHighlight.visualScale

                    // Shared launcher highlight used across Punchi Dock.
                    PunchiMenuComponents.PunchiMenuItemHighlight {
                        id: itemHighlight
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing
                        hovered: itemMouse.containsMouse
                        focused: itemMouse.activeFocus
                        pressed: itemMouse.pressed
                        motionEnabled: folderRoot.motionEnabled
                        transformSelf: false
                    }

                // List and detail modes place the icon before the label.
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    visible: folderRoot.layoutMode === "list"
                        || folderRoot.layoutMode === "detailed"
                    spacing: 8

                    Kirigami.Icon {
                        Layout.preferredWidth: folderRoot.effectiveIconSize
                        Layout.preferredHeight: folderRoot.effectiveIconSize
                        source: (appDelegate.modelData && appDelegate.modelData.icon) ? appDelegate.modelData.icon : "application-x-executable"
                    }
                    Column {
                        Layout.fillWidth: true
                        visible: folderRoot.showItemLabels
                        PunchiMenuComponents.PunchiMenuTextShadowLabel {
                            text: (appDelegate.modelData && appDelegate.modelData.name) ? appDelegate.modelData.name : ""
                            color: Kirigami.Theme.textColor
                            shadowEnabled: folderRoot.textShadowsEnabled
                            shadowPercent: folderRoot.textShadowPercent
                            font.family: folderRoot.effectiveFontFamily
                            font.pointSize: folderRoot.effectiveFontSize
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        PlasmaComponents.Label {
                            text: (appDelegate.modelData && appDelegate.modelData.command) ? appDelegate.modelData.command : ""
                            font.family: folderRoot.effectiveFontFamily
                            font.pointSize: Math.max(8, folderRoot.effectiveFontSize - 1)
                            color: Kirigami.Theme.textColor
                            opacity: 0.6
                            elide: Text.ElideRight
                            width: parent.width
                            visible: folderRoot.layoutMode === "detailed"
                        }
                    }
                }

                // Standard grid mode places the icon above the label.
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    visible: folderRoot.layoutMode === "grid"
                    spacing: folderRoot.showItemLabels ? 4 : 0

                    Kirigami.Icon {
                        Layout.preferredWidth: folderRoot.effectiveIconSize
                        Layout.preferredHeight: folderRoot.effectiveIconSize
                        Layout.alignment: Qt.AlignCenter
                        source: (appDelegate.modelData && appDelegate.modelData.icon) ? appDelegate.modelData.icon : "application-x-executable"
                    }
                    PunchiMenuComponents.PunchiMenuTextShadowLabel {
                        visible: folderRoot.showItemLabels
                        text: (appDelegate.modelData && appDelegate.modelData.name) ? appDelegate.modelData.name : ""
                        color: Kirigami.Theme.textColor
                        shadowEnabled: folderRoot.textShadowsEnabled
                        shadowPercent: folderRoot.textShadowPercent
                        font.family: folderRoot.effectiveFontFamily
                        font.pointSize: folderRoot.effectiveFontSize
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }
            }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: (appDelegate.modelData && appDelegate.modelData.name)
                        ? appDelegate.modelData.name
                        : i18n("Application") // qmllint disable unqualified
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            folderRoot.appContextMenuRequested(appDelegate.modelData)
                            return
                        }
                        folderRoot.appLaunched(appDelegate.modelData)
                    }
                    Keys.onReturnPressed: folderRoot.appLaunched(appDelegate.modelData)
                    Keys.onSpacePressed: folderRoot.appLaunched(appDelegate.modelData)
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Menu
                                || (event.key === Qt.Key_F10
                                    && (event.modifiers & Qt.ShiftModifier))) {
                            folderRoot.appContextMenuRequested(appDelegate.modelData)
                            event.accepted = true
                        }
                    }
                }
            }
        }

        FolderFanView {
            id: fanView
            objectName: "folderFanView"
            visible: folderRoot.layoutMode === "fan"
            enabled: folderRoot.layoutMode === "fan"
            Layout.fillWidth: true
            Layout.fillHeight: true
            apps: folderRoot.layoutMode === "fan" ? folderRoot.apps : []
            folderPath: folderRoot.layoutMode === "fan"
                ? folderRoot.folderPath : ""
            iconSize: folderRoot.effectiveIconSize
            rowLimit: folderRoot.configuredRowLimit
            rowHeight: folderRoot.classicCellHeight
            maximumContentHeight: folderRoot.layoutMode === "fan"
                ? folderRoot.fanContentCeiling : 0
            folderOpenerName: folderRoot.folderOpenerName
            showLabels: folderRoot.showItemLabels
            fontFamily: folderRoot.effectiveFontFamily
            fontSize: folderRoot.effectiveFontSize
            scrollEnabled: folderRoot.profileFanScrollEnabled
            textShadowsEnabled: folderRoot.textShadowsEnabled
            textShadowPercent: folderRoot.textShadowPercent
            motionEnabled: folderRoot.motionEnabled
            popupDirection: folderRoot.popupDirection
            revealProgress: folderRoot.safeRevealProgress
            revealOffsetX: folderRoot.itemRevealOffsetX(0)
            revealOffsetY: folderRoot.itemRevealOffsetY(0)
            displacedDuration: folderRoot.displacedDuration

            onAppLaunched: function(app) {
                folderRoot.appLaunched(app)
            }
            onAppContextMenuRequested: function(app) {
                folderRoot.appContextMenuRequested(app)
            }
            onOpenLocationRequested: function(path) {
                folderRoot.openLocationRequested(path)
            }
            onCloseRequested: folderRoot.closeRequested()
        }

        // Foot action: opens the folder the container points at, with the
        // container's own icon so it reads as «this folder». macOS keeps the
        // equivalent «Open in Finder» row at the foot of the stack popup.
        //
        // The slot owns the layout gate and gives the test a stable handle: the
        // offscreen harness reports `visible` as false for every item, so the
        // hidden state is checked through the slot, `enabled`, the focus flag
        // and the reserved height instead.
        Item {
            id: openLocationSlot

            objectName: "folderOpenLocationSlot"
            visible: folderRoot.folderPathAvailable
                && folderRoot.layoutMode !== "fan"
            Layout.fillWidth: true
            Layout.preferredHeight: visible
                ? folderRoot.openLocationRowHeight : 0

            Controls.ItemDelegate {
                id: openLocationDelegate

                anchors.fill: parent
                objectName: "folderOpenLocationAction"
                enabled: folderRoot.folderPathAvailable
                activeFocusOnTab: folderRoot.folderPathAvailable
                hoverEnabled: true
                padding: 0
                background: Item {}
                Accessible.name: openLocationLabel.text
                // qmllint disable unqualified
                Accessible.description: i18nc("@info:accessible",
                    "Open this folder in the file manager")
                // qmllint enable unqualified
                onClicked: folderRoot.openLocationRequested(folderRoot.folderPath)
                Keys.onReturnPressed:
                    folderRoot.openLocationRequested(folderRoot.folderPath)
                Keys.onEnterPressed:
                    folderRoot.openLocationRequested(folderRoot.folderPath)
                Keys.onSpacePressed:
                    folderRoot.openLocationRequested(folderRoot.folderPath)
                // Same as the fan: the delegate owns the click, so the hand is
                // asked for with a hover handler instead of a mouse area.
                HoverHandler {
                    objectName: "folderOpenLocationCursor"
                    cursorShape: Qt.PointingHandCursor
                }

                contentItem: Item {
                    id: openLocationContent

                    // The glyph box is as wide as an item icon, so the disc inside
                    // keeps the proportion the closing row of the fan uses.
                    readonly property int actionIconSize: Math.max(16,
                        Math.round(folderRoot.effectiveIconSize))

                    PunchiMenuComponents.PunchiMenuItemHighlight {
                        objectName: "folderOpenLocationHighlight"
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing / 2
                        radius: Kirigami.Units.cornerRadius * 2
                        hovered: openLocationDelegate.hovered
                        focused: openLocationDelegate.visualFocus
                        pressed: openLocationDelegate.pressed
                        motionEnabled: folderRoot.motionEnabled
                        transformSelf: false
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: Kirigami.Units.smallSpacing

                        // Glyph of the action, the same shape the closing row of
                        // the fan shows: a disc of the themed surface with an
                        // arrow inside. The icon of the container is not used here
                        // any more, because this row is an action and has to read
                        // the same in every presentation that offers it. The
                        // colours come from the theme, so a light and a dark theme
                        // both stay readable.
                        Item {
                            objectName: "folderOpenLocationGlyph"
                            Layout.preferredWidth: openLocationContent.actionIconSize
                            Layout.preferredHeight: openLocationContent.actionIconSize

                            Rectangle {
                                objectName: "folderOpenLocationDisc"
                                anchors.centerIn: parent
                                width: Math.round(parent.width * 0.6)
                                height: width
                                radius: width / 2
                                color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.88)
                                border.color: Qt.alpha(Kirigami.Theme.textColor, 0.12)
                                border.width: 1
                                antialiasing: true
                            }

                            Kirigami.Icon {
                                objectName: "folderOpenLocationArrow"
                                anchors.centerIn: parent
                                width: Math.round(parent.width * 0.34)
                                height: width
                                // Same source as the closing row of the fan: one
                                // action, one glyph.
                                source: "go-next-symbolic"
                                color: Kirigami.Theme.textColor
                                Accessible.ignored: true
                            }
                        }

                        PunchiMenuComponents.PunchiMenuTextShadowLabel {
                            id: openLocationLabel
                            objectName: "folderOpenLocationLabel"
                            // The row names the file manager the desktop really
                            // opens a folder with, the way the macOS reference
                            // names its Finder, and stays a short action word when
                            // that association is unknown.
                            // qmllint disable unqualified
                            text: folderRoot.folderOpenerName.length > 0
                                ? i18nc("@action:button open the folder in the file manager",
                                    "Open in %1", folderRoot.folderOpenerName)
                                : i18nc("@action:button open the container", "Open")
                            // qmllint enable unqualified
                            color: Kirigami.Theme.textColor
                            shadowEnabled: folderRoot.textShadowsEnabled
                            shadowPercent: folderRoot.textShadowPercent
                            font.family: folderRoot.effectiveFontFamily
                            font.pointSize: folderRoot.effectiveFontSize
                            // Same weight as the item labels and as the closing row
                            // of the fan, which plays this same role.
                            font.weight: Font.DemiBold
                            wrapMode: Text.NoWrap
                            elide: Text.ElideMiddle
                            Layout.maximumWidth: Math.max(0,
                                openLocationContent.width
                                    - openLocationContent.actionIconSize
                                    - Kirigami.Units.smallSpacing * 4)
                        }
                    }
                }
            }
        }
    }

}
