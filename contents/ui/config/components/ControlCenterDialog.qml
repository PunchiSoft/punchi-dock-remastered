// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import ".."

// Thin wrapper of `ControlCenterOptionsPanel`.
//
// The panel owns the layout, the list of modes and their texts; this dialog keeps
// only what makes it a dialog—title, modality, close button and size—plus the
// public API it already had, so every existing caller keeps working. It forwards
// what the panel announces and updates its own state, and writes nothing else.
//
// Translation helpers are supplied by the KCM context.
// qmllint disable unqualified
Controls.Dialog {
    id: root

    objectName: "controlCenterConfigDialog"

    // Public API kept as it was: the panel owns the value it shows, so this
    // wrapper only mirrors it and announces what the user asked for.
    property string controlCenterMode: "floating"
    property real selectorWidth: Kirigami.Units.gridUnit * 16
    readonly property alias modeOptions: optionsPanel.modeOptions

    signal controlCenterModeSelected(string mode)

    function modeIndex(mode) {
        return optionsPanel.modeIndex(mode)
    }

    function synchronizeModeSelection() {
        optionsPanel.synchronizeSelection()
    }

    title: i18nc("@title:window", "Configure Control Center")
    modal: true
    standardButtons: Controls.Dialog.Close
    // A value set from outside is the state of the dialog, never a choice of the
    // user: showing it again must not announce an intention.
    onOpened: optionsPanel.synchronizeSelection()

    contentItem: ControlCenterOptionsPanel {
        id: optionsPanel

        controlCenterMode: root.controlCenterMode
        selectorWidth: root.selectorWidth
        onControlCenterModeSelected: function(mode) {
            root.controlCenterMode = String(mode)
            root.controlCenterModeSelected(root.controlCenterMode)
        }
    }
}
// qmllint enable unqualified
