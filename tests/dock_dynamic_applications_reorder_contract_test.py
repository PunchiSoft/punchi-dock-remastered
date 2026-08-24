#!/usr/bin/env python3

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MAIN = (ROOT / "contents/ui/main.qml").read_text(encoding="utf-8")
CONFIG_SCHEMA = (ROOT / "contents/config/main.xml").read_text(encoding="utf-8")
CONFIG_MOUSE = (ROOT / "contents/ui/config/ConfigMouse.qml").read_text(
    encoding="utf-8"
)
DOCK_ITEM = (ROOT / "contents/ui/components/DockItem.qml").read_text(
    encoding="utf-8"
)
DOCK_CONFIGURATION = (
    ROOT / "contents/ui/components/DockConfigurationState.qml"
).read_text(encoding="utf-8")
DRAG_LAYER = (
    ROOT / "contents/ui/components/DockReorderDragLayer.qml"
).read_text(encoding="utf-8")
POPUP_COORDINATOR = (
    ROOT / "contents/ui/components/PopupCoordinator.qml"
).read_text(encoding="utf-8")
CONTROLLER = (ROOT / "contents/ui/components/DockItemsController.qml").read_text(
    encoding="utf-8"
)
GEOMETRY = (ROOT / "contents/ui/components/DockGeometryState.qml").read_text(
    encoding="utf-8"
)
LOGIC = (ROOT / "contents/code/logic.js").read_text(encoding="utf-8")
DEFAULTS = (ROOT / "contents/code/defaultItems.js").read_text(encoding="utf-8")
CONFIG_ITEMS = (ROOT / "contents/ui/config/code/configItems.js").read_text(
    encoding="utf-8"
)
WORKFLOW = (
    ROOT / "contents/ui/config/code/configItemsWorkflowHelper.js"
).read_text(encoding="utf-8")
PALETTE = (ROOT / "contents/ui/config/AddItemPalette.qml").read_text(
    encoding="utf-8"
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


require(
    '"dynamic-applications"' in LOGIC.split("singletonDockItemTypes", 1)[1],
    "The open-applications marker must be a singleton persistent item.",
)
require(
    '"type": "dynamic-applications"' in DEFAULTS
    and '"name": "Open applications"' in DEFAULTS,
    "Fresh configurations must include the open-applications marker.",
)
require(
    'if (type === "dynamic-applications")' in CONFIG_ITEMS
    and 'return translate("Open applications")' in CONFIG_ITEMS
    and 'return "window-duplicate"' in CONFIG_ITEMS,
    "The configuration model must expose a named and themed marker.",
)
require(
    '"type": "dynamic-applications"' in PALETTE
    and 'hasItemType("dynamic-applications")' in PALETTE
    and 'hasItemType("dynamic-applications")' in WORKFLOW,
    "The KCM must add at most one open-applications marker.",
)
require(
    'itemType === "separator" || itemType === "dynamic-applications"'
    in GEOMETRY,
    "The marker must consume separator geometry instead of a full app slot.",
)
require(
    "property bool separatorVisibleSetting: true" in DOCK_ITEM
    and "&& dockItemContainer.separatorVisibleSetting" in DOCK_ITEM
    and "dockItemDelegate.modelData.showSeparator !== false" in MAIN,
    "The marker must keep its anchor while allowing its separator to be hidden.",
)
require(
    "function dynamicApplicationsMarkerUpdate(items)" in LOGIC
    and 'item.type === "dynamic-applications"' in LOGIC
    and "currentItems.length >= maximumDockItemCount" in LOGIC
    and '"errorCode": "maximumItemCount"' in LOGIC
    and 'updatedItems.push({' in LOGIC,
    "The fallback must append one marker without exceeding the item limit.",
)
require(
    "property bool dynamicApplicationsEnabled: false" in CONTROLLER
    and "property bool dockItemsLoaded: false" in CONTROLLER
    and "onDynamicApplicationsEnabledChanged:" in CONTROLLER
    and "function scheduleDynamicApplicationsMarker()" in CONTROLLER
    and "function ensureDynamicApplicationsMarker()" in CONTROLLER
    and "Logic.dynamicApplicationsMarkerUpdate(previousItems)" in CONTROLLER
    and "root.syncDockItemsConfiguration()" in CONTROLLER
    and "root.dockItems = previousItems" in CONTROLLER,
    "An enabled legacy configuration must persist the marker with rollback.",
)
require(
    "root.dockItemsLoaded = true" in CONTROLLER
    and CONTROLLER.count("root.scheduleDynamicApplicationsMarker()") >= 3
    and "dynamicApplicationsEnabled: Plasmoid.configuration.showActiveTasks"
    in MAIN,
    "Startup, configuration changes, and hot refresh must schedule migration.",
)

dock_items_entry_start = CONFIG_SCHEMA.index(
    '<entry name="dockItemsJson" type="String">'
)
dock_items_entry_end = CONFIG_SCHEMA.index("</entry>", dock_items_entry_start)
require(
    "<default></default>"
    in CONFIG_SCHEMA[dock_items_entry_start:dock_items_entry_end]
    and CONTROLLER.count("root.dockItems = Logic.loadItems(raw)") >= 2
    and 'raw.trim().length > 0 ? Logic.loadItems(raw) : []' not in CONTROLLER
    and "cfg_dockItemsJson && cfg_dockItemsJson.length > 0"
    in WORKFLOW
    and ": ItemsJS.defaultJson()" in WORKFLOW,
    "An empty first-run KConfig value must resolve to defaults in both the "
    "runtime and KCM, while an explicit JSON array remains authoritative.",
)

for marker in (
    "readonly property int dynamicApplicationsMarkerIndex",
    "function persistentVisualIndex(modelIndex)",
    "function dynamicVisualIndex(taskIndex)",
    "Layout.column: dockGeometry.verticalPanel",
    "Layout.row: dockGeometry.verticalPanel",
    "root.dynamicLauncherInsertionIndex()",
):
    require(marker in MAIN, f"The visual/persistent split is missing: {marker}")

require(
    "function movePersistentItem(sourceIndex, targetIndex, expectedItemText)"
    in CONTROLLER
    and "root.canonicalJsonText(root.dockItems[source]) !== expected"
    in CONTROLLER
    and "root.dockItems = previousItems" in CONTROLLER,
    "Persistent moves must validate identity and roll back failed persistence.",
)

for marker in (
    "onPressAndHold",
    "persistentPointerReorderEnabled",
    "persistentReorderPressStarted",
    "mouse.button === Qt.LeftButton",
    "dockItemContainer.persistentReorderPressStarted(\n                    dockItemContainer)",
    "persistentReorderStarted",
    "persistentReorderMoved",
    "persistentReorderFinished",
    "persistentReorderCanceled",
    "persistentKeyboardMoveRequested",
    "Qt.ControlModifier | Qt.ShiftModifier",
):
    require(marker in DOCK_ITEM, f"The persistent reorder gesture is missing: {marker}")

floating_reorder_entry_start = CONFIG_SCHEMA.index(
    '<entry name="enableFloatingItemDragReordering" type="Bool">'
)
floating_reorder_entry_end = CONFIG_SCHEMA.index(
    "</entry>", floating_reorder_entry_start
)
require(
    "<default>false</default>"
    in CONFIG_SCHEMA[floating_reorder_entry_start:floating_reorder_entry_end]
    and "property alias cfg_enableFloatingItemDragReordering" in CONFIG_MOUSE
    and "visible: !page.inPanel" in CONFIG_MOUSE
    and 'i18n("Enable press-and-hold item reordering")' in CONFIG_MOUSE
    and "floatingItemDragReorderingEnabled" in DOCK_CONFIGURATION
    and "enableFloatingItemDragReordering === true" in DOCK_CONFIGURATION,
    "Floating press-and-hold reordering must be an explicit opt-in.",
)

require(
    "sourceItem.mapToItem(dockLayout, x, y)" in MAIN
    and "sourceItem.mapToItem(dockWrapper, x, y)" in MAIN
    and "persistentDockItemsRepeater.itemAt(index)" in MAIN
    and "items[index].type === \"media\"" in MAIN,
    "Reordering must resolve persistent delegates and preserve media controls.",
)
require(
    "persistentPointerReorderEnabled:" in MAIN
    and "dockItemDelegate.persistentReorderEnabled" in MAIN
    and "root.inPanel" in MAIN
    and ".floatingItemDragReorderingEnabled" in MAIN
    and "Use Control+Shift with an arrow key to move this Dock item."
    in DOCK_ITEM,
    "Disabling the floating pointer gesture must preserve keyboard reordering.",
)
require(
    "DockReorderDragLayer {" in MAIN
    and "persistentDragPointerPosition" in MAIN
    and 'effectiveHoverAnimationMode:\n                    persistentDragActive ? "none"'
    in MAIN
    and "&& !dockLayout.persistentDragActive" in MAIN
    and "persistentReorderInsertionIndicator" in DOCK_ITEM,
    "An active reorder must follow the pointer, freeze hover, and show insertion feedback.",
)
require(
    'objectName: "dockReorderDragProxy"' in DRAG_LAYER
    and "x: root.pointerPosition.x - width / 2" in DRAG_LAYER
    and "y: root.pointerPosition.y - height / 2" in DRAG_LAYER
    and "Kirigami.Theme.highlightColor" in DRAG_LAYER
    and "ShaderEffect" not in DRAG_LAYER,
    "The drag proxy must be a lightweight themed visual that follows the pointer.",
)
require(
    "onPersistentReorderPressStarted:" in MAIN
    and "popupCoordinator.cancelTaskPopupForPointerReorder()" in MAIN
    and "function cancelTaskPopupForPointerReorder()" in POPUP_COORDINATOR
    and "root.hideTaskWindowsDialog()" in POPUP_COORDINATOR
    and "root.resetTaskPopupState()" in POPUP_COORDINATOR,
    "A reorderable pointer press must dismiss previews before they interrupt the long press.",
)
require(
    "function onConfigurationChanged()" in MAIN
    and "dockLayout.cancelPersistentDrag()" in MAIN,
    "An external configuration mutation must cancel an active gesture.",
)


def persistent_visual_index(
    model_index: int, marker_index: int, task_count: int, overflow_count: int
) -> int:
    if marker_index < 0 or model_index <= marker_index:
        return model_index
    return model_index + task_count + overflow_count


require(
    [persistent_visual_index(index, 1, 2, 1) for index in range(4)]
    == [0, 1, 5, 6],
    "Persistent items after the marker must move past tasks and overflow.",
)
require(
    [persistent_visual_index(index, -1, 2, 1) for index in range(4)]
    == [0, 1, 2, 3],
    "Legacy configurations without a marker must keep their persistent order.",
)

print("Dock dynamic applications and reorder contract: PASS")
