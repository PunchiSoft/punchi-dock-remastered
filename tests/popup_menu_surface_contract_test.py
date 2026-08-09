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
    opacity_source: str = "root.configuredPunchiMenuNormalBackgroundOpacity",
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

    assert_widget_surface(
        folder_popup,
        "Folder popup",
        "dockConfig.folderPopupBackgroundOpacity",
    )
    assert_widget_surface(trash_menu, "Trash menu")
    assert_widget_surface(app_actions, "Application actions menu")
    assert_widget_surface(note_popup, "Note popup")
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
    require(folder_popup, "folderPopupDialog.closeSafely()",
            "Folder actions must close through the guarded popup path")
    require(trash_menu, "TrashContextPopup {",
            "The trash state machine must remain inside the shared surface")
    require(app_actions, "AppActionsPopup {",
            "Application actions must remain inside the shared surface")
    require(note_popup, "NotePopup {",
            "Note content must remain inside the shared surface")
    require(note_popup, "contentFramePaddingScale: 1.5",
            "Note popup must retain its medium visual frame")
    require(note_popup, "notePopupDialog.closeSafely()",
            "Note actions must close through the guarded popup path")
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

    require(config_menus, "to: 15",
            "The menu KCM must allow up to fifteen visible actions")
    require(dock_configuration, "Math.max(3, Math.min(15,",
            "Runtime configuration must accept up to fifteen visible actions")
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

    print("Popup menu surface contracts are consistent")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as error:
        print(f"popup menu surface contract failed: {error}", file=sys.stderr)
        raise SystemExit(1)
