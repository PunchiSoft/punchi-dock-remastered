import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

Item {
    id: root

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    property alias confirmationContent: confirmationView
    property real maximumWidth: Screen.width - Kirigami.Units.largeSpacing * 2

    implicitWidth: Math.min(Math.max(1, Number(maximumWidth)),
        Kirigami.Units.gridUnit * 19
            + background.margins.left + background.margins.right
            + Kirigami.Units.largeSpacing * 2)
    implicitHeight: confirmationContent.implicitHeight
        + background.margins.top + background.margins.bottom
        + Kirigami.Units.largeSpacing * 2
    width: implicitWidth
    height: implicitHeight

    KSvg.FrameSvgItem {
        id: background
        anchors.fill: parent
        imagePath: "solid/dialogs/background"
        Accessible.ignored: true
    }

    ConfirmTrashEmptyPopup {
        id: confirmationView
        x: background.margins.left + Kirigami.Units.largeSpacing
        y: background.margins.top + Kirigami.Units.largeSpacing
        width: Math.max(0, root.width - x
            - background.margins.right - Kirigami.Units.largeSpacing)
        height: implicitHeight
    }
}
