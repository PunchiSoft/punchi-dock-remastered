// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.kirigami as Kirigami
import "../org/punchi/dock" as Punchi

Item {
    id: root

    property bool active: false
    property bool blurEnabled: true
    property real backgroundOpacity: 0.50
    property bool motionEnabled: Kirigami.Units.longDuration > 0
    property int openDuration: Math.round(Kirigami.Units.longDuration * 1.1)
    property int closeDuration: Math.round(Kirigami.Units.shortDuration * 1.4)

    readonly property real safeBackgroundOpacity: {
        const requestedOpacity = Number(backgroundOpacity)
        return Number.isFinite(requestedOpacity)
            ? Math.max(0.50, Math.min(1.0, requestedOpacity))
            : 0.50
    }

    signal clicked()

    opacity: active ? 1.0 : 0.0

    Punchi.BlurBehindController {
        window: root.Window.window
        fullWindow: true
        enabled: root.active && root.blurEnabled
    }

    Rectangle {
        anchors.fill: parent
        color: Kirigami.Theme.backgroundColor
        opacity: root.safeBackgroundOpacity
        Accessible.ignored: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }

    Behavior on opacity {
        enabled: root.motionEnabled
        NumberAnimation {
            duration: root.active ? root.openDuration : root.closeDuration
            easing.type: root.active ? Easing.OutCubic : Easing.InQuad
        }
    }
}
