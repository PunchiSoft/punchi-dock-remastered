#!/usr/bin/env python3
"""Tests for exact qmllint translation-candidate filtering."""

from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_DIR = PROJECT_ROOT / "scripts"
sys.path.insert(0, str(SCRIPTS_DIR))
SCRIPT_PATH = SCRIPTS_DIR / "qmllint_i18n_candidates.py"
SPEC = importlib.util.spec_from_file_location("qmllint_i18n_candidates", SCRIPT_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"Cannot load {SCRIPT_PATH}")
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class QmllintI18nCandidatesTest(unittest.TestCase):
    """Verify exact column matching and privacy-safe output."""

    def test_column_distinguishes_model_role_from_i18n_on_same_line(self) -> None:
        source = 'Accessible.name: modelData.name || i18n("Application")'

        self.assertIsNone(MODULE.translation_function_at_column(source, 18))
        self.assertEqual(
            "i18n",
            MODULE.translation_function_at_column(source, source.index("i18n") + 1),
        )

    def test_all_supported_translation_functions_are_detected(self) -> None:
        for function in ("i18n", "i18nc", "i18np"):
            source = f'text: {function}("Value")'
            self.assertEqual(
                function,
                MODULE.translation_function_at_column(
                    source, source.index(function) + 1
                ),
            )

    def test_generated_queue_uses_reconciled_id_and_relative_path(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            project_root = root / "project"
            qml_path = project_root / "contents/ui/Test.qml"
            qml_path.parent.mkdir(parents=True)
            source = 'text: modelData.name || i18n("Fallback")'
            qml_path.write_text(source + "\n", encoding="utf-8")
            log_path = root / "qmllint.log"
            i18n_column = source.index("i18n") + 1
            log_path.write_text(
                f"Warning: {qml_path}:1:{i18n_column}: Unqualified access [unqualified]\n"
                f"{source}\n"
                f"Warning: {qml_path}:1:7: Unqualified access [unqualified]\n"
                f"{source}\n",
                encoding="utf-8",
            )
            inventory_path = root / "inventory.md"
            diagnostics, _ = MODULE.inventory.parse_log(log_path, project_root)
            inventory_path.write_text(
                MODULE.inventory.render_inventory(
                    diagnostics, 0, {}, "test", "6.11.1", "2026-08-10"
                ),
                encoding="utf-8",
            )

            candidates = MODULE.collect_candidates(
                log_path, inventory_path, project_root
            )
            rendered = MODULE.render_markdown(candidates, "test", "6.11.1")

            self.assertEqual(1, len(candidates))
            self.assertEqual(diagnostics[0].identifier, candidates[0].identifier)
            self.assertIn("`contents/ui/Test.qml`", rendered)
            self.assertNotIn(str(project_root), rendered)


if __name__ == "__main__":
    unittest.main()
