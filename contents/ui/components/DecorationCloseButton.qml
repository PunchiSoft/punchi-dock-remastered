// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../org/punchi/dock" as PunchiDock

PlasmaComponents.ToolButton {
    id: root

    // Overridable inputs allow isolated fixtures without changing the desktop theme.
    property string decorationImagePath: PunchiDock.DecorationButtonProvider.closeButtonPath
    property size decorationButtonSize: PunchiDock.DecorationButtonProvider.buttonSize
    property bool decorationActive: Window.window ? Window.window.active : true
    readonly property bool usingDecoration: themedButton.imagePath.length > 0
        && themedButton.hasElementPrefix("active")
    readonly property string renderedPrefix: themedButton.usedPrefix

    implicitWidth: Math.max(20, decorationButtonSize.width + Kirigami.Units.smallSpacing * 2)
    implicitHeight: Math.max(20, decorationButtonSize.height + Kirigami.Units.smallSpacing * 2)
    padding: 0
    hoverEnabled: true
    activeFocusOnTab: true
    focusPolicy: Qt.StrongFocus
    text: i18n("Close") // qmllint disable unqualified
    Accessible.name: root.text
    Accessible.onPressAction: root.clicked()

    HoverHandler {
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
    }

    // Preserve the standard Plasma background for the fallback only. Focus has
    // a separate indicator: keyboard focus must not masquerade as pointer hover.
    Binding {
        target: root.background
        property: "opacity"
        value: root.usingDecoration ? 0 : 1
        when: root.background !== null
    }

    contentItem: Item {
        KSvg.FrameSvgItem {
            id: themedButton
            anchors.centerIn: parent
            width: root.decorationButtonSize.width
            height: root.decorationButtonSize.height
            imagePath: root.decorationImagePath
            enabledBorders: KSvg.FrameSvg.NoBorder
            visible: root.usingDecoration
            prefix: !root.enabled
                ? [root.decorationActive ? "deactivated" : "deactivated-inactive", "inactive", "active"]
                : (root.down
                    ? [root.decorationActive ? "pressed" : "pressed-inactive", "pressed", "active"]
                    : (root.hovered
                        ? [root.decorationActive ? "hover" : "hover-inactive", "hover", "active"]
                        : [root.decorationActive ? "active" : "inactive", "active"]))
            Accessible.ignored: true
        }
        Kirigami.Icon {
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.small
            height: width
            source: "window-close"
            visible: !root.usingDecoration
            Accessible.ignored: true
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: Kirigami.Units.cornerRadius
        border.width: 2
        border.color: Kirigami.Theme.highlightColor
        visible: root.usingDecoration && root.visualFocus
        Accessible.ignored: true
    }
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
}
