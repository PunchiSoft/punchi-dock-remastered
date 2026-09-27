#!/usr/bin/env python3
"""Contract of the draft form: one type selector, one write path, shared rules.

The add dialog owns the type of the draft, so its form must not show a second
selector; the panel keeps its own selector for the existing action dialog, whose
public surface must not move. Every write of the new flow goes through the draft
controller, and the rules of each type stay in `configItems.js`.
"""

from pathlib import Path
import re
import sys


PROJECT_ROOT = Path(__file__).resolve().parents[1]
ACTION_DIALOG = (
    PROJECT_ROOT / "contents/ui/config/components/ActionDialog.qml"
).read_text()
PANEL = (PROJECT_ROOT / "contents/ui/config/ItemEditorPanel.qml").read_text()
DIALOG = (
    PROJECT_ROOT / "contents/ui/config/ItemConfigurationDialog.qml"
).read_text()
CONTROLLER = (
    PROJECT_ROOT / "contents/ui/config/ItemDraftController.qml"
).read_text()
ADAPTER = (
    PROJECT_ROOT / "contents/ui/config/code/draftFormAdapter.js"
).read_text()
CATALOG = (
    PROJECT_ROOT / "contents/ui/config/code/itemTypeCatalog.js"
).read_text()


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def require(source: str, fragment: str, message: str) -> None:
    if fragment not in source:
        fail(message)


def main() -> int:
    # 1. The existing action dialog is untouched: it keeps its own type selector.
    require(
        ACTION_DIALOG,
        "ItemEditorPanel {",
        "The action dialog must keep using the shared item form",
    )
    if "showTypeSelector" in ACTION_DIALOG:
        fail(
            "The action dialog must keep its own type selector: it must not ask "
            "the panel to hide it"
        )
    for fragment, message in (
        ("property alias appNameText: itemEditor.appNameText",
         "The action dialog must keep its public aliases"),
        ("property alias actionNameText: actionEditor.actionNameText",
         "The action dialog must keep its action aliases"),
        ("ItemActionEditor {",
         "The action dialog must keep hosting the action editor"),
    ):
        require(ACTION_DIALOG, fragment, message)

    # 2. The panel hides its selector only when the caller owns the type.
    require(
        PANEL,
        "property bool showTypeSelector: true",
        "The panel must keep its own selector by default",
    )
    require(
        PANEL,
        "visible: root.showTypeSelector",
        "The panel must be able to hide the type selector",
    )

    # 3. The add dialog owns the type: no second selector inside the form.
    require(
        DIALOG,
        'import "code/draftFormAdapter.js" as DraftFormAdapter',
        "The dialog must use the draft adapter",
    )
    require(
        DIALOG,
        "showTypeSelector: false",
        "The dialog must hide the selector of the panel",
    )
    require(
        DIALOG,
        'aliasPlaceholder: i18n("Type name or alias... then search")',
        "The add form must inject the translated application-search placeholder",
    )
    require(
        DIALOG,
        "root.synchronizeForm()",
        "An accepted type change must load the matching form immediately",
    )
    if re.search(r'"type"\s*:\s*"(app|folder|note|separator|spacer)"', DIALOG):
        fail("The dialog must not declare a second list of types")

    # 4. The view never writes the page: only the draft through the controller.
    for name, source in (("dialog", DIALOG), ("panel", PANEL)):
        if re.search(r"\bcfg_\w+\s*=", source):
            fail(f"The {name} must not write configuration on its own")
        if re.search(r"\bitems\s*=", source):
            fail(f"The {name} must not write the dock item list on its own")
    for fragment, message in (
        ("root.draftController.setDraftValues(",
         "The form must write through the controller"),
        ("DraftFormAdapter.fieldsFor(",
         "The form must read the fields through the adapter"),
    ):
        require(DIALOG, fragment, message)

    # 5. The controller keeps the single write path and the shared rules.
    for fragment, message in (
        ("function refreshDraft()",
         "The initial synchronization must not mark the draft as edited"),
        ("function setDraftValues(values)",
         "The controller must expose one write path for the form"),
        ("function setDraftArray(name, values)",
         "Nested arrays must be written through the controller"),
        ("function pruneDraft()",
         "The controller must normalize the draft with the shared rules"),
        ("ConfigItemsJS.pruneApp(root.draft)",
         "The rules of each type must stay in configItems.js"),
    ):
        require(CONTROLLER, fragment, message)
    if "root.draftEdited = true" not in CONTROLLER:
        fail("Editing the draft must mark it as edited")

    # 6. The adapter names fields only: the rules are not re-implemented.
    require(
        ADAPTER,
        '.import "configItems.js" as ConfigItemsJS',
        "The adapter must use the shared item rules",
    )
    if re.search(r"function\s+prune", ADAPTER):
        fail("The adapter must not re-implement the rules of the types")

    # 7. The separator is edited by the shared panel, not by a third editor.
    require(
        CATALOG,
        'false, "", editorItemForm),\n        entry("spacer"',
        "The separator must use the shared item form",
    )

    print("Draft form contracts are consistent")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
