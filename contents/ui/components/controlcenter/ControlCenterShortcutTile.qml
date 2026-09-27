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
    property var navigationHandler: null

    signal keyboardActivationStarted()

    // Hover, press and checked feedback animate the surface. Programmatic
    // focus on popup opening must not look like a hovered or selected tile;
    // keyboard focus gets a separate, immediate outline.
    // The 1 ms clamp avoids the known case where an animator with duration 0
    // never fires and the value never reaches its target.
    readonly property bool feedbackActive: root.checked || root.down
        || root.hovered
    readonly property int feedbackEnterDuration:
        Math.max(1, Kirigami.Units.shortDuration)
    readonly property int feedbackExitDuration:
        Math.max(1, Math.round(Kirigami.Units.shortDuration * 0.8))

    implicitWidth: Kirigami.Units.gridUnit * 12
    implicitHeight: Kirigami.Units.gridUnit * 5
    leftPadding: Kirigami.Units.largeSpacing
    rightPadding: Kirigami.Units.largeSpacing
    topPadding: Kirigami.Units.mediumSpacing
    bottomPadding: Kirigami.Units.mediumSpacing
    hoverEnabled: true
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.description: description
    Accessible.focusable: root.enabled
    Accessible.focused: root.activeFocus
    Accessible.checkable: root.expandable || root.checkable
    Accessible.checked: root.expandable ? root.expanded : root.checked

    // AbstractButton handles Space on release. Return and keypad Enter reach
    // the same action without click(), which is only available from Qt 6.8.
    Keys.onPressed: function(event) {
        if (!root.enabled) {
            event.accepted = false
            return
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (!event.isAutoRepeat) {
                root.keyboardActivationStarted()
                root.clicked()
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Space) {
            if (!event.isAutoRepeat) {
                root.keyboardActivationStarted()
            }
            event.accepted = false
        } else if (typeof root.navigationHandler === "function") {
            root.navigationHandler(root, event)
        } else {
            event.accepted = false
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    background: Rectangle {
        radius: Kirigami.Units.cornerRadius * 2
        color: root.checked || root.down
            ? Kirigami.Theme.highlightColor
            : Kirigami.Theme.backgroundColor
        opacity: root.checked || root.down
            ? 0.42 : (root.hovered ? 0.34 : 0.24)
        // The focus ring stays immediate on purpose: focus must be visible in
        // the same frame it arrives, without waiting for a transition.
        border.width: root.visualFocus ? 2 : 1
        border.color: root.visualFocus
            ? Kirigami.Theme.highlightColor
            : Qt.rgba(Kirigami.Theme.textColor.r,
                Kirigami.Theme.textColor.g,
                Kirigami.Theme.textColor.b, 0.18)

        Behavior on color {
            ColorAnimation {
                duration: root.feedbackActive
                    ? root.feedbackEnterDuration : root.feedbackExitDuration
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.feedbackActive
                    ? root.feedbackEnterDuration : root.feedbackExitDuration
            }
        }

        Behavior on border.color {
            enabled: !root.visualFocus
            ColorAnimation {
                duration: root.feedbackActive
                    ? root.feedbackEnterDuration : root.feedbackExitDuration
            }
        }

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
