import QtQuick
import QtQuick.Effects as Effects
import QtQuick.Layouts
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
    property bool compact: false
    property bool squarePresentation: false
    property int transitionDuration: Kirigami.Units.longDuration
    property real compactTransitionProgress: compact ? 1 : 0
    readonly property bool available: !!controller && controller.available
    readonly property string artUrl: controller && controller.artUrl
        ? String(controller.artUrl)
        : ""
    readonly property bool artworkReady: artUrl.length > 0
        && squareCoverSource.status === Image.Ready
    readonly property bool squareMode: squarePresentation
        && artworkReady
        && !compact
    readonly property bool ambientMode: !squareMode && !compact
        && ambientSource.status === Image.Ready
        && artUrl.length > 0
    readonly property bool volumeAvailable: !!controller && controller.volumeAvailable
    readonly property bool hasProgress: !!controller && controller.lengthUs > 0
    property real displayedPositionUs: 0
    readonly property real playbackProgress: hasProgress
        ? Math.max(0, Math.min(1, displayedPositionUs / controller.lengthUs))
        : 0
    readonly property real topControlReservedHeight: available
        ? 28 + Kirigami.Units.smallSpacing
        : 0
    readonly property real progressReservedHeight: hasProgress
        ? Kirigami.Units.smallSpacing
        : 0
    readonly property real compactPreferredHeight: (volumeAvailable ? 88 : 56)
        + topControlReservedHeight
        + progressReservedHeight
    readonly property real preferredExpandedHeight: squareMode
        ? (volumeAvailable ? 420 : 382)
            + topControlReservedHeight
            + progressReservedHeight
        : (volumeAvailable
            ? (artUrl.length > 0 ? 152 : 120)
            : (artUrl.length > 0 ? 120 : 88))
            + topControlReservedHeight
            + progressReservedHeight
    readonly property string title: controller && controller.track
        ? controller.track
        : controller && controller.identity
            ? controller.identity
            : i18n("Media playback")
    readonly property string subtitle: controller && controller.artist
        ? controller.artist
        : controller && controller.identity && controller.identity !== title
            ? controller.identity
            : i18n("MPRIS controls")
    readonly property real cornerRadius: 12
    readonly property bool compactTransitionVisible: compact
        || compactTransitionProgress > 0.001
    readonly property real squareContentOpacity: squareMode
            || compactTransitionVisible
        ? Math.max(0, Math.min(1, 1 - (2 * compactTransitionProgress)))
        : 0
    readonly property real compactContentOpacity: compactTransitionVisible
            || squareMode
        ? Math.max(0, Math.min(1, (2 * compactTransitionProgress) - 1))
        : (ambientMode ? 0 : 1)
    readonly property int closeTaskRow: preferredCloseTaskRow()
    readonly property bool canCloseWindow: !!taskControllerRef && closeTaskRow >= 0
    readonly property string appIconSource: fallbackIcon.length > 0
        ? fallbackIcon
        : "emblem-music-symbolic"
    readonly property bool appBadgeVisible: available

    implicitWidth: 280
    implicitHeight: compact ? compactPreferredHeight : preferredExpandedHeight
    clip: true
    visible: available
    Accessible.role: Accessible.Grouping
    Accessible.name: i18nc("@info:accessible", "Media controls for %1", title)

    signal closeRequested()

    Behavior on compactTransitionProgress {
        NumberAnimation {
            duration: root.transitionDuration
            easing.type: Easing.OutCubic
        }
    }

    Keys.onEscapePressed: function(event) {
        root.closeRequested()
        event.accepted = true
    }

    function focusFirstControl() {
        if (squareMode) {
            if (squareControls.focusFirstControl()) {
                return true
            }
            return squareVolume.focusControl()
        }
        const transport = ambientMode ? ambientControls : standardControls
        if (transport.focusFirstControl()) {
            return true
        }
        return (ambientMode ? ambientVolume : standardVolume).focusControl()
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
            if (isNaN(row) || row < 0) {
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

    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: Kirigami.Theme.alternateBackgroundColor
        border.width: 1
        border.color: Kirigami.Theme.disabledTextColor
    }

    ColumnLayout {
        id: squareContent
        anchors.fill: parent
        anchors.margins: 12
        spacing: Kirigami.Units.smallSpacing
        opacity: root.squareContentOpacity
        scale: 1 - (0.025 * Math.min(1, root.compactTransitionProgress))
        transformOrigin: Item.Top
        visible: opacity > 0.001

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.topControlReservedHeight
            visible: root.topControlReservedHeight > 0
        }

        Item {
            id: squareCover
            Layout.fillWidth: true
            Layout.preferredHeight: width

            Rectangle {
                anchors.fill: parent
                radius: root.cornerRadius - 2
                color: Kirigami.Theme.backgroundColor
            }

            Image {
                id: squareCoverSource
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: false
                layer.enabled: true
            }

            Item {
                id: squareCoverMask
                anchors.fill: parent
                visible: false
                layer.enabled: true

                Rectangle {
                    anchors.fill: parent
                    radius: root.cornerRadius - 2
                    color: "black"
                }
            }

            Effects.MultiEffect {
                anchors.fill: parent
                source: squareCoverSource
                maskEnabled: true
                maskSource: squareCoverMask
                visible: squareCoverSource.status === Image.Ready
            }

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.huge
                height: width
                source: root.fallbackIcon.length > 0
                    ? root.fallbackIcon
                    : "emblem-music-symbolic"
                visible: squareCoverSource.status !== Image.Ready
            }

            Rectangle {
                anchors.fill: parent
                radius: root.cornerRadius - 2
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                    Kirigami.Theme.textColor.g,
                    Kirigami.Theme.textColor.b, 0.16)
            }
        }

        PlaybackProgressBar {
            Layout.fillWidth: true
            Layout.leftMargin: 2
            Layout.rightMargin: 2
            active: root.hasProgress
            value: root.playbackProgress
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PlasmaComponents.Label {
                Layout.fillWidth: true
                Layout.leftMargin: appBadgeVisible
                    ? appBadge.width + Kirigami.Units.smallSpacing
                    : 0
                Layout.rightMargin: closeButton.visible
                    ? closeButton.width + Kirigami.Units.smallSpacing
                    : 0
                text: root.title
                font.weight: Font.DemiBold
                font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                Layout.leftMargin: appBadgeVisible
                    ? appBadge.width + Kirigami.Units.smallSpacing
                    : 0
                Layout.rightMargin: closeButton.visible
                    ? closeButton.width + Kirigami.Units.smallSpacing
                    : 0
                text: root.subtitle
                color: Kirigami.Theme.disabledTextColor
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        MediaTransportControls {
            id: squareControls
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            controller: root.controller
            prominentPlayButton: true
        }

        MediaVolumeControl {
            id: squareVolume
            Layout.fillWidth: true
            controller: root.controller
        }
    }

    Image {
        id: ambientSource
        anchors.fill: parent
        source: root.artUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        visible: false
        layer.enabled: true
    }

    Item {
        id: ambientMask
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
        source: ambientSource
        maskEnabled: true
        maskSource: ambientMask
        opacity: root.ambientMode ? 1 : 0
        visible: !root.squareMode && opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        visible: root.ambientMode
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.rgba(0, 0, 0, 0.08)
            }
            GradientStop {
                position: 0.5
                color: Qt.rgba(0, 0, 0, 0.3)
            }
            GradientStop {
                position: 1
                color: Qt.rgba(0, 0, 0, 0.9)
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing
        anchors.topMargin: Kirigami.Units.smallSpacing + root.topControlReservedHeight
        anchors.bottomMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing
        opacity: root.compactContentOpacity
        scale: root.compactTransitionVisible || root.squareMode
            ? 0.97 + (0.03 * Math.min(1, root.compactTransitionProgress))
            : 1
        transformOrigin: Item.Top
        visible: opacity > 0.001

        Item {
            readonly property real coverSize: 64 - (24 * Math.min(1, root.compactTransitionProgress))

            Layout.preferredWidth: coverSize
            Layout.preferredHeight: coverSize + (root.hasProgress ? 6 : 0)

            Rectangle {
                id: compactCover
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.coverSize
                radius: 8
                color: Kirigami.Theme.backgroundColor
                clip: true

                Image {
                    id: coverImage
                    anchors.fill: parent
                    source: root.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 36
                    height: 36
                    source: root.fallbackIcon.length > 0 ? root.fallbackIcon : "emblem-music-symbolic"
                    visible: coverImage.status !== Image.Ready
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

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            PlasmaComponents.Label {
                Layout.fillWidth: true
                Layout.leftMargin: appBadgeVisible
                    ? appBadge.width + Kirigami.Units.smallSpacing
                    : 0
                Layout.rightMargin: closeButton.visible
                    ? closeButton.width + Kirigami.Units.smallSpacing
                    : 0
                text: root.title
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                Layout.leftMargin: appBadgeVisible
                    ? appBadge.width + Kirigami.Units.smallSpacing
                    : 0
                Layout.rightMargin: closeButton.visible
                    ? closeButton.width + Kirigami.Units.smallSpacing
                    : 0
                text: root.subtitle
                opacity: 0.72 * (1 - Math.min(1, root.compactTransitionProgress))
                elide: Text.ElideRight
                maximumLineCount: 1
                visible: opacity > 0.01
            }

            Item {
                Layout.fillHeight: true
            }

            MediaTransportControls {
                id: standardControls
                Layout.fillWidth: true
                controller: root.controller
            }

            MediaVolumeControl {
                id: standardVolume
                Layout.fillWidth: true
                controller: root.controller
            }
        }
    }

    Item {
        anchors.fill: parent
        opacity: root.ambientMode ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: ambientControls.top
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.bottomMargin: 4
            spacing: 1

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.title
                color: "white"
                font.weight: Font.Bold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.subtitle
                color: Qt.rgba(1, 1, 1, 0.78)
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        MediaTransportControls {
            id: ambientControls
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: ambientVolume.top
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.bottomMargin: 4
            controller: root.controller
            lightAppearance: true
        }

        PlaybackProgressBar {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: ambientControls.top
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.bottomMargin: 2
            active: root.hasProgress
            value: root.playbackProgress
            lightAppearance: true
        }

        MediaVolumeControl {
            id: ambientVolume
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.bottomMargin: 4
            controller: root.controller
            lightAppearance: true
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: "transparent"
        border.width: 1
        border.color: root.ambientMode
            ? Qt.rgba(1, 1, 1, 0.16)
            : Kirigami.Theme.disabledTextColor
    }

    Rectangle {
        id: appBadge
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: Kirigami.Units.smallSpacing
        z: 10
        width: 28
        height: 28
        radius: width / 2
        visible: root.appBadgeVisible
        color: root.ambientMode
            ? Qt.rgba(0, 0, 0, 0.28)
            : Qt.rgba(Kirigami.Theme.backgroundColor.r,
                Kirigami.Theme.backgroundColor.g,
                Kirigami.Theme.backgroundColor.b, 0.72)
        border.width: 1
        border.color: root.ambientMode
            ? Qt.rgba(1, 1, 1, 0.18)
            : Qt.rgba(Kirigami.Theme.textColor.r,
                Kirigami.Theme.textColor.g,
                Kirigami.Theme.textColor.b, 0.12)
        Accessible.role: Accessible.Graphic
        Accessible.name: i18nc("@info:accessible", "Media application")

        Kirigami.Icon {
            anchors.centerIn: parent
            width: 18
            height: 18
            source: root.appIconSource
            color: root.ambientMode ? "white" : Kirigami.Theme.textColor
            isMask: String(root.appIconSource).indexOf("-symbolic") >= 0
        }
    }

    PlasmaComponents.ToolButton {
        id: closeButton
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Kirigami.Units.smallSpacing
        z: 10
        width: 28
        height: 28
        text: i18nc("@action:button", "Close window")
        display: PlasmaComponents.AbstractButton.IconOnly
        icon.name: "window-close"
        icon.color: root.ambientMode ? "white" : Kirigami.Theme.textColor
        visible: root.available
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
                        Kirigami.Theme.highlightColor.b,
                        root.ambientMode ? 0.32 : 0.18)
                    : Qt.rgba(root.ambientMode ? 0 : Kirigami.Theme.backgroundColor.r,
                        root.ambientMode ? 0 : Kirigami.Theme.backgroundColor.g,
                        root.ambientMode ? 0 : Kirigami.Theme.backgroundColor.b,
                        root.ambientMode ? 0.28 : 0.72))
            border.width: closeButton.activeFocus ? 1 : 0
            border.color: root.ambientMode ? "white" : Kirigami.Theme.highlightColor
        }
    }
}
// qmllint enable unqualified
