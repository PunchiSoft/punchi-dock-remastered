// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import "../contents/ui/config" as Config
import "../contents/ui/config/code/configItems.js" as Items

TestCase {
    id: testCase
    name: "FolderNavigationConfiguration"
    when: windowShown
    Config.ItemDraftController { id: controller }
    Config.ItemConfigurationDialog { id: dialog; draftController: controller }
    SignalSpy { id: accepted; target: controller; signalName: "itemAccepted" }
    function init() { failOnWarning(/.?/); controller.cancel(); accepted.clear() }
    function cleanup() { dialog.cancelDraft(); wait(0) }
    function checkbox() { return findChild(dialog, "containerBrowseSubfoldersCheckBox") }
    function open(layout) {
        dialog.openFor("folder")
        controller.setDraftValues({name: "Fixture", layout: layout, sourceType: "folder", sourcePath: "/tmp"})
        dialog.refreshEditorFields(true)
        tryVerify(function() { return checkbox() !== null })
    }
    function test_default_opt_in_and_accept() {
        open("list")
        compare(checkbox().checked, false)
        verify(checkbox().visible)
        checkbox().checked = true
        checkbox().toggled()
        compare(controller.draft.browseSubfolders, true)
        verify(controller.accept())
        compare(accepted.count, 1)
        compare(accepted.signalArguments[0][0].browseSubfolders, true)
    }
    function test_cancel_and_style_preservation() {
        open("detailed")
        checkbox().checked = true
        checkbox().toggled()
        dialog.cancelDraft()
        compare(accepted.count, 0)
        compare(controller.draft, null)
        open("list")
        compare(checkbox().checked, false)
        checkbox().checked = true
        checkbox().toggled()
        controller.setDraftValues({layout: "grid"})
        dialog.refreshEditorFields(true)
        compare(checkbox().visible, false)
        compare(controller.draft.browseSubfolders, true)
        controller.setDraftValues({layout: "list"})
        dialog.refreshEditorFields(true)
        compare(checkbox().checked, true)
        verify(checkbox().visible)
    }
    function test_json_pruning_preserves_opt_in() {
        for (const layout of ["list", "detailed", "grid", "fan"]) {
            const descriptor = {type: "folder", sourceType: "folder", sourcePath: "/tmp", layout: layout, browseSubfolders: true, apps: []}
            Items.pruneFolder(descriptor)
            compare(descriptor.browseSubfolders, true)
            compare(JSON.parse(JSON.stringify(descriptor)).browseSubfolders, true)
        }
        const old = {type: "folder", apps: []}
        Items.pruneFolder(old)
        compare(old.browseSubfolders, undefined)
    }
}
