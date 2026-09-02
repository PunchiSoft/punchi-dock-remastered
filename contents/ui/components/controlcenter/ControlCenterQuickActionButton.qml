// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Controls.AbstractButton {
    id: root

    property string iconName: ""
    property string description: ""

    implicitWidth: Kirigami.Units.gridUnit * 3
    implicitHeight: Kirigami.Units.gridUnit * 3
    leftPadding: Kirigami.Units.smallSpacing
    rightPadding: Kirigami.Units.smallSpacing
    topPadding: Kirigami.Units.smallSpacing
    bottomPadding: Kirigami.Units.smallSpacing
    hoverEnabled: enabled
    activeFocusOnTab: enabled
    Accessible.name: text
    Accessible.description: description
    Accessible.checkable: root.checkable
    Accessible.checked: root.checked

    HoverHandler {
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
    }

    background: Rectangle {
        radius: width / 2
        color: root.checked || root.down
            ? Qt.alpha(Kirigami.Theme.highlightColor, 0.34)
            : root.hovered || root.activeFocus
                ? Qt.alpha(Kirigami.Theme.textColor, 0.14)
                : Qt.alpha(Kirigami.Theme.backgroundColor, 0.34)
        opacity: root.enabled ? 1.0 : 0.46
        border.width: root.activeFocus ? 2 : 1
        border.color: root.activeFocus
            ? Kirigami.Theme.highlightColor
            : Qt.alpha(Kirigami.Theme.textColor, 0.18)
        Accessible.ignored: true
    }

    contentItem: Item {
        Kirigami.Icon {
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.medium
            height: width
            source: root.iconName
            opacity: root.enabled ? 1.0 : 0.48
            Accessible.ignored: true
        }
    }

    Controls.ToolTip.visible: root.hovered && root.enabled
    Controls.ToolTip.text: root.description.length > 0
        ? root.description : root.text
}
