import QtQuick
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami

Item {
    id: root

    default property alias contentData: contentHost.data
    property var mediaController: null
    property string mediaIcon: "emblem-music-symbolic"
    property bool showMedia: true
    property bool mediaOnly: false
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
    readonly property bool compactMedia: mediaVisible && !fullMediaFits
    property real mediaExtent: 0
    property real mediaRevealProgress: 0
    readonly property bool containsMouse: surfaceHover.hovered || mediaCard.activeFocus

    signal mediaCloseRequested()

    implicitWidth: Math.max(contentImplicitWidth, mediaVisible ? 280 : 0)
    implicitHeight: contentImplicitHeight + mediaExtent
    width: implicitWidth
    height: implicitHeight

    function updateMediaPresentation() {
        if (!mediaVisible) {
            mediaRevealProgress = 0
            mediaExtent = 0
            return
        }

        mediaExtent = mediaCard.implicitHeight + mediaGap
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

    onMediaVisibleChanged: updateMediaPresentation()
    onCompactMediaChanged: updateMediaPresentation()
    onMediaOnlyChanged: updateMediaPresentation()

    Component.onCompleted: updateMediaPresentation()

    Behavior on mediaExtent {
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on mediaRevealProgress {
        NumberAnimation {
            duration: Kirigami.Units.longDuration
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
        fallbackIcon: root.mediaIcon
        compact: root.compactMedia
        squarePresentation: root.mediaOnly
        visible: root.mediaVisible || root.mediaExtent > 0.5
        opacity: root.mediaRevealProgress
        scale: 0.98 + (0.02 * root.mediaRevealProgress)
        transform: Translate {
            y: 6 * (1 - root.mediaRevealProgress)
        }

        onImplicitHeightChanged: root.updateMediaPresentation()
        onCloseRequested: root.mediaCloseRequested()
    }

    KSvg.FrameSvgItem {
        id: menuBackground
        x: 0
        y: root.mediaExtent
        width: root.width
        height: Math.max(0, root.height - root.mediaExtent)
        imagePath: "dialogs/background"
        visible: !root.mediaOnly
    }

    Item {
        id: contentHost
        x: 0
        y: root.mediaExtent
        width: root.width
        height: Math.max(0, root.height - root.mediaExtent)
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
