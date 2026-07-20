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
    readonly property real compactPreferredHeight: volumeAvailable ? 88 : 56
    readonly property real preferredExpandedHeight: squareMode
        ? (volumeAvailable ? 420 : 382)
        : (volumeAvailable
            ? (artUrl.length > 0 ? 152 : 120)
            : (artUrl.length > 0 ? 120 : 88))
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

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.title
                font.weight: Font.DemiBold
                font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
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
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing
        opacity: root.compactContentOpacity
        scale: root.compactTransitionVisible || root.squareMode
            ? 0.97 + (0.03 * Math.min(1, root.compactTransitionProgress))
            : 1
        transformOrigin: Item.Top
        visible: opacity > 0.001

        Item {
            Layout.preferredWidth: 64 - (24 * Math.min(1, root.compactTransitionProgress))
            Layout.preferredHeight: Layout.preferredWidth

            Rectangle {
                anchors.fill: parent
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
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.title
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
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
}
// qmllint enable unqualified
