#!/usr/bin/env python3
"""Protect the persisted task scope contract and its live QML connections."""

from pathlib import Path
import re
import unittest
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parent.parent


class TaskScopeConfigTest(unittest.TestCase):
    def test_schema_defaults_and_live_bindings(self):
        schema = ET.parse(ROOT / "contents/config/main.xml")
        groups = schema.findall(".//{*}group")
        page = (ROOT / "contents/ui/config/ConfigWindows.qml").read_text()
        main = (ROOT / "contents/ui/main.qml").read_text()
        controller = (ROOT / "contents/ui/components/TaskModelController.qml").read_text()
        for key, prop, control, default in (
            ("showTasksCurrentDesktopOnly", "currentDesktopOnly", "currentDesktopOnlyCheck", "true"),
            ("showTasksCurrentActivityOnly", "currentActivityOnly", "currentActivityOnlySwitch", "false"),
            ("showTasksCurrentScreenOnly", "currentScreenOnly", "currentScreenOnlySwitch", "false"),
        ):
            with self.subTest(key=key):
                matches = [(group, entry) for group in groups
                           for entry in group.findall("{*}entry")
                           if entry.get("name") == key]
                self.assertEqual(len(matches), 1)
                group, entry = matches[0]
                self.assertEqual(group.get("name"), "General")
                self.assertEqual(entry.get("type"), "Bool")
                self.assertEqual(entry.find("{*}default").text, default)
                self.assertIn(f"property alias cfg_{key}: {control}.checked", page)
                self.assertIn(f"{prop}: Plasmoid.configuration.{key}", main)
                self.assertIn(f"property bool {prop}: {default}", controller)

    def test_page_is_registered_and_screen_comes_from_containment(self):
        categories = (ROOT / "contents/config/config.qml").read_text()
        self.assertIn('source: "config/ConfigWindows.qml"', categories)
        main = (ROOT / "contents/ui/main.qml").read_text()
        task_block = main.split("TaskModelController {", 1)[1].split("\n    }", 1)[0]
        self.assertRegex(task_block, r"screenGeometry:\s*Plasmoid\.containment\s*"
                         r"\?\s*Plasmoid\.containment\.screenGeometry")

    def test_modern_desktop_filter_receives_both_boolean_states(self):
        controller = (ROOT / "contents/ui/components/TaskModelController.qml").read_text()
        method = controller.split("function updateCurrentDesktopFilter()", 1)[1].split(
            "\n    function ", 1)[0]
        self.assertRegex(method, r"const nativeFilterApplied = "
                         r"TaskManagerCompatibility\.setOptionalProperty\("
                         r'\s*tasksModel, "filterByCurrentVirtualDesktop", enabled\)')
        self.assertIn("enabled && !nativeFilterApplied", method)
        self.assertNotRegex(method, re.compile(r'enabled\s*&&\s*TaskManagerCompatibility'))


if __name__ == "__main__":
    unittest.main()
