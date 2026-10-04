// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../org/punchi/dock" as PunchiDock

PlasmaComponents.ToolButton {
    id: root

    // Overridable inputs allow isolated fixtures without changing the desktop theme.
    property string decorationImagePath: PunchiDock.DecorationButtonProvider.closeButtonPath
    property size decorationButtonSize: PunchiDock.DecorationButtonProvider.buttonSize
    property bool decorationActive: Window.window ? Window.window.active : true
    readonly property bool usingDecoration: glyph.usingDecoration
    readonly property string renderedPrefix: glyph.renderedPrefix

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

    contentItem: DecorationButtonGlyph {
        id: glyph
        imagePath: root.decorationImagePath
        buttonSize: root.decorationButtonSize
        decorationActive: root.decorationActive
        glyphEnabled: root.enabled
        glyphHovered: root.hovered
        glyphPressed: root.down
        fallbackIconName: "window-close"
        fallbackIconSize: Kirigami.Units.iconSizes.small
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
