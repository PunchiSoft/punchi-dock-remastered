#!/usr/bin/env python3
"""Check an isolated session bus and a registered QML test before the full suite."""

import argparse
import json
import math
import os
from pathlib import Path
import signal
import subprocess
import sys


SMOKE_TEST = "punchimenu_mapped_surface_geometry_test"


class InterruptedProbe(Exception):
    """Carry a termination signal to the parent isolation wrapper."""

    def __init__(self, signum: int) -> None:
        super().__init__(signum)
        self.signum = signum


def positive_seconds(value: str) -> float:
    """Reject invalid or unbounded deadlines."""
    seconds = float(value)
    if not math.isfinite(seconds) or seconds <= 0:
        raise argparse.ArgumentTypeError("the deadline must be finite and positive")
    return seconds


def terminate_wrapper(process: subprocess.Popen) -> None:
    """Let the established wrapper stop its process group and clean its root."""
    if process.poll() is None:
        process.send_signal(signal.SIGTERM)
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired as error:
        # Never remove a temporary root while its owner or children still run.
        raise RuntimeError("the isolation wrapper did not finish cleanup") from error


def session_probe(build_dir: Path) -> int:
    """Verify D-Bus communication, then run the existing QML contract."""
    if not os.environ.get("PUNCHI_TEST_ENVIRONMENT_ROOT"):
        raise RuntimeError("the parent isolation wrapper is required")
    result = subprocess.run([
        "dbus-send", "--session", "--print-reply",
        "--dest=org.freedesktop.DBus", "/org/freedesktop/DBus",
        "org.freedesktop.DBus.GetId",
    ], check=False)
    if result.returncode:
        return result.returncode
    return subprocess.run([
        "ctest", "--test-dir", str(build_dir), "--parallel", "1",
        "-R", f"^{SMOKE_TEST}$", "--no-tests=error", "--output-on-failure",
    ], check=False).returncode


def preflight(project_root: Path, build_dir: Path, timeout: float) -> int:
    """Bound the probe while preserving parent-owned cleanup on every exit."""
    process = None

    def interrupt(signum: int, _frame: object) -> None:
        raise InterruptedProbe(signum)

    previous = {s: signal.signal(s, interrupt) for s in (signal.SIGINT, signal.SIGTERM)}
    try:
        # CTest otherwise reports success when a requested test is absent.
        metadata = subprocess.run([
            "ctest", "--test-dir", str(build_dir), "--show-only=json-v1",
        ], check=True, capture_output=True, text=True, timeout=timeout)
        tests = json.loads(metadata.stdout).get("tests", [])
        if not any(t.get("name") == SMOKE_TEST and t.get("command") for t in tests):
            raise RuntimeError(f"the built QML probe is missing: {SMOKE_TEST}")
        command = [
            sys.executable, str(project_root / "tests/run_isolated_plasmoid_full_load_test.py"),
            sys.executable, str(project_root / "tests/run_isolated_qml_tooltip_test.py"),
            "dbus-run-session",
            "--config-file=" + str(project_root / "tests/dbus-session-isolated.conf"),
            "--", sys.executable, str(Path(__file__).resolve()),
            "--build-dir", str(build_dir), "--session-probe",
        ]
        process = subprocess.Popen(command)
        try:
            return process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            terminate_wrapper(process)
            print("Error: D-Bus/QML preflight timed out.", file=sys.stderr)
            return 124
    except InterruptedProbe as interruption:
        if process is not None:
            terminate_wrapper(process)
        return 128 + interruption.signum
    finally:
        for signum, handler in previous.items():
            signal.signal(signum, handler)


def main() -> int:
    """Dispatch the public bounded probe or its isolated child."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-dir", type=Path, required=True,
                        help="Configured and freshly built CMake test directory")
    parser.add_argument("--timeout", type=positive_seconds, default=15.0,
                        help="Deadline in seconds for each preflight stage (default: 15)")
    parser.add_argument("--session-probe", action="store_true", help=argparse.SUPPRESS)
    args = parser.parse_args()
    try:
        if args.session_probe:
            return session_probe(args.build_dir.resolve())
        root = Path(__file__).resolve().parents[1]
        print("==> D-Bus/QML preflight", flush=True)
        return preflight(root, args.build_dir.resolve(), args.timeout)
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        print(f"Error: preflight failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
