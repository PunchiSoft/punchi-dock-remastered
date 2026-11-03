#!/usr/bin/env python3
"""Contract for the middle-click gesture on running dock application items."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


CONFIG_XML = read("contents/config/main.xml")
CONFIG_MOUSE = read("contents/ui/config/ConfigMouse.qml")
CONFIG_STATE = read("contents/ui/components/DockConfigurationState.qml")
DOCK_ITEM = read("contents/ui/components/DockItem.qml")
MAIN_QML = read("contents/ui/main.qml")
ITEMS_CONTROLLER = read("contents/ui/components/DockItemsController.qml")
TASK_CONTROLLER = read("contents/ui/components/TaskModelController.qml")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def mouse_group_source() -> str:
    start = CONFIG_XML.find('<group name="Mouse">')
    require(start >= 0, "The Mouse configuration group is missing.")
    end = CONFIG_XML.find("</group>", start)
    require(end > start, "The Mouse configuration group is not closed.")
    return CONFIG_XML[start:end]


MOUSE_GROUP = mouse_group_source()

require(
    '<entry name="middleClickEnabled" type="Bool">' in MOUSE_GROUP,
    "The middle-click setting must be a boolean in the Mouse group.",
)
require(
    "<default>true</default>" in MOUSE_GROUP.split("middleClickEnabled", 1)[1].split(
        "</entry>", 1
    )[0],
    "Middle-click actions must be enabled by default.",
)

require(
    "property alias cfg_middleClickEnabled: middleClickEnabledSwitch.checked"
    in CONFIG_MOUSE,
    "The configuration page must bind the middle-click switch to its setting.",
)
require(
    "id: middleClickEnabledSwitch" in CONFIG_MOUSE
    and "Controls.Switch {" in CONFIG_MOUSE,
    "The middle-click setting must use a switch control.",
)
require(
    'i18n("Enable middle-click actions")' in CONFIG_MOUSE,
    "The middle-click switch must expose a translatable label.",
)

require(
    "middleClickEnabled:" in CONFIG_STATE
    and "Plasmoid.configuration.middleClickEnabled !== false" in CONFIG_STATE,
    "A missing stored value must keep middle-click actions enabled.",
)

require(
    "signal middleClicked()" in DOCK_ITEM,
    "Dock items must expose a dedicated middle-click signal.",
)
require(
    'readonly property bool middleClickActive: middleClickEnabled'
    in DOCK_ITEM
    and '&& itemType === "app"' in DOCK_ITEM,
    "Middle-click must stay limited to application items.",
)
require(
    "buttons = buttons | Qt.MiddleButton" in DOCK_ITEM,
    "The dock item must accept the middle button only through the gated path.",
)
require(
    "Qt.LeftButton | Qt.RightButton | Qt.MiddleButton" not in DOCK_ITEM,
    "The middle button must not be accepted unconditionally.",
)
require(
    "if (mouse.button === Qt.MiddleButton)" in DOCK_ITEM
    and "dockItemContainer.middleClicked()" in DOCK_ITEM,
    "The middle button must emit the dedicated signal instead of activating the item.",
)

require(
    MAIN_QML.count("middleClickEnabled: dockConfig.middleClickEnabled") >= 2,
    "Pinned and dynamic dock delegates must receive the middle-click setting.",
)
require(
    MAIN_QML.count("onMiddleClicked:") >= 2,
    "Pinned and dynamic dock delegates must handle the middle-click signal.",
)
require(
    MAIN_QML.count("handleDockItemMiddleClick(") >= 2,
    "Both middle-click handlers must delegate to the dock items controller.",
)

require(
    "function handleDockItemMiddleClick(item)" in ITEMS_CONTROLLER,
    "The dock items controller must own the middle-click action.",
)
handler = ITEMS_CONTROLLER.split("function handleDockItemMiddleClick(item)", 1)[1]
handler = handler.split("function ", 1)[0]
require(
    'item.type !== "app"' in handler,
    "Middle-click must ignore items that are not applications.",
)
require(
    "taskState.firstRow < 0" in handler and "return" in handler,
    "Applications without open windows must ignore the middle click.",
)
require(
    "requestNewInstanceForTaskRow(taskState.firstRow)" in handler,
    "The middle-click action must request a new instance of the matched task row.",
)

require(
    "function requestNewInstanceForTaskRow(row)" in TASK_CONTROLLER,
    "The task controller must expose the new-instance request.",
)
new_instance = TASK_CONTROLLER.split("function requestNewInstanceForTaskRow(row)", 1)[1]
new_instance = new_instance.split("function ", 1)[0]
require(
    "tasksModel.index(row, 0)" in new_instance
    and "tasksModel.requestNewInstance(taskIndex)" in new_instance,
    "The new-instance request must target the task manager model.",
)

print("dock_middle_click_contract_test: OK")
