import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

Item {
    id: backgroundRoot

    property bool preferOpaque: false
    property bool spectrumActive: false
    property var spectrumLevels: []
    property real spectrumIntensity: 0.35
    property bool spectrumUsePlasmaTheme: true
    property int spectrumBarCount: 12
    property int spectrumOriginEdge: Qt.BottomEdge
    property real spectrumEdgeInset: 0
    property string spectrumBarStyle: "edge"
    property string spectrumFlowDirection: "none"
    property bool plasmaBackgroundVisible: true
    property bool customThemeEnabled: false
    property var customTheme: ({})

    readonly property bool customThemeVisible: plasmaBackgroundVisible
        && customThemeEnabled
        && customTheme
        && (customTheme.renderer === "flat"
            || customTheme.renderer === "shelf")

    KSvg.FrameSvgItem {
        anchors.fill: parent
        z: 0
        imagePath: "widgets/panel-background"
        visible: backgroundRoot.plasmaBackgroundVisible
            && !backgroundRoot.customThemeVisible
    }

    KSvg.FrameSvgItem {
        anchors.fill: parent
        z: 0
        imagePath: "solid/widgets/panel-background"
        opacity: backgroundRoot.preferOpaque ? 1 : 0
        visible: backgroundRoot.plasmaBackgroundVisible
            && !backgroundRoot.customThemeVisible

        Behavior on opacity {
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    FlatThemeBackground {
        anchors.fill: parent
        z: 0
        visible: backgroundRoot.customThemeVisible
            && backgroundRoot.customTheme.renderer === "flat"
        theme: backgroundRoot.customTheme
    }

    ShelfThemeBackground {
        anchors.fill: parent
        z: 0
        visible: backgroundRoot.customThemeVisible
            && backgroundRoot.customTheme.renderer === "shelf"
        theme: backgroundRoot.customTheme
    }

    AudioSpectrumLayer {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        z: 10
        active: backgroundRoot.spectrumActive
        levels: backgroundRoot.spectrumLevels
        intensity: backgroundRoot.spectrumIntensity
        usePlasmaTheme: backgroundRoot.spectrumUsePlasmaTheme
        barCount: backgroundRoot.spectrumBarCount
        originEdge: backgroundRoot.spectrumOriginEdge
        edgeInset: Math.max(0,
            backgroundRoot.spectrumEdgeInset - Kirigami.Units.smallSpacing)
        barStyle: backgroundRoot.spectrumBarStyle
        flowDirection: backgroundRoot.spectrumFlowDirection
    }
}
