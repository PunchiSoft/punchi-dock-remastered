#!/usr/bin/env python3
"""Verify isolated test cleanup after success, failure, and termination."""

import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time


ROOT = Path(__file__).resolve().parents[1]
WRAPPER = ROOT / "tests" / "run_isolated_plasmoid_full_load_test.py"
CHILD_SCRIPT = """
import os
from pathlib import Path
import sys
import time

root = Path(os.environ["PUNCHI_TEST_ENVIRONMENT_ROOT"])
cache = root / "cache"
cache.mkdir()
(cache / "ksvg-elements").write_text("fixture cache")
Path(os.environ["PUNCHI_TEST_ROOT_RECORD"]).write_text(str(root))
if os.environ.get("PUNCHI_TEST_WAIT") == "1":
    time.sleep(30)
sys.exit(int(os.environ.get("PUNCHI_TEST_EXIT", "0")))
"""


def recorded_root(record):
    """Read the exact temporary root published by the controlled child."""
    assert record.exists(), "The fixture did not publish its temporary root"
    return Path(record.read_text())


def run_case(outer, exit_status):
    """Run a normal or failing child and verify cleanup preserves its status."""
    record = outer / f"root-{exit_status}"
    environment = os.environ.copy()
    environment.update({
        "TMPDIR": str(outer),
        "PUNCHI_TEST_ROOT_RECORD": str(record),
        "PUNCHI_TEST_EXIT": str(exit_status),
    })
    result = subprocess.run(
        [sys.executable, str(WRAPPER), sys.executable, "-c", CHILD_SCRIPT],
        env=environment,
        timeout=5,
        check=False,
    )
    assert result.returncode == exit_status, result.returncode
    assert not recorded_root(record).exists(), "Temporary root survived child exit"


def run_signal_case(outer):
    """Terminate the wrapper and verify it cleans its controlled process group."""
    record = outer / "root-signal"
    environment = os.environ.copy()
    environment.update({
        "TMPDIR": str(outer),
        "PUNCHI_TEST_ROOT_RECORD": str(record),
        "PUNCHI_TEST_WAIT": "1",
    })
    process = subprocess.Popen(
        [sys.executable, str(WRAPPER), sys.executable, "-c", CHILD_SCRIPT],
        env=environment,
    )
    deadline = time.monotonic() + 3
    while not record.exists() and time.monotonic() < deadline:
        time.sleep(0.02)
    root = recorded_root(record)
    process.send_signal(signal.SIGTERM)
    assert process.wait(timeout=5) == 128 + signal.SIGTERM
    assert not root.exists(), "Temporary root survived wrapper termination"


def main():
    with tempfile.TemporaryDirectory(prefix="punchi-cleanup-contract-") as directory:
        outer = Path(directory)
        run_case(outer, 0)
        run_case(outer, 7)
        run_signal_case(outer)
    print("Test environment cleanup contract passed.")


if __name__ == "__main__":
    main()
