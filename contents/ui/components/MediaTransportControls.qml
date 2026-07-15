import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// Plasma provides the translation functions in the applet context.
// qmllint disable unqualified
RowLayout {
    id: root

    property var controller: null
    property bool lightAppearance: false
    readonly property bool available: !!controller && controller.available
    readonly property color controlColor: lightAppearance
        ? Qt.rgba(1, 1, 1, 0.96)
        : Kirigami.Theme.textColor

    spacing: Kirigami.Units.smallSpacing

    Item {
        Layout.fillWidth: true
    }

    PlasmaComponents.ToolButton {
        text: i18nc("@action:button", "Previous track")
        display: PlasmaComponents.AbstractButton.IconOnly
        icon.name: Application.layoutDirection === Qt.RightToLeft
            ? "media-skip-forward"
            : "media-skip-backward"
        icon.color: root.controlColor
        enabled: root.available && root.controller.canGoPrevious
        onClicked: root.controller.previous()
    }

    PlasmaComponents.ToolButton {
        text: root.controller && root.controller.playing
            ? i18nc("@action:button", "Pause")
            : i18nc("@action:button", "Play")
        display: PlasmaComponents.AbstractButton.IconOnly
        icon.name: root.controller && root.controller.playing
            ? "media-playback-pause"
            : "media-playback-start"
        icon.color: root.controlColor
        enabled: root.available && ((root.controller.playing && root.controller.canPause)
            || (!root.controller.playing && root.controller.canPlay))
        onClicked: root.controller.togglePlaying()
    }

    PlasmaComponents.ToolButton {
        text: i18nc("@action:button", "Next track")
        display: PlasmaComponents.AbstractButton.IconOnly
        icon.name: Application.layoutDirection === Qt.RightToLeft
            ? "media-skip-backward"
            : "media-skip-forward"
        icon.color: root.controlColor
        enabled: root.available && root.controller.canGoNext
        onClicked: root.controller.next()
    }

    Item {
        Layout.fillWidth: true
    }
}
// qmllint enable unqualified
