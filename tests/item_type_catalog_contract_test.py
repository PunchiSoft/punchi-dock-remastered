#!/usr/bin/env python3
"""Contract of the canonical item type catalogue and of its consumers.

The catalogue is the single source for the type key, its icon, its visible text,
its singleton flag and the editor that renders its form. This contract keeps it
complete, keeps it aligned with the singleton list `logic.js` enforces, and
prevents the consumers from declaring a second type list of their own.
"""

from pathlib import Path
import re
import sys


PROJECT_ROOT = Path(__file__).resolve().parents[1]
CATALOG = (
    PROJECT_ROOT / "contents/ui/config/code/itemTypeCatalog.js"
).read_text()
LOGIC = (PROJECT_ROOT / "contents/code/logic.js").read_text()
SELECTOR = (PROJECT_ROOT / "contents/ui/config/ItemTypeSelector.qml").read_text()
DIALOG = (
    PROJECT_ROOT / "contents/ui/config/ItemConfigurationDialog.qml"
).read_text()
CONTROLLER = (
    PROJECT_ROOT / "contents/ui/config/ItemDraftController.qml"
).read_text()

# Order the user reads in the selector.
EXPECTED_TYPES = [
    "app",
    "folder",
    "note",
    "separator",
    "spacer",
    "punchimenu",
    "control-center",
    "dynamic-applications",
    "calendar",
    "media",
    "trash",
]

EDITOR_KEYS = {
    "item-form",
    "calendar-options",
    "punchimenu-options",
    "control-center-options",
    "media-options",
    "trash-options",
}

# A hardcoded catalogue entry in a consumer: the type key written next to the
# data of the entry. Reading `descriptor.type` is fine, writing the type key with
# its icon or title is the duplication this contract prevents.
HARDCODED_ENTRY_PATTERN = re.compile(
    r'"(?:type|icon|title|description)"\s*:\s*"'
    r'(?:' + "|".join(EXPECTED_TYPES) + r')"'
)


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def require(source: str, fragment: str, message: str) -> None:
    if fragment not in source:
        fail(message)


def entry_chunks(source: str) -> list[str]:
    """Return one chunk per catalogue entry, up to the end of its arguments."""

    chunks = []
    # The declaration of the helper is not an entry, so the split keeps the
    # opening quote of each call to stay able to read the type key first.
    for part in source.split('entry("')[1:]:
        chunks.append('"' + part.split("\n    ),")[0])
    return chunks


def main() -> int:
    chunks = entry_chunks(CATALOG)
    if len(chunks) != len(EXPECTED_TYPES):
        fail(
            f"The catalogue must describe exactly {len(EXPECTED_TYPES)} types, "
            f"found {len(chunks)}"
        )

    declared_types = []
    declared_singletons = []
    for chunk in chunks:
        match = re.search(r'"([a-z-]+)"', chunk)
        if match is None:
            fail("Every catalogue entry must start with its type key")
        entry_type = match.group(1)
        declared_types.append(entry_type)
        flags = re.findall(r"\n\s*(true|false),\s*", chunk)
        if len(flags) != 1:
            fail(f"The {entry_type} entry must declare its singleton flag once")
        if flags[0] == "true":
            declared_singletons.append(entry_type)
            require(
                chunk,
                'i18n("Only one',
                f"The {entry_type} entry must explain its singleton restriction",
            )
        else:
            require(
                chunk,
                'false, "",',
                f"The {entry_type} entry must declare an empty singleton reason",
            )

    if declared_types != EXPECTED_TYPES:
        fail(
            "The catalogue must expose the agreed types in order: "
            f"{declared_types}"
        )

    if not EDITOR_KEYS.issubset(
        set(
            re.findall(
                r'"(item-form|calendar-options|punchimenu-options'
                r'|control-center-options|media-options|trash-options)"',
                CATALOG,
            )
        )
    ):
        fail("Every catalogue entry must point at a known editor key")

    singleton_match = re.search(
        r"singletonDockItemTypes\s*=\s*\[([^\]]+)\]", LOGIC
    )
    if singleton_match is None:
        fail("logic.js must keep the canonical singleton list")
    canonical = re.findall(r'"([a-z-]+)"', singleton_match.group(1))
    if sorted(canonical) != sorted(declared_singletons):
        fail(
            "The catalogue singleton flags must match logic.js: "
            f"catalogue={sorted(declared_singletons)} logic={sorted(canonical)}"
        )

    # Translations are read through functions at use time, never frozen here.
    require(
        CATALOG,
        'i18n("Application")',
        "The catalogue must translate its titles when they are read",
    )
    for translated_text in ("Añadir", "Abrir", "Öffnen"):
        if translated_text in CATALOG:
            fail(
                "The catalogue must not carry text in a specific language: "
                f"found {translated_text}"
            )

    # The consumers read the catalogue instead of declaring a second list.
    for name, source in (("selector", SELECTOR), ("dialog", DIALOG)):
        require(
            source,
            'import "code/itemTypeCatalog.js" as ItemTypeCatalog',
            f"The {name} must read the canonical catalogue",
        )
    if re.search(HARDCODED_ENTRY_PATTERN, SELECTOR):
        fail("The selector must not declare its own list of types")
    if re.search(HARDCODED_ENTRY_PATTERN, DIALOG):
        fail("The dialog must not declare its own list of types")

    # The draft controller carries no visible text and no duplicate rule: it asks
    # logic.js and announces the finished element.
    require(
        CONTROLLER,
        'import "../../code/logic.js" as DockLogic',
        "The draft controller must read the canonical singleton list",
    )
    if "i18n(" in CONTROLLER:
        fail(
            "The draft controller must stay free of visible text: it reports "
            "reason keys and the dialog translates them"
        )
    require(
        CONTROLLER,
        "signal itemAccepted(var item)",
        "The controller must announce the finished element as an intention",
    )
    if re.search(r"\bcfg_\w+\s*=", CONTROLLER):
        fail("The draft controller must not write configuration on its own")

    print("Item type catalogue contracts are consistent")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
