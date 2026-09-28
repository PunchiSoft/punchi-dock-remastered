#!/usr/bin/env python3

"""Contract for the first-install seeding of the shipped category containers.

The defaults ship category containers with their approved presentations. On a first
install its list must be filled from the installed launchers, and the result
must become an ordinary editable container so the user can change it freely
afterwards. A machine without that kind of application must keep the shipped
fallback list instead of an empty container.
"""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULTS = (ROOT / "contents/code/defaultItems.js").read_text(encoding="utf-8")
CONTROLLER = (ROOT / "contents/ui/components/DockItemsController.qml").read_text(
    encoding="utf-8"
)
LOGIC = (ROOT / "contents/code/logic.js").read_text(encoding="utf-8")
DISCOVERY_HEADER = (ROOT / "src/systemdiscovery.h").read_text(encoding="utf-8")
DISCOVERY_SOURCE = (ROOT / "src/systemdiscovery.cpp").read_text(encoding="utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


# The shipped Internet container demonstrates category discovery in the grid
# presentation and keeps a fallback list. The other requested presentations are
# locked here too, so a later seed change cannot silently homogenize them.
require(
    '"name": "Internet",\n'
    '        "icon": "folder-html",\n'
    '        "layout": "grid",\n'
    '        "sourceType": "category",\n'
    '        "sourceCategory": "Network",' in DEFAULTS,
    "The defaults must ship an Internet category container in the grid "
    "presentation.",
)
require(
    '"name": "Home",\n'
    '        "icon": "user-home",\n'
    '        "layout": "fan",' in DEFAULTS,
    "The shipped Home container must retain the fan presentation.",
)
require(
    '"name": "LibreOffice",\n'
    '        "icon": "folder-documents",\n'
    '        "layout": "detailed",' in DEFAULTS,
    "The shipped LibreOffice container must retain the detailed presentation.",
)
require(
    '"name": "Graphics",\n'
    '        "icon": "folder-pictures",\n'
    '        "layout": "list",\n'
    '        "sourceType": "category",\n'
    '        "sourceCategory": "Graphics",' in DEFAULTS,
    "The shipped Graphics container must retain the simple list presentation.",
)
require(
    '{ "type": "app", "name": "KMail", "icon": "kmail", "command": "kmail" }'
    in DEFAULTS,
    "The seeded container must keep a fallback list for machines without "
    "that category.",
)

# The seed is owned by the runtime controller and only runs while the stored
# configuration is still empty, which is what marks a first install. It resolves
# every container before the items are exposed, because replacing an already
# loaded list would rebuild the whole dock.
require(
    "const seed = root.seedCategoryItems(Logic.loadItems(raw), raw)"
    in CONTROLLER
    and "root.dockItems = seed.items" in CONTROLLER,
    "The first install must seed the containers before exposing the items.",
)
require(
    'if (String(storedJson || "").length > 0 || !root.systemDiscovery'
    in CONTROLLER,
    "The first-install seed must be gated on an empty stored configuration.",
)
require(
    "root.systemDiscovery.applicationsForCategory(" in CONTROLLER,
    "The seed must resolve the declared category through the discovery.",
)
require(
    "root.persistItems(root.dockItems)" in CONTROLLER,
    "The seeded result must be persisted through the shared write path.",
)
require(
    "function seedCategoryItems(items, storedJson) {" in CONTROLLER
    and "if (seed.changed) {" in CONTROLLER,
    "The seed must report whether it changed anything before persisting.",
)
require(
    "if (!(resolved instanceof Array) || resolved.length === 0) {"
    in CONTROLLER,
    "An empty discovery result must keep the shipped fallback list.",
)
require(
    'next.sourceType = "manual"' in CONTROLLER,
    "A seeded container must become editable after the seed.",
)
require(
    "next.layout" not in CONTROLLER,
    "The seed must not overwrite the presentation of the container.",
)
require(
    "applicationsForCategory(" in DISCOVERY_HEADER
    and "SystemDiscovery::applicationsForCategory" in DISCOVERY_SOURCE,
    "The discovery must expose a synchronous category query for the seed.",
)

# Without a stored configuration the runtime still falls back to the shipped
# defaults, which is the state the seed starts from.
require(
    "return DockDefaults.cloneItems();" in LOGIC,
    "The runtime must keep seeding from the shipped defaults.",
)

print("First-install category seed contracts are consistent")
