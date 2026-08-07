pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects as Effects
import QtQuick.Window
import org.kde.kirigami as Kirigami

Item {
    id: root

    required property url source
    property string fallbackIcon: "user-identity"
    property color borderColor: Kirigami.Theme.textColor
    property color backgroundColor: Kirigami.Theme.backgroundColor

    readonly property bool softwareRendering:
        GraphicsInfo.api === GraphicsInfo.Software

    Accessible.ignored: true

    Rectangle {
        anchors.centerIn: parent
        width: Math.max(0, parent.width - 2)
        height: width
        radius: width / 2
        color: root.backgroundColor
        opacity: 0.6
        antialiasing: true
    }

    Item {
        id: imageSource

        anchors.fill: parent
        layer.enabled: root.softwareRendering
        layer.effect: Effects.MultiEffect {
            maskEnabled: true
            maskSource: softwareMask
        }

        Image {
            id: avatarImage

            anchors.fill: parent
            source: root.source
            sourceSize: Qt.size(
                Math.round(root.width * Screen.devicePixelRatio),
                Math.round(root.height * Screen.devicePixelRatio))
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            autoTransform: true
            smooth: true
            mipmap: true
            visible: status === Image.Ready
        }

        Kirigami.Icon {
            anchors.fill: parent
            source: root.fallbackIcon
            visible: avatarImage.status !== Image.Ready
            Accessible.ignored: true
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
            radius: width / 2
            color: "white"
            antialiasing: true
        }
    }

    ShaderEffect {
        anchors.fill: parent
        visible: !root.softwareRendering
        supportsAtlasTextures: true

        readonly property Item avatarTexture: ShaderEffectSource {
            sourceItem: imageSource
            hideSource: !root.softwareRendering
            live: true
        }
        readonly property color colorBorder: root.borderColor

        fragmentShader:
            "qrc:/qt/qml/org/punchi/dock/shaders/PunchiMenuAvatar.frag.qsb"
    }

    Rectangle {
        anchors.fill: parent
        visible: root.softwareRendering
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: root.borderColor
        antialiasing: true
        layer.enabled: true
        layer.samples: 8
    }
}
