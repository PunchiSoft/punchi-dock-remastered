#!/usr/bin/env python3
"""Contract for the Items page after the transactional add flow replaced the palette."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MAIN_VIEW = (ROOT / "contents/ui/config/ConfigItemsMainView.qml").read_text(
    encoding="utf-8"
)
LIST_EDITOR = (ROOT / "contents/ui/config/DockItemListEditor.qml").read_text(
    encoding="utf-8"
)
RETIRED_PALETTE = ROOT / "contents/ui/config/AddItemPalette.qml"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def require_order(source: str, *fragments: str) -> None:
    positions = [source.find(fragment) for fragment in fragments]
    require(all(position >= 0 for position in positions), "A required page section is missing.")
    require(positions == sorted(positions), "The Items page sections are out of order.")


require(not RETIRED_PALETTE.exists(), "The retired AddItemPalette file must stay absent.")
for obsolete in (
    "AddItemPalette",
    "addItemPalette",
    'i18n("Items to add")',
    'icon.name: "go-previous-symbolic"',
    'icon.name: "go-next-symbolic"',
):
    require(obsolete not in MAIN_VIEW, f"Retired palette UI remains: {obsolete}")

for fragment in (
    'objectName: "addDockItemButton"',
    'text: i18nc("@action:button", "Add")',
    'icon.name: "list-add-symbolic"',
    "activeFocusOnTab: true",
    'Accessible.name: i18nc("@action:button", "Add item to Dock")',
    '"Open the item selector to choose what to add to the Dock."',
    "onClicked: root.addItemRequested()",
    "signal addItemRequested()",
):
    require(fragment in LIST_EDITOR, f"The list-owned add action is incomplete: {fragment}")

for fragment in (
    "signal addItemRequested()",
    "function focusAddItemButton()",
    "itemListEditor.focusAddItemButton()",
    "onAddItemRequested: root.addItemRequested()",
):
    require(fragment in MAIN_VIEW, f"The page add forwarding is incomplete: {fragment}")

require_order(
    MAIN_VIEW,
    "DockItemListEditor {",
    'objectName: "itemConfigurationReservedArea"',
    "Kirigami.InlineMessage {",
)

require('objectName: "addDockItemButton"' not in MAIN_VIEW,
        "The add button must not return to a page-wide standalone row.")

for fragment in (
    'objectName: "dockItemListEditor"',
    "Layout.fillWidth: true",
    "Layout.preferredWidth: Kirigami.Units.gridUnit * 20",
    "Layout.minimumWidth: Kirigami.Units.gridUnit * 16",
    "Layout.maximumWidth: Kirigami.Units.gridUnit * 20",
    'objectName: "itemConfigurationReservedArea"',
    "Layout.minimumWidth: Kirigami.Units.gridUnit * 12",
):
    require(fragment in MAIN_VIEW, f"The two-column body changed unexpectedly: {fragment}")

reserved_start = MAIN_VIEW.index('objectName: "itemConfigurationReservedArea"')
reserved_end = MAIN_VIEW.index("Kirigami.InlineMessage {", reserved_start)
reserved = MAIN_VIEW[reserved_start:reserved_end]
for forbidden in ("ItemEditorPanel", "ItemActionEditor", "controller", "cfg_", "i18n("):
    require(forbidden not in reserved, f"The reserved area must remain inert: {forbidden}")

require('Accessible.name: i18n("Items in Dock")' in LIST_EDITOR,
        "The list must retain its accessible name.")
require("function focusAtIndex(index)" in LIST_EDITOR,
        "The accepted item must expose a focus destination.")
require("itemList.forceActiveFocus()" in LIST_EDITOR,
        "Focusing the accepted item must be observable.")
require("Accessible.description: itemDelegate.subtitle" in LIST_EDITOR,
        "The hidden subtitle must remain accessible.")
require("text: itemDelegate.subtitle" not in LIST_EDITOR,
        "The item subtitle must not return as a visual column.")

print("Items page transactional layout contract satisfied.")
