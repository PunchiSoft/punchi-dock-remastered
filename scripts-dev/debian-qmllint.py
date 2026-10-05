#!/usr/bin/env python3
"""Run Debian Qt 6.8 lint with reflected Plasma types and the local module build."""

from __future__ import annotations

import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

PROJECT_ROOT = Path(__file__).resolve().parent.parent
NATIVE_LINT = os.environ.get("PUNCHI_DEBIAN_QMLLINT_BIN", "/usr/lib/qt6/bin/qmllint")


def configuration_metadata() -> str:
    """Describe dynamic keys from the authoritative KConfig schema."""
    types = {"Bool": "bool", "Int": "int", "UInt": "uint", "Double": "double",
             "String": "QString", "StringList": "QStringList", "Color": "QColor",
             "LongLong": "qlonglong", "ULongLong": "qulonglong"}
    lines = ['Component { name: "KConfigPropertyMap"; accessSemantics: "reference";',
             'prototype: "QObject"', 'Method { name: "writeConfig" }',
             'Method { name: "isImmutable"; type: "bool";',
             'Parameter { name: "key"; type: "QString" } }']
    entries = ET.parse(PROJECT_ROOT / "contents/config/main.xml").findall(".//{*}entry")
    if not entries:
        raise ValueError("The KConfig schema contains no entries")
    names: set[str] = set()
    for entry in entries:
        name = entry.attrib["name"]
        if name in names:
            raise ValueError(f"Duplicate KConfig entry: {name}")
        names.add(name)
        declared_type = entry.attrib["type"]
        if declared_type not in types:
            raise ValueError(f"Unsupported KConfig type: {declared_type}")
        lines.append(f"Property {{ name: {json.dumps(name)}; "
                     f"type: {json.dumps(types[declared_type])} }}")
    return "\n".join(lines + ["}"])


def ui_root(path: Path) -> Path:
    """Locate the full UI tree, including an existing isolated lint copy."""
    for parent in path.parents:
        if parent.name == "ui" and (parent / "main.qml").is_file():
            return parent
    raise ValueError(f"QML input is outside a complete UI tree: {path}")


def main(arguments: list[str]) -> int:
    version = subprocess.check_output([NATIVE_LINT, "--version"], text=True).strip()
    if arguments in (["--version"], ["-v"]) or "6.8." not in version:
        return subprocess.run([NATIVE_LINT, *arguments]).returncode
    inputs = [Path(arg).resolve() for arg in arguments if arg.endswith(".qml")]
    if not inputs:
        return subprocess.run([NATIVE_LINT, *arguments]).returncode
    roots = {ui_root(path) for path in inputs}
    if len(roots) != 1:
        raise ValueError("QML inputs must belong to one complete UI tree")
    source_ui = roots.pop()
    display_ui = next(parent for arg in arguments if arg.endswith(".qml")
                      for parent in Path(arg).parents if parent.resolve() == source_ui)
    build = Path(os.environ.get("BUILD_DIR", PROJECT_ROOT / "build/debian13-local-validation"))
    build = build.resolve()
    module = build / "bin/org/punchi/dock"
    for name in ("qmldir", "punchidockintegration.qmltypes"):
        if not (module / name).is_file():
            raise ValueError(f"Build the native module before lint: missing {module / name}")
    tooling_build = build / "debian-qml-tooling"
    subprocess.run(["cmake", "-S", str(PROJECT_ROOT / "scripts-dev/qml-tooling"),
                    "-B", str(tooling_build)], check=True, stdout=sys.stderr)
    subprocess.run(["cmake", "--build", str(tooling_build), "--parallel", "2"],
                   check=True, stdout=sys.stderr)
    with tempfile.TemporaryDirectory(prefix="debian-qml-types-", dir=build) as directory:
        temporary = Path(directory)
        environment = os.environ.copy()
        for variable, name in (("XDG_DATA_HOME", "data"), ("XDG_CONFIG_HOME", "config"),
                               ("XDG_CACHE_HOME", "cache"), ("XDG_RUNTIME_DIR", "runtime")):
            location = temporary / name
            location.mkdir(mode=0o700)
            environment[variable] = str(location)
        environment.update(QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software")
        environment["PUNCHI_TOOLING_ENVIRONMENT_ROOT"] = str(temporary)
        result = subprocess.run([str(tooling_build / "export-plasmoid-types")],
                                env=environment, check=True, capture_output=True, text=True,
                                timeout=15)
        sys.stderr.write(result.stderr)
        metadata = result.stdout
        if not metadata.rstrip().endswith("}"):
            raise ValueError("The Plasma metadata exporter produced invalid output")
        metadata = metadata[:metadata.rfind("}")] + configuration_metadata() + "\n}\n"
        import_root = temporary / "imports"
        plasmoid = import_root / "org/kde/plasma/plasmoid"
        plasmoid.mkdir(parents=True)
        (plasmoid / "types.qmltypes").write_text(metadata)
        (plasmoid / "qmldir").write_text(
            "module org.kde.plasma.plasmoid\ntypeinfo types.qmltypes\ndepends QtQuick\n")
        copied_ui = temporary / "ui"
        shutil.copytree(source_ui, copied_ui)
        shutil.copytree(source_ui.parent / "code", temporary / "code")
        for name in ("qmldir", "punchidockintegration.qmltypes"):
            shutil.copyfile(module / name, copied_ui / "org/punchi/dock" / name)
        mapped_arguments = [str(copied_ui / Path(arg).resolve().relative_to(source_ui))
                            if arg.endswith(".qml") else arg for arg in arguments]
        lint = subprocess.run([NATIVE_LINT, "-I", str(import_root), *mapped_arguments],
                              capture_output=True, text=True)
        # The complete output is preserved; only disposable source paths are mapped.
        for output, stream in ((lint.stdout, sys.stdout), (lint.stderr, sys.stderr)):
            stream.write(output.replace(str(copied_ui), str(display_ui)))
        return lint.returncode


if __name__ == "__main__":
    def interrupt(number: int, _frame: object) -> None:
        # subprocess.run kills and waits for its child on a raised exception;
        # TemporaryDirectory then cleans the tree after the child has exited.
        raise KeyboardInterrupt

    signal.signal(signal.SIGTERM, interrupt)
    try:
        sys.exit(main(sys.argv[1:]))
    except KeyboardInterrupt:
        sys.exit(130)
    except (OSError, ValueError, subprocess.SubprocessError, ET.ParseError) as error:
        print(f"Error preparing Debian QML metadata: {error}", file=sys.stderr)
        sys.exit(2)
