#!/usr/bin/env python3
"""Guard the integrity of the Punchi Dock test evidence layer.

The tests are the evidence of the project contract, not an obstacle to a
favourable result. This guard protects that evidence:

* every file under ``tests/`` tracked by Git is protected by SHA-256; any change
  requires explicit user authorization, including a change that only adds lines;
* the canonical CTest names may grow, but must not lose an entry, be renamed, or
  disappear because a registration became conditional;
* the per-profile test floor may stay or grow, never shrink on its own;
* suspicious deactivation patterns must not appear without review;
* the gate scripts must keep running the real test gate.

The guard never decides that a change is legitimate. It stops and reports the
delta; the user authorizes it, and then ``--update --authorized`` records the new
state. See ``scripts-dev/test-integrity/README.md`` for the policy and the
stop-and-report procedure, and ``AGENTS.md`` for the canonical project rule.
"""

from __future__ import annotations

import argparse
import hashlib
import re
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable, Sequence

EXIT_OK = 0
EXIT_VIOLATION = 1
EXIT_ERROR = 2

TEST_SCOPE = "tests"
MECHANISM_DIR = "scripts-dev/test-integrity"
GUARD_SCRIPT = "scripts-dev/test-integrity-guard.py"
HASHES_FILE = f"{MECHANISM_DIR}/hashes.txt"
PATTERNS_FILE = f"{MECHANISM_DIR}/patterns-baseline.txt"
FLOOR_FILE_TEMPLATE = "scripts-dev/tests-baseline-{profile}.env"
DEFAULT_BUILD_DIR = "build"

FLOOR_FILE_CONTENT = (
    "# Minimum number of CTest tests expected on this platform profile.\n"
    "# Floor semantics: the count may stay or grow. Lowering it requires explicit\n"
    '# user authorization; see AGENTS.md, "Test integrity".\n'
    "MIN_TESTS={value}\n"
)

TEST_CLASS = "test"
MECHANISM_CLASS = "mechanism"

# Suspicious constructs. A pre-existing occurrence is documented in the pattern
# baseline; a new one stops the delivery and is reported for contextual review.
PATTERNS: tuple[tuple[str, str], ...] = (
    ("cmake-will-fail", r"\bWILL_FAIL\b"),
    ("cmake-disabled", r"\bDISABLED\b"),
    ("cmake-skip-return-code", r"\bSKIP_RETURN_CODE\b"),
    ("ctest-exclude-regex", r"ctest\b[^\n]*--exclude-regex"),
    ("ctest-exclude-short", r"ctest\b[^\n]*\s-E\s"),
    ("ctest-narrow-regex", r"ctest\b[^\n]*\s-R\s"),
    ("ctest-masked-failure", r"ctest\b[^\n]*\|\|\s*true"),
    ("qt-skip-call", r"\bskip\s*\("),
    ("qt-skip-parameter", r"\bqt_skip\b"),
    ("qt-ignore-warning", r"\bignoreWarning\s*\("),
    ("qt-expect-fail", r"\bQEXPECT_FAIL\b"),
    ("python-skip-decorator", r"@(?:pytest\.mark\.(?:skip|xfail)|unittest\.skip)"),
)

PATTERN_SCAN_SCOPES = (TEST_SCOPE, "scripts-dev/distro", "scripts-user/lib")
TEXT_SUFFIXES = (
    ".cmake", ".conf", ".cpp", ".h", ".js", ".json", ".md",
    ".py", ".qml", ".sh", ".txt",
)


@dataclass(frozen=True)
class GateContract:
    """Functional contract for a script that evolves for unrelated reasons.

    These scripts are not frozen by hash: they must keep running the real gate
    and must not introduce a way to omit or neutralize it.
    """

    path: str
    required: tuple[str, ...]
    forbidden: tuple[str, ...]
    note: str


GATE_CONTRACTS: tuple[GateContract, ...] = (
    GateContract(
        path="scripts-user/lib/package-plasmoid.sh",
        required=(
            r"(?m)^\s*ctest\s+--test-dir\b",
            r"(?m)test-integrity-guard\.py",
        ),
        forbidden=(
            r"(?m)^\s*ctest\b[^\n]*\|\|\s*true",
            r"(?m)^\s*ctest\b[^\n]*\s-E\s",
            r"(?m)^\s*ctest\b[^\n]*--exclude-regex",
        ),
        note="Packaging gate: must run ctest and the integrity guard, unmasked and unfiltered.",
    ),
)


class GuardError(RuntimeError):
    """Unrecoverable environment or usage problem."""


@dataclass
class Report:
    failures: list[tuple[str, str]] = field(default_factory=list)
    notices: list[str] = field(default_factory=list)

    def fail(self, code: str, message: str) -> None:
        self.failures.append((code, message))

    def note(self, message: str) -> None:
        self.notices.append(message)

    def render(self, title: str) -> None:
        print(f"==> {title}")
        for code, message in self.failures:
            print(f"[FAIL] {code}: {message}")
        for message in self.notices:
            print(f"[NOTE] {message}")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def git_ls_files(root: Path, scope: str) -> list[str]:
    result = subprocess.run(
        ["git", "-C", str(root), "ls-files", "--", scope],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise GuardError(
            f"git ls-files failed for '{scope}': {result.stderr.strip() or 'unknown error'}"
        )
    return [line for line in result.stdout.splitlines() if line.strip()]


def hashed_paths(root: Path) -> dict[str, str]:
    """Return the protected files as ``relative path -> class``.

    The test scope relies on Git tracking, which keeps generated directories such
    as ``tests/__pycache__`` out. The mechanism scope relies on the filesystem so
    a mechanism file is protected before its first commit.
    """
    protected: dict[str, str] = {}
    for relative in git_ls_files(root, TEST_SCOPE):
        protected[relative] = TEST_CLASS

    mechanism_candidates: list[Path] = []
    if (root / GUARD_SCRIPT).is_file():
        mechanism_candidates.append(Path(GUARD_SCRIPT))
    mechanism_directory = root / MECHANISM_DIR
    if mechanism_directory.is_dir():
        mechanism_candidates.extend(
            path.relative_to(root)
            for path in sorted(mechanism_directory.iterdir())
            if path.is_file()
        )
    mechanism_candidates.extend(
        path.relative_to(root)
        for path in sorted((root / "scripts-dev").glob("tests-baseline-*.env"))
    )
    for relative in mechanism_candidates:
        as_posix = relative.as_posix()
        if as_posix == HASHES_FILE:
            # Self-hashing is circular: the hash file is protected by the
            # update rules and by the reviewed diff instead.
            continue
        protected[as_posix] = MECHANISM_CLASS
    return protected


def read_hashes(path: Path) -> dict[str, str]:
    recorded: dict[str, str] = {}
    if not path.is_file():
        return recorded
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split(None, 1)
        if len(parts) != 2:
            raise GuardError(f"malformed hash entry in {path.name}: {raw!r}")
        recorded[parts[1].strip()] = parts[0]
    return recorded


def write_hashes(path: Path, hashes: dict[str, str]) -> None:
    lines = [
        "# Protected paths and their SHA-256. Generated by test-integrity-guard.py.",
        "# A test entry changes only with explicit user authorization.",
        "",
    ]
    lines.extend(f"{digest}  {relative}" for relative, digest in sorted(hashes.items()))
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def read_lines(path: Path) -> list[str]:
    if not path.is_file():
        return []
    return [
        line.strip()
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.strip().startswith("#")
    ]


def read_pattern_baseline(path: Path) -> set[tuple[str, str]]:
    recorded: set[tuple[str, str]] = set()
    for line in read_lines(path):
        parts = line.split(None, 1)
        if len(parts) != 2:
            raise GuardError(f"malformed pattern baseline entry: {line!r}")
        recorded.add((parts[0], parts[1].strip()))
    return recorded


def write_pattern_baseline(path: Path, entries: Iterable[tuple[str, str]]) -> None:
    lines = [
        "# Documented pre-existing occurrences of deactivation patterns.",
        "# A new occurrence stops the delivery and is reported for review; it is",
        "# recorded here only with explicit user authorization.",
        "",
    ]
    lines.extend(f"{pattern_id}  {relative}" for pattern_id, relative in sorted(entries))
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def read_floor(path: Path) -> int | None:
    if not path.is_file():
        return None
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        key, separator, value = line.partition("=")
        if separator and key.strip() == "MIN_TESTS":
            try:
                return int(value.strip())
            except ValueError as error:
                raise GuardError(f"MIN_TESTS is not an integer in {path.name}") from error
    return None


def floor_path(root: Path, profile: str) -> Path:
    return root / FLOOR_FILE_TEMPLATE.format(profile=profile)


def detect_profile() -> str:
    os_release = Path("/etc/os-release")
    if os_release.is_file():
        for raw in os_release.read_text(encoding="utf-8").splitlines():
            if raw.startswith("ID="):
                return raw.partition("=")[2].strip().strip('"')
    return "unknown"


def manifest_path(root: Path, profile: str) -> Path:
    return root / MECHANISM_DIR / f"manifest-{profile}.txt"


def parse_ctest_listing(text: str) -> list[str]:
    names: list[str] = []
    for line in text.splitlines():
        match = re.match(r"\s*Test\s+#\d+:\s*(\S+)", line)
        if match:
            names.append(match.group(1))
    return names


def current_ctest_names(root: Path, build_dir: Path, names_file: Path | None) -> list[str] | None:
    """Return the canonical CTest names, or None when they cannot be discovered."""
    if names_file is not None:
        if not names_file.is_file():
            raise GuardError(f"ctest names file not found: {names_file}")
        return [line for line in read_lines(names_file)]
    if not (build_dir / "CMakeCache.txt").is_file():
        return None
    result = subprocess.run(
        ["ctest", "--test-dir", str(build_dir), "-N"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        return None
    return parse_ctest_listing(result.stdout)


def scan_patterns(root: Path) -> set[tuple[str, str]]:
    found: set[tuple[str, str]] = set()
    compiled = [(pattern_id, re.compile(regex)) for pattern_id, regex in PATTERNS]
    for scope in PATTERN_SCAN_SCOPES:
        for relative in git_ls_files(root, scope):
            if not relative.endswith(TEXT_SUFFIXES):
                continue
            path = root / relative
            if not path.is_file():
                continue
            try:
                text = path.read_text(encoding="utf-8")
            except (UnicodeDecodeError, OSError):
                continue
            for pattern_id, regex in compiled:
                if regex.search(text):
                    found.add((pattern_id, relative))
    return found


def check_gate_contracts(root: Path) -> list[tuple[str, str]]:
    failures: list[tuple[str, str]] = []
    for contract in GATE_CONTRACTS:
        path = root / contract.path
        if not path.is_file():
            failures.append(("gate-missing", f"{contract.path} is missing"))
            continue
        text = path.read_text(encoding="utf-8")
        for pattern in contract.required:
            if not re.search(pattern, text):
                failures.append(
                    (
                        "gate-contract",
                        f"{contract.path} no longer matches the required call: {pattern}",
                    )
                )
        for pattern in contract.forbidden:
            if re.search(pattern, text):
                failures.append(
                    (
                        "gate-neutralized",
                        f"{contract.path} matches a neutralization pattern: {pattern}",
                    )
                )
    return failures


@dataclass
class CheckResult:
    failures: list[tuple[str, str]]
    notices: list[str]


def collect_state(root: Path, profile: str, build_dir: Path, names_file: Path | None) -> CheckResult:
    failure_list: list[tuple[str, str]] = []
    notices: list[str] = []

    protected = hashed_paths(root)
    recorded = read_hashes(root / HASHES_FILE)
    if not (root / HASHES_FILE).is_file():
        raise GuardError(
            f"no protected-path manifest found at {HASHES_FILE}; run --update to bootstrap it"
        )

    for relative, expected in sorted(recorded.items()):
        path = root / relative
        if not path.is_file():
            failure_list.append(("test-removed", f"{relative} is recorded but no longer exists"))
            continue
        actual = sha256_file(path)
        if actual != expected:
            failure_list.append(
                ("test-modified", f"{relative} changed and is not authorized to change")
            )

    for relative in sorted(protected):
        if relative not in recorded:
            if protected[relative] == TEST_CLASS:
                failure_list.append(
                    (
                        "test-unincorporated",
                        f"{relative} is tracked by Git but absent from the manifest; "
                        "run --update to incorporate it (adding a test needs no authorization)",
                    )
                )
            else:
                failure_list.append(
                    (
                        "mechanism-unrecorded",
                        f"{relative} is a mechanism file absent from the manifest; run --update",
                    )
                )

    names = current_ctest_names(root, build_dir, names_file)
    manifest_entries = read_lines(manifest_path(root, profile))
    floor = read_floor(floor_path(root, profile))

    if names is None:
        notices.append(
            "CTest names were not discovered (no configured build directory); "
            "the name manifest and the floor were not verified"
        )
    else:
        if not manifest_entries:
            notices.append(
                f"no name manifest for profile '{profile}'; run --update to calibrate it"
            )
        missing = sorted(set(manifest_entries) - set(names))
        for name in missing:
            failure_list.append(
                (
                    "test-unregistered",
                    f"CTest name '{name}' is recorded but no longer registered",
                )
            )
        if floor is not None and len(names) < floor:
            failure_list.append(
                (
                    "test-count",
                    f"the suite reports {len(names)} tests, below the floor of {floor}",
                )
            )
        if floor is not None and manifest_entries and len(manifest_entries) < floor:
            failure_list.append(
                (
                    "manifest-shrunk",
                    f"the name manifest holds {len(manifest_entries)} entries, "
                    f"below the floor of {floor}",
                )
            )
        if floor is not None and manifest_entries and floor != len(manifest_entries):
            failure_list.append(
                (
                    "floor-mismatch",
                    f"the floor is {floor} but the authorized name manifest holds "
                    f"{len(manifest_entries)} entries; a lowered baseline must not stay authorised",
                )
            )

    if floor is None:
        notices.append(
            f"no test floor calibrated for profile '{profile}'; "
            "the quantity check is inactive for this profile"
        )

    pattern_baseline = read_pattern_baseline(root / PATTERNS_FILE)
    if not (root / PATTERNS_FILE).is_file():
        raise GuardError(
            f"no pattern baseline found at {PATTERNS_FILE}; run --update to bootstrap it"
        )
    for pattern_id, relative in sorted(scan_patterns(root) - pattern_baseline):
        failure_list.append(
            (
                "pattern-new",
                f"{relative} introduces '{pattern_id}'; this needs review, not silent acceptance",
            )
        )

    failure_list.extend(check_gate_contracts(root))
    return CheckResult(failure_list, notices)


def command_check(args: argparse.Namespace) -> int:
    root = args.root.resolve()
    build_dir = (root / args.build_dir).resolve()
    result = collect_state(root, args.profile, build_dir, args.ctest_names_file)
    report = Report(result.failures, result.notices)
    report.render(f"Test integrity check (profile: {args.profile})")
    if report.failures:
        print(f"Result: FAIL ({len(report.failures)} finding(s) require authorization)")
        print("A protected test, manifest, floor or gate changed. Stop, report the delta")
        print("and wait for explicit authorization before running --update --authorized.")
        return EXIT_VIOLATION
    print("Result: PASS")
    return EXIT_OK


@dataclass
class Delta:
    added: list[str] = field(default_factory=list)
    changed: list[str] = field(default_factory=list)
    removed: list[str] = field(default_factory=list)

    @property
    def destructive(self) -> bool:
        return bool(self.changed or self.removed)

    def describe(self, label: str) -> list[str]:
        lines = []
        for relative in self.added:
            lines.append(f"  + {label}: added {relative}")
        for relative in self.changed:
            lines.append(f"  ! {label}: changed {relative}")
        for relative in self.removed:
            lines.append(f"  - {label}: removed {relative}")
        return lines


def diff_hashes(old: dict[str, str], new: dict[str, str]) -> tuple[Delta, Delta]:
    """Split the hash delta into the test class and the mechanism class."""
    tests = Delta()
    mechanism = Delta()
    for relative in sorted(set(old) | set(new)):
        target = tests if relative.startswith(f"{TEST_SCOPE}/") else mechanism
        if relative not in old:
            target.added.append(relative)
        elif relative not in new:
            target.removed.append(relative)
        elif old[relative] != new[relative]:
            target.changed.append(relative)
    return tests, mechanism


def write_floor(path: Path, value: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(FLOOR_FILE_CONTENT.format(value=value), encoding="utf-8")


def build_receipt(
    test_delta: Delta,
    mechanism_delta: Delta,
    names_added: Sequence[str],
    names_removed: Sequence[str],
    patterns_added: Sequence[tuple[str, str]],
    patterns_removed: Sequence[tuple[str, str]],
    previous_floor: int | None,
    new_floor: int,
) -> list[str]:
    receipt: list[str] = []
    receipt.extend(test_delta.describe("test"))
    receipt.extend(mechanism_delta.describe("mechanism"))
    receipt.extend(f"  + ctest-name: added {name}" for name in names_added)
    receipt.extend(f"  - ctest-name: removed {name}" for name in names_removed)
    receipt.extend(f"  + pattern: added {pid} {rel}" for pid, rel in patterns_added)
    receipt.extend(f"  - pattern: removed {pid} {rel}" for pid, rel in patterns_removed)
    if previous_floor is None:
        receipt.append(f"  + floor: calibrated to {new_floor}")
    elif new_floor != previous_floor:
        receipt.append(f"  ! floor: {previous_floor} -> {new_floor}")
    return receipt


def command_update(args: argparse.Namespace) -> int:
    root = args.root.resolve()
    build_dir = (root / args.build_dir).resolve()
    authorized = args.authorized
    if authorized is not None and not authorized.strip():
        raise GuardError("--authorized requires a non-empty motive")

    protected = hashed_paths(root)
    if not protected:
        raise GuardError("no protected files were found; check --root")

    previous_hashes = read_hashes(root / HASHES_FILE)
    prospective = {relative: sha256_file(root / relative) for relative in sorted(protected)}
    test_delta, mechanism_delta = diff_hashes(previous_hashes, prospective)

    names = current_ctest_names(root, build_dir, args.ctest_names_file)
    name_manifest = manifest_path(root, args.profile)
    previous_names = set(read_lines(name_manifest))
    new_names = list(names) if names is not None else sorted(previous_names)
    names_removed = sorted(previous_names - set(new_names))
    names_added = sorted(set(new_names) - previous_names)

    floor_file = floor_path(root, args.profile)
    previous_floor = read_floor(floor_file)
    if names is not None:
        new_floor = max(len(new_names), previous_floor or 0)
    else:
        new_floor = previous_floor or 0
    floor_lowered = previous_floor is not None and new_floor < previous_floor

    pattern_file = root / PATTERNS_FILE
    had_pattern_baseline = pattern_file.is_file()
    previous_patterns = read_pattern_baseline(pattern_file)
    current_patterns = scan_patterns(root)
    patterns_added = sorted(current_patterns - previous_patterns)
    patterns_removed = sorted(previous_patterns - current_patterns)

    blocked: list[str] = []
    if test_delta.destructive:
        blocked.append(
            f"{len(test_delta.changed) + len(test_delta.removed)} existing test file(s) "
            "changed or disappeared"
        )
    if mechanism_delta.removed:
        blocked.append(f"{len(mechanism_delta.removed)} mechanism file(s) disappeared")
    if names_removed:
        blocked.append(f"{len(names_removed)} CTest name(s) would be dropped")
    if floor_lowered:
        blocked.append(f"the test floor would drop from {previous_floor} to {new_floor}")
    if had_pattern_baseline and patterns_added:
        blocked.append(f"{len(patterns_added)} new deactivation pattern(s) appeared")
    if had_pattern_baseline and patterns_removed:
        blocked.append(f"{len(patterns_removed)} documented pattern(s) would be dropped")

    receipt = build_receipt(
        test_delta,
        mechanism_delta,
        names_added,
        names_removed,
        patterns_added,
        patterns_removed,
        previous_floor,
        new_floor,
    )

    if blocked and authorized is None:
        print("==> Test integrity update refused")
        for item in blocked:
            print(f"[FAIL] {item}")
        for line in receipt:
            print(line)
        print("Result: FAIL (the ordinary update path cannot record a destructive change)")
        print("Report the delta and wait for explicit user authorization, then run:")
        print('  scripts-dev/test-integrity-guard.py --update --authorized "<motive>"')
        return EXIT_VIOLATION

    (root / MECHANISM_DIR).mkdir(parents=True, exist_ok=True)
    (root / "scripts-dev").mkdir(parents=True, exist_ok=True)
    if names is not None or previous_names:
        header = [
            f"# Canonical CTest names for profile '{args.profile}', from 'ctest -N'.",
            "# The set may grow. An entry must not disappear without explicit",
            "# user authorization; see AGENTS.md, \"Test integrity\".",
            "",
        ]
        name_manifest.write_text("\n".join(header + new_names) + "\n", encoding="utf-8")
    if new_floor:
        write_floor(floor_file, new_floor)
    write_pattern_baseline(pattern_file, current_patterns)

    # The mechanism data files written above are themselves protected: record
    # the hashes only once every one of them exists.
    final_paths = hashed_paths(root)
    write_hashes(
        root / HASHES_FILE,
        {relative: sha256_file(root / relative) for relative in sorted(final_paths)},
    )

    print("==> Test integrity update")
    for line in receipt or ["  (no change)"]:
        print(line)
    if authorized is not None:
        print(f"[AUTHORIZED] {authorized.strip()}")
    print("Result: PASS")
    return EXIT_OK


def _run_guard(arguments: Sequence[str]) -> tuple[int, str]:
    result = subprocess.run(
        [sys.executable, str(Path(__file__).resolve()), *arguments],
        capture_output=True,
        text=True,
        check=False,
    )
    return result.returncode, result.stdout + result.stderr


def _git(root: Path, *arguments: str) -> None:
    subprocess.run(["git", "-C", str(root), *arguments], capture_output=True, text=True, check=False)


def _scaffold(root: Path, names_file: Path, names: Sequence[str]) -> None:
    (root / TEST_SCOPE).mkdir(parents=True, exist_ok=True)
    (root / TEST_SCOPE / "alpha_test.py").write_text(
        "def test_alpha():\n    assert True\n", encoding="utf-8"
    )
    (root / TEST_SCOPE / "beta_test.qml").write_text(
        "import QtQuick\n\nItem {}\n", encoding="utf-8"
    )
    gate = root / "scripts-user/lib"
    gate.mkdir(parents=True, exist_ok=True)
    (gate / "package-plasmoid.sh").write_text(
        "ctest --test-dir \"$BUILD_DIR\" --parallel 4 --output-on-failure\n"
        "python3 scripts-dev/test-integrity-guard.py --check\n",
        encoding="utf-8",
    )
    names_file.write_text("\n".join(names) + "\n", encoding="utf-8")
    _git(root, "init", "-q")
    _git(root, "add", TEST_SCOPE, "scripts-user")


def command_self_test(args: argparse.Namespace) -> int:
    """Exercise the guard against temporary fixtures; never touches the project."""
    outcomes: list[tuple[str, str, int, int]] = []

    def record(code: str, description: str, expected: int, actual: int) -> None:
        outcomes.append((code, description, expected, actual))

    with tempfile.TemporaryDirectory(prefix="punchi-test-integrity-") as temporary:
        root = Path(temporary)
        names_file = root / "ctest-names.txt"
        _scaffold(root, names_file, ["alpha_test", "beta_test"])
        common = [
            "--root", str(root),
            "--profile", "selftest",
            "--ctest-names-file", str(names_file),
        ]

        code, _ = _run_guard(common + ["--update"])
        record("bootstrap", "bootstrap a repository without a manifest", EXIT_OK, code)
        code, _ = _run_guard(common + ["--check"])
        record("clean", "a clean repository passes without findings", EXIT_OK, code)

        alpha = root / TEST_SCOPE / "alpha_test.py"
        alpha.write_text("def test_alpha():\n    assert True\n\n\ndef test_more():\n    pass\n")
        code, _ = _run_guard(common + ["--check"])
        record(
            "modified-test",
            "modifying an existing test is detected (even adding lines)",
            EXIT_VIOLATION,
            code,
        )

        code, _ = _run_guard(common + ["--update"])
        record("unauthorized-refresh", "the ordinary update cannot record it", EXIT_VIOLATION, code)

        code, _ = _run_guard(common + ["--update", "--authorized", "self-test fixture"])
        record("authorized-refresh", "an authorized update records it", EXIT_OK, code)
        code, _ = _run_guard(common + ["--check"])
        record("authorized-clean", "the repository passes again after authorization", EXIT_OK, code)

        (root / TEST_SCOPE / "beta_test.qml").unlink()
        code, _ = _run_guard(common + ["--check"])
        record("removed-test", "deleting an existing test is detected", EXIT_VIOLATION, code)
        (root / TEST_SCOPE / "beta_test.qml").write_text(
            "import QtQuick\n\nItem {}\n", encoding="utf-8"
        )
        code, _ = _run_guard(common + ["--update", "--authorized", "self-test fixture"])
        record("restore", "restoring the deleted test recovers a clean state", EXIT_OK, code)

        names_file.write_text("alpha_test\n", encoding="utf-8")
        code, _ = _run_guard(common + ["--check"])
        record("unregistered-name", "a missing CTest name is detected", EXIT_VIOLATION, code)
        code, _ = _run_guard(common + ["--update"])
        record(
            "name-dropped",
            "the ordinary update cannot drop a recorded CTest name",
            EXIT_VIOLATION,
            code,
        )
        names_file.write_text("alpha_test\nbeta_test\n", encoding="utf-8")

        floor_file = root / FLOOR_FILE_TEMPLATE.format(profile="selftest")
        floor_file.write_text(FLOOR_FILE_CONTENT.format(value=1), encoding="utf-8")
        code, _ = _run_guard(common + ["--check"])
        record(
            "floor-reduced",
            "a lowered test baseline is detected",
            EXIT_VIOLATION,
            code,
        )
        floor_file.write_text(FLOOR_FILE_CONTENT.format(value=99), encoding="utf-8")
        code, _ = _run_guard(common + ["--check"])
        record("floor-violated", "a suite below the floor is detected", EXIT_VIOLATION, code)
        floor_file.write_text(FLOOR_FILE_CONTENT.format(value=2), encoding="utf-8")
        code, _ = _run_guard(common + ["--check"])
        record("floor-restored", "restoring the baseline recovers a clean state", EXIT_OK, code)

        hashes_file = root / HASHES_FILE
        tampered = hashes_file.read_text(encoding="utf-8").replace(
            sha256_file(root / TEST_SCOPE / "alpha_test.py"), "0" * 64
        )
        hashes_file.write_text(tampered, encoding="utf-8")
        code, _ = _run_guard(common + ["--update"])
        record(
            "hash-tampered",
            "replacing a recorded hash is refused without authorization",
            EXIT_VIOLATION,
            code,
        )
        code, _ = _run_guard(common + ["--update", "--authorized", "self-test fixture"])
        record("hash-restored", "an authorized update restores the recorded hash", EXIT_OK, code)

        (root / TEST_SCOPE / "gamma_test.py").write_text(
            "def test_gamma():\n    assert True\n", encoding="utf-8"
        )
        code, _ = _run_guard(common + ["--check"])
        record(
            "new-test",
            "creating a new, untracked test is not a false positive",
            EXIT_OK,
            code,
        )

        _git(root, "add", f"{TEST_SCOPE}/gamma_test.py")
        code, output = _run_guard(common + ["--check"])
        record(
            "new-test-tracked",
            "a tracked test outside the manifest is reported",
            EXIT_VIOLATION,
            code,
        )
        incorporation_reported = "incorporate" in output.lower()
        code, _ = _run_guard(common + ["--update"])
        record("new-test-incorporated", "adding a new test needs no authorization", EXIT_OK, code)
        code, _ = _run_guard(common + ["--check"])
        record("new-test-clean", "the suite passes with the new test incorporated", EXIT_OK, code)

        sample_gate = root / "scripts-user/lib/sample-gate.sh"
        sample_gate.write_text("ctest --test-dir build -E flaky\n", encoding="utf-8")
        _git(root, "add", "scripts-user/lib/sample-gate.sh")
        code, _ = _run_guard(common + ["--check"])
        record("new-pattern", "a new deactivation pattern is detected", EXIT_VIOLATION, code)
        sample_gate.unlink()
        _git(root, "rm", "-q", "--cached", "scripts-user/lib/sample-gate.sh")

        gate_file = root / "scripts-user/lib/package-plasmoid.sh"
        gate_file.write_text(
            "ctest --test-dir \"$BUILD_DIR\" --parallel 4 --output-on-failure\n",
            encoding="utf-8",
        )
        code, _ = _run_guard(common + ["--check"])
        record("gate-contract", "removing the guard call breaks the gate contract",
               EXIT_VIOLATION, code)

    print("==> Test integrity self-test (temporary fixtures only)")
    failed = 0
    for code, description, expected, actual in outcomes:
        status = "PASS" if expected == actual else "FAIL"
        if status == "FAIL":
            failed += 1
        print(f"[{status}] {code}: {description} (expected {expected}, got {actual})")
    if not incorporation_reported:
        failed += 1
        print("[FAIL] new-test-tracked: the report did not explain how to incorporate it")
    print(f"Result: {'PASS' if failed == 0 else 'FAIL'} ({len(outcomes) - failed}/{len(outcomes)})")
    return EXIT_OK if failed == 0 else EXIT_VIOLATION


def command_report(args: argparse.Namespace) -> int:
    root = args.root.resolve()
    baseline = read_pattern_baseline(root / PATTERNS_FILE)
    current = scan_patterns(root)
    print("==> Test integrity report (signals only, never fails)")
    for pattern_id, relative in sorted(current):
        state = "documented" if (pattern_id, relative) in baseline else "NEW"
        print(f"[{state}] {pattern_id}: {relative}")
    print(f"Result: PASS ({len(current)} occurrence(s), {len(current - baseline)} new)")
    return EXIT_OK


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="test-integrity-guard.py",
        description=(
            "Protect the Punchi Dock test evidence layer: existing tests, the "
            "infrastructure that decides what is tested, and this mechanism's data."
        ),
        epilog=(
            "The guard stops and reports; it never authorizes a change by itself. "
            "See scripts-dev/test-integrity/README.md."
        ),
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--check", action="store_true", help="verify the protected state (default)")
    mode.add_argument("--update", action="store_true", help="record the current state")
    mode.add_argument("--report", action="store_true", help="list pattern signals without failing")
    mode.add_argument("--self-test", action="store_true", help="exercise the guard on temporary fixtures")
    parser.add_argument(
        "--authorized",
        metavar="MOTIVE",
        help="explicit user authorization that allows --update to record a destructive change",
    )
    parser.add_argument("--profile", default=None, help="platform profile (default: detected)")
    parser.add_argument(
        "--root",
        type=Path,
        default=Path("."),
        help="project root (default: current directory)",
    )
    parser.add_argument(
        "--build-dir",
        type=Path,
        default=Path(DEFAULT_BUILD_DIR),
        help=f"configured build directory used by 'ctest -N' (default: {DEFAULT_BUILD_DIR})",
    )
    parser.add_argument(
        "--ctest-names-file",
        type=Path,
        default=None,
        help="read the CTest names from a file instead of running 'ctest -N' (diagnostics and self-test)",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.profile is None:
        args.profile = detect_profile()
    try:
        if args.self_test:
            return command_self_test(args)
        if args.update:
            return command_update(args)
        if args.report:
            return command_report(args)
        return command_check(args)
    except GuardError as error:
        print(f"[ERROR] {error}", file=sys.stderr)
        return EXIT_ERROR


if __name__ == "__main__":
    sys.exit(main())
