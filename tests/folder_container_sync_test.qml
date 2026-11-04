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
    readonly property string approvedNote: "The folder updates on its own. "
        + "Loading it is not needed."
    readonly property string approvedBrowseNote: "Turn on Sync folder to open subfolders."
    readonly property string approvedUnavailableTitle: "Folder unavailable"
    readonly property string approvedUnavailableDetail: "Punchi Dock cannot read this folder. "
        + "Check that it still exists or pick another one in the container settings."
    readonly property string approvedNoSnapshotTitle: "No saved contents"
    readonly property string approvedNoSnapshotDetail: "Turn on live folder contents, "
        + "or load the folder contents in the container settings."
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
    function openListDraft() {
        dialog.openFor("folder")
        controller.setDraftValues({name: "Fixture", layout: "list",
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

    function test_helper_freezes_and_releases_the_container() {
        const items = [
            {type: "folder", sourceType: "folder", sourcePath: "/tmp", apps: []},
            {type: "folder", sourceType: "manual", sourcePath: "/tmp", apps: []}
        ]
        const frozen = Items.setFolderSyncFolder(items, 0, false)
        verify(frozen.changed)
        compare(frozen.status, "updated")
        compare(frozen.items[0].syncFolder, false)
        compare(items[0].syncFolder, undefined)

        const released = Items.setFolderSyncFolder(frozen.items, 0, true)
        verify(released.changed)
        compare(released.items[0].syncFolder, undefined)

        const unchanged = Items.setFolderSyncFolder(released.items, 0, true)
        verify(!unchanged.changed)
        compare(unchanged.status, "unchanged")

        const manual = Items.setFolderSyncFolder(items, 1, false)
        verify(!manual.changed)
        compare(manual.status, "invalid-target")

        const pathless = Items.setFolderSyncFolder(
            [{type: "folder", sourceType: "folder", sourcePath: "", apps: []}], 0, false)
        verify(!pathless.changed)
        compare(pathless.status, "invalid-target")
    }

    function test_helper_freezes_with_the_current_listing() {
        const items = [{type: "folder", sourceType: "folder",
            sourcePath: "/tmp", apps: testCase.storedSnapshot, layout: "grid"}]
        const entries = [{type: "app", name: "Fresh", icon: "folder",
            url: "file:///tmp/fresh"}]

        const frozen = Items.freezeFolderWithSnapshot(items, 0, entries)
        verify(frozen.changed)
        compare(frozen.status, "updated")
        compare(frozen.items[0].syncFolder, false)
        compare(frozen.items[0].layout, "grid")
        compare(frozen.items[0].apps.length, 1)
        compare(frozen.items[0].apps[0].name, "Fresh")
        // The source list stays untouched, and the snapshot is a copy.
        compare(items[0].apps[0].name, "Stored")
        frozen.items[0].apps[0].name = "Edited"
        compare(entries[0].name, "Fresh")

        const empty = Items.freezeFolderWithSnapshot(items, 0, [])
        verify(empty.changed)
        compare(empty.items[0].apps.length, 0)

        const manual = Items.freezeFolderWithSnapshot(
            [{type: "folder", sourceType: "manual", apps: []}], 0, entries)
        verify(!manual.changed)
        compare(manual.status, "invalid-target")
    }

    function test_helper_derives_the_container_name_from_the_folder() {
        compare(Items.folderNameFromPath("/home/u/Descargas/"), "Descargas")
        compare(Items.folderNameFromPath("file:///home/u/Mis%20Documentos"),
            "Mis Documentos")
        compare(Items.folderNameFromPath("/"), "")
        compare(Items.folderNameFromPath(""), "")

        // The default label and an empty name follow the chosen folder.
        compare(Items.containerNameForFolder("Folder", "", "/home/u/Descargas/"),
            "Descargas")
        compare(Items.containerNameForFolder("", "", "/home/u/Descargas/"),
            "Descargas")
        // A name that still matches the previous folder keeps following it.
        compare(Items.containerNameForFolder(
            "Descargas", "/home/u/Descargas/", "/home/u/Imagenes/"), "Imagenes")
        // A name written by hand is never replaced.
        compare(Items.containerNameForFolder(
            "Mi nombre", "/home/u/Descargas/", "/home/u/Imagenes/"), "Mi nombre")
        // A path without a usable name keeps the current one.
        compare(Items.containerNameForFolder("Descargas", "", "/"), "Descargas")
    }

    function test_folder_picker_adopts_the_folder_name() {
        dialog.openFor("folder")
        compare(controller.draft.name, "Folder")
        const generation = controller.generation

        verify(controller.applyContainerFolder(generation, "/home/user/Descargas/"))
        compare(controller.draft.sourcePath, "/home/user/Descargas/")
        compare(controller.draft.name, "Descargas")

        verify(controller.applyContainerFolder(generation, "/home/user/Imagenes/"))
        compare(controller.draft.name, "Imagenes")

        controller.setDraftValues({"name": "Mi carpeta"})
        verify(controller.applyContainerFolder(generation, "/home/user/Videos/"))
        compare(controller.draft.name, "Mi carpeta")
        compare(controller.draft.sourcePath, "/home/user/Videos/")
    }

    function test_helper_keeps_subfolder_browsing_independent() {        const items = [{type: "folder", sourceType: "folder",
            sourcePath: "/tmp", apps: []}]

        const enabled = Items.setFolderBrowseSubfolders(items, 0, true)
        verify(enabled.changed)
        compare(enabled.items[0].browseSubfolders, true)
        compare(enabled.items[0].syncFolder, undefined)
        compare(items[0].browseSubfolders, undefined)

        const disabled = Items.setFolderBrowseSubfolders(enabled.items, 0, false)
        verify(disabled.changed)
        compare(disabled.items[0].browseSubfolders, undefined)

        const unchanged = Items.setFolderBrowseSubfolders(disabled.items, 0, false)
        verify(!unchanged.changed)
        compare(unchanged.status, "unchanged")

        // Freezing the container never rewrites the subfolder preference.
        const frozen = Items.setFolderSyncFolder(enabled.items, 0, false)
        verify(frozen.changed)
        compare(frozen.items[0].syncFolder, false)
        compare(frozen.items[0].browseSubfolders, true)

        const manual = Items.setFolderBrowseSubfolders(
            [{type: "folder", sourceType: "manual", sourcePath: "/tmp", apps: []}],
            0, true)
        verify(!manual.changed)
        compare(manual.status, "invalid-target")
    }

    function test_browse_subfolders_note_explains_the_frozen_state() {
        const checkbox = openListDraft()
        const note = findChild(dialog, "containerBrowseSubfoldersNote")
        verify(note !== null)
        verify(!note.visible)

        checkbox.checked = false
        checkbox.toggled()
        verify(note.visible)
        compare(note.text, testCase.approvedBrowseNote)
    }

    function test_switches_follow_the_live_state() {
        const sync = openDraft()
        const browse = findChild(dialog, "containerBrowseSubfoldersCheckBox")
        const syncNote = findChild(dialog, "containerSyncFolderNote")
        verify(browse !== null)
        verify(syncNote !== null)
        // Following the folder enables entering subfolders and explains why the
        // load action is not needed.
        verify(sync.checked)
        compare(browse.enabled, true)
        verify(syncNote.visible)

        sync.checked = false
        sync.toggled()
        // Freezing leaves the subfolder switch visible but inert, and the note
        // about the live listing no longer applies.
        verify(browse.visible)
        compare(browse.enabled, false)
        verify(!syncNote.visible)
    }

    function test_stored_list_stays_out_of_sight_while_following_the_folder() {
        dialog.openFor("folder")
        controller.setDraftValues({name: "Fixture", layout: "grid",
            sourceType: "folder", sourcePath: testCase.fixture})
        dialog.refreshEditorFields(true)
        const editor = findChild(dialog, "itemConfigurationActionEditor")
        verify(editor !== null)
        // The live listing replaces the stored one, so its editor is hidden but
        // keeps being rebuilt: freezing the folder shows it at once.
        verify(!editor.visible)

        controller.setDraftValues({"syncFolder": false})
        dialog.refreshEditorFields(true)
        verify(editor.visible)
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

    function test_frozen_container_without_snapshot_explains_the_state() {
        popup.folderItem = testCase.folderItem({syncFolder: false, apps: []})
        popup.sessionActive = true
        compare(popup.liveContent, false)
        verify(popup.frozenWithoutSnapshot)
        verify(popup.contentStateActive)
        const panel = findChild(popup, "folderContentState")
        verify(panel !== null)
        verify(panel.visible)
        verify(!findChild(popup, "folderPopupGridView").visible)
        compare(findChild(popup, "folderContentStateTitle").text,
            testCase.approvedNoSnapshotTitle)
        compare(findChild(popup, "folderContentStateDetail").text,
            testCase.approvedNoSnapshotDetail)
    }

    function test_unavailable_folder_without_snapshot_explains_the_state() {
        popup.folderItem = testCase.folderItem({
            sourcePath: testCase.fixture + "/missing", apps: []})
        popup.sessionActive = true
        verify(popup.liveContent)
        tryVerify(function() { return popup.folderUnreadable })
        verify(popup.contentStateActive)
        verify(findChild(popup, "folderContentState").visible)
        compare(findChild(popup, "folderContentStateTitle").text,
            testCase.approvedUnavailableTitle)
        compare(findChild(popup, "folderContentStateDetail").text,
            testCase.approvedUnavailableDetail)
        // Opening a folder that cannot be read is not offered.
        compare(popup.gridItems.length, 0)
    }

    function test_unavailable_folder_keeps_the_stored_snapshot_on_screen() {
        popup.folderItem = testCase.folderItem({
            sourcePath: testCase.fixture + "/missing"})
        popup.sessionActive = true
        verify(popup.liveContent)
        tryVerify(function() { return popup.folderUnreadable })
        verify(!popup.contentStateActive)
        verify(!findChild(popup, "folderContentState").visible)
        compare(names(popup.apps), "Stored")
        // The stale snapshot stays visible, but opening the missing folder is
        // still not offered.
        compare(popup.gridItems.length, 1)
        compare(popup.gridItems[0]._punchiOpenLocationAction, undefined)
    }

    function test_frozen_container_with_snapshot_keeps_the_grid() {
        popup.folderItem = testCase.folderItem({syncFolder: false})
        popup.sessionActive = true
        verify(!popup.contentStateActive)
        verify(findChild(popup, "folderPopupGridView").visible)
        compare(names(popup.apps), "Stored")
    }
}
