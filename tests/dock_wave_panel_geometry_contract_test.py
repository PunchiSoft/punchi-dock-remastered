#!/usr/bin/env python3

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MAIN = (ROOT / "contents/ui/main.qml").read_text()
CONFIG_SCHEMA = (ROOT / "contents/config/main.xml").read_text()
CONFIG_GENERAL = (ROOT / "contents/ui/config/ConfigGeneral.qml").read_text()
CONFIG_MOUSE = (ROOT / "contents/ui/config/ConfigMouse.qml").read_text()
DOCK_CONFIGURATION = (
    ROOT / "contents/ui/components/DockConfigurationState.qml"
).read_text()
DOCK_ITEM = (ROOT / "contents/ui/components/DockItem.qml").read_text()
TASK_INDICATOR = (ROOT / "contents/ui/components/TaskIndicator.qml").read_text()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


dock_layout_start = MAIN.index("GridLayout {\n                id: dockLayout")
dock_layout_end = MAIN.index(
    "\n            }\n        }\n\n        GuardedPopupDialog {\n            id: folderPopupDialog",
    dock_layout_start,
)
dock_layout = MAIN[dock_layout_start:dock_layout_end]

x_block_start = dock_layout.index("                x: {")
y_block_start = dock_layout.index("                y: {", x_block_start)
x_block = dock_layout[x_block_start:y_block_start]
y_block_end = dock_layout.index("\n                property int hoveredIndex", y_block_start)
y_block = dock_layout[y_block_start:y_block_end]

require(
    "if (!root.inPanel)" in x_block
    and "return Math.round((parent.width - width) / 2)" in x_block,
    "Floating horizontal geometry must retain its centered main-axis placement.",
)
require(
    "if (dockGeometry.verticalPanel)" in x_block
    and "return Math.round((parent.width - width) / 2)" in x_block
    and "panelOnLeftEdge" not in x_block
    and "panelOnRightEdge" not in x_block,
    "A vertical panel must center any Wave overflow across its allocated width.",
)
require(
    "if (!root.inPanel)" in y_block
    and "return Math.round((parent.height - height) / 2)" in y_block,
    "Floating vertical geometry must retain its centered placement.",
)
require(
    "if (!dockGeometry.verticalPanel)" in y_block
    and "return Math.round((parent.height - height) / 2)" in y_block
    and "horizontalOuterEdgeInset" not in y_block
    and "panelOnTopEdge" not in y_block
    and "panelOnBottomEdge" not in y_block,
    "A horizontal panel must center its dock row inside Plasma's allocated height.",
)
require(
    "panelWindowMappedOrigin" not in dock_layout
    and "panelCrossAxisBeforeMargin" not in dock_layout
    and "panelCrossAxisAfterMargin" not in dock_layout,
    "Panel alignment must not consume Plasma's adaptive floating window padding.",
)
require(
    "DockItem {\n                    id: taskOverflowDockItem" in dock_layout
    and "overflowLayoutAnchor" not in MAIN,
    "The overflow item must be a terminal child of the same dock layout.",
)
require(
    "return iconSize * 0.5 * (waveScale - 1.0)" in DOCK_ITEM,
    "Wave must keep compensating exactly half of its visual growth.",
)
require(
    "readonly property real waveSharedScaleDelta: Math.min(0.50" in DOCK_ITEM
    and "readonly property real wavePrimaryScaleDelta" in DOCK_ITEM,
    "Panel alignment must not replace the approved shared and primary Wave scales.",
)
require(
    "anchors.fill: visualArea" in DOCK_ITEM,
    "Task geometry must remain tied to the stable visual slot.",
)
task_indicator_start = DOCK_ITEM.index("        TaskIndicator {")
task_indicator_end = DOCK_ITEM.index(
    "\n        WindowCountBadge {", task_indicator_start
)
task_indicator = DOCK_ITEM[task_indicator_start:task_indicator_end]
require(
    'readonly property string effectiveIndicatorPosition:\n'
    '        indicatorPosition === "top" ? "top" : "bottom"'
    in DOCK_ITEM
    and '? "right" : "left"' not in DOCK_ITEM,
    "Vertical panels must preserve the configured top or bottom indicator edge.",
)
require(
    "anchors.centerIn: parent" in task_indicator
    and "width: dockItemContainer.iconSize" in task_indicator
    and "height: dockItemContainer.iconSize" in task_indicator
    and "anchors.fill: parent" not in task_indicator
    and "CenterOffset" not in task_indicator,
    "The task indicator must follow the icon footprint without an extra edge offset.",
)
require(
    "scale: dockItemContainer.waveScale" in task_indicator
    and "x: dockItemContainer.hoverOffsetX" in task_indicator
    and "y: dockItemContainer.hoverOffsetY" in task_indicator
    and "hoverAnimationMode === \"wave\"" not in task_indicator,
    "The task indicator must follow the icon transform in every zoom mode.",
)
require(
    "const configuredPercent = Number(Plasmoid.configuration.indicatorOpacity)"
    in DOCK_CONFIGURATION
    and "Number.isFinite(configuredPercent)" in DOCK_CONFIGURATION
    and "indicatorOpacity || 100" not in DOCK_CONFIGURATION,
    "Indicator opacity must preserve an explicit zero-percent configuration.",
)
require(
    "Math.min(1.0, indicatorOpacity))" in TASK_INDICATOR
    and "stateOpacity" not in TASK_INDICATOR,
    "Configured indicator opacity must be the final visual opacity.",
)
hover_animation_entry_start = CONFIG_SCHEMA.index(
    '<entry name="hoverAnimation" type="String">'
)
hover_animation_entry_end = CONFIG_SCHEMA.index(
    "</entry>", hover_animation_entry_start
)
hover_animation_entry = CONFIG_SCHEMA[
    hover_animation_entry_start:hover_animation_entry_end
]
require(
    "<default>wave</default>" in hover_animation_entry
    and 'property string cfg_hoverAnimation: "wave"' in CONFIG_MOUSE
    and 'property string hoverAnimationMode: "wave"' in DOCK_ITEM,
    "Wave must be the default hover animation across KConfig, KCM, and delegates.",
)
require(
    CONFIG_MOUSE.count('i18n("Pulse")') == 2
    and '"value": "selectionPulse"' in CONFIG_MOUSE
    and 'i18n("Selection pulse")' not in CONFIG_MOUSE
    and 'i18n("Paragraph")' not in CONFIG_MOUSE
    and 'configuredMode === "paragraph"' in DOCK_CONFIGURATION
    and 'return "selectionPulse"' in DOCK_CONFIGURATION,
    "The KCM must expose the concise Pulse label while preserving legacy migration.",
)
require(
    'hoverAnimationMode === "selectionPulse"' in DOCK_ITEM
    and "id: selectionPulseAnimation" in DOCK_ITEM
    and "to: dockItemContainer.selectionPulsePeakScale" in DOCK_ITEM
    and "to: 0.97" in DOCK_ITEM
    and 'property: "selectionPulseScale"' in DOCK_ITEM
    and "dockItemContainer.restartSelectionPulse()" in DOCK_ITEM
    and "dockItemContainer.resetSelectionPulse()" in DOCK_ITEM
    and "paragraphInfluences" not in DOCK_ITEM,
    "Selection Pulse must run once on hover and settle back to the original scale.",
)
require(
    "hoverAnimationMode: dockConfig.dockHoverAnimation" in MAIN
    and "Plasmoid.configuration.hoverAnimation" not in MAIN,
    "Every dock consumer must use the normalized reactive hover animation.",
)
require(
    "cfg_hoverScale" not in CONFIG_GENERAL
    and CONFIG_MOUSE.count("property alias cfg_hoverScale:") == 1
    and "property alias cfg_hoverScale: hoverScaleSlider.value" in CONFIG_MOUSE,
    "Hover scale must have exactly one KCM owner on the Mouse page.",
)
require(
    CONFIG_MOUSE.index('Kirigami.FormData.label: i18n("Hover animation:")')
    < CONFIG_MOUSE.index('Kirigami.FormData.label: i18n("Hover enlargement:")')
    < CONFIG_MOUSE.index('Kirigami.FormData.label: i18n("Dock motion speed:")')
    and "id: hoverScaleSlider" in CONFIG_MOUSE
    and "from: 1.0" in CONFIG_MOUSE
    and "to: 2.0" in CONFIG_MOUSE
    and 'Accessible.name: i18n("Hover enlargement")' in CONFIG_MOUSE,
    "Mouse settings must group hover animation, scale, and motion speed in that order.",
)
require(
    "Math.round((hoverScaleSlider.value - 1.0) * 100)" in CONFIG_MOUSE
    and 'text: i18n("%1%", page.hoverEnlargementPercent)' in CONFIG_MOUSE
    and "hoverEnlargementPercent <= 0" in CONFIG_MOUSE
    and "inPanel && hoverEnlargementPercent >= 100" in CONFIG_MOUSE
    and 'i18n("At 0%, the hover enlargement animation is disabled.")'
    in CONFIG_MOUSE
    and 'i18n("At 100%, hover enlargement may be clipped' in CONFIG_MOUSE,
    "Hover enlargement must display 0-100 percent and warn at its contextual limits.",
)
require(
    "Math.max(1.0," in DOCK_CONFIGURATION
    and "Math.max(1.05," not in DOCK_CONFIGURATION
    and "Math.max(1.0, hoverScaleSetting)" in DOCK_ITEM
    and "selectionPulsePeakScale <= 1.0" in DOCK_ITEM,
    "Zero-percent enlargement must disable spatial hover scaling, including Selection Pulse.",
)
require(
    "readonly property real selectionPulsePeakScale:\n"
    "        Math.max(1.0, hoverScaleSetting)" in DOCK_ITEM
    and "Math.min(0.28" not in DOCK_ITEM,
    "Selection Pulse must share the configured maximum used by single-item zoom modes.",
)
hover_start = DOCK_ITEM.index("    Item {\n        id: hoverBackground")
hover_end = DOCK_ITEM.index("\n    Rectangle {", hover_start)
hover_surface = DOCK_ITEM[hover_start:hover_end]
require(
    "PunchiMenuComponents.PunchiMenuItemHighlight {" in hover_surface
    and "anchors.margins: Kirigami.Units.smallSpacing" in hover_surface,
    "Dock hover must reuse the shared PunchiMenu highlight with its application spacing.",
)
require(
    "scale: dockItemContainer.waveScale" in hover_surface
    and "x: dockItemContainer.hoverOffsetX" in hover_surface
    and "y: dockItemContainer.hoverOffsetY" in hover_surface
    and "? dockItemContainer.waveScale : 1.0" not in hover_surface,
    "Dock hover must follow the icon scale and edge offset in every zoom mode.",
)
require(
    "readonly property bool pointerHighlighted: mouseArea.containsMouse"
    in hover_surface
    and "hovered: hoverBackground.pointerHighlighted" in hover_surface
    and "selected: hoverBackground.pointerHighlighted" in hover_surface
    and "focused: mouseArea.activeFocus" in hover_surface
    and "pressed: mouseArea.pressed" in hover_surface
    and "taskIsActive" not in hover_surface,
    "Dock hover must expose the menu frame under the pointer while remaining separate from task activity.",
)
require(
    "readonly property Item taskPopupAnchorItem: taskPopupTracksVisualArea"
    in DOCK_ITEM
    and "? visualArea : null" in DOCK_ITEM
    and MAIN.index("taskPopupTracksVisualArea: true")
        > MAIN.index("id: taskDockItemDelegate"),
    "Only dynamic tasks must opt into the transformed visual popup anchor.",
)
require(
    'readonly property bool overflowItem: itemType === "overflow"' in DOCK_ITEM
    and "readonly property bool structuralWaveItem: separatorItem || spacerItem"
    in DOCK_ITEM
    and "separatorItem || spacerItem\n        || overflowItem" not in DOCK_ITEM,
    "The overflow drawer must participate in Wave while separators and spacers remain structural.",
)
require(
    'if (overflowItem && inPanel)' not in DOCK_ITEM
    and 'trailingWaveBoundaryCompensation' not in DOCK_ITEM
    and 'trailingWaveBoundaryGuard' not in DOCK_ITEM
    and 'return directionalShift' in DOCK_ITEM,
    "The terminal drawer must use the same main-axis Wave field as regular dock items.",
)
require(
    'trailingWaveBoundaryIndex' not in MAIN
    and 'dynamicTaskCapacityLength - totalPadding' in MAIN
    and '(dockGeometry.dockBackgroundVerticalPadding * 2)' in MAIN
    and '(dockGeometry.dockBackgroundHorizontalPadding * 2)' in MAIN,
    "The panel must reserve its normal symmetric edge padding instead of a synthetic Wave boundary.",
)
require(
    "id: overflowTile" in DOCK_ITEM
    and "scale: dockItemContainer.waveScale" in DOCK_ITEM
    and "x: dockItemContainer.hoverOffsetX" in DOCK_ITEM
    and "y: dockItemContainer.hoverOffsetY" in DOCK_ITEM
    and "id: overflowTileBackground" in DOCK_ITEM
    and "color: Kirigami.Theme.highlightColor" in DOCK_ITEM
    and "color: Kirigami.Theme.highlightedTextColor" in DOCK_ITEM
    and 'iconName: "view-grid"' in MAIN,
    "The synthetic overflow control must magnify its themed tile and semantic grid icon as one visual.",
)

print("Dock Wave panel geometry contract: PASS")
