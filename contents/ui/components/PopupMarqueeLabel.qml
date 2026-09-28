// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import "punchimenu" as PunchiMenuComponents

// Compact popup caption that keeps a quiet elided resting state and reveals its
// full accessible text while the launcher is hovered or keyboard-focused.
//
// Only the full-text layer moves. The viewport and its parent layout stay fixed,
// so the interaction does not relayout neighbouring delegates per frame.
Item {
    id: root

    property string text: ""
    property bool hovered: false
    property bool focused: false
    property bool motionEnabled: Kirigami.Units.longDuration > 1
    property color color: Kirigami.Theme.textColor
    property font font: Kirigami.Theme.defaultFont
    property int horizontalAlignment: Text.AlignLeft
    property int verticalAlignment: Text.AlignVCenter
    property bool shadowEnabled: false
    property int shadowPercent: 0

    readonly property bool revealFullText: overflowing
        && (hovered || focused)
    readonly property real naturalTextWidth: Math.ceil(textMetrics.advanceWidth)
    // Ten wide glyphs provide a font-aware ceiling close to the requested
    // 8–10 visible characters. Narrow cells may expose less; wide list rows do
    // not silently expand the resting caption beyond this ceiling.
    readonly property real maximumRestingWidth:
        Math.ceil(restingWidthMetrics.advanceWidth)
    readonly property real viewportWidth: Math.max(0,
        Math.min(width, maximumRestingWidth))
    readonly property bool overflowing: naturalTextWidth > viewportWidth + 0.5
    readonly property real terminalOffset: Math.min(0,
        viewportWidth - naturalTextWidth)
    readonly property real scrollOffset: movingLabel.x
    readonly property real marqueeVelocity: motionEnabled
        ? Kirigami.Units.gridUnit * 2 * 1000
            / Kirigami.Units.longDuration
        : -1
    readonly property real restingOpacity: restingLabel.opacity
    readonly property real movingOpacity: movingLabel.opacity

    implicitWidth: Math.min(naturalTextWidth, maximumRestingWidth)
    implicitHeight: Math.max(restingLabel.implicitHeight,
        movingLabel.implicitHeight)
    Accessible.ignored: true

    TextMetrics {
        id: textMetrics
        font: root.font
        text: root.text
    }

    TextMetrics {
        id: restingWidthMetrics
        font: root.font
        text: "MMMMMMMMMM"
    }

    Item {
        id: viewport

        x: root.horizontalAlignment & Text.AlignHCenter
            ? (root.width - width) / 2
            : (root.horizontalAlignment & Text.AlignRight
                ? root.width - width : 0)
        width: root.viewportWidth
        height: root.height
        clip: true

        PunchiMenuComponents.PunchiMenuTextShadowLabel {
            id: restingLabel

            anchors.fill: parent
            text: root.text
            color: root.color
            font: root.font
            horizontalAlignment: root.horizontalAlignment
            verticalAlignment: root.verticalAlignment
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            opacity: root.revealFullText && root.motionEnabled ? 0 : 1
            shadowEnabled: root.shadowEnabled && opacity > 0.001
            shadowPercent: root.shadowPercent

            Behavior on opacity {
                enabled: root.motionEnabled
                NumberAnimation {
                    duration: Kirigami.Units.veryShortDuration
                    easing.type: Easing.OutQuad
                }
            }
        }

        PunchiMenuComponents.PunchiMenuTextShadowLabel {
            id: movingLabel

            x: root.revealFullText && root.motionEnabled
                ? root.terminalOffset : 0
            width: root.naturalTextWidth
            height: parent.height
            text: root.text
            color: root.color
            font: root.font
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: root.verticalAlignment
            wrapMode: Text.NoWrap
            elide: Text.ElideNone
            opacity: root.revealFullText && root.motionEnabled ? 1 : 0
            visible: opacity > 0.001
            shadowEnabled: root.shadowEnabled && opacity > 0.001
            shadowPercent: root.shadowPercent

            Behavior on x {
                enabled: root.motionEnabled
                SmoothedAnimation {
                    velocity: root.marqueeVelocity
                    easing.type: Easing.InOutQuad
                }
            }

            Behavior on opacity {
                enabled: root.motionEnabled
                NumberAnimation {
                    duration: Kirigami.Units.veryShortDuration
                    easing.type: Easing.OutQuad
                }
            }
        }
    }

    // Reduced motion keeps the compact label stable and exposes the same full
    // name without spatial movement.
    Controls.ToolTip.visible: root.revealFullText && !root.motionEnabled
    Controls.ToolTip.text: root.text
}
