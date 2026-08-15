#!/usr/bin/env python3

from pathlib import Path
import re
import sys


PROJECT_ROOT = Path(__file__).resolve().parents[1]


def require(source: str, fragment: str, message: str) -> None:
    if fragment not in source:
        raise AssertionError(message)


def qml_object_bodies(source: str, declaration: str) -> list[str]:
    bodies = []
    for match in re.finditer(rf"{re.escape(declaration)}\s*\{{", source):
        opening_brace = source.find("{", match.start())
        depth = 0
        for index in range(opening_brace, len(source)):
            if source[index] == "{":
                depth += 1
            elif source[index] == "}":
                depth -= 1
                if depth == 0:
                    bodies.append(source[opening_brace + 1:index])
                    break
    return bodies


def qml_object_body_by_id(
    source: str, declaration: str, object_id: str
) -> str:
    for body in qml_object_bodies(source, declaration):
        if re.search(rf"\bid:\s*{re.escape(object_id)}\b", body):
            return body
    raise AssertionError(f"Unable to isolate {object_id}")


def popup_body(main_qml: str, popup_id: str, next_popup_id: str) -> str:
    match = re.search(
        rf"GuardedPopupDialog\s*\{{\s*id:\s*{popup_id}\b"
        rf"(?P<body>.*?)\n\s*(?:GuardedPopupDialog|"
        rf"PlasmaCore\.(?:AppletPopup|Dialog))\s*\{{\s*"
        rf"id:\s*{next_popup_id}\b",
        main_qml,
        re.DOTALL,
    )
    if match is None:
        raise AssertionError(f"Unable to isolate {popup_id}")
    return match.group("body")


def assert_widget_surface(
    body: str,
    popup_name: str,
    opacity_source: str = "dockConfig.contextMenuBackgroundOpacity",
) -> None:
    for fragment, message in (
        ("location: dockGeometry.effectivePanelLocation",
         f"{popup_name} must follow the effective panel location"),
        ("ContextSurfaceStack {",
         f"{popup_name} must reuse the shared context surface"),
        ('backgroundImagePath: "widgets/background"',
         f"{popup_name} must use the PunchiMenu themed surface"),
        (opacity_source,
         f"{popup_name} must follow its approved opacity source"),
        ("contentFramePaddingPercent: 2",
         f"{popup_name} must retain the two-percent content frame"),
    ):
        require(body, fragment, message)

    if "backgroundHints: PlasmaCore.AppletPopup.StandardBackground" in body:
        raise AssertionError(f"{popup_name} must not retain a competing host surface")


def main() -> int:
    main_qml = (PROJECT_ROOT / "contents/ui/main.qml").read_text()
    guarded_dialog = (
        PROJECT_ROOT / "contents/ui/components/GuardedPopupDialog.qml"
    ).read_text()
    animated_content = (
        PROJECT_ROOT / "contents/ui/components/PopupAnimatedContent.qml"
    ).read_text()
    popup_coordinator = (
        PROJECT_ROOT / "contents/ui/components/PopupCoordinator.qml"
    ).read_text()
    app_actions_popup = (
        PROJECT_ROOT / "contents/ui/components/AppActionsPopup.qml"
    ).read_text()
    trash_context_popup = (
        PROJECT_ROOT / "contents/ui/components/TrashContextPopup.qml"
    ).read_text()
    trash_menu_popup = (
        PROJECT_ROOT / "contents/ui/components/TrashMenuPopup.qml"
    ).read_text()
    task_overflow_popup = (
        PROJECT_ROOT / "contents/ui/components/TaskOverflowPopup.qml"
    ).read_text()
    dock_configuration = (
        PROJECT_ROOT / "contents/ui/components/DockConfigurationState.qml"
    ).read_text()
    config_menus = (
        PROJECT_ROOT / "contents/ui/config/ConfigMenus.qml"
    ).read_text()
    config_folder_popups = (
        PROJECT_ROOT / "contents/ui/config/ConfigFolderPopups.qml"
    ).read_text()
    config_aspect = (
        PROJECT_ROOT / "contents/ui/config/ConfigAspect.qml"
    ).read_text()
    config_schema = (
        PROJECT_ROOT / "contents/config/main.xml"
    ).read_text()
    folder_popup_component = (
        PROJECT_ROOT / "contents/ui/components/FolderPopup.qml"
    ).read_text()
    config_items = (
        PROJECT_ROOT / "contents/ui/config/ConfigItems.qml"
    ).read_text()
    item_editor = (
        PROJECT_ROOT / "contents/ui/config/ItemEditorPanel.qml"
    ).read_text()
    action_dialog = (
        PROJECT_ROOT / "contents/ui/config/components/ActionDialog.qml"
    ).read_text()
    config_items_form_helper = (
        PROJECT_ROOT / "contents/ui/config/code/configItemsFormHelper.js"
    ).read_text()

    folder_popup = popup_body(main_qml, "folderPopupDialog", "calendarPopupDialog")
    trash_menu = popup_body(main_qml, "trashMenuDialog", "appActionsDialog")
    app_actions = popup_body(main_qml, "appActionsDialog", "notePopupDialog")
    note_popup = popup_body(main_qml, "notePopupDialog", "taskWindowsDialog")
    overflow_popup = qml_object_body_by_id(
        main_qml, "GuardedPopupDialog", "taskOverflowDialog"
    )

    assert_widget_surface(
        folder_popup,
        "Folder popup",
        "dockConfig.folderPopupBackgroundOpacity",
    )
    assert_widget_surface(trash_menu, "Trash menu")
    assert_widget_surface(app_actions, "Application actions menu")
    assert_widget_surface(
        note_popup,
        "Note popup",
        "root.configuredPunchiMenuNormalBackgroundOpacity",
    )
    assert_widget_surface(overflow_popup, "Task overflow popup")
    for fragment, message in (
        ("type: PlasmaCore.Dialog.AppletPopup",
         "Guarded menus must retain the applet-popup window role"),
        ("backgroundHints: PlasmaCore.Dialog.NoBackground",
         "Guarded menus must delegate their background to the content"),
        ("Number(root.sizingItem.implicitWidth) > 0",
         "Guarded menus must reject a non-positive width"),
        ("Number(root.sizingItem.implicitHeight) > 0",
         "Guarded menus must reject a non-positive height"),
        ("Number(root.sizingItem.width) > 0",
         "Guarded menus must validate the real width used by Plasma Dialog"),
        ("Number(root.sizingItem.height) > 0",
         "Guarded menus must validate the real height used by Plasma Dialog"),
        ("function openSafely()",
         "Guarded menus must prepare content before mapping"),
        ("function closeSafely()",
         "Guarded menus must invalidate pending opens"),
    ):
        require(guarded_dialog, fragment, message)
    for fragment, message in (
        ("readonly property real safeImplicitWidth:",
         "Animated popup content must sanitize its real width"),
        ("readonly property real safeImplicitHeight:",
         "Animated popup content must sanitize its real height"),
        ("width: root.safeImplicitWidth",
         "A popup main item must never expose zero real width to Plasma Dialog"),
        ("height: root.safeImplicitHeight",
         "A popup main item must never expose zero real height to Plasma Dialog"),
    ):
        require(animated_content, fragment, message)
    require(folder_popup, "FolderPopup {",
            "Folder profiles must remain inside the shared surface")
    require(
        folder_popup,
        "contentGeometryTransitionsEnabled: false",
        "Folder profiles must expose their final width before Plasma positions "
        "the popup",
    )
    for fragment, message in (
        ('import "punchimenu" as PunchiMenuComponents',
         "Folder popup launchers must import the canonical highlight"),
        ("PunchiMenuComponents.PunchiMenuItemHighlight {",
         "Folder popup launchers must reuse the canonical highlight"),
        ("hovered: itemMouse.containsMouse",
         "Folder popup hover must follow pointer presence"),
        ("focused: itemMouse.activeFocus",
         "Folder popup focus must remain independent from hover"),
        ("pressed: itemMouse.pressed",
         "Folder popup press feedback must remain interruptible"),
        ("motionEnabled: Kirigami.Units.longDuration > 0",
         "Folder popup motion must follow the reduced-motion preference"),
    ):
        require(folder_popup_component, fragment, message)
    require(folder_popup, "folderPopupDialog.closeSafely()",
            "Folder actions must close through the guarded popup path")
    require(trash_menu, "TrashContextPopup {",
            "The trash state machine must remain inside the shared surface")
    for fragment, message in (
        ("Kirigami.Theme.inherit: false",
         "Trash content must not inherit the panel color set"),
        ("Kirigami.Theme.colorSet: Kirigami.Theme.Window",
         "Trash content must use the Window palette"),
    ):
        require(trash_context_popup, fragment, message)
    require(
        trash_menu_popup,
        "property bool textShadowsEnabled: false",
        "Trash action text shadows must remain disabled by default",
    )
    trash_action_labels = qml_object_bodies(
        trash_menu_popup, "PlasmaExtras.ShadowedLabel"
    )
    if len(trash_action_labels) != 2:
        raise AssertionError(
            "Trash actions must retain exactly two themed shadow labels"
        )
    for label in trash_action_labels:
        require(
            label,
            "color: Kirigami.Theme.textColor",
            "Every trash action label must follow the popup theme",
        )
    require(app_actions, "AppActionsPopup {",
            "Application actions must remain inside the shared surface")
    require(note_popup, "NotePopup {",
            "Note content must remain inside the shared surface")
    require(note_popup, "contentFramePaddingScale: 1.5",
            "Note popup must retain its medium visual frame")
    require(note_popup, "notePopupDialog.closeSafely()",
            "Note actions must close through the guarded popup path")
    require(overflow_popup, "TaskOverflowPopup {",
            "Task overflow content must remain inside the shared surface")
    for fragment, message in (
        ("Kirigami.Theme.inherit: false",
         "Task overflow content must not inherit the panel color set"),
        ("Kirigami.Theme.colorSet: Kirigami.Theme.Window",
         "Task overflow content must use the Window palette"),
    ):
        require(task_overflow_popup, fragment, message)
    overflow_labels = qml_object_bodies(
        task_overflow_popup, "PlasmaExtras.ShadowedLabel"
    )
    if len(overflow_labels) != 3:
        raise AssertionError(
            "Task overflow must retain exactly three themed shadow labels"
        )
    for label in overflow_labels:
        require(
            label,
            "color: Kirigami.Theme.textColor",
            "Every task overflow label must follow the selected Plasma theme",
        )
    require(overflow_popup, "taskControllerRef: taskController",
            "Task overflow controls must resolve official window capabilities")
    require(overflow_popup, "taskOverflowDialog.closeSafely()",
            "Task overflow actions must close through the guarded popup path")
    for forbidden in (
        "previewBlurController",
        "Punchi.BlurBehindController",
        "backgroundHints: PlasmaCore.AppletPopup.StandardBackground",
    ):
        if forbidden in overflow_popup:
            raise AssertionError(
                f"Task overflow popup must not retain blur or a competing surface: {forbidden}"
            )
    for fragment, message in (
        ("signal minimizeWindowRequested(int taskRow)",
         "Task overflow must expose direct minimize intent"),
        ("signal maximizeWindowRequested(int taskRow)",
         "Task overflow must expose direct maximize intent"),
        ("signal closeWindowRequested(int taskRow)",
         "Task overflow must expose direct close intent"),
        ("WindowPreviewActionButton {",
         "Task overflow controls must reuse the shared window action primitive"),
        ("visible: entryDelegate.hasSingleWindow",
         "Direct controls must remain scoped to unambiguous single-window rows"),
        ("destructive: true",
         "The direct close control must communicate destructive intent"),
        ("id: overflowScroll",
         "Task overflow must expose a bounded viewport"),
        ("clip: true",
         "Task overflow hover rendering must remain inside its viewport"),
        ("width: overflowScroll.availableWidth",
         "Task overflow rows must exclude the scroll bar from their width"),
        ("boundsBehavior: Flickable.StopAtBounds",
         "Task overflow content must not overshoot the popup bounds"),
        ("readonly property int visibleListHeight:",
         "Task overflow must calculate the complete visible list extent"),
        ("Math.max(0, visibleRows - 1) * rowSpacing",
         "Task overflow height must reserve spacing between visible rows"),
        ("+ contentMargin * 2 + contentSpacing + visibleListHeight",
         "Task overflow height must retain both margins and the header gap"),
        ("readonly property int listBottomReserve: Kirigami.Units.smallSpacing",
         "Task overflow must reserve theme-scaled space below its last row"),
        ("+ listBottomReserve)",
         "Task overflow sizing must include the dedicated lower reserve"),
        ("Layout.bottomMargin: root.listBottomReserve",
         "Task overflow viewport must expose the dedicated lower reserve"),
        ("readonly property int headerTopReserve: listBottomReserve",
         "Task overflow must keep its additional vertical reserves symmetric"),
        ("+ headerTopReserve + listBottomReserve)",
         "Task overflow sizing must include both vertical edge reserves"),
        ("Layout.topMargin: root.headerTopReserve",
         "Task overflow header must expose the dedicated upper reserve"),
        ("anchors.margins: root.contentMargin",
         "Task overflow layout must consume the same margin used by sizing"),
        ("spacing: root.contentSpacing",
         "Task overflow layout must consume the same header gap used by sizing"),
    ):
        require(task_overflow_popup, fragment, message)
    for fragment, message in (
        ("function showPopupDialog(dialog)",
         "PopupCoordinator must centralize guarded menu opening"),
        ('typeof dialog.openSafely === "function"',
         "PopupCoordinator must prefer the guarded opening path"),
        ("function hidePopupDialog(dialog)",
         "PopupCoordinator must centralize pending-open cancellation"),
        ('typeof dialog.closeSafely === "function"',
         "PopupCoordinator must prefer the guarded closing path"),
    ):
        require(popup_coordinator, fragment, message)
    require(popup_coordinator, "root.showPopupDialog(notePopupDialogRef)",
            "Note popup opening must use the guarded popup path")
    require(popup_coordinator, "root.showPopupDialog(folderPopupDialogRef)",
            "Folder popup opening must use the guarded popup path")
    require(popup_coordinator, "root.showPopupDialog(taskOverflowDialogRef)",
            "Task overflow opening must use the guarded popup path")

    if "PlasmaCore.AppletPopup.NoBackground" in main_qml:
        raise AssertionError(
            "AppletPopup does not expose NoBackground in the public Plasma 6 API"
        )

    for fragment, message in (
        ("readonly property int actionViewportHeight: visibleRows * effectiveRowHeight",
         "The action viewport must contain an integer number of rows"),
        ("Layout.minimumHeight: appActionsRoot.actionViewportHeight",
         "The action viewport must not contract into a partial row"),
        ("Layout.maximumHeight: appActionsRoot.actionViewportHeight",
         "The action viewport must not expand into the next row"),
        ("implicitHeight: chromeHeight + actionViewportHeight",
         "The popup height must use the exact chrome and action viewport"),
    ):
        require(app_actions_popup, fragment, message)

    for fragment, message in (
        ("Kirigami.Theme.inherit: false",
         "Application actions must not inherit the panel color set"),
        ("Kirigami.Theme.colorSet: Kirigami.Theme.Window",
         "Application actions must use the Window palette"),
        ("property bool textShadowsEnabled: false",
         "Application action text shadows must remain disabled by default"),
    ):
        require(app_actions_popup, fragment, message)
    app_action_labels = qml_object_bodies(
        app_actions_popup, "PlasmaExtras.ShadowedLabel"
    )
    if len(app_action_labels) != 3:
        raise AssertionError(
            "Application actions must retain exactly three themed shadow labels"
        )
    for label in app_action_labels:
        require(
            label,
            "color: Kirigami.Theme.textColor",
            "Every application action label must follow the popup theme",
        )

    require(config_menus, "to: 15",
            "The menu KCM must allow up to fifteen visible actions")
    require(dock_configuration, "Math.max(3, Math.min(15,",
            "Runtime configuration must accept up to fifteen visible actions")
    for source, fragment, message in (
        (config_schema,
         '<entry name="contextMenuBackgroundOpacityPercent" type="Int">',
         "Context menu opacity must be persisted in KConfig"),
        (config_menus,
         "cfg_contextMenuBackgroundOpacityPercent",
         "The menu KCM must own context menu opacity"),
        (config_menus,
         "id: contextMenuBackgroundOpacitySlider",
         "The menu KCM must expose an opacity slider"),
        (config_aspect,
         "cfg_contextMenuBackgroundOpacityPercent",
         "Appearance KCM must forward context menu opacity"),
        (dock_configuration,
         "readonly property real contextMenuBackgroundOpacity:",
         "Runtime configuration must expose normalized context menu opacity"),
    ):
        require(source, fragment, message)
    for source, fragment, message in (
        (config_schema,
         '<entry name="folderPopupBackgroundOpacityPercent" type="Int">',
         "Folder opacity must be persisted in KConfig"),
        (config_folder_popups,
         "cfg_folderPopupBackgroundOpacityPercent",
         "Folder popup KCM must own the opacity setting"),
        (config_folder_popups,
         "id: folderPopupBackgroundOpacitySlider",
         "Folder popup KCM must expose an opacity slider"),
        (config_aspect,
         "cfg_folderPopupBackgroundOpacityPercent",
         "Appearance KCM must forward the folder opacity setting"),
        (dock_configuration,
         "readonly property real folderPopupBackgroundOpacity:",
         "Runtime configuration must expose normalized folder opacity"),
    ):
        require(source, fragment, message)

    for fragment, message in (
        ("Kirigami.Theme.inherit: false",
         "Folder popup content must not inherit the panel color set"),
        ("Kirigami.Theme.colorSet: Kirigami.Theme.Window",
         "Folder popup content must use the Window palette"),
        ("property bool textShadowsEnabled: false",
         "Folder popup text shadows must remain disabled by default"),
    ):
        require(folder_popup_component, fragment, message)

    shadowed_labels = qml_object_bodies(
        folder_popup_component, "PlasmaExtras.ShadowedLabel"
    )
    if len(shadowed_labels) != 3:
        raise AssertionError(
            "Folder popup must retain exactly three themed shadow labels"
        )
    for label in shadowed_labels:
        require(
            label,
            "color: Kirigami.Theme.textColor",
            "Every folder popup shadow label must follow the active theme",
        )

    for source, stale_fragment, message in (
        (config_items, "showContainerLabelsText",
         "ConfigItems must not expose the obsolete per-folder label toggle"),
        (item_editor, "folderShowLabels",
         "The folder item editor must not render the obsolete label toggle"),
        (item_editor, "showContainerLabelsText",
         "The folder item editor must not retain obsolete label text plumbing"),
        (action_dialog, "containerShowLabelsChecked",
         "ActionDialog must not retain obsolete label state plumbing"),
        (action_dialog, "showContainerLabelsText",
         "ActionDialog must not retain obsolete label text plumbing"),
        (config_items_form_helper, "containerShowLabelsChecked",
         "The item form helper must not read or write obsolete label state"),
    ):
        if stale_fragment in source:
            raise AssertionError(message)
    require(config_folder_popups, "id: showLabelsCheck",
            "Folder profile settings must remain the single label authority")
    require(
        config_schema,
        '<entry name="popupTextShadowsEnabled" type="Bool">\n'
        "      <default>false</default>",
        "Popup text shadows must remain disabled in new configurations",
    )
    require(
        dock_configuration,
        "Plasmoid.configuration.popupTextShadowsEnabled === true",
        "Runtime popup text shadows must remain opt-in",
    )
    require(
        config_schema,
        '<entry name="menuTextShadowsEnabled" type="Bool">\n'
        "      <default>false</default>",
        "Menu text shadows must remain disabled in new configurations",
    )
    require(
        dock_configuration,
        "Plasmoid.configuration.menuTextShadowsEnabled === true",
        "Runtime menu text shadows must remain opt-in",
    )

    print("Popup menu surface contracts are consistent")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as error:
        print(f"popup menu surface contract failed: {error}", file=sys.stderr)
        raise SystemExit(1)
