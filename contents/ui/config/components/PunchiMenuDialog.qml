import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Translation helpers are supplied by the KCM context.
// qmllint disable unqualified
Controls.Dialog {
    id: root

    property string menuMode: "normal"
    property string iconName: "start-here-kde"
    property real selectorWidth: Kirigami.Units.gridUnit * 16
    readonly property var modeOptions: [
        {
            "text": i18nc("@option:punchimenu-mode", "Full screen"),
            "value": "fullScreen",
            "available": true
        },
        {
            "text": i18nc("@option:punchimenu-mode", "Normal"),
            "value": "normal",
            "available": true
        },
        {
            "text": i18nc("@option:punchimenu-mode", "Compact"),
            "value": "compact",
            "available": true
        }
    ]

    signal menuModeSelected(string mode)
    signal iconPickerRequested()

    function modeIndex(mode) {
        for (let index = 0; index < modeOptions.length; index++) {
            if (modeOptions[index].value === mode) {
                return index
            }
        }
        return 0
    }

    title: i18n("Configure PunchiMenu")
    modal: true
    standardButtons: Controls.Dialog.Close
    onOpened: modeCombo.currentIndex = root.modeIndex(root.menuMode)

    contentItem: RowLayout {
        spacing: Kirigami.Units.smallSpacing

        Controls.Label {
            text: i18n("Menu mode:")
        }

        Controls.ComboBox {
            id: modeCombo

            Layout.fillWidth: true
            Layout.minimumWidth: Kirigami.Units.gridUnit * 8
            Layout.preferredWidth: Math.min(root.selectorWidth,
                Kirigami.Units.gridUnit * 12)
            Layout.maximumWidth: Kirigami.Units.gridUnit * 12
            model: root.modeOptions
            textRole: "text"
            Accessible.name: i18n("PunchiMenu display mode")

            delegate: Controls.ItemDelegate {
                required property int index
                required property var modelData

                width: modeCombo.width
                text: String(modelData.text || "")
                enabled: modelData.available === true
                highlighted: modeCombo.highlightedIndex === index
            }

            onActivated: function(index) {
                const option = root.modeOptions[index]
                if (!option || option.available !== true) {
                    currentIndex = root.modeIndex(root.menuMode)
                    return
                }
                root.menuMode = String(option.value)
                root.menuModeSelected(root.menuMode)
            }
        }

        Controls.Label {
            text: i18n("Icon:")
        }

        Controls.Button {
            icon.name: root.iconName
            display: Controls.AbstractButton.IconOnly
            text: i18nc("@action:button", "Choose PunchiMenu icon")
            Accessible.name: text
            Accessible.description: i18nc("@info:accessibility",
                "Current icon: %1", root.iconName)
            onClicked: root.iconPickerRequested()

            Controls.ToolTip.visible: hovered
            Controls.ToolTip.text: text
        }
    }
}
// qmllint enable unqualified
