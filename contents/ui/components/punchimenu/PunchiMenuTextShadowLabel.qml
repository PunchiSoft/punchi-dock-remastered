// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras

// Label of the dock popups, with the text shadow of the popup as its own.
//
// PlasmaExtras.ShadowedLabel paints its shadow through a texture of its own and
// with a fixed amount: a popup can only choose between that heavy shadow and
// none at all. This label keeps the text semantics of the shared one and draws
// the shadow itself, so the amount comes from the configuration and zero removes
// the shadow completely, texture included.
//
// The amount is mapped so that it reads the same all along the range: the blur
// radius grows from nothing to `shadowRadius` logical pixels, the offset from
// nothing to one pixel and the opacity from a light halo to an almost opaque
// shadow. One hundred percent is therefore as close to the profile Plasma draws
// by default as this effect can reach; the dilation (`spread`, 0.35 there) has
// no equivalent here.
PlasmaExtras.ShadowedLabel {
    id: root

    // Whether the popup asked for text shadows at all.
    property bool shadowEnabled: false
    // Amount of the shadow, in percent, from 0 (none) to 100 (the profile of
    // Plasma, as far as this effect reaches it).
    property int shadowPercent: 0
    // Radius the blur reaches at one hundred percent, in logical pixels. Small
    // on purpose: the label is about one line tall and blur is the most expensive
    // part of the effect.
    property int shadowRadius: 5

    readonly property real shadowAmount: {
        const requested = Number(root.shadowPercent)
        if (!Number.isFinite(requested)) {
            return 0
        }
        return Math.max(0, Math.min(100, requested)) / 100
    }
    readonly property bool shadowRequested: root.shadowEnabled
        && root.shadowAmount > 0
    // A blur that never falls to zero keeps the smallest amounts readable as a
    // shadow instead of turning into a hard copy of the glyphs.
    readonly property real shadowBlur: Math.max(0.15, root.shadowAmount)
    readonly property real shadowOpacity: 0.45 + 0.45 * root.shadowAmount
    readonly property real shadowOffset: 0.5 * root.shadowAmount
    // The shadow is darker than the surface behind the label, so it follows the
    // text colour instead of a fixed black: with a light theme it darkens the
    // glyphs, and with a dark theme it keeps the same separation instead of
    // disappearing into the surface.
    readonly property color shadowColor: Kirigami.Theme.textColor

    // The shadow of the shared label is never used here: this label owns the
    // whole effect.
    renderShadow: false
    // Software rendering cannot paint the effect, so the text stays without a
    // shadow there, exactly like the shared label falls back when it cannot
    // paint one either.
    layer.enabled: root.shadowRequested
        && GraphicsInfo.api !== GraphicsInfo.Software
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: root.shadowColor
        blurMax: root.shadowRadius
        shadowBlur: root.shadowBlur
        shadowOpacity: root.shadowOpacity
        shadowHorizontalOffset: root.shadowOffset
        shadowVerticalOffset: root.shadowOffset
    }
}
