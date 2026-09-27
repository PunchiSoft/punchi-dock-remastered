// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Options of a Control Center element: the display mode.
//
// This is a passive visual component. It receives the current value through its
// property, announces what the user asked for through its signal and writes
// nothing: it never touches the dock item list, the configuration values or the
// draft of the add dialog. Its caller decides what an intention means.
//
// The list of modes and its texts live only here: the dialog that hosts the panel
// keeps no second copy of either.
//
// Translation helpers are supplied by the KCM context.
// qmllint disable unqualified
ColumnLayout {
    id: root

    // Value the caller owns. Writing it moves the selection without announcing an
    // intention; only the interaction of the user emits a signal.
    property string controlCenterMode: "floating"
    property real selectorWidth: Kirigami.Units.gridUnit * 16
    // Layout variant. By default the label and its control share one row, which is
    // the distribution the existing dialog keeps; with the property set the label
    // takes its own row, for a panel that has to live in a narrow column.
    property bool compactLayout: false

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

    // Intention of the user, announced as it is: the repository decides whether it
    // becomes a draft value, a stored item or nothing at all.
    signal controlCenterModeSelected(string mode)

    function modeIndex(mode) {
        for (let index = 0; index < root.modeOptions.length; index++) {
            if (root.modeOptions[index].value === mode) {
                return index
            }
        }
        return 1
    }

    // Moves the shown selection to the mode of the current value and announces
    // nothing: it runs when the value changes and when the surface that hosts the
    // panel opens again, so a value set from outside is never read as a choice of
    // the user.
    function synchronizeSelection() {
        modeCombo.currentIndex = root.modeIndex(root.controlCenterMode)
    }

    onControlCenterModeChanged: root.synchronizeSelection()
    Component.onCompleted: root.synchronizeSelection()

    GridLayout {
        Layout.fillWidth: true
        columns: root.compactLayout ? 1 : 2
        columnSpacing: Kirigami.Units.smallSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        Controls.Label {
            Layout.alignment: root.compactLayout ? Qt.AlignLeft : Qt.AlignVCenter
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
                root.controlCenterModeSelected(String(option.value))
            }
        }
    }
}
// qmllint enable unqualified
