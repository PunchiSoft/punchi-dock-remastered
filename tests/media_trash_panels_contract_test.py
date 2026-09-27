#!/usr/bin/env python3
"""Contract of the media player and trash options panels extracted from their dialog.

The panels are passive visual components: they receive the values they show through
their properties—including the resolved sound names—announce the intentions of the
user through their signals and write nothing. The dialogs that host them stay thin
wrappers with the public API they already had, the rules that normalize the values
live only in `configItems.js`, and the page keeps its own wiring untouched.
"""

from pathlib import Path
import re
import sys


PROJECT_ROOT = Path(__file__).resolve().parents[1]
CONFIG_DIR = PROJECT_ROOT / "contents/ui/config"
COMPONENTS_DIR = CONFIG_DIR / "components"

MEDIA_PANEL = (CONFIG_DIR / "MediaPlayerOptionsPanel.qml").read_text()
TRASH_PANEL = (CONFIG_DIR / "TrashOptionsPanel.qml").read_text()
MEDIA_DIALOG = (COMPONENTS_DIR / "MediaPlayerDialog.qml").read_text()
TRASH_DIALOG = (COMPONENTS_DIR / "TrashDialog.qml").read_text()
CATALOG = (CONFIG_DIR / "code/itemTypeCatalog.js").read_text()
ADAPTER = (CONFIG_DIR / "code/draftFormAdapter.js").read_text()
CONFIG_ITEMS = (CONFIG_DIR / "code/configItems.js").read_text()
CONFIG_CONTROLLER = (CONFIG_DIR / "code/configItemsController.js").read_text()
DIALOG = (CONFIG_DIR / "ItemConfigurationDialog.qml").read_text()
DRAFT_CONTROLLER = (CONFIG_DIR / "ItemDraftController.qml").read_text()
CONFIG_PAGE = (CONFIG_DIR / "ConfigItems.qml").read_text()

MEDIA_KEY = "media-options"
TRASH_KEY = "trash-options"

# Everything that turns a visual component into a dialog, and every write a passive
# panel must not do.
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
    "controller",
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
    # 1. Both panels are passive.
    for name, source in (
        ("MediaPlayerOptionsPanel.qml", MEDIA_PANEL),
        ("TrashOptionsPanel.qml", TRASH_PANEL),
    ):
        for fragment in FORBIDDEN_IN_PANEL:
            forbid(
                source,
                fragment,
                f"{name} must not contain the dialog or write marker: {fragment}",
            )

    # 2. The media panel owns its options and its texts, and announces every value.
    for marker in (
        'i18nc("@option:media-track-information", "Automatic (recommended)")',
        'i18nc("@option:media-track-information", "Always show")',
        'i18nc("@option:media-track-information", "Hide")',
        'i18nc("@option:media-display-mode", "Normal (recommended)")',
        'i18nc("@option:media-display-mode", "Compact")',
        'i18nc("@option:media-player", "Automatic (active player)")',
        'i18nc("@option:media-auto-collapse", "Never")',
        'i18np("%1 second", "%1 seconds", value)',
        "signal playerSelected(var application)",
        "signal mediaTextModeSelected(string mode)",
        "signal mediaDisplayModeSelected(string mode)",
        "signal openPlayerMinimizedSelected(bool enabled)",
        "signal autoCollapseDelaySecondsSelected(int seconds)",
        "function rebuildOptions()",
        "function syncSelection()",
        "function syncTextModeSelection()",
        "function syncDisplayModeSelection()",
        "onValueModified: root.autoCollapseDelaySecondsSelected(value)",
    ):
        require(MEDIA_PANEL, marker, f"MediaPlayerOptionsPanel.qml must keep: {marker}")
    for marker in (
        "onApplicationsChanged: root.rebuildOptions()",
        "onSelectedStorageIdChanged: root.syncSelection()",
        "onMediaTextModeChanged: root.syncTextModeSelection()",
        "onMediaDisplayModeChanged: root.syncDisplayModeSelection()",
    ):
        require(
            MEDIA_PANEL,
            marker,
            "The media panel must synchronize the shown selection when a value "
            f"changes: {marker}",
        )
    forbid(
        MEDIA_PANEL,
        "normalizedMedia",
        "The media panel must not normalize: the rules live in configItems.js",
    )

    # 3. The trash panel owns its texts and receives the resolved names.
    for marker in (
        'i18n("Name:")',
        'i18n("Show trash state")',
        'i18n("Drag files")',
        'i18n("Empty icon:")',
        'i18n("Full icon:")',
        'i18n("Empty sound:")',
        'i18n("Test sound")',
        'i18n("Choose sound")',
        'i18n("Choose icon")',
        'i18n("Default")',
        "property string soundFileName",
        "property string defaultSoundFileName",
        "property bool editable: true",
        "property bool compactLayout: false",
        "signal formChanged()",
        "signal emptyIconPickerRequested()",
        "signal fullIconPickerRequested()",
        "signal soundPreviewRequested()",
        "signal soundResetRequested()",
        "signal soundPickerRequested()",
    ):
        require(TRASH_PANEL, marker, f"TrashOptionsPanel.qml must keep: {marker}")
    forbid(
        TRASH_PANEL,
        'lastIndexOf("/")',
        "The panel must not resolve a file name: it receives the resolved name",
    )
    for marker in (
        "Accessible.name: i18n(\"Choose icon\")",
        "Accessible.name: i18n(\"Test sound\")",
        "Accessible.name: i18n(\"Default\")",
        "Accessible.name: i18n(\"Choose sound\")",
    ):
        require(
            TRASH_PANEL,
            marker,
            "An icon-only button must announce what it does: " + marker,
        )

    # 4. The dialogs keep their public API and host the panel.
    for marker in (
        "property var applications: []",
        "property string selectedStorageId",
        "property string mediaTextMode",
        "property string mediaDisplayMode",
        "property bool openPlayerMinimized",
        "property int autoCollapseDelaySeconds",
        "property real selectorWidth",
        "property alias playerOptions",
        "readonly property alias textModeOptions",
        "readonly property alias displayModeOptions",
        "signal playerSelected(var application)",
        "signal mediaTextModeSelected(string mode)",
        "signal mediaDisplayModeSelected(string mode)",
        "signal openPlayerMinimizedSelected(bool enabled)",
        "signal autoCollapseDelaySecondsSelected(int seconds)",
        "function rebuildOptions()",
        "function syncSelection()",
        "function syncTextModeSelection()",
        "function syncDisplayModeSelection()",
        "contentItem: MediaPlayerOptionsPanel {",
        "root.playerSelected(application)",
        "standardButtons: Controls.Dialog.Close",
        "modal: true",
    ):
        require(MEDIA_DIALOG, marker, f"MediaPlayerDialog.qml must keep: {marker}")
    if re.search(r"^\\s*title:", MEDIA_DIALOG, re.MULTILINE):
        fail(
            "MediaPlayerDialog must not declare a title: the page sets it, which is "
            "how it already worked"
        )
    for fragment in (
        "Controls.ComboBox",
        '"Automatic (active player)"',
        '"Always show"',
        '"Normal (recommended)"',
        '"value": "automatic"',
        '"value": "always"',
        '"value": "hidden"',
        '"value": "compact"',
    ):
        forbid(
            MEDIA_DIALOG,
            fragment,
            f"MediaPlayerDialog must not keep a second copy of the panel: {fragment}",
        )

    for marker in (
        "property var controller",
        "property alias nameText: optionsPanel.nameText",
        "property alias emptyIconText: optionsPanel.emptyIconText",
        "property alias fullIconText: optionsPanel.fullIconText",
        "property alias showStateChecked: optionsPanel.showStateChecked",
        "property alias acceptDropsChecked: optionsPanel.acceptDropsChecked",
        "property alias soundPath: optionsPanel.soundPath",
        "signal formChanged()",
        "signal emptyIconPickerRequested()",
        "signal fullIconPickerRequested()",
        "signal soundPreviewRequested()",
        "signal soundResetRequested()",
        "signal soundPickerRequested()",
        "contentItem: TrashOptionsPanel {",
        'title: i18n("Configure trash")',
        "standardButtons: Controls.Dialog.Close",
        "modal: true",
        "function selectedTypeIsTrash()",
        "root.resolvedSoundName(root.soundPath)",
        "root.emptyIconPickerRequested()",
    ):
        require(TRASH_DIALOG, marker, f"TrashDialog.qml must keep: {marker}")
    for fragment in (
        "Controls.TextField",
        "Controls.CheckBox",
        'i18n("Show trash state")',
        'i18n("Empty sound:")',
    ):
        forbid(
            TRASH_DIALOG,
            fragment,
            f"TrashDialog must not keep a second copy of the panel: {fragment}",
        )

    # 5. One source for the rules: `configItems.js` owns the readers and its pruner
    # uses them; the adapter only calls them.
    for marker in (
        "function normalizedMediaTextMode(value)",
        "function normalizedMediaDisplayMode(value)",
        "function normalizedMediaAutoCollapseDelaySeconds(value)",
        "function normalizedTrashShowState(value)",
        "function normalizedTrashAcceptDrops(value)",
    ):
        require(CONFIG_ITEMS, marker, f"configItems.js must own the rule: {marker}")
    require(
        CONFIG_ITEMS,
        "var mediaTextMode = normalizedMediaTextMode(item.mediaTextMode)",
        "pruneMedia must use the canonical reader instead of a second copy",
    )
    require(
        CONFIG_ITEMS,
        "normalizedMediaAutoCollapseDelaySeconds(item.mediaAutoCollapseDelaySeconds)",
        "pruneMedia must use the canonical reader for the delay",
    )
    for marker in (
        "ConfigItemsJS.normalizedMediaTextMode(item.mediaTextMode)",
        "ConfigItemsJS.normalizedMediaDisplayMode(",
        "ConfigItemsJS.normalizedMediaAutoCollapseDelaySeconds(",
        "ConfigItemsJS.normalizedTrashShowState(item.showState)",
        "ConfigItemsJS.normalizedTrashAcceptDrops(item.acceptDrops)",
        "ConfigItemsControllerJS.fileName(path)",
    ):
        require(ADAPTER, marker, f"The adapter must read the canonical rule: {marker}")
    forbid(
        ADAPTER,
        "function normalized",
        "The adapter must not declare rules of its own",
    )
    require(
        CONFIG_CONTROLLER,
        "function fileName(path)",
        "The name of a sound file must keep its single implementation",
    )
    for marker in (
        "case \"media\":\n            ConfigItemsJS.pruneMedia(root.draft)",
        "case \"trash\":\n            ConfigItemsJS.pruneTrash(root.draft)",
    ):
        require(
            DRAFT_CONTROLLER,
            marker,
            f"The draft must be pruned with the canonical rule: {marker}",
        )

    # 6. The catalogue names one specific key per panel and the dialog maps it.
    for marker in (
        f'const editorMediaOptions = "{MEDIA_KEY}"',
        f'const editorTrashOptions = "{TRASH_KEY}"',
        'editorMediaOptions)',
        'editorTrashOptions)',
    ):
        require(CATALOG, marker, f"The catalogue must declare: {marker}")
    for marker in (f'"{MEDIA_KEY}"', f'"{TRASH_KEY}"'):
        require(
            DIALOG,
            marker,
            f"ItemConfigurationDialog must map the catalogue key: {marker}",
        )
    for marker in (
        'objectName: "itemConfigurationMediaPanel"',
        'objectName: "itemConfigurationTrashPanel"',
        "DraftFormAdapter.mediaPlayerFields(application)",
        "DraftFormAdapter.trashFields(trashPanel)",
        "DraftFormAdapter.soundFileName(",
        "root.draftController.defaultTrashEmptySound",
        "DraftFormAdapter.trashOptions(root.draftController.draft,",
        "DraftFormAdapter.mediaOptions(root.draftController.draft)",
        'onEmptyIconPickerRequested: root.iconPickerRequested("trash")',
        'onFullIconPickerRequested: root.iconPickerRequested("trashFull")',
        "onSoundPickerRequested: root.soundPickerRequested()",
        "onSoundPreviewRequested: root.soundPreviewRequested()",
        "signal soundPickerRequested()",
        "signal soundPreviewRequested()",
    ):
        require(DIALOG, marker, f"ItemConfigurationDialog must keep: {marker}")
    forbid(
        DIALOG,
        "openTrashSoundPicker",
        "The add dialog must not open the sound picker yet",
    )
    forbid(
        DIALOG,
        "playTrashEmptySoundPreview",
        "The add dialog must not play a sound yet",
    )
    forbid(
        DIALOG,
        "SystemDiscovery",
        "The add dialog must not discover applications on its own",
    )

    # 7. The page keeps the existing editing route and connects the add-only
    # dialog through semantic requests.
    for marker in (
        "TrashDialog {",
        "controller: page",
        "onFormChanged: page.applyItemForm()",
        "onEmptyIconPickerRequested: page.openIconPicker(\"trash\")",
        "onSoundPickerRequested: page.openTrashSoundPicker()",
        "MediaPlayerDialog {",
        'title: i18n("Configure media player")',
        "onPlayerSelected: function(application) {",
    ):
        require(CONFIG_PAGE, marker, f"ConfigItems.qml must keep its wiring: {marker}")
    for marker in (
        "ItemConfigurationDialog {",
        "ItemDraftController {",
        "onSoundPickerRequested: page.openDraftSoundPicker()",
        "onSoundPreviewRequested: page.playDraftTrashSoundPreview()",
        "page.requestDraftMediaApplications",
        'String(operation.kind) === "media-applications"',
    ):
        require(
            CONFIG_PAGE,
            marker,
            "The page must connect the add flow without replacing existing editing: "
            + marker,
        )

    print("Media and trash options panel contracts are consistent")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
