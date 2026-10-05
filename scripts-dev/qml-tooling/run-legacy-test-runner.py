#!/usr/bin/env python3
"""Own bootstrap configuration until the adapted QML runner fully exits."""

import os
from contextlib import nullcontext
from pathlib import Path
import signal
import subprocess
import sys
import tempfile


def main() -> int:
    if len(sys.argv) < 3:
        print("Expected the native runner and its canonical program name", file=sys.stderr)
        return 2
    root = os.environ.get("PUNCHI_TEST_ENVIRONMENT_ROOT")
    configuration = Path(os.environ.get("XDG_CONFIG_HOME", "/"))
    fixture_owned = (root and configuration.is_dir()
                     and configuration.resolve().is_relative_to(Path(root).resolve()))
    # A fixture may have written kdeglobals (including reduced motion).
    # Its existing parent owns cleanup; never discard that configuration.
    context = (nullcontext(str(configuration)) if fixture_owned
               else tempfile.TemporaryDirectory(prefix="punchi-legacy-config-"))
    with context as directory:
        environment = os.environ.copy()
        environment["XDG_CONFIG_HOME"] = directory
        environment["PUNCHI_LEGACY_CONFIG_ROOT"] = directory
        process = subprocess.Popen(sys.argv[2:], executable=sys.argv[1],
                                   env=environment, start_new_session=True)

        def forward(number: int, _frame: object) -> None:
            if process.poll() is None:
                os.killpg(process.pid, number)

        previous = {number: signal.signal(number, forward)
                    for number in (signal.SIGTERM, signal.SIGINT)}
        try:
            status = process.wait()
        finally:
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGTERM)
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait()
            for number, handler in previous.items():
                signal.signal(number, handler)
        return status if status >= 0 else 128 - status


if __name__ == "__main__":
    raise SystemExit(main())
