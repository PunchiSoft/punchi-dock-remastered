pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects as Effects
import QtQuick.Window

Item {
    id: root

    required property url source
    property real radius: 0
    property int fillMode: Image.PreserveAspectCrop

    readonly property bool softwareRendering:
        GraphicsInfo.api === GraphicsInfo.Software
    readonly property int status: sourceImage.status
    readonly property bool ready: status === Image.Ready
    readonly property real safeRadius: Math.max(0,
        Math.min(Number.isFinite(radius) ? radius : 0,
            Math.min(width, height) / 2))

    Accessible.ignored: true

    Image {
        id: sourceImage

        anchors.fill: parent
        source: root.source
        sourceSize: Qt.size(
            Math.max(1, Math.round(root.width * Screen.devicePixelRatio)),
            Math.max(1, Math.round(root.height * Screen.devicePixelRatio)))
        fillMode: root.fillMode
        asynchronous: true
        cache: true
        smooth: true
        mipmap: true
        visible: status === Image.Ready
        layer.enabled: root.softwareRendering && root.safeRadius > 0
        layer.effect: Effects.MultiEffect {
            maskEnabled: true
            maskSource: softwareMask
        }
    }

    Item {
        id: softwareMask

        anchors.fill: parent
        visible: false
        layer.enabled: true
        layer.samples: 8

        Rectangle {
            anchors.fill: parent
            radius: root.safeRadius
            color: "white"
            antialiasing: true
        }
    }

    ShaderEffect {
        anchors.fill: parent
        visible: !root.softwareRendering && root.ready
        supportsAtlasTextures: true

        readonly property Item imageTexture: ShaderEffectSource {
            sourceItem: sourceImage
            hideSource: !root.softwareRendering
            live: true
        }
        readonly property vector4d roundedGeometry: Qt.vector4d(
            root.width, root.height, root.safeRadius, 0)

        fragmentShader:
            "qrc:/qt/qml/org/punchi/dock/shaders/RoundedImage.frag.qsb"
    }
}
