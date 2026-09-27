import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import ".."

// Thin wrapper of `PunchiMenuOptionsPanel`.
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

    // Public API kept as it was: the panel owns the values it shows, so this
    // wrapper only mirrors them and announces what the user asked for.
    property string menuMode: "normal"
    property string iconName: "start-here-kde"
    property real selectorWidth: Kirigami.Units.gridUnit * 16
    readonly property alias modeOptions: optionsPanel.modeOptions

    signal menuModeSelected(string mode)
    signal iconPickerRequested()

    function modeIndex(mode) {
        return optionsPanel.modeIndex(mode)
    }

    title: i18n("Configure PunchiMenu")
    modal: true
    standardButtons: Controls.Dialog.Close
    // A value set from outside is the state of the dialog, never a choice of the
    // user: showing it again must not announce an intention.
    onOpened: optionsPanel.synchronizeSelection()

    contentItem: PunchiMenuOptionsPanel {
        id: optionsPanel

        menuMode: root.menuMode
        iconName: root.iconName
        selectorWidth: root.selectorWidth
        onMenuModeSelected: function(mode) {
            root.menuMode = String(mode)
            root.menuModeSelected(root.menuMode)
        }
        onIconPickerRequested: root.iconPickerRequested()
    }
}
// qmllint enable unqualified
