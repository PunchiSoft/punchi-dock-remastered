import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import ".."

// Thin wrapper of `MediaPlayerOptionsPanel`.
//
// The panel owns the layout, the list of options it shows and the rules that
// compose it; this dialog keeps only what makes it a dialog—modality and its close
// button, plus the title the page gives it—and the public API it already had, so
// every existing caller keeps working. It updates its own state with what the panel
// announces and forwards it; it writes nothing else.
//
// Translation helpers are supplied by the KCM context.
// qmllint disable unqualified
Controls.Dialog {
    id: root

    property var applications: []
    property string selectedStorageId: ""
    property string mediaTextMode: "automatic"
    property string mediaDisplayMode: "normal"
    property bool openPlayerMinimized: false
    property int autoCollapseDelaySeconds: 3
    property real selectorWidth: Kirigami.Units.gridUnit * 16
    property alias playerOptions: optionsPanel.playerOptions
    readonly property alias textModeOptions: optionsPanel.textModeOptions
    readonly property alias displayModeOptions: optionsPanel.displayModeOptions

    signal playerSelected(var application)
    signal mediaTextModeSelected(string mode)
    signal mediaDisplayModeSelected(string mode)
    signal openPlayerMinimizedSelected(bool enabled)
    signal autoCollapseDelaySecondsSelected(int seconds)

    // The dialog keeps these helpers because they were part of its API; the work
    // belongs to the panel, so no rule is repeated here.
    function rebuildOptions() {
        optionsPanel.rebuildOptions()
    }

    function syncSelection() {
        optionsPanel.syncSelection()
    }

    function syncTextModeSelection() {
        optionsPanel.syncTextModeSelection()
    }

    function syncDisplayModeSelection() {
        optionsPanel.syncDisplayModeSelection()
    }

    modal: true
    standardButtons: Controls.Dialog.Close

    contentItem: MediaPlayerOptionsPanel {
        id: optionsPanel

        applications: root.applications
        selectedStorageId: root.selectedStorageId
        mediaTextMode: root.mediaTextMode
        mediaDisplayMode: root.mediaDisplayMode
        openPlayerMinimized: root.openPlayerMinimized
        autoCollapseDelaySeconds: root.autoCollapseDelaySeconds
        selectorWidth: root.selectorWidth
        // Choosing a player also moves the shown selection, exactly as it did
        // before: the value belongs to the dialog and the panel only announces.
        onPlayerSelected: function(application) {
            const selected = application || ({})
            root.selectedStorageId = String(selected.storageId || "")
            root.playerSelected(application)
        }
        onMediaTextModeSelected: function(mode) {
            root.mediaTextModeSelected(String(mode))
        }
        onMediaDisplayModeSelected: function(mode) {
            root.mediaDisplayModeSelected(String(mode))
        }
        onOpenPlayerMinimizedSelected: function(enabled) {
            root.openPlayerMinimizedSelected(Boolean(enabled))
        }
        onAutoCollapseDelaySecondsSelected: function(seconds) {
            root.autoCollapseDelaySecondsSelected(Number(seconds))
        }
    }
}
// qmllint enable unqualified
