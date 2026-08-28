#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "contents/ui/config"


def require_markers(source: str, markers: tuple[str, ...], label: str) -> bool:
    passed = True
    for marker in markers:
        if marker not in source:
            print(f"{label}: missing separator value contract: {marker}", file=sys.stderr)
            passed = False
    return passed


def main() -> int:
    sources = {
        "SeparatorOptions.qml": (CONFIG / "SeparatorOptions.qml").read_text(
            encoding="utf-8"
        ),
        "ItemEditorPanel.qml": (CONFIG / "ItemEditorPanel.qml").read_text(
            encoding="utf-8"
        ),
        "ActionDialog.qml": (
            CONFIG / "components/ActionDialog.qml"
        ).read_text(encoding="utf-8"),
    }
    config_items = (CONFIG / "ConfigItems.qml").read_text(encoding="utf-8")
    form_helper = (CONFIG / "code/configItemsFormHelper.js").read_text(
        encoding="utf-8"
    )
    workflow_helper = (CONFIG / "code/configItemsWorkflowHelper.js").read_text(
        encoding="utf-8"
    )

    passed = True
    for label, source in sources.items():
        passed = require_markers(
            source,
            (
                "readonly property string separatorStyleValue:",
                "readonly property string separatorAppearanceSourceValue:",
                "readonly property real separatorThicknessValue:",
                "readonly property real separatorLengthRatioValue:",
                "readonly property real separatorOpacityValue:",
                "readonly property bool separatorGlowEnabled:",
                "function setSeparatorStyleValue(value)",
                "function setSeparatorAppearanceSourceValue(value)",
                "function setSeparatorThicknessValue(value)",
                "function setSeparatorLengthRatioValue(value)",
                "function setSeparatorOpacityValue(value)",
                "function setSeparatorGlowEnabled(enabled)",
            ),
            label,
        ) and passed
        if re.search(r"property\s+alias\s+separator\w*Control\s*:", source):
            print(
                f"{label}: separator controls must not cross component boundaries by alias",
                file=sys.stderr,
            )
            passed = False

    if re.search(r"property\s+alias\s+separator(Style|Thickness|LengthRatio|Opacity|Glow)\s*:", config_items):
        print("ConfigItems.qml: obsolete separator control alias remains", file=sys.stderr)
        passed = False

    passed = require_markers(
        form_helper,
        (
            "actionDialog.setSeparatorStyleValue(requestedSeparatorStyle)",
            "actionDialog.setSeparatorAppearanceSourceValue(",
            "actionDialog.setSeparatorThicknessValue(",
            "actionDialog.setSeparatorLengthRatioValue(",
            "actionDialog.setSeparatorOpacityValue(",
            "actionDialog.setSeparatorGlowEnabled(",
            "item.separatorStyle = actionDialog.separatorStyleValue",
            "item.separatorAppearanceSource",
            "item.separatorThickness = actionDialog.separatorThicknessValue",
            "item.separatorLengthRatio = actionDialog.separatorLengthRatioValue",
            "item.separatorOpacity = actionDialog.separatorOpacityValue",
            "item.separatorGlowEnabled = actionDialog.separatorGlowEnabled",
        ),
        "configItemsFormHelper.js",
    ) and passed

    passed = require_markers(
        sources["ItemEditorPanel.qml"],
        (
            "readonly property bool dynamicApplicationsItem:",
            "readonly property bool separatorVisibleChecked:",
            "function setSeparatorVisibleChecked(visible)",
            'text: i18n("Show separator")',
            "|| root.dynamicApplicationsItem",
            "|| separatorVisibleCheckBox.checked",
        ),
        "ItemEditorPanel.qml dynamic applications editor",
    ) and passed
    passed = require_markers(
        sources["ActionDialog.qml"],
        (
            "readonly property bool separatorVisibleChecked:",
            "function setSeparatorVisibleChecked(visible)",
        ),
        "ActionDialog.qml dynamic applications editor",
    ) and passed
    passed = require_markers(
        form_helper,
        (
            "actionDialog.setSeparatorVisibleChecked(item.showSeparator !== false)",
            'if (item.type === "dynamic-applications")',
            "item.showSeparator = actionDialog.separatorVisibleChecked",
            "ConfigItemsJS.pruneDynamicApplications(item)",
        ),
        "configItemsFormHelper.js dynamic applications editor",
    ) and passed
    passed = require_markers(
        workflow_helper,
        (
            'return i18n("Configure open applications")',
            'item.type !== "dynamic-applications"',
            'selectedItemType === "dynamic-applications"',
        ),
        "configItemsWorkflowHelper.js dynamic applications editor",
    ) and passed

    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
