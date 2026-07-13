import QtQuick
import org.kde.kirigami as Kirigami

QtObject {
    property real availableWidth: 0

    readonly property int pageImplicitWidth: Kirigami.Units.gridUnit * 28
    readonly property int contentWidth: Math.max(300,
        Math.min(380, availableWidth - (Kirigami.Units.gridUnit * 4)))
    readonly property int selectorWidth: Math.max(200,
        Math.min(280, contentWidth - (Kirigami.Units.gridUnit * 4)))
    readonly property int helperIndent: Kirigami.Units.largeSpacing
}
