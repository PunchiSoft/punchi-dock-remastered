// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtTest
import "../contents/ui/config/components" as ConfigComponents

TestCase {
    id: testCase

    name: "ItemsConfigurationDraftController"
    property var controller: null

    Component {
        id: controllerComponent

        ConfigComponents.ItemsConfigurationDraftController {}
    }

    function init() {
        controller = createTemporaryObject(controllerComponent, testCase)
        verify(controller !== null)
    }

    function cleanup() {
        if (controller) {
            controller.destroy()
            controller = null
        }
    }

    function test_loadDoesNotRewriteInheritedItems() {
        const sourceItems = [
            {
                "type": "app",
                "name": "Legacy application",
                "icon": "legacy-icon",
                "futureProperty": {
                    "version": 7,
                    "enabled": true
                }
            },
            {
                "type": "punchimenu",
                "name": "PunchiMenu",
                "applicationLayout": {
                    "version": 1,
                    "nodes": []
                }
            }
        ]
        const raw = JSON.stringify(sourceItems)

        verify(controller.load(raw))
        compare(controller.count, 2)
        compare(controller.dirty, false)
        compare(controller.expectedRaw, raw)
        compare(controller.draftItems[0].futureProperty.version, 7)
        compare(controller.draftItems[0].futureProperty.enabled, true)
    }

    function test_addMoveAndRemovePreserveUnknownProperties() {
        const sourceItems = [
            {
                "type": "app",
                "name": "Existing",
                "unknown": "preserve-me"
            },
            {
                "type": "trash",
                "name": "Existing trash",
                "customTrashOption": 42
            }
        ]
        verify(controller.load(JSON.stringify(sourceItems)))

        verify(controller.addItem("separator", 1))
        compare(controller.count, 3)
        compare(controller.draftItems[0].unknown, "preserve-me")
        compare(controller.draftItems[2].customTrashOption, 42)
        compare(controller.dirty, true)

        verify(controller.moveItemToInsertion(2, 0))
        compare(controller.draftItems[0].customTrashOption, 42)
        compare(controller.draftItems[1].unknown, "preserve-me")

        verify(controller.removeItem(2))
        compare(controller.count, 2)
        compare(controller.draftItems[0].customTrashOption, 42)
        compare(controller.draftItems[1].unknown, "preserve-me")

        const committed = controller.serializedDraft()
        controller.confirmCommitted(committed)
        compare(controller.dirty, false)
        compare(controller.expectedRaw, committed)
    }

    function test_invalidInputIsRejectedWithoutDefaults() {
        verify(!controller.load("{not-json"))
        compare(controller.loaded, false)
        compare(controller.count, 0)
        compare(controller.dirty, false)
        compare(controller.errorCode, "invalid-json")
    }

    function test_dynamicApplicationsRemovalRemainsWithLegacyEditor() {
        verify(controller.load(JSON.stringify([
            {
                "type": "dynamic-applications",
                "name": "Open applications"
            },
            {
                "type": "separator"
            }
        ])))
        compare(controller.selectedIndex, 0)
        compare(controller.selectedItemRemovable, false)
        compare(controller.canRemoveItem(0), false)
        verify(!controller.removeItem(0))
        compare(controller.errorCode, "requires-legacy-editor")
        compare(controller.count, 2)
        compare(controller.dirty, false)
        compare(controller.canRemoveItem(1), true)

        controller.select(1)
        compare(controller.selectedItemRemovable, true)
        verify(controller.removeItem(1))
        compare(controller.count, 1)
        compare(controller.errorCode, "")
    }

    function test_removabilityBridgeFollowsReorderWithoutSelectionChange() {
        verify(controller.load(JSON.stringify([
            {
                "type": "app",
                "name": "Application"
            },
            {
                "type": "dynamic-applications",
                "name": "Open applications"
            }
        ])))
        controller.select(0)
        compare(controller.selectedItemRemovable, true)

        // The neighbour swap keeps the same selection index while the
        // selected object changes, so the bridge must re-evaluate anyway.
        verify(controller.moveItem(1, 0))
        compare(controller.selectedIndex, 0)
        compare(controller.selectedItem.type, "dynamic-applications")
        compare(controller.selectedItemRemovable, false)

        controller.select(controller.count)
        compare(controller.selectedItem, null)
        compare(controller.selectedItemRemovable, false)
    }

    function test_everySupportedTypeCanBeAdded() {
        verify(controller.load(JSON.stringify([])))
        compare(controller.count, 0)

        const expectedTypes = [
            "app", "folder", "punchimenu", "control-center", "media",
            "calendar", "note", "separator", "spacer", "trash"
        ]
        for (let index = 0; index < expectedTypes.length; index++) {
            const type = expectedTypes[index]
            verify(controller.addItem(type, controller.count))
            compare(controller.draftItems[controller.count - 1].type, type)
            compare(controller.errorCode, "")
        }
        compare(controller.count, expectedTypes.length)
        compare(controller.dirty, true)
    }

    function test_duplicateSingletonIsRefused() {
        verify(controller.load(JSON.stringify([
            {
                "type": "punchimenu",
                "name": "PunchiMenu"
            }
        ])))
        compare(controller.isSingletonType("punchimenu"), true)
        compare(controller.isSingletonType("app"), false)
        compare(controller.hasItemType("punchimenu"), true)

        verify(!controller.addItem("punchimenu", 1))
        compare(controller.errorCode, "duplicate-singleton-item")
        compare(controller.count, 1)
        compare(controller.dirty, false)

        // Non singleton types keep being added freely.
        verify(controller.addItem("app", 1))
        verify(controller.addItem("app", 2))
        compare(controller.count, 3)
    }

    function test_openApplicationsIsNotOfferedHere() {
        verify(controller.load(JSON.stringify([])))
        verify(!controller.addItem("dynamic-applications", 0))
        compare(controller.errorCode, "unsupported-item-type")
        compare(controller.count, 0)
    }

    function test_emptyLegacyValueLoadsDefaultsAsCleanDraft() {
        verify(controller.load(""))
        verify(controller.count > 0)
        compare(controller.expectedRaw, "")
        compare(controller.dirty, false)
    }
}
