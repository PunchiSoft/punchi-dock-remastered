import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: backgroundRect
    color: Kirigami.Theme.backgroundColor
    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
    border.width: 1
    
    // Suavizado para las esquinas redondeadas
    antialiasing: true
}
