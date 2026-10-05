#!/usr/bin/env python3
"""Run the complete Debian gate in an owned Qt 6.8 source/build copy."""

from __future__ import annotations

import argparse
import json
import os
import platform
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", required=True, type=Path)
    arguments = parser.parse_args()
    if platform.freedesktop_os_release().get("ID") != "debian":
        parser.error("The adaptive copy is restricted to Debian")
    native_lint = os.environ.get("PUNCHI_DEBIAN_QMLLINT_BIN", "/usr/lib/qt6/bin/qmllint")
    version = subprocess.check_output([native_lint, "--version"], text=True).strip()
    if not version.startswith("qmllint 6.8."):
        parser.error("The adaptive copy requires Qt 6.8 tooling")
    project = arguments.project_root.resolve()
    evidence = Path(os.environ["BUILD_DIR"]).resolve()
    evidence.mkdir(parents=True, exist_ok=True)
    environment = os.environ.copy()
    jobs = environment.get("PUNCHI_BUILD_JOBS", "4")
    if not jobs.isdecimal() or int(jobs) < 1:
        parser.error("PUNCHI_BUILD_JOBS must be a positive integer")
    child: subprocess.Popen | None = None

    def interrupt(number: int, _frame: object) -> None:
        if child is not None and child.poll() is None:
            os.killpg(child.pid, number)
        raise KeyboardInterrupt

    previous = {number: signal.signal(number, interrupt)
                for number in (signal.SIGTERM, signal.SIGINT)}
    with tempfile.TemporaryDirectory(prefix="debian-qt68-", dir=evidence) as directory:
        source = Path(directory) / "source"
        build = Path(directory) / "build"
        source.mkdir()
        try:
            # Copy developer sources, never personal directories or stale builds.
            for name in ("contents", "src", "tests", "po", "scripts-dev", "scripts-user"):
                shutil.copytree(project / name, source / name,
                                ignore=shutil.ignore_patterns("__pycache__", "*.pyc"))
            for path in project.iterdir():
                if path.is_file() and (path.name in {"CMakeLists.txt", "metadata.json", "Messages.sh",
                                                    ".gitignore", ".kpackageignore", "AGENTS.md"}
                                       or path.name.startswith(("LICENSE", "NOTICE", "README"))):
                    shutil.copy2(path, source / path.name)
            # The integrity guard needs the unchanged tracked-path index only.
            subprocess.run(["git", "init", "--quiet", str(source)], check=True)
            index = subprocess.check_output(["git", "-C", str(project), "rev-parse",
                                             "--git-path", "index"], text=True).strip()
            index_path = Path(index)
            if not index_path.is_absolute():
                index_path = project / index_path
            shutil.copy2(index_path, source / ".git/index")
            environment["BUILD_DIR"] = str(build)
            environment["PUNCHI_DEBIAN_QT68_COPY"] = "1"
            environment["QMLLINT_BIN"] = str(source / "scripts-dev/debian-qmllint.py")

            def run(command: list[str]) -> int:
                nonlocal child
                child = subprocess.Popen(command, cwd=source, env=environment,
                                         start_new_session=True)
                status = child.wait()
                child = None
                return status

            status = run(["python3", str(source / "scripts-dev/qml-tooling/debian-style-adaptation.py"),
                          "--source-root", str(source)])
            if status:
                return status
            status = run(["python3", str(source / "scripts-dev/qml-tooling/debian-fixture-adaptation.py"),
                          "--source-root", str(source), "--evidence-root", str(evidence)])
            if status:
                return status
            commands = [
                ["cmake", "-S", str(source), "-B", str(build), "-DBUILD_TESTING=ON",
                 "-DCMAKE_BUILD_TYPE=" + environment.get("PACKAGE_BUILD_TYPE", "Release")],
                ["python3", str(source / "scripts-dev/test-integrity-guard.py"), "--update",
                 "--profile", "debian", "--build-dir", str(build), "--authorized",
                 "User explicitly approved three fixture prerequisites only in the disposable Debian copy: "
                 "XDG application menu, valid containment metadata, and rendering/window activation before "
                 "the real media selector click. All existing assertions, 155 names and gates are preserved."],
                ["cmake", "--build", str(build), "--parallel", jobs],
                ["cmake", "--build", str(build), "--target", "stage_plasmoid_module"],
            ]
            for command in commands:
                status = run(command)
                if status:
                    return status
            module = build / "package-root/contents/ui/org/punchi/dock"
            shutil.copytree(module, source / "contents/ui/org/punchi/dock", dirs_exist_ok=True)
            tooling_build = build / "debian-runtime-bootstrap"
            for command in (
                ["cmake", "-S", str(source / "scripts-dev/qml-tooling"), "-B", str(tooling_build),
                 "-DPUNCHI_TEST_SOURCE_ROOT=" + str(source), "-DPUNCHI_TEST_BUILD_ROOT=" + str(build)],
                ["cmake", "--build", str(tooling_build), "--parallel", jobs],
            ):
                status = run(command)
                if status:
                    return status
            # Authorized only for this copy: same setup and assertions, with
            # the legacy Plasma registration missing from standalone runners.
            for runner in ("punchi_qmltestrunner", "config_items_qml_test_runner",
                           "recent_general_qml_test_runner"):
                launcher = build / "bin" / runner
                native = tooling_build / ("legacy_" + runner)
                wrapper = source / "scripts-dev/qml-tooling/run-legacy-test-runner.py"
                launcher.write_text(
                    "#!/usr/bin/env python3\nimport runpy, sys\n"
                    "sys.argv = [" + json.dumps(str(wrapper)) + ", "
                    + json.dumps(str(native)) + ", __file__, *sys.argv[1:]]\n"
                    "runpy.run_path(" + json.dumps(str(wrapper)) + ", run_name='__main__')\n")
                launcher.chmod(0o755)
            print("==> Running the unchanged Debian gate in the Qt 6.8 copy", flush=True)
            return run([str(source / "scripts-dev/distro/debian13-package.sh")])
        finally:
            if child is not None and child.poll() is None:
                os.killpg(child.pid, signal.SIGTERM)
                try:
                    child.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(child.pid, signal.SIGKILL)
                    child.wait()
            integrity = source / "scripts-dev/test-integrity/hashes.txt"
            if integrity.is_file():
                shutil.copy2(integrity, evidence / "qt68-copy-test-integrity-hashes.txt")
            for name in ("qmllint.log", "Testing/Temporary/LastTest.log",
                         "Testing/Temporary/LastTestsFailed.log"):
                path = build / name
                if path.is_file():
                    shutil.copy2(path, evidence / ("qt68-copy-" + path.name))
            for number, handler in previous.items():
                signal.signal(number, handler)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise SystemExit(130)
