pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects as Effects
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// Plasma provides the translation functions in the applet context.
// qmllint disable unqualified
FocusScope {
    id: root

    property var controller: null
    property var taskControllerRef: null
    property var windows: []
    property string fallbackIcon: "emblem-music-symbolic"
    property string profile: "card"
    property Component profileComponentOverride: null
    property bool headerControlsEnabled: true
    required property real containedProfileHeight
    required property real fullCoverProfileHeight
    required property real compactProfileHeight

    readonly property bool available: !!controller && controller.available
    readonly property bool compactProfile: profile === "compact"
    readonly property bool fullCoverProfile: profile === "fullCard"
    readonly property string artUrl: controller && controller.artUrl
        ? String(controller.artUrl)
        : ""
    readonly property string title: controller && controller.track
        ? controller.track
        : controller && controller.identity
            ? controller.identity
            : (available ? i18n("Media playback") : "")
    readonly property string subtitle: controller && controller.artist
        ? controller.artist
        : controller && controller.identity && controller.identity !== title
            ? controller.identity
            : (available ? i18n("MPRIS controls") : "")
    readonly property bool volumeAvailable: available && controller.volumeAvailable
    readonly property bool hasProgress: available && controller.lengthUs > 0
    property real displayedPositionUs: 0
    readonly property real playbackProgress: hasProgress
        ? Math.max(0, Math.min(1, displayedPositionUs / controller.lengthUs))
        : 0
    readonly property real cornerRadius: {
        const shortSide = Math.min(width, height)
        const themeRadius = Math.max(1, Number(Kirigami.Units.cornerRadius))
        const proportionalRadius = Number.isFinite(shortSide) && shortSide > 0
            ? shortSide * 0.04
            : themeRadius
        return Math.max(themeRadius, Math.min(themeRadius * 2,
            proportionalRadius))
    }
    readonly property real safeContentInset: Math.max(
        Kirigami.Units.smallSpacing, Math.round(cornerRadius))
    readonly property real headerControlEdgeAdjustment: 2
    readonly property real headerControlInset: Kirigami.Units.smallSpacing
        + Math.max(1, Math.round(Kirigami.Units.smallSpacing / 3))
        + headerControlEdgeAdjustment
    readonly property int closeTaskRow: preferredCloseTaskRow()
    readonly property bool canCloseWindow: !!taskControllerRef && closeTaskRow >= 0
    readonly property bool contentReady: available
        && profileLoader.status === Loader.Ready
        && (!headerControlsEnabled || headerControlsLoader.status === Loader.Ready)
    readonly property color overlayBackgroundColor: Kirigami.Theme.backgroundColor
    readonly property color overlayTextColor: Kirigami.Theme.textColor
    readonly property color overlaySecondaryTextColor: Kirigami.Theme.disabledTextColor

    implicitWidth: 280
    implicitHeight: compactProfile
        ? compactProfileHeight
        : (fullCoverProfile ? fullCoverProfileHeight : containedProfileHeight)
    clip: true
    Accessible.role: Accessible.Grouping
    Accessible.name: title

    signal closeRequested()

    function focusFirstControl() {
        // The active profile is selected through Loader and exposes this shared
        // method regardless of its concrete visual composition.
        // qmllint disable missing-property
        return profileLoader.item
            && typeof profileLoader.item["focusFirstControl"] === "function"
            && profileLoader.item["focusFirstControl"]()
        // qmllint enable missing-property
    }

    function preferredCloseTaskRow() {
        const sourceWindows = windows instanceof Array ? windows : []
        let fallbackRow = -1
        for (let index = 0; index < sourceWindows.length; index++) {
            const windowData = sourceWindows[index]
            if (!windowData || !windowData.closable) {
                continue
            }
            const row = Number(windowData.row)
            if (!Number.isFinite(row) || row < 0) {
                continue
            }
            if (windowData.active) {
                return row
            }
            if (fallbackRow < 0) {
                fallbackRow = row
            }
        }
        return fallbackRow
    }

    function closeAssociatedWindow() {
        if (!canCloseWindow) {
            return false
        }
        if (taskControllerRef.closeTaskRow(closeTaskRow)) {
            closeRequested()
            return true
        }
        return false
    }

    function syncDisplayedPosition() {
        displayedPositionUs = hasProgress
            ? Math.min(controller.lengthUs, Math.max(0, controller.positionUs))
            : 0
    }

    component PlaybackProgressBar: Item {
        id: progressRoot

        property real value: 0
        property bool active: false
        property bool lightAppearance: false

        implicitHeight: 4
        visible: active
        Accessible.role: Accessible.ProgressBar
        Accessible.name: i18nc("@info:accessible", "Playback progress")

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 2
            radius: height / 2
            color: progressRoot.lightAppearance
                ? Qt.rgba(1, 1, 1, 0.22)
                : Qt.rgba(Kirigami.Theme.textColor.r,
                    Kirigami.Theme.textColor.g,
                    Kirigami.Theme.textColor.b, 0.14)

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * progressRoot.value
                radius: parent.radius
                color: progressRoot.lightAppearance
                    ? Qt.rgba(1, 1, 1, 0.78)
                    : Kirigami.Theme.highlightColor
            }
        }
    }

    component ContainedProfile: Item {
        id: containedRoot

        function focusFirstControl() {
            return containedControls.focusFirstControl()
                || containedVolume.focusControl()
        }

        Item {
            id: containedCover
            x: root.safeContentInset
            y: root.safeContentInset + 28 + Kirigami.Units.smallSpacing
            width: Math.max(0,
                containedRoot.width - root.safeContentInset * 2)
            height: 256

            Rectangle {
                anchors.fill: parent
                radius: Math.max(1, root.cornerRadius - 2)
                color: Kirigami.Theme.backgroundColor
            }

            Image {
                id: containedCoverSource
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: false
                layer.enabled: true
            }

            Item {
                id: containedCoverMask
                anchors.fill: parent
                visible: false
                layer.enabled: true

                Rectangle {
                    anchors.fill: parent
                    radius: Math.max(1, root.cornerRadius - 2)
                    color: "black"
                }
            }

            Effects.MultiEffect {
                anchors.fill: parent
                source: containedCoverSource
                maskEnabled: true
                maskSource: containedCoverMask
                visible: containedCoverSource.status === Image.Ready
            }

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.huge
                height: width
                source: root.fallbackIcon
                visible: containedCoverSource.status !== Image.Ready
            }

            Rectangle {
                anchors.fill: parent
                radius: Math.max(1, root.cornerRadius - 2)
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                    Kirigami.Theme.textColor.g,
                    Kirigami.Theme.textColor.b, 0.16)
            }
        }

        PlaybackProgressBar {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: containedCover.bottom
            anchors.leftMargin: root.safeContentInset + 2
            anchors.rightMargin: root.safeContentInset + 2
            anchors.topMargin: 6
            active: root.hasProgress
            value: root.playbackProgress
        }

        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: containedCover.bottom
            anchors.leftMargin: root.safeContentInset
            anchors.rightMargin: root.safeContentInset
            anchors.topMargin: 14
            height: 40

            PlasmaComponents.Label {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 22
                text: root.title
                font.weight: Font.DemiBold
                font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            PlasmaComponents.Label {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 18
                text: root.subtitle
                color: Kirigami.Theme.disabledTextColor
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        MediaTransportControls {
            id: containedControls
            x: root.safeContentInset
            anchors.bottom: containedVolume.top
            anchors.bottomMargin: Kirigami.Units.smallSpacing
            width: Math.max(0,
                containedRoot.width - root.safeContentInset * 2)
            height: 52
            controller: root.controller
            prominentPlayButton: true
        }

        MediaVolumeControl {
            id: containedVolume
            x: root.safeContentInset
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.safeContentInset
            width: Math.max(0,
                containedRoot.width - root.safeContentInset * 2)
            height: 28
            controller: root.controller
        }
    }

    component FullCoverProfile: Item {
        id: fullCoverRoot

        function focusFirstControl() {
            return fullCoverControls.focusFirstControl()
                || fullCoverVolume.focusControl()
        }

        Image {
            id: fullCoverSource
            anchors.fill: parent
            source: root.artUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            visible: false
            layer.enabled: true
        }

        Item {
            id: fullCoverMask
            anchors.fill: parent
            visible: false
            layer.enabled: true

            Rectangle {
                anchors.fill: parent
                radius: root.cornerRadius
                color: "black"
            }
        }

        Effects.MultiEffect {
            anchors.fill: parent
            source: fullCoverSource
            maskEnabled: true
            maskSource: fullCoverMask
            visible: fullCoverSource.status === Image.Ready
        }

        Rectangle {
            anchors.fill: parent
            radius: root.cornerRadius
            visible: fullCoverSource.status !== Image.Ready
            color: Kirigami.Theme.backgroundColor

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.huge
                height: width
                source: root.fallbackIcon
                opacity: 0.25
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: root.cornerRadius
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Qt.rgba(root.overlayBackgroundColor.r,
                        root.overlayBackgroundColor.g,
                        root.overlayBackgroundColor.b, 0.28)
                }
                GradientStop {
                    position: 0.52
                    color: Qt.rgba(root.overlayBackgroundColor.r,
                        root.overlayBackgroundColor.g,
                        root.overlayBackgroundColor.b, 0.20)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(root.overlayBackgroundColor.r,
                        root.overlayBackgroundColor.g,
                        root.overlayBackgroundColor.b, 0.90)
                }
            }
        }

        MediaVolumeControl {
            id: fullCoverVolume
            x: root.safeContentInset
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.safeContentInset
            width: Math.max(0,
                fullCoverRoot.width - root.safeContentInset * 2)
            height: 28
            controller: root.controller
            lightAppearance: false
        }

        MediaTransportControls {
            id: fullCoverControls
            x: root.safeContentInset
            anchors.bottom: fullCoverVolume.top
            anchors.bottomMargin: Kirigami.Units.smallSpacing
            width: Math.max(0,
                fullCoverRoot.width - root.safeContentInset * 2)
            height: 52
            controller: root.controller
            prominentPlayButton: true
            lightAppearance: false
        }

        PlaybackProgressBar {
            x: root.safeContentInset + 2
            anchors.bottom: fullCoverControls.top
            anchors.bottomMargin: Kirigami.Units.smallSpacing
            width: Math.max(0,
                fullCoverRoot.width - (root.safeContentInset + 2) * 2)
            active: root.hasProgress
            value: root.playbackProgress
            lightAppearance: false
        }

        Item {
            x: root.safeContentInset
            anchors.bottom: fullCoverControls.top
            anchors.bottomMargin: Kirigami.Units.gridUnit
            width: Math.max(0,
                fullCoverRoot.width - root.safeContentInset * 2)
            height: 42

            PlasmaComponents.Label {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 23
                text: root.title
                color: root.overlayTextColor
                font.weight: Font.Bold
                font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            PlasmaComponents.Label {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 18
                text: root.subtitle
                color: root.overlaySecondaryTextColor
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }

    component CompactProfile: Item {
        id: compactRoot

        function focusFirstControl() {
            return compactControls.focusFirstControl()
                || compactVolume.focusControl()
        }

        Item {
            x: Kirigami.Units.smallSpacing
            y: 42
            width: 44
            height: 48

            Rectangle {
                id: compactCover
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 44
                radius: 8
                color: Kirigami.Theme.backgroundColor
                clip: true

                Image {
                    anchors.fill: parent
                    source: root.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 30
                    height: width
                    source: root.fallbackIcon
                    visible: root.artUrl.length === 0
                }
            }

            PlaybackProgressBar {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: compactCover.bottom
                anchors.topMargin: 2
                active: root.hasProgress
                value: root.playbackProgress
            }
        }

        PlasmaComponents.Label {
            x: 60
            y: 40
            width: Math.max(0, compactRoot.width - 72)
            height: 18
            text: root.title
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        MediaTransportControls {
            id: compactControls
            x: 60
            y: 60
            width: Math.max(0, compactRoot.width - 72)
            height: 32
            controller: root.controller
        }

        MediaVolumeControl {
            id: compactVolume
            x: 60
            y: 94
            width: Math.max(0, compactRoot.width - 72)
            height: 28
            controller: root.controller
        }
    }

    Loader {
        id: profileLoader
        anchors.fill: parent
        active: root.available
        sourceComponent: root.profileComponentOverride
            ? root.profileComponentOverride
            : (root.compactProfile
                ? compactProfileComponent
                : (root.fullCoverProfile
                    ? fullCoverProfileComponent
                    : containedProfileComponent))
    }

    Component {
        id: containedProfileComponent
        ContainedProfile {}
    }

    Component {
        id: fullCoverProfileComponent
        FullCoverProfile {}
    }

    Component {
        id: compactProfileComponent
        CompactProfile {}
    }

    Loader {
        id: headerControlsLoader
        anchors.fill: parent
        active: root.available && root.headerControlsEnabled
        sourceComponent: Component {
            Item {
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: root.headerControlInset
                    z: 10
                    width: 28
                    height: 28
                    radius: width / 2
                    color: Qt.rgba(root.overlayBackgroundColor.r,
                        root.overlayBackgroundColor.g,
                        root.overlayBackgroundColor.b, 0.72)
                    border.width: 1
                    border.color: Qt.rgba(root.overlayTextColor.r,
                        root.overlayTextColor.g, root.overlayTextColor.b, 0.16)
                    Accessible.role: Accessible.Graphic
                    Accessible.name: i18nc("@info:accessible", "Media application")

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        source: root.fallbackIcon
                        color: root.overlayTextColor
                        isMask: String(root.fallbackIcon).indexOf("-symbolic") >= 0
                    }
                }

                PlasmaComponents.ToolButton {
                    id: closeButton
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: root.headerControlInset
                    z: 10
                    width: 28
                    height: 28
                    text: i18nc("@action:button", "Close window")
                    display: PlasmaComponents.AbstractButton.IconOnly
                    icon.name: "window-close"
                    icon.color: root.overlayTextColor
                    enabled: root.canCloseWindow
                    Accessible.name: text
                    Accessible.role: Accessible.Button
                    onClicked: root.closeAssociatedWindow()

                    background: Rectangle {
                        radius: width / 2
                        color: closeButton.pressed
                            ? Qt.rgba(Kirigami.Theme.negativeTextColor.r,
                                Kirigami.Theme.negativeTextColor.g,
                                Kirigami.Theme.negativeTextColor.b, 0.26)
                            : (closeButton.hovered || closeButton.activeFocus
                                ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                                    Kirigami.Theme.highlightColor.g,
                                    Kirigami.Theme.highlightColor.b, 0.32)
                                : Qt.rgba(root.overlayBackgroundColor.r,
                                    root.overlayBackgroundColor.g,
                                    root.overlayBackgroundColor.b, 0.72))
                        border.width: closeButton.activeFocus ? 1 : 0
                        border.color: Kirigami.Theme.highlightColor
                    }
                }
            }
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
        running: root.hasProgress && root.controller.playing
        onTriggered: root.displayedPositionUs = Math.min(
            root.controller.lengthUs, root.displayedPositionUs + 1000000)
    }

    onControllerChanged: syncDisplayedPosition()
    onHasProgressChanged: syncDisplayedPosition()
    Component.onCompleted: syncDisplayedPosition()

    Keys.onEscapePressed: function(event) {
        root.closeRequested()
        event.accepted = true
    }
}
// qmllint enable unqualified
