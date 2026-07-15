import QtQuick

HoverHandler {
    id: root

    property bool cursorEnabled: false
    property string role: "click"

    enabled: cursorEnabled
    cursorShape: {
        if (role === "text") {
            return Qt.IBeamCursor
        }
        if (role === "slider") {
            return Qt.OpenHandCursor
        }
        return Qt.PointingHandCursor
    }
}
