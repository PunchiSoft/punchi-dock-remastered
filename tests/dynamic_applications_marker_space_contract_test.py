#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Contract for the dynamic-applications marker footprint.

The marker no longer paints a separator. It only takes layout space while its
move handle is active or while the launcher drop placeholder is shown, and the
visual index math subtracts its slot the rest of the time.
"""

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
COMPONENTS = ROOT / "contents/ui/components"
CODE = ROOT / "contents/code"
CONFIG = ROOT / "contents/ui/config"

COLLAPSE_PROPERTY = (
    'readonly property bool dynamicApplicationsMarkerCollapsed: '
    'itemType === "dynamic-applications" '
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
    '&& dockItemContainer.itemType !== "dynamic-applications" '
    "&& !dockItemContainer.persistentMoveHandleVisible"
)
SEPARATOR_SLOT = "Math.max(10, Math.ceil(separatorThickness + 4))"

GEOMETRY_COLLAPSE_FUNCTION = (
    "function dynamicApplicationsMarkerCollapsed(item) { "
    'const itemType = item && item.type ? String(item.type) : "app" '
    'return itemType === "dynamic-applications" '
    "&& !root.dynamicApplicationsMoveModeActive }"
)
GEOMETRY_MARKER_EXTENT = (
    'if (itemType === "dynamic-applications") '
    "{ return root.dynamicApplicationsMoveModeActive "
    "? root.dynamicApplicationsMoveHandleExtent : 0 }"
)
GEOMETRY_VISIBLE_COUNT = "visibleFixedDockItemCount"
GEOMETRY_FIXED_LENGTH = (
    "return Math.ceil(extent "
    "+ (Math.max(0, root.visibleFixedDockItemCount - 1) * dockSpacing))"
)

LEGACY_SEPARATOR_KEYS = (
    "showSeparator",
    "separatorAppearanceSource",
    "separatorStyle",
    "separatorThickness",
    "separatorLengthRatio",
    "separatorOpacity",
    "separatorGlowEnabled",
)


def compact(source: str) -> str:
    return re.sub(r"\s+", " ", source)


def require(condition: bool, message: str) -> bool:
    if not condition:
        print(f"dynamic applications marker space contract: {message}",
            file=sys.stderr)
    return condition


def function_body(source: str, name: str) -> str:
    start = source.find(f"function {name}(")
    if start < 0:
        return ""
    depth = 0
    for index in range(source.find("{", start), len(source)):
        if source[index] == "{":
            depth += 1
        elif source[index] == "}":
            depth -= 1
            if depth == 0:
                return source[start:index + 1]
    return ""


def main() -> int:
    dock_item = compact(
        (COMPONENTS / "DockItem.qml").read_text(encoding="utf-8")
    )
    geometry = compact(
        (COMPONENTS / "DockGeometryState.qml").read_text(encoding="utf-8")
    )
    placement = compact(
        (CODE / "recentApplicationsPlacement.js").read_text(encoding="utf-8")
    )
    config_items = (CONFIG / "code/configItems.js").read_text(encoding="utf-8")
    default_items = (CODE / "defaultItems.js").read_text(encoding="utf-8")

    passed = True

    # The marker stops occupying space only when it shows nothing functional.
    passed &= require(
        COLLAPSE_PROPERTY in dock_item,
        "DockItem must collapse the marker only without move handle and drop "
        "placeholder",
    )
    passed &= require(
        "separatorVisibleSetting" not in dock_item,
        "the marker must not keep a separator visibility setting",
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

    # The marker never paints a separator, while a plain one keeps its gate.
    passed &= require(
        SEPARATOR_VISUAL_GATE in dock_item,
        "the separator visual gate must exclude the dynamic-applications marker",
    )

    # The panel length mirrors the same footprint from the item model.
    passed &= require(
        GEOMETRY_COLLAPSE_FUNCTION in geometry,
        "DockGeometryState must collapse the marker unless its move handle is "
        "active",
    )
    passed &= require(
        GEOMETRY_MARKER_EXTENT in geometry,
        "the marker must reserve only the move handle extent",
    )
    passed &= require(
        'itemType === "separator" || itemType === "dynamic-applications"'
        not in geometry,
        "the marker must not consume separator geometry",
    )
    passed &= require(
        'if (itemType === "separator") {' in geometry,
        "the separator geometry branch must serve plain separators only",
    )
    passed &= require(
        "item.showSeparator" not in geometry,
        "the panel extent must not read the removed per-item separator flag",
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

    # The visual index math subtracts the marker slot unless it is shown.
    passed &= require(
        placement.count("dynamicCount - 1 + markerSlots") == 2,
        "persistent and recent visual indices must subtract the marker slot",
    )
    passed &= require(
        "function dynamicVisualIndex(index, markerSlot, recentIndex, "
        "recentSlots, offset)" in placement,
        "the task index must accept the marker slot explicitly",
    )
    passed &= require(
        "index + (markerSlot === true ? 1 : 0) + offset" in placement,
        "the first task must start at the marker slot only while it is shown",
    )

    # Persisted separator values on the marker are dropped, not normalized.
    prune_body = function_body(config_items, "pruneDynamicApplications")
    passed &= require(
        prune_body != "",
        "pruneDynamicApplications must stay available",
    )
    for key in LEGACY_SEPARATOR_KEYS:
        passed &= require(
            f'"{key}"' in prune_body,
            f"pruneDynamicApplications must delete the legacy key {key}",
        )
    passed &= require(
        "pruneSeparatorAppearance(item)" not in prune_body,
        "the marker must not keep normalizing separator appearance",
    )

    # The default dock must not ship a marker separator any more.
    passed &= require(
        "showSeparator" not in default_items,
        "the default items must not declare a marker separator",
    )

    if not passed:
        return 1
    print("dynamic applications marker space contract: ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
