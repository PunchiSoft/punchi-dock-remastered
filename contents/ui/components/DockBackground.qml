import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

Item {
    id: backgroundRoot

    property bool preferOpaque: false

    KSvg.FrameSvgItem {
        anchors.fill: parent
        imagePath: "widgets/panel-background"
    }

    KSvg.FrameSvgItem {
        anchors.fill: parent
        imagePath: "solid/widgets/panel-background"
        opacity: backgroundRoot.preferOpaque ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}
