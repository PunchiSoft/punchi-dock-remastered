#!/usr/bin/env python3
"""Exercise progress ownership and CTest results without touching Plasma."""
import os
from pathlib import Path
import fcntl
import pty
import select
import signal
import struct
import subprocess
import tempfile
import termios
import time

ROOT = Path(__file__).resolve().parents[1]


def run_in_terminal(command, environment, expected_status=0):
    """Run a command in an 80-column pseudo-terminal and return its display output."""
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 80, 0, 0))
    process = subprocess.Popen(command, env=environment, stdin=subprocess.DEVNULL,
                               stdout=slave, stderr=slave, close_fds=True)
    os.close(slave)
    chunks = []
    deadline = time.monotonic() + 5
    try:
        while time.monotonic() < deadline:
            readable, _, _ = select.select([master], [], [], 0.1)
            if readable:
                try:
                    chunks.append(os.read(master, 4096))
                except OSError:
                    break
            if process.poll() is not None and not readable:
                break
        process.wait(timeout=1)
    finally:
        os.close(master)
        if process.poll() is None:
            process.kill()
            process.wait(timeout=1)
    output = b"".join(chunks).decode(errors="replace")
    assert process.returncode == expected_status, output
    return output


def main():
    with tempfile.TemporaryDirectory(prefix="punchi-progress-test-") as directory:
        temporary = Path(directory)
        worker = temporary / "worker.sh"
        environment = dict(os.environ, PROJECT_ROOT=str(ROOT), PUNCHI_LANG="en",
                           PUNCHI_LOG_DIR=str(temporary / "logs"),
                           CHILD_FILE=str(temporary / "child"))
        # Do not inherit a surrounding developer setup's presentation session.
        environment.pop("PUNCHI_PROGRESS_DIR", None)
        command = ["bash", "-c",
                   'source "$PROJECT_ROOT/scripts-dev/lib/setup-logging.sh"; '
                   'punchi_run_setup_with_log test bash "$1"', "test", str(worker)]
        worker.write_text('source "$PROJECT_ROOT/scripts-dev/lib/setup-progress.sh"\n'
                          'punchi_progress_update 60 tests\n'
                          'printf "1/3 Test #1: passed ... Passed 0.1 sec\\n"\n'
                          'printf "2/3 Test #2: skipped ... ***Skipped 0.1 sec\\n"\n'
                          'printf "3/3 Test #3: disabled ... ***Not Run (Disabled) 0.0 sec\\n"\n')
        result = subprocess.run(command, env=environment, capture_output=True,
                                text=True, timeout=5)
        assert result.returncode == 0, result.stderr
        assert "3/3 completed; 0 failed; 2 skipped" in result.stdout, result.stdout
        assert "\x1b" not in result.stdout and "\r" not in result.stdout

        environment["LC_ALL"] = "C.UTF-8"
        environment["TERM"] = "xterm-256color"
        terminal_output = run_in_terminal(command, environment)
        expected_bar = "[" + "█" * 20 + " " * 14 + "]"
        assert f"{expected_bar}  60% Running tests... 3/3" in terminal_output, terminal_output
        assert "[" + "█" * 34 + "] 100% Operation completed successfully" in terminal_output, terminal_output

        static_command = [
            "bash", "-c",
            'source "$PROJECT_ROOT/scripts-dev/lib/setup-progress.sh"; '
            'PUNCHI_PROGRESS_PRESENTATION=static punchi_progress_update 50 build',
        ]
        static_output = run_in_terminal(static_command, environment)
        expected_static_bar = "[" + "█" * 17 + " " * 17 + "]"
        assert f"{expected_static_bar}  50% Building native integration..." in static_output, static_output

        environment["TMPDIR"] = str(temporary)
        public_command = [
            "bash", "-c",
            'source "$PROJECT_ROOT/scripts-user/setup.sh"; '
            'run_command_with_transient_progress bash "$1"',
            "test", str(worker),
        ]
        worker.write_text('source "$PROJECT_ROOT/scripts-dev/lib/setup-progress.sh"\n'
                          'punchi_progress_update 40 build\n'
                          'printf "noisy compiler output\\n"\n'
                          'sleep 0.15\n'
                          'punchi_progress_update 70 stage\n'
                          'printf "noisy staging output\\n"\n'
                          'sleep 0.15\n'
                          'punchi_progress_update 100 complete\n')
        public_output = run_in_terminal(public_command, environment)
        assert "noisy compiler output" not in public_output, public_output
        assert "noisy staging output" not in public_output, public_output
        assert "\r\x1b[2K" in public_output, public_output
        assert "100% Operation completed successfully" in public_output, public_output
        assert public_output.count("\n") == 1, repr(public_output)
        assert not list(temporary.glob("punchi-user-progress.*"))
        assert not list(temporary.glob("punchi-progress.*"))

        plain_result = subprocess.run(public_command, env=environment,
                                      capture_output=True, text=True, timeout=5)
        assert plain_result.returncode == 0, plain_result.stderr
        assert "noisy compiler output" in plain_result.stderr, plain_result.stderr
        assert "noisy staging output" in plain_result.stderr, plain_result.stderr
        assert "\x1b" not in plain_result.stderr and "\r" not in plain_result.stderr
        assert not list(temporary.glob("punchi-user-progress.*"))
        assert not list(temporary.glob("punchi-progress.*"))

        worker.write_text('source "$PROJECT_ROOT/scripts-dev/lib/setup-progress.sh"\n'
                          'punchi_progress_update 40 build\n'
                          'printf "public build diagnostic\\n"\n'
                          'exit 7\n')
        failure_output = run_in_terminal(public_command, environment, expected_status=7)
        assert "public build diagnostic" in failure_output, failure_output
        assert "Operation failed" in failure_output, failure_output
        assert not list(temporary.glob("punchi-user-progress.*"))
        assert not list(temporary.glob("punchi-progress.*"))

        for group in (False, True):
            for interrupt in (signal.SIGINT, signal.SIGTERM):
                child_file = temporary / "child"
                child_file.unlink(missing_ok=True)
                worker.write_text('sleep 30 &\nprintf "%s" "$!" > "$CHILD_FILE"\nwait\n')
                process = subprocess.Popen(command, env=environment, stdout=subprocess.PIPE,
                                           stderr=subprocess.PIPE, start_new_session=True,
                                           text=True)
                try:
                    deadline = time.monotonic() + 3
                    while not child_file.exists() and time.monotonic() < deadline:
                        time.sleep(0.02)
                    assert child_file.exists(), "Worker did not start"
                    child = int(child_file.read_text())
                    (os.killpg if group else os.kill)(process.pid, interrupt)
                    output, errors = process.communicate(timeout=5)
                    assert process.returncode == 128 + interrupt, (output, errors)
                    assert "[100%]" not in output, output
                    stat = Path(f"/proc/{child}/stat")
                    assert not stat.exists() or stat.read_text().split()[2] == "Z", "Child is still running"
                    log = (temporary / "logs/setup-test-latest.log").read_text()
                    assert f"Exit status: {128 + interrupt}" in log
                finally:
                    # Only this fixture's private process group can be signalled.
                    try:
                        os.killpg(process.pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
                    process.communicate(timeout=5)
    print("Setup progress regression tests passed.")


if __name__ == "__main__":
    main()
