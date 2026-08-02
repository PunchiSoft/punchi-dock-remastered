pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Effects as Effects
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

FocusScope {
    id: root
    scale: root.clickScale

    // Plasma provides translation functions in the applet context.
    // qmllint disable unqualified
    property var controller: null
    property int iconSize: 48
    property bool vertical: false
    property bool motionEnabled: true
    property bool contextMenuEnabled: true
    property bool launchAvailable: false
    property string defaultPlayerName: ""
    property string defaultPlayerIcon: ""
    property string textMode: "automatic"
    property string displayMode: "normal"
    property int motionSpeedPercent: 100
    property int autoCollapseDelaySeconds: 3
    property int expandedMainAxisLength: Math.round(Math.max(120,
        Math.min(320, iconSize * 4.2)))
    property bool expanded: true
    property real displayedPositionUs: 0
    readonly property bool available: !!controller && controller.available
    readonly property string artUrl: available && controller.artUrl
        ? String(controller.artUrl)
        : ""
    readonly property int controlExtent: Math.round(Math.max(22,
        Math.min(32, iconSize * 0.58)))
    readonly property int coverExtent: Math.max(16, iconSize - 8)
    readonly property string launchActionText: defaultPlayerName.length > 0
        ? i18nc("@action:button", "Open %1", defaultPlayerName)
        : i18nc("@action:button", "Open the default media player")
    readonly property string elapsedText: formatTime(displayedPositionUs)
    readonly property string durationText: available && controller.lengthUs > 0
        ? formatTime(controller.lengthUs)
        : ""
    readonly property string timeText: durationText.length > 0
        ? i18nc("@info:media elapsed and total duration", "%1 / %2", elapsedText, durationText)
        : ""
    readonly property string metadataText: resolvedMetadataText()
    readonly property string metadataMovementKey: resolvedMetadataMovementKey()
    readonly property string normalizedTextMode: textMode === "always"
        || textMode === "hidden" ? textMode : "automatic"
    readonly property bool compactMode: displayMode === "compact"
    readonly property bool narrowVerticalLayout: vertical
        && width < Kirigami.Units.gridUnit * 5
    readonly property bool metadataVisible: normalizedTextMode === "always"
        || (normalizedTextMode === "automatic" && !narrowVerticalLayout)
    readonly property int compactMainAxisLength: iconSize
    readonly property int resolvedMotionSpeedPercent: Math.max(50,
        Math.min(150, Number.isFinite(motionSpeedPercent)
            ? Math.round(motionSpeedPercent)
            : 100))
    readonly property int resolvedAutoCollapseDelaySeconds: Math.max(0,
        Math.min(30, Number.isFinite(autoCollapseDelaySeconds)
            ? Math.round(autoCollapseDelaySeconds)
            : 3))
    readonly property int morphDuration: Math.round(200 * 100
        / resolvedMotionSpeedPercent)
    property real currentMainAxisLength: !compactMode || expanded
        ? expandedMainAxisLength
        : compactMainAxisLength
    property real expandedContentOpacity: !compactMode || expanded ? 1.0 : 0.0
    property real compactContentOpacity: compactMode && !expanded ? 1.0 : 0.0
    readonly property string accessibleDescription: available
        ? (controller.playing
            ? i18nc("@info:accessible", "%1. Playing.", metadataText)
            : i18nc("@info:accessible", "%1. Paused.", metadataText))
        : i18nc("@info:accessible", "No MPRIS player is active")
    readonly property bool interactionActive: hoverHandler.hovered || activeFocus
    readonly property bool interactionPaused: interactionActive

    signal contextMenuRequested(bool keyboardInvoked)
    signal hoverChanged(bool hovered)
    signal expansionChanged(bool expanded, int transitionDuration)
    signal launchRequested()
    signal playbackLaunchRequested()

    Accessible.role: Accessible.Grouping
    Accessible.name: i18nc("@info:accessible", "Media player controls")
    Accessible.description: accessibleDescription

    property real clickScale: 1.0

    Behavior on clickScale {
        enabled: root.motionEnabled && Kirigami.Units.longDuration > 0
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutQuad
        }
    }

    Behavior on currentMainAxisLength {
        enabled: root.motionEnabled && Kirigami.Units.longDuration > 0
        NumberAnimation {
            duration: root.expanded
                ? Math.round(180 * 100 / root.resolvedMotionSpeedPercent)
                : Math.round(140 * 100 / root.resolvedMotionSpeedPercent)
            easing.type: root.expanded ? Easing.OutCubic : Easing.InCubic
        }
    }

    Behavior on expandedContentOpacity {
        enabled: root.motionEnabled && Kirigami.Units.longDuration > 0
        NumberAnimation {
            duration: root.expanded
                ? Math.round(160 * 100 / root.resolvedMotionSpeedPercent)
                : Math.round(100 * 100 / root.resolvedMotionSpeedPercent)
            easing.type: root.expanded ? Easing.OutCubic : Easing.InQuad
        }
    }

    Behavior on compactContentOpacity {
        enabled: root.motionEnabled && Kirigami.Units.longDuration > 0
        NumberAnimation {
            duration: root.expanded
                ? Math.round(100 * 100 / root.resolvedMotionSpeedPercent)
                : Math.round(140 * 100 / root.resolvedMotionSpeedPercent)
            easing.type: root.expanded ? Easing.InQuad : Easing.OutCubic
        }
    }

    function formatTime(microseconds) {
        const totalSeconds = Math.max(0, Math.floor(Number(microseconds || 0) / 1000000))
        const hours = Math.floor(totalSeconds / 3600)
        const minutes = Math.floor((totalSeconds % 3600) / 60)
        const seconds = totalSeconds % 60
        if (hours > 0) {
            return String(hours) + ":" + String(minutes).padStart(2, "0")
                + ":" + String(seconds).padStart(2, "0")
        }
        return String(minutes) + ":" + String(seconds).padStart(2, "0")
    }

    function resolvedMetadataText() {
        if (!available) {
            return defaultPlayerName.length > 0
                ? i18nc("@info:media", "%1 is not running", defaultPlayerName)
                : i18nc("@info:media", "No media playing")
        }
        const title = controller.track
            ? String(controller.track)
            : (controller.identity ? String(controller.identity) : i18n("Media playback"))
        const artist = controller.artist ? String(controller.artist) : ""
        if (artist.length > 0 && timeText.length > 0) {
            return i18nc("@info:media artist, title and playback time", "%1 — %2 — %3",
                artist, title, timeText)
        }
        if (artist.length > 0) {
            return i18nc("@info:media artist and title", "%1 — %2", artist, title)
        }
        if (timeText.length > 0) {
            return i18nc("@info:media title and playback time", "%1 — %2", title, timeText)
        }
        return title
    }

    function resolvedMetadataMovementKey() {
        if (!available) {
            return "inactive\u001f" + defaultPlayerName
        }
        const identity = controller.identity ? String(controller.identity) : ""
        const artist = controller.artist ? String(controller.artist) : ""
        const title = controller.track ? String(controller.track) : ""
        return "active\u001f" + identity + "\u001f" + artist + "\u001f" + title
            + "\u001f" + durationText
    }

    function syncDisplayedPosition() {
        displayedPositionUs = available && controller.lengthUs > 0
            ? Math.min(controller.lengthUs, Math.max(0, controller.positionUs))
            : 0
    }

    function focusFirstControl() {
        if (previousButton.enabled) {
            previousButton.forceActiveFocus(Qt.TabFocusReason)
            return true
        }
        if (playPauseButton.enabled) {
            playPauseButton.forceActiveFocus(Qt.TabFocusReason)
            return true
        }
        if (nextButton.enabled) {
            nextButton.forceActiveFocus(Qt.TabFocusReason)
            return true
        }
        playPauseButton.forceActiveFocus(Qt.TabFocusReason)
        return true
    }

    component MarqueeViewport: Item {
        id: marqueeRoot

        required property string displayText
        required property string movementKey
        property bool verticalFlow: false
        property bool movementAllowed: true
        property bool movementPaused: false
        property real offset: 0
        readonly property real travel: Math.max(0,
            movingLabel.implicitWidth - movementSurface.width)
        readonly property bool overflowing: travel > 1
        readonly property bool shouldMove: overflowing
            && movementAllowed
            && !movementPaused
            && visible
        readonly property int travelDuration: Math.max(1800,
            Math.min(14000, Math.round(travel * 38)))

        clip: true
        Accessible.ignored: true

        onShouldMoveChanged: {
            if (!shouldMove) {
                marqueeAnimation.stop()
                offset = 0
            } else {
                marqueeAnimation.restart()
            }
        }
        onMovementKeyChanged: {
            offset = 0
            Qt.callLater(function() {
                if (marqueeRoot.shouldMove) {
                    marqueeAnimation.restart()
                }
            })
        }

        Item {
            id: movementSurface

            anchors.centerIn: parent
            width: marqueeRoot.verticalFlow ? marqueeRoot.height : marqueeRoot.width
            height: marqueeRoot.verticalFlow ? marqueeRoot.width : marqueeRoot.height
            rotation: marqueeRoot.verticalFlow ? 90 : 0

            Controls.Label {
                id: movingLabel

                x: -marqueeRoot.offset
                y: 0
                width: marqueeRoot.movementAllowed
                    ? implicitWidth
                    : movementSurface.width
                height: movementSurface.height
                text: marqueeRoot.displayText
                textFormat: Text.PlainText
                wrapMode: Text.NoWrap
                elide: marqueeRoot.movementAllowed
                    ? Text.ElideNone
                    : Text.ElideRight
                maximumLineCount: 1
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: root.available ? 0.92 : 0.68
            }
        }

        SequentialAnimation {
            id: marqueeAnimation
            loops: Animation.Infinite
            alwaysRunToEnd: false

            PauseAnimation { duration: 900 }
            NumberAnimation {
                target: marqueeRoot
                property: "offset"
                from: 0
                to: marqueeRoot.travel
                duration: marqueeRoot.travelDuration
                easing.type: Easing.Linear
            }
            PauseAnimation { duration: 900 }
            NumberAnimation {
                target: marqueeRoot
                property: "offset"
                to: 0
                duration: Math.max(500, Math.min(1200,
                    Math.round(marqueeRoot.travelDuration * 0.2)))
                easing.type: Easing.OutCubic
            }
        }
    }

    HoverHandler {
        id: hoverHandler
        onHoveredChanged: root.hoverChanged(hovered)
    }

    Timer {
        id: collapseTimer
        interval: Math.max(1, root.resolvedAutoCollapseDelaySeconds * 1000)
        repeat: false
        running: root.visible && root.compactMode && root.expanded
            && root.resolvedAutoCollapseDelaySeconds > 0
            && !root.interactionActive
        onTriggered: {
            if (!root.interactionActive) {
                root.expanded = false
            }
        }
    }

    onInteractionActiveChanged: {
        if (!compactMode || interactionActive) {
            expanded = true
        }
    }

    onCompactModeChanged: {
        if (!compactMode && !expanded) {
            expanded = true
        } else {
            expansionChanged(!compactMode || expanded, Math.round(220 * 100
                / resolvedMotionSpeedPercent))
        }
    }

    onExpandedChanged: expansionChanged(expanded, Math.round(220 * 100
        / resolvedMotionSpeedPercent))

    Controls.ToolTip {
        visible: root.vertical && !root.metadataVisible && hoverHandler.hovered
        text: root.metadataText
        delay: Kirigami.Units.toolTipDelay
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        enabled: root.contextMenuEnabled
        onTapped: root.contextMenuRequested(false)
    }

    Keys.onPressed: function(event) {
        if (root.contextMenuEnabled && (event.key === Qt.Key_Menu
                || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier)))) {
            root.contextMenuRequested(true)
            event.accepted = true
        }
    }

    Connections {
        target: root.controller
        ignoreUnknownSignals: true
        function onStateChanged() {
            root.syncDisplayedPosition()
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.visible && root.available && root.controller.playing
            && root.controller.lengthUs > 0
        onTriggered: root.displayedPositionUs = Math.min(
            root.controller.lengthUs, root.displayedPositionUs + 1000000)
    }

    onControllerChanged: syncDisplayedPosition()
    Component.onCompleted: syncDisplayedPosition()

    Rectangle {
        anchors.fill: parent
        visible: opacity > 0.01
        radius: Math.max(4, Math.round(Math.min(width, height) * 0.16))
        color: Kirigami.Theme.alternateBackgroundColor
        opacity: root.expandedContentOpacity
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r,
            Kirigami.Theme.textColor.g,
            Kirigami.Theme.textColor.b, 0.18)
    }

    Kirigami.Icon {
        id: compactPlayerIcon
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        source: root.defaultPlayerIcon.length > 0
            ? root.defaultPlayerIcon
            : "emblem-music-symbolic"
        fallback: "emblem-music-symbolic"
        isMask: String(source).indexOf("-symbolic") >= 0
        opacity: root.compactContentOpacity
        visible: opacity > 0.01
        Accessible.ignored: true

        HoverHandler {
            cursorShape: root.launchAvailable && !root.available && root.compactMode
                ? Qt.PointingHandCursor
                : Qt.ArrowCursor
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            enabled: root.launchAvailable && !root.available && root.compactMode
            onPressedChanged: root.clickScale = pressed ? 0.94 : 1.0
            onTapped: root.launchRequested()
        }
    }

    GridLayout {
        id: mediaLayout
        anchors.fill: parent
        anchors.margins: 2
        visible: opacity > 0.01
        opacity: root.expandedContentOpacity
        columns: root.vertical ? 1 : 2
        rows: root.vertical ? (root.metadataVisible ? 3 : 2) : 2
        rowSpacing: 2
        columnSpacing: 4

        Rectangle {
            id: coverFrame
            Layout.preferredWidth: root.coverExtent
            Layout.preferredHeight: root.coverExtent
            Layout.alignment: Qt.AlignCenter
            Layout.row: 0
            Layout.column: 0
            Layout.rowSpan: root.vertical ? 1 : 2
            radius: Math.max(3, Math.round(width * 0.16))
            color: Kirigami.Theme.backgroundColor

            Image {
                id: artworkSource
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: status === Image.Ready
                layer.enabled: visible
                layer.effect: Effects.MultiEffect {
                    maskEnabled: true
                    maskSource: artworkMask
                }
            }

            Item {
                id: artworkMask
                anchors.fill: parent
                visible: false
                layer.enabled: true

                Rectangle {
                    anchors.fill: parent
                    radius: coverFrame.radius
                    color: "white"
                }
            }

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Math.max(16, parent.width * 0.64)
                height: width
                source: root.defaultPlayerIcon.length > 0
                    ? root.defaultPlayerIcon
                    : "emblem-music-symbolic"
                fallback: "emblem-music-symbolic"
                visible: artworkSource.status !== Image.Ready
                isMask: String(source).indexOf("-symbolic") >= 0
            }

            HoverHandler {
                cursorShape: root.launchAvailable && !root.available
                    ? Qt.PointingHandCursor
                    : Qt.ArrowCursor
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                enabled: root.launchAvailable && !root.available
                onPressedChanged: root.clickScale = pressed ? 0.94 : 1.0
                onTapped: root.launchRequested()
            }
        }

        ColumnLayout {
            id: metadataArea
            Layout.fillWidth: !root.vertical
            Layout.fillHeight: !root.vertical
            Layout.preferredWidth: root.vertical ? root.coverExtent : -1
            Layout.preferredHeight: root.vertical ? Math.max(root.controlExtent * 1.8,
                root.height - root.coverExtent - transportControls.implicitHeight - 8) : -1
            Layout.row: root.vertical ? 1 : 0
            Layout.column: root.vertical ? 0 : 1
            spacing: 1
            visible: !root.vertical || root.metadataVisible

            MarqueeViewport {
                id: metadataViewport
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: Math.max(14, Kirigami.Units.gridUnit)
                visible: root.metadataVisible
                displayText: root.metadataText
                movementKey: root.metadataMovementKey
                verticalFlow: root.vertical
                movementAllowed: root.motionEnabled
                movementPaused: root.interactionPaused
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: Math.max(14, Kirigami.Units.gridUnit)
                visible: !root.metadataVisible

                Controls.ProgressBar {
                    anchors.centerIn: parent
                    width: root.vertical ? parent.height : parent.width
                    height: Math.max(4, Kirigami.Units.smallSpacing)
                    rotation: root.vertical ? 90 : 0
                    from: 0
                    to: root.available && root.controller.lengthUs > 0
                        ? root.controller.lengthUs
                        : 1
                    value: root.available && root.controller.lengthUs > 0
                        ? root.displayedPositionUs
                        : 0
                    Accessible.ignored: true
                }
            }

            Controls.ToolTip {
                visible: metadataHover.hovered
                text: root.metadataText
                delay: Kirigami.Units.toolTipDelay
            }

            HoverHandler {
                id: metadataHover
            }

        }

        GridLayout {
            id: transportControls
            Layout.alignment: Qt.AlignCenter
            Layout.row: root.vertical ? (root.metadataVisible ? 2 : 1) : 1
            Layout.column: root.vertical ? 0 : 1
            flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
            columns: root.vertical ? 1 : 3
            rows: root.vertical ? 3 : 1
            rowSpacing: 1
            columnSpacing: 1

            PlasmaComponents.ToolButton {
                id: previousButton
                Layout.preferredWidth: root.controlExtent
                Layout.preferredHeight: root.controlExtent
                text: i18nc("@action:button", "Previous track")
                display: PlasmaComponents.AbstractButton.IconOnly
                icon.name: Application.layoutDirection === Qt.RightToLeft
                    ? "media-skip-forward"
                    : "media-skip-backward"
                enabled: root.available && root.controller.canControl
                    && root.controller.canGoPrevious
                Accessible.name: text
                onClicked: root.controller.previous()
                KeyNavigation.tab: playPauseButton
            }

            PlasmaComponents.ToolButton {
                id: playPauseButton
                Layout.preferredWidth: root.controlExtent
                Layout.preferredHeight: root.controlExtent
                text: root.available && root.controller.playing
                    ? i18nc("@action:button", "Pause")
                    : i18nc("@action:button", "Play")
                display: PlasmaComponents.AbstractButton.IconOnly
                icon.name: root.available && root.controller.playing
                    ? "media-playback-pause"
                    : "media-playback-start"
                enabled: (!root.available && root.launchAvailable)
                    || (root.available && root.controller.canControl
                        && ((root.controller.playing && root.controller.canPause)
                            || (!root.controller.playing && root.controller.canPlay)))
                Accessible.name: text
                Accessible.description: !root.available && root.launchAvailable
                    ? root.launchActionText
                    : ""
                onClicked: {
                    if (!root.available && root.launchAvailable) {
                        root.playbackLaunchRequested()
                    } else {
                        root.controller.togglePlaying()
                    }
                }
                KeyNavigation.tab: nextButton
            }

            PlasmaComponents.ToolButton {
                id: nextButton
                Layout.preferredWidth: root.controlExtent
                Layout.preferredHeight: root.controlExtent
                text: i18nc("@action:button", "Next track")
                display: PlasmaComponents.AbstractButton.IconOnly
                icon.name: Application.layoutDirection === Qt.RightToLeft
                    ? "media-skip-backward"
                    : "media-skip-forward"
                enabled: root.available && root.controller.canControl
                    && root.controller.canGoNext
                Accessible.name: text
                onClicked: root.controller.next()
                KeyNavigation.tab: previousButton
            }
        }
    }
}
// qmllint enable unqualified
