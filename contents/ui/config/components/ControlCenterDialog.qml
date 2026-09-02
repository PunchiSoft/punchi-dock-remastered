// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Translation helpers are supplied by the KCM context.
// qmllint disable unqualified
Controls.Dialog {
    id: root

    objectName: "controlCenterConfigDialog"

    property string controlCenterMode: "fullScreen"
    property real selectorWidth: Kirigami.Units.gridUnit * 16
    readonly property var modeOptions: [
        {
            "text": i18nc("@option:control-center-mode", "Full screen"),
            "value": "fullScreen"
        },
        {
            "text": i18nc("@option:control-center-mode", "Floating"),
            "value": "floating"
        }
    ]

    signal controlCenterModeSelected(string mode)

    function modeIndex(mode) {
        for (let index = 0; index < root.modeOptions.length; index++) {
            if (root.modeOptions[index].value === mode) {
                return index
            }
        }
        return 0
    }

    function synchronizeModeSelection() {
        modeCombo.currentIndex = root.modeIndex(root.controlCenterMode)
    }

    title: i18nc("@title:window", "Configure Control Center")
    modal: true
    standardButtons: Controls.Dialog.Close
    onOpened: root.synchronizeModeSelection()

    contentItem: RowLayout {
        spacing: Kirigami.Units.smallSpacing

        Controls.Label {
            text: i18nc("@label:listbox", "Display mode:")
        }

        Controls.ComboBox {
            id: modeCombo

            objectName: "controlCenterModeCombo"

            Layout.fillWidth: true
            Layout.minimumWidth: Kirigami.Units.gridUnit * 8
            Layout.preferredWidth: Math.min(root.selectorWidth,
                Kirigami.Units.gridUnit * 12)
            Layout.maximumWidth: Kirigami.Units.gridUnit * 12
            model: root.modeOptions
            textRole: "text"
            Accessible.name: i18nc("@info:accessibility",
                "Control Center display mode")

            delegate: Controls.ItemDelegate {
                required property int index
                required property var modelData

                width: modeCombo.width
                text: String(modelData.text || "")
                highlighted: modeCombo.highlightedIndex === index
            }

            onActivated: function(index) {
                const option = root.modeOptions[index]
                if (!option) {
                    currentIndex = root.modeIndex(root.controlCenterMode)
                    return
                }
                root.controlCenterMode = String(option.value)
                root.controlCenterModeSelected(root.controlCenterMode)
            }
        }
    }
}
// qmllint enable unqualified
