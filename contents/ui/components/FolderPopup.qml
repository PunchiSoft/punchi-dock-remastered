pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../org/punchi/dock" as Punchi
import "punchimenu" as PunchiMenuComponents

Item {
    id: folderRoot
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    readonly property real presentationWidth: layoutMode === "grid"
        ? Math.min(desiredGridWidth + scrollBarGutter, safeMaximumWidth)
        : (layoutMode === "fan"
            ? Math.min(fanView.implicitWidth + classicMargin * 2,
                safeMaximumWidth)
            : Math.min(Math.round(280 * effectiveScale), safeMaximumWidth))
    implicitWidth: presentationWidth + (lateralNavigation
        ? presentationWidth + Kirigami.Units.smallSpacing : 0)
    implicitHeight: lateralNavigation
        ? Math.max(classicPopupHeight, navigationPane.item
            ? (navigationPane.item as FolderPopup).implicitHeight : 0) : classicPopupHeight
    width: implicitWidth
    height: implicitHeight

    // Properties injected by the main UI.
    property var folderItem: ({})
    property bool embeddedNavigationPane: false
    property bool sessionActive: true
    property Punchi.FolderNavigationModel modelOverride: null
    property string pathOverride: ""
    property string titleOverride: ""
    property bool directoryNavigationEnabled: navigationActive
    property bool showCloseButton: true
    property bool backAvailable: narrowNavigation
    property int navigationDepth: navigator.history.length
    readonly property bool navigationActive: !embeddedNavigationPane
        && folderItem.browseSubfolders === true
        && folderItem.sourceType === "folder"
        && (layoutMode === "list" || layoutMode === "detailed")
    readonly property bool lateralNavigation: navigationActive && navigator.hasChild
        && maximumAvailableWidth >= presentationWidth * 2 + Kirigami.Units.smallSpacing
    readonly property bool narrowNavigation: navigationActive && navigator.hasChild
        && !lateralNavigation
    readonly property Punchi.FolderNavigationModel directoryModel: modelOverride
        ? modelOverride : (navigationActive
            ? (narrowNavigation ? navigator.childModel : navigator.rootModel) : null)
    readonly property string headerTitle: titleOverride.length > 0
        ? titleOverride : (narrowNavigation ? navigator.breadcrumb
            : String(folderItem.name || ""))
    readonly property FolderNavigationController navigationController: navigator
    property int pendingViewIndex: -1
    property real pendingViewScroll: 0

    FolderNavigationController {
        id: navigator
        enabled: folderRoot.navigationActive && folderRoot.sessionActive
        rootPath: String(folderRoot.folderItem.sourcePath || "")
        rootName: String(folderRoot.folderItem.name || "")
        onRestoreRequested: function(primary, index, scroll) {
            if (primary || !folderRoot.lateralNavigation) {
                folderRoot.restoreView(index, scroll)
            } else if (navigationPane.item) {
                (navigationPane.item as FolderPopup).restoreView(index, scroll)
            }
        }
    }
    property string layoutMode: "grid"
    property int profileIconSize: 42
    property bool profileAutoLayout: true
    property int profileColumns: 3
    property int profileRows: 4
    property bool profileShowLabels: true
    property string profileFontFamily: ""
    property int profileFontSize: layoutMode === "grid" ? 9 : 10
    // Whether the fan may scroll. The fan is the only presentation whose model
    // is truncated when this is off, so the popup keeps the value and hands it
    // to the fan alone.
    property bool profileFanScrollEnabled: false
    property real profileScale: 1.5
    property bool showHeaderLabel: true
    property bool textShadowsEnabled: true
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
    readonly property string folderPath: pathOverride.length > 0
        ? pathOverride : (navigationActive && directoryModel
            ? directoryModel.location : String(folderItem.sourcePath || "").trim())
    readonly property bool folderPathAvailable: folderPath.length > 0
    // qmllint disable unqualified
    readonly property string openLocationActionText:
        folderOpenerName.length > 0
            ? i18nc("@action:button open the folder in the file manager",
                "Open in %1", folderOpenerName)
            : i18nc("@action:button open the container", "Open")
    // qmllint enable unqualified

    // Quick access entries.
    property var apps: folderItem.apps || []
    property int itemCount: directoryModel ? directoryModel.count
        : Math.max(0, Number(apps && apps.length) || 0)
    // The reference integrates the location action as the final Grid cell. This
    // derived model belongs only to Grid: List and Detailed keep consuming apps
    // directly, and Fan keeps its dedicated model below.
    readonly property var gridItems: {
        const sourceItems = apps || []
        if (!folderPathAvailable) {
            return sourceItems
        }
        const visibleItems = sourceItems.slice()
        visibleItems.push({ "_punchiOpenLocationAction": true })
        return visibleItems
    }
    readonly property int classicItemCount: layoutMode === "grid"
        ? gridItems.length : itemCount
    readonly property real effectiveScale: Math.max(0.5, Math.min(3.0,
        Number(profileScale || 1.5)))
    readonly property int classicMargin: Math.round(
        (layoutMode === "fan" ? 6 : 12) * effectiveScale)
    readonly property int classicSpacing: layoutMode === "fan"
        ? 0 : Math.round(8 * effectiveScale)
    readonly property int effectiveIconSize: Math.max(16, Math.min(192,
        Math.round(Number(profileIconSize || 42) * effectiveScale)))
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
    readonly property int safeMaximumWidth: Math.max(
        classicMargin * 2 + gridCellWidth,
        Number(maximumAvailableWidth || 752))
    // Shape the automatic arrangement aims at, as columns divided by rows. The
    // value reproduces the distribution of the folder popup: wider than tall,
    // without collapsing into a single strip or into a narrow column.
    property real automaticTargetRatio: 1.5
    // Cost of a ragged last row: one application left alone on the final line.
    // The elastic cell of a folder container cancels it, so both container
    // kinds are told apart by the same cost and not by a special case.
    property real automaticOrphanPenalty: 1
    // Cost of one row that would not fit the height the popup offers. It stays
    // far above the other terms, so scrolling is always the last resort.
    property real automaticOverflowWeight: 10
    readonly property int automaticMaximumColumnCount: Math.max(1,
        Math.min(5, Math.floor((safeMaximumWidth - classicMargin * 2)
            / gridCellWidth)))
    readonly property int automaticRowLimit: Math.max(1, Math.min(8,
        Math.floor((effectiveMaximumHeight - classicChromeHeight)
            / classicCellHeight)))
    readonly property int automaticColumnCount: automaticGridColumnCount(
        classicItemCount, itemCount, folderPathAvailable,
        automaticMaximumColumnCount, automaticRowLimit,
        automaticTargetRatio, automaticOrphanPenalty,
        automaticOverflowWeight)
    readonly property int effectiveGridColumnRequest:
        profileAutoLayout && layoutMode === "grid"
            ? automaticColumnCount : configuredColumnCount
    readonly property int effectiveClassicRowLimit:
        profileAutoLayout && layoutMode === "grid"
            ? automaticRowLimit : configuredRowLimit
    readonly property int desiredGridWidth: classicMargin * 2
        + effectiveGridColumnRequest * gridCellWidth
    readonly property int gridColumnsWithoutScrollBar: Math.max(1,
        Math.min(effectiveGridColumnRequest, Math.floor(
            (Math.min(desiredGridWidth, safeMaximumWidth)
                - classicMargin * 2) / gridCellWidth)))
    readonly property bool scrollRequired: layoutMode === "grid"
        ? classicItemCount > effectiveClassicRowLimit
            * gridColumnsWithoutScrollBar
        : itemCount > configuredRowLimit
    readonly property int scrollBarGutter: scrollRequired
        ? Math.ceil(verticalScrollBar.implicitWidth)
            + Kirigami.Units.smallSpacing
        : 0
    readonly property int classicContentWidth: (lateralNavigation ? presentationWidth : implicitWidth)
        - classicMargin * 2 - scrollBarGutter
    readonly property int gridColumnCount: layoutMode === "grid"
        ? Math.max(1, Math.min(effectiveGridColumnRequest,
            Math.floor(classicContentWidth / gridCellWidth)))
        : 1
    readonly property int classicRowCount: layoutMode === "grid"
        ? Math.ceil(classicItemCount / gridColumnCount)
        : itemCount
    readonly property int visibleClassicRows: layoutMode === "fan"
        ? fanView.visibleRowCount
        : Math.max(1, Math.min(classicRowCount,
            layoutMode === "grid"
                ? effectiveClassicRowLimit : configuredRowLimit))
    readonly property bool effectiveShowHeaderLabel: (showHeaderLabel || directoryNavigationEnabled)
        && layoutMode !== "fan"
    // List and Detailed retain a chrome row. Grid includes the action in its
    // model, and Fan carries it at the far end of its arc.
    readonly property bool separateLocationRowActive: folderPathAvailable
        && (layoutMode === "list" || layoutMode === "detailed")
    readonly property int openLocationRowHeight:
        separateLocationRowActive
        ? classicCellHeight : 0
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

    // Cost of arranging the cells of the popup in `columns` columns. It is the
    // discrete counterpart of the empty area of the grid: the holes are the sum,
    // row by row, of the cells a row does not use, so `holes / columns` is the
    // relative slack of the last row. The kind of container enters through the
    // elastic cell: the location action of a folder container takes the first
    // free seat of that row, so a last row holding one application plus the
    // action reads as complete and never counts as ragged.
    function automaticGridCost(totalItems, applicationItems, hasLocationAction,
            columns, maximumRows, targetRatio, orphanPenalty,
            overflowWeight) {
        const cellTotal = Math.max(0, Math.floor(Number(totalItems) || 0))
        const applicationTotal = Math.max(0,
            Math.floor(Number(applicationItems) || 0))
        const safeColumns = Math.max(1, Math.floor(Number(columns) || 1))
        const rows = Math.ceil(cellTotal / safeColumns)
        const holes = safeColumns * rows - cellTotal
        const overflow = Math.max(0, rows - maximumRows)
        const shapeDelta = Math.log(safeColumns / rows)
            - Math.log(targetRatio)
        const lastApplicationRow = applicationTotal <= 0
            ? 0 : ((applicationTotal - 1) % safeColumns) + 1
        const ragged = lastApplicationRow === 1
            && applicationTotal > safeColumns
            && (!hasLocationAction || lastApplicationRow + 1 > safeColumns)
        return overflowWeight * overflow
            + holes / safeColumns
            + shapeDelta * shapeDelta
            + (ragged ? orphanPenalty : 0)
    }

    // Automatic column count of the Grid profile. One row wins whenever the
    // cells fit in it, because a single line is the shortest arrangement and can
    // never leave a ragged row behind. Otherwise the candidates run from two
    // columns up to the ceiling the width allows, and the cheapest one wins with
    // ties resolved towards the widest grid, which is how the reference
    // distribution reads.
    function automaticGridColumnCount(totalItems, applicationItems,
            hasLocationAction, maximumColumns, maximumRows, targetRatio,
            orphanPenalty, overflowWeight) {
        const cellTotal = Math.max(0, Math.floor(Number(totalItems) || 0))
        const columnCeiling = Math.max(1,
            Math.floor(Number(maximumColumns) || 1))
        const rowCeiling = Math.max(1, Math.floor(Number(maximumRows) || 1))
        const requestedRatio = Number(targetRatio)
        const safeTargetRatio = Number.isFinite(requestedRatio)
                && requestedRatio > 0 ? requestedRatio : 1.5
        const requestedOrphanPenalty = Number(orphanPenalty)
        const safeOrphanPenalty = Number.isFinite(requestedOrphanPenalty)
            ? Math.max(0, requestedOrphanPenalty) : 0
        const requestedOverflowWeight = Number(overflowWeight)
        const safeOverflowWeight = Number.isFinite(requestedOverflowWeight)
            ? Math.max(0, requestedOverflowWeight) : 0
        if (cellTotal <= 0) {
            return 1
        }
        if (cellTotal <= columnCeiling) {
            return cellTotal
        }
        if (columnCeiling < 2) {
            return columnCeiling
        }

        let selectedColumns = 2
        let selectedCost = Number.POSITIVE_INFINITY
        for (let columns = 2; columns <= columnCeiling; columns++) {
            const cost = automaticGridCost(cellTotal, applicationItems,
                hasLocationAction, columns, rowCeiling, safeTargetRatio,
                safeOrphanPenalty, safeOverflowWeight)
            // Floating point costs that differ only below this step belong to
            // the same arrangement, so the comparison stays stable.
            const comparableCost = Math.round(cost * 1e9) / 1e9
            if (comparableCost < selectedCost
                    || (comparableCost === selectedCost
                        && columns > selectedColumns)) {
                selectedColumns = columns
                selectedCost = comparableCost
            }
        }
        return selectedColumns
    }

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
    signal directoryActivated(var entry, int index, real scroll)
    signal backRequested()

    function restoreView(index, scroll) {
        folderRoot.pendingViewIndex = index
        folderRoot.pendingViewScroll = scroll
        Qt.callLater(folderRoot.applyViewRestore)
    }

    function applyViewRestore() {
        if (folderRoot.pendingViewIndex < 0 || (folderRoot.directoryModel
                && folderRoot.directoryModel.loading)) {
            return
        }
        const index = Math.min(folderRoot.pendingViewIndex, gridView.count - 1)
        gridView.currentIndex = index
        gridView.contentY = Math.max(0, Math.min(folderRoot.pendingViewScroll,
            Math.max(0, gridView.contentHeight - gridView.height)))
        folderRoot.pendingViewIndex = -1
        if (gridView.currentItem) {
            gridView.currentItem.forceActiveFocus()
        } else if (folderRoot.backAvailable) {
            backButton.forceActiveFocus()
        } else {
            classicCloseButton.forceActiveFocus()
        }
    }

    onDirectoryActivated: function(entry, index, scroll) {
        if (!embeddedNavigationPane) {
            navigator.enter(entry, index, scroll, !narrowNavigation)
        }
    }
    onBackRequested: {
        if (!embeddedNavigationPane) {
            navigator.back()
        }
    }
    Keys.onEscapePressed: folderRoot.closeRequested()
    Keys.onLeftPressed: {
        if (folderRoot.backAvailable) {
            folderRoot.backRequested()
        }
    }

    Loader {
        id: navigationPane
        objectName: "folderNavigationPaneLoader"
        active: folderRoot.lateralNavigation
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: folderRoot.presentationWidth
        // Dynamic loading reuses the view without recursively instantiating its QML type.
        // The embedded pane disables its own navigation loader.
        source: active ? "FolderPopup.qml" : ""
        onLoaded: {
            const pane = navigationPane.item as FolderPopup
            pane.embeddedNavigationPane = true
            pane.directoryNavigationEnabled = true
            pane.showCloseButton = false
            pane.backAvailable = true
            pane.navigationDepth = Qt.binding(function() { return navigator.history.length })
            pane.sessionActive = Qt.binding(function() { return folderRoot.sessionActive })
            pane.folderItem = Qt.binding(function() { return folderRoot.folderItem })
            pane.layoutMode = Qt.binding(function() { return folderRoot.layoutMode })
            pane.modelOverride = navigator.childModel
            pane.pathOverride = Qt.binding(function() { return navigator.childModel.location })
            pane.titleOverride = Qt.binding(function() { return navigator.breadcrumb })
            pane.profileIconSize = Qt.binding(function() { return folderRoot.profileIconSize })
            pane.profileRows = Qt.binding(function() { return folderRoot.profileRows })
            pane.profileShowLabels = Qt.binding(function() { return folderRoot.profileShowLabels })
            pane.profileFontFamily = Qt.binding(function() { return folderRoot.profileFontFamily })
            pane.profileFontSize = Qt.binding(function() { return folderRoot.profileFontSize })
            pane.profileScale = Qt.binding(function() { return folderRoot.profileScale })
            pane.textShadowsEnabled = Qt.binding(function() { return folderRoot.textShadowsEnabled })
            pane.textShadowPercent = Qt.binding(function() { return folderRoot.textShadowPercent })
            pane.maximumAvailableWidth = Qt.binding(function() { return folderRoot.presentationWidth })
            pane.maximumAvailableHeight = Qt.binding(function() { return folderRoot.maximumAvailableHeight })
            pane.folderOpenerName = Qt.binding(function() { return folderRoot.folderOpenerName })
            pane.animationStyle = "none"
            pane.restoreView(navigator.pendingIndex, navigator.pendingScroll)
        }
    }
    Connections {
        target: navigationPane.item
        function onDirectoryActivated(entry, index, scroll) {
            navigator.enter(entry, index, scroll, false)
        }
        function onBackRequested() { navigator.back() }
        function onAppLaunched(app) { folderRoot.appLaunched(app) }
        function onAppContextMenuRequested(app) { folderRoot.appContextMenuRequested(app) }
        function onOpenLocationRequested(path) { folderRoot.openLocationRequested(path) }
        function onCloseRequested() { folderRoot.closeRequested() }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: folderRoot.classicMargin
        anchors.rightMargin: folderRoot.classicMargin + (folderRoot.lateralNavigation
            ? folderRoot.presentationWidth + Kirigami.Units.smallSpacing : 0)
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
                text: folderRoot.headerTitle || i18n("Folder") // qmllint disable unqualified
                elide: Text.ElideMiddle
                anchors.leftMargin: folderRoot.backAvailable ? backButton.width : 0
                anchors.rightMargin: folderRoot.directoryNavigationEnabled
                    && folderRoot.showCloseButton ? classicCloseButton.width : 0
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
            DecorationCloseButton {
                id: classicCloseButton
                objectName: "folderPopupCloseButton"
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onClicked: folderRoot.closeRequested()
                visible: folderRoot.showCloseButton
            }
            Controls.ToolButton {
                id: backButton
                objectName: "folderNavigationBack"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                visible: folderRoot.backAvailable
                enabled: visible
                icon.name: "go-previous-symbolic"
                text: i18nc("@action:button folder navigation", "Back") // qmllint disable unqualified
                display: Controls.AbstractButton.IconOnly
                Accessible.name: text
                onClicked: folderRoot.backRequested()
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
            model: folderRoot.layoutMode === "grid"
                ? folderRoot.gridItems
                : ((folderRoot.layoutMode === "list"
                    || folderRoot.layoutMode === "detailed")
                    ? (folderRoot.directoryModel || folderRoot.apps) : [])
            onCountChanged: Qt.callLater(folderRoot.applyViewRestore)
            Controls.BusyIndicator {
                anchors.centerIn: parent
                running: !!folderRoot.directoryModel && folderRoot.directoryModel.loading
                visible: running
            }
            Controls.Label {
                anchors.fill: parent
                text: folderRoot.directoryModel ? folderRoot.directoryModel.error : ""
                visible: text.length > 0
                wrapMode: Text.Wrap
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
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
                onActiveFocusChanged: {
                    if (activeFocus) { itemMouse.forceActiveFocus() }
                }
                readonly property bool browsableDirectory: folderRoot.directoryNavigationEnabled
                    && !!(modelData && modelData.navigable)
                    && (!(folderRoot.embeddedNavigationPane || folderRoot.narrowNavigation)
                        || folderRoot.navigationDepth < 3)

                readonly property bool isOpenLocationAction:
                    !!(modelData && modelData._punchiOpenLocationAction)
                readonly property string displayName: isOpenLocationAction
                    ? folderRoot.openLocationActionText
                    : ((modelData && modelData.name) ? modelData.name : "")
                readonly property string displayIcon:
                    (modelData && modelData.icon)
                        ? modelData.icon : "application-x-executable"

                objectName: isOpenLocationAction
                    ? "folderGridOpenLocationAction"
                    : "folderPopupDelegate-" + index
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

                function activate() {
                    if (isOpenLocationAction) {
                        folderRoot.openLocationRequested(folderRoot.folderPath)
                    } else {
                        gridView.currentIndex = index
                        if (browsableDirectory) {
                            folderRoot.directoryActivated(modelData, index, gridView.contentY)
                        } else {
                            folderRoot.appLaunched(modelData)
                        }
                    }
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
                        source: appDelegate.displayIcon
                    }
                    Column {
                        Layout.fillWidth: true
                        visible: folderRoot.showItemLabels
                        PopupMarqueeLabel {
                            objectName: "folderPopupListLabel-" + appDelegate.index
                            text: appDelegate.displayName
                            hovered: itemMouse.containsMouse
                            focused: itemMouse.activeFocus
                            motionEnabled: folderRoot.motionEnabled
                            color: Kirigami.Theme.textColor
                            shadowEnabled: folderRoot.textShadowsEnabled
                            shadowPercent: folderRoot.textShadowPercent
                            font.family: folderRoot.effectiveFontFamily
                            font.pointSize: folderRoot.effectiveFontSize
                            font.weight: Font.DemiBold
                            width: parent.width
                        }
                        PlasmaComponents.Label {
                            text: appDelegate.modelData
                                ? (appDelegate.modelData.description || appDelegate.modelData.command || "") : ""
                            font.family: folderRoot.effectiveFontFamily
                            font.pointSize: Math.max(8, folderRoot.effectiveFontSize - 1)
                            color: Kirigami.Theme.textColor
                            opacity: 0.6
                            elide: Text.ElideRight
                            width: parent.width
                            visible: folderRoot.layoutMode === "detailed"
                        }
                    }
                    Kirigami.Icon {
                        visible: appDelegate.browsableDirectory
                        source: "go-next-symbolic"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Layout.preferredWidth
                        Accessible.ignored: true
                    }
                }

                // Standard grid mode places the icon above the label.
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    visible: folderRoot.layoutMode === "grid"
                    spacing: folderRoot.showItemLabels ? 4 : 0

                    Item {
                        Layout.preferredWidth: folderRoot.effectiveIconSize
                        Layout.preferredHeight: folderRoot.effectiveIconSize
                        Layout.alignment: Qt.AlignCenter

                        Kirigami.Icon {
                            anchors.fill: parent
                            visible: !appDelegate.isOpenLocationAction
                            source: appDelegate.displayIcon
                            Accessible.ignored: true
                        }

                        Rectangle {
                            objectName: "folderGridOpenLocationDisc"
                            anchors.centerIn: parent
                            visible: appDelegate.isOpenLocationAction
                            width: Math.round(parent.width * 0.72)
                            height: width
                            radius: width / 2
                            color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.88)
                            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.24)
                            border.width: 1
                            antialiasing: true
                        }

                        Kirigami.Icon {
                            objectName: "folderGridOpenLocationArrow"
                            anchors.centerIn: parent
                            visible: appDelegate.isOpenLocationAction
                            width: Math.round(parent.width * 0.44)
                            height: width
                            source: "go-next-symbolic"
                            color: Kirigami.Theme.textColor
                            Accessible.ignored: true
                        }
                    }
                    PopupMarqueeLabel {
                        objectName: appDelegate.isOpenLocationAction
                            ? "folderGridOpenLocationLabel"
                            : "folderPopupGridLabel-" + appDelegate.index
                        visible: folderRoot.showItemLabels
                        text: appDelegate.displayName
                        hovered: itemMouse.containsMouse
                        focused: itemMouse.activeFocus
                        motionEnabled: folderRoot.motionEnabled
                        color: Kirigami.Theme.textColor
                        shadowEnabled: folderRoot.textShadowsEnabled
                        shadowPercent: folderRoot.textShadowPercent
                        font.family: folderRoot.effectiveFontFamily
                        font.pointSize: folderRoot.effectiveFontSize
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

                MouseArea {
                    id: itemMouse
                    objectName: appDelegate.isOpenLocationAction
                        ? "folderGridOpenLocationPointer"
                        : "folderPopupPointer-" + appDelegate.index
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: appDelegate.isOpenLocationAction
                        ? Qt.LeftButton : Qt.LeftButton | Qt.RightButton
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: appDelegate.displayName.length > 0
                        ? appDelegate.displayName
                        : i18n("Application") // qmllint disable unqualified
                    // qmllint disable unqualified
                    Accessible.description: appDelegate.isOpenLocationAction
                        ? i18nc("@info:accessible",
                            "Open this folder in the file manager") : ""
                    // qmllint enable unqualified
                    onClicked: function(mouse) {
                        if (appDelegate.isOpenLocationAction) {
                            appDelegate.activate()
                            return
                        }
                        if (mouse.button === Qt.RightButton) {
                            folderRoot.appContextMenuRequested(appDelegate.modelData)
                            return
                        }
                        appDelegate.activate()
                    }
                    Keys.onReturnPressed: appDelegate.activate()
                    Keys.onEnterPressed: appDelegate.activate()
                    Keys.onSpacePressed: appDelegate.activate()
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Right && appDelegate.browsableDirectory) {
                            appDelegate.activate()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                            gridView.currentIndex = Math.max(0, Math.min(gridView.count - 1,
                                appDelegate.index + (event.key === Qt.Key_Up ? -1 : 1)))
                            gridView.positionViewAtIndex(gridView.currentIndex, GridView.Contain)
                            if (gridView.currentItem) {
                                gridView.currentItem.forceActiveFocus()
                            }
                            event.accepted = true
                        }
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

        // Foot action for List and Detailed. Grid integrates this action as its
        // final cell, while Fan closes its arc with a specialized row.
        //
        // The slot owns the layout gate and gives the test a stable handle: the
        // offscreen harness reports `visible` as false for every item, so the
        // hidden state is checked through the slot, `enabled`, the focus flag
        // and the reserved height instead.
        Item {
            id: openLocationSlot

            objectName: "folderOpenLocationSlot"
            visible: folderRoot.separateLocationRowActive
            Layout.fillWidth: true
            Layout.preferredHeight: visible
                ? folderRoot.openLocationRowHeight : 0

            Controls.ItemDelegate {
                id: openLocationDelegate

                anchors.fill: parent
                objectName: "folderOpenLocationAction"
                enabled: folderRoot.separateLocationRowActive
                activeFocusOnTab: folderRoot.separateLocationRowActive
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
                            text: folderRoot.openLocationActionText
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
