import QtQuick
import QtTest
import "../contents/ui/config/code/configItems.js" as ConfigItems

TestCase {
    name: "ContainerLauncherDropLogic"

    function init() {
        failOnWarning(/.?/)
    }

    function launcher(overrides) {
        const result = {
            "name": "Writer",
            "icon": "libreoffice-writer",
            "command": "libreoffice --writer %U",
            "description": "Word processor",
            "storageId": "libreoffice-writer.desktop",
            "appId": "libreoffice-writer"
        }
        const source = overrides || {}
        const keys = Object.keys(source)
        for (let index = 0; index < keys.length; index++) {
            result[keys[index]] = source[keys[index]]
        }
        return result
    }

    function manualContainer(layout) {
        return {
            "type": "folder",
            "name": "Office",
            "icon": "folder-documents",
            "layout": layout,
            "sourceType": "manual",
            "apps": []
        }
    }

    function test_eachPresentationAcceptsTheSameManualContainerOperation() {
        const layouts = ["grid", "list", "detailed"]
        for (let index = 0; index < layouts.length; index++) {
            const original = [manualContainer(layouts[index])]
            const result = ConfigItems.addApplicationToManualContainer(
                original, 0, launcher())

            verify(result.changed)
            compare(result.status, "added")
            compare(original[0].apps.length, 0)
            compare(result.items[0].layout, layouts[index])
            compare(result.items[0].apps.length, 1)
            compare(result.items[0].apps[0].storageId,
                "libreoffice-writer.desktop")
            compare(result.items[0].apps[0].appId, "libreoffice-writer")
            compare(result.items[0].apps[0].name, "Writer")
            compare(result.items[0].apps[0].icon,
                "libreoffice-writer")
        }
    }

    function test_duplicateIdentityDoesNotMutateTheContainer() {
        const container = manualContainer("grid")
        container.apps = [launcher({
            "storageId": "LibreOffice-Writer.desktop",
            "appId": "LibreOffice-Writer"
        })]

        const result = ConfigItems.addApplicationToManualContainer(
            [container], 0, launcher())

        verify(!result.changed)
        compare(result.status, "duplicate")
        compare(result.items[0].apps.length, 1)
    }

    function test_managedContainerRejectsManualContent() {
        const container = manualContainer("list")
        container.sourceType = "category"

        const result = ConfigItems.addApplicationToManualContainer(
            [container], 0, launcher())

        verify(!result.changed)
        compare(result.status, "managed-container")
        compare(result.items[0].apps.length, 0)
    }

    function test_invalidLauncherAndStaleTargetAreRejected() {
        const invalidLauncher = ConfigItems.addApplicationToManualContainer(
            [manualContainer("detailed")], 0, { "name": "Missing ID" })
        verify(!invalidLauncher.changed)
        compare(invalidLauncher.status, "invalid-application")

        const invalidTarget = ConfigItems.addApplicationToManualContainer(
            [{ "type": "app", "name": "Writer" }], 0, launcher())
        verify(!invalidTarget.changed)
        compare(invalidTarget.status, "invalid-target")
    }

    function test_folderLayoutUpdateIsImmutableAndPresentationOnly() {
        const original = [manualContainer("grid")]
        original[0].apps = [launcher()]

        const result = ConfigItems.setFolderLayout(original, 0, "detailed")

        verify(result.changed)
        compare(result.status, "updated")
        compare(original[0].layout, "grid")
        compare(result.items[0].layout, "detailed")
        compare(result.items[0].apps.length, 1)
        compare(result.items[0].sourceType, "manual")
    }

    function test_folderLayoutUpdateRejectsInvalidInputsAndNoOp() {
        const original = [manualContainer("list")]
        const unchanged = ConfigItems.setFolderLayout(original, 0, "list")
        verify(!unchanged.changed)
        compare(unchanged.status, "unchanged")
        verify(unchanged.items === original)

        const invalidLayout = ConfigItems.setFolderLayout(
            original, 0, "radial")
        verify(!invalidLayout.changed)
        compare(invalidLayout.status, "invalid-layout")

        const invalidTarget = ConfigItems.setFolderLayout(
            [{ "type": "app" }], 0, "grid")
        verify(!invalidTarget.changed)
        compare(invalidTarget.status, "invalid-target")
    }
}
