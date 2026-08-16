#!/usr/bin/env python3
"""Tests for the qmllint debt inventory generator."""

from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = PROJECT_ROOT / "scripts" / "qmllint_debt_inventory.py"
SPEC = importlib.util.spec_from_file_location("qmllint_debt_inventory", SCRIPT_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"Cannot load {SCRIPT_PATH}")
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class QmllintDebtInventoryTest(unittest.TestCase):
    """Validate parsing, stable IDs, privacy, and manual-state preservation."""

    def test_inventory_preserves_manual_fields_after_line_shift(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            temporary_root = Path(temporary_directory)
            project_root = temporary_root / "project"
            project_root.mkdir()
            log_path = temporary_root / "qmllint.log"
            output_path = temporary_root / "inventory.md"
            qml_path = project_root / "contents/ui/Test.qml"
            qml_path.parent.mkdir(parents=True)
            qml_path.write_text("import QtQuick\n", encoding="utf-8")
            log_path.write_text(
                f"Warning: {qml_path}:10:7: Unqualified access [unqualified]\n",
                encoding="utf-8",
            )

            diagnostics, info_count = MODULE.parse_log(log_path, project_root)
            first = MODULE.render_inventory(
                diagnostics, info_count, {}, "test", "6.11.1", "2026-08-10"
            )
            identifier = diagnostics[0].identifier
            first = first.replace(
                f"| - [ ] | `{identifier}` |",
                f"| - [x] | `{identifier}` |",
            ).replace("| — | — |", "| Fixed explicit root access | clean rerun |")
            output_path.write_text(first, encoding="utf-8")

            log_path.write_text(
                f"Warning: {qml_path}:25:7: Unqualified access [unqualified]\n",
                encoding="utf-8",
            )
            shifted, _ = MODULE.parse_log(log_path, project_root)
            shifted = MODULE.reconcile_identifiers(
                shifted, MODULE.read_existing_rows(output_path)
            )
            states = MODULE.read_manual_state(output_path)
            updated = MODULE.render_inventory(
                shifted,
                0,
                states,
                "test",
                "6.11.1",
                "2026-08-10",
                MODULE.read_existing_rows(output_path),
            )

            self.assertEqual(identifier, shifted[0].identifier)
            self.assertIn(f"| - [ ] | `{identifier}` |", updated)
            self.assertIn("Fixed explicit root access", updated)
            self.assertIn("clean rerun", updated)
            self.assertNotIn(str(temporary_root), updated)

    def test_missing_warning_is_retained_for_manual_closure(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            output_path = root / "inventory.md"
            row = (
                "| - [ ] | `QML-ABC123` | `contents/ui/Test.qml` | 7:2 | "
                "`alias-cycle` | Alias cycle | Explanation | needs review | — |"
            )
            output_path.write_text(row + "\n", encoding="utf-8")

            rendered = MODULE.render_inventory(
                [],
                0,
                MODULE.read_manual_state(output_path),
                "test",
                "6.11.1",
                "2026-08-10",
                MODULE.read_existing_rows(output_path),
            )

            self.assertIn("## Firmas ausentes del corte actual", rendered)
            self.assertIn("`QML-ABC123`", rendered)
            self.assertIn("needs review", rendered)

    def test_removing_first_duplicate_does_not_shift_following_id(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            project_root = root / "project"
            project_root.mkdir()
            qml_path = project_root / "contents/ui/Test.qml"
            qml_path.parent.mkdir(parents=True)
            qml_path.write_text("import QtQuick\n", encoding="utf-8")
            log_path = root / "qmllint.log"
            output_path = root / "inventory.md"
            log_path.write_text(
                "".join(
                    (
                        f"Warning: {qml_path}:10:7: Unqualified access [unqualified]\n",
                        f"Warning: {qml_path}:20:7: Unqualified access [unqualified]\n",
                    )
                ),
                encoding="utf-8",
            )
            initial, _ = MODULE.parse_log(log_path, project_root)
            output_path.write_text(
                MODULE.render_inventory(
                    initial, 0, {}, "test", "6.11.1", "2026-08-10"
                ),
                encoding="utf-8",
            )
            first_id, second_id = (item.identifier for item in initial)

            log_path.write_text(
                f"Warning: {qml_path}:20:7: Unqualified access [unqualified]\n",
                encoding="utf-8",
            )
            remaining, _ = MODULE.parse_log(log_path, project_root)
            remaining = MODULE.reconcile_identifiers(
                remaining, MODULE.read_existing_rows(output_path)
            )

            self.assertEqual(second_id, remaining[0].identifier)
            self.assertNotEqual(first_id, remaining[0].identifier)

    def test_external_diagnostic_path_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            with self.assertRaises(ValueError):
                MODULE.normalize_project_path("/outside/Test.qml", root)


if __name__ == "__main__":
    unittest.main()
