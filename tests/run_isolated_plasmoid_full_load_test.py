#!/usr/bin/env python3
"""Run the full-load fixture and remove its environment after every exit path."""

import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile


class ForwardedSignal(Exception):
    """Record a signal that must be forwarded to the isolated process group."""

    def __init__(self, signum):
        super().__init__(signum)
        self.signum = signum


def stop_process_group(process):
    """Stop only the process group created by this wrapper."""
    if process is None or process.poll() is not None:
        return
    try:
        os.killpg(process.pid, signal.SIGTERM)
        process.wait(timeout=2)
    except ProcessLookupError:
        return
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.wait(timeout=2)


def main():
    if len(sys.argv) < 2:
        print("Error: an isolated test command is required.", file=sys.stderr)
        return 2

    temporary = tempfile.TemporaryDirectory(prefix="punchi-full-load-test-")
    environment_root = Path(temporary.name)
    environment = os.environ.copy()
    environment["PUNCHI_TEST_ENVIRONMENT_ROOT"] = str(environment_root)
    process = None
    result = 1
    cleanup_error = None

    def forward_signal(signum, _frame):
        if process is not None and process.poll() is None:
            try:
                os.killpg(process.pid, signum)
            except ProcessLookupError:
                pass
        raise ForwardedSignal(signum)

    previous_handlers = {
        signum: signal.signal(signum, forward_signal)
        for signum in (signal.SIGINT, signal.SIGTERM)
    }
    try:
        process = subprocess.Popen(
            sys.argv[1:],
            env=environment,
            start_new_session=True,
        )
        result = process.wait()
    except ForwardedSignal as forwarded:
        stop_process_group(process)
        result = 128 + forwarded.signum
    finally:
        stop_process_group(process)
        for signum, handler in previous_handlers.items():
            signal.signal(signum, handler)
        try:
            temporary.cleanup()
        except OSError as error:
            cleanup_error = error

    if cleanup_error is not None:
        print(f"Error: could not clean isolated test environment: {cleanup_error}", file=sys.stderr)
        return 1
    if environment_root.exists():
        print(f"Error: isolated test environment survived cleanup: {environment_root}", file=sys.stderr)
        return 1
    return result


if __name__ == "__main__":
    sys.exit(main())
