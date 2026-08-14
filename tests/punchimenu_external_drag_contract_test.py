#!/usr/bin/env python3

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
NORMAL = (ROOT / "contents/ui/components/punchimenu/PunchiMenuNormal.qml").read_text()
FULLSCREEN = (ROOT / "contents/ui/components/punchimenu/PunchiMenuOverlay.qml").read_text()
DOCK_ITEM = (ROOT / "contents/ui/components/DockItem.qml").read_text()
DOCK_CONTROLLER = (ROOT / "contents/ui/components/DockItemsController.qml").read_text()
MAIN = (ROOT / "contents/ui/main.qml").read_text()
NATIVE_CONTROLLER = (ROOT / "src/launcherdragcontroller.cpp").read_text()
DRAG_LAYER = (
    ROOT / "contents/ui/components/punchimenu/PunchiMenuDragLayer.qml"
).read_text()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


require(
    NORMAL.count("Kirigami.Separator {") >= 3,
    "PunchiMenu Normal must retain its existing separator and add the two theme separators.",
)
require(
    NORMAL.index("id: btnClose")
    < NORMAL.index("Kirigami.Separator {", NORMAL.index("id: btnClose"))
    < NORMAL.index("id: categoriesView"),
    "The first theme separator must divide the header from categories.",
)
require(
    NORMAL.index("id: categoriesView")
    < NORMAL.index("Kirigami.Separator {", NORMAL.index("id: categoriesView"))
    < NORMAL.index("id: applicationsDropArea"),
    "The second theme separator must divide categories from applications.",
)
require(
    "Punchi.LauncherDragController" in NORMAL
    and "Punchi.LauncherDragController" not in FULLSCREEN,
    "Native launcher drag must remain exclusive to PunchiMenu Normal.",
)
require(
    "handleDragOutsideSurface" in NORMAL
    and "cancelInternalLayoutDrag(true)" in NORMAL,
    "Normal must transition explicitly from internal to native drag without releasing a click.",
)
require(
    "startRejectedFolderDrag" not in NORMAL
    and "startRejectedFolderDrag" not in NATIVE_CONTROLLER
    and "application/x-punchi-rejected-folder" not in NATIVE_CONTROLLER,
    "Folders must never start a modal native drag without an external destination.",
)
require(
    "internalDragLayer.move(position, true)" in NORMAL
    and "visualBounds: root.folderDialogBackdropGeometry" in NORMAL
    and "property bool rejected: false" in DRAG_LAYER
    and "Drag.active: root.active && !root.rejected" in DRAG_LAYER
    and 'source: "dialog-cancel"' in DRAG_LAYER,
    "Folders must collide with the themed menu bounds and remain cancellable in QML.",
)
require(
    'property string dropIntent: "none"' in NORMAL
    and 'dropIntent = "insertBefore"' in NORMAL
    and 'dropIntent = "insertAfter"' in NORMAL
    and 'dropIntent = "group"' in NORMAL
    and "beforeNodeIdForInsertion" in NORMAL
    and "dropGroupingActive" in NORMAL
    and "dropInsertionActive" in NORMAL,
    "Normal must distinguish insertion slots from application grouping targets.",
)
require(
    "id: categoriesView" in NORMAL
    and "Layout.preferredHeight: Kirigami.Units.gridUnit * 2.1" in NORMAL
    and "Layout.alignment: Qt.AlignVCenter" in NORMAL,
    "Category pills and lateral controls must share the same centered height.",
)
require(
    NORMAL.count("highlighted: categoryLeftEdge.highlightedContent") == 1
    and NORMAL.count("highlighted: categoryRightEdge.highlightedContent") == 1
    and NORMAL.count("background: PunchiMenuActionBackground {") >= 6,
    "Category edge controls must use the shared theme-aware action highlight.",
)
search_filter_start = NORMAL.index("function filterAllApplications()")
search_filter_end = NORMAL.index("function requestAllApplications()", search_filter_start)
search_filter = NORMAL[search_filter_start:search_filter_end]
require(
    "const matches = []" in search_filter
    and "searchApplications = matches" in search_filter
    and "visibleApplicationsModel.clear()" not in search_filter
    and "visibleApplicationsModel.append(" not in search_filter,
    "Search must replace one plain result projection instead of rebuilding a QML ListModel row by row.",
)
require(
    'application/x-punchi-launcher' in NATIVE_CONTROLLER
    and "mimeData->setUrls" in NATIVE_CONTROLLER
    and "service->entryPath()" in NATIVE_CONTROLLER,
    "The native controller must publish a verified desktop URL and the Punchi marker MIME type.",
)
require(
    "isPunchiLauncherDrag" in DOCK_ITEM
    and "applicationLauncherDropped" in DOCK_ITEM
    and DOCK_ITEM.index("isPunchiLauncherDrag(drop)")
    < DOCK_ITEM.index('itemType === "trash" && drop.hasUrls'),
    "Launcher drops must be routed before trash and ordinary file drops.",
)
require(
    'externalDropState !== "launcherAcceptable"' in DOCK_ITEM
    and "launcherDropPlaceholderVisible" in DOCK_ITEM
    and "launcherDropReservedExtent" in DOCK_ITEM,
    "Launcher insertion must move the existing frame into a reserved dock slot.",
)
require(
    "Layout.leftMargin: launcherDropPlaceholderVisible" in DOCK_ITEM
    and "Layout.bottomMargin: launcherDropPlaceholderVisible" in DOCK_ITEM
    and "anchors.leftMargin: dockItemContainer.launcherDropPlaceholderVisible" in DOCK_ITEM
    and "anchors.bottomMargin: dockItemContainer.launcherDropPlaceholderVisible" in DOCK_ITEM,
    "The placeholder and drop receiver must cover horizontal and vertical dock gaps.",
)
require(
    "launcherDropTransitionActive" in MAIN
    and 'Release to insert %1 in the Dock' in DOCK_ITEM,
    "Dock neighbors and accessible feedback must describe insertion rather than containment.",
)
require(
    "validateApplicationLauncherDrop" in DOCK_CONTROLLER
    and "pinApplicationLauncherAt" in DOCK_CONTROLLER
    and "pinAppToDockAt" in DOCK_CONTROLLER,
    "Dock persistence must revalidate and insert or move the launcher transactionally.",
)
require(
    MAIN.count("launcherDropValidator: function(urls)") >= 3,
    "Pinned, dynamic and overflow dock targets must share launcher validation.",
)

print("PunchiMenu external drag contract: PASS")
