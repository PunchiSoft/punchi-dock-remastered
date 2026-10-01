#!/usr/bin/env python3
"""Unit tests for the reproducible Plasma configuration auditor."""

from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = PROJECT_ROOT / "scripts-dev" / "audit-plasma-config.py"
SPEC = importlib.util.spec_from_file_location("audit_plasma_config", SCRIPT_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"Cannot load {SCRIPT_PATH}")
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class PlasmaConfigAuditorTest(unittest.TestCase):
    """Exercise success and each important structural failure."""

    def create_project(
        self,
        root: Path,
        *,
        config_source: str = "config/ConfigGeneral.qml",
        page_properties: str = "property int cfg_iconSize: 32",
        runtime_source: str = (
            "readonly property int iconSize: Plasmoid.configuration.iconSize\n"
            "readonly property var favorites: "
            "Plasmoid.configuration.punchiMenuFavoriteStorageIds\n"
        ),
        extra_entry: str = "",
    ) -> None:
        """Create the smallest valid Punchi-shaped configuration tree."""

        schema_directory = root / "contents/config"
        page_directory = root / "contents/ui/config"
        runtime_directory = root / "contents/ui"
        schema_directory.mkdir(parents=True)
        page_directory.mkdir(parents=True)
        runtime_directory.mkdir(parents=True, exist_ok=True)

        (schema_directory / "main.xml").write_text(
            """<?xml version="1.0" encoding="UTF-8"?>
<kcfg xmlns="http://www.kde.org/standards/kcfg/1.0">
  <group name="General">
    <entry name="iconSize" type="Int"><default>32</default></entry>
    <entry name="punchiMenuFavoriteStorageIds" type="StringList"><default/></entry>
    %s
  </group>
</kcfg>
""" % extra_entry,
            encoding="utf-8",
        )
        (schema_directory / "config.qml").write_text(
            "ConfigModel { ConfigCategory { source: \"%s\" } }\n" % config_source,
            encoding="utf-8",
        )
        (page_directory / "ConfigGeneral.qml").write_text(
            "Item { %s }\n" % page_properties,
            encoding="utf-8",
        )
        (runtime_directory / "main.qml").write_text(
            "Item { %s }\n" % runtime_source,
            encoding="utf-8",
        )

    def issue_codes(self, report: object) -> set[str]:
        """Return diagnostic codes from an AuditReport-like object."""

        return {issue.code for issue in report.issues}

    def test_valid_project_passes_with_runtime_only_entry(self) -> None:
        """A complete visible key and an approved runtime key pass."""

        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            self.create_project(root)

            report = MODULE.audit_project(root)

            self.assertEqual([], report.errors)
            self.assertEqual({"iconSize"}, set(report.kcm_owners))
            self.assertEqual(
                {"iconSize", "punchiMenuFavoriteStorageIds"},
                set(report.reactive_references),
            )

    def test_schema_entry_without_surface_or_runtime_reference_fails(self) -> None:
        """Disconnected schema entries produce both actionable diagnostics."""

        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            self.create_project(
                root,
                extra_entry='<entry name="orphanedValue" type="Bool"><default>false</default></entry>',
            )

            report = MODULE.audit_project(root)
            codes = self.issue_codes(report)

            self.assertIn("schema-without-kcm", codes)
            self.assertIn("schema-without-reactive-reference", codes)
            self.assertIn("schema-without-runtime-consumer", codes)

    def test_cfg_property_without_schema_fails(self) -> None:
        """A KCM property cannot silently invent a configuration key."""

        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            self.create_project(
                root,
                page_properties=(
                    "property int cfg_iconSize: 32\n"
                    "property bool cfg_unknownToggle: false"
                ),
            )

            report = MODULE.audit_project(root)

            self.assertIn("cfg-without-schema", self.issue_codes(report))

    def test_missing_or_escaping_page_source_fails(self) -> None:
        """ConfigModel sources must remain below contents/ui and exist."""

        with tempfile.TemporaryDirectory() as temporary_directory:
            missing_root = Path(temporary_directory) / "missing"
            escaping_root = Path(temporary_directory) / "escaping"
            self.create_project(missing_root, config_source="config/Missing.qml")
            self.create_project(escaping_root, config_source="../Private.qml")

            missing_report = MODULE.audit_project(missing_root)
            escaping_report = MODULE.audit_project(escaping_root)

            self.assertIn("config-page-missing", self.issue_codes(missing_report))
            self.assertIn("config-page-unsafe", self.issue_codes(escaping_report))

    def test_unknown_runtime_key_and_json_output_fail_cleanly(self) -> None:
        """Unknown runtime accesses fail and the CLI exposes stable JSON."""

        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            self.create_project(
                root,
                runtime_source=(
                    "readonly property int iconSize: Plasmoid.configuration.iconSize\n"
                    "readonly property var favorites: "
                    "Plasmoid.configuration.punchiMenuFavoriteStorageIds\n"
                    "readonly property bool unknown: Plasmoid.configuration.unknownToggle\n"
                ),
            )

            result = subprocess.run(
                (
                    sys.executable,
                    str(SCRIPT_PATH),
                    "--project-root",
                    str(root),
                    "--format",
                    "json",
                ),
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            payload = json.loads(result.stdout)

            self.assertEqual(1, result.returncode)
            self.assertEqual("fail", payload["result"])
            self.assertTrue(
                any(
                    issue["code"] == "runtime-key-without-schema"
                    for issue in payload["issues"]
                )
            )
            self.assertEqual("", result.stderr)

    def test_duplicate_schema_and_unexpected_multiple_owners_fail(self) -> None:
        """Ambiguous schema and KCM ownership cannot silently pass."""

        with tempfile.TemporaryDirectory() as temporary_directory:
            duplicate_root = Path(temporary_directory) / "duplicate"
            owners_root = Path(temporary_directory) / "owners"
            self.create_project(
                duplicate_root,
                extra_entry=(
                    '<entry name="iconSize" type="Int">'
                    "<default>48</default></entry>"
                ),
            )
            self.create_project(owners_root)
            (owners_root / "contents/ui/config/ConfigMouse.qml").write_text(
                "Item { property int cfg_iconSize: 32 }\n",
                encoding="utf-8",
            )
            (owners_root / "contents/config/config.qml").write_text(
                """ConfigModel {
    ConfigCategory { source: "config/ConfigGeneral.qml" }
    ConfigCategory { source: "config/ConfigMouse.qml" }
}
""",
                encoding="utf-8",
            )

            duplicate_report = MODULE.audit_project(duplicate_root)
            owners_report = MODULE.audit_project(owners_root)

            self.assertIn("schema-duplicate", self.issue_codes(duplicate_report))
            self.assertIn(
                "unexpected-multiple-owners", self.issue_codes(owners_report)
            )


if __name__ == "__main__":
    unittest.main()
