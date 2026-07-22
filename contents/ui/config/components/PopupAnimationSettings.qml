import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// qmllint disable unqualified
Kirigami.FormLayout {
    id: root

    property string sectionTitle: ""
    property string animationStyle: "scale"
    property alias animationSpeedPercent: speedSlider.value
    property alias animationIntensityPercent: intensitySlider.value
    property int contentWidthHint: 420
    property int selectorWidthHint: 240
    property bool interactiveCursorEnabled: false

    readonly property var animationOptions: [
        { "text": i18n("Subtle scale"), "value": "scale" },
        { "text": i18n("Bounce"), "value": "bounce" },
        { "text": i18n("Fade"), "value": "fade" },
        { "text": i18n("Slide from the dock"), "value": "slide" },
        { "text": i18n("None"), "value": "none" }
    ]

    function syncAnimationSelector() {
        const resolvedIndex = Math.max(0,
            animationCombo.indexOfValue(root.animationStyle))
        if (animationCombo.currentIndex !== resolvedIndex) {
            animationCombo.currentIndex = resolvedIndex
        }
    }

    onAnimationStyleChanged: syncAnimationSelector()
    Component.onCompleted: syncAnimationSelector()

    component SectionTitle: Kirigami.Heading {
        Layout.fillWidth: true
        level: 3
        leftPadding: 0
    }

    SectionTitle {
        Kirigami.FormData.isSection: true
        text: root.sectionTitle
    }

    Controls.ComboBox {
        id: animationCombo
        Kirigami.FormData.label: i18n("Opening effect:")
        Layout.preferredWidth: root.selectorWidthHint
        Layout.maximumWidth: root.selectorWidthHint
        textRole: "text"
        valueRole: "value"
        model: root.animationOptions
        onActivated: {
            if (root.animationStyle !== currentValue) {
                root.animationStyle = currentValue
            }
        }

        ConfigCursorBehavior {
            cursorEnabled: root.interactiveCursorEnabled
        }
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Speed:")
        Layout.maximumWidth: root.contentWidthHint
        enabled: root.animationStyle !== "none"

        Controls.Slider {
            id: speedSlider
            from: 10
            to: 200
            value: 100
            stepSize: 5
            snapMode: Controls.Slider.SnapAlways
            Layout.fillWidth: true
            Layout.preferredWidth: root.contentWidthHint - 64
            Accessible.name: i18n("Opening animation speed")

            ConfigCursorBehavior {
                cursorEnabled: root.interactiveCursorEnabled
                role: "slider"
            }
        }

        Controls.Label {
            text: i18n("%1%", Math.round(speedSlider.value))
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 56
        }
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Intensity:")
        Layout.maximumWidth: root.contentWidthHint
        enabled: root.animationStyle !== "none"

        Controls.Slider {
            id: intensitySlider
            from: 10
            to: 200
            value: 100
            stepSize: 5
            snapMode: Controls.Slider.SnapAlways
            Layout.fillWidth: true
            Layout.preferredWidth: root.contentWidthHint - 64
            Accessible.name: i18n("Opening animation intensity")

            ConfigCursorBehavior {
                cursorEnabled: root.interactiveCursorEnabled
                role: "slider"
            }
        }

        Controls.Label {
            text: i18n("%1%", Math.round(intensitySlider.value))
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 56
        }
    }
}
// qmllint enable unqualified
