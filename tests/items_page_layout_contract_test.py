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
ITEM_NOTES = (ROOT / "contents/ui/config/code/itemNotes.js").read_text(
    encoding="utf-8"
)
CONFIG_ITEMS = (ROOT / "contents/ui/config/ConfigItems.qml").read_text(
    encoding="utf-8"
)
CONFIG_ITEMS_CONTROLLER = (
    ROOT / "contents/ui/config/code/configItemsController.js"
).read_text(encoding="utf-8")
RETIRED_PALETTE = ROOT / "contents/ui/config/AddItemPalette.qml"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def require_order(source: str, *fragments: str) -> None:
    positions = [source.find(fragment) for fragment in fragments]
    require(all(position >= 0 for position in positions), "A required page section is missing.")
    require(positions == sorted(positions), "The Items page sections are out of order.")


require(not RETIRED_PALETTE.exists(), "The retired AddItemPalette file must stay absent.")

require(
    "ConfigItemsControllerJS.normalizedItemSelectionIndex(" in CONFIG_ITEMS,
    "Loading the item model must preserve the explicit no-selection state.",
)
require(
    "function normalizedItemSelectionIndex(selectedIndex, itemCount)"
    in CONFIG_ITEMS_CONTROLLER,
    "The item selection normalization contract is missing.",
)
require(
    "Math.max(selectedIndex, 0)" not in CONFIG_ITEMS,
    "Loading items must not coerce no selection to the first row.",
)
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

# The toolbar is one continuous row: the two actions that build or edit the
# selection first, then the three that reorder or remove it, all of them with the
# same spacing and with no filler standing between them, so the width left over
# stays at the end of the row instead of opening a hole in the middle.
toolbar_start = LIST_EDITOR.index(
    "// The item actions sit in the first row of the frame"
)
toolbar = LIST_EDITOR[toolbar_start:LIST_EDITOR.index("ListView {", toolbar_start)]
toolbar_order = [
    'objectName: "addDockItemButton"',
    'text: i18n("Configure")',
    'icon.name: "go-up-symbolic"',
    'icon.name: "go-down-symbolic"',
    'icon.name: "edit-delete-symbolic"',
]
toolbar_positions = [toolbar.find(fragment) for fragment in toolbar_order]
require(
    all(position >= 0 for position in toolbar_positions),
    "The item toolbar is missing one of its five actions.",
)
require(
    toolbar_positions == sorted(toolbar_positions),
    "The item toolbar must order Add, Configure, Up, Down and Delete.",
)
require(
    "Item {" not in toolbar,
    "The item toolbar must stay one continuous row, with no filler between its buttons.",
)

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
    "Layout.preferredWidth: Kirigami.Units.gridUnit * 16",
    "Layout.minimumWidth: Kirigami.Units.gridUnit * 16",
    "Layout.maximumWidth: Kirigami.Units.gridUnit * 16",
    'objectName: "itemConfigurationReservedArea"',
    "Layout.minimumWidth: Kirigami.Units.gridUnit * 12",
):
    require(fragment in MAIN_VIEW, f"The two-column body changed unexpectedly: {fragment}")

reserved_start = MAIN_VIEW.index('objectName: "itemConfigurationReservedArea"')
reserved_end = MAIN_VIEW.index("Kirigami.InlineMessage {", reserved_start)
reserved = MAIN_VIEW[reserved_start:reserved_end]

# The right column is no longer empty: it shows the note of the selected type. It
# must stay a note, so no editor panel and no configuration write live here, and its
# text belongs to the note catalogue instead of being written into the view. Only the
# short label of a note is bold, so the view declares styled text and the whole
# sentence must never be bolded.
for forbidden in ("ItemEditorPanel", "ItemActionEditor", "cfg_", "i18n(",
                  "font.bold: true"):
    require(forbidden not in reserved,
            f"The right column must stay a note area: {forbidden}")
for fragment in (
    'objectName: "itemTypeNote"',
    "ItemNotes.noteFor(root.selectedNoteType)",
    "textFormat: Text.StyledText",
    "Accessible.name: ItemNotes.plainText(text)",
    "wrapMode: Text.WordWrap",
    "Layout.maximumWidth: Kirigami.Units.gridUnit * 40",
):
    require(fragment in reserved, f"The selected-type note is incomplete: {fragment}")

# The note must follow the selected row directly. The editor's cached type can lag
# behind while the selection changes, which used to show the Application note for
# PunchiMenu.
for fragment in (
    "readonly property string selectedNoteType:",
    "const index = Number(controller.selectedIndex)",
    "const sourceItems = controller.items",
    "const selectedItem = sourceItems[index]",
    'String(selectedItem.type || "app")',
):
    require(fragment in MAIN_VIEW,
            f"The selected-type note must follow the selected item: {fragment}")

for fragment in (
    "function plainText(markup)",
    "function noteFor(type)",
    'case "app":',
    'case "folder":',
    'case "dynamic-applications":',
    'case "punchimenu":',
    'case "control-center":',
    'case "calendar":',
    'case "trash":',
    'case "media":',
    'case "note":',
    'case "separator":',
    'case "spacer":',
    "i18nc(",
    "<b>Note:</b>",
):
    require(fragment in ITEM_NOTES, f"The note catalogue is incomplete: {fragment}")

require('Accessible.name: i18n("Items in Dock")' in LIST_EDITOR,
        "The list must retain its accessible name.")
for fragment in (
    'objectName: "dockItemList"',
    "Keys.onPressed: function(event)",
    "event.key === Qt.Key_Down",
    "event.key === Qt.Key_Up",
    "root.controller.selectItem(nextIndex)",
    "root.controller.selectItem(previousIndex)",
):
    require(fragment in LIST_EDITOR,
            f"The unselected list must remain keyboard-operable: {fragment}")
require("function focusAtIndex(index)" in LIST_EDITOR,
        "The accepted item must expose a focus destination.")
require("itemList.forceActiveFocus()" in LIST_EDITOR,
        "Focusing the accepted item must be observable.")
require("Accessible.description: itemDelegate.subtitle" in LIST_EDITOR,
        "The hidden subtitle must remain accessible.")
require("text: itemDelegate.subtitle" not in LIST_EDITOR,
        "The item subtitle must not return as a visual column.")

print("Items page transactional layout contract satisfied.")
