#!/usr/bin/env python3
"""Contract of the timed options panel, of its wrapper and of the phase closure.

The panel is a passive visual component for the calendar and the clock: it receives
the values it shows through the controls the caller pushes, announces the intentions
of the user and writes nothing. The dialog that hosts it stays a thin wrapper with
the public API it already had, the rules that normalize the values live only in
`configItems.js`, and the component the panel replaced is gone without leaving a
reference behind.
"""

from pathlib import Path
import re
import sys


PROJECT_ROOT = Path(__file__).resolve().parents[1]
CONFIG_DIR = PROJECT_ROOT / "contents/ui/config"
COMPONENTS_DIR = CONFIG_DIR / "components"

PANEL = (CONFIG_DIR / "TimedOptionsPanel.qml").read_text()
DIALOG = (COMPONENTS_DIR / "TimedDialog.qml").read_text()
CATALOG = (CONFIG_DIR / "code/itemTypeCatalog.js").read_text()
ADAPTER = (CONFIG_DIR / "code/draftFormAdapter.js").read_text()
CONFIG_ITEMS = (CONFIG_DIR / "code/configItems.js").read_text()
DRAFT_CONTROLLER = (CONFIG_DIR / "ItemDraftController.qml").read_text()
ADD_DIALOG = (CONFIG_DIR / "ItemConfigurationDialog.qml").read_text()
CONFIG_PAGE = (CONFIG_DIR / "ConfigItems.qml").read_text()

CALENDAR_KEY = "calendar-options"
REMOVED_COMPONENT = "CalendarOptions"

# Everything that turns a visual component into a dialog, and every write or external
# dependency a passive panel must not have.
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
    "ColorPaletteDialog",
    "colorPaletteDialog",
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
    # 1. The panel is passive: it does not know the page, the draft or the colour
    # dialog, and it is not a dialog itself.
    for fragment in FORBIDDEN_IN_PANEL:
        forbid(
            PANEL,
            fragment,
            f"TimedOptionsPanel.qml must not contain: {fragment}",
        )
    for marker in (
        'property string selectedItemType: "calendar"',
        "property bool editable: true",
        "property bool syncingValues: false",
        "property bool initializing: true",
        "property bool compactLayout: false",
        "signal formChanged()",
        "signal colorRequested(string target)",
        "function announce()",
        "function synchronizeValues(values)",
        "Component.onCompleted: root.initializing = false",
    ):
        require(PANEL, marker, f"TimedOptionsPanel.qml must keep: {marker}")

    # 2. The panel exposes the controls the page and its form helper read and write.
    for marker in (
        "property alias itemNameControl: itemName",
        "property alias timedItemWidthControl: timedItemWidth",
        "property alias timedTextScaleControl: timedTextScale",
        "property alias calendarItemHeightControl: calendarItemHeight",
        "property alias calendarFormatControl: calendarFormatCombo",
        "property alias calendarTimeTextScaleControl: calendarTimeTextScale",
        "property alias calendarDateTextScaleControl: calendarDateTextScale",
        "property alias calendarTextShadowsControl: calendarTextShadows",
        "property alias calendarShowWeekNumbersControl: calendarShowWeekNumbers",
        "property alias calendarPopupScaleControl: calendarPopupScale",
        "property alias calendarTextColorControl: textColorHolder",
    ):
        require(PANEL, marker, f"TimedOptionsPanel.qml must keep: {marker}")

    # 3. Units and ranges stay exactly as they were: pixels for the width,
    # percentages in the presentation and the same limits for every scale.
    for marker in (
        "from: 0\n                to: 600\n                stepSize: 10",
        'i18n("Automatic") : value + " px"',
        "from: 0.75\n                to: 1.8\n                stepSize: 0.05",
        "from: 0.75\n                to: 2.0\n                stepSize: 0.05",
        "from: 0.5\n                to: 3.0\n                stepSize: 0.05",
        "snapMode: Controls.Slider.SnapAlways",
        'Math.round(calendarPopupScale.value * 100) + "%"',
        "Math.round(calendarTimeTextScale.value * 100) + \"%\"",
        "Math.round(calendarDateTextScale.value * 100) + \"%\"",
    ):
        require(PANEL, marker, f"TimedOptionsPanel.qml must keep: {marker}")
    if PANEL.count("snapMode: Controls.Slider.SnapAlways") != 4:
        fail("Every slider of the panel must keep snapping to its step")

    # 4. Texts and contexts move with the interface.
    for marker in (
        'i18n("Name:")',
        'i18n("Item width:")',
        'i18n("Width:")',
        'i18n("Height:")',
        'i18n("Item height:")',
        'i18n("Text scale:")',
        'i18n("Format:")',
        'i18n("Time text scale:")',
        'i18n("Date text scale:")',
        'i18n("Show shadows on clock and date text")',
        'i18n("Show week numbers")',
        'i18n("Popup scale:")',
        'i18n("Text color:")',
        'i18n("Time text scale")',
        'i18n("Date text scale")',
        'i18n("Show calendar week numbers")',
        'i18n("Calendar popup scale")',
        'i18n("Adjusts the calendar popup scale between 50 and 300 percent.")',
    ):
        require(PANEL, marker, f"TimedOptionsPanel.qml must keep the text: {marker}")
    require(
        PANEL,
        '"HH:mm",\n                "HH:mm:ss",\n                "hh:mm AP",',
        "The panel must keep the list of formats",
    )
    if PANEL.count('"dddd, d MMMM yyyy"') != 1:
        fail("The list of formats must keep its seven entries, in one place")

    # 5. The wrapper keeps the whole public surface it had, including the four colour
    # controls that resolve to null today.
    for marker in (
        "property var controller",
        "property alias itemNameControl: optionsPanel.itemNameControl",
        "property alias timedItemWidthControl: optionsPanel.timedItemWidthControl",
        "property alias timedTextScaleControl: optionsPanel.timedTextScaleControl",
        "property alias calendarItemHeightControl: optionsPanel.calendarItemHeightControl",
        "property alias calendarFormatControl: optionsPanel.calendarFormatControl",
        "property alias calendarTimeTextScaleControl:",
        "property alias calendarDateTextScaleControl:",
        "property alias calendarTextShadowsControl:",
        "property alias calendarShowWeekNumbersControl:",
        "property alias calendarPopupScaleControl:",
        "property alias calendarTextColorControl:",
        "property var calendarBackgroundColorControl: null",
        "property var calendarAccentColorControl: null",
        "property var calendarBorderColorControl: null",
        "property var calendarRadiusControl: null",
        "modal: true",
        "standardButtons: Controls.Dialog.Close",
        "timedDialog.controller.selectedConfigureTitle()",
        "timedDialog.controller.width - Kirigami.Units.largeSpacing * 2",
        "timedDialog.controller.height - Kirigami.Units.largeSpacing * 2",
        "contentItem: TimedOptionsPanel {",
        "timedDialog.controller.applyItemForm()",
        "timedDialog.controller.openTimedColorDialog(String(target))",
        "syncingValues: timedDialog.isSynchronizing()",
    ):
        require(DIALOG, marker, f"TimedDialog.qml must keep: {marker}")
    for fragment in (
        "Controls.TextField",
        "Controls.Slider",
        "Controls.SpinBox",
        "Controls.ComboBox",
        "Controls.CheckBox",
        'i18n("Time text scale:")',
        'i18n("Popup scale:")',
    ):
        forbid(
            DIALOG,
            fragment,
            f"TimedDialog must not keep a second copy of the panel: {fragment}",
        )

    # 6. The page keeps its wiring and its aliases, so both flows keep working.
    for marker in (
        "TimedDialog {",
        "controller: page",
        "property alias itemName: timedDialog.itemNameControl",
        "property alias timedItemWidth: timedDialog.timedItemWidthControl",
        "property alias timedTextScale: timedDialog.timedTextScaleControl",
        "property alias calendarItemHeight: timedDialog.calendarItemHeightControl",
        "property alias calendarTimeTextScale:",
        "property alias calendarDateTextScale:",
        "property alias calendarTextShadows:",
        "property alias calendarFormat:",
        "property alias calendarShowWeekNumbers:",
        "property alias calendarPopupScale:",
        "property alias clockColor: timedDialog.calendarTextColorControl",
        "property alias calendarTextColor: timedDialog.calendarTextColorControl",
        "function openTimedDialog(index)",
    ):
        require(CONFIG_PAGE, marker, f"ConfigItems.qml must keep: {marker}")

    # 7. One key and one map: the catalogue names the calendar editor once and the add
    # dialog turns that key into exactly one component.
    require(
        CATALOG,
        f'const editorCalendarOptions = "{CALENDAR_KEY}"',
        "The catalogue must keep a single key for the calendar editor",
    )
    require(
        CATALOG,
        'false, "", editorCalendarOptions)',
        "The calendar entry must point at that key",
    )
    if CATALOG.count('"calendar-options"') != 1:
        fail("The calendar editor key must be declared exactly once")
    require(
        ADD_DIALOG,
        f'if (String(key) === "{CALENDAR_KEY}") {{\n            return calendarOptionsComponent',
        "The add dialog must map the key to the calendar panel",
    )
    if ADD_DIALOG.count("return calendarOptionsComponent") != 1:
        fail("The map must name the calendar component exactly once")
    if ADD_DIALOG.count("TimedOptionsPanel {") != 1:
        fail("The add dialog must instantiate the timed panel exactly once")
    require(
        ADD_DIALOG,
        'selectedItemType: "calendar"',
        "The add dialog only builds calendars, so the panel is told so",
    )
    require(
        ADD_DIALOG,
        'objectName: "itemConfigurationCalendarPanel"',
        "The add dialog must host the calendar panel",
    )
    require(
        ADD_DIALOG,
        'onColorRequested: function(target) {\n                root.colorPickerRequested(String(target))',
        "The colour request must stay an announcement of the dialog",
    )
    require(
        ADD_DIALOG,
        "signal colorPickerRequested(string target)",
        "The dialog must announce the colour request",
    )
    forbid(
        ADD_DIALOG,
        "ColorPaletteDialog",
        "The add dialog must not open the colour dialog yet",
    )
    if '"clock"' in CATALOG:
        fail(
            "The catalogue must not offer a clock type: the clock is only edited from "
            "the dialog of an existing element"
        )

    # 8. One source for the rules: `configItems.js` owns the readers, `pruneCalendar`
    # uses them, the draft applies that pruner and the adapter only calls the readers.
    for marker in (
        "function normalizedCalendarTimeTextScale(value)",
        "function normalizedCalendarDateTextScale(value)",
        "function normalizedCalendarTextShadowsEnabled(value)",
        "function normalizedCalendarShowWeekNumbers(value)",
        "function normalizedCalendarPopupScale(value)",
    ):
        require(CONFIG_ITEMS, marker, f"configItems.js must own the rule: {marker}")
    for marker in (
        "item.timeTextScale = normalizedCalendarTimeTextScale(item.timeTextScale)",
        "item.dateTextScale = normalizedCalendarDateTextScale(item.dateTextScale)",
        "normalizedCalendarTextShadowsEnabled(item.calendarTextShadowsEnabled)",
        "item.showWeekNumbers = normalizedCalendarShowWeekNumbers(item.showWeekNumbers)",
        "item.popupScale = normalizedCalendarPopupScale(item.popupScale)",
    ):
        require(
            CONFIG_ITEMS,
            marker,
            f"pruneCalendar must use the canonical reader: {marker}",
        )
    require(
        DRAFT_CONTROLLER,
        'case "calendar":\n            ConfigItemsJS.pruneCalendar(root.draft)',
        "The draft of a calendar must be pruned with the canonical rule",
    )
    for marker in (
        "function calendarOptions(draft)",
        "function calendarFields(panel)",
        "ConfigItemsJS.normalizedCalendarTimeTextScale(",
        "ConfigItemsJS.normalizedCalendarDateTextScale(",
        "ConfigItemsJS.normalizedCalendarTextShadowsEnabled(",
        "ConfigItemsJS.normalizedCalendarShowWeekNumbers(",
        "ConfigItemsJS.normalizedCalendarPopupScale(",
    ):
        require(ADAPTER, marker, f"The adapter must keep: {marker}")
    forbid(
        ADAPTER,
        "function normalized",
        "The adapter must not declare rules of its own",
    )

    # 9. The component the panel replaced is gone, and nothing points at it. This is
    # the repeatable form of the reference search that justified its removal.
    removed_path = CONFIG_DIR / f"{REMOVED_COMPONENT}.qml"
    if removed_path.exists():
        fail(f"The replaced component must be gone: {removed_path}")
    for path in sorted(CONFIG_DIR.rglob("*")):
        if path.suffix not in (".qml", ".js"):
            continue
        source = path.read_text()
        for match in re.finditer(rf"\b{REMOVED_COMPONENT}\b(?!s)", source):
            fail(
                "A canonical component name must not survive the removal: "
                f"{path}:{match.start()}"
            )

    print("Timed options panel contracts are consistent")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
