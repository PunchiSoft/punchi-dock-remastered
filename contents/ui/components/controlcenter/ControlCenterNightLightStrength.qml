// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Rectangle {
    id: root

    property int strength: 0
    property bool controlAvailable: false
    property string settingsActionName: ""

    signal previewRequested(int strength)
    signal previewStopped()
    signal strengthModified(int strength)
    signal settingsRequested()

    implicitHeight: Kirigami.Units.gridUnit * 3
    radius: height / 2
    color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.28)
    border.width: 1
    border.color: Qt.alpha(Kirigami.Theme.textColor, 0.12)
    Accessible.role: Accessible.Pane
    Accessible.name: i18nc("@label", "Night Light intensity") // qmllint disable unqualified

    Timer {
        id: previewTimer

        interval: Kirigami.Units.humanMoment
        onTriggered: root.previewStopped()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.largeSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.mediumSpacing

        Kirigami.Icon {
            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
            Layout.preferredHeight: Layout.preferredWidth
            source: "redshift-status-on"
            opacity: root.controlAvailable ? 1.0 : 0.46
            Accessible.ignored: true
        }

        Controls.Label {
            text: i18nc("@label", "Intensity") // qmllint disable unqualified
            opacity: root.controlAvailable ? 1.0 : 0.58
        }

        PlasmaComponents.Slider {
            id: strengthSlider

            objectName: "controlCenterNightLightStrengthSlider"
            Layout.fillWidth: true
            from: 0
            to: 100
            stepSize: 2
            live: true
            value: root.strength
            enabled: root.controlAvailable
            Accessible.name: i18nc("@label", "Night Light intensity") // qmllint disable unqualified
            Accessible.description: i18nc("@info", "Adjust the warmth of the screen filter") // qmllint disable unqualified

            onMoved: {
                const roundedStrength = Math.round(value)
                root.previewRequested(roundedStrength)
                if (!pressed) {
                    root.strengthModified(roundedStrength)
                    previewTimer.restart()
                }
            }
            onPressedChanged: {
                if (!pressed) {
                    root.strengthModified(Math.round(value))
                    root.previewStopped()
                }
            }
        }

        Controls.Label {
            objectName: "controlCenterNightLightStrengthValue"
            text: i18nc("@label Night Light intensity percentage", "%1%", Math.round(strengthSlider.value)) // qmllint disable unqualified
            font: Kirigami.Theme.smallFont
            horizontalAlignment: Text.AlignRight
            Layout.minimumWidth: Kirigami.Units.gridUnit * 2.4
        }

        PlasmaComponents.Button {
            objectName: "controlCenterNightLightSettingsButton"
            text: root.settingsActionName
            icon.name: "configure"
            display: PlasmaComponents.AbstractButton.IconOnly
            Accessible.name: text
            onClicked: root.settingsRequested()

            Controls.ToolTip.visible: hovered
            Controls.ToolTip.text: text

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
}
