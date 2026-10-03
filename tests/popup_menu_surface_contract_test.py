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
        rf"GuardedPopupDialog\s*\{{\s*"
        rf"id:\s*{popup_id}\b(?P<body>.*?)\n\s*"
        rf"(?:GuardedPopupDialog|PlasmaCore\.(?:AppletPopup|Dialog))\s*\{{\s*"
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
    adaptive_margin_source: str = "",
) -> None:
    required_fragments = [
        ("ContextSurfaceStack {",
         f"{popup_name} must reuse the shared context surface"),
        ('backgroundImagePath: "widgets/background"',
         f"{popup_name} must use the PunchiMenu themed surface"),
        (opacity_source,
         f"{popup_name} must follow its approved opacity source"),
        ("contentFramePaddingPercent: 2",
         f"{popup_name} must retain the two-percent content frame"),
    ]
    if adaptive_margin_source:
        required_fragments.extend((
            ("panelLocation: dockGeometry.effectivePanelLocation",
             f"{popup_name} must follow the resolved dock edge"),
            (f"popupGap: {adaptive_margin_source}",
             f"{popup_name} must consume its adaptive gap"),
            ("floatingDockAnchor: root.floatingDockAnchor",
             f"{popup_name} must use the floating dock surface"),
            ("panelWindow: root.Window.window",
             f"{popup_name} must use the complete panel surface"),
        ))
    else:
        required_fragments.append((
            "location: dockGeometry.effectivePanelLocation",
            f"{popup_name} must follow the effective panel location",
        ))
    for fragment, message in required_fragments:
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
    dock_geometry = (
        PROJECT_ROOT / "contents/ui/components/DockGeometryState.qml"
    ).read_text()
    popup_spacing_metrics = (
        PROJECT_ROOT / "contents/ui/components/PopupSpacingMetrics.qml"
    ).read_text()
    dock_background = (
        PROJECT_ROOT / "contents/ui/components/DockBackground.qml"
    ).read_text()
    context_surface_stack = (
        PROJECT_ROOT / "contents/ui/components/ContextSurfaceStack.qml"
    ).read_text()
    compact_menu = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuCompact.qml"
    ).read_text()
    normal_placement = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuNormalPlacement.qml"
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
    folder_fan_view = (
        PROJECT_ROOT / "contents/ui/components/FolderFanView.qml"
    ).read_text()
    text_shadow_label = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuTextShadowLabel.qml"
    ).read_text()
    items_controller = (
        PROJECT_ROOT / "contents/ui/components/DockItemsController.qml"
    ).read_text()
    config_items = (
        PROJECT_ROOT / "contents/ui/config/ConfigItems.qml"
    ).read_text()
    item_editor = (
        PROJECT_ROOT / "contents/ui/config/ItemEditorPanel.qml"
    ).read_text()
    item_action_editor = (
        PROJECT_ROOT / "contents/ui/config/ItemActionEditor.qml"
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
    require(folder_popup, "gap: dockGeometry.folderPopupGap",
            "Folder popup must consume the configured distance")
    require(folder_popup, "NativePopupSpacing {",
            "Folder popup must retain native positioning with a spacing anchor")
    require(folder_popup, "sourceAnchor: folderPopupDialog.sourceAnchor",
            "Folder popup must preserve the original launcher identity")
    require(folder_popup, "preserveHorizontalAnchorCenter: true",
            "All folder profiles must remain anchored horizontally near the screen center")
    assert_widget_surface(
        trash_menu,
        "Trash menu",
    )
    require(trash_menu, "gap: dockGeometry.contextMenuGap",
            "Trash menu must consume the configured menu distance")
    require(trash_menu, "NativePopupSpacing {",
            "Trash menu must retain native positioning with a spacing anchor")
    require(trash_menu, "sourceAnchor: trashMenuDialog.sourceAnchor",
            "Trash menu must preserve the original launcher identity")
    assert_widget_surface(
        app_actions,
        "Application actions menu",
    )
    require(app_actions, "gap: dockGeometry.contextMenuGap",
            "Application actions menu must consume the configured menu distance")
    require(app_actions, "NativePopupSpacing {",
            "Application actions menu must retain native positioning with a spacing anchor")
    require(app_actions, "sourceAnchor: appActionsDialog.sourceAnchor",
            "Application actions menu must preserve the original launcher identity")
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
        ("function backgroundFrameInset(side)",
         "The floating Dock background must expose its effective frame inset"),
        ('id: panelBackground',
         "The translucent Dock frame must be addressable for placement"),
        ('id: solidPanelBackground',
         "The opaque Dock frame must be addressable for placement"),
    ):
        require(dock_background, fragment, message)
    for source, fragment, message in (
        (normal_placement,
         "Math.max(0, Math.round(Kirigami.Units.smallSpacing))",
         "Panel popups must derive their minimum gap from a theme metric"),
        (normal_placement,
         "? Math.max(root.minimumPanelGap, requestedGap)",
         "Only panel placement must enforce the themed minimum gap"),
        (normal_placement, "property real horizontalAnchorWidth: menuWidth",
         "Popup placement must default horizontal anchoring to the full window"),
        (compact_menu, "readonly property real primarySurfaceWidth:",
         "Compact PunchiMenu must expose its stable primary surface width"),
        (main_qml,
         "horizontalAnchorWidth: punchiMenuCompact.primarySurfaceWidth",
         "Compact PunchiMenu must anchor its primary surface instead of its flyout"),
    ):
        require(source, fragment, message)
    require(
        context_surface_stack,
        "function effectiveBackgroundWindowRect()",
        "Popup placement must measure its themed surface in window-client coordinates",
    )
    require(
        context_surface_stack,
        "backgroundBlurMaskSource: menuBackground",
        "The blur region must keep reading the background frame",
    )
    popup_tail = (
        PROJECT_ROOT / "contents/ui/components/FolderPopupTail.qml"
    ).read_text()
    require(
        popup_tail,
        "fillColor: Kirigami.Theme.backgroundColor",
        "The tail fill must come from the theme background colour",
    )
    require(
        popup_tail,
        "readonly property real safeAnchorExtent:",
        "The tail must normalize the live dock item extent",
    )
    require(
        popup_tail,
        "readonly property real tailWidthRatio: 0.55",
        "The compact tail width must stay a share of its dock item",
    )
    require(
        popup_tail,
        "layer.samples: 8",
        "The drawn triangle must share the multisampled pass of the shaped surfaces",
    )
    require(
        popup_tail,
        "readonly property real tailDepthRatio: 0.55",
        "The compact tail depth must stay a ratio of its base",
    )
    require(
        popup_tail,
        "root.safeAnchorExtent * root.tailWidthRatio)",
        "The tail base must follow that share, never a fixed length",
    )
    require(
        popup_tail,
        "readonly property real tipRadiusRatio: 0.08",
        "The compact tip radius must be independent of frame insets",
    )
    if "cornerRadius" in popup_tail:
        raise AssertionError(
            "Frame insets must not be reused as the tail corner radius")
    require(
        popup_tail,
        "PathSvg {",
        "The tail outline must be drawn as a vector path",
    )
    require(
        popup_tail,
        "readonly property real windowGrowth: Math.max(0,",
        "The surface must grow only by the part of the tail outside the frame",
    )
    require(
        popup_tail,
        "readonly property var blurRegionPolygon:",
        "The tail must publish the same silhouette for the KWin blur region",
    )
    require(
        context_surface_stack,
        "backgroundBlurAdditionalMaskPolygon:",
        "The shared surface must expose the optional tail blur polygon",
    )
    for fragment, message in (
        ('menuBackground.y + root.backgroundFrameInset("top")',
         "The tail band must start at the effective background edge"),
        ('menuBackground.x + root.backgroundFrameInset("left")',
         "The tail band must start at the effective background edge"),
        ("z: menuBackground.z + 1",
         "The tail must join the card edge over the frame shadow strip"),
    ):
        require(context_surface_stack, fragment, message)
    require(
        popup_tail,
        'root.command("L", tipLeft)',
        "The flank must run straight from the base corner to the tip",
    )
    if "neckLeft" in popup_tail:
        raise AssertionError(
            "The tail must not carry the reverted neck in its outline")
    require(
        popup_tail,
        'root.command("Q", apex)',
        "Only the tip of the triangle must be curved",
    )
    require(
        popup_tail,
        'root.command("M", baseLeft)',
        "The triangle base must start on the card edge, with sharp corners",
    )
    for fragment, message in (
        ("Accessible.ignored: true",
         "The decorative tail must stay out of accessibility"),
    ):
        require(popup_tail, fragment, message)
    if re.search(r"KSvg\.FrameSvgItem\s*\{\s*id:\s*lobe", popup_tail):
        raise AssertionError(
            "The tail must not go back to a frame lobe without junction curves")
    for fragment, message in (
        ("property bool edgeTailEnabled: false",
         "The tail must stay disabled for the popups sharing the surface"),
        ("readonly property real edgeTailExtent: root.edgeTailPresent",
         "The reserved band must follow the tail length"),
        ("visible: root.edgeTailPresent",
         "The band must be hidden unless the surface asked for a tail"),
        ("clip: true",
         "The band must keep the buried half of the tail off the card"),
        ("frameInsetLeft: menuBackground.inset.left",
         "The tail must be composed from the background frame insets"),
        ("surfaceOpacity: menuBackground.opacity",
         "The tail must share the background opacity"),
        ("height: root.surfaceContentHeight + root.contentFramePadding * 2",
         "The background frame must keep its own size when a band is reserved"),
    ):
        require(context_surface_stack, fragment, message)
    # The tail belongs to the three classic presentations of the folder popup.
    # The accepted layouts are listed one by one on purpose: a layout added later
    # must not inherit the tail without a review, and the fan never receives it.
    tail_binding_match = re.search(
        r"edgeTailEnabled:(?P<value>.*?)edgeTailLocation:",
        main_qml,
        re.DOTALL,
    )
    if tail_binding_match is None:
        raise AssertionError(
            "The folder surface must enable the tail right before its side")
    tail_binding = tail_binding_match.group("value")
    for layout_mode in ("grid", "list", "detailed"):
        if f'"{layout_mode}"' not in tail_binding:
            raise AssertionError(
                f"The {layout_mode} presentation must receive the folder tail")
    if '"fan"' in tail_binding:
        raise AssertionError(
            "The fan presentation must stay out of the tail: it draws no card "
            "background of its own and its alignment belongs to its arc")
    if "indexOf(" not in tail_binding or "layoutMode" not in tail_binding:
        raise AssertionError(
            "The tail must be enabled from an explicit list of folder layouts")
    if "===" in tail_binding or "!==" in tail_binding:
        raise AssertionError(
            "The tail must not be enabled by excluding the fan: an unknown "
            "layout would inherit it without a review")
    require(
        main_qml,
        "edgeTailLocation: dockGeometry.spectrumOriginEdge",
        "The tail must leave from the dock edge",
    )
    require(
        main_qml,
        "edgeTailAnchorExtent: folderPopupDialog.sourceAnchor",
        "The tail must stay proportional to the dock item it points at",
    )
    require(
        main_qml,
        "folderSurfaceStack.backgroundBlurAdditionalMaskPolygon",
        "The folder popup controller must unite the tail with its blur region",
    )
    if re.search(r"edgeTailLocation:\s*folderPopupAnimatedContent\b", main_qml):
        raise AssertionError(
            "The tail side must not follow the direction the popup grows toward")
    if main_qml.count("edgeTailEnabled:") != 1:
        raise AssertionError(
            "The tail must stay scoped to the folder popup surface only, so "
            "every other consumer of the shared surface keeps it disabled")
    if main_qml.count("additionalMaskPolygon:") != 1:
        raise AssertionError(
            "Only the folder popup blur controller may unite the tail "
            "silhouette with its blur region")
    tail_instantiations = sorted(
        path.relative_to(PROJECT_ROOT).as_posix()
        for path in (PROJECT_ROOT / "contents/ui").rglob("*.qml")
        if "FolderPopupTail {" in path.read_text()
    )
    if tail_instantiations != ["contents/ui/components/ContextSurfaceStack.qml"]:
        raise AssertionError(
            "The three classic presentations must share a single tail "
            f"component, found in: {tail_instantiations}")
    if "i18n" in popup_tail:
        raise AssertionError(
            "The decorative tail must not carry visible text of its own")
    config_xml = (PROJECT_ROOT / "contents/config/main.xml").read_text()
    if re.search(r"(?<![A-Za-z])tail(?![A-Za-z])", config_xml, re.IGNORECASE):
        raise AssertionError(
            "The tail must not introduce a configuration key")
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
    folder_popup_component = (
        PROJECT_ROOT / "contents/ui/components/FolderPopup.qml"
    ).read_text()
    require(
        folder_popup_component,
        "horizontalAlignment: Text.AlignHCenter",
        "The folder popup title must be centered on the popup",
    )
    require(
        folder_popup_component,
        "font.weight: Font.DemiBold",
        "The popup labels must share the weight the fan labels use",
    )
    folder_popup_config_page = (
        PROJECT_ROOT / "contents/ui/config/ConfigFolderPopups.qml"
    ).read_text()
    require(
        folder_popup_config_page,
        "stepSize: 0.05",
        "The folder popup scale must move in five percent steps",
    )
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
        ("move: Transition {",
         "Folder popup model moves must animate declaratively"),
        ("moveDisplaced: Transition {",
         "Folder popup neighbours must follow model moves"),
        ("PunchiMenuComponents.PunchiMenuItemHighlight {",
         "Folder popup launchers must reuse the canonical highlight"),
        ("hovered: itemMouse.containsMouse",
         "Folder popup hover must follow pointer presence"),
        ("focused: itemMouse.activeFocus",
         "Folder popup focus must remain independent from hover"),
        ("pressed: itemMouse.pressed",
         "Folder popup press feedback must remain interruptible"),
        ("motionEnabled: folderRoot.motionEnabled",
         "Folder popup motion must follow the reduced-motion preference"),
        ("transformSelf: false",
         "Folder popup delegates must not duplicate the canonical highlight transform"),
    ):
        require(folder_popup_component, fragment, message)
    for fragment, message in (
        ("ListView {",
         "The fan view must virtualize the entries it shows"),
        ("curveOffsetForItem(itemY)",
         "The fan curve must be derived from viewport geometry"),
        ("rowLeanForItem(itemY)",
         "The fan must lean each row along its arc, not only shift it"),
        ("rowArcStepDegrees",
         "The fan must derive the lean of a row from the angular step of the "
         "arc"),
        ("rowSagPerPitch",
         "The fan must derive its sag from the same angular step as its lean"),
        ("radius: root.highlightRadius",
         "The fan highlight must adopt the text curvature"),
        ("highlightRadius: labelHeight / 2",
         "The fan highlight radius must be derived, not fixed"),
        ("objectName: \"folderFanPill-\" + fanDelegate.index",
         "Every fan entry must carry its own labelled pill"),
        ("radius: height / 2",
         "A fan pill must hug its own text with a full pill radius"),
        ("origin.x: fanContent.iconX + root.iconSize / 2",
         "A fan row must turn about the centre of its own icon"),
        ("rowAir",
         "The fan must declare the air between two rows"),
        ("preferredRowHeight",
         "The fan must expose the pitch its rows need"),
        ("source: \"go-next-symbolic\"",
         "The closing row must point towards the container it opens"),
        ("revealProgressForDistance(",
         "The fan reveal must sweep along its arc instead of by row order"),
        ("property real revealSweepShare:",
         "The fan sweep must stay a declared, tunable share"),
        ("rowSagPerPitchSquared",
         "The fan arc must keep the second order of its own angular step"),
        ("PunchiMenuComponents.PunchiMenuItemHighlight {",
         "Fan launchers must reuse the canonical interaction surface"),
        ("focused: fanDelegate.visualFocus",
         "Fan focus indication must follow keyboard-visible focus"),
        ("acceptedButtons: Qt.LeftButton | Qt.RightButton",
         "Fan launchers must expose their application context menu"),
        ("Keys.onEscapePressed:",
         "The fan view must support keyboard dismissal"),
        ("root.focusItem(fanDelegate.index + 1",
         "The fan view must support predictable keyboard navigation"),
        ("naturalLabelWidth:",
         "Fan label capsules must follow their own text width"),
        ("distanceFromOrigin",
         "The fan curve must open progressively from the panel-facing item"),
        ("leadingOverhang",
         "The fan must reserve the flight its pills take at the end the arc "
         "opens to"),
        ("trailingOverhang",
         "The fan must reserve the flight at the other end too, for the popups "
         "that open downwards"),
        ("bandHeight",
         "The fan must declare the band its own rows occupy"),
        ("topMargin: root.leadingOverhang",
         "The reserve of the far end must be content of the list, so the list "
         "paints it instead of wasting it as a half row"),
        ("bottomMargin: root.trailingOverhang",
         "The reserve of a popup opening downwards must be content of the list "
         "as well"),
        ("envelopeForRows(",
         "The fan must measure its reserve for the row count it shows"),
        ("settleAtBeginning(",
         "The fan must rest with its band placed after the reserve"),
        ("maximumContentHeight",
         "The fan must accept the height its popup can really offer"),
        ("overflowItemCount",
         "The fan must know how many entries exceed its visible area"),
        ("omittedItemCount",
         "The fan must know how many entries the effective model really "
         "leaves out"),
        ("displayedApps",
         "The fan must expose the model its list consumes"),
        ("displayedItemCount",
         "The fan must separate the entries it keeps from the total"),
        ("effectiveScrollEnabled",
         "The fan must separate the requested scroll from the effective one"),
        ("model: root.displayedApps",
         "The list must consume the effective model, not the whole array"),
        ("interactive: root.effectiveScrollEnabled",
         "A static fan must refuse the wheel, the touchpad and drag"),
        ("property bool scrollEnabled: false",
         "The fan must be static unless the preference turns scrolling on"),
        ("focusStepFromLocationAction(",
         "The closing row must take part in the keyboard ring"),
        ("focusLocationAction(",
         "The fan must be able to move the focus to the closing row"),
        ("reconcileAfterModelChange(",
         "A change of the effective model must keep a valid current row"),
        ('i18ncp("@item:inlistbox closing row of the folder fan"',
         "The closing row must count what it leaves out, with plurals"),
        ('"%1 more in %2"',
         "The count of the closing row must name where it opens"),
        ("folderOpenerName",
         "The fan must receive the file manager that opens a container"),
        ("openActionLabelText",
         "The closing row must keep a short label for the folder it opens"),
        ('i18nc("@action:button open the container", "Open")',
         "The short label of the closing row must stay translatable"),
        ('"Open this folder in the file manager"',
         "The closing row must describe its action for readers"),
        ("actionCaptionProbe",
         "The reserved width must be measured from the text the row can show"),
        ("Math.max(actionCaptionWidth,",
         "The closing row must never be narrower than its own text"),
        ("PunchiMenuComponents.PunchiMenuTextShadowLabel",
         "The labels of the fan must take the graduated shadow of the popups"),
        ("shadowPercent: root.textShadowPercent",
         "The fan must take the amount of the shadow from the configuration"),
    ):
        require(folder_fan_view, fragment, message)
    if "hiddenItemCount" in folder_fan_view:
        raise AssertionError(
            "The fan must separate the entries that exceed its visible area "
            "from the ones the effective model really omits: a single "
            "hiddenItemCount conflated both"
        )
    if "rowBleed" in folder_fan_view:
        raise AssertionError(
            "The fan must not keep one symmetric bleed for the whole fan: the "
            "flight belongs to the end the arc opens to"
        )
    if "Open in Dolphin" in folder_fan_view:
        raise AssertionError(
            "The closing row of the fan must keep its short label: the "
            "descriptive phrase belongs to the chrome row of the other "
            "presentations"
        )
    if "renderShadow: root.textShadowsEnabled" in folder_fan_view:
        raise AssertionError(
            "A label of the fan must not enable the fixed texture shadow of the "
            "shared label: the amount belongs to the configuration"
        )
    # All presentations integrate the location action into their collection.
    # The file manager name and glyph remain shared across presentations.
    for fragment, message in (
        ('i18nc("@action:button open the folder in the file manager"',
         "The location action must name the file manager that opens a folder"),
        ("folderOpenerName.length > 0",
         "The location action must name the file manager the desktop resolved"),
        ('? "folderOpenLocationGlyph"',
         "The list action must show the glyph of the reference"),
        ('? "folderOpenLocationArrow"',
         "The list action must carry the arrow of the reference"),
        ('"_punchiOpenLocationAction": true',
         "Grid must append a marked location action to its visual model"),
        ('? "folderGridOpenLocationAction"',
         "Grid must expose the location action as a normal final delegate"),
        ('objectName: "folderGridOpenLocationArrow"',
         "The Grid action must carry the arrow from the reference"),
        ("readonly property int openLocationRowHeight: 0",
         "The location action must not reserve a fixed footer"),
        ("? folderRoot.listItems : folderRoot.apps",
         "List and Detailed must consume the presentation model for folders"),
    ):
        require(folder_popup_component, fragment, message)
    for retired_footer in ("folderOpenLocationIcon", "openLocationSlot",
                           "separateLocationRowActive"):
        if retired_footer in folder_popup_component:
            raise AssertionError("The folder popup must not retain its separate footer")
    # The presentation model is a typed property rather than a visual child.
    models = qml_object_bodies(folder_popup_component, "Punchi.FolderPopupEntriesModel")
    if len(models) != 1:
        raise AssertionError("The list action must share one presentation model")
    for fragment, message in (
        ("sourceModel: folderRoot.directoryModel",
         "Native folder rows must stay connected to their source"),
        ("appendOpenLocation: folderRoot.folderPathAvailable",
         "Only a folder with a location may append its opening action"),
        ('&& (folderRoot.layoutMode === "list" || folderRoot.layoutMode === "detailed")',
         "Only List and Detailed may use the list presentation adapter"),
    ):
        require(models[0], fragment, message)
    delegate = qml_object_body_by_id(folder_popup_component, "Item", "appDelegate")
    require(delegate, "folderRoot.openLocationRequested(folderRoot.folderPath)",
            "The location row must request the current folder through the shared delegate")
    pointer = qml_object_body_by_id(delegate, "MouseArea", "itemMouse")
    for fragment, message in (
        ("cursorShape: Qt.PointingHandCursor", "The collection action must show the hand cursor"),
        ('"folderOpenLocationAction"', "The list action must expose its pointer delegate"),
        ("Accessible.role: Accessible.Button", "The location action must remain an accessible button"),
        ("Accessible.name: appDelegate.displayName", "The action must expose its visible caption"),
        ('"Open this folder in the file manager"', "The action must describe its purpose accessibly"),
        ("Keys.onReturnPressed: appDelegate.activate()", "Return must activate the collection row"),
        ("Keys.onEnterPressed: appDelegate.activate()", "Enter must activate the collection row"),
        ("Keys.onSpacePressed: appDelegate.activate()", "Space must activate the collection row"),
        ("appDelegate.activate()", "Pointer activation must use the shared collection action"),
    ):
        require(pointer, fragment, message)
    # The fan retains its existing control and cursor contract.
    opening_rows = [body for body in qml_object_bodies(folder_fan_view, "Controls.ItemDelegate")
                    if "openLocationRequested" in body]
    if not opening_rows:
        raise AssertionError("The folder fan must keep the row that opens the container")
    for body in opening_rows:
        require(body, "cursorShape: Qt.PointingHandCursor",
                "The closing row of the folder fan must show the hand cursor")
    require(
        folder_popup_component,
        'visible: folderRoot.layoutMode === "fan"',
        "FolderPopup must instantiate the dedicated fan presentation",
    )
    for fragment, message in (
        ("classicContentHeight: layoutMode === \"fan\"",
         "The folder popup must take the fan height from the fan itself"),
        ("Math.ceil(fanView.implicitHeight)",
         "The folder popup must not add a second reserve on top of the one the "
         "fan already keeps"),
        ("maximumContentHeight: folderRoot.layoutMode === \"fan\"",
         "The folder popup must hand the fan the height it can offer"),
        ("folderOpenerName: folderRoot.folderOpenerName",
         "The folder popup must hand the fan the file manager it opens with"),
        ("fanContentCeiling",
         "The folder popup must hold the fan to the height the display offers"),
        ("property bool profileFanScrollEnabled: false",
         "The folder popup must carry the fan scroll preference"),
        ("scrollEnabled: folderRoot.profileFanScrollEnabled",
         "The folder popup must hand the fan the scroll preference"),
    ):
        require(folder_popup_component, fragment, message)
    require(
        main_qml,
        "maximumSurfaceHeight: dockGeometry.folderFanAvailableHeight",
        "The folder popup must receive the height the display really offers",
    )
    require(
        main_qml,
        "folderOpenerName: dockItemsController.folderOpenerName",
        "The folder popup must receive the name of the file manager",
    )
    require(
        items_controller,
        "readonly property string folderOpenerName",
        "The items controller must expose the file manager in use",
    )
    for fragment, message in (
        ('folderPopupContent.layoutMode !== "fan"',
         "The Fan presentation must not draw a general themed surface"),
        ('backgroundBlurEnabled:\n'
         '                        folderPopupContent.layoutMode !== "fan"',
         "The folder surface must explicitly disable Fan blur"),
        ("horizontalAnchorOffset:",
         "The native popup anchor must support an internal Fan origin"),
        ("folderPopupContent.fanOriginIconCenterX",
         "The Fan origin must remain aligned with the dock launcher"),
    ):
        require(folder_popup, fragment, message)
    for fragment, message in (
        ('"Fan"), "value": "fan"',
         "The folder KCM must expose the fan profile"),
        ("cfg_folderFanIconSize",
         "The folder KCM must persist fan icon sizing"),
        ("cfg_folderFanRows",
         "The folder KCM must persist the fan visible-row limit"),
        ("cfg_folderFanScrollEnabled",
         "The folder KCM must persist the fan scroll preference"),
        ('id: fanScrollCheck\n'
         '            objectName: "fanScrollCheck"\n'
         '            visible: page.activeProfile === "fan"',
         "The fan scroll switch must be offered only for the fan profile"),
        ('i18n("Allow scrolling in the fan")',
         "The fan scroll switch must keep its translatable label"),
        (
            'i18n("When disabled, the fan shows only the configured number '
            'of items. Use the final row to open the remaining items in the '
            'file manager.")',
            "The fan scroll switch must explain what it governs",
        ),
        ("from: 24\n                to: 64\n                stepSize: 2",
         "The folder icon size must keep the granularity of the dock icon size"),
    ):
        require(config_folder_popups, fragment, message)
    for fragment, message in (
        ('name="folderFanIconSize"',
         "KConfig must declare the fan icon profile"),
        ('name="folderFanRows"',
         "KConfig must declare the fan row profile"),
        ('name="folderFanScrollEnabled"',
         "KConfig must declare the fan scroll preference"),
        ('<entry name="folderFanScrollEnabled" type="Bool">\n'
         '      <default>false</default>',
         "The fan scroll preference must be a Bool that defaults to false"),
    ):
        require(config_schema, fragment, message)
    require(
        config_aspect,
        "property alias cfg_folderFanScrollEnabled: "
        "folderPopupPage.cfg_folderFanScrollEnabled",
        "The aspect page must expose the fan scroll preference",
    )
    require(
        dock_configuration,
        "readonly property bool folderFanScrollEnabled:",
        "The configuration state must consume the fan scroll preference",
    )
    require(
        main_qml,
        "profileFanScrollEnabled: dockConfig.folderFanScrollEnabled",
        "main.qml must hand the fan scroll preference to the folder popup",
    )
    for fragment, message in (
        ("animationStyle: folderPopupAnimatedContent.animationStyle",
         "Folder popup delegates must consume the configured opening style"),
        ("animationIntensityPercent:",
         "Folder popup delegates must consume the configured opening intensity"),
        ("popupDirection: folderPopupAnimatedContent.popupDirection",
         "Folder popup delegates must follow the popup direction"),
        ("revealProgress: folderPopupAnimatedContent.openingProgress",
         "Folder popup delegates must share the surface opening progress"),
    ):
        require(folder_popup, fragment, message)
    for fragment, message in (
        ("closingDurationFactor: 0.65",
         "Exits must run on a shorter budget than entries"),
        ("duration: root.effectiveAnimationDuration",
         "The popup animation must consume the directional duration"),
    ):
        require(animated_content, fragment, message)
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
        ("property bool textShadowsEnabled: true",
         "Folder popup text shadows must remain enabled by default"),
    ):
        require(folder_popup_component, fragment, message)

    shadowed_labels = qml_object_bodies(
        folder_popup_component, "PunchiMenuComponents.PunchiMenuTextShadowLabel"
    )
    marquee_labels = qml_object_bodies(
        folder_popup_component, "PopupMarqueeLabel"
    )
    # Only the title remains a direct shadow label. The collection action shares
    # the app captions' elided/marquee primitive in List and Detailed.
    if len(shadowed_labels) != 1:
        raise AssertionError(
            "Folder popup must retain one direct themed shadow label for its title"
        )
    require(shadowed_labels[0], "id: classicHeaderLabel",
            "The direct shadow label must belong to the folder title")
    if len(marquee_labels) != 2:
        raise AssertionError(
            "Folder popup must retain exactly two shared marquee labels"
        )
    action_captions = [label for label in marquee_labels
                      if '"folderOpenLocationLabel"' in label]
    if len(action_captions) != 1:
        raise AssertionError("The list action must share its collection caption")
    for fragment, message in (
        ("text: appDelegate.displayName", "The location row must use its action caption"),
        ("hovered: itemMouse.containsMouse", "The action caption must follow valid pointer hover"),
        ("focused: itemMouse.activeFocus", "The action caption must follow keyboard focus"),
        ("motionEnabled: folderRoot.motionEnabled", "The action caption must respect reduced motion"),
    ):
        require(action_captions[0], fragment, message)
    for label in shadowed_labels + marquee_labels:
        require(
            label,
            "color: Kirigami.Theme.textColor",
            "Every folder popup shadow label must follow the active theme",
        )
        require(
            label,
            "shadowPercent: folderRoot.textShadowPercent",
            "Every folder popup shadow label must follow the configured amount",
        )

    popup_marquee_label = (
        PROJECT_ROOT / "contents/ui/components/PopupMarqueeLabel.qml"
    ).read_text()
    shared_marquee_label = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuMarqueeLabel.qml"
    ).read_text()
    require(
        popup_marquee_label,
        "visibleCharacterLimit: 10",
        "Popup names must keep the approved ten-character profile",
    )
    for fragment, message in (
        ('text: "MMMMMMMMMMMMMMMMMMMM".substring(',
         "Launcher names must derive their resting cap from wide glyphs"),
        ("elide: Text.ElideRight",
         "Popup names must show an ellipsis at rest"),
        ("SmoothedAnimation {",
         "Full popup names must reveal with a retargetable animation"),
        ("Controls.ToolTip.visible: root.revealFullText && !root.motionEnabled",
         "Reduced motion must expose the full popup name without movement"),
    ):
        require(shared_marquee_label, fragment, message)

    for source, label in (
        (folder_popup_component, "classic folder popup"),
        (folder_fan_view, "folder fan"),
    ):
        require(source, "PopupMarqueeLabel {",
                f"The {label} must use the shared long-name behaviour")

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
        "      <default>true</default>",
        "Popup text shadows must be enabled in new configurations",
    )
    require(
        dock_configuration,
        "Plasmoid.configuration.popupTextShadowsEnabled !== false",
        "Runtime popup text shadows must preserve the enabled default",
    )
    require(
        config_schema,
        '<entry name="folderPopupTextShadowPercent" type="Int">\n'
        "      <default>25</default>",
        "The folder popup must own the amount of its text shadow, with a mild "
        "default",
    )
    for key in (
        "folderGridIconSize",
        "folderListIconSize",
        "folderDetailedIconSize",
        "folderFanIconSize",
    ):
        require(
            config_schema,
            f'<entry name="{key}" type="Int">\n'
            "      <default>42</default>",
            f"{key} must default to the shared 42 px popup icon size",
        )
    require(
        config_schema,
        '<entry name="folderGridAutoLayout" type="Bool">\n'
        "      <default>true</default>",
        "Grid must use automatic arrangement by default",
    )
    require(
        config_schema,
        '<entry name="folderPopupScale" type="Double">\n'
        "      <default>1.5</default>",
        "Folder popups must default to 150 percent scale",
    )
    for fragment, message in (
        ("property int cfg_folderGridIconSize: 42",
         "The grid KCM fallback must match the 42 px schema default"),
        ("property bool cfg_folderGridAutoLayout: true",
         "The grid KCM must expose automatic arrangement as its default"),
        ("property int cfg_folderListIconSize: 42",
         "The list KCM fallback must match the 42 px schema default"),
        ("property int cfg_folderDetailedIconSize: 42",
         "The detailed KCM fallback must match the 42 px schema default"),
        ("property int cfg_folderFanIconSize: 42",
         "The fan KCM fallback must match the 42 px schema default"),
    ):
        require(config_folder_popups, fragment, message)
    for source, fragment, message in (
        (config_aspect, "cfg_folderGridAutoLayout",
         "The appearance page must forward the Grid arrangement mode"),
        (dock_configuration, "folderGridAutoLayout",
         "Runtime configuration must expose the Grid arrangement mode"),
        (main_qml, "profileAutoLayout: dockConfig.folderGridAutoLayout",
         "The live folder popup must receive the Grid arrangement mode"),
        (folder_popup_component, "function automaticGridColumnCount(",
         "Grid must derive its automatic columns from the item count"),
        (config_folder_popups, 'objectName: "gridArrangementCombo"',
         "The folder popup page must offer Automatic and Manual Grid modes"),
    ):
        require(source, fragment, message)
    require(
        config_folder_popups,
        "cfg_folderPopupTextShadowPercent",
        "The folder popup page must offer the amount of the text shadow",
    )
    require(
        config_aspect,
        "cfg_folderPopupTextShadowPercent",
        "The appearance page must forward the amount of the text shadow",
    )
    require(
        dock_configuration,
        "Plasmoid.configuration.folderPopupTextShadowPercent",
        "The runtime must expose the amount of the folder popup text shadow",
    )
    require(
        folder_popup_component,
        "textShadowPercent: folderRoot.textShadowPercent",
        "Every label of the folder popup must follow the configured amount",
    )
    require(
        text_shadow_label,
        "layer.effect: MultiEffect {",
        "The label of the popups must own the shadow of its own text",
    )
    require(
        text_shadow_label,
        "shadowHorizontalOffset: root.shadowOffset",
        "The amount must reach the geometry of the shadow, not only its text",
    )
    require(
        text_shadow_label,
        "layer.enabled: root.shadowRequested",
        "Zero must remove the shadow completely, texture included",
    )
    if "renderShadow: true" in text_shadow_label:
        raise AssertionError(
            "The graduated label must not fall back on the fixed shadow of the "
            "shared label"
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
    context_actions = (
        PROJECT_ROOT / "contents/ui/components/DockContextActionsController.qml"
    ).read_text()
    for source in (config_schema, config_menus, config_aspect, main_qml,
                   context_actions):
        for retired_symbol in ("showEditDockItemAction", "editDockItemHandler",
                               "editablePinnedItem", '"editDockItem"'):
            if retired_symbol in source:
                raise AssertionError(
                    f"The retired context action must not retain {retired_symbol}"
                )
    require(
        main_qml,
        "function openDockItemEditor(index)",
        "PunchiMenu must retain its shared item editor entry point",
    )
    require(
        config_schema,
        '<entry name="pendingEditDockItemIndex" type="Int">',
        "PunchiMenu must retain its shared item editor handoff",
    )
    require(
        config_schema,
        '<entry name="showConfigureDockAction" type="Bool">\n'
        "      <default>true</default>",
        "showConfigureDockAction must default to true in schema",
    )
    for fragment, message in (
        ('<entry name="folderPopupExtraDistance" type="Int">',
         "The legacy folder distance must remain readable for migration"),
        ('<entry name="folderPopupDistancePercent" type="Int">\n'
         "      <default>-1</default>",
         "The folder distance must expose a legacy-aware percentage key"),
        ('<entry name="contextMenuDistancePercent" type="Int">\n'
         "      <default>0</default>",
         "Context menu distance must default to an attached surface"),
    ):
        require(config_schema, fragment, message)
    for fragment, message in (
        ("function popupGapForPercent(value)",
         "Dock geometry must centralize percentage conversion"),
        ("readonly property int folderFanAvailableHeight",
         "Dock geometry must expose the height the fan may really use"),
        ("- taskPopupReservedVerticalExtent - 24",
         "The fan height must discount the panel and the same screen margin as "
         "the shared ceiling"),
    ):
        require(dock_geometry, fragment, message)
    for fragment, message in (
        ("Math.round(Kirigami.Units.gridUnit * 2)",
         "The adaptive maximum must follow Kirigami grid metrics"),
        ("function normalizedPercent(value)",
         "The shared metric must clamp and normalize percentages"),
        ("function gapForPercent(value)",
         "The shared metric must own the effective-gap conversion"),
    ):
        require(popup_spacing_metrics, fragment, message)
    if "maximumAdaptivePopupGap" in dock_geometry:
        raise AssertionError(
            "Dock geometry must not duplicate PopupSpacingMetrics.maximumGap"
        )

    for source, fragment, message in (
        (item_action_editor,
         "signal actionPopupSettingsChanged()",
         "The per-application row limit must emit an edit intent"),
        (item_action_editor,
         "to: 12",
         "The per-application row selector must match its runtime maximum"),
        (action_dialog,
         "onActionPopupSettingsChanged: root.actionPopupSettingsChanged()",
         "ActionDialog must forward per-application row changes"),
        (config_items,
         "onActionPopupSettingsChanged: page.applyItemForm()",
         "ConfigItems must persist per-application row changes"),
        (config_items_form_helper,
         "item.actionPopupMaxVisibleRows !== undefined",
         "The item editor must restore an existing row override"),
        (config_items_form_helper,
         "item.actionPopupMaxVisibleRows = Math.max(1, Math.min(12,",
         "The item editor must store a bounded row override"),
        (config_items_form_helper,
         "delete item.actionPopupMaxVisibleRows",
         "Disabling the row override must restore global behavior"),
        (popup_coordinator,
         '"maxVisibleRows": itemData',
         "PopupCoordinator must project the per-application override"),
        (app_actions,
         "popupCoordinator.activeAppContextMenuData.maxVisibleRows",
         "Standalone application menus must consume the per-item row limit"),
        (main_qml,
         "maxVisibleActionRows: Number(",
         "Task action menus must consume the per-item row limit"),
    ):
        require(source, fragment, message)
    for stale_cfg_property in (
        "cfg_actionPopupLimitRows",
        "cfg_actionPopupMaxVisibleRows",
    ):
        if stale_cfg_property in config_items:
            raise AssertionError(
                f"ConfigItems must not expose non-schema property {stale_cfg_property}"
            )
    require(
        main_qml,
        "showConfigureDockAction: Plasmoid.configuration.showConfigureDockAction !== false",
        "Runtime configure dock action must bind to configuration",
    )
    require(
        config_menus,
        "property alias cfg_showConfigureDockAction: showConfigureDockActionSwitch.checked",
        "ConfigMenus must expose showConfigureDockAction alias",
    )
    require(
        config_menus,
        "id: menuTextShadowsSwitch",
        "ConfigMenus must use a switch for menu text shadows",
    )
    require(
        config_menus,
        "property alias cfg_contextMenuDistancePercent: contextMenuDistanceSlider.value",
        "ConfigMenus must expose the adaptive context menu distance",
    )
    require(
        config_folder_popups,
        "property int cfg_folderPopupDistancePercent: -1",
        "Folder popup settings must expose the legacy-aware distance",
    )
    require(
        config_folder_popups,
        "value: page.effectiveFolderPopupDistancePercent",
        "Folder popup settings must display migrated legacy values",
    )
    require(
        config_aspect,
        "property alias cfg_showConfigureDockAction: menuAppearancePage.cfg_showConfigureDockAction",
        "ConfigAspect must expose showConfigureDockAction alias to KCM root",
    )
    require(
        config_aspect,
        "property alias cfg_folderPopupDistancePercent: folderPopupPage.cfg_folderPopupDistancePercent",
        "ConfigAspect must expose the folder distance percentage",
    )
    require(
        config_aspect,
        "property alias cfg_contextMenuDistancePercent: menuAppearancePage.cfg_contextMenuDistancePercent",
        "ConfigAspect must expose the context menu distance percentage",
    )

    print("Popup menu surface contracts are consistent")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as error:
        print(f"popup menu surface contract failed: {error}", file=sys.stderr)
        raise SystemExit(1)
