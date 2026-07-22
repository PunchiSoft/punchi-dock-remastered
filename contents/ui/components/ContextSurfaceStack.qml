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
    property bool showMedia: true
    property bool mediaOnly: false
    property bool forceCompactMedia: false
    property bool transitionsEnabled: true
    property bool contentGeometryTransitionsEnabled: true
    property bool surfaceStateFrozen: false
    property int transitionSpeedPercent: 100
    property real mediaGap: 2
    property real maximumAvailableHeight: 0
    readonly property Item contentItem: contentHost.children.length > 0
        ? contentHost.children[0]
        : null
    readonly property real contentImplicitWidth: !mediaOnly && contentItem ? contentItem.implicitWidth : 0
    readonly property real contentImplicitHeight: !mediaOnly && contentItem ? contentItem.implicitHeight : 0
    readonly property bool mediaRequested: showMedia
        && !!mediaController
        && mediaController.available
    readonly property bool fullMediaFits: maximumAvailableHeight <= 0
        || contentImplicitHeight + mediaGap + mediaCard.preferredExpandedHeight <= maximumAvailableHeight
    readonly property bool compactMediaFits: maximumAvailableHeight <= 0
        || contentImplicitHeight + mediaGap + mediaCard.compactPreferredHeight <= maximumAvailableHeight
    readonly property bool mediaVisible: mediaRequested && compactMediaFits
    readonly property bool mediaSurfacePresent: mediaVisible || mediaExtent > 0.5
    readonly property bool compactMedia: mediaVisible
        && (forceCompactMedia || !fullMediaFits)
    readonly property int transitionDuration: transitionsEnabled && Kirigami.Units.longDuration > 1
        ? Math.round(Kirigami.Units.longDuration * 100
            / Math.max(10, Math.min(200, transitionSpeedPercent)))
        : 0
    readonly property real requestedContentExtent: !mediaOnly && contentItem
        ? contentItem.implicitHeight
        : 0
    property real mediaExtent: 0
    property real contentWidthExtent: contentImplicitWidth
    property real contentExtent: requestedContentExtent
    property real mediaRevealProgress: 0
    readonly property bool containsMouse: surfaceHover.hovered
        || (mediaVisible && mediaCard.activeFocus)

    signal mediaCloseRequested()

    implicitWidth: Math.max(contentWidthExtent, mediaSurfacePresent ? 280 : 0)
    implicitHeight: contentExtent + mediaExtent
    width: implicitWidth
    height: implicitHeight

    function updateMediaExtent() {
        if (root.surfaceStateFrozen) {
            return
        }
        if (!mediaVisible) {
            mediaExtent = 0
            return
        }

        mediaExtent = mediaCard.implicitHeight + mediaGap
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

    onMediaVisibleChanged: updateMediaVisibility()
    onCompactMediaChanged: updateMediaExtent()
    onMediaOnlyChanged: updateMediaExtent()
    onSurfaceStateFrozenChanged: {
        if (!root.surfaceStateFrozen) {
            root.updateMediaVisibility()
        }
    }

    Component.onCompleted: updateMediaVisibility()

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
        controller: root.mediaController
        taskControllerRef: root.taskControllerRef
        windows: root.mediaWindows
        fallbackIcon: root.mediaIcon
        compact: root.compactMedia
        squarePresentation: root.mediaOnly
        transitionDuration: root.transitionDuration
        height: Math.max(0, root.mediaExtent - root.mediaGap)
        visible: root.mediaVisible || root.mediaExtent > 0.5
        opacity: root.mediaRevealProgress
        scale: 0.98 + (0.02 * root.mediaRevealProgress)
        transform: Translate {
            y: 6 * (1 - root.mediaRevealProgress)
        }

        onImplicitHeightChanged: root.updateMediaExtent()
        onCloseRequested: root.mediaCloseRequested()
    }

    KSvg.FrameSvgItem {
        id: menuBackground
        x: 0
        y: root.mediaExtent
        width: root.width
        height: root.contentExtent
        imagePath: "dialogs/background"
        visible: !root.mediaOnly
    }

    Item {
        id: contentHost
        x: 0
        y: root.mediaExtent
        width: root.width
        height: root.contentExtent
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
