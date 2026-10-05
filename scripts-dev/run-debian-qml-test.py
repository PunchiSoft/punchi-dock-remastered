#!/usr/bin/env python3
"""Run unchanged QML tests against a disposable tree with the local native build."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", required=True, type=Path)
    parser.add_argument("--module-root", required=True, type=Path)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    arguments = parser.parse_args()
    command = arguments.command
    if command and command[0] == "--":
        command = command[1:]
    project = arguments.project_root.resolve()
    module = arguments.module_root.resolve()
    if not command or "-input" not in command:
        parser.error("A QML runner command with -input is required")
    input_index = command.index("-input") + 1
    original_input = Path(command[input_index]).resolve()
    relative_input = original_input.relative_to(project)
    if not original_input.is_file() or relative_input.parts[0] != "tests":
        parser.error("The input must be an existing test inside the project")
    for filename in ("qmldir", "libpunchidockintegration.so", "libpunchidockintegrationplugin.so"):
        if not (module / filename).is_file():
            parser.error(f"Missing local native build file: {module / filename}")
    with tempfile.TemporaryDirectory(prefix="punchi-debian-qml-test-") as directory:
        root = Path(directory)
        shutil.copytree(project / "tests", root / "tests",
                        ignore=shutil.ignore_patterns("__pycache__"))
        shutil.copytree(project / "contents", root / "contents",
                        ignore=shutil.ignore_patterns("*.so", "*.so.*"))
        shutil.copytree(module, root / "contents/ui/org/punchi/dock", dirs_exist_ok=True)
        command[input_index] = str(root / relative_input)
        environment = os.environ.copy()
        # Preserve directories owned by an existing isolation/fixture wrapper.
        for variable, name in (("XDG_DATA_HOME", "data"), ("XDG_CONFIG_HOME", "config"),
                               ("XDG_CACHE_HOME", "cache"), ("XDG_RUNTIME_DIR", "runtime")):
            if "PUNCHI_TEST_ENVIRONMENT_ROOT" not in environment:
                location = root / name
                location.mkdir(mode=0o700)
                environment[variable] = str(location)
        child = subprocess.Popen(command, env=environment, start_new_session=True)
        previous_handlers = {}

        def forward_signal(number: int, _frame: object) -> None:
            if child.poll() is None:
                os.killpg(child.pid, number)

        for number in (signal.SIGINT, signal.SIGTERM):
            previous_handlers[number] = signal.signal(number, forward_signal)
        try:
            status = child.wait()
        finally:
            if child.poll() is None:
                os.killpg(child.pid, signal.SIGTERM)
                try:
                    child.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(child.pid, signal.SIGKILL)
                    child.wait()
            for number, handler in previous_handlers.items():
                signal.signal(number, handler)
        return status if status >= 0 else 128 - status


if __name__ == "__main__":
    raise SystemExit(main())
