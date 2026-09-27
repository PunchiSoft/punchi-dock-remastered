#!/usr/bin/env python3
"""Contract of the options panels extracted from their own dialog.

The panels are passive visual components: they receive the values they show
through their properties, announce the intentions of the user through their
signals and write nothing. The dialogs that host them stay thin wrappers with the
public API they already had, and neither of them keeps a second copy of the list
of modes, of its texts or of the rules that validate them.
"""

from pathlib import Path
import re
import sys


PROJECT_ROOT = Path(__file__).resolve().parents[1]
CONFIG_DIR = PROJECT_ROOT / "contents/ui/config"
COMPONENTS_DIR = CONFIG_DIR / "components"

PUNCHI_MENU_PANEL = (CONFIG_DIR / "PunchiMenuOptionsPanel.qml").read_text()
CONTROL_CENTER_PANEL = (
    CONFIG_DIR / "ControlCenterOptionsPanel.qml"
).read_text()
PUNCHI_MENU_DIALOG = (
    COMPONENTS_DIR / "PunchiMenuDialog.qml"
).read_text()
CONTROL_CENTER_DIALOG = (
    COMPONENTS_DIR / "ControlCenterDialog.qml"
).read_text()
CATALOG = (CONFIG_DIR / "code/itemTypeCatalog.js").read_text()
ADAPTER = (CONFIG_DIR / "code/draftFormAdapter.js").read_text()
DIALOG = (CONFIG_DIR / "ItemConfigurationDialog.qml").read_text()
CONFIG_ITEMS = (CONFIG_DIR / "code/configItems.js").read_text()
CONFIG_PAGE = (CONFIG_DIR / "ConfigItems.qml").read_text()

PUNCHI_MENU_KEY = "punchimenu-options"
CONTROL_CENTER_KEY = "control-center-options"

# Everything that turns a visual component into a dialog, and every write a
# passive panel must not do.
FORBIDDEN_IN_PANEL = (
    "Controls.Dialog",
    "standardButtons",
    "onOpened",
    "modal:",
    "function open(",
    "function close(",
    "draftController",
    "setDraftValues",
    "clearDraftValue",
    "dockItemsJson",
    "ConfigItems.",
    "cfg_",
    "ItemDraftController",
)


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def require(source: str, fragment: str, message: str) -> None:
    if fragment not in source:
        fail(message)


def forbid(source: str, fragment: str, message: str) -> None:
    if fragment in source:
        fail(message)


def main() -> int:
    # 1. The panels are passive: no dialog behaviour and no write path.
    for name, source in (
        ("PunchiMenuOptionsPanel.qml", PUNCHI_MENU_PANEL),
        ("ControlCenterOptionsPanel.qml", CONTROL_CENTER_PANEL),
    ):
        for fragment in FORBIDDEN_IN_PANEL:
            forbid(
                source,
                fragment,
                f"{name} must not contain the dialog or write marker: {fragment}",
            )
        require(
            source,
            "property bool compactLayout: false",
            f"{name} must expose the narrow layout variant and keep the row by "
            "default, so the existing dialog keeps its distribution",
        )
        require(
            source,
            "property real selectorWidth",
            f"{name} must keep the width the caller decides",
        )

    # 2. Each panel owns the list of modes, its texts and its contexts.
    require(
        PUNCHI_MENU_PANEL,
        'i18nc("@option:punchimenu-mode", "Full screen")',
        "The PunchiMenu panel must keep the mode text and its context",
    )
    require(
        PUNCHI_MENU_PANEL,
        'i18nc("@option:punchimenu-mode", "Normal")',
        "The PunchiMenu panel must keep the Normal mode and its context",
    )
    require(
        PUNCHI_MENU_PANEL,
        'i18nc("@option:punchimenu-mode", "Compact")',
        "The PunchiMenu panel must keep the Compact mode and its context",
    )
    require(
        PUNCHI_MENU_PANEL,
        'i18n("Menu mode:")',
        "The PunchiMenu panel must keep the label of the mode control",
    )
    require(
        PUNCHI_MENU_PANEL,
        'i18n("Icon:")',
        "The PunchiMenu panel must keep the label of the icon control",
    )
    require(
        PUNCHI_MENU_PANEL,
        'i18nc("@action:button", "Choose PunchiMenu icon")',
        "The PunchiMenu panel must keep the accessible name of the icon button",
    )
    require(
        PUNCHI_MENU_PANEL,
        'i18n("PunchiMenu display mode")',
        "The PunchiMenu panel must keep the accessible name of the mode control",
    )
    require(
        CONTROL_CENTER_PANEL,
        'i18nc("@label:listbox", "Display mode:")',
        "The Control Center panel must keep the label and its context",
    )
    require(
        CONTROL_CENTER_PANEL,
        'i18nc("@option:control-center-mode", "Full screen")',
        "The Control Center panel must keep the mode text and its context",
    )
    require(
        CONTROL_CENTER_PANEL,
        'i18nc("@option:control-center-mode", "Floating")',
        "The Control Center panel must keep the Floating mode and its context",
    )
    require(
        CONTROL_CENTER_PANEL,
        'i18nc("@info:accessibility",\n                "Control Center display mode")',
        "The Control Center panel must keep the accessible name of the mode control",
    )

    # 3. The list a panel shows and the list `configItems.js` accepts are the same
    # one; the normalization stays in the canonical module.
    punchi_menu_modes = re.findall(
        r'"value":\s*"([^"]+)"', PUNCHI_MENU_PANEL
    )
    if sorted(punchi_menu_modes) != ["compact", "fullScreen", "normal"]:
        fail(f"The PunchiMenu panel must list the three modes: {punchi_menu_modes}")
    control_center_modes = re.findall(
        r'"value":\s*"([^"]+)"', CONTROL_CENTER_PANEL
    )
    if sorted(control_center_modes) != ["floating", "fullScreen"]:
        fail(
            "The Control Center panel must list the two modes: "
            f"{control_center_modes}"
        )
    for marker in (
        'var availableModes = ["fullScreen", "normal", "compact"]',
        'var availableModes = ["fullScreen", "floating"]',
    ):
        require(
            CONFIG_ITEMS,
            marker,
            f"configItems.js must keep the canonical mode list: {marker}",
        )
    for marker in (
        "function normalizedPunchiMenuMode(value)",
        "function normalizedControlCenterMode(value)",
    ):
        forbid(
            PUNCHI_MENU_PANEL + CONTROL_CENTER_PANEL,
            marker,
            "A panel must not reimplement the canonical normalization",
        )

    # 4. The dialogs are thin wrappers with the public API they already had, and
    # they keep no copy of the list of modes or of its texts.
    for name, source, panel_type in (
        ("PunchiMenuDialog.qml", PUNCHI_MENU_DIALOG, "PunchiMenuOptionsPanel"),
        (
            "ControlCenterDialog.qml",
            CONTROL_CENTER_DIALOG,
            "ControlCenterOptionsPanel",
        ),
    ):
        require(
            source,
            f"contentItem: {panel_type} {{",
            f"{name} must host the extracted panel",
        )
        require(
            source,
            "readonly property alias modeOptions:",
            f"{name} must expose the list of modes of the panel",
        )
        require(
            source,
            "standardButtons: Controls.Dialog.Close",
            f"{name} must keep its dialog buttons",
        )
        require(
            source,
            "modal: true",
            f"{name} must keep its modality",
        )
        require(
            source,
            "onOpened: optionsPanel.synchronizeSelection()",
            f"{name} must synchronize the shown selection when it opens",
        )
        for fragment in (
            '"value":',
            '"Full screen"',
            '"Floating"',
            '"Menu mode:"',
            '"Display mode:"',
            '"Icon:"',
            'readonly property var modeOptions:',
            "Controls.ComboBox",
        ):
            forbid(
                source,
                fragment,
                f"{name} must not keep a second copy of the panel: {fragment}",
            )

    require(
        PUNCHI_MENU_DIALOG,
        "property string menuMode",
        "PunchiMenuDialog must keep its menuMode property",
    )
    require(
        PUNCHI_MENU_DIALOG,
        "property string iconName",
        "PunchiMenuDialog must keep its iconName property",
    )
    require(
        PUNCHI_MENU_DIALOG,
        "property real selectorWidth",
        "PunchiMenuDialog must keep its selectorWidth property",
    )
    require(
        PUNCHI_MENU_DIALOG,
        "signal menuModeSelected(string mode)",
        "PunchiMenuDialog must keep its intention signal",
    )
    require(
        PUNCHI_MENU_DIALOG,
        "signal iconPickerRequested()",
        "PunchiMenuDialog must keep its icon request signal",
    )
    require(
        PUNCHI_MENU_DIALOG,
        "return optionsPanel.modeIndex(mode)",
        "PunchiMenuDialog must answer through the panel, not with its own list",
    )
    require(
        PUNCHI_MENU_DIALOG,
        'title: i18n("Configure PunchiMenu")',
        "PunchiMenuDialog must keep its title",
    )
    require(
        PUNCHI_MENU_DIALOG,
        "root.menuModeSelected(root.menuMode)",
        "PunchiMenuDialog must forward the intention of the panel",
    )
    require(
        PUNCHI_MENU_DIALOG,
        "onIconPickerRequested: root.iconPickerRequested()",
        "PunchiMenuDialog must forward the request for an icon",
    )

    require(
        CONTROL_CENTER_DIALOG,
        'objectName: "controlCenterConfigDialog"',
        "ControlCenterDialog must keep the object name the page tracks",
    )
    require(
        CONTROL_CENTER_DIALOG,
        "property string controlCenterMode",
        "ControlCenterDialog must keep its controlCenterMode property",
    )
    require(
        CONTROL_CENTER_DIALOG,
        "signal controlCenterModeSelected(string mode)",
        "ControlCenterDialog must keep its intention signal",
    )
    require(
        CONTROL_CENTER_DIALOG,
        "function synchronizeModeSelection() {\n        optionsPanel."
        "synchronizeSelection()",
        "ControlCenterDialog must keep its synchronization helper",
    )
    require(
        CONTROL_CENTER_DIALOG,
        'title: i18nc("@title:window", "Configure Control Center")',
        "ControlCenterDialog must keep its title and its context",
    )
    require(
        CONTROL_CENTER_DIALOG,
        "root.controlCenterModeSelected(root.controlCenterMode)",
        "ControlCenterDialog must forward the intention of the panel",
    )
    require(
        CONTROL_CENTER_PANEL,
        'objectName: "controlCenterModeCombo"',
        "The mode control of the Control Center must keep its object name in the "
        "panel, which is where it lives now",
    )

    # 5. The catalogue names one specific key per extracted panel and neither of
    # them falls back to the pending editor.
    for marker in (
        f'const editorPunchiMenuOptions = "{PUNCHI_MENU_KEY}"',
        f'const editorControlCenterOptions = "{CONTROL_CENTER_KEY}"',
    ):
        require(CATALOG, marker, f"The catalogue must declare: {marker}")
    require(
        CATALOG,
        f"true, i18n(\"Only one PunchiMenu item can be added.\"),\n"
        f"            editorPunchiMenuOptions)",
        "The PunchiMenu entry must point at its options panel",
    )
    require(
        CATALOG,
        f"true, i18n(\"Only one Control Center item can be added.\"),\n"
        f"            editorControlCenterOptions)",
        "The Control Center entry must point at its options panel",
    )

    # 6. The add dialog maps the keys of the catalogue and writes through the
    # controller; it keeps no list of types and does not normalize anything.
    for marker in (f'"{PUNCHI_MENU_KEY}"', f'"{CONTROL_CENTER_KEY}"'):
        require(
            DIALOG,
            marker,
            f"ItemConfigurationDialog must map the catalogue key: {marker}",
        )
    require(
        DIALOG,
        "sourceComponent: root.optionsPanelVisible",
        "ItemConfigurationDialog must load the panel by its catalogue key",
    )
    require(
        DIALOG,
        'objectName: "itemConfigurationPunchiMenuPanel"',
        "ItemConfigurationDialog must host the PunchiMenu panel",
    )
    require(
        DIALOG,
        'objectName: "itemConfigurationControlCenterPanel"',
        "ItemConfigurationDialog must host the Control Center panel",
    )
    require(
        DIALOG,
        'root.draftController.setDraftValues({"menuMode": String(mode)})',
        "The mode of PunchiMenu must be written through the controller",
    )
    require(
        DIALOG,
        '"controlCenterMode": String(mode)',
        "The mode of the Control Center must be written through the controller",
    )
    require(
        DIALOG,
        'onIconPickerRequested: root.iconPickerRequested("punchimenu")',
        "The icon request must stay an announcement of the dialog",
    )
    forbid(
        DIALOG,
        "openIconPicker",
        "The add dialog must not open the icon picker yet",
    )
    if "normalizedPunchiMenuMode" in DIALOG or "activeFocusOnTab" in DIALOG:
        fail("The add dialog must not carry panel behaviour")

    # 7. The values the panels show are read through the shared adapter, which
    # reuses the canonical normalization instead of a second set of rules.
    for marker in (
        "function punchiMenuOptions(draft)",
        "function controlCenterOptions(draft)",
        "ConfigItemsJS.normalizedPunchiMenuMode(item.menuMode)",
        "ConfigItemsJS.normalizedControlCenterMode(",
    ):
        require(ADAPTER, marker, f"The adapter must keep: {marker}")

    # 8. The page that already used the dialogs keeps working without touching
    # its own wiring: both are still built the same way.
    for marker in (
        "PunchiMenuDialog {",
        "onMenuModeSelected: function(mode) { page.setPunchiMenuMode(mode) }",
        "ControlCenterDialog {",
        "onControlCenterModeSelected: function(mode) {",
        'page.openIconPicker("punchimenu")',
    ):
        require(
            CONFIG_PAGE,
            marker,
            f"ConfigItems.qml must keep its wiring: {marker}",
        )

    print("Options panel contracts are consistent")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
