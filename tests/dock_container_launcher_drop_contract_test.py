#!/usr/bin/env python3

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DOCK_ITEM = (ROOT / "contents/ui/components/DockItem.qml").read_text()
DOCK_DROP_STATE = (ROOT / "contents/code/dockDropState.js").read_text()
DOCK_CONTROLLER = (
    ROOT / "contents/ui/components/DockItemsController.qml"
).read_text()
CONFIG_ITEMS = (
    ROOT / "contents/ui/config/code/configItems.js"
).read_text()
MAIN = (ROOT / "contents/ui/main.qml").read_text()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


require(
    "function mayContainApplicationLauncher(event)" in DOCK_ITEM
    and "function isApplicationLauncherDrag(event, validation)" in DOCK_ITEM
    and "validateLauncherDrop(drag.urls)" in DOCK_ITEM,
    "Launcher containment must use the native resolver instead of trusting a file extension.",
)
require(
    DOCK_ITEM.index("isApplicationLauncherDrag(")
    < DOCK_ITEM.index('itemType === "trash" && drop.hasUrls'),
    "Resolved launchers must be routed before trash and ordinary file drops.",
)
require(
    '"launcherContainmentAcceptable"' in DOCK_ITEM
    and '"launcherContainmentRejected"' in DOCK_ITEM
    and '"folder-add-symbolic"' in DOCK_ITEM,
    "Manual and managed containers must expose distinct themed drop feedback.",
)
require(
    "function maintainLauncherDropAcceptance(event)" in DOCK_ITEM
    and "dockItemContainer.maintainLauncherDropAcceptance(drag)" in DOCK_ITEM
    and "DockDropState.launcherDropAcceptance(" in DOCK_ITEM
    and 'case "launcherContainmentAcceptable":' in DOCK_DROP_STATE,
    "Accepted container drops must stay accepted throughout pointer movement.",
)
require(
    "applicationLauncherContainerDropped" in DOCK_ITEM
    and "launcherContainerDropTarget" in DOCK_ITEM
    and "launcherContainerDropEnabled" in DOCK_ITEM,
    "DockItem must emit containment intent without persisting data itself.",
)
require(
    "function addApplicationToManualContainer(" in CONFIG_ITEMS
    and '"managed-container"' in CONFIG_ITEMS
    and '"duplicate"' in CONFIG_ITEMS
    and "containerApplicationIdentityKeys" in CONFIG_ITEMS,
    "Container mutation must be pure, manual-only, and duplicate-safe.",
)
require(
    "function addApplicationLauncherToContainer(" in DOCK_CONTROLLER
    and "canonicalJsonText(currentContainer) !== expectedText" in DOCK_CONTROLLER
    and "commitDockItemsJson(" in DOCK_CONTROLLER,
    "The controller must revalidate the target and commit through the persistence adapter.",
)
container_commit = DOCK_CONTROLLER[
    DOCK_CONTROLLER.index("function addApplicationLauncherToContainer(") :
    DOCK_CONTROLLER.index("function pinAppToDesktop(")
]
commit_call = container_commit.index(
    "root.persistenceAdapter.commitDockItemsJson("
)
commit_success = container_commit.index(
    "root.dockItems = update.items"
)
require(
    commit_call < commit_success
    and "root.runtimeService.persistDockItemsJson(" in container_commit[commit_success:]
    and "root.configurationChanged()" in container_commit[commit_success:],
    "A successful native commit must publish the immutable items to the live controller before reporting success.",
)
require(
    MAIN.count("launcherContainerDropTarget:") == 1
    and 'modelData.type === "folder"' in MAIN
    and '"manual") === "manual"' in MAIN
    and "handleContainerApplicationLauncherDrop(" in MAIN,
    "Only persistent manual folder delegates may accept launcher containment.",
)
container_drop_handler = MAIN[
    MAIN.index("function handleContainerApplicationLauncherDrop(") :
    MAIN.index("function launchConfiguredMediaPlayer(")
]
normalized_container_drop_handler = " ".join(container_drop_handler.split())
require(
    "visualParent, coordinator)" in normalized_container_drop_handler
    and "coordinator.folderPopupDialogRef" in container_drop_handler
    and "popupCoordinator" not in container_drop_handler
    and "mainContainer" not in container_drop_handler,
    "Root drop handlers must receive representation-owned objects explicitly instead of resolving nested ids.",
)
failure_branch = container_drop_handler.index("if (!result.success)")
failure_feedback = container_drop_handler.index(
    "dropFeedbackPopup.presentFeedback(visualParent", failure_branch
)
failure_return = container_drop_handler.index("return", failure_feedback)
success_dismiss = container_drop_handler.index(
    "dropFeedbackPopup.dismissFeedback()", failure_return
)
require(
    failure_branch < failure_feedback < failure_return < success_dismiss
    and "openFolderPopup(" not in container_drop_handler
    and "showPopupDialog(" not in container_drop_handler,
    "Container drops must stay visually silent on success and must never open a dialog during drag and drop.",
)
external_drop_handler = MAIN[
    MAIN.index("function handleApplicationUrlsDrop(") :
    MAIN.index("function handleContainerApplicationLauncherDrop(")
]
require(
    "coordinator.closeAllPopups(null)" in external_drop_handler
    and "popupCoordinator" not in external_drop_handler,
    "Ordinary URL drops must use the same explicit coordinator boundary.",
)
container_drop_binding = MAIN[
    MAIN.index("onExternalUrlsDropped:") :
    MAIN.index("onPersistentReorderPressStarted:")
]
normalized_container_drop_binding = " ".join(container_drop_binding.split())
require(
    "taskState.rows, urls, visualParent, popupCoordinator)"
    in normalized_container_drop_binding
    and "dockItemDelegate.modelData), visualParent, popupCoordinator)"
    in normalized_container_drop_binding,
    "The full representation must pass its coordinator explicitly to both root drop handlers.",
)
require(
    "beginExternalDropActivation()" in DOCK_ITEM
    and "handleApplicationUrlsDrop(" in MAIN
    and 'externalDropState = "acceptable"' in DOCK_ITEM,
    "Ordinary file hover activation and open-with behavior must remain intact.",
)

print("Dock container launcher drop contract: PASS")
