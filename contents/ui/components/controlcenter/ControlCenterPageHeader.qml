// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: root

    required property string title
    required property string backActionName
    required property string toggleText
    required property bool toggleChecked
    required property bool toggleEnabled
    required property string primaryActionText
    required property string primaryActionIconName
    required property bool primaryActionEnabled
    required property string settingsActionText

    property string headerObjectName: ""
    property string navigationRowObjectName: ""
    property string actionsRowObjectName: ""
    property string backButtonObjectName: ""
    property string toggleObjectName: ""
    property string primaryActionObjectName: ""
    property string settingsActionObjectName: ""

    signal backRequested()
    signal toggleRequested(bool enabled)
    signal primaryActionRequested()
    signal settingsRequested()

    objectName: headerObjectName
    spacing: Kirigami.Units.smallSpacing

    function focusBackButton() {
        backButton.forceActiveFocus(Qt.PopupFocusReason)
    }

    RowLayout {
        objectName: root.navigationRowObjectName
        Layout.fillWidth: true
        spacing: Kirigami.Units.mediumSpacing

        PlasmaComponents.ToolButton {
            id: backButton

            objectName: root.backButtonObjectName
            icon.name: Application.layoutDirection === Qt.RightToLeft
                ? "go-next" : "go-previous"
            text: root.backActionName
            display: PlasmaComponents.AbstractButton.IconOnly
            Accessible.name: text
            onClicked: root.backRequested()
        }

        Controls.Label {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: root.title
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.25
            font.bold: true
            elide: Text.ElideRight
        }
    }

    RowLayout {
        objectName: root.actionsRowObjectName
        Layout.fillWidth: true
        spacing: Kirigami.Units.mediumSpacing

        Item {
            Layout.fillWidth: true
        }

        PlasmaComponents.Switch {
            objectName: root.toggleObjectName
            text: root.toggleText
            checked: root.toggleChecked
            enabled: root.toggleEnabled
            onToggled: root.toggleRequested(checked)
        }

        PlasmaComponents.ToolButton {
            objectName: root.primaryActionObjectName
            text: root.primaryActionText
            icon.name: root.primaryActionIconName
            display: PlasmaComponents.AbstractButton.IconOnly
            enabled: root.primaryActionEnabled
            Accessible.name: text
            onClicked: root.primaryActionRequested()
        }

        PlasmaComponents.ToolButton {
            objectName: root.settingsActionObjectName
            text: root.settingsActionText
            icon.name: "configure"
            display: PlasmaComponents.AbstractButton.IconOnly
            Accessible.name: text
            onClicked: root.settingsRequested()
        }
    }
}
