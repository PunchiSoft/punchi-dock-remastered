#!/usr/bin/env python3
"""Prepare a clean Kubuntu host and build Punchi Dock natively."""

from __future__ import annotations

import argparse
import os
import platform
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Mapping, Sequence


SCRIPT_PATH = Path(__file__).resolve()
PROJECT_ROOT = SCRIPT_PATH.parents[2]
DIST_DIR = PROJECT_ROOT / "dist"

APT_PACKAGES: tuple[str, ...] = (
    "binutils",
    "build-essential",
    "cmake",
    "extra-cmake-modules",
    "gettext",
    "git",
    "kpackagetool6",
    "libkf6coreaddons-dev",
    "libkf6i18n-dev",
    "libkf6jobwidgets-dev",
    "libkf6kio-dev",
    "libkf6service-dev",
    "libpipewire-0.3-dev",
    "libplasma-dev",
    "ninja-build",
    "pkg-config",
    "qt6-base-dev",
    "qt6-declarative-dev",
    "qt6-declarative-dev-tools",
    "unzip",
    "zip",
)

REQUIRED_COMMANDS: tuple[str, ...] = (
    "cmake",
    "ctest",
    "c++",
    "kpackagetool6",
    "msgattrib",
    "msgfmt",
    "pkg-config",
    "qtpaths6",
    "readelf",
    "strip",
    "unzip",
    "zip",
)


class SetupError(RuntimeError):
    """Report an actionable environment preparation failure."""


def parse_arguments() -> argparse.Namespace:
    """Parse command-line options."""

    parser = argparse.ArgumentParser(
        description=(
            "Install the Kubuntu build dependencies and compile a native "
            "Punchi Dock plasmoid for the current Plasma 6 host."
        )
    )
    parser.add_argument(
        "--yes",
        action="store_true",
        help="Pass --yes to APT. Sudo can still request the user password.",
    )
    parser.add_argument(
        "--skip-update",
        action="store_true",
        help="Skip apt-get update when the local package index is already current.",
    )
    workflow_group = parser.add_mutually_exclusive_group()
    workflow_group.add_argument(
        "--dependencies-only",
        action="store_true",
        help="Install and verify dependencies without building a plasmoid.",
    )
    workflow_group.add_argument(
        "--local-test",
        action="store_true",
        help="Build, install, restart Plasma Shell, and collect startup diagnostics.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate the host and print commands without changing the system.",
    )
    return parser.parse_args()


def read_os_release(path: Path = Path("/etc/os-release")) -> dict[str, str]:
    """Read simple key/value fields from os-release without evaluating shell code."""

    if not path.is_file():
        raise SetupError(f"Distribution metadata was not found: {path}")

    fields: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        fields[key] = value.strip().strip("\"").strip("'")
    return fields


def command_output(command: Sequence[str]) -> str:
    """Run a read-only command and return its standard output."""

    try:
        result = subprocess.run(
            command,
            check=True,
            cwd=PROJECT_ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
    except FileNotFoundError as error:
        raise SetupError(f"Required command was not found: {command[0]}") from error
    except subprocess.CalledProcessError as error:
        output = (error.stdout or "").strip()
        detail = f"\n{output}" if output else ""
        raise SetupError(f"Command failed: {' '.join(command)}{detail}") from error
    return result.stdout.strip()


def run_command(
    command: Sequence[str],
    *,
    dry_run: bool,
    environment: Mapping[str, str] | None = None,
) -> None:
    """Run a state-changing command without invoking a shell."""

    print(f"$ {' '.join(command)}", flush=True)
    if dry_run:
        return
    try:
        subprocess.run(
            command,
            check=True,
            cwd=PROJECT_ROOT,
            env=dict(environment) if environment is not None else None,
        )
    except FileNotFoundError as error:
        raise SetupError(f"Required command was not found: {command[0]}") from error
    except subprocess.CalledProcessError as error:
        raise SetupError(
            f"Command failed with exit code {error.returncode}: {' '.join(command)}"
        ) from error


def extract_plasma_version(version_output: str) -> str:
    """Extract a numeric Plasma version from localized command output."""

    named_match = re.search(
        r"\bplasmashell\D+([0-9]+(?:\.[0-9]+){1,3})",
        version_output,
        flags=re.IGNORECASE,
    )
    if named_match:
        return named_match.group(1)

    fallback_match = re.search(
        r"(?<![0-9])([0-9]+(?:\.[0-9]+){1,3})(?![0-9])",
        version_output,
    )
    return fallback_match.group(1) if fallback_match else ""


def detect_plasma_version() -> str:
    """Return and validate the active Plasma major version."""

    output = command_output(("plasmashell", "--version"))
    version = extract_plasma_version(output)
    if not version.startswith("6."):
        raise SetupError(
            "Punchi Dock requires Plasma 6; "
            f"version output: {output or 'empty'}"
        )
    return version


def validate_host() -> tuple[dict[str, str], str]:
    """Ensure the script is running as a desktop user on Kubuntu."""

    if os.geteuid() == 0:
        raise SetupError(
            "Run this script as the desktop user, not as root. "
            "It requests sudo only for APT."
        )

    os_release = read_os_release()
    if os_release.get("ID") != "ubuntu":
        raise SetupError(
            "This setup script is only for Kubuntu/Ubuntu with Plasma "
            f"(detected: {os_release.get('ID', 'unknown')})."
        )
    if shutil.which("sudo") is None:
        raise SetupError("sudo is required to install APT packages.")
    if shutil.which("apt-get") is None or shutil.which("apt-cache") is None:
        raise SetupError("apt-get and apt-cache are required on the Kubuntu host.")

    plasma_version = detect_plasma_version()
    return os_release, plasma_version


def unavailable_packages() -> list[str]:
    """Return required package names absent from the configured APT catalog."""

    unavailable: list[str] = []
    for package_name in APT_PACKAGES:
        result = subprocess.run(
            ("apt-cache", "show", "--no-all-versions", package_name),
            check=False,
            text=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if result.returncode != 0:
            unavailable.append(package_name)
    return unavailable


def install_dependencies(arguments: argparse.Namespace) -> None:
    """Refresh APT metadata, validate package names, and install dependencies."""

    if not arguments.skip_update:
        run_command(
            ("sudo", "apt-get", "update"),
            dry_run=arguments.dry_run,
        )

    if arguments.dry_run:
        missing: list[str] = []
    else:
        missing = unavailable_packages()
    if missing:
        formatted = "\n  - ".join(missing)
        raise SetupError(
            "The following packages are unavailable in the configured APT sources:\n"
            f"  - {formatted}\n"
            "Enable the official Ubuntu Universe repository for this Kubuntu "
            "release, refresh APT, and run the script again."
        )

    install_command = ["sudo", "apt-get", "install"]
    if arguments.yes:
        install_command.append("--yes")
    install_command.extend(APT_PACKAGES)
    run_command(install_command, dry_run=arguments.dry_run)


def verify_commands(*, dry_run: bool) -> None:
    """Verify the exact commands consumed by the packaging pipeline."""

    if dry_run:
        print("Dry run: post-install command verification was skipped.")
        return

    missing = [name for name in REQUIRED_COMMANDS if shutil.which(name) is None]
    if missing:
        raise SetupError(
            "Dependency installation completed, but required commands are missing: "
            + ", ".join(missing)
        )

    run_command(
        (str(PROJECT_ROOT / "scripts" / "check-build-environment.sh"),),
        dry_run=False,
    )


def baseline_path(os_release: Mapping[str, str], plasma_version: str) -> Path:
    """Return the same host-specific baseline path as the Kubuntu build wrapper."""

    safe_version = re.sub(r"[^A-Za-z0-9._-]", "_", plasma_version)
    label = (
        f"kubuntu{os_release.get('VERSION_ID', 'unknown')}-"
        f"plasma{safe_version}-{platform.machine()}"
    )
    cache_root = Path(
        os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache"))
    )
    return cache_root / "punchi-dock-remastered" / label / "qmllint-baseline.env"


def build_plasmoid(
    arguments: argparse.Namespace,
    os_release: Mapping[str, str],
    plasma_version: str,
) -> None:
    """Build either a package-only or installed local-test artifact."""

    environment = os.environ.copy()
    local_baseline = baseline_path(os_release, plasma_version)
    if not local_baseline.is_file():
        print(f"Recording the first Kubuntu qmllint baseline: {local_baseline}")
        environment["QMLLINT_RECORD_BASELINE"] = "1"

    if arguments.local_test:
        command = (str(PROJECT_ROOT / "scripts" / "probar-plasmoid.sh"),)
    else:
        command = (str(PROJECT_ROOT / "scripts" / "build-kubuntu-package.sh"),)

    run_command(command, dry_run=arguments.dry_run, environment=environment)
    if arguments.dry_run:
        return

    artifacts = sorted(
        DIST_DIR.glob("punchi-dock-remastered-*-kubuntu*.plasmoid"),
        key=lambda path: path.stat().st_mtime,
        reverse=True,
    )
    if not artifacts:
        raise SetupError("The build finished without creating a Kubuntu artifact.")
    print(f"Kubuntu artifact ready: {artifacts[0]}")


def main() -> int:
    """Run the complete Kubuntu setup and packaging workflow."""

    arguments = parse_arguments()
    try:
        os_release, plasma_version = validate_host()
        pretty_name = os_release.get("PRETTY_NAME", "Kubuntu")
        print(f"Detected host: {pretty_name}, Plasma {plasma_version}")
        print("Required APT packages:")
        for package_name in APT_PACKAGES:
            print(f"  - {package_name}")

        install_dependencies(arguments)
        verify_commands(dry_run=arguments.dry_run)
        if not arguments.dependencies_only:
            build_plasmoid(arguments, os_release, plasma_version)
        print("Kubuntu build environment preparation completed.")
        return 0
    except SetupError as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
