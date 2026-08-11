import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Translation helpers are supplied by the KCM context.
// qmllint disable unqualified
Controls.Dialog {
    id: root

    property string menuMode: "normal"
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
            "text": i18nc("@option:punchimenu-mode", "Compact (coming soon)"),
            "value": "compact",
            "available": false
        }
    ]

    signal menuModeSelected(string mode)

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

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        Controls.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: root.selectorWidth
            text: i18n("Menu mode:")
            wrapMode: Text.WordWrap
        }

        Controls.ComboBox {
            id: modeCombo

            Layout.fillWidth: true
            Layout.preferredWidth: root.selectorWidth
            Layout.maximumWidth: root.selectorWidth
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
    }
}
// qmllint enable unqualified
