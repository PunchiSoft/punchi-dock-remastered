// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.kirigami as Kirigami
import "ControlCenterLayoutMetrics.js" as LayoutMetrics

Item {
    id: root

    property bool floatingMode: false
    property real referenceWidth: parent ? parent.width : 0
    property real referenceHeight: parent ? parent.height : 0
    readonly property real edgeMargin:
        LayoutMetrics.edgeMargin(Kirigami.Units.gridUnit)

    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: root.floatingMode ? 0 : root.edgeMargin
    anchors.rightMargin: root.floatingMode ? 0 : root.edgeMargin
    width: root.floatingMode && parent
        ? parent.width
        : LayoutMetrics.availableWidth(
            root.referenceWidth, Kirigami.Units.gridUnit)
    height: root.floatingMode && parent
        ? parent.height
        : LayoutMetrics.availableHeight(
            root.referenceHeight, Kirigami.Units.gridUnit)
}
