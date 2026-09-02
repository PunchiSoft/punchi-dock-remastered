// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: root

    required property var summary
    required property var body
    required property var applicationName
    required property var applicationIconName
    required property bool closable

    signal closeRequested()

    readonly property string effectiveApplicationName:
        String(applicationName || "").trim()
    readonly property string effectiveSummary: {
        const text = String(summary || "").trim()
        return text.length > 0 ? text : effectiveApplicationName
    }

    width: ListView.view ? ListView.view.width : 0
    implicitHeight: Math.max(Kirigami.Units.gridUnit * 3.2,
        contentLayout.implicitHeight + Kirigami.Units.largeSpacing)
    Accessible.role: Accessible.StaticText
    Accessible.name: effectiveApplicationName.length > 0
        ? effectiveApplicationName + ": " + effectiveSummary
        : effectiveSummary
    Accessible.description: String(body || "")

    RowLayout {
        id: contentLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Kirigami.Units.largeSpacing
        anchors.rightMargin: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.mediumSpacing

        Kirigami.Icon {
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            Layout.alignment: Qt.AlignTop
            source: String(root.applicationIconName || "notification-inactive")
            Accessible.ignored: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Controls.Label {
                Layout.fillWidth: true
                visible: root.effectiveApplicationName.length > 0
                text: root.effectiveApplicationName
                opacity: 0.68
                font: Kirigami.Theme.smallFont
                elide: Text.ElideRight
                Accessible.ignored: true
            }

            Controls.Label {
                Layout.fillWidth: true
                text: root.effectiveSummary
                font.bold: true
                maximumLineCount: 1
                elide: Text.ElideRight
                Accessible.ignored: true
            }

            Controls.Label {
                Layout.fillWidth: true
                visible: String(root.body || "").trim().length > 0
                text: String(root.body || "").trim()
                opacity: 0.76
                maximumLineCount: 2
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                Accessible.ignored: true
            }
        }

        PlasmaComponents.ToolButton {
            id: closeButton

            objectName: "notificationCloseButton"
            Layout.alignment: Qt.AlignTop
            visible: root.closable
            icon.name: "window-close"
            text: i18nc("@action:button", "Close") // qmllint disable unqualified
            display: PlasmaComponents.AbstractButton.IconOnly
            Accessible.name: text
            onClicked: root.closeRequested()

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Kirigami.Units.largeSpacing
        anchors.rightMargin: Kirigami.Units.largeSpacing
        height: 1
        color: Kirigami.Theme.textColor
        opacity: 0.12
        Accessible.ignored: true
    }
}
