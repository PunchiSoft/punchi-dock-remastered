// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Controls.AbstractButton {
    id: root

    property string iconName: ""
    property string description: ""
    property string badgeText: ""
    property string trailingIconName: "go-next-symbolic"
    property bool expandable: false
    property bool expanded: false

    implicitWidth: Kirigami.Units.gridUnit * 12
    implicitHeight: Kirigami.Units.gridUnit * 5
    leftPadding: Kirigami.Units.largeSpacing
    rightPadding: Kirigami.Units.largeSpacing
    topPadding: Kirigami.Units.mediumSpacing
    bottomPadding: Kirigami.Units.mediumSpacing
    hoverEnabled: true
    activeFocusOnTab: true
    Accessible.name: text
    Accessible.description: description
    Accessible.checkable: root.expandable || root.checkable
    Accessible.checked: root.expandable ? root.expanded : root.checked

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    background: Rectangle {
        radius: Kirigami.Units.cornerRadius * 2
        color: root.checked || root.down || root.activeFocus
            ? Kirigami.Theme.highlightColor
            : Kirigami.Theme.backgroundColor
        opacity: root.checked || root.down || root.activeFocus
            ? 0.42 : (root.hovered ? 0.34 : 0.24)
        border.width: root.activeFocus ? 2 : 1
        border.color: root.activeFocus
            ? Kirigami.Theme.highlightColor
            : Qt.rgba(Kirigami.Theme.textColor.r,
                Kirigami.Theme.textColor.g,
                Kirigami.Theme.textColor.b, 0.18)
        Accessible.ignored: true
    }

    contentItem: RowLayout {
        spacing: Kirigami.Units.mediumSpacing

        Item {
            Layout.preferredWidth: Kirigami.Units.iconSizes.large
            Layout.preferredHeight: Kirigami.Units.iconSizes.large
            Layout.alignment: Qt.AlignVCenter

            Kirigami.Icon {
                anchors.fill: parent
                source: root.iconName
                Accessible.ignored: true
            }

            Rectangle {
                visible: root.badgeText.length > 0
                anchors.right: parent.right
                anchors.top: parent.top
                width: Math.max(Kirigami.Units.gridUnit,
                    badgeLabel.implicitWidth + Kirigami.Units.smallSpacing)
                height: Kirigami.Units.gridUnit
                radius: height / 2
                color: Kirigami.Theme.highlightColor
                Accessible.ignored: true

                Controls.Label {
                    id: badgeLabel
                    anchors.centerIn: parent
                    text: root.badgeText
                    color: Kirigami.Theme.highlightedTextColor
                    font.bold: true
                    font.pixelSize: Math.max(9,
                        Kirigami.Theme.smallFont.pixelSize - 1)
                    Accessible.ignored: true
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Kirigami.Units.smallSpacing / 2

            Controls.Label {
                Layout.fillWidth: true
                text: root.text
                font.bold: true
                elide: Text.ElideRight
                maximumLineCount: 1
                Accessible.ignored: true
            }

            Controls.Label {
                Layout.fillWidth: true
                text: root.description
                opacity: 0.72
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
                font: Kirigami.Theme.smallFont
                Accessible.ignored: true
            }
        }

        Kirigami.Icon {
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            Layout.alignment: Qt.AlignVCenter
            source: root.trailingIconName
            opacity: 0.70
            Accessible.ignored: true
        }
    }
}
