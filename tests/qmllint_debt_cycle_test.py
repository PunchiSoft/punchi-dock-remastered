#!/usr/bin/env python3
"""Tests for the transactional qmllint debt close workflow."""

from __future__ import annotations

import importlib.util
import os
import sys
import tempfile
import unittest
from unittest import mock
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_ROOT = PROJECT_ROOT / "scripts-dev"
sys.path.insert(0, str(SCRIPTS_ROOT))
SPEC = importlib.util.spec_from_file_location(
    "qmllint_debt_cycle", SCRIPTS_ROOT / "qmllint_debt_cycle.py"
)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("Cannot load qmllint_debt_cycle.py")
CYCLE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = CYCLE
SPEC.loader.exec_module(CYCLE)
import qmllint_debt_inventory as INVENTORY  # noqa: E402


class QmllintDebtCycleTest(unittest.TestCase):
    """Verify success and all write-blocking safety gates."""

    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary_directory.name) / "project"
        self.qml_path = self.root / "contents/ui/Test.qml"
        self.qml_path.parent.mkdir(parents=True)
        self.qml_path.write_text("import QtQuick\n", encoding="utf-8")
        self.inventory_path = self.root / "docs/debt/inventory.md"
        self.inventory_path.parent.mkdir(parents=True)
        self.baseline_path = self.root / "scripts/baseline.env"
        self.baseline_path.parent.mkdir(parents=True)
        self.backup_root = self.root / "backup/cycle"
        self.qmllint_path = self.root / "tools/fake-qmllint"
        self.qmllint_path.parent.mkdir(parents=True)
        self.gate_path = self.root / "tools/fake-gate"
        self.gate_path.write_text(
            "#!/bin/sh\ntest -f \"$QMLLINT_BASELINE_FILE\"\n",
            encoding="utf-8",
        )
        self.gate_path.chmod(0o755)
        self.initial_diagnostics = self._diagnostics((10, 20))
        self.target_id = self.initial_diagnostics[0].identifier
        self.second_id = self.initial_diagnostics[1].identifier
        self.inventory_path.write_text(
            INVENTORY.render_inventory(
                self.initial_diagnostics, 0, {}, "test", "6.11.1", "2026-08-10"
            ),
            encoding="utf-8",
        )
        self.baseline_path.write_text(
            "".join(
                (
                    "QMLLINT_BASELINE_TOTAL=2\n",
                    "QMLLINT_BASELINE_UNQUALIFIED=2\n",
                    "QMLLINT_BASELINE_LAYOUT=0\n",
                    "QMLLINT_BASELINE_MISSING_PROPERTY=0\n",
                    "QMLLINT_BASELINE_IMPORT=0\n",
                )
            ),
            encoding="utf-8",
        )

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def _diagnostics(self, lines: tuple[int, ...]) -> list[INVENTORY.WarningDiagnostic]:
        diagnostics = []
        for occurrence, line in enumerate(lines, start=1):
            path = "contents/ui/Test.qml"
            category = "unqualified"
            message = "Unqualified access"
            diagnostics.append(
                INVENTORY.WarningDiagnostic(
                    identifier=INVENTORY.stable_identifier(
                        path, category, message, occurrence
                    ),
                    path=path,
                    line=line,
                    column=7,
                    category=category,
                    message=message,
                )
            )
        return diagnostics

    def _write_fake_qmllint(self, lines: tuple[int, ...]) -> None:
        warning_lines = "".join(
            f"printf '%s\\n' 'Warning: {self.qml_path}:{line}:7: Unqualified access [unqualified]'\n"
            for line in lines
        )
        self.qmllint_path.write_text(
            "#!/bin/sh\n"
            "if [ \"$1\" = \"--version\" ]; then\n"
            "  printf '%s\\n' 'qmllint 6.11.1'\n"
            "  exit 0\n"
            "fi\n"
            + warning_lines,
            encoding="utf-8",
        )
        self.qmllint_path.chmod(0o755)

    def _config(self, identifiers: tuple[str, ...] | None = None) -> CYCLE.CycleConfig:
        return CYCLE.CycleConfig(
            identifiers=identifiers or (self.target_id,),
            observation="Confirmed test resolution",
            profile="test",
            project_root=self.root,
            inventory_path=self.inventory_path,
            baseline_path=self.baseline_path,
            qmllint_path=self.qmllint_path,
            gate_script=self.gate_path,
            backup_root=self.backup_root,
        )

    def _assert_unchanged(self, inventory_before: str, baseline_before: str) -> None:
        self.assertEqual(inventory_before, self.inventory_path.read_text(encoding="utf-8"))
        self.assertEqual(baseline_before, self.baseline_path.read_text(encoding="utf-8"))
        self.assertFalse(self.backup_root.exists())

    def test_success_closes_id_backs_up_and_lowers_baseline(self) -> None:
        self._write_fake_qmllint((20,))

        counts, backup_directory = CYCLE.close_cycle(self._config())

        self.assertEqual(1, counts.total)
        updated = self.inventory_path.read_text(encoding="utf-8")
        self.assertIn(f"| - [x] | `{self.target_id}` |", updated)
        self.assertIn(f"| - [ ] | `{self.second_id}` |", updated)
        self.assertIn("Confirmed test resolution", updated)
        self.assertIn("QMLLINT_BASELINE_TOTAL=1", self.baseline_path.read_text(encoding="utf-8"))
        self.assertTrue((backup_directory / "inventory.before.md").is_file())
        self.assertTrue((backup_directory / "baseline.before.env").is_file())

    def test_success_closes_multiple_ids_as_one_batch(self) -> None:
        self._write_fake_qmllint(())

        counts, _ = CYCLE.close_cycle(
            self._config((self.target_id, self.second_id))
        )

        self.assertEqual(0, counts.total)
        updated = self.inventory_path.read_text(encoding="utf-8")
        self.assertIn(f"| - [x] | `{self.target_id}` |", updated)
        self.assertIn(f"| - [x] | `{self.second_id}` |", updated)
        self.assertIn(
            "QMLLINT_BASELINE_TOTAL=0",
            self.baseline_path.read_text(encoding="utf-8"),
        )

    def test_target_still_active_writes_nothing(self) -> None:
        self._write_fake_qmllint((10, 20))
        inventory_before = self.inventory_path.read_text(encoding="utf-8")
        baseline_before = self.baseline_path.read_text(encoding="utf-8")

        with self.assertRaisesRegex(CYCLE.CycleError, "target IDs are still active"):
            CYCLE.close_cycle(self._config())

        self._assert_unchanged(inventory_before, baseline_before)

    def test_new_diagnostic_id_writes_nothing(self) -> None:
        self._write_fake_qmllint((20, 30))
        inventory_before = self.inventory_path.read_text(encoding="utf-8")
        baseline_before = self.baseline_path.read_text(encoding="utf-8")

        with self.assertRaisesRegex(CYCLE.CycleError, "new diagnostic IDs"):
            CYCLE.close_cycle(self._config())

        self._assert_unchanged(inventory_before, baseline_before)

    def test_required_baseline_increase_writes_nothing(self) -> None:
        self._write_fake_qmllint((20,))
        self.baseline_path.write_text(
            self.baseline_path.read_text(encoding="utf-8").replace(
                "QMLLINT_BASELINE_UNQUALIFIED=2", "QMLLINT_BASELINE_UNQUALIFIED=0"
            ),
            encoding="utf-8",
        )
        inventory_before = self.inventory_path.read_text(encoding="utf-8")
        baseline_before = self.baseline_path.read_text(encoding="utf-8")

        with self.assertRaisesRegex(CYCLE.CycleError, "baseline increase"):
            CYCLE.close_cycle(self._config())

        self._assert_unchanged(inventory_before, baseline_before)

    def test_gate_failure_writes_nothing(self) -> None:
        self._write_fake_qmllint((20,))
        self.gate_path.write_text("#!/bin/sh\nexit 9\n", encoding="utf-8")
        self.gate_path.chmod(0o755)
        inventory_before = self.inventory_path.read_text(encoding="utf-8")
        baseline_before = self.baseline_path.read_text(encoding="utf-8")

        with self.assertRaisesRegex(CYCLE.CycleError, "profile gate failed"):
            CYCLE.close_cycle(self._config())

        self._assert_unchanged(inventory_before, baseline_before)

    def test_second_state_write_failure_rolls_back_both_files(self) -> None:
        self._write_fake_qmllint((20,))
        inventory_before = self.inventory_path.read_text(encoding="utf-8")
        baseline_before = self.baseline_path.read_text(encoding="utf-8")
        original_atomic_write = CYCLE.atomic_write
        failed_once = False

        def fail_inventory_once(path: Path, content: str) -> None:
            nonlocal failed_once
            if path == self.inventory_path and not failed_once:
                failed_once = True
                raise OSError("simulated inventory write failure")
            original_atomic_write(path, content)

        with mock.patch.object(CYCLE, "atomic_write", side_effect=fail_inventory_once):
            with self.assertRaisesRegex(CYCLE.CycleError, "were restored"):
                CYCLE.close_cycle(self._config())

        self.assertEqual(inventory_before, self.inventory_path.read_text(encoding="utf-8"))
        self.assertEqual(baseline_before, self.baseline_path.read_text(encoding="utf-8"))
        self.assertTrue(self.backup_root.is_dir())


if __name__ == "__main__":
    unittest.main()
