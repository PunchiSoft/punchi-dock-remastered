#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Contract for the dynamic-applications marker footprint.

Hiding the marker separator must release its layout slot. The marker used to
keep a fixed slot because its size was computed without reading the separator
visibility, so unchecking "Show separator" only hid the line and left a gap.
"""

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
COMPONENTS = ROOT / "contents/ui/components"
CODE = ROOT / "contents/code"

COLLAPSE_PROPERTY = (
    'readonly property bool dynamicApplicationsMarkerCollapsed: '
    'itemType === "dynamic-applications" '
    "&& !separatorVisibleSetting "
    "&& !persistentMoveHandleVisible "
    "&& !launcherDropPlaceholderVisible"
)
COLLAPSED_TERNARY = (
    "? (dynamicApplicationsMarkerCollapsed "
    "? 0 "
    ": Math.max(10, Math.ceil(separatorThickness + 4)))"
)
COLLAPSED_VERTICAL = (
    "if ((separatorItem || spacerItem) && verticalPanelMode) { "
    "if (dynamicApplicationsMarkerCollapsed) { return 0 }"
)
SEPARATOR_VISUAL_GATE = (
    "visible: dockItemContainer.separatorItem "
    "&& dockItemContainer.separatorVisibleSetting "
    "&& !dockItemContainer.persistentMoveHandleVisible"
)
SEPARATOR_SLOT = "Math.max(10, Math.ceil(separatorThickness + 4))"

GEOMETRY_COLLAPSE_FUNCTION = (
    "function dynamicApplicationsMarkerCollapsed(item) { "
    'const itemType = item && item.type ? String(item.type) : "app" '
    'return itemType === "dynamic-applications" '
    "&& item.showSeparator === false }"
)
GEOMETRY_MOVE_MODE_BRANCH = (
    'if (itemType === "dynamic-applications" '
    "&& root.dynamicApplicationsMoveModeActive) "
    "{ return root.dynamicApplicationsMoveHandleExtent }"
)
GEOMETRY_COLLAPSED_EXTENT = (
    "if (root.dynamicApplicationsMarkerCollapsed(item)) { return 0 }"
)
GEOMETRY_VISIBLE_COUNT = "visibleFixedDockItemCount"
GEOMETRY_FIXED_LENGTH = (
    "return Math.ceil(extent "
    "+ (Math.max(0, root.visibleFixedDockItemCount - 1) * dockSpacing))"
)


def compact(source: str) -> str:
    return re.sub(r"\s+", " ", source)


def require(condition: bool, message: str) -> bool:
    if not condition:
        print(f"dynamic applications marker space contract: {message}",
            file=sys.stderr)
    return condition


def main() -> int:
    dock_item = compact(
        (COMPONENTS / "DockItem.qml").read_text(encoding="utf-8")
    )
    geometry = compact(
        (COMPONENTS / "DockGeometryState.qml").read_text(encoding="utf-8")
    )
    default_items = (CODE / "defaultItems.js").read_text(encoding="utf-8")

    passed = True

    # The marker stops occupying space only when it draws nothing at all.
    passed &= require(
        COLLAPSE_PROPERTY in dock_item,
        "DockItem must collapse the marker only without separator, move handle "
        "and drop placeholder",
    )
    passed &= require(
        "visible: !dockItemContainer.dynamicApplicationsMarkerCollapsed"
        in dock_item,
        "the collapsed marker must stop being visible so it releases its slot",
    )

    # Every extent calculation of the marker has to agree, in both axes.
    passed &= require(
        dock_item.count(COLLAPSED_TERNARY) == 2,
        "implicitWidth and implicitHeight must return zero for the collapsed "
        "marker",
    )
    passed &= require(
        COLLAPSED_VERTICAL in dock_item,
        "visualAreaHeight must return zero for the collapsed marker in vertical "
        "panels",
    )
    passed &= require(
        dock_item.count(SEPARATOR_SLOT) == 3,
        "a plain separator must keep its reserved slot",
    )

    # The separator appearance itself is out of scope for this correction.
    passed &= require(
        SEPARATOR_VISUAL_GATE in dock_item,
        "the separator visual gate must keep depending on the separator item, "
        "its visibility setting and the move handle",
    )

    # The panel length mirrors the same footprint from the item model.
    passed &= require(
        GEOMETRY_COLLAPSE_FUNCTION in geometry,
        "DockGeometryState must mirror the collapsed marker from the model",
    )
    passed &= require(
        GEOMETRY_MOVE_MODE_BRANCH in geometry,
        "the move handle extent must stay authoritative while moving the marker",
    )
    passed &= require(
        geometry.count(GEOMETRY_COLLAPSED_EXTENT) == 1,
        "the panel main axis extent must be zero for the collapsed marker",
    )
    move_mode_index = geometry.find(GEOMETRY_MOVE_MODE_BRANCH)
    collapsed_index = geometry.find(GEOMETRY_COLLAPSED_EXTENT)
    separator_index = geometry.find("if (itemType === \"separator\"")
    passed &= require(
        0 <= move_mode_index < collapsed_index < separator_index,
        "the move handle branch must be evaluated before the collapsed marker",
    )
    passed &= require(
        GEOMETRY_FIXED_LENGTH in geometry,
        "the fixed panel length must count only the rendered items",
    )
    passed &= require(
        geometry.count(GEOMETRY_VISIBLE_COUNT) == 4,
        "the rendered item count must drive the fixed length and both boundary "
        "spacings",
    )
    passed &= require(
        "items.length - 1" not in geometry,
        "the fixed panel length must not reserve a gap for the collapsed marker",
    )

    # The default dock must keep shipping a visible separator.
    passed &= require(
        "showSeparator" not in default_items,
        "the default items must not disable the dynamic-applications separator",
    )

    if not passed:
        return 1
    print("dynamic applications marker space contract: ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
