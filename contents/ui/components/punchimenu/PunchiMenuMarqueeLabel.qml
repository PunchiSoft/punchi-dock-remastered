// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

// Shared caption for launchers that can keep a compact resting width and reveal
// the complete accessible name without resizing its delegate.
Item {
    id: root

    property string text: ""
    property bool hovered: false
    property bool focused: false
    property bool motionEnabled: Kirigami.Units.longDuration > 1
    property bool shorteningEnabled: true
    property int visibleCharacterLimit: 10
    property color color: Kirigami.Theme.textColor
    property font font: Kirigami.Theme.defaultFont
    property int horizontalAlignment: Text.AlignLeft
    property int verticalAlignment: Text.AlignVCenter
    property int maximumLineCount: 1
    property int wrapMode: Text.NoWrap
    property bool shadowEnabled: false
    property int shadowPercent: 0

    readonly property int safeVisibleCharacterLimit: Math.max(6,
        Math.min(20, Math.round(Number(visibleCharacterLimit) || 10)))
    readonly property bool revealFullText: shorteningEnabled && overflowing
        && (hovered || focused)
    readonly property real naturalTextWidth: Math.ceil(textMetrics.advanceWidth)
    readonly property real maximumRestingWidth: shorteningEnabled
        ? Math.ceil(restingWidthMetrics.advanceWidth) : width
    readonly property real viewportWidth: Math.max(0,
        Math.min(width, maximumRestingWidth))
    readonly property bool overflowing: shorteningEnabled
        && naturalTextWidth > viewportWidth + 0.5
    readonly property real terminalOffset: Math.min(0,
        viewportWidth - naturalTextWidth)
    readonly property real scrollOffset: movingLabel.x
    readonly property real marqueeTravelGridUnitsPerLongDuration: 0.65
    readonly property real marqueeVelocity: motionEnabled
        ? Kirigami.Units.gridUnit
            * marqueeTravelGridUnitsPerLongDuration * 1000
            / Kirigami.Units.longDuration
        : -1
    readonly property real restingOpacity: restingLabel.opacity
    readonly property real movingOpacity: movingLabel.opacity
    readonly property bool truncated: restingLabel.truncated

    implicitWidth: shorteningEnabled
        ? Math.min(naturalTextWidth, maximumRestingWidth)
        : naturalTextWidth
    implicitHeight: shorteningEnabled
        ? Math.ceil(fontMetrics.height)
        : Math.ceil(fontMetrics.height * Math.max(1, maximumLineCount))
    Accessible.ignored: true

    TextMetrics {
        id: textMetrics
        font: root.font
        text: root.text
    }

    TextMetrics {
        id: restingWidthMetrics
        font: root.font
        text: "MMMMMMMMMMMMMMMMMMMM".substring(
            0, root.safeVisibleCharacterLimit)
    }

    FontMetrics {
        id: fontMetrics
        font: root.font
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

        PunchiMenuTextShadowLabel {
            id: restingLabel

            anchors.fill: parent
            text: root.text
            color: root.color
            font: root.font
            textFormat: Text.PlainText
            horizontalAlignment: root.horizontalAlignment
            verticalAlignment: root.verticalAlignment
            maximumLineCount: root.shorteningEnabled
                ? 1 : root.maximumLineCount
            wrapMode: root.shorteningEnabled ? Text.NoWrap : root.wrapMode
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

        PunchiMenuTextShadowLabel {
            id: movingLabel

            x: root.revealFullText && root.motionEnabled
                ? root.terminalOffset : 0
            width: root.naturalTextWidth
            height: parent.height
            text: root.text
            color: root.color
            font: root.font
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: root.verticalAlignment
            maximumLineCount: 1
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

    Controls.ToolTip.visible: root.revealFullText && !root.motionEnabled
    Controls.ToolTip.text: root.text
}
