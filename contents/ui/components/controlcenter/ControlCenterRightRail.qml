// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.kirigami as Kirigami
import "ControlCenterLayoutMetrics.js" as LayoutMetrics

Item {
    id: root

    readonly property real edgeMargin:
        LayoutMetrics.edgeMargin(Kirigami.Units.gridUnit)

    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: root.edgeMargin
    anchors.rightMargin: root.edgeMargin
    width: LayoutMetrics.availableWidth(
        parent.width, Kirigami.Units.gridUnit)
    height: LayoutMetrics.availableHeight(
        parent.height, Kirigami.Units.gridUnit)
}
