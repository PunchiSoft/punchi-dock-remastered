#!/usr/bin/env python3
"""Measure Punchi Dock memory inside an isolated Plasma session.

The plasmoid has no process of its own: it runs inside ``plasmashell``. This
harness therefore launches a nested compositor plus a private ``plasmashell``
(D-Bus, config, cache, data and runtime directories are all temporary), adds
dock instances through Plasma scripting and reports the private anonymous
memory (``Pss_Anon``) each instance costs.

Nothing here touches the user's session and nothing uses the network.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import signal
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass, field
from pathlib import Path

PLUGIN_ID = "org.kde.plasma.punchi-dock-remastered"
PROJECT_ROOT = Path(__file__).resolve().parent.parent
BASELINE_FILE = Path(__file__).resolve().parent / "memory-baseline.env"
REQUIRED_TOOLS = ("dbus-daemon", "gdbus", "kwin_wayland", "plasmashell")


class MeasurementError(RuntimeError):
    """Raised when the isolated session cannot produce a valid measurement."""


class Terminated(Exception):
    """Raised from a signal handler so cleanup always runs."""

    def __init__(self, signum: int) -> None:
        super().__init__(signum)
        self.signum = signum


@dataclass
class Metrics:
    baseline_mb: float = 0.0
    first_instance_mb: float = 0.0
    second_instance_mb: float = 0.0
    retention_mb: float = 0.0
    samples: dict = field(default_factory=dict)

    def as_dict(self) -> dict:
        return {
            "baseline_mb": round(self.baseline_mb, 1),
            "first_instance_mb": round(self.first_instance_mb, 1),
            "second_instance_mb": round(self.second_instance_mb, 1),
            "retention_mb": round(self.retention_mb, 1),
            "samples": self.samples,
        }


def log(message: str) -> None:
    print(message, flush=True)


def require_tools() -> None:
    missing = [tool for tool in REQUIRED_TOOLS if shutil.which(tool) is None]
    if missing:
        raise MeasurementError(
            "Missing required tools: %s. Install the Plasma 6 tooling before measuring."
            % ", ".join(missing)
        )
    if not os.environ.get("WAYLAND_DISPLAY"):
        raise MeasurementError(
            "No Wayland session detected. The isolated compositor needs a Wayland host; "
            "run the measurement from a Plasma Wayland session."
        )


def process_alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def read_anon_mb(pid: int) -> float | None:
    try:
        with open(f"/proc/{pid}/smaps_rollup", encoding="ascii") as handle:
            for line in handle:
                if line.startswith("Pss_Anon"):
                    return int(line.split()[1]) / 1024.0
    except OSError:
        return None
    return None


def _read_bytes(path: Path) -> bytes:
    try:
        return path.read_bytes()
    except OSError:
        return b""


def sample(pid: int, seconds: float, interval: float = 0.5) -> tuple[float, float, float]:
    values: list[float] = []
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        value = read_anon_mb(pid)
        if value is not None:
            values.append(value)
        time.sleep(interval)
    if not values:
        raise MeasurementError("plasmashell disappeared during sampling.")
    return min(values), max(values), values[-1]


class IsolatedSession:
    """Owns every process and directory it creates, and removes them on exit."""

    def __init__(self, package_root: Path, socket_name: str = "punchi-memory-probe") -> None:
        self.package_root = package_root
        self.socket_name = socket_name
        self.root = Path(tempfile.mkdtemp(prefix="punchi-memory-budget-"))
        self.runtime_dir = self.root / "runtime"
        self.config_dir = self.root / "config"
        self.cache_dir = self.root / "cache"
        self.data_dir = self.root / "data"
        self.dbus_address: str | None = None
        self.processes: dict[str, subprocess.Popen] = {}
        self.plasmashell_pid: int | None = None

    # -- environment -----------------------------------------------------
    def _environment(self) -> dict:
        environment = os.environ.copy()
        environment.update(
            {
                "XDG_RUNTIME_DIR": str(self.runtime_dir),
                "XDG_CONFIG_HOME": str(self.config_dir),
                "XDG_CACHE_HOME": str(self.cache_dir),
                "XDG_DATA_HOME": str(self.data_dir),
                "XDG_CURRENT_DESKTOP": "KDE",
                "KDE_FULL_SESSION": "true",
                "QT_QPA_PLATFORM": "wayland",
            }
        )
        if self.dbus_address:
            environment["DBUS_SESSION_BUS_ADDRESS"] = self.dbus_address
        return environment

    def _prepare_directories(self) -> None:
        for directory in (self.runtime_dir, self.config_dir, self.cache_dir):
            directory.mkdir(parents=True, exist_ok=True)
        self.runtime_dir.chmod(0o700)
        plasmoid_target = self.data_dir / "plasma" / "plasmoids" / PLUGIN_ID
        plasmoid_target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(self.package_root / "contents", plasmoid_target / "contents")
        shutil.copy2(self.package_root / "metadata.json", plasmoid_target / "metadata.json")

    # -- processes -------------------------------------------------------
    def _spawn(self, name: str, command: list[str], log_path: Path) -> subprocess.Popen:
        handle = open(log_path, "w", encoding="utf-8")
        process = subprocess.Popen(
            command,
            env=self._environment(),
            stdout=handle,
            stderr=subprocess.STDOUT,
            start_new_session=True,
        )
        process.log_handle = handle  # type: ignore[attr-defined]
        self.processes[name] = process
        return process

    def _start_dbus(self) -> None:
        process = subprocess.run(
            ["dbus-daemon", "--session", "--print-address", "--fork", "--print-pid"],
            capture_output=True,
            text=True,
            timeout=20,
            check=False,
        )
        if process.returncode != 0:
            raise MeasurementError(f"dbus-daemon failed: {process.stderr.strip()}")
        lines = [line for line in process.stdout.splitlines() if line.strip()]
        if len(lines) < 2:
            raise MeasurementError("dbus-daemon did not report its address and pid.")
        self.dbus_address = lines[0].strip()
        dbus_pid = int(lines[1].strip())
        self.processes["dbus"] = _ForeignProcess(dbus_pid)

    def _start_compositor(self) -> None:
        self._spawn(
            "kwin",
            [
                "kwin_wayland",
                "--virtual",
                "--xwayland",
                "false",
                "--socket",
                self.socket_name,
                "--width",
                "1600",
                "--height",
                "900",
            ],
            self.root / "kwin.log",
        )
        socket_path = self.runtime_dir / self.socket_name
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            if socket_path.exists():
                return
            time.sleep(0.2)
        raise MeasurementError("The nested compositor did not create its socket.")

    def _start_shell(self) -> None:
        environment = self._environment()
        environment["WAYLAND_DISPLAY"] = self.socket_name
        handle = open(self.root / "plasmashell.log", "w", encoding="utf-8")
        process = subprocess.Popen(
            ["plasmashell", "--no-respawn"],
            env=environment,
            stdout=handle,
            stderr=subprocess.STDOUT,
            start_new_session=True,
        )
        process.log_handle = handle  # type: ignore[attr-defined]
        self.processes["plasmashell"] = process
        self.plasmashell_pid = process.pid
        self._wait_for_shell()

    def _plasma_shell_call(self, script: str) -> str:
        return self._bus_call(
            "org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell.evaluateScript", script
        )

    def _bus_call(self, destination: str, path: str, method: str, argument: str) -> str:
        result = subprocess.run(
            [
                "gdbus",
                "call",
                "--session",
                "--dest",
                destination,
                "--object-path",
                path,
                "--method",
                method,
                argument,
            ],
            env=self._environment(),
            capture_output=True,
            text=True,
            timeout=60,
            check=False,
        )
        if result.returncode != 0:
            raise MeasurementError(f"gdbus call failed: {result.stderr.strip()}")
        return result.stdout.strip()

    def _wait_for_shell(self, timeout: float = 120.0) -> None:
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if self.plasmashell_pid and not process_alive(self.plasmashell_pid):
                raise MeasurementError(self._shell_failure())
            try:
                subprocess.run(
                    [
                        "gdbus",
                        "introspect",
                        "--session",
                        "--dest",
                        "org.kde.plasmashell",
                        "--object-path",
                        "/PlasmaShell",
                    ],
                    env=self._environment(),
                    capture_output=True,
                    timeout=10,
                    check=True,
                )
                return
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
                time.sleep(1.0)
        raise MeasurementError("plasmashell did not answer on the isolated bus.")

    def _shell_failure(self) -> str:
        log_path = self.root / "plasmashell.log"
        tail = ""
        if log_path.exists():
            tail = "\n".join(log_path.read_text(encoding="utf-8", errors="replace").splitlines()[-15:])
        return f"plasmashell exited before answering on the isolated bus.\n{tail}"

    # -- dock instances --------------------------------------------------
    def dock_instance_count(self) -> int:
        config = self.config_dir / "plasma-org.kde.plasma.desktop-appletsrc"
        if not config.exists():
            return 0
        return config.read_text(encoding="utf-8", errors="replace").count(f"plugin={PLUGIN_ID}")

    def add_dock(self) -> None:
        before = self.dock_instance_count()
        self._plasma_shell_call('panels()[0].addWidget("%s")' % PLUGIN_ID)
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            if self.dock_instance_count() > before:
                return
            time.sleep(1.0)
        raise MeasurementError("The dock instance was not added to the isolated panel.")

    def remove_docks(self) -> None:
        script = (
            'var ps=panels(); for (var i=0;i<ps.length;i++){ var ws=ps[i].widgets();'
            ' for (var j=ws.length-1;j>=0;j--){ if (String(ws[j].type)=="%s"){ ws[j].remove(); } } }'
            % PLUGIN_ID
        )
        self._plasma_shell_call(script)
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            if self.dock_instance_count() == 0:
                return
            time.sleep(1.0)
        raise MeasurementError("The dock instances were not removed from the isolated panel.")

    # -- lifecycle -------------------------------------------------------
    def start(self) -> None:
        self._prepare_directories()
        self._start_dbus()
        self._start_compositor()
        self._start_shell()

    def measure(self, settle_seconds: float, sample_seconds: float) -> float:
        if self.plasmashell_pid is None:
            raise MeasurementError("plasmashell is not running.")
        time.sleep(settle_seconds)
        _, _, last = sample(self.plasmashell_pid, sample_seconds)
        return last

    def stop(self) -> None:
        for name in ("plasmashell", "kwin", "dbus"):
            process = self.processes.pop(name, None)
            if process is None:
                continue
            try:
                process.terminate()
            except ProcessLookupError:
                continue
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                try:
                    process.kill()
                    process.wait(timeout=10)
                except (ProcessLookupError, subprocess.TimeoutExpired):
                    pass
        for process in list(self.processes.values()):
            process.close()
        self._reap_orphans()
        shutil.rmtree(self.root, ignore_errors=True)

    def _reap_orphans(self) -> None:
        """Terminate processes this session started, identified by its temp root."""

        marker = str(self.root).encode()
        own_pid = os.getpid()
        victims: list[int] = []
        for entry in Path("/proc").iterdir():
            if not entry.name.isdigit():
                continue
            pid = int(entry.name)
            if pid == own_pid:
                continue
            if marker in _read_bytes(entry / "environ") or marker in _read_bytes(entry / "cmdline"):
                victims.append(pid)
        for pid in victims:
            try:
                os.kill(pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline and any(process_alive(pid) for pid in victims):
            time.sleep(0.2)
        for pid in victims:
            if process_alive(pid):
                try:
                    os.kill(pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass

    def close(self) -> None:
        for process in getattr(self, "started", []):
            process.close()


class _ForeignProcess:
    """Wraps a pid created outside Popen so it shares the cleanup interface."""

    def __init__(self, pid: int) -> None:
        self.pid = pid

    def terminate(self) -> None:
        try:
            os.kill(self.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass

    def wait(self, timeout: float | None = None) -> int:
        deadline = time.monotonic() + (timeout or 0)
        while time.monotonic() < deadline:
            try:
                os.kill(self.pid, 0)
            except ProcessLookupError:
                return 0
            time.sleep(0.1)
        raise subprocess.TimeoutExpired("dbus-daemon", timeout or 0)

    def kill(self) -> None:
        try:
            os.kill(self.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass

    def close(self) -> None:
        pass


def read_baseline() -> dict:
    baseline = {}
    if not BASELINE_FILE.exists():
        return baseline
    for line in BASELINE_FILE.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        baseline[key.strip()] = value.strip()
    return baseline


def write_baseline(metrics: Metrics, allow_raise: bool) -> None:
    current = read_baseline()
    limits = {
        "MEMORY_MAX_FIRST_INSTANCE_MB": metrics.first_instance_mb,
        "MEMORY_MAX_SECOND_INSTANCE_MB": metrics.second_instance_mb,
        "MEMORY_MAX_RETENTION_MB": metrics.retention_mb,
    }
    for key, measured in limits.items():
        previous = current.get(key)
        if previous is not None and not allow_raise and measured > float(previous) + 0.5:
            raise MeasurementError(
                f"{key} would rise from {previous} MB to {measured:.1f} MB. "
                "A memory baseline may only decrease; pass --allow-raise with a documented reason."
            )
    environment = current.get("MEMORY_PROFILE", "local")
    lines = [
        "# Punchi Dock memory budget, measured with scripts-dev/memory-budget.py.",
        "# Values are Pss_Anon deltas in MB for the environment in MEMORY_PROFILE.",
        "# A baseline may only decrease.",
        f"MEMORY_PROFILE={environment}",
        f"MEMORY_MAX_FIRST_INSTANCE_MB={limits['MEMORY_MAX_FIRST_INSTANCE_MB']:.1f}",
        f"MEMORY_MAX_SECOND_INSTANCE_MB={limits['MEMORY_MAX_SECOND_INSTANCE_MB']:.1f}",
        f"MEMORY_MAX_RETENTION_MB={limits['MEMORY_MAX_RETENTION_MB']:.1f}",
    ]
    BASELINE_FILE.write_text("\n".join(lines) + "\n", encoding="utf-8")
    log(f"Baseline written to {BASELINE_FILE.relative_to(PROJECT_ROOT)}")


def check_baseline(metrics: Metrics) -> int:
    baseline = read_baseline()
    if not baseline:
        log("No baseline file found; run with --write-baseline to create one.")
        return 1
    measured = {
        "MEMORY_MAX_FIRST_INSTANCE_MB": metrics.first_instance_mb,
        "MEMORY_MAX_SECOND_INSTANCE_MB": metrics.second_instance_mb,
        "MEMORY_MAX_RETENTION_MB": metrics.retention_mb,
    }
    failures = 0
    for key, value in measured.items():
        raw = baseline.get(key)
        if raw is None:
            log(f"{key}: missing from baseline")
            failures += 1
            continue
        limit = float(raw)
        status = "ok" if value <= limit else "EXCEEDED"
        if value > limit:
            failures += 1
        log(f"{key}: {value:.1f} MB / budget {limit:.1f} MB -> {status}")
    return 0 if failures == 0 else 1


def measure(settle_seconds: float, sample_seconds: float, package_root: Path) -> Metrics:
    require_tools()
    session = IsolatedSession(package_root)
    metrics = Metrics()
    try:
        log("Starting isolated Plasma session...")
        session.start()
        log("Measuring the shell without the dock...")
        metrics.baseline_mb = session.measure(settle_seconds, sample_seconds)
        session.add_dock()
        log("Measuring the first dock instance...")
        first_total = session.measure(settle_seconds, sample_seconds)
        session.add_dock()
        log("Measuring the second dock instance...")
        second_total = session.measure(settle_seconds, sample_seconds)
        session.remove_docks()
        log("Measuring memory retained after removal...")
        retained_total = session.measure(settle_seconds, sample_seconds)
        metrics.first_instance_mb = first_total - metrics.baseline_mb
        metrics.second_instance_mb = second_total - first_total
        metrics.retention_mb = retained_total - metrics.baseline_mb
        metrics.samples = {
            "baseline_total_mb": round(metrics.baseline_mb, 1),
            "first_total_mb": round(first_total, 1),
            "second_total_mb": round(second_total, 1),
            "retained_total_mb": round(retained_total, 1),
        }
    finally:
        session.stop()
    return metrics


def parse_arguments(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--settle", type=float, default=25.0, help="Seconds to wait before sampling")
    parser.add_argument("--sample", type=float, default=10.0, help="Seconds of sampling per step")
    parser.add_argument(
        "--package",
        type=Path,
        default=PROJECT_ROOT,
        help="Package root to measure instead of the working tree (component bisection)",
    )
    parser.add_argument("--json", action="store_true", help="Print the metrics as JSON")
    parser.add_argument("--check", action="store_true", help="Fail when a metric exceeds the baseline")
    parser.add_argument("--write-baseline", action="store_true", help="Record the measured values")
    parser.add_argument(
        "--allow-raise",
        action="store_true",
        help="Allow writing a higher baseline (requires a documented reason)",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    arguments = parse_arguments(argv)

    def handler(signum, _frame):
        raise Terminated(signum)

    for signum in (signal.SIGINT, signal.SIGTERM):
        signal.signal(signum, handler)

    try:
        package_root = arguments.package.resolve()
        if not (package_root / "metadata.json").exists():
            raise MeasurementError(f"{package_root} does not look like a plasmoid package.")
        metrics = measure(arguments.settle, arguments.sample, package_root)
    except Terminated as error:
        log(f"Interrupted by signal {error.signum}.")
        return 130
    except MeasurementError as error:
        print(f"Memory measurement failed: {error}", file=sys.stderr)
        return 2

    if arguments.json:
        print(json.dumps(metrics.as_dict(), indent=2))
    else:
        log(
            "Result: first instance %.1f MB, second instance %.1f MB, retention %.1f MB"
            % (metrics.first_instance_mb, metrics.second_instance_mb, metrics.retention_mb)
        )

    exit_code = 0
    if arguments.write_baseline:
        try:
            write_baseline(metrics, arguments.allow_raise)
        except MeasurementError as error:
            print(f"Memory baseline not updated: {error}", file=sys.stderr)
            exit_code = 1
    if arguments.check:
        exit_code = max(exit_code, check_baseline(metrics))
    return exit_code


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
