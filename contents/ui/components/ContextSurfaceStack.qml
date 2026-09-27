import QtQuick
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami
import "punchimenu" as PunchiMenuComponents

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
    // When enabled, the owning dialog asks KWin for blur behind this surface.
    // The region comes from the theme frame mask contracted by its insets.
    property bool backgroundBlurEnabled: true
    property real contentFramePaddingPercent: 0
    property real contentFramePaddingScale: 1.0
    property real minimumSurfaceWidth: 0
    property real minimumSurfaceHeight: 0
    property bool preserveContentGeometry: false
    // Optional comic-style tail, composed from the same theme frame that draws
    // the background. It needs a band outside the frame, so the frame keeps its
    // own size and the surface grows by the visible length of the tail.
    // Disabled by default: only the folder grid popup enables it.
    property bool edgeTailEnabled: false
    property int edgeTailLocation: Qt.BottomEdge
    // Extent of the dock item the tail points at, so the tail stays proportional
    // to the icon it belongs to.
    property real edgeTailAnchorExtent: 0
    // Tip position along the surface axis, in window coordinates. A non-finite
    // value centers the tail on the surface.
    property real edgeTailTipOffset: NaN
    readonly property Item contentItem: contentHost.children.length > 0
        ? contentHost.children[0]
        : null
    readonly property real contentImplicitWidth: !mediaOnly && contentItem ? contentItem.implicitWidth : 0
    readonly property real contentImplicitHeight: !mediaOnly && contentItem ? contentItem.implicitHeight : 0
    readonly property var backgroundBlurMaskSource: menuBackground
    readonly property bool backgroundBlurMaskPresent: menuBackground.visible
        && menuBackground.width > 0
        && menuBackground.height > 0
    readonly property point backgroundBlurMaskOffset:
        mappedSurfaceGeometry.backgroundMaskOffset
    // Optional shapes are expressed in the local coordinate system of the
    // themed frame. BlurBehindController contracts that frame first and then
    // unions this polygon, so the frame insets never erode the tail.
    readonly property var backgroundBlurAdditionalMaskPolygon: {
        if (!root.edgeTailPresent) {
            return []
        }
        // mapToItem() is a mapping operation, not a complete dependency list.
        // These reads keep the polygon reactive when either sibling moves or
        // changes size. Ancestor animation is applied once through the shared
        // backgroundBlurMaskOffset below.
        const geometryValues = [
            edgeTail.x, edgeTail.y, edgeTail.width, edgeTail.height,
            menuBackground.x, menuBackground.y,
            menuBackground.width, menuBackground.height,
            edgeTail.tipPosition, edgeTail.tailBase,
            edgeTail.protrusion, edgeTail.tipRadius
        ]
        if (geometryValues.some(value => !Number.isFinite(value))) {
            return []
        }
        const localPolygon = edgeTail.blurRegionPolygon
        const mappedPolygon = []
        for (let index = 0; index < localPolygon.length; ++index) {
            const mappedPoint = edgeTail.mapToItem(
                menuBackground, localPolygon[index])
            if (!Number.isFinite(mappedPoint.x)
                    || !Number.isFinite(mappedPoint.y)) {
                return []
            }
            mappedPolygon.push(Qt.point(mappedPoint.x, mappedPoint.y))
        }
        return mappedPolygon
    }
    // The owning dialog reveals this surface inside an animated container.
    // Supplying that container and its translation keeps the mask origin valid
    // after the reveal, which mapToItem() alone does not invalidate. Both
    // default to this surface when no animation wraps it.
    property Item blurTransformSurface: null
    property real blurTranslationX: 0
    property real blurTranslationY: 0
    readonly property Item effectiveBlurTransformSurface:
        root.blurTransformSurface ? root.blurTransformSurface : root
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
    readonly property bool edgeTailPresent: root.edgeTailEnabled
        && root.drawContentBackground && !root.mediaOnly
    readonly property bool edgeTailHorizontal:
        root.edgeTailLocation === Qt.TopEdge
            || root.edgeTailLocation === Qt.BottomEdge
    // True when the band sits before the frame on its axis, that is, on the top
    // or on the left of the window.
    readonly property bool edgeTailBandOnStart:
        root.edgeTailLocation === Qt.TopEdge
            || root.edgeTailLocation === Qt.LeftEdge
    // Band the tail needs outside the frame. The tail derives both lengths from
    // the frame insets, so no length is fixed here: the visible length starts at
    // the effective background edge, and the surface only grows by the part that
    // falls outside the frame rectangle.
    readonly property real edgeTailProtrusion: root.edgeTailPresent
        ? edgeTail.protrusion : 0
    readonly property real edgeTailExtent: root.edgeTailPresent
        ? edgeTail.windowGrowth : 0
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
        + (root.edgeTailPresent && !root.edgeTailHorizontal
            ? root.edgeTailExtent : 0)
    implicitHeight: root.mediaExtent + (root.mediaOnly
        ? 0
        : root.surfaceContentHeight + root.contentFramePadding * 2)
        + (root.edgeTailPresent && root.edgeTailHorizontal
            ? root.edgeTailExtent : 0)
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

    function backgroundFrameInset(side) {
        const insets = menuBackground["inset"]
        if (!insets) {
            return 0
        }
        const requestedInset = Number(insets[side])
        return Number.isFinite(requestedInset)
            ? Math.max(0, requestedInset)
            : 0
    }

    function effectiveBackgroundWindowRect() {
        if (!root.drawContentBackground || root.mediaOnly
                || menuBackground.width <= 0
                || menuBackground.height <= 0) {
            return Qt.rect(0, 0, 0, 0)
        }
        const leftInset = root.backgroundFrameInset("left")
        const topInset = root.backgroundFrameInset("top")
        const rightInset = root.backgroundFrameInset("right")
        const bottomInset = root.backgroundFrameInset("bottom")
        if (leftInset + rightInset >= menuBackground.width
                || topInset + bottomInset >= menuBackground.height) {
            return Qt.rect(0, 0, 0, 0)
        }
        const topLeft = menuBackground.mapToItem(
            null, Qt.point(leftInset, topInset))
        const bottomRight = menuBackground.mapToItem(null, Qt.point(
            menuBackground.width - rightInset,
            menuBackground.height - bottomInset))
        return Qt.rect(
            Math.round(Math.min(topLeft.x, bottomRight.x)),
            Math.round(Math.min(topLeft.y, bottomRight.y)),
            Math.max(0, Math.round(Math.abs(bottomRight.x - topLeft.x))),
            Math.max(0, Math.round(Math.abs(bottomRight.y - topLeft.y))))
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

    HoverHandler {
        id: surfaceHover
    }

    MediaControlsCard {
        id: mediaCard
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: root.edgeTailPresent && root.edgeTailHorizontal
            && root.edgeTailBandOnStart ? root.edgeTailExtent : 0
        anchors.leftMargin: root.edgeTailPresent && !root.edgeTailHorizontal
            && root.edgeTailBandOnStart ? root.edgeTailExtent : 0
        anchors.rightMargin: root.edgeTailPresent && !root.edgeTailHorizontal
            && !root.edgeTailBandOnStart ? root.edgeTailExtent : 0
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
        opacity: root.mediaRevealProgress
        scale: 0.98 + (0.02 * root.mediaRevealProgress)
        transform: Translate {
            y: 6 * (1 - root.mediaRevealProgress)
        }

        onImplicitHeightChanged: root.updateMediaExtent()
        onCloseRequested: root.mediaCloseRequested()
    }

    // Band that carries the optional tail. It starts at the effective background
    // edge of the frame, which is the border the user sees and the one the blur
    // region measures, and the clip keeps the rest of the lobe off the card.
    FolderPopupTail {
        id: edgeTail
        visible: root.edgeTailPresent
        clip: true
        // The band joins the card edge, so it paints over the card shadow strip
        // at the junction instead of leaving a seam there.
        z: menuBackground.z + 1
        location: root.edgeTailLocation
        surfaceOpacity: menuBackground.opacity
        tipOffset: root.edgeTailTipOffset
        anchorExtent: root.edgeTailAnchorExtent
        frameInsetLeft: menuBackground.inset.left
        frameInsetTop: menuBackground.inset.top
        frameInsetRight: menuBackground.inset.right
        frameInsetBottom: menuBackground.inset.bottom
        x: !root.edgeTailHorizontal
            ? (root.edgeTailBandOnStart
                ? menuBackground.x + root.backgroundFrameInset("left")
                    - root.edgeTailProtrusion
                : menuBackground.x + menuBackground.width
                    - root.backgroundFrameInset("right"))
            : 0
        y: root.edgeTailHorizontal
            ? (root.edgeTailBandOnStart
                ? menuBackground.y + root.backgroundFrameInset("top")
                    - root.edgeTailProtrusion
                : menuBackground.y + menuBackground.height
                    - root.backgroundFrameInset("bottom"))
            : 0
        width: root.edgeTailHorizontal
            ? root.width : root.edgeTailProtrusion
        height: root.edgeTailHorizontal
            ? root.edgeTailProtrusion : root.height
    }

    KSvg.FrameSvgItem {
        id: menuBackground
        // The frame keeps its own size, so the popup background and its blur
        // region do not change: only its position moves by the tail band.
        x: root.edgeTailPresent && root.edgeTailBandOnStart
            && !root.edgeTailHorizontal ? root.edgeTailExtent : 0
        y: root.mediaExtent + (root.edgeTailPresent && root.edgeTailBandOnStart
            && root.edgeTailHorizontal ? root.edgeTailExtent : 0)
        width: root.width - (root.edgeTailPresent && !root.edgeTailHorizontal
            ? root.edgeTailExtent : 0)
        height: root.surfaceContentHeight + root.contentFramePadding * 2
        imagePath: root.backgroundImagePath
        visible: root.drawContentBackground && !root.mediaOnly
        opacity: root.safeBackgroundOpacity
        Accessible.ignored: true
    }
    // Mask contract consumed by the owning dialog's BlurBehindController. The
    // frame does not fill the window, so its own origin and insets define the
    // requested region instead of the window bounds or the theme shadow.
    PunchiMenuComponents.PunchiMenuMappedSurfaceGeometry {
        id: mappedSurfaceGeometry
        targetItem: root
        surfaceItem: root.effectiveBlurTransformSurface
        backgroundItem: menuBackground
        translationX: root.blurTranslationX
        translationY: root.blurTranslationY
        leftInset: menuBackground.inset.left
        topInset: menuBackground.inset.top
        rightInset: menuBackground.inset.right
        bottomInset: menuBackground.inset.bottom
    }
    Item {
        id: contentHost
        // The content follows the frame, so a tail band moves the content with
        // the card instead of resizing it.
        x: menuBackground.x + root.contentFramePadding
        y: menuBackground.y + root.contentFramePadding
        width: Math.max(0, menuBackground.width - root.contentFramePadding * 2)
        height: root.surfaceContentHeight
        visible: !root.mediaOnly
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
