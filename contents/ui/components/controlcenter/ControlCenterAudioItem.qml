// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

FocusScope {
    id: root

    required property var adapter
    required property var audioObject
    required property int itemType
    required property string label
    required property string iconName
    property string description: ""
    property var routingModel: null
    property bool defaultSelectorVisible: false
    property bool defaultDevice: audioObject
        ? Boolean(audioObject["default"]) : false

    readonly property bool muted: audioObject
        ? Boolean(audioObject.muted) : false
    readonly property int volumePercentage:
        adapter ? adapter.percentageFor(audioObject) : 0

    objectName: "controlCenterAudioItem"
    implicitHeight: contentLayout.implicitHeight

    ColumnLayout {
        id: contentLayout

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Controls.RadioButton {
                id: defaultButton

                visible: root.defaultSelectorVisible
                checked: root.defaultDevice
                text: ""
                // The translation helper is supplied by the plasmoid context.
                // qmllint disable unqualified
                Accessible.name: i18nc(
                    "@action:button %1 is an audio device name",
                    "Use %1 as the default device", root.label)
                // qmllint enable unqualified
                onClicked: root.adapter.setDefaultDevice(root.audioObject)

                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: Accessible.name
            }

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Layout.preferredWidth
                source: root.iconName
                Accessible.ignored: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 0

                Controls.Label {
                    Layout.fillWidth: true
                    text: root.label
                    elide: Text.ElideRight
                    font.bold: root.defaultDevice
                }

                Controls.Label {
                    Layout.fillWidth: true
                    visible: root.description.length > 0
                    text: root.description
                    elide: Text.ElideRight
                    opacity: 0.68
                    font: Kirigami.Theme.smallFont
                }
            }

            Controls.Label {
                // qmllint disable unqualified
                text: i18nc("@info:label Percentage value", "%1%",
                    root.volumePercentage)
                // qmllint enable unqualified
                opacity: 0.82
                font: Kirigami.Theme.smallFont
            }

            PlasmaComponents.ToolButton {
                id: muteButton

                objectName: "controlCenterAudioMuteButton"
                icon.name: root.muted
                    ? "audio-volume-muted" : root.iconName
                text: root.muted
                    ? i18nc("@action:button", "Unmute %1", root.label) // qmllint disable unqualified
                    : i18nc("@action:button", "Mute %1", root.label) // qmllint disable unqualified
                display: PlasmaComponents.AbstractButton.IconOnly
                Accessible.name: text
                onClicked: root.adapter.toggleObjectMuted(root.audioObject)

                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: text
            }

            PlasmaComponents.ToolButton {
                id: optionsButton

                objectName: "controlCenterAudioOptionsButton"
                icon.name: "overflow-menu"
                // qmllint disable unqualified
                text: i18nc("@action:button", "More options for %1",
                    root.label)
                // qmllint enable unqualified
                display: PlasmaComponents.AbstractButton.IconOnly
                Accessible.name: text
                onClicked: root.adapter.openItemOptions(
                    root.audioObject,
                    root.itemType,
                    root.routingModel,
                    optionsButton)

                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: text
            }
        }

        PlasmaComponents.Slider {
            id: volumeSlider

            objectName: "controlCenterAudioSlider"
            Layout.fillWidth: true
            Layout.leftMargin: root.defaultSelectorVisible
                ? defaultButton.implicitWidth
                    + Kirigami.Units.iconSizes.smallMedium
                    + Kirigami.Units.smallSpacing * 2
                : Kirigami.Units.iconSizes.smallMedium
                    + Kirigami.Units.smallSpacing
            from: 0
            to: root.adapter ? root.adapter.maximumPercentage : 100
            stepSize: 1
            value: root.volumePercentage
            // qmllint disable unqualified
            Accessible.name: i18nc("@label", "Volume for %1",
                root.label)
            Accessible.description: i18nc(
                "@info:accessibility %1 is an audio item, %2 is a percentage",
                "%1, %2 percent", root.label,
                root.volumePercentage)
            // qmllint enable unqualified
            onMoved: root.adapter.setObjectValue(root.audioObject, value)
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }
    }
}
