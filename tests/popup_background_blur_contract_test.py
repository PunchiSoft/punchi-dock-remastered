#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later

"""Static contract checks for the background blur of dock popups.

The blur region must come from the theme frame mask contracted by its insets
and mapped to window-client coordinates, and the preference must reach every
popup that shares the surface. These checks keep that chain intact.
"""

from pathlib import Path
import re


PROJECT_ROOT = Path(__file__).resolve().parents[1]
COMPONENTS_DIRECTORY = PROJECT_ROOT / "contents/ui/components"
CONFIG_DIRECTORY = PROJECT_ROOT / "contents/ui/config"

CONTEXT_SURFACE_PATH = COMPONENTS_DIRECTORY / "ContextSurfaceStack.qml"
ANIMATED_CONTENT_PATH = COMPONENTS_DIRECTORY / "PopupAnimatedContent.qml"
MAIN_PATH = PROJECT_ROOT / "contents/ui/main.qml"
CONFIG_XML_PATH = PROJECT_ROOT / "contents/config/main.xml"
CONFIG_POPUPS_PATH = CONFIG_DIRECTORY / "ConfigFolderPopups.qml"
CONFIG_MENUS_PATH = CONFIG_DIRECTORY / "ConfigMenus.qml"
CONFIG_ASPECT_PATH = CONFIG_DIRECTORY / "ConfigAspect.qml"
CONFIGURATION_STATE_PATH = COMPONENTS_DIRECTORY / "DockConfigurationState.qml"

# Every guarded popup that renders ContextSurfaceStack owns one controller,
# one animated container and one surface that consumes its transform.
# The task overflow popup is deliberately excluded: popup_menu_surface_contract_test
# forbids blur and a competing surface there, so it keeps its current surface.
POPUP_BLUR_CONTROLLERS = {
    "folderPopupDialog": (
        "folderSurfaceStack",
        "folderPopupBlurController",
        "folderPopupAnimatedContent",
        "popupBackgroundBlurEnabled",
    ),
    "trashMenuDialog": (
        "trashSurfaceStack",
        "trashMenuBlurController",
        "trashMenuAnimatedContent",
        "contextMenuBackgroundBlurEnabled",
    ),
    "appActionsDialog": (
        "appActionsSurfaceStack",
        "appActionsBlurController",
        "appActionsAnimatedContent",
        "contextMenuBackgroundBlurEnabled",
    ),
    "notePopupDialog": (
        "noteSurfaceStack",
        "notePopupBlurController",
        "notePopupAnimatedContent",
        "popupBackgroundBlurEnabled",
    ),
}

BLUR_FREE_POPUP_DIALOGS = ("taskOverflowDialog",)


def require(condition: bool, message: str) -> None:
    """Raise a focused contract failure when condition is false."""

    if not condition:
        raise AssertionError(message)


def source_for(path: Path) -> str:
    """Read a project source file and report a useful missing-file failure."""

    require(path.is_file(), f"Required source is missing: {path}")
    return path.read_text(encoding="utf-8")


def compact(source: str) -> str:
    """Collapse formatting-only whitespace for resilient expression checks."""

    return re.sub(r"\s+", " ", source)


def block_matching(source: str, header_pattern: str, label: str) -> str:
    """Return the brace-balanced body that follows a matched header."""

    match = re.search(header_pattern, source)
    require(match is not None, f"Missing {label} block.")

    opening = source.find("{", match.start())
    require(opening >= 0, f"{label} block has no body.")

    depth = 0
    for index in range(opening, len(source)):
        character = source[index]
        if character == "{":
            depth += 1
        elif character == "}":
            depth -= 1
            if depth == 0:
                return source[opening:index + 1]

    raise AssertionError(f"{label} block is not balanced.")


def assert_surface_exposes_mask(source: str) -> None:
    """The shared popup surface owns the mask contract and its mapping."""

    body = compact(source)
    require(
        'import "punchimenu" as PunchiMenuComponents' in source,
        "ContextSurfaceStack must reuse the approved mapped-surface helper.",
    )
    require(
        re.search(
            r"readonly property var backgroundBlurMaskSource: menuBackground",
            body,
        )
        is not None,
        "The blur mask source must be the themed background frame.",
    )
    require(
        re.search(
            r"readonly property bool backgroundBlurMaskPresent: "
            r"menuBackground\.visible && menuBackground\.width > 0 "
            r"&& menuBackground\.height > 0",
            body,
        )
        is not None,
        "The blur must be gated on a drawn, non-empty background frame.",
    )
    require(
        re.search(
            r"readonly property point backgroundBlurMaskOffset: "
            r"mappedSurfaceGeometry\.backgroundMaskOffset",
            body,
        )
        is not None,
        "The blur origin must come from the mapped surface geometry helper.",
    )
    require(
        re.search(
            r"readonly property var backgroundBlurAdditionalMaskPolygon:",
            body,
        )
        is not None,
        "The surface must expose an optional polygon for non-frame shapes.",
    )
    require(
        "edgeTail.mapToItem( menuBackground, localPolygon[index])" in body,
        "The tail polygon must be mapped into the themed frame coordinate system.",
    )
    require(
        re.search(r"property bool backgroundBlurEnabled: true", body) is not None,
        "The surface must expose a per-surface blur switch.",
    )
    for expression, reason in (
        (
            r"property Item blurTransformSurface: null",
            "typed animated-container input instead of inspecting its parent",
        ),
        (r"property real blurTranslationX: 0", "the reveal translation input"),
        (r"property real blurTranslationY: 0", "the reveal translation input"),
        (
            r"readonly property Item effectiveBlurTransformSurface: "
            r"root\.blurTransformSurface \? root\.blurTransformSurface : root",
            "a fallback to the surface itself when no animation wraps it",
        ),
    ):
        require(
            re.search(expression, body) is not None,
            f"The surface must expose {reason}.",
        )

    helper = compact(
        block_matching(
            source,
            r"PunchiMenuComponents\.PunchiMenuMappedSurfaceGeometry\s*\{",
            "ContextSurfaceStack mapped surface geometry",
        )
    )
    require(
        re.search(r"backgroundItem: menuBackground", helper) is not None,
        "The helper must map the themed background frame, not the window.",
    )
    require(
        re.search(r"surfaceItem: root\.effectiveBlurTransformSurface", helper) is not None,
        "The helper must read the animated container that reveals the surface.",
    )
    for side in ("left", "top", "right", "bottom"):
        require(
            re.search(
                rf"{side}Inset: menuBackground\.inset\.{side}",
                helper,
            )
            is not None,
            f"The helper must contract the mask by the {side} inset.",
        )


def assert_animated_content_exposes_transform(source: str) -> None:
    """The reveal container publishes the transform the mask must follow."""

    body = compact(source)
    require(
        re.search(r"readonly property Item transformSurfaceItem: animatedSurface", body)
        is not None,
        "PopupAnimatedContent must expose the animated surface item.",
    )
    require(
        re.search(r"readonly property real contentTranslationX: slideX", body) is not None
        and re.search(r"readonly property real contentTranslationY: slideY", body)
        is not None,
        "PopupAnimatedContent must expose its slide translation.",
    )


def assert_popup_controllers(source: str) -> None:
    """Each popup requests blur from its own surface and assigned preference."""

    for dialog, (surface, controller, animated, preference) in POPUP_BLUR_CONTROLLERS.items():
        require(
            re.search(rf"id:\s*{dialog}\b", source) is not None,
            f"Missing popup dialog {dialog}.",
        )
        require(
            re.search(rf"id:\s*{surface}\b", source) is not None,
            f"Missing popup surface {surface}.",
        )
        require(
            re.search(rf"id:\s*{animated}\b", source) is not None,
            f"Missing animated container {animated}.",
        )

        surface_block = compact(
            block_matching(
                source,
                rf"ContextSurfaceStack \{{\s*id: {surface}\b",
                f"{surface} block",
            )
        )
        for expression, reason in (
            (
                rf"blurTransformSurface: {animated}\.transformSurfaceItem",
                "the animated container it is revealed inside",
            ),
            (
                rf"blurTranslationX: {animated}\.contentTranslationX",
                "the reveal translation on the horizontal axis",
            ),
            (
                rf"blurTranslationY: {animated}\.contentTranslationY",
                "the reveal translation on the vertical axis",
            ),
        ):
            require(
                re.search(expression, surface_block) is not None,
                f"{surface} must receive {reason}.",
            )
        require(
            "root.parent" not in surface_block,
            "The surface must not inspect its parent instead of typed inputs.",
        )

        block = compact(
            block_matching(
                source,
                rf"readonly property Punchi\.BlurBehindController {controller}:"
                r"\s*Punchi\.BlurBehindController\s*\{",
                f"{dialog} blur controller",
            )
        )
        for expression, reason in (
            (rf"window: {dialog}\b", "own window"),
            ("fullWindow: false", "exact frame region instead of the whole window"),
            (rf"maskSource: {surface}\.backgroundBlurMaskSource", "the themed frame"),
            ("useMaskSourceInsets: true", "inset contraction"),
            (rf"maskOffset: {surface}\.backgroundBlurMaskOffset", "the mapped origin"),
            (r"enabled: .*?visible", "window visibility"),
            (
                rf"{surface}\.backgroundBlurMaskPresent",
                "a drawn background frame",
            ),
            (
                f"dockConfig.{preference}",
                "its own popup or context menu preference",
            ),
        ):
            require(
                re.search(expression, block, flags=re.DOTALL) is not None,
                f"{controller} must use {reason}.",
            )
        if dialog == "folderPopupDialog":
            require(
                re.search(
                    rf"additionalMaskPolygon: "
                    rf"{surface}\.backgroundBlurAdditionalMaskPolygon",
                    block,
                )
                is not None,
                "The folder popup blur must include its callout polygon.",
            )
        else:
            require(
                "additionalMaskPolygon" not in block,
                f"{controller} must keep the optional polygon empty.",
            )
        other_preference = (
            "popupBackgroundBlurEnabled"
            if preference == "contextMenuBackgroundBlurEnabled"
            else "contextMenuBackgroundBlurEnabled"
        )
        require(
            f"dockConfig.{other_preference}" not in block,
            f"{controller} must not depend on the unrelated blur preference.",
        )


def assert_blur_free_popups(source: str) -> None:
    """Popups under a no-blur contract must stay without a blur controller."""

    for dialog in BLUR_FREE_POPUP_DIALOGS:
        body = compact(
            block_matching(
                source,
                rf"GuardedPopupDialog \{{\s*id: {dialog}\b",
                f"{dialog} dialog",
            )
        )
        require(
            "Punchi.BlurBehindController" not in body,
            f"{dialog} must keep its approved no-blur surface.",
        )


def assert_preference_is_wired(config_xml: str, page: str, aspect: str, state: str) -> None:
    """The switch stores in KConfig and reaches the runtime state."""

    entry_match = re.search(
        r'<entry name="popupBackgroundBlurEnabled" type="Bool">(.*?)</entry>',
        config_xml,
        flags=re.DOTALL,
    )
    require(
        entry_match is not None,
        "Missing the popupBackgroundBlurEnabled KConfig entry.",
    )
    require(
        "<default>true</default>" in compact(entry_match.group(1)),
        "Background blur must be enabled by default.",
    )
    require(
        re.search(r"<entry name=\"folderPopupShowHeader\"", config_xml) is not None,
        "The blur entry must stay next to the other popup preferences.",
    )

    page_body = compact(page)
    require(
        re.search(
            r"property alias cfg_popupBackgroundBlurEnabled: "
            r"popupBackgroundBlurSwitch\.checked",
            page_body,
        )
        is not None,
        "The popup page must alias the blur preference to its switch.",
    )
    switch = compact(
        block_matching(
            page,
            r"Controls\.Switch \{\s*id: popupBackgroundBlurSwitch",
            "folder popup blur switch",
        )
    )
    require(
        re.search(r'Kirigami\.FormData\.label: i18n\("Background blur:"\)', switch)
        is not None,
        "The switch must keep a form label.",
    )
    require(
        re.search(r"Accessible\.description: i18n\(", switch) is not None,
        "The switch must describe its effect for assistive technology.",
    )

    opacity_index = page.index("id: folderPopupBackgroundOpacitySlider")
    switch_index = page.index("id: popupBackgroundBlurSwitch")
    distance_index = page.index("id: folderPopupDistanceSlider")
    require(
        opacity_index < switch_index < distance_index,
        "The blur switch must sit below background opacity and above popup distance.",
    )

    require(
        re.search(
            r"property alias cfg_popupBackgroundBlurEnabled: "
            r"folderPopupPage\.cfg_popupBackgroundBlurEnabled",
            compact(aspect),
        )
        is not None,
        "The appearance page must re-export the blur preference.",
    )
    require(
        re.search(
            r"readonly property bool popupBackgroundBlurEnabled: "
            r"Plasmoid\.configuration\.popupBackgroundBlurEnabled === undefined "
            r"\? !root\.appearanceDefaults\.opaquePopupsByDefault "
            r": Plasmoid\.configuration\.popupBackgroundBlurEnabled === true",
            compact(state),
        )
        is not None,
        "The runtime state must read the blur preference reactively.",
    )


def assert_menu_preference_is_wired(config_xml: str, page: str, aspect: str, state: str) -> None:
    """Context menus own a separate, reactive blur preference."""

    entry_match = re.search(
        r'<entry name="contextMenuBackgroundBlurEnabled" type="Bool">(.*?)</entry>',
        config_xml,
        flags=re.DOTALL,
    )
    require(entry_match is not None, "Missing the context menu blur KConfig entry.")
    require(
        "<default>false</default>" in compact(entry_match.group(1)),
        "Opaque context menus must disable blur by default.",
    )
    require(
        "property alias cfg_contextMenuBackgroundBlurEnabled: "
        "contextMenuBackgroundBlurSwitch.checked" in compact(page),
        "ConfigMenus must expose the context menu blur switch.",
    )
    switch = compact(
        block_matching(
            page,
            r"Controls\.Switch \{\s*id: contextMenuBackgroundBlurSwitch",
            "context menu blur switch",
        )
    )
    require(
        'Kirigami.FormData.label: i18n("Background blur:")' in switch
        and "Accessible.description: i18n(" in switch,
        "Context menu blur must be labelled and accessible.",
    )
    require(
        page.index("id: contextMenuBackgroundOpacitySlider")
        < page.index("id: contextMenuBackgroundBlurSwitch")
        < page.index("id: menuTextShadowsSwitch"),
        "Context menu blur must sit below opacity and above text shadows.",
    )
    require(
        "property alias cfg_contextMenuBackgroundBlurEnabled: "
        "menuAppearancePage.cfg_contextMenuBackgroundBlurEnabled" in compact(aspect),
        "ConfigAspect must expose the menu blur preference to the KCM.",
    )
    require(
        "readonly property bool contextMenuBackgroundBlurEnabled: "
        "Plasmoid.configuration.contextMenuBackgroundBlurEnabled === true"
        in compact(state),
        "The runtime state must read the menu blur preference reactively.",
    )


def main() -> None:
    surface_source = source_for(CONTEXT_SURFACE_PATH)
    animated_source = source_for(ANIMATED_CONTENT_PATH)
    main_source = source_for(MAIN_PATH)
    config_xml = source_for(CONFIG_XML_PATH)
    page_source = source_for(CONFIG_POPUPS_PATH)
    menu_page_source = source_for(CONFIG_MENUS_PATH)
    aspect_source = source_for(CONFIG_ASPECT_PATH)
    state_source = source_for(CONFIGURATION_STATE_PATH)

    assert_surface_exposes_mask(surface_source)
    assert_animated_content_exposes_transform(animated_source)
    assert_popup_controllers(main_source)
    assert_blur_free_popups(main_source)
    assert_preference_is_wired(config_xml, page_source, aspect_source, state_source)
    assert_menu_preference_is_wired(config_xml, menu_page_source, aspect_source, state_source)


if __name__ == "__main__":
    main()
