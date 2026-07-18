import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Plasma provides the translation functions in the applet context.
// qmllint disable unqualified
RowLayout {
    id: root

    property var controller: null
    property bool lightAppearance: false
    readonly property bool available: !!controller
        && controller.available
        && controller.volumeAvailable
    readonly property color controlColor: lightAppearance
        ? Qt.rgba(1, 1, 1, 0.96)
        : Kirigami.Theme.textColor

    spacing: Kirigami.Units.smallSpacing
    visible: available
    implicitHeight: visible ? Math.max(volumeIcon.implicitHeight, volumeSlider.implicitHeight) : 0

    function focusControl() {
        if (available) {
            volumeSlider.forceActiveFocus(Qt.TabFocusReason)
            return true
        }
        return false
    }

    Kirigami.Icon {
        id: volumeIcon
        Layout.preferredWidth: Kirigami.Units.iconSizes.small
        Layout.preferredHeight: Kirigami.Units.iconSizes.small
        source: root.controller && root.controller.volume <= 0.001
            ? "audio-volume-muted"
            : (root.controller && root.controller.volume < 0.5
                ? "audio-volume-low"
                : "audio-volume-high")
        color: root.controlColor
        Accessible.ignored: true
    }

    Controls.Slider {
        id: volumeSlider
        Layout.fillWidth: true
        from: 0
        to: 100
        stepSize: 1
        Kirigami.StyleHints.tickMarkStepSize: -1
        enabled: root.available
        Accessible.name: i18nc("@label:slider", "Media volume")
        Accessible.description: i18nc("@info:accessible", "Adjust the media player volume")
        onMoved: {
            if (root.available) {
                root.controller.setVolume(value / 100.0)
            }
        }
    }

    Binding {
        target: volumeSlider
        property: "value"
        value: root.controller ? root.controller.volume * 100.0 : 0.0
        when: !volumeSlider.pressed
    }

    Controls.Label {
        Layout.preferredWidth: 38
        horizontalAlignment: Text.AlignRight
        text: i18nc("@label", "%1%", Math.round(volumeSlider.value))
        color: root.controlColor
    }
}
// qmllint enable unqualified
