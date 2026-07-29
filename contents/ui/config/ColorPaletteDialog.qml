import QtQuick
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami


Item {
    id: root

    property string title: ""
    property string currentColor: ""
    property color fallbackColor: Kirigami.Theme.textColor

    signal colorChosen(string color)

    function open() {
        openNativeColorDialog()
    }

    function openNativeColorDialog() {
        plasmaColorDialog.selectedColor = parseColor(currentColor, fallbackColor)
        plasmaColorDialog.open()
    }

    function parseColor(value, fallback) {
        var text = String(value || "")
        if (text.length > 0) {
            return text
        }
        return fallback
    }

    function colorToHex(value) {
        return "#" + channelToHex(value.r * 255) + channelToHex(value.g * 255) + channelToHex(value.b * 255)
    }

    function channelToHex(value) {
        var text = Math.max(0, Math.min(255, Math.round(value))).toString(16)
        return text.length === 1 ? "0" + text : text
    }

    ColorDialog {
        id: plasmaColorDialog

        title: root.title
        selectedColor: root.parseColor(root.currentColor, root.fallbackColor)
        onAccepted: root.colorChosen(root.colorToHex(selectedColor))
    }
}
