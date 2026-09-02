// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

FocusScope {
    id: root

    property string title: ""
    property string iconName: ""
    property string unavailableText: i18nc("@info", "Unavailable") // qmllint disable unqualified
    property int value: 0
    property bool controlAvailable: false
    property bool iconActionEnabled: false
    property string iconActionName: title
    property string settingsActionName: i18nc("@action:button", "Open settings") // qmllint disable unqualified

    signal valueModified(real value)
    signal iconActionTriggered()
    signal settingsRequested()

    objectName: "controlCenterControlCard"
    implicitWidth: Kirigami.Units.gridUnit * 22
    implicitHeight: Kirigami.Units.gridUnit * 6

    Rectangle {
        anchors.fill: parent
        radius: Kirigami.Units.cornerRadius * 2.5
        color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.78)
        border.width: 1
        border.color: Qt.alpha(Kirigami.Theme.textColor, 0.16)
        Accessible.ignored: true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.mediumSpacing
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.ToolButton {
                id: iconButton
                icon.name: root.iconName
                text: root.iconActionName
                display: PlasmaComponents.AbstractButton.IconOnly
                enabled: root.iconActionEnabled && root.controlAvailable
                Accessible.name: text
                onClicked: root.iconActionTriggered()
            }

            Controls.Label {
                Layout.fillWidth: true
                text: root.title
                font.bold: true
                elide: Text.ElideRight
            }

            Controls.Label {
                text: root.controlAvailable
                    ? i18nc("@info:label Percentage value", "%1%", root.value) // qmllint disable unqualified
                    : root.unavailableText
                opacity: root.controlAvailable ? 0.82 : 0.62
                font: Kirigami.Theme.smallFont
            }

            PlasmaComponents.ToolButton {
                id: settingsButton
                icon.name: "configure"
                text: root.settingsActionName
                display: PlasmaComponents.AbstractButton.IconOnly
                Accessible.name: text
                onClicked: root.settingsRequested()
            }
        }

        PlasmaComponents.Slider {
            id: slider
            objectName: "controlCenterControlSlider"
            Layout.fillWidth: true
            from: 0
            to: 100
            stepSize: 1
            value: root.value
            enabled: root.controlAvailable
            Accessible.name: root.title
            Accessible.description: root.controlAvailable
                ? i18nc("@info:accessibility Percentage value", "%1 percent", root.value) // qmllint disable unqualified
                : root.unavailableText
            onMoved: root.valueModified(value)
        }
    }
}
