pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import "../org/punchi/dock" as PunchiDock

PlasmaComponents.ToolButton {
    id: root

    property bool destructive: false
    property int visualRadius: Kirigami.Units.cornerRadius
    // Empty keeps the Plasma-styled control. Otherwise the matching button of the
    // selected window decoration is drawn when the theme provides that resource.
    property string decorationRole: ""
    property bool decorationActive: true
    // Overridable inputs allow isolated fixtures without changing the desktop theme.
    property string decorationImagePath: decorationRole.length > 0
        ? String(PunchiDock.DecorationButtonProvider.buttonPaths[decorationRole] || "")
        : ""
    property size decorationButtonSize: PunchiDock.DecorationButtonProvider.buttonSize
    readonly property bool usingDecoration: decorationGlyph.usingDecoration
    readonly property string renderedPrefix: decorationGlyph.renderedPrefix
    readonly property color accentColor: destructive
        ? Kirigami.Theme.negativeTextColor
        : Kirigami.Theme.highlightColor
    readonly property bool highlightedContent: enabled
        && (hovered || pressed || activeFocus || actionToolTip.containsMouse)
    // Coherent pointer input: the tooltip area covers the whole control, so both
    // signals describe the same hover and must feed the same glyph state.
    readonly property bool pointerHovered: hovered || actionToolTip.containsMouse

    implicitWidth: 28
    implicitHeight: 28
    padding: 2
    focusPolicy: Qt.StrongFocus
    display: PlasmaComponents.AbstractButton.IconOnly
    opacity: enabled ? 1.0 : 0.38
    Accessible.name: text
    Accessible.role: Accessible.Button
    icon.color: destructive
        ? Kirigami.Theme.negativeTextColor
        : Kirigami.Theme.textColor

    // The decoration brings its own background and interaction states, so only the
    // focus ring stays here: keyboard focus must remain visible.
    contentItem: DecorationButtonGlyph {
        id: decorationGlyph
        imagePath: root.decorationImagePath
        buttonSize: root.decorationButtonSize
        decorationActive: root.decorationActive
        glyphEnabled: root.enabled
        glyphHovered: root.pointerHovered
        glyphPressed: root.pressed
        // The pointer is over the control itself: its hover and press read as
        // active, while the rest state still follows the window.
        activePointerStates: true
        fallbackIconName: String(root.icon.name)
        fallbackIconColor: root.icon.color
        fallbackIconSize: root.icon.width > 0
            ? root.icon.width
            : Kirigami.Units.iconSizes.smallMedium
    }

    background: Rectangle {
        radius: root.visualRadius
        color: root.usingDecoration || !root.highlightedContent
            ? "transparent"
            : Qt.alpha(root.accentColor, root.pressed ? 0.32 : 0.22)
        border.width: root.activeFocus ? 2
            : (root.usingDecoration ? 0
                : (root.hovered || actionToolTip.containsMouse ? 1 : 0))
        border.color: root.accentColor
        antialiasing: true
        Accessible.ignored: true

        Behavior on color {
            ColorAnimation {
                duration: Math.max(80,
                    Math.min(140, Kirigami.Units.shortDuration))
            }
        }
    }

    PlasmaCore.ToolTipArea {
        id: actionToolTip
        anchors.fill: parent
        active: root.enabled && root.visible && root.text.length > 0
        mainText: root.text
    }

    HoverHandler {
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
    }

    onActiveFocusChanged: {
        if (activeFocus) {
            actionToolTip.showToolTip()
        } else if (!actionToolTip.containsMouse) {
            actionToolTip.hideImmediately()
        }
    }
}
