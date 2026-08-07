import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: root

    property bool fieldActiveFocus: false
    property bool fieldHovered: false
    property bool auxiliaryHovered: false

    radius: height / 2
    color: Kirigami.Theme.backgroundColor
    border.width: fieldActiveFocus ? 2 : 1
    border.color: fieldActiveFocus
        ? Kirigami.Theme.highlightColor
        : Qt.alpha(Kirigami.Theme.textColor,
            fieldHovered || auxiliaryHovered ? 0.45 : 0.28)
    Accessible.ignored: true
}
