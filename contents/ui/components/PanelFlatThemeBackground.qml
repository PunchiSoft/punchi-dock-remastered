// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import "../org/punchi/dock" as Punchi

Punchi.PanelThemeSurface {
    id: root

    property var theme: ({})
    property bool dockVertical: false
    property real restingPadding: 0
    property bool backgroundVisible: true
    property bool spectrumVisible: false
    property bool spectrumActive: false
    property var spectrumLevels: []
    property real spectrumIntensity: 0.35
    property bool spectrumUsePlasmaTheme: true
    property int spectrumBarCount: 12
    property int spectrumOriginEdge: Qt.BottomEdge
    property string spectrumBarStyle: "edge"
    property string spectrumFlowDirection: "none"
    readonly property bool aligned: hosting && contentGeometry.width > 0
        && contentGeometry.height > 0
    readonly property bool spectrumHosted: aligned && spectrumVisible
    readonly property real visibleThickness: (dockVertical
        ? contentGeometry.width : contentGeometry.height) + restingPadding * 2
    readonly property real surfaceX: dockVertical ? contentGeometry.x - restingPadding : 0
    readonly property real surfaceY: dockVertical ? 0 : contentGeometry.y - restingPadding
    readonly property var shadowData: theme && theme.shadow ? theme.shadow : ({})
    readonly property real shadowSize: Number(shadowData.size || 0)
    readonly property real leftReserve: shadowSize + Math.max(0, -Number(shadowData.xOffset || 0))
    readonly property real rightReserve: shadowSize + Math.max(0, Number(shadowData.xOffset || 0))
    readonly property real topReserve: shadowSize + Math.max(0, -Number(shadowData.yOffset || 0))
    readonly property real bottomReserve: shadowSize + Math.max(0, Number(shadowData.yOffset || 0))

    Accessible.ignored: true

    FlatThemeBackground {
        objectName: "panelFlatThemeRenderer"
        // The host retains zoom headroom; only the resting strip is painted.
        // Preserve the frame's length and put shadows outside the colored strip.
        x: root.surfaceX - root.leftReserve
        y: root.surfaceY - root.topReserve
        width: (root.dockVertical ? root.visibleThickness : root.width)
            + root.leftReserve + root.rightReserve
        height: (root.dockVertical ? root.height : root.visibleThickness)
            + root.topReserve + root.bottomReserve
        visible: root.aligned && root.backgroundVisible
        theme: root.theme
        dockVertical: root.dockVertical
        inPanel: true
        Accessible.ignored: true
    }

    Item {
        objectName: "panelAudioSpectrumRenderer"
        x: root.surfaceX
        y: root.surfaceY
        width: root.dockVertical ? root.visibleThickness : root.width
        height: root.dockVertical ? root.height : root.visibleThickness
        visible: root.spectrumHosted
        Accessible.ignored: true

        AudioSpectrumLayer {
            anchors.fill: parent
            active: root.spectrumActive
            levels: root.spectrumLevels
            intensity: root.spectrumIntensity
            usePlasmaTheme: root.spectrumUsePlasmaTheme
            barCount: root.spectrumBarCount
            vertical: root.dockVertical
            originEdge: root.spectrumOriginEdge
            barStyle: root.spectrumBarStyle
            flowDirection: root.spectrumFlowDirection
        }
    }
}
