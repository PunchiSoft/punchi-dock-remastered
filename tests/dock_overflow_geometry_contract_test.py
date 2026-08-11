#!/usr/bin/env python3

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MAIN = (ROOT / "contents/ui/main.qml").read_text()
MODEL = (ROOT / "contents/ui/components/TaskModelController.qml").read_text()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


dock_layout_start = MAIN.index("GridLayout {\n                id: dockLayout")
dock_layout_end = MAIN.index(
    "\n            }\n        }\n\n        GuardedPopupDialog {\n            id: folderPopupDialog",
    dock_layout_start,
)
dock_layout = MAIN[dock_layout_start:dock_layout_end]

y_block_start = dock_layout.index("                y: {")
y_block_end = dock_layout.index("\n                property int hoveredIndex", y_block_start)
y_block = dock_layout[y_block_start:y_block_end]

overflow_start = dock_layout.index("DockItem {\n                    id: taskOverflowDockItem")
overflow_item = dock_layout[overflow_start:]

require(
    "overflowLayoutAnchor" not in MAIN
    and "overflowWaveHover" not in MAIN
    and "trailingOverflowExtent" not in MAIN,
    "Overflow must not retain an external anchor or duplicated geometry extent.",
)
require(
    "return Math.round((parent.height - height) / 2)" in y_block,
    "Centered vertical panels must align the unified dock layout as one block.",
)
require(
    "return parent.height - height" in y_block
    and "- dockGeometry.dockBackgroundVerticalPadding" in y_block,
    "End-aligned vertical panels must align the unified layout before padding.",
)
require(
    "visible: root.overflowTaskRows.length > 0" in overflow_item
    and "itemIndex: dockItemsController.dockItems.length" in overflow_item
    and "+ root.visibleTaskRows.length" in overflow_item,
    "The synthetic overflow entry must remain the final visible dock index.",
)
require(
    "Layout.preferredWidth: root.inPanel" in overflow_item
    and "? dockGeometry.panelItemWidth : implicitWidth" in overflow_item
    and "Layout.preferredHeight: root.inPanel" in overflow_item
    and "? dockGeometry.panelItemHeight : implicitHeight" in overflow_item,
    "The synthetic entry must use the canonical panel cell in both orientations.",
)
require(
    "itemType: \"overflow\"" in overflow_item
    and "iconName: \"view-grid\"" in overflow_item
    and "onItemClicked: popupCoordinator.openTaskOverflowPopup(taskOverflowDockItem)"
    in overflow_item,
    "The unified entry must retain its semantic icon and popup action.",
)
require(
    "readonly property bool wavePointerInsideLayout:\n                    dockWaveHover.hovered"
    in dock_layout,
    "The unified layout hover handler must cover the synthetic entry and its spacing.",
)
require(
    "const directLimit = Math.min(configuredLimit, Math.max(0, availableSlots - 1))"
    in MODEL,
    "The model must continue reserving exactly one available slot for overflow.",
)
require(
    "readonly property real dynamicTaskCapacityLength" in MAIN
    and "if (dockGeometry.panelFillLengthEnabled)" in MAIN
    and "Number(root.availableScreenRect.height || 0)" in MAIN
    and "Number(root.availableScreenRect.width || 0)" in MAIN,
    "Panel capacity must use assigned Fill length or an independent screen limit in Fit mode.",
)
require(
    "dynamicTaskCapacityLength - totalPadding" in MAIN
    and "if (!dockGeometry.panelFillLengthEnabled)" not in MAIN[
        MAIN.index("readonly property int dynamicTaskSlotCapacity"):
        MAIN.index("Binding {", MAIN.index("readonly property int dynamicTaskSlotCapacity"))
    ],
    "Fit-content panels must retain a mathematical safety capacity without a feedback loop.",
)

print("Dock overflow geometry contract: PASS")
