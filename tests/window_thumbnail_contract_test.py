#!/usr/bin/env python3

from pathlib import Path
import re
import sys


PROJECT_ROOT = Path(__file__).resolve().parents[1]


def require(source: str, fragment: str, message: str) -> None:
    if fragment not in source:
        raise AssertionError(message)


def function_body(source: str, function_name: str) -> str:
    signature = re.search(
        rf"\bfunction\s+{re.escape(function_name)}\s*\([^)]*\)\s*\{{",
        source,
    )
    if signature is None:
        raise AssertionError(f"Missing function contract: {function_name}")

    opening_brace = source.find("{", signature.start())
    depth = 0
    for index in range(opening_brace, len(source)):
        if source[index] == "{":
            depth += 1
        elif source[index] == "}":
            depth -= 1
            if depth == 0:
                return source[opening_brace + 1:index]

    raise AssertionError(f"Unterminated function contract: {function_name}")


def declared_property_expression(source: str, property_name: str) -> str:
    expression = re.search(
        rf"\b(?:readonly\s+)?property\s+[A-Za-z_$][\w$<>.]*\s+"
        rf"{re.escape(property_name)}\s*:\s*(?P<expression>.*?)"
        r"\n\s*(?:readonly\s+)?property\b",
        source,
        re.DOTALL,
    )
    if expression is None:
        raise AssertionError(f"Missing property contract: {property_name}")
    return expression.group("expression")


def main() -> int:
    thumbnail = (PROJECT_ROOT / "contents/ui/components/WindowLiveThumbnail.qml").read_text()
    card = (PROJECT_ROOT / "contents/ui/components/WindowPreviewCard.qml").read_text()
    action_button = (
        PROJECT_ROOT / "contents/ui/components/WindowPreviewActionButton.qml"
    ).read_text()
    preview_surface = (
        PROJECT_ROOT / "contents/ui/components/WindowPreviewSurface.qml"
    ).read_text()
    popup = (PROJECT_ROOT / "contents/ui/components/TaskWindowsPopup.qml").read_text()
    main_qml = (PROJECT_ROOT / "contents/ui/main.qml").read_text()
    dock_configuration = (
        PROJECT_ROOT / "contents/ui/components/DockConfigurationState.qml"
    ).read_text()
    dock_geometry = (
        PROJECT_ROOT / "contents/ui/components/DockGeometryState.qml"
    ).read_text()
    config_popups = (
        PROJECT_ROOT / "contents/ui/config/ConfigPopups.qml"
    ).read_text()
    config_aspect = (
        PROJECT_ROOT / "contents/ui/config/ConfigAspect.qml"
    ).read_text()
    config_schema = (PROJECT_ROOT / "contents/config/main.xml").read_text()
    surface_stack = (
        PROJECT_ROOT / "contents/ui/components/ContextSurfaceStack.qml"
    ).read_text()
    task_surface = (
        PROJECT_ROOT / "contents/ui/components/TaskPopupSurface.qml"
    ).read_text()
    presentation_controller = (
        PROJECT_ROOT / "contents/ui/components/TaskPopupPresentationController.qml"
    ).read_text()
    task_context_popup = (
        PROJECT_ROOT / "contents/ui/components/TaskContextPopup.qml"
    ).read_text()
    media_card = (
        PROJECT_ROOT / "contents/ui/components/MediaControlsCard.qml"
    ).read_text()
    replacement_card = (
        PROJECT_ROOT / "contents/ui/components/MprisReplacementCard.qml"
    ).read_text()
    popup_coordinator = (
        PROJECT_ROOT / "contents/ui/components/PopupCoordinator.qml"
    ).read_text()

    require(thumbnail, "property bool minimized: false",
            "WindowLiveThumbnail must receive the minimized state explicitly")
    require(thumbnail, "root.isX11 && root.minimized",
            "The minimized fallback must be restricted to X11")
    require(thumbnail, "root.isX11 && !root.minimized && Number(root.winId) > 0",
            "X11 thumbnails must require a restored window and an explicit XID")
    if "Number(root.winId || root.windowUuid)" in thumbnail:
        raise AssertionError("Wayland UUIDs must not be used as X11 window identifiers")

    for source, consumer in ((card, "WindowPreviewCard"), (popup, "TaskWindowsPopup")):
        require(source, "minimized:", f"{consumer} must propagate minimized state")
        require(source, "KWindowSystem.isPlatformX11",
                f"{consumer} must restrict the minimized fallback to X11")
        require(source, "i18n(\"Window minimized\")",
                f"{consumer} must present the intentional minimized fallback")

    require(popup, "winId: windowRow.previewWinId",
            "TaskWindowsPopup must propagate the explicit X11 window identifier")

    for fragment, message in (
        ('import QtQuick.Effects as Effects',
         "Live thumbnails must use the Qt 6 mask implementation"),
        ("property real cornerRadius: 0",
         "Live thumbnails must receive their effective corner radius"),
        ("layer.enabled: root.hasThumbnail && root.cornerRadius > 0",
         "The rounded mask must be limited to ready live thumbnails"),
        ("maskSource: roundedMask",
         "Live thumbnails must apply the rounded mask"),
    ):
        require(thumbnail, fragment, message)

    for fragment, message in (
        ("const shortSide = Math.min(previewFrameWidth, previewFrameHeight)",
         "The preview radius must react to both effective dimensions"),
        ("shortSide * 0.04",
         "The preview radius must remain proportional to its current size"),
        ("Math.min(themeRadius * 2, proportionalRadius)",
         "The responsive radius must retain a theme-derived upper bound"),
        ("previewRadius: root.previewRadius",
         "The current preview surface must propagate the responsive radius"),
    ):
        require(preview_surface, fragment, message)
    if "previewRadius: 4" in preview_surface:
        raise AssertionError("The current preview path must not restore a fixed radius")

    requested_windows_body = function_body(preview_surface, "requestedWindows")
    identity_result = re.search(
        r"\b(?:const|let)\s+(?P<name>[A-Za-z_$][\w$]*)\s*=\s*"
        r"(?:root\.)?taskControllerRef\.taskWindowsForIdentity\s*\(",
        requested_windows_body,
    )
    if identity_result is None:
        raise AssertionError(
            "WindowPreviewSurface must retain the identity lookup result before "
            "choosing its pinned-window fallback"
        )
    identity_name = identity_result.group("name")
    non_empty_identity = re.search(
        rf"\b{re.escape(identity_name)}\.length\s*>\s*0\b",
        requested_windows_body[identity_result.end():],
    )
    if non_empty_identity is None:
        raise AssertionError(
            "WindowPreviewSurface must accept an identity lookup only when it "
            "contains at least one window"
        )
    identity_return = re.search(
        rf"\breturn\s+{re.escape(identity_name)}\b",
        requested_windows_body[identity_result.end():],
    )
    if identity_return is None:
        raise AssertionError(
            "WindowPreviewSurface must return a non-empty live identity result"
        )
    if non_empty_identity.start() > identity_return.start():
        raise AssertionError(
            "WindowPreviewSurface must validate the live identity result before "
            "returning it"
        )
    fallback_contract = re.search(
        r"(?:root\.)?fallbackWindows\s+instanceof\s+Array\s*\?\s*"
        r"(?:root\.)?fallbackWindows\s*:\s*\[\]",
        requested_windows_body,
    )
    if fallback_contract is None:
        raise AssertionError(
            "WindowPreviewSurface must retain fallbackWindows when the live "
            "identity lookup is temporarily empty"
        )
    if fallback_contract.start() < identity_result.start():
        fallback_name_match = re.search(
            r"\b(?:const|let)\s+(?P<name>[A-Za-z_$][\w$]*)\s*=\s*"
            r"(?:root\.)?fallbackWindows\s+instanceof\s+Array",
            requested_windows_body,
        )
        fallback_returned = fallback_name_match is not None and re.search(
            rf"\breturn\s+{re.escape(fallback_name_match.group('name'))}\b",
            requested_windows_body[identity_result.end():],
        )
    else:
        fallback_returned = "return" in requested_windows_body[
            identity_result.end():fallback_contract.start() + len(fallback_contract.group(0))
        ]
    if not fallback_returned:
        raise AssertionError(
            "WindowPreviewSurface must return its pinned-window snapshot after "
            "an empty identity lookup"
        )

    for fragment, message in (
        ("cornerRadius: root.previewRadius",
         "WindowPreviewCard must propagate its radius to the live stream"),
        ("id: informationPlate",
         "Window information must have a theme-aware contrast plate"),
        ("Kirigami.Theme.backgroundColor.b, 0.82",
         "The information plate must use the approved theme opacity"),
        ("wrapMode: Text.NoWrap",
         "Window information must not grow the popup with long text"),
        ("maximumLineCount: 1",
         "Window information must remain on one line per label"),
    ):
        require(card, fragment, message)

    for fragment, message in (
        ("readonly property int fallbackApplicationIconSize:",
         "The disabled preview application icon must have responsive metrics"),
        ("const shortSide = Math.min(previewWidth, previewHeight)",
         "The fallback icon must react to both preview dimensions"),
        ("const minimumSize = Kirigami.Units.iconSizes.huge",
         "The fallback icon must remain slightly larger than its legacy size"),
        ("const maximumSize = Math.round(minimumSize * 1.125)",
         "The fallback icon must retain a theme-derived upper bound"),
        ("shortSide * 0.38",
         "The fallback icon must scale proportionally with the preview"),
        ('source: "view-hidden"',
         "The disabled preview state must use Breeze's hidden-view icon"),
        ("visible: root.disabledPreviewFallback",
         "The hidden-view icon must be limited to the disabled state"),
        ('i18nc("@info Window live preview state", "Disabled")',
         "The disabled state must use a short contextual label"),
        ("Accessible.ignored: true",
         "The decorative status icon must not duplicate the visible label"),
    ):
        require(card, fragment, message)

    if card.count("WindowPreviewActionButton {") != 4:
        raise AssertionError(
            "Every current thumbnail action must use the shared themed button"
        )
    if "Controls.ToolTip" in card:
        raise AssertionError(
            "Thumbnail actions must not restore Qt Controls tooltips"
        )
    for fragment, message in (
        ("PlasmaComponents.ToolButton",
         "Thumbnail actions must use the Plasma control implementation"),
        ("Kirigami.Theme.highlightColor",
         "Regular thumbnail actions must use the Plasma highlight color"),
        ("Kirigami.Theme.negativeTextColor",
         "The close action must preserve its semantic negative color"),
        ("PlasmaCore.ToolTipArea",
         "Thumbnail actions must use Plasma's independent themed tooltip"),
        ("mainText: root.text",
         "Thumbnail actions must use Plasma's stable default tooltip content"),
        ("icon.color: destructive",
         "Regular thumbnail action icons must preserve the normal text color"),
        ("activeFocus || actionToolTip.containsMouse",
         "Pointer and keyboard focus must share the highlighted state"),
        ("actionToolTip.showToolTip()",
         "Keyboard focus must expose the same tooltip information"),
        ("Accessible.name: text",
         "Thumbnail action labels must remain accessible"),
    ):
        require(action_button, fragment, message)
    if "mainItem:" in action_button:
        raise AssertionError(
            "Thumbnail actions must not introduce local tooltip geometry overrides"
        )

    require(config_schema,
            '<entry name="windowPreviewBackgroundOpacityPercent" type="Int">',
            "KConfig must persist a dedicated window preview opacity")
    require(config_schema,
            '<entry name="mediaCardBackgroundOpacityPercent" type="Int">\n      <default>75</default>',
            "KConfig must persist an independent media card opacity")
    require(config_schema,
            '<entry name="windowPreviewFrameSize" type="String">\n      <default>thin</default>',
            "KConfig must persist the thin window preview frame by default")
    require(config_schema,
            '<entry name="windowPreviewTextShadowsEnabled" type="Bool">\n      <default>false</default>',
            "Window preview text shadows must remain disabled by default")
    require(config_popups,
            "property alias cfg_windowPreviewBackgroundOpacityPercent:",
            "The popup configuration page must own the opacity value")
    require(config_popups,
            "property alias cfg_mediaCardBackgroundOpacityPercent:",
            "The popup configuration page must own the media opacity value")
    require(config_popups, 'i18n("Media card opacity:")',
            "The popup configuration page must expose the media opacity control")
    require(config_popups, "from: 50",
            "The preview opacity slider must retain its safe lower bound")
    require(config_popups, "to: 100",
            "The preview opacity slider must retain its opaque upper bound")
    require(config_popups, 'property string cfg_windowPreviewFrameSize: "thin"',
            "The popup configuration page must own the frame size")
    for value in ("thin", "medium", "wide"):
        require(config_popups, f'"value": "{value}"',
                f"The popup configuration page must expose the {value} frame")
    require(config_aspect,
            "property alias cfg_windowPreviewBackgroundOpacityPercent:",
            "The Appearance KCM must expose the popup page opacity")
    require(config_aspect,
            "property alias cfg_mediaCardBackgroundOpacityPercent:",
            "The Appearance KCM must expose the media card opacity")
    require(config_aspect,
            "property alias cfg_windowPreviewFrameSize:",
            "The Appearance KCM must expose the popup frame size")
    require(dock_configuration,
            "readonly property real windowPreviewBackgroundOpacity:",
            "Runtime configuration must sanitize the preview opacity")
    require(dock_configuration,
            "readonly property real mediaCardBackgroundOpacity:",
            "Runtime configuration must sanitize the media card opacity")
    require(dock_configuration,
            "readonly property string windowPreviewFrameSize:",
            "Runtime configuration must sanitize the preview frame size")
    require(dock_configuration,
            "readonly property real windowPreviewFrameScale:",
            "Runtime configuration must map frame profiles to bounded scales")
    require(dock_configuration,
            "Plasmoid.configuration.windowPreviewTextShadowsEnabled === true",
            "Runtime text shadows must be opt-in")

    task_dialog_match = re.search(
        r"PlasmaCore\.Dialog\s*\{\s*id:\s*taskWindowsDialog\b"
        r"(?P<body>.*?)\n\s*GuardedPopupDialog\s*\{\s*"
        r"id:\s*taskOverflowDialog\b",
        main_qml,
        re.DOTALL,
    )
    if task_dialog_match is None:
        raise AssertionError(
            "The composed window popup must use the guarded custom Dialog"
        )
    task_dialog = task_dialog_match.group("body")
    for fragment, message in (
        ("type: PlasmaCore.Dialog.AppletPopup",
         "The custom window must retain Plasma's applet-popup role"),
        ("backgroundHints: PlasmaCore.Dialog.NoBackground",
         "The custom window must have one content-owned surface"),
        ("property bool preparingToShow: false",
         "The popup must prepare content before mapping its window"),
        ("function openSafely()",
         "The popup must expose a guarded opening path"),
        ("function closeSafely()",
         "The popup must invalidate pending opens when closing"),
        ("Number(taskPopupAnimatedContent.implicitWidth) > 0",
         "The popup must reject non-positive window width"),
        ("Number(taskPopupAnimatedContent.implicitHeight) > 0",
         "The popup must reject non-positive window height"),
        ("Number(taskPopupAnimatedContent.width) > 0",
         "The popup must validate Plasma Dialog's real window width"),
        ("Number(taskPopupAnimatedContent.height) > 0",
         "The popup must validate Plasma Dialog's real window height"),
        ("taskPopupSurface.geometryReady",
         "The popup must wait for its selected surface geometry"),
        ("TaskPopupSurface {",
         "The task popup must use its dedicated single-owner surface"),
        ("presentationMode: popupCoordinator.activeTaskPopupPresentation",
         "The visual surface must consume the coordinator's single decision"),
        ("backgroundOpacity: taskPopupSurface.replacementMediaPresentation",
         "The popup must select opacity from its active presentation"),
        ("? dockConfig.mediaCardBackgroundOpacity",
         "Replacement media cards must use their dedicated reactive opacity"),
        (": dockConfig.windowPreviewBackgroundOpacity",
         "Previews and overlays must retain preview opacity"),
        ("contentFramePaddingPercent: 2",
         "The thumbnail frame padding must remain at two percent"),
        ("contentFramePaddingScale: dockConfig.windowPreviewFrameScale",
         "The thumbnail frame must apply the reactive size profile"),
        ("maximumSurfaceWidth: dockGeometry.taskPopupAvailableWidth",
         "The task surface must receive the safe popup width"),
        ("maximumSurfaceHeight: dockGeometry.taskPopupAvailableHeight",
         "The task surface must receive the safe popup height"),
        ("maximumAvailableWidth: taskPopupSurface.maximumContentWidth",
         "Embedded task content must reserve the outer frame width"),
        ("maximumAvailableHeight: taskPopupSurface.maximumContentHeight",
         "Embedded actions must reserve compact media and frame height"),
        ("|| taskWindowsDialog.preparingToShow",
         "Preview content must be measurable before the window is visible"),
    ):
        require(task_dialog, fragment, message)

    require(
        main_qml,
        "taskPopupTracksVisualArea: true",
        "Dynamic task previews must follow the transformed icon geometry",
    )
    for fragment, message in (
        ("function taskPopupAnchor(visualParent)",
         "PopupCoordinator must resolve a dedicated visual task anchor"),
        ("visualParent.taskPopupAnchorItem",
         "The visual task anchor must remain optional"),
        ("taskPopupAnchor(visualParent)",
         "Task popup opening must use the resolved visual anchor"),
        ("function taskPopupHorizontalX(popupWidth, availableGeometry)",
         "Compact dynamic previews must expose a one-shot horizontal position"),
        ("anchor.mapToGlobal(Qt.point(",
         "The compact correction must use the dynamic icon's global center"),
    ):
        require(popup_coordinator, fragment, message)

    for fragment, message in (
        ("function compactDynamicHorizontalAnchorEnabled()",
         "The task dialog must classify compact dynamic anchoring explicitly"),
        ("&& dockGeometry.horizontalPanel",
         "The one-shot correction must remain horizontal-only"),
        ("&& !dockGeometry.panelFillLengthEnabled",
         "Fill-length panels must preserve Plasma's native positioning"),
        ("popupCoordinator.taskPopupVisualParent.taskPopupTracksVisualArea",
         "Only dynamic task owners may request the compact correction"),
        ("function applyCompactDynamicHorizontalAnchor()",
         "The task dialog must apply the correction once while opening"),
        ("visible = true\n                applyCompactDynamicHorizontalAnchor()",
         "The corrected X must be applied after Plasma's native placement and before the first frame"),
    ):
        require(task_dialog, fragment, message)

    for forbidden in (
        "backgroundHints: PlasmaCore.AppletPopup.StandardBackground",
        "previewBlurController",
        "Punchi.BlurBehindController",
    ):
        if forbidden in task_dialog:
            raise AssertionError(
                "The guarded custom popup must not retain a competing surface: "
                f"{forbidden}"
            )

    for fragment, message in (
        ('import org.kde.ksvg as KSvg',
         "MediaControlsCard must use Plasma's themed surface when standalone"),
        ('imagePath: "widgets/background"',
         "Standalone media cards must use the same themed resource as PunchiMenu"),
        ("property bool drawBackground: true",
         "Embedded media presentations must be able to delegate the exterior surface"),
        ("active: root.drawBackground",
         "The media background must have an explicit ownership gate"),
        ("themedBackgroundInsetsValid",
         "The standalone themed card must validate its effective insets"),
    ):
        require(media_card, fragment, message)

    for fragment, message in (
        ('imagePath: "widgets/background"',
         "TaskPopupSurface must own the same exterior surface as PunchiMenu"),
        ("property string presentationMode: \"none\"",
         "TaskPopupSurface must consume one explicit presentation mode"),
        ("MprisReplacementCard {",
         "Replacement media must use its focused content-only renderer"),
        ("readonly property bool geometryReady:",
         "TaskPopupSurface must expose one geometry readiness contract"),
        ("containedCardHeight:",
         "Contained artwork must have a profile metric independent of image state"),
        ("fullCoverCardHeight:",
         "Full-cover artwork must have a profile metric independent of image state"),
        ("maximumContentHeight:",
         "Task actions must receive a height budget below compact media"),
        ("themedContentMarginsValid:",
         "The task surface must validate the theme's content margins"),
        ("contentPaddingLeft:",
         "The task surface must reserve the themed left content margin"),
        ("contentPaddingTop:",
         "The task surface must reserve the themed top content margin"),
        ("contentPaddingRight:",
         "The task surface must reserve the themed right content margin"),
        ("contentPaddingBottom:",
         "The task surface must reserve the themed bottom content margin"),
        ("contentFramePadding > 0",
         "An explicit frame profile must prevent a second theme-margin gutter"),
    ):
        require(task_surface, fragment, message)

    square_mode_expression = declared_property_expression(media_card, "squareMode")
    for fragment, message in (
        ("squarePresentation",
         "The square MPRIS geometry must follow the selected presentation profile"),
        ("!fullCoverMode",
         "The square and full-cover MPRIS profiles must remain exclusive"),
        ("!compact",
         "The square MPRIS profile must remain exclusive with compact mode"),
    ):
        require(square_mode_expression, fragment, message)
    if "artworkReady" in square_mode_expression:
        raise AssertionError(
            "The square MPRIS geometry must not wait for asynchronous artwork"
        )

    require(
        dock_geometry,
        "root.inPanel && !root.verticalPanel ? panelPreferredHeight : 0",
        "A vertical panel must not consume the popup's available height",
    )
    require(
        dock_geometry,
        "- taskPopupReservedVerticalExtent - 24",
        "Popup height must subtract only the relevant horizontal-panel extent",
    )

    for fragment, message in (
        ('property string backgroundImagePath: "dialogs/background"',
         "Other surface consumers must preserve their established default"),
        ("property real contentFramePaddingPercent: 0",
         "Adaptive padding must remain opt-in"),
        ("property real contentFramePaddingScale: 1.0",
         "Other consumers must preserve the established frame size"),
        ("property bool preserveContentGeometry: false",
         "Geometry retention must remain opt-in"),
        ("shortSide * requestedPercent / 100",
         "Frame padding must be proportional to the shorter content side"),
        ("Kirigami.Units.smallSpacing",
         "Frame padding must have a theme-derived lower bound"),
        ("Math.max(1.0, Math.min(2.0, requestedScale))",
         "Frame padding profiles must stay inside the approved scale range"),
        ("Math.min(Kirigami.Units.gridUnit,",
         "Scaled frame padding must retain a theme-derived upper bound"),
    ):
        require(surface_stack, fragment, message)

    task_surface_card_match = re.search(
        r"MprisReplacementCard\s*\{(?P<body>.*?)"
        r"\n\s*onCloseRequested:\s*root\.mediaCloseRequested\(\)",
        task_surface,
        re.DOTALL,
    )
    if task_surface_card_match is None:
        raise AssertionError(
            "TaskPopupSurface must own exactly one replacement media renderer"
        )
    replacement_card_body = task_surface_card_match.group("body")
    for fragment, message in (
        ('? "compact"',
         "Media actions must select the compact profile explicitly"),
        (": root.presentationMode",
         "The replacement renderer must consume the selected card profile"),
        ("containedProfileHeight: root.containedCardHeight",
         "The task surface must own the contained-card metric"),
        ("fullCoverProfileHeight: root.fullCoverCardHeight",
         "The task surface must own the full-cover metric"),
        ("compactProfileHeight: root.compactCardHeight",
         "The task surface must own the compact metric"),
    ):
        require(replacement_card_body, fragment, message)

    for forbidden in (
        'import org.kde.ksvg as KSvg',
        'imagePath: "widgets/background"',
        "drawBackground",
    ):
        if forbidden in replacement_card:
            raise AssertionError(
                "MprisReplacementCard must remain content-only: "
                f"{forbidden}"
            )

    require(
        replacement_card,
        "readonly property real safeContentInset:",
        "Replacement media controls must share one theme-derived safe inset",
    )
    require(
        replacement_card,
        "readonly property real headerControlInset:",
        "Header controls must share their own small theme-derived inset",
    )
    require(
        replacement_card,
        "readonly property real headerControlEdgeAdjustment: 2",
        "The approved header controls must move two logical pixels inward",
    )
    if replacement_card.count("anchors.margins: root.headerControlInset") != 2:
        raise AssertionError(
            "The application badge and close button must share the header inset"
        )
    if "implicitWidth: internalWidth + contentFramePadding * 2" in task_surface:
        raise AssertionError(
            "TaskPopupSurface must not ignore asymmetric theme margins"
        )

    content_ready_expression = declared_property_expression(
        replacement_card, "contentReady"
    )
    for fragment, message in (
        ("available",
         "Replacement content must not map before MPRIS is available"),
        ("profileLoader.status === Loader.Ready",
         "Replacement content must wait for its selected profile"),
        ("headerControlsLoader.status === Loader.Ready",
         "Replacement content must wait for its header controls"),
    ):
        require(content_ready_expression, fragment, message)
    if "!available" in content_ready_expression:
        raise AssertionError(
            "Unavailable MPRIS content must never be declared ready"
        )

    for forbidden in (
        "fullMediaFits",
        "compactMediaFits",
        "mediaCard.preferredExpandedHeight",
        "onImplicitHeightChanged: root.updateMediaExtent()",
    ):
        if forbidden in task_surface:
            raise AssertionError(
                "The task surface must not restore circular media geometry: "
                f"{forbidden}"
            )

    for forbidden in (
        "function scheduleReanchor()",
        "onImplicitWidthChanged:",
        "onImplicitHeightChanged:",
        "popupCoordinator.reanchorTaskWindowsPopup",
        "visualParent = null",
    ):
        if forbidden in task_dialog:
            raise AssertionError(
                "The task popup must let Plasma resize without per-frame reanchoring: "
                f"{forbidden}"
            )

    open_task_popup_body = function_body(popup_coordinator, "openTaskWindowsPopup")
    preview_decision_index = open_task_popup_body.find("const previewAllowed")
    presentation_index = open_task_popup_body.find(
        "const presentation = taskPresentationPolicy.resolve"
    )
    waiting_index = open_task_popup_body.find('if (presentation === "waiting")')
    if preview_decision_index < 0 or presentation_index < 0 or waiting_index < 0:
        raise AssertionError(
            "PopupCoordinator must resolve one presentation before opening"
        )
    if not preview_decision_index < presentation_index < waiting_index:
        raise AssertionError(
            "The presentation policy must receive preview availability before "
            "the waiting branch is evaluated"
        )
    waiting_return_index = open_task_popup_body.find(
        "return", waiting_index
    )
    if waiting_return_index < 0:
        raise AssertionError(
            "PopupCoordinator must leave the pending popup undecided while "
            "MPRIS resolution is in progress"
        )
    if "resetTaskPopupState" in open_task_popup_body[
            waiting_index:waiting_return_index]:
        raise AssertionError(
            "The MPRIS resolving guard must preserve the pending popup request"
        )

    for fragment, message in (
        ("readonly property bool replacementRequested:",
         "The presentation controller must identify replacement modes once"),
        ("function controllerMatches(applicationId)",
         "MPRIS availability must be associated with the requested application"),
        ("function resolve(applicationId, previewAvailable)",
         "The presentation controller must expose one pure decision entry point"),
        ('return "waiting"',
         "An unresolved exclusive media request must have an explicit state"),
        ('return root.mediaMode',
         "A resolved card or full-card request must retain its selected profile"),
        ('return root.overlayRequested ? "overlay" : "preview"',
         "Overlay and plain preview must remain explicit outcomes"),
    ):
        require(presentation_controller, fragment, message)

    mpris_state_changed_body = function_body(popup_coordinator, "onStateChanged")
    for fragment, message in (
        ("mprisControllerRef.resolving",
         "PopupCoordinator must wait for the MPRIS lookup to settle"),
        ("resumePendingTaskPopupAfterMediaResolution",
         "PopupCoordinator must resume the preserved request after MPRIS settles"),
    ):
        require(mpris_state_changed_body, fragment, message)

    mpris_resolving_changed_body = function_body(
        popup_coordinator, "onResolvingChanged"
    )
    for fragment, message in (
        ("root.mprisControllerRef.resolving",
         "PopupCoordinator must recognize an unfinished MPRIS resolution"),
        ("resumePendingTaskPopupAfterMediaResolution",
         "An unavailable MPRIS result must also resume the pending popup request"),
    ):
        require(mpris_resolving_changed_body, fragment, message)
    resolving_guard_index = mpris_resolving_changed_body.find(
        "root.mprisControllerRef.resolving"
    )
    resolving_guard_return = mpris_resolving_changed_body.find(
        "return", resolving_guard_index
    )
    resume_after_guard = mpris_resolving_changed_body.find(
        "resumePendingTaskPopupAfterMediaResolution"
    )
    if not (resolving_guard_index >= 0
            and resolving_guard_return > resolving_guard_index
            and resume_after_guard > resolving_guard_return):
        raise AssertionError(
            "PopupCoordinator must return while MPRIS is resolving and only "
            "resume the popup after resolution finishes"
        )

    fallback_timer_match = re.search(
        r"id:\s*mediaAvailabilityFallbackTimer\b(?P<body>.*?)"
        r"\n\s*Connections\s*\{",
        popup_coordinator,
        re.DOTALL,
    )
    if fallback_timer_match is None:
        raise AssertionError("PopupCoordinator must retain its media fallback timer")
    require(
        fallback_timer_match.group("body"),
        "mprisControllerRef.resolving",
        "The media fallback timer must not treat an in-flight lookup as unavailable",
    )

    pending_request_body = function_body(
        popup_coordinator, "pendingTaskPopupRequestActive"
    )
    require(
        pending_request_body,
        "pendingTaskPopupRequestValid",
        "Pending MPRIS resumption must use explicit request validity",
    )
    if "taskPopupSourceContainsMouse" in pending_request_body:
        raise AssertionError(
            "A recorded pending request must not be invalidated by sampling hover "
            "state again during asynchronous completion"
        )

    cancel_pending_body = function_body(
        popup_coordinator, "cancelPendingTaskWindowsPopup"
    )
    require(
        cancel_pending_body,
        "pendingTaskPopupRequestValid = false",
        "Leaving the task item must explicitly cancel a pending MPRIS request",
    )

    no_content_start = open_task_popup_body.find(
        'if (presentation === "none")'
    )
    no_content_end = open_task_popup_body.find(
        "activeTaskPopupPresentation = presentation", no_content_start
    )
    if no_content_start < 0 or no_content_end <= no_content_start:
        raise AssertionError(
            "PopupCoordinator must retain an explicit no-media/no-preview branch"
        )
    no_content_body = open_task_popup_body[no_content_start:no_content_end]
    for fragment, message in (
        ("hideTaskWindowsDialog",
         "A failed retarget must hide the previous popup surface"),
        ("resetTaskPopupState",
         "A failed retarget must clear its pending popup state"),
    ):
        require(no_content_body, fragment, message)

    resume_media_popup_body = function_body(
        popup_coordinator, "resumePendingTaskPopupAfterMediaResolution"
    )
    for fragment, message in (
        ("openTaskWindowsPopup",
         "PopupCoordinator must retry the preserved popup request after MPRIS settles"),
        ("mediaReplacementMode",
         "Only card and full-card modes may resume an exclusive media request"),
        ("pendingTaskPopupAwaitingMediaResolution",
         "MPRIS signals must only resume a request that actually waited for resolution"),
        ("pendingTaskPopupRows",
         "The MPRIS retry must use the still-pending task rows"),
        ("taskPopupVisualParent",
         "The MPRIS retry must require the original popup anchor"),
        ("mprisControllerRef.resolving",
         "The MPRIS retry must not run until resolution has finished"),
    ):
        require(resume_media_popup_body, fragment, message)

    close_all_body = function_body(popup_coordinator, "closeAllPopups")
    for fragment, message in (
        ("pendingTaskPopupRequestValid = false",
         "Opening another popup must invalidate a pending task hover"),
        ("pendingTaskPopupAwaitingMediaResolution = false",
         "Opening another popup must cancel an outstanding MPRIS decision"),
    ):
        require(close_all_body, fragment, message)

    for fragment, message in (
        ("popupDialogActive(taskWindowsDialogRef)",
         "Task popup cancellation must include a guarded opening in progress"),
        ("taskWindowsDialogRef.preparingToShow",
         "Task popup cancellation must explicitly detect preparation state"),
        ("hideTaskWindowsDialog",
         "Leaving during preparation must cancel openSafely before resetting state"),
    ):
        require(cancel_pending_body, fragment, message)

    replacement_mode_match = re.search(
        r"readonly\s+property\s+bool\s+mediaReplacementMode\s*:\s*"
        r"(?P<expression>.*?)\n\s*(?:readonly\s+)?property",
        popup_coordinator,
        re.DOTALL,
    )
    if replacement_mode_match is None:
        raise AssertionError(
            "PopupCoordinator must keep replacement media modes explicit"
        )
    replacement_mode_expression = replacement_mode_match.group("expression")
    for mode in ("card", "fullCard"):
        require(
            replacement_mode_expression,
            f'mediaHoverMode === "{mode}"',
            f"The {mode} media mode must replace window previews",
        )
    if 'mediaHoverMode === "overlay"' in replacement_mode_expression:
        raise AssertionError(
            "Overlay must not enter the exclusive media replacement path"
        )

    if "const showMedia" in open_task_popup_body:
        raise AssertionError(
            "PopupCoordinator must not keep a second boolean media decision"
        )

    open_context_menu_body = function_body(
        popup_coordinator, "openAppContextMenu"
    )
    require(
        open_context_menu_body,
        "if (!taskPopupAlreadyActive)",
        "Opening actions inside an active task popup must preserve its presentation",
    )

    for fragment, message in (
        ("Loader {",
         "TaskContextPopup must load its preview renderer on demand"),
        ("id: previewPage",
         "The preview page must have one lazy-loading owner"),
        ("active: root.previewSurfaceVisible",
         "Replacement modes must unload the legacy preview renderer"),
        ("WindowPreviewSurface {",
         "Preview and overlay modes must retain the established renderer"),
        ("previewRendererLoaded:",
         "The lazy preview state must remain inspectable"),
    ):
        require(task_context_popup, fragment, message)

    preview_binding_match = re.search(
        r"\bpreviewsEnabled\s*:\s*(?P<expression>.*?)"
        r"\n\s*returnToMedia\s*:",
        task_dialog,
        re.DOTALL,
    )
    if preview_binding_match is None:
        raise AssertionError(
            "The task popup must expose its explicit preview binding"
        )
    preview_binding_expression = preview_binding_match.group("expression")
    for mode in ("preview", "overlay"):
        require(
            preview_binding_expression,
            f'activeTaskPopupPresentation === "{mode}"',
            f"The {mode} presentation must enable the preview renderer",
        )
    for replacement_mode in ("card", "fullCard"):
        if f'activeTaskPopupPresentation === "{replacement_mode}"' \
                in preview_binding_expression:
            raise AssertionError(
                "Replacement media must not enable the window renderer"
            )

    media_overlay_match = re.search(
        r"readonly\s+property\s+bool\s+mediaOverlayRequested\s*:\s*"
        r"(?P<expression>.*?)\n\s*readonly\s+property",
        preview_surface,
        re.DOTALL,
    )
    if media_overlay_match is None:
        raise AssertionError(
            "WindowPreviewSurface must keep an explicit overlay presentation path"
        )
    media_overlay_expression = media_overlay_match.group("expression")
    require(
        media_overlay_expression,
        "mediaOverlayEnabled",
        "Overlay must consume the coordinator's explicit presentation result",
    )
    require(
        task_context_popup,
        'mediaOverlayEnabled: root.presentationMode === "overlay"',
        "TaskContextPopup must pass only the resolved overlay state",
    )
    require(
        preview_surface,
        "visible: root.mediaOverlayVisible",
        "The overlay media card must remain composed inside the preview surface",
    )

    for fragment, message in (
        ("function showTaskWindowsDialog()",
         "PopupCoordinator must centralize guarded task-popup opening"),
        ("return root.showPopupDialog(root.taskWindowsDialogRef)",
         "The task popup must use the shared guarded opening path"),
        ('typeof dialog.openSafely === "function"',
         "PopupCoordinator must prefer guarded opening when available"),
        ("function hideTaskWindowsDialog()",
         "PopupCoordinator must centralize pending-open cancellation"),
        ("root.hidePopupDialog(root.taskWindowsDialogRef)",
         "The task popup must use the shared guarded closing path"),
        ('typeof dialog.closeSafely === "function"',
         "PopupCoordinator must prefer guarded closing when available"),
    ):
        require(popup_coordinator, fragment, message)
    if popup_coordinator.count("dialog.visible = true") != 1:
        raise AssertionError(
            "Only the compatibility fallback may map the task popup directly"
        )
    if popup_coordinator.count("dialog.visible = false") != 1:
        raise AssertionError(
            "Only the compatibility fallback may hide the task popup directly"
        )

    print("Window thumbnail platform contracts are consistent")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as error:
        print(f"window thumbnail contract failed: {error}", file=sys.stderr)
        raise SystemExit(1)
