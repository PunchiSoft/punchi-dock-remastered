// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami

// Draws the button of the selected window decoration when the theme provides a
// compatible resource and falls back to a functional theme icon otherwise.
// Appearance belongs to the decoration; the action belongs to the consumer.
Item {
    id: root

    // Resolved by the consumer so the binding depends on the provider property
    // and follows decoration changes without restarting plasmashell.
    property string imagePath: ""
    property size buttonSize: Qt.size(16, 16)
    // The decoration's own vocabulary: active window versus inactive window.
    property bool decorationActive: true
    property bool glyphEnabled: true
    property bool glyphHovered: false
    property bool glyphPressed: false
    // Pointing at a control directly is not the same as owning the window focus:
    // consumers that show the pointer states as active set this to true, while the
    // rest state keeps respecting the window's active/inactive decoration state.
    property bool activePointerStates: false
    property string fallbackIconName: ""
    property int fallbackIconSize: Kirigami.Units.iconSizes.smallMedium
    property color fallbackIconColor: Kirigami.Theme.textColor

    readonly property bool usingDecoration: themedGlyph.imagePath.length > 0
        && themedGlyph.hasElementPrefix("active")
    readonly property string renderedPrefix: themedGlyph.usedPrefix

    implicitWidth: usingDecoration
        ? Math.max(0, buttonSize.width)
        : Math.max(0, fallbackIconSize)
    implicitHeight: usingDecoration
        ? Math.max(0, buttonSize.height)
        : Math.max(0, fallbackIconSize)

    KSvg.FrameSvgItem {
        id: themedGlyph

        anchors.centerIn: parent
        width: root.buttonSize.width
        height: root.buttonSize.height
        imagePath: root.imagePath
        enabledBorders: KSvg.FrameSvg.NoBorder
        visible: root.usingDecoration
        prefix: !root.glyphEnabled
            ? [root.decorationActive ? "deactivated" : "deactivated-inactive",
                "inactive", "active"]
            : (root.glyphPressed
                ? (root.activePointerStates
                    ? ["pressed", "pressed-inactive", "active"]
                    : [root.decorationActive ? "pressed" : "pressed-inactive",
                        "pressed", "active"])
                : (root.glyphHovered
                    ? (root.activePointerStates
                        ? ["hover", "hover-inactive", "active"]
                        : [root.decorationActive ? "hover" : "hover-inactive",
                            "hover", "active"])
                    : [root.decorationActive ? "active" : "inactive", "active"]))
        Accessible.ignored: true
    }

    Kirigami.Icon {
        anchors.centerIn: parent
        width: root.fallbackIconSize
        height: root.fallbackIconSize
        source: root.fallbackIconName
        color: root.fallbackIconColor
        visible: !root.usingDecoration
        Accessible.ignored: true
    }
}
