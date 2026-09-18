// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

import "../code/configItems.js" as ConfigItemsJS
import "../code/items.js" as ItemsJS
import "../../../code/logic.js" as DockLogic

QtObject {
    id: root

    property string expectedRaw: ""
    property var originalItems: []
    property var draftItems: []
    property int selectedIndex: -1
    property bool loaded: false
    property string errorCode: ""
    // Element types this surface can add. Open applications stays out until
    // its legacy showActiveTasks transaction migrates.
    readonly property var supportedTypes: [
        "app",
        "folder",
        "punchimenu",
        "control-center",
        "media",
        "calendar",
        "note",
        "separator",
        "spacer",
        "trash"
    ]
    property string defaultTrashEmptySound:
        "/usr/share/sounds/ocean/stereo/trash-empty.oga"

    readonly property bool dirty: loaded
        && JSON.stringify(draftItems) !== JSON.stringify(originalItems)
    readonly property int count: draftItems.length
    readonly property var draftTypes: {
        const types = []
        const items = draftItems
        for (let index = 0; index < items.length; index++) {
            types.push(String(items[index].type || ""))
        }
        return types
    }
    readonly property var selectedItem: {
        const index = selectedIndex
        return index >= 0 && index < draftItems.length
            ? draftItems[index] : null
    }
    // Removing the open-applications element also clears the legacy
    // showActiveTasks preference, a transaction this phase does not migrate
    // yet. The runtime restores the marker while that preference stays
    // enabled, so removal continues in the existing Items editor.
    readonly property bool selectedItemRemovable: loaded
        && selectedItem !== null
        && String(selectedItem.type || "") !== "dynamic-applications"

    function clone(value) {
        return JSON.parse(JSON.stringify(value))
    }

    function parsedItems(raw) {
        const source = String(raw || "")
        const effective = source.trim().length > 0
            ? source : ItemsJS.defaultJson()
        try {
            return ConfigItemsJS.parseJsonArray(effective)
        } catch (error) {
            return {
                "ok": false,
                "items": [],
                "error": "invalid-json"
            }
        }
    }

    function load(raw) {
        const source = String(raw || "")
        const result = parsedItems(source)
        expectedRaw = source
        errorCode = result.ok ? "" : String(result.error || "invalid-json")
        loaded = result.ok
        originalItems = result.ok ? clone(result.items) : []
        draftItems = result.ok ? clone(result.items) : []
        selectedIndex = draftItems.length > 0 ? 0 : -1
        return result.ok
    }

    function serializedDraft() {
        return JSON.stringify(draftItems, null, 4)
    }

    function select(index) {
        const target = Number(index)
        selectedIndex = Number.isInteger(target)
                && target >= 0 && target < draftItems.length
            ? target : -1
    }

    function addItem(type, insertionIndex) {
        if (!loaded) {
            return false
        }
        if (draftItems.length >= DockLogic.maximumDockItemCount) {
            errorCode = "maximum-item-count"
            return false
        }
        const requestedType = String(type || "")
        if (supportedTypes.indexOf(requestedType) < 0) {
            errorCode = "unsupported-item-type"
            return false
        }
        if (isSingletonType(requestedType)
                && hasItemType(requestedType)) {
            errorCode = "duplicate-singleton-item"
            return false
        }

        const requestedIndex = Number(insertionIndex)
        const target = Number.isInteger(requestedIndex)
            ? Math.max(0, Math.min(requestedIndex, draftItems.length))
            : draftItems.length
        const nextItems = clone(draftItems)
        nextItems.splice(target, 0,
            ConfigItemsJS.newItem(requestedType, defaultTrashEmptySound))
        draftItems = nextItems
        selectedIndex = target
        errorCode = ""
        return true
    }

    function removeItem(index) {
        const target = Number(index)
        if (!loaded || !Number.isInteger(target)
                || target < 0 || target >= draftItems.length) {
            return false
        }
        if (!canRemoveItem(target)) {
            errorCode = "requires-legacy-editor"
            return false
        }
        const result = ConfigItemsJS.removeItem(draftItems, target)
        draftItems = result.items
        selectedIndex = result.selectedIndex
        errorCode = ""
        return true
    }

    function canRemoveItem(index) {
        const target = Number(index)
        if (!loaded || !Number.isInteger(target)
                || target < 0 || target >= draftItems.length) {
            return false
        }
        return String(draftItems[target].type || "")
            !== "dynamic-applications"
    }

    function isSingletonType(type) {
        return DockLogic.singletonDockItemTypes.indexOf(String(type || "")) >= 0
    }

    function hasItemType(type) {
        return draftTypes.indexOf(String(type || "")) >= 0
    }

    function moveItem(index, targetIndex) {
        const source = Number(index)
        const target = Number(targetIndex)
        if (!loaded || !Number.isInteger(source)
                || !Number.isInteger(target)
                || source < 0 || source >= draftItems.length
                || target < 0 || target >= draftItems.length
                || source === target) {
            return false
        }
        const result = ConfigItemsJS.moveItem(draftItems, source, target)
        draftItems = result.items
        selectedIndex = result.selectedIndex
        errorCode = ""
        return true
    }

    function moveItemToInsertion(index, insertionIndex) {
        const source = Number(index)
        const insertion = Number(insertionIndex)
        if (!Number.isInteger(source) || !Number.isInteger(insertion)
                || source < 0 || source >= draftItems.length) {
            return false
        }
        const boundedInsertion = Math.max(0,
            Math.min(insertion, draftItems.length))
        const target = boundedInsertion > source
            ? boundedInsertion - 1 : boundedInsertion
        if (target === source) {
            selectedIndex = source
            return false
        }
        return moveItem(source, target)
    }

    function confirmCommitted(raw) {
        expectedRaw = String(raw || serializedDraft())
        originalItems = clone(draftItems)
        errorCode = ""
    }
}
