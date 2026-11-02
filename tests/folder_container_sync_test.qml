// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtCore
import QtTest
import "../contents/ui/components" as Components
import "../contents/ui/config" as Config
import "../contents/ui/config/code/configItems.js" as Items

// A container bound to a folder must show that folder on every presentation,
// and must keep the snapshot stored in the configuration when the user freezes
// the container or when the folder cannot be listed.
TestCase {
    id: testCase
    name: "FolderContainerSync"
    when: windowShown
    visible: true
    width: 900
    height: 640

    readonly property string fixture: StandardPaths.writableLocation(
        StandardPaths.RuntimeLocation) + "/navigation"
    readonly property string approvedNote: "The container lists the folder as it is now, "
        + "so added or removed files appear without pressing Load content. If the folder "
        + "is unavailable, the container shows the contents loaded last."
    readonly property var storedSnapshot: [
        {type: "app", name: "Stored", icon: "folder", command: "stored"}
    ]

    Components.FolderPopup {
        id: popup
        animationStyle: "none"
        profileScale: 1
        maximumAvailableWidth: 800
        maximumAvailableHeight: 560
        layoutMode: "grid"
    }

    Config.ItemDraftController {
        id: controller
        items: []
    }
    Config.ItemConfigurationDialog {
        id: dialog
        draftController: controller
    }
    SignalSpy { id: acceptedSpy; target: controller; signalName: "itemAccepted" }

    function init() {
        failOnWarning(/.?/)
        popup.sessionActive = false
        popup.layoutMode = "grid"
    }
    function cleanup() {
        popup.sessionActive = false
        dialog.cancelDraft()
        controller.cancel()
        wait(0)
    }

    function settle(model) {
        tryCompare(model, "loading", false, 5000)
    }
    function names(apps) {
        const result = []
        for (let index = 0; index < apps.length; ++index) {
            result.push(String(apps[index].name || ""))
        }
        return result.join("|")
    }
    function folderItem(extra) {
        const item = {name: "Fixture", sourceType: "folder",
            sourcePath: testCase.fixture, apps: testCase.storedSnapshot}
        for (const key in extra) { item[key] = extra[key] }
        return item
    }
    function openDraft() {
        dialog.openFor("folder")
        controller.setDraftValues({name: "Fixture", layout: "grid",
            sourceType: "folder", sourcePath: testCase.fixture})
        dialog.refreshEditorFields(true)
        const checkbox = findChild(dialog, "containerSyncFolderCheckBox")
        tryVerify(function() { return checkbox !== null })
        return checkbox
    }

    function test_pruning_keeps_only_an_explicit_freeze() {
        const synced = {type: "folder", sourceType: "folder",
            sourcePath: "/tmp", apps: []}
        Items.pruneFolder(synced)
        compare(synced.syncFolder, undefined)

        const explicit = {type: "folder", sourceType: "folder",
            sourcePath: "/tmp", apps: [], syncFolder: true}
        Items.pruneFolder(explicit)
        compare(explicit.syncFolder, undefined)

        const frozen = {type: "folder", sourceType: "folder",
            sourcePath: "/tmp", apps: [], syncFolder: false}
        Items.pruneFolder(frozen)
        compare(frozen.syncFolder, false)
        compare(JSON.parse(JSON.stringify(frozen)).syncFolder, false)

        // A source without a folder cannot be frozen.
        const manual = {type: "folder", sourceType: "manual",
            sourcePath: "/tmp", apps: [], syncFolder: false}
        Items.pruneFolder(manual)
        compare(manual.syncFolder, undefined)
    }

    function test_option_defaults_to_sync_and_shows_the_approved_note() {
        const checkbox = openDraft()
        compare(checkbox.checked, true)
        verify(checkbox.visible)
        const note = findChild(dialog, "containerSyncFolderNote")
        verify(note !== null)
        verify(note.visible)
        compare(note.text, testCase.approvedNote)
    }

    function test_unchecking_the_option_freezes_the_container() {
        const checkbox = openDraft()
        checkbox.checked = false
        checkbox.toggled()
        compare(controller.draft.syncFolder, false)
        verify(controller.accept())
        compare(acceptedSpy.count, 1)
        compare(acceptedSpy.signalArguments[0][0].syncFolder, false)
    }

    function test_synced_container_lists_the_folder() {
        popup.folderItem = testCase.folderItem({})
        popup.sessionActive = true
        verify(popup.liveContent)
        settle(popup.navigationController.rootModel)
        tryVerify(function() { return popup.apps.length > 0 })
        verify(popup.directoryModel !== null)
        const listed = names(popup.apps)
        verify(listed.indexOf("document.txt") >= 0)
        verify(listed.indexOf("Stored") < 0)
        // Hidden entries stay out, as they do in the listing itself.
        verify(listed.indexOf(".hidden") < 0)
        // The rows are launchable without going through the configuration.
        verify(String(popup.apps[0].url || "").length > 0)
        compare(popup.apps[0].type, "app")
        compare(popup.itemCount, popup.apps.length)
        const grid = findChild(popup, "folderPopupGridView")
        tryCompare(grid, "count", popup.apps.length + 1)
    }

    function test_frozen_container_keeps_the_stored_snapshot() {
        popup.folderItem = testCase.folderItem({syncFolder: false})
        popup.sessionActive = true
        // Nothing is listed for a frozen container, so the snapshot is the only
        // source and must survive unchanged.
        compare(popup.liveContent, false)
        compare(popup.directoryModel, null)
        compare(names(popup.apps), "Stored")
        compare(popup.itemCount, 1)
    }

    function test_unavailable_folder_falls_back_to_the_stored_snapshot() {
        popup.folderItem = testCase.folderItem({
            sourcePath: testCase.fixture + "/missing"})
        popup.sessionActive = true
        compare(popup.liveContent, true)
        tryVerify(function() { return popup.directoryModel === null })
        tryVerify(function() { return names(popup.apps) === "Stored" })
        compare(popup.itemCount, 1)
    }
}
