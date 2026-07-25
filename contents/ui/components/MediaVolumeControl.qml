import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
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
    readonly property int muteButtonExtent: 28
    readonly property int muteIconExtent: 20

    spacing: Kirigami.Units.smallSpacing
    visible: available
    implicitHeight: visible
        ? Math.max(volumeMuteButton.implicitHeight, volumeSlider.implicitHeight)
        : 0

    function focusControl() {
        if (available) {
            volumeSlider.forceActiveFocus(Qt.TabFocusReason)
            return true
        }
        return false
    }

    function suppressSliderTickMarksWhenSupported() {
        // Kirigami before 6.24 does not expose this attached member in its
        // QML type metadata. Runtime detection keeps the fallback safe.
        // qmllint disable missing-property
        const styleHints = volumeSlider.Kirigami.StyleHints
        // qmllint enable missing-property
        if (!styleHints
                || typeof styleHints["tickMarkStepSize"] === "undefined") {
            return
        }
        styleHints["tickMarkStepSize"] = -1
    }

    PlasmaComponents.ToolButton {
        id: volumeMuteButton
        Layout.preferredWidth: root.muteButtonExtent
        Layout.preferredHeight: root.muteButtonExtent
        text: root.controller && root.controller.volume <= 0.001
            ? i18nc("@action:button", "Restore media volume")
            : i18nc("@action:button", "Mute media volume")
        display: PlasmaComponents.AbstractButton.IconOnly
        icon.width: root.muteIconExtent
        icon.height: root.muteIconExtent
        icon.name: root.controller && root.controller.volume <= 0.001
            ? "audio-volume-muted"
            : (root.controller && root.controller.volume < 0.5
                ? "audio-volume-low"
                : "audio-volume-high")
        icon.color: root.controlColor
        enabled: root.available
        Accessible.name: text
        Accessible.role: Accessible.Button
        Controls.ToolTip.visible: hovered || activeFocus
        Controls.ToolTip.text: text
        Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
        onClicked: root.controller.toggleMute()
    }

    Controls.Slider {
        id: volumeSlider
        Layout.fillWidth: true
        from: 0
        to: 100
        stepSize: 1
        enabled: root.available
        Accessible.name: i18nc("@label:slider", "Media volume")
        Accessible.description: i18nc("@info:accessible", "Adjust the media player volume")
        Component.onCompleted: root.suppressSliderTickMarksWhenSupported()
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
