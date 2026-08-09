#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later

"""Static contract checks for the PunchiMenu application-folder UI."""

from pathlib import Path
import re


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PUNCHIMENU_DIRECTORY = (
    PROJECT_ROOT / "contents/ui/components/punchimenu"
)

MENU_PATHS = {
    "Normal": PUNCHIMENU_DIRECTORY / "PunchiMenuNormal.qml",
    "Fullscreen": PUNCHIMENU_DIRECTORY / "PunchiMenuOverlay.qml",
}

# PunchiMenuModalSurface is the bounded modal primitive owned by the six
# folder-specific components. Keeping this inventory explicit ensures that a
# new folder UI component cannot silently bypass the safety checks below.
FOLDER_UI_COMPONENTS = (
    PUNCHIMENU_DIRECTORY / "PunchiMenuFolderActionContent.qml",
    PUNCHIMENU_DIRECTORY / "PunchiMenuFolderActionState.qml",
    PUNCHIMENU_DIRECTORY / "PunchiMenuFolderActionView.qml",
    PUNCHIMENU_DIRECTORY / "PunchiMenuFolderSurface.qml",
    PUNCHIMENU_DIRECTORY / "PunchiMenuFolderTile.qml",
    PUNCHIMENU_DIRECTORY / "PunchiMenuFolderView.qml",
    PUNCHIMENU_DIRECTORY / "PunchiMenuModalSurface.qml",
)


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


def without_comments(source: str) -> str:
    """Remove QML comments while preserving strings and line structure."""

    result: list[str] = []
    index = 0
    quote = ""
    escaped = False
    line_comment = False
    block_comment = False
    while index < len(source):
        character = source[index]
        next_character = source[index + 1] if index + 1 < len(source) else ""

        if line_comment:
            if character == "\n":
                line_comment = False
                result.append(character)
            else:
                result.append(" ")
            index += 1
            continue
        if block_comment:
            if character == "*" and next_character == "/":
                result.extend((" ", " "))
                block_comment = False
                index += 2
            else:
                result.append("\n" if character == "\n" else " ")
                index += 1
            continue
        if quote:
            result.append(character)
            if escaped:
                escaped = False
            elif character == "\\":
                escaped = True
            elif character == quote:
                quote = ""
            index += 1
            continue
        if character in {'"', "'", "`"}:
            quote = character
            result.append(character)
            index += 1
            continue
        if character == "/" and next_character == "/":
            result.extend((" ", " "))
            line_comment = True
            index += 2
            continue
        if character == "/" and next_character == "*":
            result.extend((" ", " "))
            block_comment = True
            index += 2
            continue

        result.append(character)
        index += 1

    return "".join(result)


def matching_brace(source: str, opening_brace: int) -> int:
    """Return the matching closing brace, ignoring strings and comments."""

    require(
        0 <= opening_brace < len(source) and source[opening_brace] == "{",
        "Internal test error: block does not start with an opening brace.",
    )
    depth = 0
    index = opening_brace
    quote = ""
    escaped = False
    line_comment = False
    block_comment = False
    while index < len(source):
        character = source[index]
        next_character = source[index + 1] if index + 1 < len(source) else ""

        if line_comment:
            if character == "\n":
                line_comment = False
            index += 1
            continue
        if block_comment:
            if character == "*" and next_character == "/":
                block_comment = False
                index += 2
            else:
                index += 1
            continue
        if quote:
            if escaped:
                escaped = False
            elif character == "\\":
                escaped = True
            elif character == quote:
                quote = ""
            index += 1
            continue
        if character in {'"', "'", "`"}:
            quote = character
            index += 1
            continue
        if character == "/" and next_character == "/":
            line_comment = True
            index += 2
            continue
        if character == "/" and next_character == "*":
            block_comment = True
            index += 2
            continue
        if character == "{":
            depth += 1
        elif character == "}":
            depth -= 1
            if depth == 0:
                return index
        index += 1

    raise AssertionError("Unbalanced QML block in source under test.")


def block_matching(source: str, pattern: str, description: str) -> str:
    """Extract the balanced QML/JavaScript block starting at pattern."""

    match = re.search(pattern, source, flags=re.MULTILINE)
    require(match is not None, f"Missing {description}.")
    assert match is not None
    opening_brace = source.find("{", match.start(), match.end())
    require(opening_brace >= 0, f"Missing opening brace for {description}.")
    closing_brace = matching_brace(source, opening_brace)
    return source[match.start() : closing_brace + 1]


def qml_blocks(source: str, type_name: str) -> list[str]:
    """Return every instantiation block for a qualified QML type."""

    pattern = re.compile(
        rf"^[ \t]*{re.escape(type_name)}[ \t]*\{{",
        flags=re.MULTILINE,
    )
    blocks: list[str] = []
    for match in pattern.finditer(source):
        opening_brace = source.find("{", match.start(), match.end())
        blocks.append(source[match.start() : matching_brace(source, opening_brace) + 1])
    return blocks


def block_containing(blocks: list[str], fragment: str, description: str) -> str:
    """Select the single QML block that contains a behavioral fragment."""

    matches = [block for block in blocks if fragment in block]
    require(len(matches) == 1, f"Expected one {description}; found {len(matches)}.")
    return matches[0]


def assert_folder_component_inventory() -> dict[Path, str]:
    """Confirm and load the seven files that comprise the folder UI."""

    expected_named_components = {
        path.name for path in FOLDER_UI_COMPONENTS if "Folder" in path.name
    }
    discovered_named_components = {
        path.name for path in PUNCHIMENU_DIRECTORY.glob("PunchiMenuFolder*.qml")
    }
    require(
        discovered_named_components == expected_named_components,
        "PunchiMenu folder component inventory changed; extend this contract "
        "before adding or removing folder UI files.",
    )
    require(
        len(FOLDER_UI_COMPONENTS) == 7,
        "The audited PunchiMenu folder UI inventory must contain seven files.",
    )
    return {path: source_for(path) for path in FOLDER_UI_COMPONENTS}


def assert_menu_integration(menu_sources: dict[str, str]) -> None:
    """Check that both menu modes consume the native folder layout."""

    for mode, source in menu_sources.items():
        layout_models = qml_blocks(source, "Punchi.PunchiMenuLayoutModel")
        folder_surfaces = qml_blocks(source, "PunchiMenuFolderSurface")
        require(
            len(layout_models) == 1,
            f"PunchiMenu {mode} must instantiate one PunchiMenuLayoutModel.",
        )
        require(
            len(folder_surfaces) == 1,
            f"PunchiMenu {mode} must instantiate one PunchiMenuFolderSurface.",
        )
        surface = compact(folder_surfaces[0])
        require(
            re.search(r"\blayoutModel\s*:\s*applicationLayoutModel\b", surface)
            is not None,
            f"PunchiMenu {mode} must connect its folder surface to its layout model.",
        )
        require(
            re.search(
                r"\blayoutController\s*:\s*root\.applicationLayoutController\b",
                surface,
            )
            is not None,
            f"PunchiMenu {mode} must connect folder actions to the controller.",
        )

        folder_tiles = qml_blocks(source, "PunchiMenuFolderTile")
        require(
            len(folder_tiles) == 1
            and re.search(r"\bvisible\s*:[^\n]*\bisFolder\b", folder_tiles[0])
            is not None,
            f"PunchiMenu {mode} must render folder tiles only for folder nodes.",
        )


def assert_folder_visibility_gates(normal_source: str, fullscreen_source: str) -> None:
    """Keep organized folder nodes out of categories and search results."""

    normal_compact = compact(normal_source)
    require(
        re.search(
            r"readonly property bool organizedListingActive:\s*"
            r"activeCategoryKey\s*===\s*[\"']All[\"']\s*&&\s*"
            r"searchField\.text\.trim\(\)\.length\s*===\s*0",
            normal_compact,
        )
        is not None,
        "PunchiMenu Normal must expose folders only in All Applications with no search.",
    )
    normal_node_lookup = block_matching(
        normal_source,
        r"function\s+applicationNodeAt\s*\([^)]*\)\s*\{",
        "PunchiMenu Normal application node lookup",
    )
    require(
        re.search(
            r"if\s*\(\s*organizedListingActive\s*\).*?"
            r"applicationLayoutModel\.nodes\s*\[",
            normal_node_lookup,
            flags=re.DOTALL,
        )
        is not None,
        "PunchiMenu Normal must read folder nodes only through the organized gate.",
    )
    require(
        re.search(r"\bnodeType\s*:\s*[\"']application[\"']", normal_node_lookup)
        is not None,
        "PunchiMenu Normal fallback results must remain application nodes.",
    )

    fullscreen_compact = compact(fullscreen_source)
    require(
        re.search(
            r"readonly property bool organizedListingActive:\s*"
            r"searchText\.trim\(\)\.length\s*===\s*0",
            fullscreen_compact,
        )
        is not None,
        "PunchiMenu Fullscreen must expose folders only in its all-applications "
        "view with no search.",
    )
    fullscreen_listing = block_matching(
        fullscreen_source,
        r"readonly\s+property\s+var\s+visibleApplications\s*:\s*\{",
        "PunchiMenu Fullscreen visible application projection",
    )
    require(
        re.search(
            r"if\s*\(\s*organizedListingActive\s*\).*?"
            r"applicationLayoutModel\.nodes",
            fullscreen_listing,
            flags=re.DOTALL,
        )
        is not None,
        "PunchiMenu Fullscreen must read folder nodes only through the no-search gate.",
    )


def assert_folder_component_boundaries(folder_sources: dict[Path, str]) -> None:
    """Keep persistence, commands, and transient windows outside folder UI."""

    forbidden_storage = (
        (r"\bPlasmoid\s*\.\s*configuration\b", "Plasmoid.configuration"),
        (r"\bdockItemsJson\b", "dockItemsJson"),
        (r"\bapplicationLayout\b", "applicationLayout"),
    )
    forbidden_command = re.compile(
        r"\b(?:command|appCommand|launchApplicationByCommand)\b",
        flags=re.IGNORECASE,
    )
    forbidden_window_type = re.compile(
        r"^[ \t]*(?:[A-Za-z_][A-Za-z0-9_]*\.)*"
        r"(?:Dialog|Popup|Timer)[ \t]*\{",
        flags=re.MULTILINE,
    )

    label_count = 0
    for path, source in folder_sources.items():
        code = without_comments(source)
        for pattern, name in forbidden_storage:
            require(
                re.search(pattern, code) is None,
                f"{path.name} must not access {name} directly.",
            )
        require(
            forbidden_command.search(code) is None,
            f"{path.name} must use storage identities, not command execution data.",
        )
        require(
            forbidden_window_type.search(code) is None,
            f"{path.name} must not instantiate Dialog, Popup, or Timer.",
        )

        for label_type in (
            "PlasmaComponents.Label",
            "Kirigami.Label",
            "Controls.Label",
            "Text",
        ):
            for label in qml_blocks(code, label_type):
                if re.search(r"\btext\s*:", label) is None:
                    continue
                label_count += 1
                require(
                    re.search(r"\btextFormat\s*:\s*Text\.PlainText\b", label)
                    is not None,
                    f"Dynamic label in {path.name} must render as Text.PlainText.",
                )

    require(label_count > 0, "Folder UI must expose audited dynamic labels.")


def assert_bounded_collections(folder_sources: dict[Path, str]) -> None:
    """Require virtualization for collections and a bounded folder preview."""

    action_state = folder_sources[
        PUNCHIMENU_DIRECTORY / "PunchiMenuFolderActionState.qml"
    ]
    action_content = folder_sources[
        PUNCHIMENU_DIRECTORY / "PunchiMenuFolderActionContent.qml"
    ]
    folder_view = folder_sources[
        PUNCHIMENU_DIRECTORY / "PunchiMenuFolderView.qml"
    ]
    folder_tile = folder_sources[
        PUNCHIMENU_DIRECTORY / "PunchiMenuFolderTile.qml"
    ]
    folder_surface = compact(
        folder_sources[PUNCHIMENU_DIRECTORY / "PunchiMenuFolderSurface.qml"]
    )
    modal_surface = compact(
        folder_sources[PUNCHIMENU_DIRECTORY / "PunchiMenuModalSurface.qml"]
    )

    action_lists = qml_blocks(action_content, "ListView")
    require(
        any("model: root.applicationCandidates" in compact(block) for block in action_lists),
        "Folder creation candidates must use a virtualized ListView.",
    )
    require(
        any("model: root.availableFolders" in compact(block) for block in action_lists),
        "Folder destinations must use a virtualized ListView.",
    )

    state_compact = compact(action_state)
    content_compact = compact(action_content)
    require(
        "scrollBarReserve" in action_content
        and "applicationScrollBar.implicitWidth" in action_content
        and "folderScrollBar.implicitWidth" in action_content
        and action_content.count("- applicationList.scrollBarReserve") == 1
        and action_content.count("- folderList.scrollBarReserve") == 1,
        "Folder action lists must reserve space for their vertical scrollbars.",
    )
    require(
        "gridScrollBarReserve" in folder_view
        and "applicationScrollBar.implicitWidth" in folder_view
        and "availableGridWidth" in folder_view,
        "Folder member grids must reserve space for their vertical scrollbar.",
    )
    require(
        re.search(
            r"readonly property int maximumFolderMembers\s*:\s*128",
            state_compact,
        )
        is not None,
        "Folder creation UI must share the backend member limit of 128.",
    )
    selection_update = block_matching(
        action_state,
        r"function\s+setStorageIdSelected\s*\([^)]*\)\s*\{",
        "folder member selection update",
    )
    require(
        re.search(
            r"next\.length\s*>=\s*maximumFolderMembers.*?return",
            selection_update,
            flags=re.DOTALL,
        )
        is not None,
        "Folder creation must reject selections beyond 128 before submission.",
    )
    require(
        "selectedApplicationCount >= root.maximumFolderMembers"
        in content_compact
        and "selectionBlocked" in content_compact
        and "selectionSummary" in content_compact,
        "Folder creation must disable excess candidates and expose the limit.",
    )

    folder_grids = qml_blocks(folder_view, "GridView")
    require(
        len(folder_grids) == 1
        and "model: root.members || []" in compact(folder_grids[0]),
        "Folder members must use one virtualized GridView.",
    )
    for collection in action_lists + folder_grids:
        normalized = compact(collection)
        require(
            "clip: true" in normalized
            and "boundsBehavior: Flickable.StopAtBounds" in normalized,
            "Virtualized folder collections must be clipped and bounded.",
        )

    preview_repeaters = qml_blocks(folder_tile, "Repeater")
    require(len(preview_repeaters) == 1, "Folder tile must have one bounded preview.")
    require(
        re.search(
            r"\bmodel\s*:\s*Math\.min\s*\(\s*4\s*,",
            preview_repeaters[0],
        )
        is not None,
        "Folder tile preview must instantiate at most four icons.",
    )

    require(
        "maximumWidth: root.width - Kirigami.Units.largeSpacing * 2"
        in folder_surface
        and "maximumHeight: root.height - Kirigami.Units.largeSpacing * 2"
        in folder_surface,
        "Folder surface must stay inside the owning menu.",
    )
    require(
        re.search(
            r"width:\s*Math\.max\(0,\s*Math\.min\(root\.preferredWidth,\s*"
            r"root\.maximumWidth\)\)",
            modal_surface,
        )
        is not None
        and re.search(
            r"height:\s*Math\.max\(0,\s*Math\.min\(root\.preferredHeight,\s*"
            r"root\.maximumHeight\)\)",
            modal_surface,
        )
        is not None,
        "Folder modal dimensions must be clamped to their maximum bounds.",
    )


def assert_folder_action_contracts(
    menu_sources: dict[str, str], folder_sources: dict[Path, str]
) -> None:
    """Protect placement gates and destructive-action confirmations."""

    for mode, source in menu_sources.items():
        if mode == "Normal":
            inventory_names = (
                "standaloneApplicationContextEntries",
                "folderMemberContextEntries",
                "folderContextEntries",
            )
            inventories = {
                name: block_matching(
                    source,
                    rf"function\s+{name}\s*\([^)]*\)\s*\{{",
                    f"PunchiMenu Normal {name}",
                )
                for name in inventory_names
            }
            require(
                'contextEntry("moveToFolder"' in inventories[
                    "standaloneApplicationContextEntries"
                ]
                and re.search(
                    r"folderChoiceCount\s*>\s*0",
                    inventories["standaloneApplicationContextEntries"],
                )
                is not None,
                "PunchiMenu Normal must disable Move when no destination exists.",
            )
            require(
                'contextEntry("removeFromFolder"' in inventories[
                    "folderMemberContextEntries"
                ],
                "PunchiMenu Normal member inventory must expose removal.",
            )
            require(
                'contextEntry("dissolveFolder"' in inventories[
                    "folderContextEntries"
                ],
                "PunchiMenu Normal folder inventory must expose dissolution.",
            )
            for name, inventory in inventories.items():
                require(
                    "visible:" not in without_comments(inventory),
                    f"PunchiMenu Normal {name} must not retain hidden rows.",
                )
            dispatcher = block_matching(
                source,
                r"function\s+activateContextMenuAction\s*\([^)]*\)\s*\{",
                "PunchiMenu Normal context action dispatcher",
            )
            for marker in (
                "root.beginMoveToFolder(",
                "root.beginRemoveFromFolder(",
                "root.beginDissolveFolder(",
            ):
                require(
                    marker in dispatcher,
                    f"PunchiMenu Normal dispatcher is missing {marker}",
                )
            continue

        menu_items = qml_blocks(source, "PlasmaComponents.MenuItem")
        menu_items += qml_blocks(source, "PlasmaExtras.MenuItem")

        move_marker = "folderSurface.beginMove("
        remove_marker = "folderSurface.beginRemove("
        dissolve_marker = "folderSurface.beginDissolve("

        move_item = block_containing(
            menu_items,
            move_marker,
            f"PunchiMenu {mode} Move to Folder action",
        )
        require(
            re.search(
                r"\benabled\s*:.*?folderChoiceCount\s*>\s*0",
                move_item,
                flags=re.DOTALL,
            )
            is not None,
            f"PunchiMenu {mode} must reactively disable Move when no destination exists.",
        )
        block_containing(
            menu_items,
            remove_marker,
            f"PunchiMenu {mode} Remove from Folder action",
        )
        block_containing(
            menu_items,
            dissolve_marker,
            f"PunchiMenu {mode} Dissolve Folder action",
        )

        require(
            "standaloneApplicationContextMenu" in source
            and "folderMemberContextMenu" in source
            and "folderContextMenu" in source,
            f"PunchiMenu {mode} must keep standalone, member and folder menus separate.",
        )
        menu_owner_type = "PlasmaComponents.Menu"
        menu_ids = (
            "standaloneApplicationContextMenu",
            "folderMemberContextMenu",
            "folderContextMenu",
        )
        for menu_id in menu_ids:
            menu_block = block_matching(
                source,
                rf"{re.escape(menu_owner_type)}\s*\{{\s*id\s*:\s*{menu_id}\b",
                f"PunchiMenu {mode} {menu_id}",
            )
            require(
                "visible:" not in without_comments(menu_block),
                f"PunchiMenu {mode} {menu_id} must not retain hidden menu rows.",
            )

    action_state = folder_sources[
        PUNCHIMENU_DIRECTORY / "PunchiMenuFolderActionState.qml"
    ]
    choices = block_matching(
        action_state,
        r"function\s+queryFolderChoices\s*\([^)]*\)\s*\{",
        "folder destination query",
    )
    require(
        re.search(
            r"applicationPlacement\s*\(.*?"
            r"placement\.placement\s*!==\s*[\"']standalone[\"'].*?"
            r"return\s*\[\s*\]",
            choices,
            flags=re.DOTALL,
        )
        is not None,
        "Folder destination query must reject non-standalone applications.",
    )
    state_compact = compact(action_state)
    require(
        re.search(
            r"requestDissolveFolder\s*\(\s*folderId\s*,\s*true\s*\)",
            state_compact,
        )
        is not None,
        "Dissolve Folder must request explicit confirmation.",
    )
    require(
        re.search(
            r"requestRemoveApplicationFromFolder\s*\(\s*sourceStorageId\s*,\s*"
            r"folderId\s*,\s*true\s*\)",
            state_compact,
        )
        is not None,
        "Remove from Folder must request explicit confirmation.",
    )

    action_content = compact(
        folder_sources[
            PUNCHIMENU_DIRECTORY / "PunchiMenuFolderActionContent.qml"
        ]
    )
    require(
        re.search(
            r"visible:\s*root\.mode\s*===\s*[\"']dissolve[\"']\s*\|\|\s*"
            r"root\.mode\s*===\s*[\"']remove[\"']",
            action_content,
        )
        is not None
        and "id: primaryButton" in action_content,
        "Remove and dissolve operations must pass through the confirmation view.",
    )

    modal_surface = folder_sources[
        PUNCHIMENU_DIRECTORY / "PunchiMenuModalSurface.qml"
    ]
    folder_surface = folder_sources[
        PUNCHIMENU_DIRECTORY / "PunchiMenuFolderSurface.qml"
    ]
    require(
        "property var allowedExternalFocusItems: []" in modal_surface
        and "function acceptsFocusItem(item)" in modal_surface
        and "root.acceptsFocusItem(focusedItem)" in modal_surface,
        "Folder modal must allow the active context-menu focus branch.",
    )
    require(
        "property var allowedExternalFocusItems: []" in folder_surface
        and "allowedExternalFocusItems: root.allowedExternalFocusItems"
        in folder_surface
        and "function restoreFocus()" in folder_surface,
        "Folder surface must expose the context-menu focus allowlist and restoration.",
    )
    fullscreen_source = menu_sources["Fullscreen"]
    require(
        "folderMemberContextMenu.contentItem" in fullscreen_source
        and "allowedExternalFocusItems:" in fullscreen_source
        and "operationInlineMessage" in fullscreen_source,
        "Fullscreen must allow the folder-member menu to retain keyboard focus.",
    )
    operation_message = block_matching(
        fullscreen_source,
        r"Kirigami\.InlineMessage\s*\{",
        "PunchiMenu Fullscreen operation message",
    )
    require(
        "id: operationInlineMessage" in compact(operation_message)
        and "y: mainContentContainer.y + gridArea.y" in compact(operation_message)
        and "z: 240" in compact(operation_message)
        and fullscreen_source.rfind("PunchiMenuFolderSurface {")
        < fullscreen_source.rfind("Kirigami.InlineMessage {"),
        "Fullscreen operation feedback must remain above the folder modal layer.",
    )


def assert_exact_case_hidden_ids(
    main_source: str, menu_sources: dict[str, str]
) -> None:
    """Prevent case folding of desktop-file storage identities."""

    lower_case_call = re.compile(r"\.to(?:Locale)?LowerCase\s*\(")
    configured_ids = block_matching(
        main_source,
        r"readonly\s+property\s+var\s+"
        r"configuredPunchiMenuHiddenApplicationIds\s*:\s*\{",
        "configured hidden application ID normalization",
    )
    require(
        lower_case_call.search(configured_ids) is None,
        "main.qml must preserve hidden application ID case.",
    )
    configured_compact = compact(configured_ids)
    require(
        re.search(
            r"comparisonKey\s*=\s*[\"']#[\"']\s*\+\s*storageId",
            configured_compact,
        )
        is not None
        and re.search(r"result\.push\s*\(\s*storageId\s*\)", configured_compact)
        is not None,
        "main.qml must deduplicate and retain exact hidden storage IDs.",
    )

    for mode, source in menu_sources.items():
        lookup = block_matching(
            source,
            r"readonly\s+property\s+var\s+hiddenApplicationLookup\s*:\s*\{",
            f"PunchiMenu {mode} hidden application lookup",
        )
        hidden_check = block_matching(
            source,
            r"function\s+isApplicationHidden\s*\([^)]*\)\s*\{",
            f"PunchiMenu {mode} hidden application check",
        )
        hidden_count = block_matching(
            source,
            r"readonly\s+property\s+int\s+hiddenApplicationCount\s*:\s*\{",
            f"PunchiMenu {mode} hidden application count",
        )
        for description, block in (
            ("lookup", lookup),
            ("check", hidden_check),
            ("count", hidden_count),
        ):
            require(
                lower_case_call.search(block) is None,
                f"PunchiMenu {mode} hidden ID {description} must preserve case.",
            )
        require(
            re.search(
                r"lookup\s*\[\s*[\"']#[\"']\s*\+\s*storageId\s*\]\s*=\s*true",
                compact(lookup),
            )
            is not None,
            f"PunchiMenu {mode} must index exact hidden storage IDs.",
        )
        require(
            re.search(
                r"hiddenApplicationLookup\s*\[\s*[\"']#[\"']\s*\+\s*"
                r"normalizedId\s*\]",
                compact(hidden_check),
            )
            is not None,
            f"PunchiMenu {mode} must query hidden IDs without case folding.",
        )


def assert_modal_interaction_and_accessibility(
    menu_sources: dict[str, str], folder_sources: dict[Path, str]
) -> None:
    """Keep folder surfaces modal, bounded, and exposed once to assistive tech."""

    modal_source = folder_sources[
        PUNCHIMENU_DIRECTORY / "PunchiMenuModalSurface.qml"
    ]
    modal_compact = compact(modal_source)
    require(
        "Accessible.role: Accessible.Dialog" in modal_compact,
        "The internal folder surface must expose dialog semantics.",
    )
    require(
        "Keys.priority: Keys.BeforeItem" in modal_compact
        and "Keys.onTabPressed:" in modal_compact
        and "Keys.onBacktabPressed:" in modal_compact
        and "moveFocusWithinSurface" in modal_compact
        and "containsFocusItem" in modal_compact,
        "The modal folder surface must trap forward and reverse Tab focus.",
    )
    require(
        modal_compact.count("wheel.accepted = true") >= 2,
        "The modal backdrop and empty panel area must consume wheel input.",
    )
    require(
        "property real backdropOpacity: 0.64" in modal_compact
        and "root.backdropOpacity" in modal_compact,
        "The modal surface must expose a visual backdrop opacity without "
        "removing its input-blocking layer.",
    )

    folder_tile = compact(
        folder_sources[PUNCHIMENU_DIRECTORY / "PunchiMenuFolderTile.qml"]
    )
    folder_view = compact(
        folder_sources[PUNCHIMENU_DIRECTORY / "PunchiMenuFolderView.qml"]
    )
    normal_source = menu_sources["Normal"]
    normal_compact = compact(normal_source)
    normal_backdrop_geometry = compact(
        block_matching(
            normal_source,
            r"readonly property rect folderDialogBackdropGeometry\s*:\s*\{",
            "PunchiMenu Normal folder backdrop geometry",
        )
    )
    normal_folder_tile = compact(
        qml_blocks(normal_source, "PunchiMenuFolderTile")[0]
    )
    require(
        "normalBackground.inset.left" in normal_backdrop_geometry
        and "normalBackground.inset.top" in normal_backdrop_geometry
        and "normalBackground.inset.right" in normal_backdrop_geometry
        and "normalBackground.inset.bottom" in normal_backdrop_geometry
        and "root, Qt.point(leftInset, topInset)"
        in normal_backdrop_geometry
        and "normalBackground.width - rightInset" in normal_backdrop_geometry
        and "normalBackground.height - bottomInset" in normal_backdrop_geometry
        and "normalBackground.margins" not in normal_backdrop_geometry,
        "PunchiMenu Normal folder veil must follow the effective themed "
        "surface through FrameSvg insets instead of content margins or the "
        "uncontracted projected frame.",
    )
    require(
        "Accessible.onPressAction: root.activated()" in folder_tile,
        "Folder tiles must expose their activation action to assistive tech.",
    )
    require(
        "readonly property alias hovered: pointer.containsMouse" in folder_tile,
        "Folder tiles must expose their pointer hover state to their menu delegate.",
    )
    require(
        "readonly property bool pointerHovered: "
        "delegatePointer.containsMouse "
        "&& root.applicationHoverAllowed" in normal_compact
        and "readonly property bool selected: keyboardFocused || pointerHovered"
        in normal_compact,
        "PunchiMenu Normal must select applications and folders through one "
        "pointer-hover contract.",
    )
    require(
        "id: folderTile" in normal_folder_tile
        and "selected: applicationDelegate.selected "
        "|| nodeDropTarget.containsDrag" in normal_folder_tile
        and "onHoveredChanged:" not in normal_folder_tile,
        "PunchiMenu Normal must route folder hover and drag selection through "
        "the shared delegate pointer.",
    )
    require(
        "Accessible.onPressAction: launchApplication()" in folder_view,
        "Applications inside folders must expose their launch action.",
    )
    require(
        "property real applicationHighlightOpacity: 0.30" in folder_view
        and "property real applicationCornerRadiusScale: 1.0" in folder_view
        and "property real applicationHoverScale: 1.0" in folder_view
        and "root.applicationHighlightOpacity" in folder_view
        and "root.applicationCornerRadiusScale" in folder_view
        and "root.applicationHoverScale" in folder_view,
        "Folder application delegates must expose a reusable themed hover profile.",
    )
    require(
        "readonly property bool highlighted: activeFocus "
        "|| appPointer.containsMouse" in folder_view
        and "scale: applicationDelegate.highlighted "
        "? root.applicationHoverScale : 1.0" in folder_view
        and "Behavior on scale" in folder_view
        and "Behavior on border.color" in folder_view,
        "Folder application hover must preserve focus visibility and animate "
        "the same visual properties as the parent grids.",
    )
    require(
        "id: applicationLabelFontMetrics" in folder_view
        and "font: Kirigami.Theme.defaultFont" in folder_view
        and "applicationLabelFontMetrics.height * 2" in folder_view
        and "maximumApplicationLabelHeight" in folder_view
        and "Kirigami.Units.smallSpacing * 5" in folder_view
        and "font: applicationLabelFontMetrics.font" in folder_view,
        "Folder grid cells must reserve themed font space for two label lines, "
        "the icon, layout spacing, and vertical margins.",
    )
    rename_button_position = folder_view.find("id: renameButton")
    dismiss_button_position = folder_view.find("id: dismissButton")
    require(
        rename_button_position >= 0
        and dismiss_button_position > rename_button_position
        and 'icon.name: "window-close"' in folder_view
        and 'text: i18nc("@action:button", "Close")' in folder_view
        and "mainText: dismissButton.text" in folder_view
        and "onClicked: root.closeRequested()" in folder_view,
        "Folder views must expose a themed close button at the trailing edge "
        "and reuse the existing close request.",
    )
    require(
        "readonly property bool isHiddenApplication" in folder_view
        and "modelData && modelData.appHidden" in folder_view
        and "opacity: isHiddenApplication ? 0.58 : 1.0" in folder_view,
        "Revealed hidden applications inside folders must retain their visual indicator.",
    )
    require(
        "property bool detailedApplicationFeedback: false" in folder_view
        and 'source: "view-hidden-symbolic"' in folder_view
        and "root.detailedApplicationFeedback" in folder_view
        and "appPointer.containsMouse" in folder_view,
        "Fullscreen folder members must support explicit hidden and hover feedback.",
    )

    folder_surface_compact = compact(
        folder_sources[PUNCHIMENU_DIRECTORY / "PunchiMenuFolderSurface.qml"]
    )
    require(
        'readonly property bool useWidgetModalProfile: viewMode === "action" '
        '|| viewMode === "folder"'
        in folder_surface_compact
        and 'root.useWidgetModalProfile ? "widgets/background"'
        in folder_surface_compact
        and "backdropOpacity: 0.64"
        in folder_surface_compact
        and "panelShadowEnabled: root.viewMode === \"action\" "
        "&& !root.useWidgetModalProfile" in folder_surface_compact,
        "All PunchiMenu folder and action surfaces must use the shared "
        "widget-themed modal profile.",
    )
    for mode, expected_profile in {
        "Normal": (
            "applicationHighlightOpacity: 0.30",
            "applicationCornerRadiusScale: 1.5",
            "applicationHoverScale: 1.018",
        ),
        "Fullscreen": (
            "applicationHighlightOpacity: 0.30",
            "applicationCornerRadiusScale: 2.0",
            "applicationHoverScale: 1.03",
        ),
    }.items():
        menu_compact = compact(menu_sources[mode])
        require(
            all(fragment in menu_compact for fragment in expected_profile),
            f"PunchiMenu {mode} must pass its main-grid hover profile to "
            "applications opened inside folders.",
        )
    require(
        "property bool returnToFolderAfterMemberRemoval: false"
        in folder_surface_compact
        and re.search(
            r'actionView\.mode\s*===\s*["\']remove["\'].*?'
            r'returnToFolderAfterMemberRemoval.*?'
            r'openFolder\s*\(\s*actionOriginFolderId\s*\)',
            folder_surface_compact,
        )
        is not None,
        "Removing a member must be able to return to a surviving folder.",
    )
    require(
        "property bool compactLayout: false" in folder_surface_compact
        and "readonly property real compactFolderPreferredWidth"
        in folder_surface_compact
        and "readonly property real compactFolderPreferredHeight"
        in folder_surface_compact,
        "Folder surfaces must expose bounded content-aware compact geometry.",
    )

    fullscreen_surface = compact(
        qml_blocks(menu_sources["Fullscreen"], "PunchiMenuFolderSurface")[0]
    )
    normal_surface = compact(
        qml_blocks(menu_sources["Normal"], "PunchiMenuFolderSurface")[0]
    )
    require(
        "detailedApplicationFeedback: true" in fullscreen_surface
        and "returnToFolderAfterMemberRemoval: true" in fullscreen_surface,
        "Fullscreen must opt into detailed folder feedback and context preservation.",
    )
    require(
        "detailedApplicationFeedback: true" in normal_surface
        and "compactLayout: true" in normal_surface
        and "returnToFolderAfterMemberRemoval: true" not in normal_surface,
        "PunchiMenu Normal must use compact folder geometry and detailed "
        "feedback without changing its approved member-removal navigation policy.",
    )
    require(
        "compactLayout: true" not in fullscreen_surface,
        "PunchiMenu Fullscreen must preserve its spacious folder geometry.",
    )

    for mode, source in menu_sources.items():
        require(
            "Accessible.ignored: isFolder" in compact(source),
            f"PunchiMenu {mode} must not duplicate the folder tile accessible node.",
        )

    fullscreen_compact = compact(menu_sources["Fullscreen"])
    wheel_handler = block_matching(
        menu_sources["Fullscreen"],
        r"Kirigami\.WheelHandler\s*\{",
        "PunchiMenu Fullscreen wheel handler",
    )
    require(
        re.search(
            r"if\s*\(\s*folderSurface\.active\s*\).*?"
            r"wheel\.accepted\s*=\s*true.*?return",
            wheel_handler,
            flags=re.DOTALL,
        )
        is not None,
        "Fullscreen wheel pagination must ignore input while a folder surface is open.",
    )
    reconcile = block_matching(
        menu_sources["Fullscreen"],
        r"function\s+reconcileApplicationSelection\s*\([^)]*\)\s*\{",
        "PunchiMenu Fullscreen selection reconciliation",
    )
    require(
        re.search(
            r"visibleApplications\.length\s*-\s*1.*?"
            r"currentApplicationIndex",
            reconcile,
            flags=re.DOTALL,
        )
        is not None
        and re.search(
            r"onVisibleApplicationsChanged\s*:\s*Qt\.callLater\s*\(\s*"
            r"root\.reconcileApplicationSelection\s*\)",
            menu_sources["Fullscreen"],
        )
        is not None,
        "Fullscreen must clamp its selected application after projection changes.",
    )


def assert_exact_case_favorite_ids(menu_sources: dict[str, str]) -> None:
    """Keep favorite desktop-file identities exact on case-sensitive systems."""

    lower_case_call = re.compile(r"\.to(?:Locale)?LowerCase\s*\(")
    for mode, source in menu_sources.items():
        favorite_check = block_matching(
            source,
            r"function\s+isFavorite\s*\([^)]*\)\s*\{",
            f"PunchiMenu {mode} favorite identity check",
        )
        require(
            lower_case_call.search(favorite_check) is None,
            f"PunchiMenu {mode} favorite IDs must preserve case.",
        )

    controller_source = source_for(
        PROJECT_ROOT / "contents/ui/components/PunchiMenuFavoritesController.qml"
    )
    for function_name in ("refresh", "containsFavorite", "removeFavorite"):
        function_block = block_matching(
            controller_source,
            rf"function\s+{function_name}\s*\([^)]*\)\s*\{{",
            f"favorites controller {function_name}",
        )
        require(
            lower_case_call.search(function_block) is None,
            f"Favorites controller {function_name} must preserve ID case.",
        )


def assert_layout_conflict_reconciliation(main_source: str) -> None:
    """Keep durable state reconciliation on layout compare-and-swap conflicts."""

    handler = block_matching(
        main_source,
        r"onPersistenceRequested\s*:\s*function\s*\([^)]*\)\s*\{",
        "PunchiMenu persistence request handler",
    )
    require(
        re.search(
            r"errorCode\s*===\s*[\"']layout-conflict[\"']",
            handler,
        )
        is not None,
        "PunchiMenu persistence must recognize layout-conflict.",
    )
    rejection = handler.find("rejectPersistence(")
    reconciliation = handler.find("reconcileDockItemsJson(")
    require(
        rejection >= 0 and reconciliation > rejection,
        "A layout conflict must reject the transaction before durable reconciliation.",
    )


def main() -> None:
    """Run the complete static folder UI contract."""

    folder_sources = assert_folder_component_inventory()
    menu_sources = {mode: source_for(path) for mode, path in MENU_PATHS.items()}
    main_source = source_for(PROJECT_ROOT / "contents/ui/main.qml")

    assert_menu_integration(menu_sources)
    assert_folder_visibility_gates(
        menu_sources["Normal"], menu_sources["Fullscreen"]
    )
    assert_folder_component_boundaries(folder_sources)
    assert_bounded_collections(folder_sources)
    assert_folder_action_contracts(menu_sources, folder_sources)
    assert_exact_case_hidden_ids(main_source, menu_sources)
    assert_modal_interaction_and_accessibility(menu_sources, folder_sources)
    assert_exact_case_favorite_ids(menu_sources)
    assert_layout_conflict_reconciliation(main_source)

    print("PunchiMenu folder UI contract: PASS")


if __name__ == "__main__":
    main()
