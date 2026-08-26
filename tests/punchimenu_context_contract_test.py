#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later

from pathlib import Path
import re
import sys


PROJECT_ROOT = Path(__file__).resolve().parents[1]


def argument_counts(source: str, symbol: str) -> list[int]:
    counts: list[int] = []
    offset = 0
    marker = f"{symbol}("
    while True:
        start = source.find(marker, offset)
        if start < 0:
            return counts
        index = start + len(marker)
        depth = 1
        commas = 0
        quote = ""
        escaped = False
        while index < len(source) and depth > 0:
            character = source[index]
            if quote:
                if escaped:
                    escaped = False
                elif character == "\\":
                    escaped = True
                elif character == quote:
                    quote = ""
            elif character in {'"', "'"}:
                quote = character
            elif character == "(":
                depth += 1
            elif character == ")":
                depth -= 1
            elif character == "," and depth == 1:
                commas += 1
            index += 1
        if depth != 0:
            raise ValueError(f"Unbalanced call to {symbol}")
        counts.append(commas + 1)
        offset = index


def check_component(relative_path: str) -> bool:
    source = (PROJECT_ROOT / relative_path).read_text(encoding="utf-8")
    expected_signal = (
        "signal pinToDockRequested(string storageId, string appName, "
        "string appIcon, string appCommand)"
    )
    if expected_signal not in source:
        print(f"{relative_path}: incomplete pinToDockRequested contract", file=sys.stderr)
        return False
    counts = argument_counts(source, "openApplicationContextMenu")
    if not counts or any(count != 7 for count in counts):
        print(f"{relative_path}: context-menu argument counts are {counts}", file=sys.stderr)
        return False
    return True


def main() -> int:
    passed = check_component(
        "contents/ui/components/punchimenu/PunchiMenuNormal.qml"
    )
    passed = check_component(
        "contents/ui/components/punchimenu/PunchiMenuOverlay.qml"
    ) and passed

    normal_source = (
        PROJECT_ROOT / "contents/ui/components/punchimenu/PunchiMenuNormal.qml"
    ).read_text(encoding="utf-8")
    compact_menu_source = (
        PROJECT_ROOT / "contents/ui/components/punchimenu/PunchiMenuCompact.qml"
    ).read_text(encoding="utf-8")
    mapped_surface_geometry_source = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuMappedSurfaceGeometry.qml"
    ).read_text(encoding="utf-8")
    normal_context_surface_source = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuContextSurface.qml"
    ).read_text(encoding="utf-8")
    overlay_source = (
        PROJECT_ROOT / "contents/ui/components/punchimenu/PunchiMenuOverlay.qml"
    ).read_text(encoding="utf-8")
    category_sections_source = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuCategorySectionsView.qml"
    ).read_text(encoding="utf-8")
    drag_layer_source = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuDragLayer.qml"
    ).read_text(encoding="utf-8")
    icon_metrics_source = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuIconMetrics.qml"
    ).read_text(encoding="utf-8")
    folder_tile_source = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuFolderTile.qml"
    ).read_text(encoding="utf-8")
    folder_view_source = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuFolderView.qml"
    ).read_text(encoding="utf-8")
    folder_surface_source = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuFolderSurface.qml"
    ).read_text(encoding="utf-8")
    main_source = (PROJECT_ROOT / "contents/ui/main.qml").read_text(encoding="utf-8")
    config_items_source = (
        PROJECT_ROOT / "contents/ui/config/code/configItems.js"
    ).read_text(encoding="utf-8")
    dock_items_controller_source = (
        PROJECT_ROOT / "contents/ui/components/DockItemsController.qml"
    ).read_text(encoding="utf-8")
    dock_context_actions_source = (
        PROJECT_ROOT / "contents/ui/components/DockContextActionsController.qml"
    ).read_text(encoding="utf-8")
    app_actions_popup_source = (
        PROJECT_ROOT / "contents/ui/components/AppActionsPopup.qml"
    ).read_text(encoding="utf-8")
    dialog_source = (
        PROJECT_ROOT / "contents/ui/config/components/PunchiMenuDialog.qml"
    ).read_text(encoding="utf-8")
    placement_source = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuNormalPlacement.qml"
    ).read_text(encoding="utf-8")
    category_pill_source = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuCategoryPill.qml"
    ).read_text(encoding="utf-8")
    search_background_source = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuSearchBackground.qml"
    ).read_text(encoding="utf-8")
    action_background_source = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuActionBackground.qml"
    ).read_text(encoding="utf-8")
    item_highlight_source = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuItemHighlight.qml"
    ).read_text(encoding="utf-8")
    session_view_source = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuSessionView.qml"
    ).read_text(encoding="utf-8")
    normal_settings_view_source = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuNormalSettingsView.qml"
    ).read_text(encoding="utf-8")
    fullscreen_settings_view_source = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuFullScreenSettingsView.qml"
    ).read_text(encoding="utf-8")
    settings_view_source = (
        normal_settings_view_source
        + "\n"
        + fullscreen_settings_view_source
    )
    fullscreen_combo_source = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuFullScreenComboBox.qml"
    ).read_text(encoding="utf-8")
    avatar_component_source = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuUserAvatar.qml"
    ).read_text(encoding="utf-8")
    avatar_shader_source = (
        PROJECT_ROOT / "src/shaders/PunchiMenuAvatar.frag"
    ).read_text(encoding="utf-8")
    native_build_source = (
        PROJECT_ROOT / "src/CMakeLists.txt"
    ).read_text(encoding="utf-8")
    fedora_setup_source = (
        PROJECT_ROOT / "scripts-dev/distro/fedora-setup.sh"
    ).read_text(encoding="utf-8")
    debian_setup_source = (
        PROJECT_ROOT / "scripts-dev/distro/debian13-setup.sh"
    ).read_text(encoding="utf-8")
    session_controller_source = (
        PROJECT_ROOT / "src/sessionactionscontroller.cpp"
    ).read_text(encoding="utf-8")
    workflow_source = (
        PROJECT_ROOT / "contents/ui/config/code/configItemsWorkflowHelper.js"
    ).read_text(encoding="utf-8")
    config_page_source = (
        PROJECT_ROOT / "contents/ui/config/ConfigItems.qml"
    ).read_text(encoding="utf-8")
    punchi_menu_config_path = (
        PROJECT_ROOT / "contents/ui/config/ConfigPunchiMenu.qml"
    )
    additional_shortcuts_config_source = (
        PROJECT_ROOT / "contents/ui/config/ConfigAdditionalShortcuts.qml"
    ).read_text(encoding="utf-8")
    config_model_source = (
        PROJECT_ROOT / "contents/config/config.qml"
    ).read_text(encoding="utf-8")
    discovery_header_source = (
        PROJECT_ROOT / "src/systemdiscovery.h"
    ).read_text(encoding="utf-8")
    discovery_implementation_source = (
        PROJECT_ROOT / "src/systemdiscovery.cpp"
    ).read_text(encoding="utf-8")
    if "readonly property string appCommand" not in normal_source:
        print("PunchiMenuNormal.qml: favorite appCommand is not exposed", file=sys.stderr)
        passed = False
    if "readonly property bool isX11Session" in overlay_source:
        print("PunchiMenuOverlay.qml: retired automatic opacity policy remains", file=sys.stderr)
        passed = False
    if "PathView {" in overlay_source or "id: categoryModel" in overlay_source:
        print("PunchiMenuOverlay.qml: the retired category carousel is still present", file=sys.stderr)
        passed = False
    icon_scale_contract = (
        (config_items_source, "Math.max(75, Math.min(150", "persistent normalization"),
        (main_source, "Math.max(75, Math.min(150", "runtime percentage clamp"),
        (settings_view_source, "to: 150", "internal settings slider maximum"),
        (overlay_source, "Math.max(0.75, Math.min(1.5", "fullscreen scale clamp"),
        (normal_source, "Math.max(0.75, Math.min(1.5", "Normal scale clamp"),
    )
    for source, marker, description in icon_scale_contract:
        if marker not in source:
            print(
                f"PunchiMenu icon scale: missing {description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    icon_geometry_contract = (
        (
            icon_metrics_source,
            "readonly property int effectiveSize",
            "shared effective-size projection",
        ),
        (
            icon_metrics_source,
            "Math.min(desiredSize, availableSize)",
            "cell geometry cap",
        ),
        (
            normal_source,
            "requestedIconSize: applicationDelegate.iconSize",
            "Normal folder/application size handoff",
        ),
        (
            overlay_source,
            "requestedIconSize: appDelegate.safeIconSize",
            "Fullscreen folder/application size handoff",
        ),
        (
            folder_tile_source,
            "readonly property int previewSize: iconMetrics.effectiveSize",
            "folder tile geometry cap",
        ),
        (
            folder_view_source,
            "Kirigami.Units.gridUnit * 7.5",
            "folder column width independent from icon scale",
        ),
    )
    for source, marker, description in icon_geometry_contract:
        if marker not in source:
            print(
                f"PunchiMenu icon geometry: missing {description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    if "property real iconScale" in folder_tile_source:
        print(
            "PunchiMenu icon geometry: folder tiles must not receive raw scale",
            file=sys.stderr,
        )
        passed = False
    if "iconSize + Kirigami.Units.gridUnit" in folder_view_source:
        print(
            "PunchiMenu icon geometry: folder columns must not depend on icon size",
            file=sys.stderr,
        )
        passed = False
    folder_grid_limits_contract = (
        (
            config_items_source,
            "function normalizedPunchiMenuNormalFolderMaximumColumns(value)",
            "persistent Normal column normalization",
        ),
        (
            config_items_source,
            "function normalizedPunchiMenuNormalFolderMaximumRows(value)",
            "persistent Normal row normalization",
        ),
        (
            config_items_source,
            "function normalizedPunchiMenuFullScreenFolderMaximumColumns(value)",
            "persistent Fullscreen column normalization",
        ),
        (
            config_items_source,
            "function normalizedPunchiMenuFullScreenFolderMaximumRows(value)",
            "persistent Fullscreen row normalization",
        ),
        (
            config_items_source,
            '"normalFolderMaximumColumns": 3',
            "Normal column default",
        ),
        (
            config_items_source,
            '"normalFolderMaximumRows": 3',
            "Normal row default",
        ),
        (
            config_items_source,
            '"fullScreenFolderMaximumColumns": 5',
            "Fullscreen column default",
        ),
        (
            config_items_source,
            '"fullScreenFolderMaximumRows": 5',
            "Fullscreen row default",
        ),
        (
            settings_view_source,
            '"Maximum folder columns:")',
            "embedded column control",
        ),
        (
            settings_view_source,
            '"Maximum folder rows:")',
            "embedded row control",
        ),
        (
            main_source,
            "readonly property int configuredPunchiMenuNormalFolderMaximumColumns",
            "reactive runtime projection",
        ),
        (
            normal_source,
            "property int folderMaximumColumns: 3",
            "Normal column property",
        ),
        (
            normal_source,
            "property int folderMaximumRows: 3",
            "Normal row property",
        ),
        (
            overlay_source,
            "property int folderMaximumColumns: 5",
            "Fullscreen column property",
        ),
        (
            overlay_source,
            "property int folderMaximumRows: 5",
            "Fullscreen row property",
        ),
        (
            normal_source,
            "maximumColumnCount: root.safeFolderMaximumColumns",
            "Normal folder-surface handoff",
        ),
        (
            overlay_source,
            "maximumColumnCount: root.safeFolderMaximumColumns",
            "Fullscreen folder-surface handoff",
        ),
        (
            folder_surface_source,
            "automaticCompactFolderColumnCount",
            "content-aware preferred width",
        ),
        (
            folder_view_source,
            "geometricColumnCapacity",
            "available-width capacity",
        ),
        (
            folder_view_source,
            "visibleRowCount",
            "bounded visible rows",
        ),
        (
            folder_view_source,
            "Math.min(\n        safeMaximumColumnCount, geometricColumnCapacity)",
            "effective safe maximum",
        ),
    )
    for source, marker, description in folder_grid_limits_contract:
        if marker not in source:
            print(
                f"PunchiMenu folder grid limits: missing {description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    for projection in (
        "configuredPunchiMenuNormalFolderMaximumColumns",
        "configuredPunchiMenuNormalFolderMaximumRows",
        "configuredPunchiMenuFullScreenFolderMaximumColumns",
        "configuredPunchiMenuFullScreenFolderMaximumRows",
    ):
        if main_source.count("root." + projection) != 1:
            print(
                f"PunchiMenu folder grid limits: invalid runtime handoff for {projection}",
                file=sys.stderr,
            )
            passed = False
    if (
        "to: 3" not in normal_settings_view_source
        or "to: 5" not in fullscreen_settings_view_source
    ):
        print(
            "PunchiMenu folder grid limits: isolated ranges must preserve "
            "Normal 1-3 and Fullscreen 1-5",
            file=sys.stderr,
        )
        passed = False
    distribution_name_contract = (
        (
            discovery_header_source,
            "Q_PROPERTY(QString distributionName READ distributionName CONSTANT)",
            "read-only backend property",
        ),
        (
            discovery_header_source,
            "Q_PROPERTY(QString distributionLogo READ distributionLogo CONSTANT)",
            "read-only distribution logo property",
        ),
        (discovery_implementation_source, "KOSRelease", "KDE OS release API"),
        (discovery_implementation_source, "osRelease.logo().trimmed()", "OS logo source"),
        (config_items_source, "item.showDistributionName !== false", "default-on persistence"),
        (settings_view_source, '"showDistributionName", checked', "internal settings routing"),
        (settings_view_source, 'i18n("Show distribution name in full screen")', "translated internal option"),
        (main_source, "readonly property bool configuredPunchiMenuShowDistributionName", "reactive runtime setting"),
        (overlay_source, "property bool showDistributionName: true", "fullscreen display option"),
        (overlay_source, "String(systemDiscovery.distributionName", "distribution label source"),
        (overlay_source, "String(systemDiscovery.distributionLogo", "distribution logo source"),
        (overlay_source, "Kirigami.Units.iconSizes.small", "standard small icon limit"),
        (overlay_source, "Math.round(distributionFontMetrics.height)", "heading line-height limit"),
        (overlay_source, "Accessible.ignored: true", "decorative logo semantics"),
        (search_background_source, "radius: height / 2", "pill-shaped search background"),
        (search_background_source, "color: Kirigami.Theme.backgroundColor", "theme-aware search background"),
        (search_background_source, "? Kirigami.Theme.highlightColor", "themed search focus border"),
    )
    for source, marker, description in distribution_name_contract:
        if marker not in source:
            print(
                f"PunchiMenu distribution label: missing {description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    if 'i18nc("@title:menu", "PunchiMenu")' in overlay_source:
        print(
            "PunchiMenu distribution label: disabled label still has a title fallback",
            file=sys.stderr,
        )
        passed = False
    distribution_reserve_contract = (
        "Layout.preferredHeight: distributionHeading.implicitHeight",
        "visible: root.distributionName.length > 0",
        "opacity: root.showDistributionName ? 1.0 : 0.0",
        "Accessible.ignored: !root.showDistributionName",
    )
    for marker in distribution_reserve_contract:
        if marker not in overlay_source:
            print(
                "PunchiMenu distribution label: missing stable hidden-state "
                f"geometry: {marker}",
                file=sys.stderr,
            )
            passed = False
    distribution_container_start = overlay_source.find(
        "id: distributionTitleContainer")
    distribution_container_end = overlay_source.find(
        "readonly property int logoSize", distribution_container_start)
    distribution_container_header = overlay_source[
        distribution_container_start:distribution_container_end
    ]
    if (distribution_container_start < 0
            or distribution_container_end < 0
            or "visible: root.showDistributionName"
                in distribution_container_header
            or "Layout.preferredHeight: visible"
                in distribution_container_header):
        print(
            "PunchiMenu distribution label: the display setting still "
            "collapses the reserved title row",
            file=sys.stderr,
        )
        passed = False
    if normal_source.count("showDistributionName") != 0:
        print(
            "PunchiMenuNormal.qml: fullscreen distribution setting leaked into Normal mode",
            file=sys.stderr,
        )
        passed = False
    if main_source.count(
        "showDistributionName: root.configuredPunchiMenuShowDistributionName"
    ) != 1:
        print(
            "main.qml: distribution setting must be bound only to Fullscreen",
            file=sys.stderr,
        )
        passed = False
    page_navigation_arrows_contract = (
        (
            config_items_source,
            "item.showPageNavigationArrows !== false",
            "default-on persistence",
        ),
        (
            settings_view_source,
            '"showPageNavigationArrows", checked',
            "internal settings routing",
        ),
        (
            settings_view_source,
            'i18n("Show page navigation arrows")',
            "translated internal option",
        ),
        (
            main_source,
            "readonly property bool configuredPunchiMenuShowPageNavigationArrows:",
            "reactive runtime setting",
        ),
        (
            overlay_source,
            "property bool showPageNavigationArrows: true",
            "fullscreen display option",
        ),
    )
    for source, marker, description in page_navigation_arrows_contract:
        if marker not in source:
            print(
                "PunchiMenu Fullscreen page arrows: missing "
                f"{description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    if len(re.findall(
        r"showPageNavigationArrows:\s*"
        r"root\.configuredPunchiMenuShowPageNavigationArrows",
        main_source,
    )) != 1:
        print(
            "main.qml: page-arrow setting must be bound only to Fullscreen",
            file=sys.stderr,
        )
        passed = False
    if "visible: root.showPageNavigationArrows" in overlay_source:
        print(
            "PunchiMenu Fullscreen page arrows: the display setting must not "
            "remove the button geometry",
            file=sys.stderr,
        )
        passed = False
    visual_only_arrow_contract = (
        (
            "enabled: root.showPageNavigationArrows",
            2,
            "disabled hidden interaction",
        ),
        (
            "opacity: !root.showPageNavigationArrows",
            2,
            "opacity-only hiding",
        ),
        (
            "focusPolicy: root.showPageNavigationArrows",
            2,
            "hidden focus exclusion",
        ),
        (
            "Accessible.ignored: !root.showPageNavigationArrows",
            2,
            "hidden accessibility exclusion",
        ),
        (
            "anchors.leftMargin: root.applicationGridHorizontalInset",
            2,
            "stable left grid inset",
        ),
        (
            "anchors.rightMargin: root.applicationGridHorizontalInset",
            2,
            "stable right grid inset",
        ),
        (
            "function alignCurrentPage()",
            1,
            "page alignment helper",
        ),
        (
            "pagesView.positionViewAtIndex(safePage, ListView.Beginning)",
            1,
            "page-boundary restoration",
        ),
        (
            "onShowPageNavigationArrowsChanged: Qt.callLater(function()",
            1,
            "reactive page realignment",
        ),
    )
    for marker, expected_count, description in visual_only_arrow_contract:
        if overlay_source.count(marker) != expected_count:
            print(
                "PunchiMenu Fullscreen page arrows: expected "
                f"{expected_count} occurrence(s) of {description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    for button_id in ("previousPageButton", "nextPageButton"):
        button_start = overlay_source.find(f"id: {button_id}")
        button_contract = overlay_source[button_start:button_start + 1800]
        if button_start < 0 or (
            "visible: root.applicationViewActive && root.pageCount > 1"
            not in button_contract
        ):
            print(
                "PunchiMenu Fullscreen page arrows: button geometry must "
                f"remain stable while hidden: {button_id}",
                file=sys.stderr,
            )
            passed = False
    if normal_source.count("showPageNavigationArrows") != 0:
        print(
            "PunchiMenuNormal.qml: fullscreen page-arrow setting leaked into "
            "Normal mode",
            file=sys.stderr,
        )
        passed = False
    close_button_position_contract = (
        (
            config_items_source,
            "function normalizedPunchiMenuFullScreenCloseButtonPosition(value)",
            "persistence normalizer",
        ),
        (
            config_items_source,
            'if (item.fullScreenCloseButtonPosition === "right")',
            "default-value pruning",
        ),
        (
            settings_view_source,
            '"fullScreenCloseButtonPosition", option.value',
            "internal settings routing",
        ),
        (
            main_source,
            "readonly property string configuredPunchiMenuFullScreenCloseButtonPosition:",
            "reactive runtime setting",
        ),
        (
            overlay_source,
            "property string closeButtonPosition: \"right\"",
            "fullscreen display option",
        ),
        (
            overlay_source,
            "readonly property int closeButtonCornerMargin: Kirigami.Units.gridUnit",
            "shared corner metric",
        ),
    )
    for source, marker, description in close_button_position_contract:
        if marker not in source:
            print(
                "PunchiMenu Fullscreen close button: missing "
                f"{description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    if len(re.findall(
        r"closeButtonPosition:\s*"
        r"root\.configuredPunchiMenuFullScreenCloseButtonPosition",
        main_source,
    )) != 1:
        print(
            "main.qml: close-button position must be bound only to Fullscreen",
            file=sys.stderr,
        )
        passed = False
    close_button_equal_margin_contract = (
        "x: root.closeButtonOnLeft",
        "? root.closeButtonCornerMargin",
        "parent.width - width - root.closeButtonCornerMargin",
        "y: root.closeButtonCornerMargin",
    )
    for marker in close_button_equal_margin_contract:
        if overlay_source.count(marker) != 1:
            print(
                "PunchiMenu Fullscreen close button: X and Y must use the "
                f"same corner metric: {marker}",
                file=sys.stderr,
            )
            passed = False
    if ("anchors.left: root.closeButtonOnLeft" in overlay_source
            or "anchors.right: root.closeButtonOnLeft" in overlay_source):
        print(
            "PunchiMenu Fullscreen close button: conditional horizontal "
            "anchors can stretch the control during hot updates",
            file=sys.stderr,
        )
        passed = False
    if normal_source.count("fullScreenCloseButtonPosition") != 0:
        print(
            "PunchiMenuNormal.qml: fullscreen close-button setting leaked "
            "into Normal mode",
            file=sys.stderr,
        )
        passed = False
    close_button_start = overlay_source.find("id: closeButton")
    close_button_contract = overlay_source[
        close_button_start:close_button_start + 1800
    ]
    if close_button_start < 0 or (
        "HoverHandler {" not in close_button_contract
        or "enabled: closeButton.enabled" not in close_button_contract
        or "cursorShape: Qt.PointingHandCursor" not in close_button_contract
    ):
        print(
            "PunchiMenu Fullscreen close button: pointing-hand cursor "
            "contract is incomplete",
            file=sys.stderr,
        )
        passed = False
    item_dialog_contract = (
        'i18n("Menu mode:")',
        "Controls.ComboBox {",
        "signal menuModeSelected(string mode)",
        "property string iconName",
        "signal iconPickerRequested()",
        'i18n("Icon:")',
        'i18nc("@action:button", "Choose PunchiMenu icon")',
        "contentItem: RowLayout {",
    )
    for marker in item_dialog_contract:
        if marker not in dialog_source:
            print(
                f"PunchiMenuDialog.qml: missing item editor control: {marker}",
                file=sys.stderr,
            )
            passed = False
    legacy_dialog_forbidden_markers = (
        "Controls.Switch {",
        "Controls.Slider {",
        "Controls.SpinBox {",
        "normalPlacementModeSelected",
        "gridIconScalePercentSelected",
        "favoriteIconScalePercentSelected",
        "normalFolderMaximumColumnsSelected",
        "fullScreenFolderMaximumColumnsSelected",
        "showDistributionNameSelected",
        "showPageNavigationArrowsSelected",
        "fullScreenCloseButtonPositionSelected",
        "normalSizePercentSelected",
        "KQuickControls.KeySequenceItem",
        "signal shortcutSelected",
        "property string shortcut",
        'i18n("Full screen and Normal are available. Compact will be enabled in a future update.")',
        'i18n("The effective size adapts to the screen and available grid cell space.")',
        'i18n("The safe range applies to the reserved Favorites section in both menu modes.")',
        'i18n("Attached keeps the menu next to its dock or panel. Centered uses the available area of the active screen.")',
        'i18n("The percentages adjust the menu size relative to your screen width and height (from 30% to 90%).")',
        'i18n("This shortcut controls PunchiMenu independently from the widget activation shortcut.")',
    )
    for marker in legacy_dialog_forbidden_markers:
        if marker in dialog_source:
            print(
                f"PunchiMenuDialog.qml: advanced duplicate remains in basic editor: {marker}",
                file=sys.stderr,
            )
            passed = False
    legacy_dialog_consumer_forbidden_markers = (
        "onNormalPlacementModeSelected:",
        "onGridIconScalePercentSelected:",
        "onFavoriteIconScalePercentSelected:",
        "onNormalFolderMaximumColumnsSelected:",
        "onNormalFolderMaximumRowsSelected:",
        "onFullScreenFolderMaximumColumnsSelected:",
        "onFullScreenFolderMaximumRowsSelected:",
        "onShowDistributionNameSelected:",
        "onShowPageNavigationArrowsSelected:",
        "onFullScreenCloseButtonPositionSelected:",
        "onNormalSizePercentSelected:",
        "shortcut: page.cfg_punchiMenuShortcut",
        "onShortcutSelected:",
    )
    for marker in legacy_dialog_consumer_forbidden_markers:
        if marker in config_page_source:
            print(
                f"ConfigItems.qml: retired PunchiMenuDialog binding remains: {marker}",
                file=sys.stderr,
            )
            passed = False
    item_dialog_wiring_contract = (
        'page.openIconPicker("punchimenu")',
        "punchiMenuDialog.iconName = ConfigItemsJS.normalizedPunchiMenuIcon(",
        "punchiMenuDialog.iconName = item.icon",
    )
    for marker in item_dialog_wiring_contract:
        source = config_page_source if marker.startswith("page.openIconPicker") else workflow_source
        if marker not in source:
            print(
                f"PunchiMenu item editor: missing icon wiring: {marker}",
                file=sys.stderr,
            )
            passed = False

    if punchi_menu_config_path.exists():
        print(
            "ConfigPunchiMenu.qml: redundant standalone KCM page was not retired",
            file=sys.stderr,
        )
        passed = False
    if 'source: "config/ConfigPunchiMenu.qml"' in config_model_source:
        print(
            "config.qml: redundant PunchiMenu category was not retired",
            file=sys.stderr,
        )
        passed = False

    contextual_mode_contract = (
        (dock_context_actions_source, 'i18nc("@title:menu", "Menu mode")'),
        (dock_context_actions_source, '"kind": "submenu"'),
        (dock_context_actions_source, '"kind": "setPunchiMenuMode"'),
        (dock_context_actions_source, '"checked": isNormalAnchored'),
        (dock_context_actions_source, '"checked": isNormalCentered'),
        (dock_context_actions_source, '"checked": isFullScreen'),
        (dock_context_actions_source, '"normalPlacementMode", String(action.placementMode)'),
        (dock_context_actions_source, 'i18nc("@action:context", "Configure Punchi Dock…")'),
        (dock_context_actions_source, '"kind": "configureDock"'),
        (dock_context_actions_source, 'i18nc("@title:menu", "Folder view")'),
        (dock_context_actions_source, '"kind": "setFolderView"'),
        (dock_context_actions_source, '"expectedFolderText": expectedFolderText'),
        (main_source, "function openDockConfiguration()"),
        (main_source, "configureDockHandler: function()"),
        (dock_items_controller_source, '"menuMode": true'),
        (dock_items_controller_source, "function setFolderLayout(targetIndex, layout, expectedFolderText)"),
        (dock_items_controller_source, "root.canonicalJsonText(currentFolder) !== expectedText"),
        (dock_items_controller_source, "root.persistenceAdapter.commitDockItemsJson("),
        (dock_items_controller_source, "root.dockItems = update.items"),
        (dock_items_controller_source, "root.configurationChanged()"),
        (app_actions_popup_source, "function openSubMenu(action)"),
        (app_actions_popup_source, "function closeSubMenu()"),
        (app_actions_popup_source, "readonly property var displayedActions"),
    )
    for source, marker in contextual_mode_contract:
        if marker not in source:
            print(
                f"PunchiMenu contextual mode selector: missing contract: {marker}",
                file=sys.stderr,
            )
            passed = False
    folder_layout_start = dock_items_controller_source.index(
        "function setFolderLayout(targetIndex, layout, expectedFolderText)"
    )
    folder_layout_end = dock_items_controller_source.index(
        "function punchiMenuApplicationLayout()", folder_layout_start
    )
    folder_layout_transaction = dock_items_controller_source[
        folder_layout_start:folder_layout_end
    ]
    folder_layout_commit = folder_layout_transaction.index(
        "root.persistenceAdapter.commitDockItemsJson("
    )
    folder_layout_publish = folder_layout_transaction.index(
        "root.dockItems = update.items"
    )
    if folder_layout_commit >= folder_layout_publish:
        print(
            "Folder view changes must be durable before publishing QML state.",
            file=sys.stderr,
        )
        passed = False
    if "root.syncDockItemsConfiguration()" in folder_layout_transaction:
        print(
            "Folder view changes must use the compare-and-swap persistence adapter.",
            file=sys.stderr,
        )
        passed = False
    additional_shortcuts_contract = (
        'title: i18n("Additional Shortcuts")',
        "property string cfg_punchiMenuShortcut",
        "KQuickControls.KeySequenceItem",
        'Kirigami.FormData.label: i18n("Open or close PunchiMenu:")',
        "page.cfg_punchiMenuShortcut = keySequence.toString()",
        'Accessible.name: i18n("PunchiMenu keyboard shortcut")',
    )
    for marker in additional_shortcuts_contract:
        if marker not in additional_shortcuts_config_source:
            print(
                "ConfigAdditionalShortcuts.qml: shortcut contract is incomplete: "
                f"{marker}",
                file=sys.stderr,
            )
            passed = False
    if "Plasmoid.globalShortcut" in additional_shortcuts_config_source:
        print(
            "ConfigAdditionalShortcuts.qml: the dedicated editor must not change "
            "Plasma's widget activation shortcut",
            file=sys.stderr,
        )
        passed = False
    if "Plasmoid.configuration.writeConfig()" not in main_source:
        print("main.qml: quick editor hand-off is not persisted", file=sys.stderr)
        passed = False
    pending_editor_contract = (
        "onCfg_pendingEditDockItemIndexChanged: consumePendingEditRequest()",
        "onDiskItemsLoadedChanged:",
        "if (!diskItemsLoaded || pendingEditConsumed",
    )
    for marker in pending_editor_contract:
        if marker not in config_page_source:
            print(
                f"ConfigItems.qml: quick editor hand-off is incomplete: {marker}",
                file=sys.stderr,
            )
            passed = False
    category_arrow_contract = (
        "Layout.preferredWidth: Kirigami.Units.gridUnit * 2.1",
        "Layout.preferredHeight: Kirigami.Units.gridUnit * 2.1",
        "Layout.alignment: Qt.AlignVCenter",
    )
    for marker in category_arrow_contract:
        if normal_source.count(marker) < 2:
            print(
                f"PunchiMenu Normal: category arrows do not match the pills: {marker}",
                file=sys.stderr,
            )
            passed = False
    session_view_contract = (
        (overlay_source, 'property string contentViewActive: "applications"', "explicit content view state"),
        (overlay_source, 'readonly property bool sessionViewActive: contentViewActive === "session"', "derived session state"),
        (overlay_source, "KCoreAddons.KUser {", "local user identity source"),
        (overlay_source, "Punchi.SessionActionsController {", "native session controller"),
        (overlay_source, "PunchiMenuSessionView {", "dedicated session view"),
        (overlay_source, 'source: "view-grid"', "theme-native return-to-grid icon"),
        (overlay_source, 'source: "user-identity"', "generic user icon"),
        (overlay_source, "visible: !root.sessionViewRequested", "user-icon closed state"),
        (overlay_source, "visible: root.sessionViewRequested", "grid active state"),
        (overlay_source, "readonly property int headerControlSize", "shared header control metric"),
        (overlay_source, "background: PunchiMenuActionBackground {", "themed header action surface"),
        (overlay_source,
            "if (root.applicationViewActive\n"
            "                            && !root.categoryGroupingActive)",
            "wheel isolation"),
        (session_view_source, "signal logoutRequested()", "logout intent"),
        (session_view_source, "signal restartRequested()", "restart intent"),
        (session_view_source, "signal shutdownRequested()", "shutdown intent"),
        (session_view_source, "readonly property int avatarSize: Kirigami.Units.gridUnit * 9", "larger avatar metric"),
        (session_view_source, "PunchiMenuUserAvatar {", "dedicated avatar component"),
        (avatar_component_source, "Image.PreserveAspectCrop", "avatar crop policy"),
        (avatar_component_source, "Screen.devicePixelRatio", "device-pixel avatar source"),
        (avatar_component_source, "mipmap: true", "downsampling quality"),
        (avatar_component_source, "ShaderEffectSource {", "shader input source"),
        (avatar_component_source, "supportsAtlasTextures: true", "atlas-safe shader"),
        (avatar_component_source, "PunchiMenuAvatar.frag.qsb", "embedded avatar shader"),
        (avatar_component_source, "Effects.MultiEffect {", "software-rendering fallback"),
        (avatar_component_source, "maskEnabled: true", "fallback circular mask"),
        (avatar_component_source, 'fallbackIcon: "user-identity"', "avatar fallback"),
        (avatar_shader_source, "const highp float innerRadius", "inner avatar radius"),
        (avatar_shader_source, "const highp float outerRadius", "outer border radius"),
        (avatar_shader_source, "mix(colorSource, colorBorder", "image-to-border blend"),
        (avatar_shader_source, "mix(colorBorder, colorEmpty", "border-to-alpha blend"),
        (native_build_source, "--qsbversion 65", "shader format compatible with Qt 6.6"),
        (native_build_source, "qt_add_resources(punchidockintegration", "embedded shader resource"),
        (fedora_setup_source, "qt6-qtshadertools", "Fedora shader build dependency"),
        (debian_setup_source, "qt6-shader-baker", "Debian shader build dependency"),
        (session_view_source, "PlasmaComponents.Button {", "Plasma-themed session controls"),
        (session_controller_source, "ConfirmationMode::ForcePrompt", "forced KDE confirmation"),
    )
    for source, marker, description in session_view_contract:
        if marker not in source:
            print(
                f"PunchiMenu Fullscreen session view: missing {description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    normal_session_view_contract = (
        ('property string contentViewActive: "applications"',
            "exclusive content view state"),
        ('readonly property bool applicationViewActive:',
            "derived application state"),
        ('readonly property bool sessionViewActive:',
            "derived session state"),
        ('return requestedView === "settings" || requestedView === "session"',
            "content view normalization"),
        ('id: sessionButton', "single session header toggle"),
        ('source: "user-identity"', "generic user icon"),
        ('source: "view-grid"', "return-to-applications icon"),
        ('KCoreAddons.KUser {', "local user identity source"),
        ('Punchi.SessionActionsController {', "native session controller"),
        ('id: sessionViewLoader', "lazy session view loader"),
        ('active: root.sessionViewActive', "lazy session activation"),
        ('PunchiMenuSessionView {', "shared session action view"),
    )
    for marker, description in normal_session_view_contract:
        if marker not in normal_source:
            print(
                "PunchiMenu Normal session view: missing "
                f"{description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    for retired_header_control in (
        "id: btnLogOut",
        "id: btnReboot",
        "id: btnShutdown",
    ):
        if retired_header_control in normal_source:
            print(
                "PunchiMenu Normal session view: direct header action "
                f"returned: {retired_header_control}",
                file=sys.stderr,
            )
            passed = False
    if session_view_source.count("cursorShape: Qt.PointingHandCursor") < 3:
        print(
            "PunchiMenu Fullscreen session view: every action needs a pointing cursor",
            file=sys.stderr,
        )
        passed = False
    if session_view_source.count(
        "readonly property bool highlightedContent: enabled"
    ) < 3:
        print(
            "PunchiMenu Fullscreen session view: every action needs a themed highlight state",
            file=sys.stderr,
        )
        passed = False
    if session_view_source.count(
        "readonly property color foregroundColor: highlightedContent"
    ) < 3:
        print(
            "PunchiMenu Fullscreen session view: every action needs a shared themed foreground color",
            file=sys.stderr,
        )
        passed = False
    if session_view_source.count("Kirigami.Theme.textColor: foregroundColor") < 3:
        print(
            "PunchiMenu Fullscreen session view: action labels must inherit the shared themed foreground color",
            file=sys.stderr,
        )
        passed = False
    if session_view_source.count("icon.color: foregroundColor") < 3:
        print(
            "PunchiMenu Fullscreen session view: action icons must inherit the shared themed foreground color",
            file=sys.stderr,
        )
        passed = False
    if session_view_source.count("background: PunchiMenuActionBackground {") < 3:
        print(
            "PunchiMenu Fullscreen session view: every action needs the shared themed background",
            file=sys.stderr,
        )
        passed = False
    action_background_contract = (
        "property bool highlighted: false",
        "property bool showBaseSurface: false",
        "Kirigami.Theme.highlightColor",
        "Kirigami.Theme.textColor",
        "Behavior on color",
    )
    for marker in action_background_contract:
        if marker not in action_background_source:
            print(
                f"PunchiMenu themed action background: missing contract: {marker}",
                file=sys.stderr,
            )
            passed = False
    item_highlight_contract = (
        "Qt.alpha(Kirigami.Theme.highlightColor, 0.20)",
        "border.width: focused || selected ? 2 : 0",
        "Kirigami.Units.cornerRadius * 2",
        "? 0.97 : visualScale",
        "Behavior on color",
        "id: pulseAnimation",
        "id: bounceAnimation",
    )
    for marker in item_highlight_contract:
        if marker not in item_highlight_source:
            print(
                f"PunchiMenu shared item highlight: missing contract: {marker}",
                file=sys.stderr,
            )
            passed = False
    for source, label, minimum_count in (
        (normal_source, "Normal", 2),
        (overlay_source, "Fullscreen", 2),
        (folder_tile_source, "folder tile", 1),
        (folder_view_source, "folder contents", 1),
    ):
        if source.count("PunchiMenuItemHighlight {") < minimum_count:
            print(
                f"PunchiMenu {label}: shared item highlight is not reused",
                file=sys.stderr,
            )
            passed = False
    if overlay_source.count("selected: appDelegate.highlighted") != 2:
        print(
            "PunchiMenu Fullscreen: wheel hover must restore both folder and application borders immediately",
            file=sys.stderr,
        )
        passed = False
    for source, mode in ((normal_source, "Normal"), (overlay_source, "Fullscreen")):
        drag_reorder_contract = (
            'property string dropIntent: "none"',
            "function updateDropIntent(drag)",
            'dropIntent === "insertBefore"',
            'dropIntent = "insertAfter"',
            'dropIntent = "group"',
            "function beforeNodeIdForInsertion(targetIndex, insertAfter)",
        )
        for marker in drag_reorder_contract:
            if marker not in source:
                print(
                    f"PunchiMenu {mode} DnD: missing shared reorder/group contract: {marker}",
                    file=sys.stderr,
                )
                passed = False
    fullscreen_edge_indicator_contract = (
        "readonly property int gridColumn:",
        "readonly property bool atLeadingPageEdge:",
        "readonly property bool atTrailingPageEdge:",
        "x: atLeadingPageEdge ? 0",
        "? parent.width - width",
        ": centeredX",
    )
    for marker in fullscreen_edge_indicator_contract:
        if marker not in overlay_source:
            print(
                "PunchiMenu Fullscreen DnD: insertion indicator must stay fully "
                f"inside clipped page edges: missing {marker}",
                file=sys.stderr,
            )
            passed = False
    normal_leading_edge_indicator_contract = (
        "readonly property int gridColumn:",
        "applicationDelegate.index",
        "% Math.max(1, root.columnCount)",
        "readonly property bool atLeadingGridEdge:",
        "!after && gridColumn === 0",
        "x: atLeadingGridEdge ? 0",
        ": after ? parent.width - width / 2",
        ": -width / 2",
    )
    for marker in normal_leading_edge_indicator_contract:
        if marker not in normal_source:
            print(
                "PunchiMenu Normal DnD: insertBefore indicator must stay fully "
                f"inside the clipped leading edge: missing {marker}",
                file=sys.stderr,
            )
            passed = False
    unstable_scroll_reserve = (
        "readonly property real verticalScrollBarReserve:\n"
        "                        verticalScrollRequired"
    )
    if unstable_scroll_reserve in normal_source:
        print(
            "PunchiMenu Normal: scrollbar reserve still depends on the layout it changes",
            file=sys.stderr,
        )
        passed = False
    if (
        "readonly property real verticalScrollBarReserve:\n"
        "                        Math.max(1, applicationsScrollBar.implicitWidth)"
    ) not in normal_source:
        print(
            "PunchiMenu Normal: stable scrollbar channel is missing",
            file=sys.stderr,
        )
        passed = False
    if "boundsBehavior: Flickable.StopAtBounds" not in normal_source:
        print(
            "PunchiMenu Normal: the application grid must stop at its bounds",
            file=sys.stderr,
        )
        passed = False
    stable_scrollbar_contract = (
        "readonly property int stableRowCount: Math.ceil(",
        "readonly property real stableContentHeight:",
        "stableRowCount * cellHeight",
        "stableContentHeight > height + 0.5",
        "id: applicationsScrollBar",
        "size: stableSize",
        "position: stablePosition",
        "position\n                                    * applicationsGrid.stableContentHeight",
    )
    for marker in stable_scrollbar_contract:
        if marker not in normal_source:
            print(
                "PunchiMenu Normal: stable row-based scrollbar contract is missing: "
                f"{marker}",
                file=sys.stderr,
            )
            passed = False
    if "PlasmaComponents.ScrollBar.vertical:" in normal_source:
        print(
            "PunchiMenu Normal: the unstable GridView-attached scrollbar returned",
            file=sys.stderr,
        )
        passed = False
    fullscreen_lazy_surface_contract = (
        "id: sessionViewLoader",
        "active: root.sessionViewRequested || root.sessionViewActive",
        "id: folderSurfaceLoader",
        "folderSurfaceLoader.active = true",
        "active: false\n        asynchronous: false",
    )
    for marker in fullscreen_lazy_surface_contract:
        if marker not in overlay_source:
            print(
                "PunchiMenu Fullscreen: inactive secondary surfaces must remain "
                f"lazy: missing {marker}",
                file=sys.stderr,
            )
            passed = False
    if avatar_component_source.count("antialiasing: true") < 3:
        print(
            "PunchiMenu Fullscreen avatar: background, mask and fallback border need antialiasing",
            file=sys.stderr,
        )
        passed = False
    if "Kirigami.Theme.inherit: false" in session_view_source:
        print(
            "PunchiMenu Fullscreen session view: the inherited theme must not be isolated",
            file=sys.stderr,
        )
        passed = False
    session_transition_contract = (
        'property string contentViewRequested: "applications"',
        "property real modeContentOpacity: 1.0",
        "readonly property bool modeTransitionActive",
        "function commitContentViewState(viewName)",
        "function setContentView(viewName)",
        "id: modeFadeOutAnimation",
        "easing.type: Easing.InCubic",
        "id: modeFadeInAnimation",
        "easing.type: Easing.OutCubic",
        "root.commitContentViewState(root.contentViewRequested)",
        "enabled: !root.modeTransitionActive",
    )
    for marker in session_transition_contract:
        if marker not in overlay_source:
            print(
                f"PunchiMenu Fullscreen session transition: missing {marker}",
                file=sys.stderr,
            )
            passed = False
    internal_settings_contract = (
        (
            overlay_source,
            'readonly property bool settingsViewActive: contentViewActive === "settings"',
            "derived settings state",
        ),
        (
            overlay_source,
            "function setSettingsViewActive(active)",
            "settings transition entry point",
        ),
        (
            overlay_source,
            "PunchiMenuFullScreenSettingsView {",
            "dedicated settings view",
        ),
        (
            overlay_source,
            "root.settingChangeRequested(fieldName, value)",
            "view-to-controller intent",
        ),
        (
            overlay_source,
            "onAdvancedConfigurationRequested:",
            "advanced KCM fallback",
        ),
        (
            main_source,
            "onSettingChangeRequested: function(fieldName, value)",
            "runtime persistence routing",
        ),
        (
            dock_items_controller_source,
            'import "../config/code/configItems.js" as ConfigItemsJS',
            "shared normalizer import",
        ),
        (
            dock_items_controller_source,
            "function setPunchiMenuValue(fieldName, value)",
            "whitelisted persistence entry point",
        ),
        (
            dock_items_controller_source,
            "ConfigItemsJS.prunePunchiMenu(nextItem)",
            "canonical settings normalization",
        ),
        (
            fullscreen_settings_view_source,
            "Controls.ScrollView {",
            "scrollable settings content",
        ),
        (
            fullscreen_settings_view_source,
            'i18nc("@title", "PunchiMenu Settings")',
            "translated title",
        ),
        (
            fullscreen_settings_view_source,
            "function focusInitialAction()",
            "predictable keyboard focus",
        ),
        (
            fullscreen_settings_view_source,
            '"Open mode and icon settings…")',
            "remaining settings action",
        ),
    )
    for source, marker, description in internal_settings_contract:
        if marker not in source:
            print(
                "PunchiMenu Fullscreen internal settings: missing "
                f"{description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    allowed_internal_settings = (
        "normalBlurEnabled",
        "normalBackgroundOpacityPercent",
        "fullScreenBlurEnabled",
        "fullScreenBackgroundOpacityPercent",
        "showDistributionName",
        "showPageNavigationArrows",
        "showApplicationLabels",
        "sortApplicationsAlphabetically",
        "fullScreenApplicationOrder",
        "fullScreenCloseButtonPosition",
        "gridIconScalePercent",
        "favoriteIconScalePercent",
        "normalPlacementMode",
        "normalPanelDistancePercent",
        "normalWidthPercent",
        "normalHeightPercent",
        "normalShowCategories",
        "normalCategoryGrouping",
        "normalFolderMaximumColumns",
        "normalFolderMaximumRows",
        "fullScreenFolderMaximumColumns",
        "fullScreenFolderMaximumRows",
    )
    for field_name in allowed_internal_settings:
        if dock_items_controller_source.count(f'"{field_name}": true') != 1:
            print(
                "PunchiMenu Fullscreen internal settings: persistence "
                f"whitelist is incomplete for {field_name}",
                file=sys.stderr,
            )
            passed = False
    normal_internal_settings_contract = (
        'readonly property bool settingsViewActive:',
        "function setSettingsViewActive(active)",
        "id: configureButton",
        'icon.name: root.settingsViewActive ? "view-grid" : "configure"',
        "id: settingsViewLoader",
        "PunchiMenuNormalSettingsView {",
        "root.settingChangeRequested(fieldName, value)",
        "onAdvancedConfigurationRequested:",
    )
    for marker in normal_internal_settings_contract:
        if marker not in normal_source:
            print(
                "PunchiMenu Normal internal settings: missing "
                f"embedded-view contract marker: {marker}",
                file=sys.stderr,
            )
            passed = False
    normal_settings_contract = (
        '"normalBlurEnabled", checked',
        '"normalBackgroundOpacityPercent",',
        '"normalCategoryGrouping", checked',
        '"normalShowCategories", checked',
        '"normalFolderMaximumColumns", value',
        '"normalFolderMaximumRows", value',
        "visible: root.anchoredMode",
        '"normalPlacementMode", modelData.value',
        '"normalPanelDistancePercent", Math.round(value)',
        '"normalWidthPercent",',
        '"normalHeightPercent",',
        "Controls.RadioButton {",
    )
    for marker in normal_settings_contract:
        if marker not in normal_settings_view_source:
            print(
                "PunchiMenu Normal settings: missing isolated routing: "
                f"{marker}",
                file=sys.stderr,
            )
            passed = False
    fullscreen_settings_contract = (
        '"fullScreenBlurEnabled", checked',
        '"fullScreenBackgroundOpacityPercent",',
        '"fullScreenFolderMaximumColumns", value',
        '"fullScreenFolderMaximumRows", value',
        '"fullScreenCloseButtonPosition",',
        "PunchiMenuFullScreenComboBox {",
    )
    for marker in fullscreen_settings_contract:
        if marker not in fullscreen_settings_view_source:
            print(
                "PunchiMenu Fullscreen settings: missing isolated routing: "
                f"{marker}",
                file=sys.stderr,
            )
            passed = False
    selector_separation_contract = (
        (fullscreen_combo_source,
            "root.mapToItem(popupParentItem, 0, root.height)",
            "Fullscreen popup origin mapping"),
        (fullscreen_combo_source,
            "const visibleNow = root.popup.visible",
            "Fullscreen popup refresh"),
        (normal_settings_view_source, "Controls.ButtonGroup {",
            "Normal exclusive radio groups"),
        (normal_settings_view_source,
            "Controls.ButtonGroup.group:",
            "Normal radio group membership"),
        (normal_settings_view_source,
            "checked: index === root.placementIndex()",
            "Normal placement selection state"),
        (normal_settings_view_source,
            "hoverAnimationRepeater.itemAt(0)",
            "Normal hover label first-option alignment"),
        (normal_settings_view_source,
            "normalPlacementRepeater.itemAt(0)",
            "Normal placement label first-option alignment"),
    )
    for source, marker, description in selector_separation_contract:
        if marker not in source:
            print(
                f"PunchiMenu selector separation: missing {description}: "
                f"{marker}",
                file=sys.stderr,
            )
            passed = False
    if normal_settings_view_source.count("Controls.ButtonGroup {") != 2:
        print(
            "PunchiMenu Normal settings: both option sets must use an "
            "exclusive button group",
            file=sys.stderr,
        )
        passed = False
    if normal_settings_view_source.count("exclusive: true") != 2:
        print(
            "PunchiMenu Normal settings: each radio group must allow exactly "
            "one selected option",
            file=sys.stderr,
        )
        passed = False
    if normal_settings_view_source.count("Controls.RadioButton {") != 2:
        print(
            "PunchiMenu Normal settings: both option sets must use radio "
            "button delegates",
            file=sys.stderr,
        )
        passed = False
    if normal_settings_view_source.count(
        "Layout.alignment: Qt.AlignLeft") != 2:
        print(
            "PunchiMenu Normal settings: radio options must keep compact "
            "left alignment",
            file=sys.stderr,
        )
        passed = False
    if fullscreen_settings_view_source.count(
        "PunchiMenuFullScreenComboBox {") != 3:
        print(
            "PunchiMenu Fullscreen settings: all three selectors must preserve "
            "the Fullscreen ComboBox",
            file=sys.stderr,
        )
        passed = False
    for forbidden_normal_selector in (
        "PlasmaComponents.ComboBox {",
        "PunchiMenuFullScreenComboBox",
        "PlasmaExtras.Menu",
        "popup.",
    ):
        if forbidden_normal_selector in normal_settings_view_source:
            print(
                "PunchiMenu Normal selector: option groups must not create a "
                f"popup: {forbidden_normal_selector}",
                file=sys.stderr,
            )
            passed = False
    if any(marker in normal_settings_view_source for marker in (
        "showDistributionName",
        "showPageNavigationArrows",
        "fullScreenCloseButtonPosition",
        "PunchiMenuFullScreenComboBox",
    )):
        print(
            "PunchiMenu Normal settings: contains Fullscreen-only controls",
            file=sys.stderr,
        )
        passed = False
    if any(marker in fullscreen_settings_view_source for marker in (
        "normalPlacementMode",
        "normalPanelDistancePercent",
        "normalWidthPercent",
        "normalHeightPercent",
    )):
        print(
            "PunchiMenu Fullscreen settings: contains Normal-only controls",
            file=sys.stderr,
        )
        passed = False
    for retired_component in (
        "PunchiMenuSettingsView.qml",
        "PunchiMenuComboBox.qml",
        "PunchiMenuNormalInlineSelector.qml",
    ):
        if (
            PROJECT_ROOT
            / "contents/ui/components/punchimenu"
            / retired_component
        ).exists():
            print(
                "PunchiMenu settings separation: retired shared component "
                f"still exists: {retired_component}",
                file=sys.stderr,
            )
            passed = False
    if "onClicked: root.configureRequested()" in overlay_source:
        print(
            "PunchiMenu Fullscreen internal settings: the header gear still "
            "bypasses the internal view",
            file=sys.stderr,
        )
        passed = False
    paged_grid_contract = (
        "property bool applicationCatalogLoaded: false",
        "applicationsLoading = !applicationCatalogLoaded",
        "root.systemDiscovery.requestApplicationCatalog()",
        "snapMode: ListView.SnapOneItem",
        "preferredHighlightEnd: 0",
        "maximumFlickVelocity: 4 * width",
        "cacheBuffer: Math.max(0, width)",
        "onMovementStarted: root.resetPageNavigation()",
        "preventStealing: internalDragLayer.active",
        "readonly property int pageCapacity",
        "readonly property int pageCount",
        "readonly property int pageIndicatorDotDiameter",
        "readonly property int pageIndicatorTargetDiameter",
        "readonly property int compactSearchWidth",
        "readonly property int applicationGridHorizontalInset",
        "id: searchContainer",
        "PlasmaComponents.TextField {",
        '? "view-grid" : "configure"',
        "PlasmaCore.ToolTipArea {",
        "mainText: configureButton.text",
        "mainText: previousPageButton.text",
        "mainText: nextPageButton.text",
        "spacing: Math.max(1, Math.round(root.pageIndicatorDotDiameter * 0.5))",
        "signal configureRequested()",
        'i18nc("@action:button", "Page %1 of %2"',
        'i18nc("@placeholder", "Search applications…")',
        "anchors.leftMargin: root.applicationGridHorizontalInset",
        "anchors.rightMargin: root.applicationGridHorizontalInset",
        'icon.name: "go-previous-symbolic"',
        'icon.name: "go-next-symbolic"',
        'i18nc("@action:button", "Previous page")',
        'i18nc("@action:button", "Next page")',
        "onClicked: root.requestPageStep(-1)",
        "onClicked: root.requestPageStep(1)",
        "property real wheelPageAccumulator: 0",
        "property bool wheelGestureCommitted: false",
        "function handlePageWheel(wheel)",
        "wheelGestureResetTimer.restart()",
        "const threshold = usesPixelDelta ? wheelPixelThreshold : 120",
        "root.handlePageWheel(wheel)",
        "readonly property bool pageTransitionActive",
        "readonly property bool applicationHoverAllowed",
        "delegatePointer.containsMouse\n                                        && root.applicationHoverAllowed",
        "if (root.applicationHoverAllowed)",
        "Kirigami.WheelHandler {",
        "id: wheelInputHandler",
        "target: pagesView",
        "scrollFlickableTarget: false",
        "blockTargetWheel: true",
    )
    for marker in paged_grid_contract:
        if marker not in overlay_source:
            print(
                f"PunchiMenuOverlay.qml: missing paged-grid contract: {marker}",
                file=sys.stderr,
            )
            passed = False
    if 'systemDiscovery.requestApplications("All")' in overlay_source:
        print(
            "PunchiMenu Fullscreen first open: the central catalog must not be queried twice",
            file=sys.stderr,
        )
        passed = False
    if main_source.count("systemDiscovery.requestApplicationCatalog()") != 1:
        print(
            "PunchiMenu first open: main must preload the catalog once, not on every toggle",
            file=sys.stderr,
        )
        passed = False
    sycoca_refresh_contract = (
        "#include <KSycoca>",
        "KSycoca::self(), &KSycoca::databaseChanged",
        "requestApplicationCatalog();",
    )
    for marker in sycoca_refresh_contract:
        if marker not in discovery_implementation_source:
            print(
                f"PunchiMenu catalog refresh: missing KDE service database contract: {marker}",
                file=sys.stderr,
            )
            passed = False

    fullscreen_internal_drag_contract = (
        (overlay_source, "onPressAndHold: function(mouse)", "system long-press entry"),
        (overlay_source, "preventStealing: internalDragLayer.active", "post-threshold page arbitration"),
        (overlay_source, "interactive: root.pageCount > 1 && !internalDragLayer.active", "page gesture suspension"),
        (overlay_source, "if (internalDragLayer.active) {\n            wheel.accepted = true", "wheel suspension"),
        (overlay_source, "folderSurface.beginCreateFromStorageIds([", "application-to-application creation"),
        (overlay_source, ".requestAddApplicationToFolder(", "application-to-folder move"),
        (overlay_source, "requestMoveNode(", "transactional node reorder"),
        (overlay_source, "event.source === internalDragLayer.dragSource", "source identity validation"),
        (overlay_source, "root.cancelInternalLayoutDrag()", "explicit cancellation"),
        (overlay_source, "function onActiveChanged()", "window-focus cancellation"),
        (drag_layer_source, "Drag.keys: [root.dragKey]", "private drag key"),
        (drag_layer_source, "Drag.source: dragProxy", "internal source identity"),
        (drag_layer_source, "Drag.supportedActions: Qt.MoveAction", "internal move action"),
        (drag_layer_source, "dragProxy.Drag.cancel()", "non-persistent cancel"),
    )
    for source, marker, description in fullscreen_internal_drag_contract:
        if marker not in source:
            print(
                f"PunchiMenu Fullscreen DnD: missing {description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    if "Drag.mimeData" in drag_layer_source or "text/plain" in drag_layer_source:
        print(
            "PunchiMenu Fullscreen DnD: internal layout drag exposes external MIME data",
            file=sys.stderr,
        )
        passed = False
    if re.search(
        r"enabled:\s*!root\.sessionViewActive\s*"
        r"&&\s*!root\.modeTransitionActive\s*"
        r"&&\s*!root\.applicationLaunchPending\s*"
        r"&&\s*!internalDragLayer\.active",
        overlay_source,
    ):
        print(
            "PunchiMenu Fullscreen DnD: disabling pagesView also disables its drop targets",
            file=sys.stderr,
        )
        passed = False
    normal_internal_drag_contract = (
        (normal_source, "PunchiMenuDragLayer {", "shared internal transport"),
        (normal_source, "onPressAndHold: function(mouse)", "system long-press entry"),
        (normal_source, "preventStealing: internalDragLayer.active", "post-threshold scroll arbitration"),
        (normal_source, "interactive: !internalDragLayer.active", "direct vertical gesture suspension"),
        (normal_source, "target: internalDragLayer.active\n                            ? applicationsGrid : null", "wheel suspension without disabling targets"),
        (normal_source, "function updateDragAutoScroll(position)", "viewport edge detection"),
        (normal_source, "function performDragAutoScroll()", "bounded vertical autoscroll"),
        (normal_source, "id: dragScrollTimer", "single bounded scroll timer"),
        (normal_source, "folderSurface.beginCreateFromStorageIds([", "application-to-application creation"),
        (normal_source, ".requestAddApplicationToFolder(", "application-to-folder move"),
        (normal_source, "requestMoveNode(", "transactional node reorder"),
        (normal_source, "event.source === internalDragLayer.dragSource", "source identity validation"),
        (normal_source, "root.cancelInternalLayoutDrag()", "explicit cancellation"),
        (normal_source, "function onActiveChanged()", "window-focus cancellation"),
    )
    for source, marker, description in normal_internal_drag_contract:
        if marker not in source:
            print(
                f"PunchiMenu Normal DnD: missing {description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    alphabetical_sorting_contract = (
        (config_items_source, 'item.sortApplicationsAlphabetically === true',
            "canonical boolean normalization"),
        (main_source,
            "configuredPunchiMenuSortApplicationsAlphabetically",
            "reactive runtime projection"),
        (settings_view_source,
            'i18n("Sort applications alphabetically")',
            "internal settings switch"),
        (settings_view_source,
            "visible: root.sortApplicationsAlphabetically",
            "conditional internal information message"),
        (settings_view_source,
            'i18n("Alphabetical sorting is active. Application positions cannot be changed manually, but drag and drop remains available.")',
            "internal sorting consequence"),
        (normal_source,
            "alphabeticalSortingEnabled: root.sortApplicationsAlphabetically",
            "Normal model projection"),
        (overlay_source,
            'root.safeApplicationOrderMode === "alphabetical"',
            "Fullscreen model projection"),
        (normal_source,
            "if (root.sortApplicationsAlphabetically\n"
            "                || !applicationLayoutController",
            "Normal positional-move guard"),
        (overlay_source,
            'if (root.safeApplicationOrderMode !== "manual"',
            "Fullscreen positional-move guard"),
        (normal_source,
            'dropIntent = internalDragLayer.folder\n'
            '                                        ? "none" : "group"',
            "Normal grouping-only drop intent"),
        (overlay_source,
            'dropIntent = internalDragLayer.folder\n'
            '                                                ? "none" : "group"',
            "Fullscreen grouping-only drop intent"),
    )
    for source, marker, description in alphabetical_sorting_contract:
        if marker not in source:
            print(
                "PunchiMenu alphabetical sorting: missing "
                f"{description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    category_grouping_contract = (
        (config_items_source,
            "normalizedPunchiMenuFullScreenApplicationOrder",
            "canonical Fullscreen order normalization"),
        (main_source,
            "configuredPunchiMenuFullScreenApplicationOrder",
            "independent Fullscreen runtime projection"),
        (main_source,
            "categories: application.categories || []",
            "KDE category metadata preservation"),
        (fullscreen_settings_view_source,
            '"By categories"',
            "category ordering option"),
        (fullscreen_settings_view_source,
            "model: root.applicationOrderOptions",
            "Fullscreen popup selector model"),
        (fullscreen_settings_view_source,
            '"fullScreenApplicationOrder",',
            "category order persistence"),
        (overlay_source,
            "PunchiMenuCategorySectionsView {",
            "dedicated category sections view"),
        (overlay_source,
            "categoryGroups: applicationLayoutModel.categoryGroups",
            "model-backed category projection"),
        (category_sections_source,
            "Kirigami.Separator {",
            "simple themed section separator"),
        (category_sections_source,
            "model: sectionDelegate.members",
            "direct application members per section"),
        (category_sections_source,
            "root.launchRequested(storageId)",
            "direct application launch from a category"),
    )
    for source, marker, description in category_grouping_contract:
        if marker not in source:
            print(
                "PunchiMenu category grouping: missing "
                f"{description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    if "Controls.RadioButton {" in fullscreen_settings_view_source:
        print(
            "PunchiMenu category grouping: Fullscreen must use its mapped "
            "popup selector instead of Normal-mode radio buttons",
            file=sys.stderr,
        )
        passed = False
    forbidden_virtual_category_markers = (
        (overlay_source, 'nodeType: "category"'),
        (overlay_source, "openVirtualFolder"),
        (folder_surface_source, 'viewMode === "category"'),
        (folder_tile_source, "categoryTile"),
        (folder_view_source, "categoryView"),
    )
    for source, marker in forbidden_virtual_category_markers:
        if marker in source:
            print(
                "PunchiMenu category grouping: categories must remain direct "
                f"sections, found obsolete virtual-folder marker: {marker}",
                file=sys.stderr,
            )
            passed = False
    application_labels_contract = (
        (config_items_source,
            "item.showApplicationLabels !== false",
            "default-on canonical normalization"),
        (main_source,
            "configuredPunchiMenuShowApplicationLabels",
            "reactive runtime projection"),
        (settings_view_source,
            'i18n("Show application names")',
            "internal settings switch"),
        (normal_source,
            "visible: root.showApplicationLabels",
            "Normal application and favorite labels"),
        (overlay_source,
            "visible: root.showApplicationLabels",
            "Fullscreen application and favorite labels"),
        (folder_view_source,
            "visible: root.showApplicationLabels",
            "folder member labels"),
        (normal_source,
            "active: !root.showApplicationLabels",
            "Normal fallback tooltips"),
        (overlay_source,
            "active: !root.showApplicationLabels",
            "Fullscreen fallback tooltips"),
        (folder_view_source,
            "active: !root.showApplicationLabels",
            "folder fallback tooltips"),
        (drag_layer_source,
            "visible: root.folder || root.showApplicationLabels",
            "application-only drag labels"),
        (folder_tile_source,
            "text: root.effectiveLabel",
            "persistent folder labels"),
    )
    for source, marker, description in application_labels_contract:
        if marker not in source:
            print(
                "PunchiMenu application labels: missing "
                f"{description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    hover_animation_contract = (
        (config_items_source,
            '["none", "individual", "pulse", "bounce"]',
            "canonical animation values"),
        (config_items_source,
            'String(value || "pulse")',
            "Pulse default"),
        (main_source,
            "configuredPunchiMenuHoverAnimation",
            "reactive runtime projection"),
        (settings_view_source,
            'i18n("PunchiMenu hover animation")',
            "internal animation selector"),
        (dock_items_controller_source,
            '"hoverAnimation": true',
            "internal persistence permission"),
        (normal_source,
            "animationMode: root.hoverAnimation",
            "Normal delegates"),
        (overlay_source,
            "animationMode: root.hoverAnimation",
            "Fullscreen delegates"),
        (folder_view_source,
            "? 0.97 : itemHighlight.visualScale",
            "folder member full-item transform"),
        (folder_tile_source,
            "? 0.97 : itemHighlight.visualScale",
            "folder full-item transform"),
    )
    for source, marker, description in hover_animation_contract:
        if marker not in source:
            print(
                "PunchiMenu hover animation: missing "
                f"{description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    highlight_source = (
        PROJECT_ROOT
        / "contents/ui/components/punchimenu/PunchiMenuItemHighlight.qml"
    ).read_text(encoding="utf-8")
    for marker, description in (
        ("id: pulseAnimation", "one-shot Pulse profile"),
        ("id: bounceAnimation", "one-shot Bounce profile"),
        ("id: individualAnimation", "sustained Individual profile"),
        ('animationMode === "none"', "None profile"),
        ("property: \"motionScale\"", "shared full-item scale"),
    ):
        if marker not in highlight_source:
            print(
                "PunchiMenu hover animation primitive: missing "
                f"{description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    desktop_effects_settings_contract = (
        (settings_view_source,
            'import org.kde.kcmutils as KCM',
            "internal KCM launcher import"),
        (settings_view_source,
            'KConfig.KAuthorized.authorizeControlModule(\n'
            '                            "kcm_kwin_effects")',
            "internal authorization check"),
        (settings_view_source,
            'KCM.KCMLauncher.openSystemSettings(\n'
            '                            "kcm_kwin_effects")',
            "internal desktop-effects launcher"),
        (settings_view_source,
            "text: root.backgroundBlurEnabled\n"
            "                            ? i18n(\"The background will use KWin blur when available.",
            "internal reactive blur explanation"),
        (settings_view_source,
            'i18n("Without blur, the background depends on the Plasma theme and the selected opacity.")',
            "internal disabled-blur explanation"),
    )
    for source, marker, description in desktop_effects_settings_contract:
        if marker not in source:
            print(
                "PunchiMenu desktop effects settings: missing "
                f"{description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    blur_explanation_order_contract = (
        (
            settings_view_source,
            "id: backgroundBlurSwitch",
            "text: root.backgroundBlurEnabled",
            "id: backgroundOpacitySlider",
            "internal settings",
        ),
    )
    for source, switch_marker, message_marker, opacity_marker, description in (
        blur_explanation_order_contract
    ):
        switch_index = source.find(switch_marker)
        message_index = source.find(message_marker)
        opacity_index = source.find(opacity_marker)
        if not switch_index < message_index < opacity_index:
            print(
                "PunchiMenu blur explanation order: the message must appear "
                f"below the switch and before opacity in {description}",
                file=sys.stderr,
            )
            passed = False
    if re.search(
        r"enabled:\s*!root\.applicationLaunchPending\s*"
        r"&&\s*!internalDragLayer\.active",
        normal_source,
    ):
        print(
            "PunchiMenu Normal DnD: disabling applicationsGrid also disables its drop targets",
            file=sys.stderr,
        )
        passed = False
    if overlay_source.count("Layout.preferredWidth: root.headerControlSize") < 3:
        print(
            "PunchiMenu Fullscreen: header actions must share the search field height",
            file=sys.stderr,
        )
        passed = False
    if overlay_source.count("PunchiMenuSearchBackground {") != 1:
        print(
            "PunchiMenu Fullscreen: only the search field may use the search surface",
            file=sys.stderr,
        )
        passed = False
    if overlay_source.count("background: PunchiMenuActionBackground {") != 4:
        print(
            "PunchiMenu Fullscreen: all four header controls need the action surface",
            file=sys.stderr,
        )
        passed = False
    if overlay_source.count("icon.color: highlightedContent") < 3:
        print(
            "PunchiMenu Fullscreen: standard header icons must use the highlighted text color",
            file=sys.stderr,
        )
        passed = False
    if "readonly property color foregroundColor: highlightedContent" not in overlay_source:
        print(
            "PunchiMenu Fullscreen: the avatar/grid toggle must follow the "
            "highlighted text color",
            file=sys.stderr,
        )
        passed = False
    if '"system-log-out"' in overlay_source:
        print(
            "PunchiMenu Fullscreen: the ambiguous logout glyph remains on "
            "the session-view toggle",
            file=sys.stderr,
        )
        passed = False
    if "source: currentUser.faceIconUrl" in overlay_source:
        print(
            "PunchiMenu Fullscreen: the header toggle still consumes the "
            "personal avatar image",
            file=sys.stderr,
        )
        passed = False
    if normal_source.count("icon.color: highlightedContent") < 3:
        print(
            "PunchiMenu Normal: standard header icons must use the theme "
            "highlighted text color",
            file=sys.stderr,
        )
        passed = False
    normal_header_cursor_contract = (
        "enabled: configureButton.enabled\n                        cursorShape: Qt.PointingHandCursor",
        "enabled: sessionButton.enabled\n                        cursorShape: Qt.PointingHandCursor",
        "enabled: btnClose.enabled\n                        cursorShape: Qt.PointingHandCursor",
    )
    for marker in normal_header_cursor_contract:
        if marker not in normal_source:
            print(
                "PunchiMenu Normal: every persistent header action needs a "
                f"pointing cursor: {marker}",
                file=sys.stderr,
            )
            passed = False
    header_cursor_contract = (
        "enabled: hiddenApplicationsButton.enabled\n                    cursorShape: Qt.PointingHandCursor",
        "enabled: configureButton.enabled\n                    cursorShape: Qt.PointingHandCursor",
        "enabled: sessionButton.enabled\n                    cursorShape: Qt.PointingHandCursor",
    )
    for marker in header_cursor_contract:
        if marker not in overlay_source:
            print(
                "PunchiMenu Fullscreen: every header action needs a pointing cursor",
                file=sys.stderr,
            )
            passed = False
    if "Controls.Menu {" in overlay_source:
        print(
            "PunchiMenu Fullscreen: context menu must use PlasmaComponents.Menu",
            file=sys.stderr,
        )
        passed = False
    fullscreen_context_menu_icon_contract = (
        '? "favorite-favorited"',
        ': "favorite"',
        '? "window-unpin"',
        ': "window-pin"',
        'icon.name: "user-desktop"',
        '? "view-visible"',
        ': "view-hidden"',
    )
    for marker in fullscreen_context_menu_icon_contract:
        if marker not in overlay_source:
            print(
                f"PunchiMenu Fullscreen: missing themed context-menu icon: {marker}",
                file=sys.stderr,
            )
            passed = False
    normal_context_menu_icon_contract = (
        '? "favorite-favorited"',
        ': "favorite"',
        '? "window-unpin"',
        ': "window-pin"',
        '"user-desktop", true',
        '? "view-visible"',
        ': "view-hidden"',
    )
    for marker in normal_context_menu_icon_contract:
        if marker not in normal_source:
            print(
                f"PunchiMenu Normal: missing native themed menu icon: {marker}",
                file=sys.stderr,
            )
            passed = False
    fullscreen_context_menu_interaction_contract = (
        "modal: false",
        "Controls.Popup.CloseOnEscape",
        "requestContextMenu(targetMenu, sourceItem, x, y)",
        "property Item pendingSourceItem: null",
        "function requestContextMenu(menu, sourceItem, x, y)",
        "if (menu.opened || menu.visible)",
        "function completeContextMenuClose(menu)",
        "onClosed:",
        "Qt.callLater(function()",
        "folderSurface.restoreFocus()",
    )
    for marker in fullscreen_context_menu_interaction_contract:
        if marker not in overlay_source:
            print(
                f"PunchiMenu Fullscreen: missing retarget/close contract: {marker}",
                file=sys.stderr,
            )
            passed = False
    if "Controls.Popup.CloseOnPressOutside" not in overlay_source:
        print(
            "PunchiMenu Fullscreen: context menu no longer closes on an outside press",
            file=sys.stderr,
        )
        passed = False
    normal_context_menu_contract = (
        "function standaloneApplicationContextEntries(context)",
        "function folderMemberContextEntries(context)",
        "function folderContextEntries()",
        "function activateContextMenuAction(actionId)",
        "applicationContextMenuSurface.openAt(sourceItem",
        "id: applicationContextMenuSurface",
        "allowedExternalFocusItems: [applicationContextMenuSurface]",
        "root.openApplicationContextMenu(\n                                        applicationDelegate",
        "root.openApplicationContextMenu(\n                                                favoriteMouseArea",
    )
    for marker in normal_context_menu_contract:
        if marker not in normal_source:
            print(
                f"PunchiMenu Normal: missing embedded context surface contract: {marker}",
                file=sys.stderr,
            )
            passed = False
    normal_context_surface_contract = (
        "FocusScope {",
        "targetItem.mapToItem(root,",
        "signal actionTriggered(string actionId)",
        "signal closeRequested(bool restoreFocus)",
        "acceptedButtons: Qt.LeftButton",
        "propagateComposedEvents: true",
        "mouse.accepted = false",
        'imagePath: "widgets/background"',
        "PlasmaComponents.MenuItem {",
        "PlasmaComponents.MenuSeparator {",
        "Keys.priority: Keys.BeforeItem",
        "event.key === Qt.Key_Escape",
        "root.width - width - root.edgeMargin",
        "root.height - height - root.edgeMargin",
    )
    for marker in normal_context_surface_contract:
        if marker not in normal_context_surface_source:
            print(
                f"PunchiMenu Normal context surface: missing contract: {marker}",
                file=sys.stderr,
            )
            passed = False
    if normal_source.count("onPressed: function(mouse)") < 2:
        print(
            "PunchiMenu Normal: right-click menus must open from the press event",
            file=sys.stderr,
        )
        passed = False
    obsolete_normal_context_markers = (
        "PlasmaComponents.Menu {",
        "Controls.Menu {",
        "Controls.MenuItem {",
        "Controls.MenuSeparator {",
        "PlasmaExtras.Menu {",
        "PlasmaExtras.MenuItem {",
        "standaloneApplicationContextMenuComponent",
        "folderMemberContextMenuComponent",
        "folderContextMenuComponent",
        "menuComponent.createObject(root,",
        "status === PlasmaExtras.Menu.Closed",
        "property bool pendingPopupRequested: false",
        "function requestPopup(sourceItem, x, y)",
        "popupType:",
        "function dismissForTarget(storageId)",
        "function dismissForNavigation()",
        "id: contextDismissArea",
        "[PunchiMenuContextTrace]",
        "[PunchiMenuPopupGeometry]",
    )
    for marker in obsolete_normal_context_markers:
        if marker in normal_source:
            print(
                f"PunchiMenu Normal: obsolete Quick popup workaround remains: {marker}",
                file=sys.stderr,
            )
            passed = False
    if "configureToolTip.showToolTip()" in overlay_source:
        print(
            "PunchiMenu Fullscreen: configuration tooltip still opens automatically on focus",
            file=sys.stderr,
        )
        passed = False
    if ('screenInset: root.configuredPunchiMenuNormalPlacementMode === "anchored"'
            not in main_source):
        print(
            "PunchiMenu Normal: configured edge distance is not applied to screen bounds",
            file=sys.stderr,
        )
        passed = False
    if "wheel.angleDelta.y > 0 || wheel.angleDelta.x < 0" in overlay_source:
        print(
            "PunchiMenuOverlay.qml: wheel events still request pages without gesture arbitration",
            file=sys.stderr,
        )
        passed = False
    pages_view_index = overlay_source.find("id: pagesView")
    wheel_handler_index = overlay_source.find("id: wheelInputHandler")
    if pages_view_index < 0 or wheel_handler_index <= pages_view_index:
        print(
            "PunchiMenuOverlay.qml: wheel handler must be declared after the ListView",
            file=sys.stderr,
        )
        passed = False
    if "id: wheelInputInterceptor" in overlay_source:
        print(
            "PunchiMenuOverlay.qml: wheel interception still creates a cursor-blocking MouseArea",
            file=sys.stderr,
        )
        passed = False
    if "id: wheelInputHandler\n                target: null" in overlay_source:
        print(
            "PunchiMenuOverlay.qml: wheel handler is detached from the paged ListView",
            file=sys.stderr,
        )
        passed = False
    if overlay_source.count("cursorShape: Qt.PointingHandCursor") < 2:
        print(
            "PunchiMenuOverlay.qml: application and Favorite delegates must preserve the pointing cursor",
            file=sys.stderr,
        )
        passed = False
    if "appMouseArea.containsMouse && !pagesView.moving" in overlay_source:
        print(
            "PunchiMenuOverlay.qml: hover still relies only on interactive movement state",
            file=sys.stderr,
        )
        passed = False
    if "parent.activeFocus || pagesView.currentIndex === index" in overlay_source:
        print(
            "PunchiMenuOverlay.qml: page dots still change diameter with focus or selection",
            file=sys.stderr,
        )
        passed = False
    if "Controls.TextField {\n            id: searchField" in overlay_source:
        print(
            "PunchiMenuOverlay.qml: fullscreen search still uses the generic wide field",
            file=sys.stderr,
        )
        passed = False
    if "Kirigami.SearchField {" in overlay_source:
        print(
            "PunchiMenuOverlay.qml: Kirigami.SearchField reintroduces non-Plasma tooltips",
            file=sys.stderr,
        )
        passed = False
    if "Controls.ToolTip.visible: hovered || activeFocus" in overlay_source:
        print(
            "PunchiMenuOverlay.qml: configuration tooltip does not use Plasma styling",
            file=sys.stderr,
        )
        passed = False
    if "PlasmaComponents.ToolTip." in overlay_source:
        print(
            "PunchiMenuOverlay.qml: attached tooltips can inherit the fullscreen color scheme",
            file=sys.stderr,
        )
        passed = False
    if "id: clearSearchToolTip" in overlay_source:
        print(
            "PunchiMenuOverlay.qml: the approved tooltip-free search bar still creates a tooltip",
            file=sys.stderr,
        )
        passed = False
    if overlay_source.count("PlasmaCore.ToolTipArea {") < 7:
        print(
            "PunchiMenuOverlay.qml: every fullscreen action tooltip must use a Plasma tooltip window",
            file=sys.stderr,
        )
        passed = False

    fullscreen_favorites_contract = (
        "readonly property bool favoritesSectionVisible",
        "id: favoritesSection",
        "readonly property real reservedHeight",
        'i18nc("@title:section", "Favorites")',
        "model: root.favorites",
        "function launchFavoriteAt(index)",
        "function openCurrentFavoriteContextMenu()",
        "root.openApplicationContextMenu(\n                                                favoriteDelegate",
        "id: favoritesLeftToolTip",
        "id: favoritesRightToolTip",
    )
    for marker in fullscreen_favorites_contract:
        if marker not in overlay_source:
            print(
                f"PunchiMenuOverlay.qml: missing fullscreen favorites contract: {marker}",
                file=sys.stderr,
            )
            passed = False

    favorite_scale_contract = (
        (
            config_items_source,
            "function normalizedPunchiMenuFavoriteIconScalePercent(value)",
            "safe Favorites scale normalization",
        ),
        (
            config_items_source,
            "Math.max(75, Math.min(110",
            "safe Favorites scale range",
        ),
        (
            settings_view_source,
            '"Favorites icon scale:")',
            "embedded Favorites scale control",
        ),
        (
            main_source,
            "readonly property real configuredPunchiMenuFavoriteIconScale",
            "reactive Favorites scale projection",
        ),
        (
            normal_source,
            "readonly property real safeFavoriteIconScale",
            "Normal Favorites scale clamp",
        ),
        (
            overlay_source,
            "readonly property real safeFavoriteIconScale",
            "Fullscreen Favorites scale clamp",
        ),
    )
    for source, marker, description in favorite_scale_contract:
        if marker not in source:
            print(
                f"PunchiMenu Favorites scale: missing {description}: {marker}",
                file=sys.stderr,
            )
            passed = False

    background_legibility_contract = (
        (
            config_items_source,
            "function normalizedPunchiMenuFullScreenBackgroundOpacityPercent(value)",
            "Fullscreen opacity normalization",
        ),
        (
            config_items_source,
            "function normalizedPunchiMenuNormalBackgroundOpacityPercent(value)",
            "Normal opacity normalization",
        ),
        (
            config_items_source,
            "Math.max(50, Math.min(100",
            "safe opacity percentage range",
        ),
        (
            main_source,
            "readonly property bool configuredPunchiMenuFullScreenBlurEnabled",
            "Fullscreen reactive blur projection",
        ),
        (
            main_source,
            "readonly property real configuredPunchiMenuFullScreenBackgroundOpacity",
            "Fullscreen reactive opacity projection",
        ),
        (
            main_source,
            "readonly property bool configuredPunchiMenuNormalBlurEnabled",
            "Normal reactive blur projection",
        ),
        (
            main_source,
            "readonly property real configuredPunchiMenuNormalBackgroundOpacity",
            "Normal reactive opacity projection",
        ),
        (
            main_source,
            "window: punchiMenuNormalDialog",
            "Normal dialog-owned blur controller",
        ),
        (
            normal_source,
            "readonly property var backgroundBlurMaskSource: normalBackground",
            "Normal background-owned blur mask source",
        ),
        (
            main_source,
            "maskSource: punchiMenuNormal.backgroundBlurMaskSource",
            "Normal themed blur source binding",
        ),
        (
            normal_source,
            "readonly property point backgroundBlurMaskOffset:",
            "Normal background-owned blur mask offset",
        ),
        (
            main_source,
            "maskOffset: punchiMenuNormal.backgroundBlurMaskOffset",
            "Normal themed blur offset binding",
        ),
        (
            overlay_source,
            "enabled: root.menuOpen && root.backgroundBlurEnabled",
            "Fullscreen blur switch binding",
        ),
        (
            overlay_source,
            "opacity: root.safeBackgroundOpacity",
            "Fullscreen background-only opacity",
        ),
        (
            normal_source,
            "property real backgroundOpacity: 0.75",
            "Normal background opacity input",
        ),
        (
            normal_source,
            "opacity: root.safeBackgroundOpacity",
            "Normal background-only opacity",
        ),
    )
    for source, marker, description in background_legibility_contract:
        if marker not in source:
            print(
                f"PunchiMenu background legibility: missing {description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    normal_blur_region_pattern = re.compile(
        r"readonly\s+property\s+Punchi\.BlurBehindController\s+"
        r"normalBlurController\s*:\s*Punchi\.BlurBehindController\s*\{\s*"
        r"window\s*:\s*punchiMenuNormalDialog\s*"
        r"fullWindow\s*:\s*false\s*"
        r"maskSource\s*:\s*punchiMenuNormal\.backgroundBlurMaskSource\s*"
        r"useMaskSourceInsets\s*:\s*true\s*"
        r"maskOffset\s*:\s*punchiMenuNormal\.backgroundBlurMaskOffset\s*"
        r"enabled\s*:\s*punchiMenuNormalDialog\.visible\s*"
        r"&&\s*root\.configuredPunchiMenuNormalBlurEnabled\s*\}",
        re.DOTALL,
    )
    if normal_blur_region_pattern.search(main_source) is None:
        print(
            "PunchiMenu background legibility: the Normal blur controller must "
            "use the complete reactive mask-and-inset contract",
            file=sys.stderr,
        )
        passed = False
    normal_blur_mapping_contract = (
        "root.backgroundItem.mapToItem(",
        "root.surfaceItem.width, root.surfaceItem.height",
        "root.surfaceItem.scale, root.surfaceItem.transformOrigin",
        "root.translationX, root.translationY",
    )
    for marker in normal_blur_mapping_contract:
        if marker not in mapped_surface_geometry_source:
            print(
                "PunchiMenu background legibility: the blur position must "
                f"follow the animated visual hierarchy: {marker}",
                file=sys.stderr,
            )
            passed = False
    normal_compact_source = re.sub(r"\s+", " ", normal_source)
    if (
        "backgroundBlurMaskOffset: "
        "mappedSurfaceGeometry.backgroundMaskOffset"
        not in normal_compact_source
    ):
        print(
            "PunchiMenu background legibility: Normal must consume the "
            "reactive mapped mask offset",
            file=sys.stderr,
        )
        passed = False
    compact_menu_compact_source = re.sub(r"\s+", " ", compact_menu_source)
    compact_blur_mapping_contract = (
        "backgroundBlurMaskOffset: "
        "mappedSurfaceGeometry.backgroundMaskOffset",
        "PunchiMenuMappedSurfaceGeometry { id: mappedSurfaceGeometry",
        "targetItem: root surfaceItem: surface "
        "backgroundItem: compactBackground",
        "translationX: surfaceTranslation.x "
        "translationY: surfaceTranslation.y",
        "leftInset: compactBackground.inset.left",
        "topInset: compactBackground.inset.top",
        "rightInset: compactBackground.inset.right",
        "bottomInset: compactBackground.inset.bottom",
    )
    for marker in compact_blur_mapping_contract:
        if marker not in compact_menu_compact_source:
            print(
                "PunchiMenu background legibility: Compact must consume the "
                f"reactive mapped mask geometry: {marker}",
                file=sys.stderr,
            )
            passed = False
    if "compactBackground.mapToItem(null" in compact_menu_source:
        print(
            "PunchiMenu background legibility: Compact must not keep a "
            "non-reactive direct mask offset binding",
            file=sys.stderr,
        )
        passed = False
    retired_blur_geometry_markers = (
        "blurPadding",
        "blurInsetPercent",
        "blurCornerRadiusPercent",
        "blurCornerRadius",
        "cornerRadius: punchiMenuNormalDialog",
    )
    if any(marker in main_source for marker in retired_blur_geometry_markers):
        print(
            "PunchiMenu background legibility: independent Normal blur geometry must not return",
            file=sys.stderr,
        )
        passed = False
    retired_normal_blur_clip_markers = (
        (main_source, "maskClipRect"),
        (normal_source, "backgroundBlurClipGeometry"),
        (normal_source, "effectiveBackgroundGeometry"),
    )
    if any(
        marker in source
        for source, marker in retired_normal_blur_clip_markers
    ):
        print(
            "PunchiMenu background legibility: the exact Normal mask must not "
            "be intersected with a parallel rectangular geometry",
            file=sys.stderr,
        )
        passed = False
    normal_widget_background_contract = (
        (main_source, "backgroundHints: PlasmaCore.Dialog.NoBackground", "transparent dialog host"),
        (normal_source, "import org.kde.ksvg as KSvg", "KSvg import"),
        (normal_source, "KSvg.FrameSvgItem {", "themed frame surface"),
        (normal_source, "id: normalBackground", "single Normal background authority"),
        (normal_source, 'imagePath: "widgets/background"', "widget background resource"),
        (normal_source, "opacity: root.safeBackgroundOpacity", "background-only opacity"),
        (normal_source, "normalBackground.margins.left", "themed left content margin"),
        (normal_source, "normalBackground.margins.top", "themed top content margin"),
        (normal_source, "normalBackground.margins.right", "themed right content margin"),
        (normal_source, "normalBackground.margins.bottom", "themed bottom content margin"),
    )
    for source, marker, description in normal_widget_background_contract:
        if marker not in source:
            print(
                f"PunchiMenu Normal widget background: missing {description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    if "backgroundHints: PlasmaCore.Dialog.StandardBackground" in main_source:
        print(
            "PunchiMenu Normal widget background: the old dialog background remains enabled",
            file=sys.stderr,
        )
        passed = False
    if main_source.count(
        "backgroundOpacity: root.configuredPunchiMenu"
    ) < 2:
        print(
            "main.qml: both PunchiMenu modes must receive their background opacity",
            file=sys.stderr,
        )
        passed = False
    if main_source.count(
        "favoriteIconScale: root.configuredPunchiMenuFavoriteIconScale"
    ) < 2:
        print(
            "main.qml: both PunchiMenu modes must receive the shared Favorites scale",
            file=sys.stderr,
        )
        passed = False
    if 'icon.name: "window-close"' not in normal_source:
        print(
            "PunchiMenuNormal.qml: Close must use the theme-aware full icon",
            file=sys.stderr,
        )
        passed = False
    if 'icon.name: "window-close-symbolic"' in normal_source:
        print(
            "PunchiMenuNormal.qml: the low-contrast symbolic Close icon remains",
            file=sys.stderr,
        )
        passed = False
    if 'icon.name: "window-close"' not in overlay_source:
        print(
            "PunchiMenuOverlay.qml: Close must match the theme-aware Normal icon",
            file=sys.stderr,
        )
        passed = False
    if 'icon.name: "window-close-symbolic"' in overlay_source:
        print(
            "PunchiMenuOverlay.qml: the neutral symbolic Close icon remains",
            file=sys.stderr,
        )
        passed = False
    if overlay_source.count("PunchiMenuSearchBackground {") != 1:
        print(
            "PunchiMenuOverlay.qml: search must remain the only pill surface",
            file=sys.stderr,
        )
        passed = False
    if normal_source.count("PunchiMenuSearchBackground {") != 1:
        print("PunchiMenuNormal.qml: shared search pill is missing", file=sys.stderr)
        passed = False
    if "contentItem: Rectangle {" in overlay_source:
        print(
            "PunchiMenuOverlay.qml: page dot is still stretched as the button content item",
            file=sys.stderr,
        )
        passed = False
    if "preferredHighlightEnd: width" in overlay_source:
        print(
            "PunchiMenuOverlay.qml: page snapping still uses the entire viewport as its highlight range",
            file=sys.stderr,
        )
        passed = False
    if "currentIndex: 0\n                cacheBuffer" in overlay_source:
        print(
            "PunchiMenuOverlay.qml: a constant current-page binding can fight interactive swipes",
            file=sys.stderr,
        )
        passed = False
    if "positionViewAtIndex(safePage, ListView.Center)" in overlay_source:
        print(
            "PunchiMenuOverlay.qml: immediate positioning still overrides smooth page motion",
            file=sys.stderr,
        )
        passed = False

    hidden_applications_contract = (
        (
            config_items_source,
            "function normalizedPunchiMenuHiddenApplicationIds(value)",
            "persistent identifier normalization",
        ),
        (
            config_items_source,
            "item.hiddenApplicationIds = normalizedPunchiMenuHiddenApplicationIds(",
            "configuration pruning",
        ),
        (
            dock_items_controller_source,
            "function setPunchiMenuApplicationHidden(storageId, hidden)",
            "controller-owned persistence",
        ),
        (
            dock_items_controller_source,
            "root.syncDockItemsConfiguration()",
            "reactive configuration synchronization",
        ),
        (
            main_source,
            "readonly property var configuredPunchiMenuHiddenApplicationIds",
            "runtime configuration projection",
        ),
        (
            overlay_source,
            "property var hiddenApplicationIds: []",
            "fullscreen hidden identifiers",
        ),
        (
            overlay_source,
            "property bool revealHiddenApplications: false",
            "transient reveal state",
        ),
        (
            overlay_source,
            "if (appHidden && !revealHiddenApplications)",
            "catalog filtering",
        ),
        (
            overlay_source,
            "signal setApplicationHiddenRequested(string storageId, bool hidden)",
            "view intent signal",
        ),
        (
            overlay_source,
            'i18nc("@action:inmenu", "Hide from listing")',
            "context action for hiding",
        ),
        (
            overlay_source,
            'i18nc("@action:inmenu", "Show in listing")',
            "context action for restoring",
        ),
        (
            overlay_source,
            'source: "view-hidden-symbolic"',
            "non-color hidden marker",
        ),
        (
            overlay_source,
            'i18nc("@action:button", "Show hidden applications")',
            "reveal action",
        ),
        (
            overlay_source,
            'i18nc("@action:button", "Hide hidden applications")',
            "filter action",
        ),
        (
            overlay_source,
            'i18nc("@info:accessibility",\n                                        "Hidden from the application listing")',
            "accessible hidden state",
        ),
        (
            overlay_source,
            "event.key === Qt.Key_Menu",
            "keyboard context-menu access",
        ),
        (
            overlay_source,
            "const app = applicationAt(currentApplicationIndex)",
            "selected application context-menu routing",
        ),
    )
    for source, marker, description in hidden_applications_contract:
        if marker not in source:
            print(
                f"PunchiMenu hidden applications: missing {description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    normal_hidden_contract = (
        "property var hiddenApplicationIds: []",
        "property bool revealHiddenApplications: false",
        "function applicationShouldBeVisible(storageId)",
        "signal setApplicationHiddenRequested(string storageId, bool hidden)",
        'i18nc("@action:inmenu", "Hide from listing")',
        'i18nc("@action:inmenu", "Show in listing")',
        'i18nc("@action:button", "Show hidden applications")',
        'i18nc("@action:button", "Hide hidden applications")',
        'source: "view-hidden-symbolic"',
        "event.key === Qt.Key_Menu",
    )
    for marker in normal_hidden_contract:
        if marker not in normal_source:
            print(
                f"PunchiMenuNormal.qml: missing shared hidden-item contract: {marker}",
                file=sys.stderr,
            )
            passed = False
    if main_source.count(
        "hiddenApplicationIds: root.configuredPunchiMenuHiddenApplicationIds"
    ) < 2:
        print(
            "main.qml: both PunchiMenu presentations must share hidden applications",
            file=sys.stderr,
        )
        passed = False
    if main_source.count("onSetApplicationHiddenRequested:") < 2:
        print(
            "main.qml: both PunchiMenu presentations must persist hidden applications",
            file=sys.stderr,
        )
        passed = False
    if overlay_source.count("revealHiddenApplications = false") < 3:
        print(
            "PunchiMenuOverlay.qml: transient reveal state is not reset on every close path",
            file=sys.stderr,
        )
        passed = False
    if normal_source.count("revealHiddenApplications = false") < 3:
        print(
            "PunchiMenuNormal.qml: transient reveal state is not reset on every close path",
            file=sys.stderr,
        )
        passed = False

    normal_placement_contract = (
        (
            config_items_source,
            "function normalizedPunchiMenuNormalPlacementMode(value)",
            "persistent placement normalization",
        ),
        (
            settings_view_source,
            '"Normal menu placement:")',
            "embedded translated setting label",
        ),
        (
            main_source,
            "readonly property string configuredPunchiMenuNormalPlacementMode",
            "reactive runtime projection",
        ),
        (
            placement_source,
            'if (root.placementMode === "centered")',
            "available-area centering",
        ),
        (
            main_source,
            "visualParent: null",
            "single-owner Normal dialog positioning",
        ),
        (
            main_source,
            "location: PlasmaCore.Types.Floating",
            "manual anchored and centered dialog positioning",
        ),
        (
            main_source,
            "backgroundHints: PlasmaCore.Dialog.NoBackground",
            "single custom Plasma widget surface",
        ),
        (
            main_source,
            "readonly property real reportedAvailableWidth: Math.max(",
            "pre-show screen geometry fallback",
        ),
        (
            main_source,
            "minimumContentWidth + screenMargin",
            "non-empty initial dialog width",
        ),
        (
            main_source,
            "minimumContentHeight + screenMargin",
            "non-empty initial dialog height",
        ),
        (
            main_source,
            "Layout.minimumWidth: punchiMenuNormalDialog.desiredContentWidth",
            "native panel dialog minimum width",
        ),
        (
            main_source,
            "Layout.maximumWidth: punchiMenuNormalDialog.desiredContentWidth",
            "native panel dialog fixed width",
        ),
        (
            main_source,
            "Layout.minimumHeight: punchiMenuNormalDialog.desiredContentHeight",
            "native panel dialog minimum height",
        ),
        (
            main_source,
            "Layout.maximumHeight: punchiMenuNormalDialog.desiredContentHeight",
            "native panel dialog fixed height",
        ),
        (
            category_pill_source,
            "radius: height / 2",
            "pill geometry",
        ),
    )
    for source, marker, description in normal_placement_contract:
        if marker not in source:
            print(
                f"PunchiMenu Normal: missing {description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    if "visualParent: root.punchiMenuAnchorItem || root" in main_source \
            or 'visualParent: root.configuredPunchiMenuNormalPlacementMode === "centered"' \
            in main_source:
        print(
            "main.qml: Normal mode still allows Plasma to override its calculated position",
            file=sys.stderr,
        )
        passed = False
    if "PunchiMenuCategoryPill {" not in normal_source:
        print("PunchiMenuNormal.qml: category pill component is not used", file=sys.stderr)
        passed = False

    normal_pointer_contract = (
        (category_pill_source, "id: pointerHover", "category hover source"),
        (
            category_pill_source,
            "Kirigami.Theme.highlightedTextColor",
            "category highlighted text color",
        ),
        (
            category_pill_source,
            "cursorShape: Qt.PointingHandCursor",
            "category pointing cursor",
        ),
        (normal_source, "id: sessionHover", "session-view hover source"),
        (normal_source, "id: categoryLeftHover", "left category cursor"),
        (normal_source, "id: categoryRightHover", "right category cursor"),
        (normal_source, "id: favoritesLeftHover", "left Favorites cursor"),
        (normal_source, "id: favoritesRightHover", "right Favorites cursor"),
    )
    for source, marker, description in normal_pointer_contract:
        if marker not in source:
            print(
                f"PunchiMenu Normal interaction: missing {description}: {marker}",
                file=sys.stderr,
            )
            passed = False

    normal_horizontal_wheel_contract = (
        "function handleHorizontalWheel(",
        "id: categoriesWheelHandler",
        "target: categoriesView",
        "id: favoritesWheelHandler",
        "target: favoritesView",
        "id: applicationDragWheelBlocker",
        "target: internalDragLayer.active",
        "scrollFlickableTarget: false",
        "blockTargetWheel: true",
    )
    for marker in normal_horizontal_wheel_contract:
        if marker not in normal_source:
            print(
                f"PunchiMenu Normal wheel: missing smooth horizontal contract: {marker}",
                file=sys.stderr,
            )
            passed = False
    if normal_source.count("Kirigami.WheelHandler {") != 3:
        print(
            "PunchiMenu Normal wheel: categories, Favorites, and active DnD need exactly three handlers",
            file=sys.stderr,
        )
        passed = False

    normal_feedback_contract = (
        "readonly property int operationMessageDuration: 7000",
        "property int operationSecondsRemaining: 0",
        '"%1 · %2 s"',
        "id: operationMessageTimer",
        "id: operationFeedback",
        "id: operationFeedbackHover",
        "z: 400",
        "Kirigami.Units.gridUnit * 36",
        "showCloseButton: true",
        "function dismissOperationMessage()",
        "operationMessageTimer.stop()",
        "operationMessageTimer.start()",
        "interval: 1000",
        "repeat: true",
        "Accessible.name: root.operationBaseMessage",
        "detailedApplicationFeedback: true",
    )
    for marker in normal_feedback_contract:
        if marker not in normal_source:
            print(
                f"PunchiMenu Normal feedback: missing contract: {marker}",
                file=sys.stderr,
            )
            passed = False
    if "operationMessageTimer.restart()" in normal_source:
        print(
            "PunchiMenu Normal feedback: hover must resume without resetting time",
            file=sys.stderr,
        )
        passed = False
    if normal_source.count("Kirigami.InlineMessage {") != 1:
        print(
            "PunchiMenu Normal feedback: status message must have one top-level owner",
            file=sys.stderr,
        )
        passed = False

    fullscreen_feedback_contract = (
        "readonly property int operationMessageDuration: 7000",
        "property int operationSecondsRemaining: 0",
        '"%1 · %2 s"',
        "id: operationMessageTimer",
        "id: operationInlineMessage",
        "id: operationInlineMessageHover",
        "width: Math.min(gridArea.width, Kirigami.Units.gridUnit * 36)",
        "showCloseButton: true",
        "function dismissOperationMessage()",
        "operationMessageTimer.stop()",
        "operationMessageTimer.start()",
        "interval: 1000",
        "repeat: true",
        "Accessible.name: root.operationBaseMessage",
    )
    for marker in fullscreen_feedback_contract:
        if marker not in overlay_source:
            print(
                f"PunchiMenu Fullscreen feedback: missing contract: {marker}",
                file=sys.stderr,
            )
            passed = False
    if "operationMessageTimer.restart()" in overlay_source:
        print(
            "PunchiMenu Fullscreen feedback: hover must resume without resetting time",
            file=sys.stderr,
        )
        passed = False

    dedicated_config_contract = (
        (
            config_model_source,
            'source: "config/ConfigAdditionalShortcuts.qml"',
            "additional shortcuts configuration category",
        ),
        (dialog_source, '"value": "fullScreen"', "full-screen mode option"),
        (dialog_source, '"value": "normal"', "Normal mode option"),
        (workflow_source, "ConfigItemsJS.prunePunchiMenu(item)",
         "shared item normalization"),
        (
            settings_view_source,
            '"normalPanelDistancePercent", Math.round(value)',
            "embedded panel distance control",
        ),
        (
            config_items_source,
            "function normalizedPunchiMenuNormalPanelDistancePercent(value, legacyGap)",
            "panel distance normalization",
        ),
        (
            config_items_source,
            '"normalPanelDistancePercent": 25',
            "panel distance default",
        ),
        (
            main_source,
            "readonly property int configuredPunchiMenuNormalPanelDistancePercent",
            "reactive panel distance projection",
        ),
        (
            main_source,
            "panelGap: root.configuredPunchiMenuNormalPanelGap",
            "runtime panel distance binding",
        ),
        (
            placement_source,
            "property real panelThickness: 0",
            "panel thickness fallback input",
        ),
        (
            normal_source,
            "readonly property real verticalScrollBarReserve:",
            "scrollbar width reservation",
        ),
        (
            normal_source,
            "(width - verticalScrollBarReserve) / root.columnCount",
            "grid width adjustment",
        ),
    )
    for source, marker, description in dedicated_config_contract:
        if marker not in source:
            print(
                f"PunchiMenu dedicated configuration: missing {description}: {marker}",
                file=sys.stderr,
            )
            passed = False
    if "Punchi.BlurBehindController" in normal_source or "surfaceOpacity" in normal_source:
        print("PunchiMenuNormal.qml: manual surface blur was not retired", file=sys.stderr)
        passed = False
    if "Controls.ToolTip" in normal_source:
        print("PunchiMenuNormal.qml: a generic tooltip remains", file=sys.stderr)
        passed = False
    if normal_source.count("PlasmaCore.ToolTipArea {") < 6:
        print("PunchiMenuNormal.qml: Plasma tooltips are incomplete", file=sys.stderr)
        passed = False

    main_source = (PROJECT_ROOT / "contents/ui/main.qml").read_text(encoding="utf-8")
    if main_source.count("showOperationResult(") < 4:
        print("main.qml: operation results are not handled by both menus", file=sys.stderr)
        passed = False
    if "import org.kde.kwindowsystem" not in main_source:
        print("main.qml: KWindowSystem is used without its QML import", file=sys.stderr)
        passed = False
    if "readonly property var dockItemsControllerService: dockItemsController" not in main_source:
        print("main.qml: the outer dock controller is not exposed explicitly", file=sys.stderr)
        passed = False
    if "readonly property int configuredPunchiMenuItemIndex" not in main_source:
        print("main.qml: PunchiMenu configuration target index is missing", file=sys.stderr)
        passed = False
    if "onConfigureRequested:" not in main_source or "root.openDockItemEditor(itemIndex)" not in main_source:
        print("main.qml: fullscreen configuration request is not routed", file=sys.stderr)
        passed = False
    if main_source.count("dockItemsController: root.dockItemsControllerService") < 2:
        print("main.qml: both PunchiMenu instances must receive the outer controller", file=sys.stderr)
        passed = False
    if main_source.count("dockItemsController: dockItemsController") != 1:
        print("main.qml: unexpected self-named dock controller binding in PunchiMenu", file=sys.stderr)
        passed = False
    if main_source.count("root.dockItemsControllerService.togglePinAppToDock(") < 2:
        print("main.qml: pin handlers do not use the outer controller", file=sys.stderr)
        passed = False
    if main_source.count("root.dockItemsControllerService.pinAppToDesktop(") < 2:
        print("main.qml: desktop shortcut handlers do not use the outer controller", file=sys.stderr)
        passed = False
    if "readonly property bool isX11Session: KWindowSystem.isPlatformX11" not in main_source:
        print("main.qml: the normal menu does not detect X11 through KWindowSystem", file=sys.stderr)
        passed = False
    x11_popup_flags = "? Qt.Popup | Qt.FramelessWindowHint"
    wayland_dialog_flags = (
        ": Qt.Dialog | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint"
    )
    if x11_popup_flags not in main_source or wayland_dialog_flags not in main_source:
        print("main.qml: PunchiMenu normal lacks separate X11 and Wayland flags", file=sys.stderr)
        passed = False
    fullscreen_panel_type = (
        "type: openedFromPanel\n"
        "                ? PlasmaCore.Dialog.Normal\n"
        "                : PlasmaCore.Dialog.OnScreenDisplay"
    )
    fullscreen_panel_flags = (
        "flags: openedFromPanel\n"
        "                ? Qt.Window | Qt.FramelessWindowHint"
    )
    fullscreen_x11_flags = (
        "? Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint"
    )
    fullscreen_wayland_flags = (
        ": Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint\n"
        "                        | Qt.BypassWindowManagerHint"
    )
    if ("property bool openedFromPanel: false" not in main_source
            or "punchiMenuDialogInstance.openedFromPanel = root.inPanel" not in main_source
            or fullscreen_panel_type not in main_source
            or fullscreen_panel_flags not in main_source
            or fullscreen_x11_flags not in main_source
            or fullscreen_wayland_flags not in main_source):
        print(
            "main.qml: fullscreen PunchiMenu lacks conditional panel stacking",
            file=sys.stderr,
        )
        passed = False

    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
