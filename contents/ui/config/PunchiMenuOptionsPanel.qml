// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Options of a PunchiMenu element: the display mode and the icon.
//
// This is a passive visual component. It receives the current values through its
// properties, announces what the user asked for through its signals and writes
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

    // Values the caller owns. Writing them moves the selection without announcing
    // an intention; only the interaction of the user emits a signal.
    property string menuMode: "normal"
    property string iconName: "start-here-kde"
    property real selectorWidth: Kirigami.Units.gridUnit * 16
    // Layout variant. By default the label and its control share one row, which is
    // the distribution the existing dialog keeps; with the property set the label
    // takes its own row, for a panel that has to live in a narrow column.
    property bool compactLayout: false

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

    // Intentions of the user, announced as they are: the repository decides
    // whether they become a draft value, a stored item or nothing at all.
    signal menuModeSelected(string mode)
    signal iconPickerRequested()

    function modeIndex(mode) {
        for (let index = 0; index < root.modeOptions.length; index++) {
            if (root.modeOptions[index].value === mode) {
                return index
            }
        }
        return 0
    }

    // Moves the shown selection to the mode of the current value and announces
    // nothing: it runs when the value changes and when the surface that hosts the
    // panel opens again, so a value set from outside is never read as a choice of
    // the user.
    function synchronizeSelection() {
        modeCombo.currentIndex = root.modeIndex(root.menuMode)
    }

    onMenuModeChanged: root.synchronizeSelection()
    Component.onCompleted: root.synchronizeSelection()

    GridLayout {
        Layout.fillWidth: true
        columns: root.compactLayout ? 1 : 4
        columnSpacing: Kirigami.Units.smallSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        Controls.Label {
            Layout.alignment: root.compactLayout ? Qt.AlignLeft : Qt.AlignVCenter
            text: i18n("Menu mode:")
        }

        Controls.ComboBox {
            id: modeCombo

            objectName: "punchiMenuModeCombo"

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
                root.menuModeSelected(String(option.value))
            }
        }

        Controls.Label {
            Layout.alignment: root.compactLayout ? Qt.AlignLeft : Qt.AlignVCenter
            text: i18n("Icon:")
        }

        Controls.Button {
            objectName: "punchiMenuIconButton"

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
