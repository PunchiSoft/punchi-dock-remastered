import QtQuick
import QtQuick.Controls as Controls
import ".."

// Thin wrapper of `TrashOptionsPanel`.
//
// The panel owns the layout, the controls and their texts; this dialog keeps only
// what makes it a dialog—title, modality and its close button—plus the public API it
// already had, so every existing caller and the form helpers that read it keep
// working. It resolves with the page controller the two values the panel shows as
// names and forwards what the panel announces; it writes nothing else.
//
// Translation helpers are supplied by the KCM context.
// qmllint disable unqualified
Controls.Dialog {
    id: root

    // Page the dialog reads its context from: the selected type gates the form and
    // the sounds are shown with the name its helper resolves. It is not handed to
    // the panel, which receives plain values and stays passive.
    property var controller

    property alias nameText: optionsPanel.nameText
    property alias emptyIconText: optionsPanel.emptyIconText
    property alias fullIconText: optionsPanel.fullIconText
    property alias showStateChecked: optionsPanel.showStateChecked
    property alias acceptDropsChecked: optionsPanel.acceptDropsChecked
    property alias soundPath: optionsPanel.soundPath

    signal formChanged()
    signal emptyIconPickerRequested()
    signal fullIconPickerRequested()
    signal soundPreviewRequested()
    signal soundResetRequested()
    signal soundPickerRequested()

    function hasController() {
        return root.controller !== undefined && root.controller !== null
    }

    function defaultSoundPath() {
        return root.hasController()
            ? String(root.controller.defaultTrashEmptySound || "") : ""
    }

    function resolvedSoundName(path) {
        return root.hasController()
            ? String(root.controller.fileName(path)) : String(path)
    }

    function selectedTypeIsTrash() {
        return root.hasController()
            && String(root.controller.selectedItemType) === "trash"
    }

    // A sound that was cleared falls back to the one a new element ships with, and
    // the same default is what the dialog starts with. The rule lives here because
    // this wrapper is the one that knows the default.
    onSoundPathChanged: {
        if (root.soundPath.length === 0 && root.defaultSoundPath().length > 0) {
            root.soundPath = root.defaultSoundPath()
        }
    }
    Component.onCompleted: {
        if (root.soundPath.length === 0) {
            root.soundPath = root.defaultSoundPath()
        }
    }

    modal: true
    title: i18n("Configure trash")
    standardButtons: Controls.Dialog.Close

    contentItem: TrashOptionsPanel {
        id: optionsPanel

        objectName: "trashOptionsPanel"

        editable: root.selectedTypeIsTrash()
        soundFileName: root.resolvedSoundName(root.soundPath)
        defaultSoundFileName: root.resolvedSoundName(root.defaultSoundPath())
        onFormChanged: root.formChanged()
        onEmptyIconPickerRequested: root.emptyIconPickerRequested()
        onFullIconPickerRequested: root.fullIconPickerRequested()
        onSoundPreviewRequested: root.soundPreviewRequested()
        onSoundResetRequested: root.soundResetRequested()
        onSoundPickerRequested: root.soundPickerRequested()
    }
}
// qmllint enable unqualified
