import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

RowLayout {
    id: root

    property string customColor: ""
    property color fallbackColor: Kirigami.Theme.textColor
    property real selectorWidth: 0
    readonly property string normalizedCustomColor: {
        const value = String(customColor || "").trim()
        return /^#[0-9a-fA-F]{6}$/.test(value) ? value : ""
    }
    readonly property bool customMode: normalizedCustomColor.length > 0
    readonly property color effectiveColor: customMode ? normalizedCustomColor : fallbackColor

    signal colorRequested()
    signal themeRequested()

    function syncMode() {
        colorModeCombo.currentIndex = root.customMode ? 1 : 0
    }

    spacing: Kirigami.Units.smallSpacing

    // qmllint disable unqualified
    Controls.RoundButton {
        id: colorButton

        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
        Layout.preferredHeight: Layout.preferredWidth
        padding: Kirigami.Units.smallSpacing
        enabled: root.enabled
        display: Controls.AbstractButton.IconOnly
        Accessible.name: i18n("Choose custom color")
        Accessible.description: i18n("Current color: %1", root.customMode
            ? root.normalizedCustomColor.toUpperCase()
            : i18n("Plasma color"))
        onClicked: root.colorRequested()

        contentItem: Rectangle {
            implicitWidth: Kirigami.Units.iconSizes.smallMedium
            implicitHeight: implicitWidth
            radius: width / 2
            color: root.effectiveColor
            border.width: 1
            border.color: Kirigami.Theme.textColor
        }

        Controls.ToolTip.visible: hovered
        Controls.ToolTip.text: i18n("Choose custom color")
    }

    Controls.ComboBox {
        id: colorModeCombo

        Layout.fillWidth: true
        Layout.preferredWidth: root.selectorWidth > 0 ? root.selectorWidth : implicitWidth
        Layout.maximumWidth: root.selectorWidth > 0 ? root.selectorWidth : Number.POSITIVE_INFINITY
        enabled: root.enabled
        textRole: "text"
        valueRole: "value"
        displayText: root.customMode ? i18n("Custom color") : i18n("Plasma color")
        Accessible.name: i18n("Color source")
        model: [
            { "text": i18n("Plasma color"), "value": "plasma" },
            { "text": i18n("Custom color"), "value": "custom" }
        ]
        onActivated: {
            if (currentValue === "plasma") {
                root.themeRequested()
            } else {
                root.colorRequested()
            }
            Qt.callLater(root.syncMode)
        }
    }
    // qmllint enable unqualified

    onCustomColorChanged: syncMode()
    Component.onCompleted: syncMode()
}
