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


def expose_host_wayland_socket(environment_root, environment):
    """Make the host Wayland socket reachable from the isolated runtime.

    Plasma 6.8's Theme creates a Wayland client extension even when the test
    runs with the offscreen QPA. The fixture rewrites XDG_RUNTIME_DIR, so the
    socket must be linked into that directory; otherwise the extension reports
    a connection failure that the warning gate correctly treats as an error.
    The link lives inside the temporary tree and is removed with it.
    """

    wayland_display = environment.get("WAYLAND_DISPLAY", "")
    host_runtime = environment.get("XDG_RUNTIME_DIR", "")
    if not wayland_display or not host_runtime:
        return
    host_socket = Path(wayland_display)
    if not host_socket.is_absolute():
        host_socket = Path(host_runtime) / wayland_display
    if not host_socket.exists():
        return
    runtime = environment_root / "wayland"
    runtime.mkdir(parents=True, exist_ok=True)
    runtime.chmod(0o700)
    link = runtime / host_socket.name
    if link.exists() or link.is_symlink():
        return
    link.symlink_to(host_socket)
    # An absolute WAYLAND_DISPLAY survives the fixture rewriting
    # XDG_RUNTIME_DIR, and avoids creating the runtime directory before the
    # child wrapper owns it.
    environment["WAYLAND_DISPLAY"] = str(link)


def main():
    if len(sys.argv) < 2:
        print("Error: an isolated test command is required.", file=sys.stderr)
        return 2

    temporary = tempfile.TemporaryDirectory(prefix="punchi-full-load-test-")
    environment_root = Path(temporary.name)
    environment = os.environ.copy()
    environment["PUNCHI_TEST_ENVIRONMENT_ROOT"] = str(environment_root)
    expose_host_wayland_socket(environment_root, environment)
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
