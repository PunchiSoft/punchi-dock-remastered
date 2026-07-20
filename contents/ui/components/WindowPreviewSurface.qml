pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    property var taskControllerRef: null
    property int taskRevision: 0
    property string applicationId: ""
    property var windowUuids: []
    property var fallbackWindows: []
    property string previewStyle: "card"
    property real previewScale: 1.5
    property string previewInfoMode: "full"
    property int maxVisibleRows: 4
    property int maximumAvailableWidth: 752
    property int maximumAvailableHeight: 640
    property var resolvedWindows: []
    property string resolvedWindowState: ""
    readonly property var windows: resolvedWindows
    readonly property bool showLiveThumbnails: previewStyle === "thumbnail"
    readonly property bool containsMouse: popupHover.hovered

    function requestedWindows() {
        if (taskControllerRef
                && (applicationId.length > 0 || windowUuids.length > 0)) {
            return taskControllerRef.taskWindowsForIdentity(applicationId, windowUuids)
        }
        return fallbackWindows instanceof Array ? fallbackWindows : []
    }

    function windowStateKey(sourceWindows) {
        const candidateWindows = sourceWindows instanceof Array ? sourceWindows : []
        return JSON.stringify(candidateWindows.map(function(windowData) {
            return {
                "row": Number(windowData.row),
                "title": String(windowData.title || ""),
                "name": String(windowData.name || ""),
                "subtitle": String(windowData.subtitle || ""),
                "active": !!windowData.active,
                "closable": !!windowData.closable,
                "minimizable": !!windowData.minimizable,
                "minimized": !!windowData.minimized,
                "maximizable": !!windowData.maximizable,
                "maximized": !!windowData.maximized,
                "icon": String(windowData.icon || ""),
                "windowUuid": String(windowData.windowUuid || "")
            }
        }))
    }

    function refreshWindows() {
        const nextWindows = requestedWindows()
        const nextState = windowStateKey(nextWindows)
        if (nextState === resolvedWindowState) {
            return
        }
        resolvedWindowState = nextState
        resolvedWindows = nextWindows
    }

    onTaskRevisionChanged: refreshWindows()
    onTaskControllerRefChanged: refreshWindows()
    onApplicationIdChanged: refreshWindows()
    onWindowUuidsChanged: refreshWindows()
    onFallbackWindowsChanged: refreshWindows()
    Component.onCompleted: refreshWindows()

    readonly property real maximumPreviewScaleByWidth: Math.max(1.5,
        (maximumAvailableWidth - 56) / 184)
    readonly property real maximumPreviewScaleByHeight: Math.max(1.5,
        (maximumAvailableHeight - verticalPadding * 2 - cardOuterPadding * 2)
            * 1.6 / 184)
    readonly property real effectivePreviewScale: Math.max(1.5, Math.min(4.5,
        previewScale, maximumPreviewScaleByWidth, maximumPreviewScaleByHeight))
    readonly property int previewFrameWidth: Math.round(184 * effectivePreviewScale)
    readonly property int previewFrameHeight: Math.round(previewFrameWidth / 1.6)
    readonly property int horizontalPadding: Kirigami.Units.smallSpacing * 2
    readonly property int verticalPadding: Kirigami.Units.smallSpacing * 2
    readonly property int cardOuterPadding: 2
    readonly property int cardHeight: previewFrameHeight + (cardOuterPadding * 2)
    readonly property int listSpacing: Kirigami.Units.smallSpacing
    readonly property int listContentHeight: windows.length > 0
        ? windows.length * cardHeight + (windows.length - 1) * listSpacing
        : 0
    readonly property int visibleRowLimit: Math.max(1, Math.min(8, maxVisibleRows))
    readonly property int configuredRowsHeight: visibleRowLimit * cardHeight
        + (visibleRowLimit - 1) * listSpacing
    readonly property int availableListHeight: Math.max(cardHeight,
        maximumAvailableHeight - verticalPadding * 2)
    readonly property int listViewportHeight: Math.min(listContentHeight,
        configuredRowsHeight, availableListHeight)
    readonly property bool scrollRequired: listContentHeight > listViewportHeight
    readonly property int scrollBarGutter: scrollRequired
        ? Math.ceil(windowScrollBar.implicitWidth) + Kirigami.Units.smallSpacing
        : 0

    implicitWidth: Math.max(196, previewFrameWidth + horizontalPadding * 2
        + cardOuterPadding * 2) + scrollBarGutter
    implicitHeight: verticalPadding * 2 + listViewportHeight
    width: implicitWidth
    height: implicitHeight
    Layout.maximumHeight: maximumAvailableHeight

    signal activateRequested(int taskRow)
    signal presentWindowRequested(int taskRow)
    signal minimizeWindowRequested(int taskRow)
    signal maximizeWindowRequested(int taskRow)
    signal closeWindowRequested(int taskRow)

    HoverHandler {
        id: popupHover
    }

    Controls.ScrollView {
        id: windowsScrollView
        anchors.fill: parent
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: root.horizontalPadding
        anchors.topMargin: root.verticalPadding
        anchors.bottomMargin: root.verticalPadding
        clip: true
        rightPadding: root.scrollBarGutter
        Controls.ScrollBar.horizontal.policy: Controls.ScrollBar.AlwaysOff
        Controls.ScrollBar.vertical: Controls.ScrollBar {
            id: windowScrollBar
            parent: windowsScrollView
            x: windowsScrollView.width - width
            y: windowsScrollView.topPadding
            height: windowsScrollView.availableHeight
            policy: root.scrollRequired
                ? Controls.ScrollBar.AsNeeded
                : Controls.ScrollBar.AlwaysOff
        }

        ListView {
            id: windowList
            width: windowsScrollView.availableWidth
            model: root.windows
            spacing: root.listSpacing
            boundsBehavior: Flickable.StopAtBounds

            delegate: WindowPreviewCard {
                id: previewCard
                required property var modelData

                width: windowList.width
                windowData: modelData
                liveThumbnailEnabled: root.showLiveThumbnails
                streamActive: root.visible
                    && (previewCard.y + previewCard.height >= windowList.contentY - 8)
                    && (previewCard.y <= windowList.contentY + windowList.height + 8)
                infoMode: root.previewInfoMode
                previewWidth: root.previewFrameWidth
                previewHeight: root.previewFrameHeight
                previewRadius: 4
                outerPadding: root.cardOuterPadding

                onActivateRequested: taskRow => root.activateRequested(taskRow)
                onPresentWindowRequested: taskRow => root.presentWindowRequested(taskRow)
                onMinimizeWindowRequested: taskRow => root.minimizeWindowRequested(taskRow)
                onMaximizeWindowRequested: taskRow => root.maximizeWindowRequested(taskRow)
                onCloseWindowRequested: taskRow => root.closeWindowRequested(taskRow)
            }
        }
    }
}
