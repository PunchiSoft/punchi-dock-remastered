#!/usr/bin/env python3

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EDITOR = (ROOT / "contents/ui/config/ItemActionEditor.qml").read_text()
DIALOG = (
    ROOT / "contents/ui/config/components/ActionDialog.qml"
).read_text()
CONFIG_ITEMS = (ROOT / "contents/ui/config/ConfigItems.qml").read_text()
DISCOVERY = (
    ROOT / "contents/ui/config/SystemDiscoveryManager.qml"
).read_text()
WORKFLOW = (
    ROOT / "contents/ui/config/code/configItemsWorkflowHelper.js"
).read_text()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


require(
    "DropArea {" in EDITOR
    and 'objectName: "containerApplicationDropArea"' in EDITOR
    and "validateApplicationLauncherUrls(" in EDITOR
    and "applicationLauncherDropped(var urls)" in EDITOR,
    "The container editor must expose a validated launcher drop target.",
)
require(
    "applicationLauncherDropEnabled" in DIALOG
    and 'root.containerSourceValue === "manual"' in DIALOG
    and "onApplicationLauncherDropped" in DIALOG,
    "Only manual container dialogs may forward launcher drops.",
)
require(
    "function validateApplicationLauncherDrop(urls)" in DISCOVERY
    and "systemDiscovery.validateApplicationLauncherDrop(urls || [])"
    in DISCOVERY,
    "The KCM must reuse the native launcher resolver instead of trusting MIME names.",
)
require(
    "function addApplicationLauncherToSelectedContainer(" in WORKFLOW
    and "ConfigItemsJS.addApplicationToManualContainer(" in WORKFLOW
    and "refreshFromItems()" in WORKFLOW,
    "A validated launcher must use the duplicate-safe immutable mutation and refresh the KCM model.",
)
require(
    "applicationLauncherDropValidator:" in CONFIG_ITEMS
    and "page.validateApplicationLauncherDrop" in CONFIG_ITEMS
    and "onApplicationLauncherDropped" in CONFIG_ITEMS
    and "page.addApplicationLauncherToSelectedContainer(urls)" in CONFIG_ITEMS,
    "ConfigItems must wire validation, drop intent, mutation, and feedback end to end.",
)
require(
    'objectName: "addActionButton"' in EDITOR
    and "Accessible.name:" in EDITOR
    and "Controls.ToolTip.text: Accessible.name" in EDITOR,
    "The existing add button must remain a named keyboard-accessible alternative to drag and drop.",
)

print("Container editor launcher drop contract: PASS")
