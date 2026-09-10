#!/usr/bin/env python3
"""Exercise progress ownership and CTest results without touching Plasma."""
import os
from pathlib import Path
import signal
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]


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
