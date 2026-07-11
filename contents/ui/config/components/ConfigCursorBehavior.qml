import QtQuick

HoverHandler {
    id: root

    property bool active: false
    property string role: "click"

    enabled: active
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
