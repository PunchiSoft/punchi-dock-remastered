#!/usr/bin/env python3
"""Static integration contract for the transactional Add item flow."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CONFIG = (ROOT / "contents/ui/config/ConfigItems.qml").read_text(encoding="utf-8")
VIEW = (ROOT / "contents/ui/config/ConfigItemsMainView.qml").read_text(encoding="utf-8")
DIALOG = (ROOT / "contents/ui/config/ItemConfigurationDialog.qml").read_text(encoding="utf-8")
CONTROLLER = (ROOT / "contents/ui/config/ItemDraftController.qml").read_text(encoding="utf-8")
DISCOVERY = (ROOT / "contents/ui/config/SystemDiscoveryManager.qml").read_text(encoding="utf-8")
WORKFLOW = (ROOT / "contents/ui/config/code/configItemsWorkflowHelper.js").read_text(encoding="utf-8")
CATALOG = (ROOT / "contents/ui/config/code/itemTypeCatalog.js").read_text(encoding="utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


require("AddItemPalette" not in VIEW and "function addItem(type)" not in WORKFLOW,
        "The immediate palette path must stay retired.")
require("function addItem(type)" not in CONFIG,
        "ConfigItems must not expose the immediate insertion wrapper.")
require('onAddItemRequested: page.openAddItemDialog()' in CONFIG,
        "The page button must reach the dialog owner.")
require("ItemDraftController {" in CONFIG and "ItemConfigurationDialog {" in CONFIG,
        "The page must own one draft controller and one dialog.")
require("function onItemAccepted(item)" in CONFIG
        and "page.acceptAddedItem(item)" in CONFIG
        and "nextItems.push(clone(item))" in CONFIG,
        "Only the accepted snapshot may enter the dock item list.")
require("ConfigItemsJS.itemAdditionImpact(item.type)" in CONFIG
        and "cfg_showActiveTasks = true" in CONFIG,
        "Addition side effects must run after the accepted item is committed.")

for signal in (
    "onApplicationSearchRequested",
    "onIconPickerRequested",
    "onFolderPickerRequested",
    "onContentLoadRequested",
    "onApplicationLauncherDropped",
    "onSoundPickerRequested",
    "onSoundPreviewRequested",
    "onColorPickerRequested",
    "onSurfaceClosed",
):
    require(signal in CONFIG, f"An Add item intention is not connected: {signal}")

require("pendingExternalOperation" in CONTROLLER
        and "generation" in CONTROLLER
        and "takeExternalOperation" in CONTROLLER
        and "clearExternalOperation" in CONTROLLER,
        "External answers must be owned and invalidated by the draft controller.")
require("requestId" in DISCOVERY
        and "folderEntriesDiscovered(var entries, int requestId)" in DISCOVERY
        and "queuedFolderRequestId" in DISCOVERY,
        "Folder discovery must preserve request identity even when serialized.")
require("requestId > 0" in CONFIG
        and 'takeExternalOperation(' in CONFIG
        and '"", requestId)' in CONFIG,
        "The page must discard stale identified responses instead of falling through to editing.")
require("The configuration of this type is not connected yet." not in DIALOG,
        "All catalogue types have editors; the provisional state must stay removed.")

for editor in (
    'editorItemForm = "item-form"',
    'editorCalendarOptions = "calendar-options"',
    'editorPunchiMenuOptions = "punchimenu-options"',
    'editorControlCenterOptions = "control-center-options"',
    'editorMediaOptions = "media-options"',
    'editorTrashOptions = "trash-options"',
):
    require(editor in CATALOG, f"A canonical editor key is missing: {editor}")

require("function finishAddItemDialog()" in CONFIG
        and "mainView.focusAddItemButton()" in CONFIG
        and "mainView.focusItemAtIndex(selectedIndex)" in CONFIG,
        "Closing must restore focus according to cancellation or acceptance.")

print("Transactional item addition page contract: PASS")
