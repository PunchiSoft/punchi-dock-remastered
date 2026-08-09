import QtQuick
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami

Item {
    id: root

    default property alias contentData: contentHost.data
    property var mediaController: null
    property var taskControllerRef: null
    property var mediaWindows: []
    property string mediaIcon: "emblem-music-symbolic"
    property string mediaControlsMode: "card"
    property bool showMedia: true
    property bool mediaOnly: false
    property bool forceCompactMedia: false
    property bool transitionsEnabled: true
    property bool contentGeometryTransitionsEnabled: true
    property bool surfaceStateFrozen: false
    property int transitionSpeedPercent: 100
    property real mediaGap: 2
    property real maximumAvailableHeight: 0
    property bool drawContentBackground: true
    property string backgroundImagePath: "dialogs/background"
    property real backgroundOpacity: 1.0
    property real contentFramePaddingPercent: 0
    property real contentFramePaddingScale: 1.0
    property real minimumSurfaceWidth: 0
    property real minimumSurfaceHeight: 0
    property bool preserveContentGeometry: false
    property real contentTransferProgress: 1
    readonly property Item contentItem: contentHost.children.length > 0
        ? contentHost.children[0]
        : null
    readonly property real contentImplicitWidth: !mediaOnly && contentItem ? contentItem.implicitWidth : 0
    readonly property real contentImplicitHeight: !mediaOnly && contentItem ? contentItem.implicitHeight : 0
    readonly property real effectiveMediaGap: mediaOnly ? 0 : mediaGap
    readonly property bool mediaRequested: showMedia
        && !!mediaController
        && mediaController.available
    readonly property bool fullMediaFits: maximumAvailableHeight <= 0
        || contentImplicitHeight + effectiveMediaGap
            + mediaCard.preferredExpandedHeight <= maximumAvailableHeight
    readonly property bool compactMediaFits: maximumAvailableHeight <= 0
        || contentImplicitHeight + effectiveMediaGap
            + mediaCard.compactPreferredHeight <= maximumAvailableHeight
    readonly property bool mediaVisible: mediaRequested && compactMediaFits
    readonly property bool mediaSurfacePresent: mediaVisible || mediaExtent > 0.5
    readonly property bool compactMedia: mediaVisible
        && (forceCompactMedia || !fullMediaFits)
    readonly property real targetMediaExtent: mediaVisible
        ? mediaCard.implicitHeight + effectiveMediaGap
        : 0
    readonly property bool mediaGeometrySettled:
        Math.abs(mediaExtent - targetMediaExtent) <= 0.5
    readonly property int transitionDuration: transitionsEnabled && Kirigami.Units.longDuration > 1
        ? Math.round(Kirigami.Units.longDuration * 100
            / Math.max(10, Math.min(200, transitionSpeedPercent)))
        : 0
    readonly property real requestedContentExtent: !mediaOnly && contentItem
        ? contentItem.implicitHeight
        : 0
    property real lastPositiveContentWidth: Math.max(0, root.minimumSurfaceWidth)
    property real lastPositiveContentHeight: Math.max(0, root.minimumSurfaceHeight)
    readonly property real targetContentWidth: root.mediaOnly
        ? 0
        : (root.contentImplicitWidth > 0
            ? root.contentImplicitWidth
            : (root.preserveContentGeometry ? root.lastPositiveContentWidth : 0))
    readonly property real targetContentHeight: root.mediaOnly
        ? 0
        : (root.requestedContentExtent > 0
            ? root.requestedContentExtent
            : (root.preserveContentGeometry ? root.lastPositiveContentHeight : 0))
    property real mediaExtent: 0
    property real contentWidthExtent: root.targetContentWidth
    property real contentExtent: root.targetContentHeight
    property real mediaRevealProgress: 0
    readonly property bool containsMouse: surfaceHover.hovered
        || (mediaVisible && mediaCard.activeFocus)
    readonly property real safeBackgroundOpacity: {
        const requestedOpacity = Number(root.backgroundOpacity)
        return Number.isFinite(requestedOpacity)
            ? Math.max(0.5, Math.min(1.0, requestedOpacity))
            : 1.0
    }
    readonly property real surfaceContentWidth: Math.max(
        Math.max(0, root.minimumSurfaceWidth), root.contentWidthExtent)
    readonly property real surfaceContentHeight: Math.max(
        Math.max(0, root.minimumSurfaceHeight), root.contentExtent)
    readonly property real contentFramePadding: {
        const requestedPercent = Number(root.contentFramePaddingPercent)
        if (!root.drawContentBackground || root.mediaOnly
                || !Number.isFinite(requestedPercent)
                || requestedPercent <= 0) {
            return 0
        }
        const shortSide = Math.min(root.surfaceContentWidth,
            root.surfaceContentHeight)
        if (!Number.isFinite(shortSide) || shortSide <= 0) {
            return 0
        }
        const requestedPadding = shortSide * requestedPercent / 100
        const basePadding = Math.max(Kirigami.Units.smallSpacing,
            Math.min(Kirigami.Units.gridUnit / 2, requestedPadding))
        const requestedScale = Number(root.contentFramePaddingScale)
        const safeScale = Number.isFinite(requestedScale)
            ? Math.max(1.0, Math.min(2.0, requestedScale))
            : 1.0
        return Math.round(Math.min(Kirigami.Units.gridUnit,
            basePadding * safeScale))
    }
    signal mediaCloseRequested()

    implicitWidth: Math.max(
        root.surfaceContentWidth + (root.mediaOnly
            ? 0
            : root.contentFramePadding * 2),
        root.mediaSurfacePresent ? 280 : 0)
    implicitHeight: root.mediaExtent + (root.mediaOnly
        ? 0
        : root.surfaceContentHeight + root.contentFramePadding * 2)
    readonly property bool presentationGeometryReady:
        Number.isFinite(root.implicitWidth) && root.implicitWidth > 0
        && Number.isFinite(root.implicitHeight) && root.implicitHeight > 0
        && root.mediaGeometrySettled
    width: implicitWidth
    height: implicitHeight

    function updateMediaExtent() {
        if (root.surfaceStateFrozen) {
            return
        }
        mediaExtent = root.targetMediaExtent
    }

    function updateMediaVisibility() {
        if (root.surfaceStateFrozen) {
            return
        }
        updateMediaExtent()
        if (!mediaVisible) {
            mediaRevealProgress = 0
            return
        }

        mediaRevealProgress = 0
        Qt.callLater(function() {
            if (root.mediaVisible) {
                root.mediaRevealProgress = 1
            }
        })
    }

    function focusMediaControls() {
        return mediaVisible && mediaCard.focusFirstControl()
    }

    function rememberPositiveContentGeometry() {
        if (Number.isFinite(root.contentImplicitWidth)
                && root.contentImplicitWidth > 0) {
            root.lastPositiveContentWidth = root.contentImplicitWidth
        }
        if (Number.isFinite(root.requestedContentExtent)
                && root.requestedContentExtent > 0) {
            root.lastPositiveContentHeight = root.requestedContentExtent
        }
    }

    function beginContentTransfer() {
        if (!transitionsEnabled || transitionDuration <= 0) {
            contentTransferProgress = 1
            return
        }

        contentTransferAnimation.stop()
        contentTransferProgress = 0
        contentTransferAnimation.start()
    }

    onMediaVisibleChanged: updateMediaVisibility()
    onCompactMediaChanged: updateMediaExtent()
    onMediaOnlyChanged: updateMediaExtent()
    onContentImplicitWidthChanged: root.rememberPositiveContentGeometry()
    onRequestedContentExtentChanged: root.rememberPositiveContentGeometry()
    onSurfaceStateFrozenChanged: {
        if (!root.surfaceStateFrozen) {
            root.updateMediaVisibility()
        }
    }

    Component.onCompleted: {
        root.rememberPositiveContentGeometry()
        root.updateMediaVisibility()
    }

    Behavior on mediaExtent {
        NumberAnimation {
            duration: root.transitionDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on contentWidthExtent {
        enabled: root.transitionsEnabled
            && root.contentGeometryTransitionsEnabled
            && root.transitionDuration > 0

        NumberAnimation {
            duration: root.transitionDuration
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on contentExtent {
        enabled: root.transitionsEnabled
            && root.contentGeometryTransitionsEnabled
            && root.transitionDuration > 0

        NumberAnimation {
            duration: root.transitionDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on mediaRevealProgress {
        NumberAnimation {
            duration: root.transitionDuration
            easing.type: Easing.OutCubic
        }
    }

    NumberAnimation {
        id: contentTransferAnimation
        target: root
        property: "contentTransferProgress"
        from: 0
        to: 1
        duration: Math.max(90, Math.min(160, Math.round(root.transitionDuration * 0.65)))
        easing.type: Easing.OutCubic
    }

    HoverHandler {
        id: surfaceHover
    }

    MediaControlsCard {
        id: mediaCard
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        controller: root.mediaController
        taskControllerRef: root.taskControllerRef
        windows: root.mediaWindows
        fallbackIcon: root.mediaIcon
        compact: root.compactMedia
        squarePresentation: root.mediaOnly
        fullCoverPresentation: root.mediaOnly && root.mediaControlsMode === "fullCard"
        transitionDuration: root.transitionDuration
        height: root.mediaOnly
            ? Math.max(0, root.mediaExtent)
            : Math.max(0, root.mediaExtent - root.effectiveMediaGap)
        visible: root.mediaVisible || root.mediaExtent > 0.5
        opacity: root.mediaRevealProgress * (0.72 + (0.28 * root.contentTransferProgress))
        scale: 0.98 + (0.02 * root.mediaRevealProgress)
        transform: Translate {
            y: (6 * (1 - root.mediaRevealProgress))
                + (4 * (1 - root.contentTransferProgress))
        }

        onImplicitHeightChanged: root.updateMediaExtent()
        onCloseRequested: root.mediaCloseRequested()
    }

    KSvg.FrameSvgItem {
        id: menuBackground
        x: 0
        y: root.mediaExtent
        width: root.width
        height: root.surfaceContentHeight + root.contentFramePadding * 2
        imagePath: root.backgroundImagePath
        visible: root.drawContentBackground && !root.mediaOnly
        opacity: root.safeBackgroundOpacity
            * (0.72 + (0.28 * root.contentTransferProgress))
        Accessible.ignored: true
    }

    Item {
        id: contentHost
        x: root.contentFramePadding
        y: root.mediaExtent + root.contentFramePadding
        width: Math.max(0, root.width - root.contentFramePadding * 2)
        height: root.surfaceContentHeight
        visible: !root.mediaOnly
        opacity: 0.72 + (0.28 * root.contentTransferProgress)
        transform: Translate {
            y: 4 * (1 - root.contentTransferProgress)
        }
    }

    Binding {
        target: root.contentItem
        property: "width"
        value: contentHost.width
        when: root.contentItem !== null
    }

    Binding {
        target: root.contentItem
        property: "height"
        value: contentHost.height
        when: root.contentItem !== null
    }
}
