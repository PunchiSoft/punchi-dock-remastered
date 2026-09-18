#!/usr/bin/env python3

from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]
CONFIG_MODEL = (ROOT / "contents/config/config.qml").read_text(encoding="utf-8")
DEVELOPMENT_PAGE = (
    ROOT / "contents/ui/config/ConfigDevelopment.qml"
).read_text(encoding="utf-8")
CONFIGURATION_WINDOW = (
    ROOT / "contents/ui/config/components/ItemsConfigurationWindow.qml"
).read_text(encoding="utf-8")
CONFIGURATION_WORKSPACE = (
    ROOT / "contents/ui/config/components/ItemsConfigurationWorkspace.qml"
).read_text(encoding="utf-8")
CONFIGURATION_CONTROLLER = (
    ROOT / "contents/ui/config/components/ItemsConfigurationDraftController.qml"
).read_text(encoding="utf-8")
CONFIGURATION_CATALOG = (
    ROOT / "contents/ui/config/components/ItemsConfigurationCatalog.qml"
).read_text(encoding="utf-8")
CONFIGURATION_TILE = (
    ROOT / "contents/ui/config/components/ItemsConfigurationCatalogTile.qml"
).read_text(encoding="utf-8")
PANEL_REVEAL_ADAPTER = (
    ROOT / "src" / "panelrevealadapter.cpp"
).read_text(encoding="utf-8")
QML_TYPES = (
    ROOT / "contents/ui/org/punchi/dock/punchidockintegration.qmltypes"
).read_text(encoding="utf-8")
PANEL_REVEAL_DESTRUCTOR = PANEL_REVEAL_ADAPTER.split(
    "PanelRevealAdapter::~PanelRevealAdapter()", 1)[-1].split(
    "QObject *PanelRevealAdapter::applet()", 1)[0]
CONFIGURATION_UI = CONFIGURATION_WINDOW + "\n" + CONFIGURATION_WORKSPACE
CONTROLLER_REMOVAL_GUARD = CONFIGURATION_CONTROLLER.split(
    "function canRemoveItem", 1)[-1].split("function moveItem", 1)[0]
CONTROLLER_SUPPORTED_TYPES = CONFIGURATION_CONTROLLER.split(
    "readonly property var supportedTypes: [", 1)[-1].split("]", 1)[0]


def require(condition: bool, message: str) -> None:
    if not condition:
        print(message, file=sys.stderr)
        raise SystemExit(1)


require(
    'name: i18n("Development")' in CONFIG_MODEL
    and 'source: "config/ConfigDevelopment.qml"' in CONFIG_MODEL,
    "The Development configuration category is not registered.",
)
require(
    CONFIG_MODEL.index('source: "config/ConfigDevelopment.qml"')
    > CONFIG_MODEL.index('source: "config/ConfigAdditionalShortcuts.qml"'),
    "Development must remain the final Punchi Dock category before shell pages.",
)
require(
    'objectName: "configureItemsButton"' in DEVELOPMENT_PAGE
    and 'text: i18nc("@action:button", "Configure items")'
    in DEVELOPMENT_PAGE
    and "itemsConfigurationWindow.openWithReveal()" in DEVELOPMENT_PAGE,
    "The Development page must expose the single items configuration entry.",
)
require(
    "onConcealed: {" in DEVELOPMENT_PAGE
    and "configureItemsButton.forceActiveFocus(" in DEVELOPMENT_PAGE,
    "Closing the floating window must restore focus to its launcher.",
)
require(
    "Punchi.PanelRevealAdapter" in DEVELOPMENT_PAGE
    and "panelRevealAdapter.beginReveal()" in DEVELOPMENT_PAGE
    and "panelRevealAdapter.endReveal()" in DEVELOPMENT_PAGE,
    "The Development page must reveal the dock panel while its items are edited.",
)
require(
    "Plasma::Types::NeedsAttentionStatus" in PANEL_REVEAL_ADAPTER
    and "containment->setStatus(" in PANEL_REVEAL_ADAPTER
    and "m_previousStatus" in PANEL_REVEAL_ADAPTER
    and "m_statusChangedByAdapter" in PANEL_REVEAL_ADAPTER,
    "The reveal must use a temporary attention status and restore ownership safely.",
)
require(
    "setUserConfiguring" not in PANEL_REVEAL_ADAPTER
    and "setTransientParent" not in PANEL_REVEAL_ADAPTER,
    "Revealing the dock must not enter panel edit mode or reparent the dialog.",
)
require(
    'name: "dialogWindow"' not in QML_TYPES,
    "The published QML metadata must not retain the removed dialogWindow API.",
)
require(
    'window->property("visibilityMode").isValid()' in PANEL_REVEAL_ADAPTER,
    "Only the window of a panel may be revealed.",
)
require(
    "endReveal();" in PANEL_REVEAL_DESTRUCTOR,
    "Destroying the reveal adapter must release the panel state.",
)
require(
    'property string cfg_dockItemsJson: ""' in DEVELOPMENT_PAGE
    and "Punchi.DockItemsPersistenceAdapter" in DEVELOPMENT_PAGE
    and "commitDockItemsJson(" in DEVELOPMENT_PAGE
    and "page.cfg_dockItemsJson = committed" in DEVELOPMENT_PAGE,
    "The new editor must commit through the existing dockItemsJson transaction.",
)

for marker in (
    "PlasmaCore.Dialog {",
    "location: PlasmaCore.Types.Floating",
    "type: PlasmaCore.Dialog.Normal",
    "backgroundHints: PlasmaCore.Dialog.NoBackground",
    'title: i18nc("@title:window", "Punchi Dock Items Configuration")',
    'imagePath: "solid/dialogs/background"',
    "opacity: 1.0",
    "function openWithReveal()",
    "function closeWithFade()",
    "function requestCommit(closeAfterCommit)",
    "function confirmCommit(committedRaw, closeAfterCommit)",
    "ItemsConfigurationDraftController",
    'objectName: "itemsConfigurationCatalog"',
    'objectName: "itemsConfigurationDockPreview"',
    'objectName: "itemsConfigurationApplyButton"',
    'objectName: "itemsConfigurationAcceptButton"',
    "Timer {",
    "Keys.onEscapePressed",
):
    require(marker in CONFIGURATION_UI, f"Missing window contract: {marker}")

require(
    "BlurBehindController" not in CONFIGURATION_WINDOW
    and "blurEnabled" not in CONFIGURATION_WINDOW,
    "The initial items configuration window must not request blur.",
)

require(
    "ConfigItems.qml" not in CONFIGURATION_UI
    and "ConfigItems.qml" not in DEVELOPMENT_PAGE,
    "The new editor must not embed or replace the legacy Items page.",
)

# Open applications also own the legacy showActiveTasks preference, which the
# runtime reads to restore its marker. Until that transaction migrates, the new
# editor keeps the element but leaves its removal to the Items page.
require(
    'readonly property bool selectedItemRemovable:'
    in CONFIGURATION_CONTROLLER
    and '"dynamic-applications"' in CONTROLLER_REMOVAL_GUARD,
    "Open applications removal must stay blocked in the new editor.",
)
require(
    'errorCode = "requires-legacy-editor"' in CONFIGURATION_CONTROLLER
    and 'code === "requires-legacy-editor"' in CONFIGURATION_WINDOW,
    "A blocked removal must report and explain requires-legacy-editor.",
)
require(
    '"type": "dynamic-applications"' not in CONFIGURATION_UI,
    "The initial catalog must not offer the open applications element.",
)
require(
    "draftController.selectedItemRemovable" in CONFIGURATION_WINDOW
    and "root.selectedItemRemovable" in CONFIGURATION_WORKSPACE
    and 'objectName: "itemsConfigurationRemoveButton"'
    in CONFIGURATION_WORKSPACE,
    "Removal must stay gated through the reactive removability bridge.",
)

# Catalog contract: every supported element type is offered once and the
# open-applications element stays outside this surface.
for item_type in (
    "app",
    "folder",
    "punchimenu",
    "control-center",
    "media",
    "calendar",
    "note",
    "separator",
    "spacer",
    "trash",
):
    require(
        f'"type": "{item_type}"' in CONFIGURATION_CATALOG,
        f"The catalog is missing {item_type}.",
    )
    require(
        f'"{item_type}"' in CONTROLLER_SUPPORTED_TYPES,
        f"The draft controller does not accept {item_type}.",
    )
require(
    'ItemsConfigurationCatalog' in CONFIGURATION_WINDOW
    and "catalogSource.entries" in CONFIGURATION_WINDOW,
    "The window must consume the shared element catalog.",
)
require(
    '"type": "dynamic-applications"' not in CONFIGURATION_CATALOG
    and '"dynamic-applications"' not in CONTROLLER_SUPPORTED_TYPES,
    "Open applications must stay outside this surface for now.",
)
require(
    CONFIGURATION_CATALOG.count('"singleton": true') == 3,
    "Only the three single-instance elements may be marked as singletons.",
)
require(
    'errorCode = "duplicate-singleton-item"' in CONFIGURATION_CONTROLLER
    and 'code === "duplicate-singleton-item"' in CONFIGURATION_WINDOW,
    "A duplicate singleton must be refused and explained.",
)
require(
    'modelData.singleton === true' in CONFIGURATION_WORKSPACE
    and "root.presentTypes.indexOf" in CONFIGURATION_WORKSPACE
    and "enabled: root.loaded && !entryUnavailable"
    in CONFIGURATION_WORKSPACE,
    "Catalog tiles must gate single-instance elements already on the dock.",
)

# Geometry contract: the surface grows with its own content, keeps a theme
# derived inner margin and never clips a catalog row.
require(
    "readonly property real contentMargin:" in CONFIGURATION_WINDOW
    and "+ root.contentMargin" in CONFIGURATION_WINDOW,
    "The surface must keep a theme-derived margin around the frame content.",
)
require(
    "configurationSurface.contentImplicitHeight" in CONFIGURATION_WINDOW
    and "maximumContentHeight" in CONFIGURATION_WINDOW
    and "preferredContentHeight" not in CONFIGURATION_WINDOW,
    "The dialog height must follow the content instead of the screen share.",
)
require(
    "surfaceContentWidth:" in CONFIGURATION_WINDOW
    and "contentImplicitWidth" in CONFIGURATION_WINDOW
    and "catalogRows" in CONFIGURATION_WORKSPACE
    and "Layout.preferredHeight: cellHeight * root.catalogRows"
    in CONFIGURATION_WORKSPACE,
    "The catalog rows must derive from the surface width so no tile is clipped.",
)

# Tile contract: centered content, add affordance attached to the icon and the
# shared interactive profile of the project.
require(
    "anchors.centerIn: parent" in CONFIGURATION_TILE
    and "padding:" in CONFIGURATION_TILE,
    "The catalog tile content must stay centered inside its own padding.",
)
require(
    "id: addBadge" in CONFIGURATION_TILE
    and "Kirigami.Theme.highlightedTextColor" in CONFIGURATION_TILE
    and 'text: "+"' in CONFIGURATION_TILE
    and "Accessible.ignored: true" in CONFIGURATION_TILE,
    "The add affordance must stay a decorative badge attached to the icon.",
)
require(
    "Kirigami.Units.cornerRadius * 2" in CONFIGURATION_TILE
    and "0.20" in CONFIGURATION_TILE
    and "0.97" in CONFIGURATION_TILE
    and "root.keyboardFocusVisible ? 2 : 1" in CONFIGURATION_TILE
    and "Qt.TabFocusReason" in CONFIGURATION_TILE
    and "Qt.BacktabFocusReason" in CONFIGURATION_TILE,
    "The tile must keep the shared hover, focus and press profile, with the "
    "focus ring limited to keyboard focus.",
)

# Tooltip contract: Plasma renders the tooltip in its own window, so the text is
# never clipped by the configuration surface, and the in-window tooltip of Qt
# Quick Controls must not come back to this dialog.
require(
    "PlasmaCore.ToolTipArea" in CONFIGURATION_TILE
    and "PlasmaCore.ToolTipArea" in CONFIGURATION_WORKSPACE
    and "PlasmaCore.ToolTipArea" in CONFIGURATION_WINDOW,
    "Every tooltip of the items configuration must use the Plasma tooltip area.",
)
require(
    "Controls.ToolTip" not in CONFIGURATION_UI
    and "Controls.ToolTip" not in CONFIGURATION_TILE,
    "The in-window tooltip must not return to the items configuration.",
)
require(
    'objectName: "itemsConfigurationTileToolTip"' in CONFIGURATION_TILE
    and "active: !dragHandler.active" in CONFIGURATION_TILE
    and "onKeyboardFocusVisibleChanged" in CONFIGURATION_TILE
    and "tileToolTip.showToolTip()" in CONFIGURATION_TILE,
    "The tile tooltip must stay testable, quiet while dragging, reachable from "
    "the keyboard and never opened by a programmatic focus.",
)

print("Development configuration contract: OK")
