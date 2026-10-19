#!/usr/bin/env python3
"""Run the folder sort QML test against an owned temporary fixture."""

from __future__ import annotations

import os
from pathlib import Path
import subprocess
import sys
import tempfile

FILES = (
    ("alpha.txt", 30, 1577836800),
    ("Bravo.txt", 10, 1609459200),
    ("charlie.txt", 20, 1640995200),
    ("doc.png", 50, 1672531200),
    ("echo.pdf", 40, 1704067200),
)


def main(arguments: list[str]) -> int:
    if len(arguments) != 3:
        print("usage: run_isolated_folder_sort_test.py <qmltestrunner> <build-bin>",
            file=sys.stderr)
        return 2

    runner = Path(arguments[1]).resolve()
    build_bin = Path(arguments[2]).resolve()
    project = Path(__file__).resolve().parent.parent
    source_test = project / "tests/folder_sort_test.qml"

    with tempfile.TemporaryDirectory(prefix="punchi-folder-sort-") as directory:
        root = Path(directory)
        fixture = root / "fixture"
        fixture.mkdir()
        for name, size, timestamp in FILES:
            path = fixture / name
            path.write_bytes(b"\0" * size)
            os.utime(path, (timestamp, timestamp))

        generated = root / "folder_sort_test.qml"
        source = source_test.read_text(encoding="utf-8")
        source = source.replace("/tmp/punchi-folder-sort-fixture", str(fixture))
        generated.write_text(source, encoding="utf-8")

        environment = os.environ.copy()
        environment["LANGUAGE"] = "en"
        environment["QT_QPA_PLATFORM"] = "offscreen"
        environment["QT_QUICK_CONTROLS_STYLE"] = "org.kde.desktop"
        environment["LD_LIBRARY_PATH"] = str(build_bin) + os.pathsep + environment.get(
            "LD_LIBRARY_PATH", "")
        completed = subprocess.run(
            [str(runner), "-import", str(build_bin), "-input", str(generated)],
            env=environment,
            check=False,
        )
        return completed.returncode


if __name__ == "__main__":
    sys.exit(main(sys.argv))
