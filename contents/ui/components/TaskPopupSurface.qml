pragma ComponentBehavior: Bound

import QtQuick
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami

Item {
    id: root

    default property alias contentData: contentHost.data

    property string presentationMode: "none"
    property var mediaController: null
    property var taskControllerRef: null
    property var mediaWindows: []
    property string mediaIcon: "emblem-music-symbolic"
    property bool mediaActionsComposed: false
    property real backgroundOpacity: 1.0
    property real contentFramePaddingPercent: 0
    property real contentFramePaddingScale: 1.0
    property real minimumSurfaceWidth: 0
    property real minimumSurfaceHeight: 0
    property real maximumSurfaceWidth: 752
    property real maximumSurfaceHeight: 640
    property Component backgroundComponent: defaultBackgroundComponent
    property Component replacementProfileComponentOverride: null
    property bool replacementHeaderControlsEnabled: true

    readonly property Item contentItem: contentHost.children.length > 0
        ? contentHost.children[0]
        : null
    readonly property bool replacementMediaPresentation:
        presentationMode === "card" || presentationMode === "fullCard"
    readonly property bool surfacePresentationActive:
        presentationMode !== "none" && presentationMode !== "waiting"
    readonly property bool contentPresentation:
        presentationMode === "preview" || presentationMode === "overlay"
            || mediaActionsComposed
    readonly property bool compactMediaPresentation:
        replacementMediaPresentation && mediaActionsComposed
    readonly property real containedCardHeight: 420 + 28
        + Kirigami.Units.smallSpacing * 2
    readonly property real fullCoverCardHeight: 380
    readonly property real compactCardHeight: 88 + 28
        + Kirigami.Units.smallSpacing * 2
    readonly property real maximumAdaptiveFramePaddingReservation:
        contentFramePaddingPercent > 0 ? Kirigami.Units.gridUnit * 2 : 0
    readonly property real maximumHorizontalFramePaddingReservation: Math.max(
        maximumAdaptiveFramePaddingReservation,
        contentPaddingLeft + contentPaddingRight)
    readonly property real maximumVerticalFramePaddingReservation: Math.max(
        maximumAdaptiveFramePaddingReservation,
        contentPaddingTop + contentPaddingBottom)
    readonly property real maximumFramePaddingReservation: Math.max(
        maximumHorizontalFramePaddingReservation,
        maximumVerticalFramePaddingReservation)
    readonly property real maximumContentWidth: Math.max(1,
        maximumSurfaceWidth - maximumHorizontalFramePaddingReservation)
    readonly property real maximumContentHeight: Math.max(1,
        maximumSurfaceHeight - maximumVerticalFramePaddingReservation
            - (compactMediaPresentation
                ? compactCardHeight + Kirigami.Units.smallSpacing
                : 0))
    readonly property real mediaContentWidth: replacementMediaPresentation ? 280 : 0
    readonly property real mediaContentHeight: replacementMediaPresentation
        ? (compactMediaPresentation
            ? compactCardHeight
            : (presentationMode === "fullCard"
                ? fullCoverCardHeight
                : containedCardHeight))
        : 0
    readonly property real contentImplicitWidth: contentPresentation && contentItem
        ? Math.max(0, Number(contentItem.implicitWidth))
        : 0
    readonly property real contentImplicitHeight: contentPresentation && contentItem
        ? Math.max(0, Number(contentItem.implicitHeight))
        : 0
    readonly property real contentGap: replacementMediaPresentation
            && mediaActionsComposed
        ? Kirigami.Units.smallSpacing
        : 0
    readonly property real internalWidth: Math.max(
        Math.max(0, minimumSurfaceWidth), mediaContentWidth, contentImplicitWidth)
    readonly property real internalHeight: Math.max(0, minimumSurfaceHeight,
        mediaContentHeight + contentGap + contentImplicitHeight)
    readonly property real contentFramePadding: {
        const requestedPercent = Number(root.contentFramePaddingPercent)
        if (!Number.isFinite(requestedPercent) || requestedPercent <= 0) {
            return 0
        }
        const shortSide = Math.min(root.internalWidth, root.internalHeight)
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
    // FrameSvg margins describe the theme-approved content area. They are
    // intentionally distinct from mask insets, which delimit blur and shadow.
    // qmllint disable missing-property
    readonly property var themedContentMargins: themedBackgroundLoader.item
        ? themedBackgroundLoader.item["margins"]
        : null
    // qmllint enable missing-property
    readonly property bool themedContentMarginsValid: {
        const margins = root.themedContentMargins
        if (!margins) {
            return false
        }
        const left = Number(margins.left)
        const top = Number(margins.top)
        const right = Number(margins.right)
        const bottom = Number(margins.bottom)
        return Number.isFinite(left) && left >= 0
            && Number.isFinite(top) && top >= 0
            && Number.isFinite(right) && right >= 0
            && Number.isFinite(bottom) && bottom >= 0
            && left + right < Math.max(1, root.internalWidth)
            && top + bottom < Math.max(1, root.internalHeight)
    }
    // The configured frame profile owns visual density. Theme margins remain
    // the safe fallback only when no explicit popup frame was requested; using
    // the full margin in addition to the 2% profile creates a double gutter.
    readonly property real contentPaddingLeft: contentFramePadding > 0
        ? contentFramePadding
        : (themedContentMarginsValid ? Number(themedContentMargins.left) : 0)
    readonly property real contentPaddingTop: contentFramePadding > 0
        ? contentFramePadding
        : (themedContentMarginsValid ? Number(themedContentMargins.top) : 0)
    readonly property real contentPaddingRight: contentFramePadding > 0
        ? contentFramePadding
        : (themedContentMarginsValid ? Number(themedContentMargins.right) : 0)
    readonly property real contentPaddingBottom: contentFramePadding > 0
        ? contentFramePadding
        : (themedContentMarginsValid ? Number(themedContentMargins.bottom) : 0)
    readonly property real safeBackgroundOpacity: {
        const requestedOpacity = Number(root.backgroundOpacity)
        return Number.isFinite(requestedOpacity)
            ? Math.max(0.5, Math.min(1.0, requestedOpacity))
            : 1.0
    }
    // Loader.item is intentionally dynamic because tests can inject lightweight
    // visual components while Plasma uses the concrete replacement card.
    // qmllint disable missing-property
    readonly property bool containsMouse: surfaceHover.hovered
        || (replacementMediaPresentation && replacementMediaLoader.item
            && replacementMediaLoader.item["activeFocus"])
    readonly property bool geometryReady: surfacePresentationActive
        && Number.isFinite(implicitWidth) && implicitWidth > 0
        && Number.isFinite(implicitHeight) && implicitHeight > 0
        && themedBackgroundLoader.status === Loader.Ready
        && (!replacementMediaPresentation
            || (mediaContentWidth > 0 && mediaContentHeight > 0
                && replacementMediaLoader.status === Loader.Ready
                && replacementMediaLoader.item
                && replacementMediaLoader.item["contentReady"]))
    // qmllint enable missing-property

    implicitWidth: internalWidth + contentPaddingLeft + contentPaddingRight
    implicitHeight: internalHeight + contentPaddingTop + contentPaddingBottom
    width: implicitWidth
    height: implicitHeight
    clip: true

    signal mediaCloseRequested()

    function focusMediaControls() {
        // qmllint disable missing-property
        return root.replacementMediaPresentation
            && replacementMediaLoader.item
            && replacementMediaLoader.item["focusFirstControl"]()
        // qmllint enable missing-property
    }

    HoverHandler {
        id: surfaceHover
    }

    Component {
        id: defaultBackgroundComponent

        KSvg.FrameSvgItem {
            imagePath: "widgets/background"
            Accessible.ignored: true
        }
    }

    Loader {
        id: themedBackgroundLoader
        anchors.fill: parent
        active: root.surfacePresentationActive
        opacity: root.safeBackgroundOpacity
        sourceComponent: root.backgroundComponent
    }

    Loader {
        id: replacementMediaLoader
        x: root.contentPaddingLeft
        y: root.contentPaddingTop
        width: root.internalWidth
        height: root.mediaContentHeight
        active: root.replacementMediaPresentation

        sourceComponent: Component {
            MprisReplacementCard {
                controller: root.mediaController
                taskControllerRef: root.taskControllerRef
                windows: root.mediaWindows
                fallbackIcon: root.mediaIcon
                profile: root.compactMediaPresentation
                    ? "compact"
                    : root.presentationMode
                containedProfileHeight: root.containedCardHeight
                fullCoverProfileHeight: root.fullCoverCardHeight
                compactProfileHeight: root.compactCardHeight
                profileComponentOverride: root.replacementProfileComponentOverride
                headerControlsEnabled: root.replacementHeaderControlsEnabled

                onCloseRequested: root.mediaCloseRequested()
            }
        }
    }

    Item {
        id: contentHost
        x: root.contentPaddingLeft
        y: root.contentPaddingTop + root.mediaContentHeight + root.contentGap
        width: root.internalWidth
        height: root.contentImplicitHeight
        visible: root.contentPresentation
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
