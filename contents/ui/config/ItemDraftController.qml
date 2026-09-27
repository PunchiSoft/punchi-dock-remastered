// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import "../../code/logic.js" as DockLogic
import "code/configItems.js" as ConfigItemsJS
import "code/itemTypeCatalog.js" as ItemTypeCatalog

// Draft of the element the «Add item» dialog is building.
//
// It owns the transactional contract of that dialog: the draft is created by
// `ConfigItemsJS.newItem()` and stays OUT of the dock item list until accept()
// runs, so cancelling cannot leave a provisional `New App`, `Folder` or any
// other item behind. The controller never writes `cfg_` values and never touches
// the item list: it only announces the finished element through
// `itemAccepted(var item)`, and whoever owns the list decides what to do with it.
QtObject {
    id: root

    // Dock item list the draft has to respect. It is read to reject a second
    // singleton and never written.
    property var items: []
    // Sound a new trash element ships with, injected by the page so this
    // component keeps no configuration of its own.
    property string defaultTrashEmptySound: ""

    // Type being drafted and the element itself. `draft` is null while the
    // dialog is closed.
    property string draftType: ""
    property var draft: null
    // Bumped whenever a new draft starts or the dialog closes. Asynchronous
    // answers (application search, folder load) carry the generation they were
    // asked in and are dropped when it no longer matches, so a late result can
    // never mutate a closed draft.
    property int generation: 0
    // True once the draft differs from the defaults `newItem()` produced.
    property bool draftEdited: false
    // Bumped whenever a value of the draft changes or a new draft starts. A QML
    // binding cannot follow the properties of a plain JavaScript object, so the
    // form announces every write through markEdited() and the validity below
    // reads this counter to be re-evaluated.
    property int draftRevision: 0
    // External pickers and discovery services return after the interaction that
    // started them. The controller owns their identity so a result can only reach
    // the draft generation and type that requested it.
    property int nextExternalRequestId: 0
    property var pendingExternalOperation: null

    // Keys of the missing data, empty when the draft can be added. The dialog
    // translates them, so this controller stays free of visible text.
    readonly property string invalidReason: {
        root.draftRevision
        const item = root.draft
        if (item === null) {
            return "no-draft"
        }
        if (!ItemTypeCatalog.isValidType(root.draftType)) {
            return "unknown-type"
        }
        if (String(root.draftType) === "app"
                && String(item.command || "").trim().length === 0) {
            return "app-command"
        }
        if (String(root.draftType) === "folder") {
            const source = String(item.sourceType || "manual")
            if (source === "folder"
                    && String(item.sourcePath || "").trim().length === 0) {
                return "folder-path"
            }
            if (source === "category"
                    && String(item.sourceCategory || "").trim().length === 0) {
                return "folder-category"
            }
        }
        return ""
    }
    readonly property bool draftValid: root.invalidReason.length === 0

    // Emitted only from accept(), with the finished element.
    signal itemAccepted(var item)
    signal cancelled()
    signal draftStarted()
    // The draft has data and the user asked for another type: the dialog asks
    // for confirmation and then calls confirmTypeChange().
    signal typeChangeConfirmationRequested(string type)

    function isSingletonType(type) {
        return DockLogic.singletonDockItemTypes.indexOf(String(type)) >= 0
    }

    function hasItemType(type) {
        const wanted = String(type)
        const list = root.items ? root.items : []
        for (let index = 0; index < list.length; index++) {
            const item = list[index]
            if (item && String(item.type) === wanted) {
                return true
            }
        }
        return false
    }

    // Availability for the selector: a singleton that is already in the dock
    // cannot be added again.
    function isTypeAvailable(type) {
        if (!ItemTypeCatalog.isValidType(type)) {
            return false
        }
        return !(root.isSingletonType(type) && root.hasItemType(type))
    }

    // Reason a disabled entry shows, empty when the type is available.
    function unavailableReason(type) {
        if (root.isTypeAvailable(type)) {
            return ""
        }
        const descriptor = ItemTypeCatalog.descriptorFor(type)
        return descriptor === null ? "" : descriptor.singletonReason
    }

    function availableTypeOrFirst(type) {
        if (root.isTypeAvailable(type)) {
            return String(type)
        }
        return ItemTypeCatalog.firstAvailableType(function(candidate) {
            return root.hasItemType(candidate)
        })
    }

    // Starts a draft. Returns its generation so the caller can pass it to the
    // asynchronous work it triggers.
    function startDraft(type) {
        root.clearExternalOperation()
        root.generation += 1
        root.draftType = String(type)
        root.draft = ConfigItemsJS.newItem(root.draftType,
            root.defaultTrashEmptySound)
        root.draftEdited = false
        root.draftRevision += 1
        root.draftStarted()
        return root.generation
    }

    function open(type) {
        return root.startDraft(root.availableTypeOrFirst(type))
    }

    // Asks for another type. Returns true when the draft was replaced, false
    // when the user still has to confirm discarding it.
    function requestType(type) {
        const wanted = String(type)
        if (wanted === root.draftType && root.draft !== null) {
            return true
        }
        if (root.draftEdited) {
            root.typeChangeConfirmationRequested(wanted)
            return false
        }
        root.startDraft(wanted)
        return true
    }

    function confirmTypeChange(type) {
        root.startDraft(type)
    }

    // The form calls this after writing any value into the draft: it marks the
    // draft as edited, so switching type asks for confirmation, and refreshes the
    // validity binding.
    function markEdited() {
        root.draftEdited = true
        root.draftRevision += 1
    }

    // Initial synchronization: the values the form shows when the draft starts
    // are the draft itself, not an edit, so the draft must not become "edited"
    // and a type change must not ask for confirmation yet.
    function refreshDraft() {
        root.draftRevision += 1
    }

    // Single write path for the form: it merges the fields the editor produced
    // into the draft, and the draft stays the only copy of the data.
    function setDraftValues(values) {
        if (root.draft === null || !values) {
            return
        }
        for (const name in values) {
            root.draft[name] = values[name]
        }
        root.markEdited()
    }

    // Removes a field the form cleared, so no stale value survives.
    function clearDraftValue(name) {
        if (root.draft === null) {
            return
        }
        delete root.draft[name]
        root.markEdited()
    }

    // Nested arrays (context actions, container applications) are written the
    // same way: the editor hands in its snapshot and the draft keeps the only
    // copy, so cancelling discards those changes too.
    function setDraftArray(name, values) {
        if (root.draft === null) {
            return
        }
        root.draft[name] = Array.isArray(values) ? values.slice() : []
        root.markEdited()
    }

    function draftArray(name) {
        const current = root.draft === null ? null : root.draft[name]
        return Array.isArray(current) ? current.slice() : []
    }

    // Nested arrays of the draft: the context actions of an application and the
    // applications of a container. Every operation reuses the functions of
    // `configItems.js`, which receive the dock list; the draft is passed as a
    // single-element list and the result is adopted back, so the rules stay in one
    // place and the draft stays the only copy of the data.
    readonly property bool draftNestedEditable: String(root.draftType) === "app"
        || String(root.draftType) === "folder"

    function nestedArrayName() {
        return String(root.draftType) === "folder" ? "apps" : "actions"
    }

    function nestedCount() {
        return root.draftArray(root.nestedArrayName()).length
    }

    // Adopts what a shared helper returned and reports the selection it proposes,
    // or the current one when the helper only returns the list.
    function adoptNestedResult(result, fallbackSelection) {
        if (root.draft === null || result === null || result === undefined) {
            return -1
        }
        const nextList = result.items ? result.items : result
        if (!Array.isArray(nextList) || nextList.length === 0) {
            return -1
        }
        root.draft = nextList[0]
        root.markEdited()
        if (result.items && result.selectedActionIndex !== undefined) {
            return Number(result.selectedActionIndex)
        }
        return Number(fallbackSelection)
    }

    function setActionsEnabled(enabled) {
        if (String(root.draftType) !== "app") {
            return
        }
        root.adoptNestedResult(
            ConfigItemsJS.setActionsEnabled([root.draft], 0, enabled), -1)
    }

    function addNestedEntry() {
        if (!root.draftNestedEditable) {
            return -1
        }
        return String(root.draftType) === "folder"
            ? root.adoptNestedResult(ConfigItemsJS.addContainerApp([root.draft], 0), 0)
            : root.adoptNestedResult(ConfigItemsJS.addAction([root.draft], 0), 0)
    }

    function removeNestedEntry(index) {
        if (!root.draftNestedEditable || index < 0) {
            return -1
        }
        return String(root.draftType) === "folder"
            ? root.adoptNestedResult(
                ConfigItemsJS.removeContainerApp([root.draft], 0, index), 0)
            : root.adoptNestedResult(
                ConfigItemsJS.removeAction([root.draft], 0, index), 0)
    }

    function moveNestedEntry(index, delta) {
        const target = index + Number(delta)
        if (!root.draftNestedEditable || index < 0
                || target < 0 || target >= root.nestedCount()) {
            return -1
        }
        return String(root.draftType) === "folder"
            ? root.adoptNestedResult(
                ConfigItemsJS.moveContainerApp([root.draft], 0, index, target), index)
            : root.adoptNestedResult(
                ConfigItemsJS.moveAction([root.draft], 0, index, target), index)
    }

    function applyNestedEntry(index, name, icon, command) {
        if (!root.draftNestedEditable || index < 0) {
            return -1
        }
        return String(root.draftType) === "folder"
            ? root.adoptNestedResult(ConfigItemsJS.applyContainerApp(
                [root.draft], 0, index, name, icon, command), index)
            : root.adoptNestedResult(ConfigItemsJS.applyAction(
                [root.draft], 0, index, name, icon, command), index)
    }

    function setActionPopupLimitRows(enabled, rows) {
        if (String(root.draftType) !== "app") {
            return
        }
        if (!enabled) {
            root.clearDraftValue("actionPopupMaxVisibleRows")
            return
        }
        const value = Math.max(1, Math.min(12, Math.round(Number(rows))))
        root.setDraftValues({"actionPopupMaxVisibleRows": value})
    }

    function beginExternalOperation(kind, target, details) {
        if (root.draft === null) {
            return -1
        }
        root.nextExternalRequestId += 1
        root.pendingExternalOperation = {
            "id": root.nextExternalRequestId,
            "kind": String(kind || ""),
            "target": String(target || ""),
            "generation": root.generation,
            "draftType": String(root.draftType),
            "details": details || {}
        }
        return root.nextExternalRequestId
    }

    function externalOperationMatches(kind, requestId) {
        const operation = root.pendingExternalOperation
        if (operation === null || root.draft === null) {
            return false
        }
        if (!root.isCurrent(Number(operation.generation))
                || String(operation.draftType) !== String(root.draftType)) {
            return false
        }
        if (String(kind || "").length > 0
                && String(operation.kind) !== String(kind)) {
            return false
        }
        return requestId === undefined || Number(requestId) <= 0
            || Number(operation.id) === Number(requestId)
    }

    function takeExternalOperation(kind, requestId) {
        if (!root.externalOperationMatches(kind, requestId)) {
            return null
        }
        const operation = root.pendingExternalOperation
        root.pendingExternalOperation = null
        return operation
    }

    function clearExternalOperation() {
        root.pendingExternalOperation = null
    }

    function applyDiscoveredApplication(generation, application) {
        if (!root.isCurrent(generation) || root.draft === null
                || String(root.draftType) !== "app") {
            return false
        }
        const selected = application || {}
        root.setDraftValues({
            "name": String(selected.name || ""),
            "description": String(selected.description || ""),
            "icon": String(selected.icon || "application-x-executable"),
            "command": String(selected.command || ""),
            "storageId": String(selected.storageId || ""),
            "appId": ConfigItemsJS.normalizedApplicationId(
                selected.appId || selected.storageId || "")
        })
        root.pruneDraft()
        return true
    }

    function applyContainerApplications(generation, applications, iconName) {
        if (!root.isCurrent(generation) || root.draft === null
                || String(root.draftType) !== "folder") {
            return false
        }
        const values = {
            "apps": Array.isArray(applications)
                ? ConfigItemsJS.clone(applications) : []
        }
        if (String(iconName || "").length > 0) {
            values.icon = String(iconName)
        }
        root.setDraftValues(values)
        root.pruneDraft()
        return true
    }

    function applyExternalValue(generation, expectedType, name, value) {
        if (!root.isCurrent(generation) || root.draft === null
                || (String(expectedType || "").length > 0
                    && String(root.draftType) !== String(expectedType))) {
            return false
        }
        const values = {}
        values[String(name)] = value
        root.setDraftValues(values)
        root.pruneDraft()
        return true
    }

    function applyExternalIcon(generation, target, nestedIndex, iconName) {
        if (!root.isCurrent(generation) || root.draft === null) {
            return -1
        }
        const requestedTarget = String(target)
        if (requestedTarget === "action") {
            const rows = root.draftArray(root.nestedArrayName())
            const index = Number(nestedIndex)
            if (!root.draftNestedEditable || index < 0 || index >= rows.length) {
                return -1
            }
            const row = rows[index]
            return root.applyNestedEntry(index, String(row.name || ""),
                String(iconName), String(row.command || ""))
        }
        const field = requestedTarget === "trashFull" ? "fullIcon" : "icon"
        return root.applyExternalValue(generation, "", field,
            String(iconName)) ? Number(nestedIndex) : -1
    }

    function addDroppedApplication(generation, application) {
        if (!root.isCurrent(generation) || root.draft === null
                || String(root.draftType) !== "folder") {
            return {"changed": false, "status": "invalid-target"}
        }
        const result = ConfigItemsJS.addApplicationToManualContainer(
            [root.draft], 0, application)
        if (result && result.changed === true) {
            root.draft = result.items[0]
            root.markEdited()
        }
        return result
    }

    // Applies the canonical shape of the type to the draft. The rules are the
    // same ones the existing action dialog uses, because they live in
    // `configItems.js`: nothing is re-implemented for this flow.
    function pruneDraft() {
        if (root.draft === null) {
            return
        }
        switch (String(root.draftType)) {
        case "app":
            ConfigItemsJS.pruneApp(root.draft)
            break
        case "folder":
            ConfigItemsJS.pruneFolder(root.draft)
            break
        case "note":
            ConfigItemsJS.pruneNote(root.draft)
            break
        case "separator":
            ConfigItemsJS.pruneSeparator(root.draft)
            break
        case "spacer":
            ConfigItemsJS.pruneSpacer(root.draft)
            break
        case "dynamic-applications":
            ConfigItemsJS.pruneDynamicApplications(root.draft)
            break
        case "media":
            ConfigItemsJS.pruneMedia(root.draft)
            break
        case "trash":
            ConfigItemsJS.pruneTrash(root.draft)
            break
        case "calendar":
            ConfigItemsJS.pruneCalendar(root.draft)
            break
        default:
            break
        }
        root.draftRevision += 1
    }

    function isCurrent(generation) {
        return generation === root.generation
    }

    // Cancelling leaves no trace: no item, no selection, no cfg_ value.
    function cancel() {
        root.clearExternalOperation()
        root.generation += 1
        root.draft = null
        root.draftType = ""
        root.draftEdited = false
        root.cancelled()
    }

    // Rejects a singleton that appeared behind the form, so the restriction is
    // validated here and not only by the visual state of the selector.
    function accept() {
        if (root.draft === null || !root.draftValid) {
            return false
        }
        if (!root.isTypeAvailable(root.draftType)) {
            return false
        }
        const finished = root.draft
        root.clearExternalOperation()
        root.generation += 1
        root.draft = null
        root.draftType = ""
        root.draftEdited = false
        root.itemAccepted(finished)
        return true
    }
}
