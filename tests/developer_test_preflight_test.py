#!/usr/bin/env python3
"""Exercise the developer gate with controlled D-Bus/QML failures and cleanup."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import unittest


PROJECT = Path(__file__).resolve().parents[1]


class DeveloperTestPreflightTest(unittest.TestCase):
    """Use disposable executables without starting services or installing packages."""

    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="punchi-preflight-regression-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        for name in ("scripts-user/lib/package-plasmoid.sh",
                     "scripts-user/lib/build-concurrency.sh",
                     "scripts-dev/test-preflight.py",
                     "tests/run_isolated_plasmoid_full_load_test.py",
                     "tests/run_isolated_qml_tooltip_test.py",
                     "tests/dbus-session-isolated.conf"):
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(PROJECT / name, target)
        (self.root / "contents/ui").mkdir(parents=True)
        (self.root / "contents/ui/Fixture.qml").write_text("import QtQuick\nItem {}\n")
        (self.root / "build").mkdir()
        (self.root / "baseline.env").write_text("QMLLINT_BASELINE_TOTAL=0\n")
        (self.root / "scripts-dev/test-integrity-guard.py").write_text("print('Integrity fixture PASS')\n")
        self.bin = self.root / "fake-bin"
        self.bin.mkdir()
        self.environment = os.environ.copy()
        self.environment.update({
            "PATH": str(self.bin) + os.pathsep + os.environ["PATH"],
            "PYTHONDONTWRITEBYTECODE": "1",
            "PUNCHI_PREFLIGHT_EVENTS": str(self.root / "events.jsonl"),
            "PUNCHI_PACKAGE_CORE": "1",
            "PUNCHI_PACKAGE_VALIDATION_MODE": "full",
            "BUILD_DIR": str(self.root / "build"),
            "PACKAGE_OUTPUT_FILE": str(self.root / "unused.plasmoid"),
            "QMLLINT_BASELINE_FILE": str(self.root / "baseline.env"),
            "QMLLINT_BIN": str(self.bin / "qmllint"),
            "PUNCHI_BUILD_JOBS": "2",
        })
        self.write_executable("cmake", "record('cmake', sys.argv[1:])\n")
        self.write_executable("qmllint", "if '--version' in sys.argv: print('qmllint 6.11.2')\n")
        self.write_executable("ctest", """
if '--show-only=json-v1' in sys.argv:
    names = [] if os.environ.get('MISSING_PROBE') else [
        {'name': 'punchimenu_mapped_surface_geometry_test', 'command': [sys.executable]},
        {'name': 'plasmoid_full_load_test', 'command': [sys.executable]}]
    print(json.dumps({'tests': names}))
elif '-R' in sys.argv:
    record('qml', sys.argv[1:])
    if os.environ.get('SLOW_PROBE'): time.sleep(30)
    sys.exit(int(os.environ.get('QML_RESULT', '0')))
else:
    record('full-suite', sys.argv[1:])
    sys.exit(19)
""")
        self.write_executable("dbus-run-session", """
record('session', [os.environ.get('PUNCHI_TEST_ENVIRONMENT_ROOT')])
environment = os.environ.copy()
environment['DBUS_SESSION_BUS_ADDRESS'] = 'unix:path=fixture'
sys.exit(subprocess.call(sys.argv[sys.argv.index('--') + 1:], env=environment))
""")
        self.write_executable("dbus-send", """
record('bus', sys.argv[1:])
assert os.environ.get('DBUS_SESSION_BUS_ADDRESS')
sys.exit(int(os.environ.get('BUS_RESULT', '0')))
""")

    def write_executable(self, name: str, body: str) -> None:
        """Make a local stand-in that records only test-owned paths and arguments."""
        file = self.bin / name
        file.write_text(f"#!{sys.executable}\n" + """
import json, os, subprocess, sys, time
def record(event, values):
    with open(os.environ['PUNCHI_PREFLIGHT_EVENTS'], 'a') as output:
        output.write(json.dumps({'event': event, 'values': values}) + '\\n')
""" + body)
        file.chmod(0o700)

    def events(self) -> list[dict]:
        """Read the exact fixture event stream, or an empty stream before launch."""
        file = self.root / "events.jsonl"
        return [json.loads(line) for line in file.read_text().splitlines()] if file.exists() else []

    def run_gate(self, **overrides: str) -> subprocess.CompletedProcess:
        """Run the real packaging gate only until the controlled test result."""
        env = self.environment | overrides
        result = subprocess.run([
            "bash", str(self.root / "scripts-user/lib/package-plasmoid.sh"),
        ], env=env, capture_output=True, text=True, timeout=20)
        self.assert_clean()
        # Every tested path must stop before staging the package.
        self.assertFalse(any('--target' in e['values'] for e in self.events() if e['event'] == 'cmake'))
        self.assertFalse((self.root / "unused.plasmoid").exists())
        return result

    def assert_clean(self) -> None:
        """Verify the parent wrapper removed each root it actually allocated."""
        for event in self.events():
            if event['event'] == 'session':
                root = event['values'][0]
                self.assertTrue(root)
                self.assertFalse(Path(root).exists(), root)

    def test_bus_failure_stops_before_qml_and_full_suite(self) -> None:
        result = self.run_gate(BUS_RESULT="7")
        self.assertEqual(result.returncode, 7, result.stdout + result.stderr)
        self.assertFalse(any(e['event'] in ('qml', 'full-suite') for e in self.events()))

    def test_qml_failure_stops_before_full_suite(self) -> None:
        result = self.run_gate(QML_RESULT="8")
        self.assertEqual(result.returncode, 8, result.stdout + result.stderr)
        self.assertTrue(any(e['event'] == 'qml' for e in self.events()))
        self.assertFalse(any(e['event'] == 'full-suite' for e in self.events()))

    def test_success_runs_unfiltered_full_gate(self) -> None:
        result = self.run_gate()
        self.assertEqual(result.returncode, 19, result.stdout + result.stderr)
        events = self.events()
        self.assertLess(next(i for i,e in enumerate(events) if e['event'] == 'bus'),
                        next(i for i,e in enumerate(events) if e['event'] == 'qml'))
        full = next(e for e in events if e['event'] == 'full-suite')
        self.assertIn('--output-on-failure', full['values'])
        self.assertNotIn('-R', full['values'])
        self.assertNotIn('-E', full['values'])

    def test_missing_probe_fails_without_session(self) -> None:
        result = self.run_gate(MISSING_PROBE="1")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertFalse(any(e['event'] == 'session' for e in self.events()))

    def test_deadline_stops_probe_and_cleans_root(self) -> None:
        result = subprocess.run([
            sys.executable, str(self.root / "scripts-dev/test-preflight.py"),
            '--build-dir', str(self.root / 'build'), '--timeout', '1',
        ], env=self.environment | {'SLOW_PROBE': '1'},
            capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 124, result.stdout + result.stderr)
        self.assertTrue(any(e['event'] == 'qml' for e in self.events()))
        self.assert_clean()

    def test_invalid_deadline_is_rejected(self) -> None:
        for value in ('0', '-1', 'nan', 'inf'):
            result = subprocess.run([
                sys.executable, str(self.root / "scripts-dev/test-preflight.py"),
                '--build-dir', str(self.root / 'build'), '--timeout', value,
            ], env=self.environment, capture_output=True, text=True, timeout=5)
            self.assertEqual(result.returncode, 2, result.stdout + result.stderr)

    def test_termination_cleans_the_running_probe(self) -> None:
        process = subprocess.Popen([
            sys.executable, str(self.root / "scripts-dev/test-preflight.py"),
            '--build-dir', str(self.root / 'build'),
        ], env=self.environment | {'SLOW_PROBE': '1'},
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline:
                if any(e['event'] == 'qml' for e in self.events()):
                    break
                time.sleep(0.02)
            self.assertTrue(any(e['event'] == 'qml' for e in self.events()))
            process.terminate()
            output, error = process.communicate(timeout=5)
            self.assertEqual(process.returncode, 143, output + error)
        finally:
            if process.poll() is None:
                process.terminate()
                process.communicate(timeout=5)
        self.assert_clean()


if __name__ == '__main__':
    unittest.main()
