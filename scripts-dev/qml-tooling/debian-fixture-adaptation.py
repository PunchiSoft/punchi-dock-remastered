#!/usr/bin/env python3
"""Apply the user-authorized fixture prerequisites only in the Debian copy."""

import argparse
import difflib
from pathlib import Path

# Reviewed on 2026-10-04; existing assertions and warning policies stay intact.
CHANGES = [('tests/recentapplicationsadapter_test.cpp',
  [('        const QString applications = '
    'QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation);',
    '        const QString menuDirectory = '
    'QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + '
    'QStringLiteral("/menus");\n'
    '        const QString menuPrefix = QString::fromLocal8Bit(qgetenv("XDG_MENU_PREFIX"));\n'
    "        if (menuPrefix.contains(QLatin1Char('/')) || "
    'menuPrefix.contains(QLatin1Char(\'\\\\\'))) { qFatal("Invalid menu fixture prefix"); }\n'
    '        if (!QDir().mkpath(menuDirectory)) { qFatal("Could not create the menu fixture '
    'directory"); }\n'
    "        QFile menu(menuDirectory + QLatin1Char('/') + menuPrefix + "
    'QStringLiteral("applications.menu"));\n'
    '        if (!menu.open(QIODevice::WriteOnly)) { qFatal("Could not write the application menu '
    'fixture"); }\n'
    '        const QByteArray menuContent = "<!DOCTYPE Menu PUBLIC \\"-//freedesktop//DTD Menu '
    '1.0//EN\\" '
    '\\"http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd\\">\\n<Menu><Name>Applications</Name><DefaultAppDirs/><Include><All/></Include></Menu>\\n";\n'
    '        if (menu.write(menuContent) != menuContent.size()) { qFatal("Could not complete the '
    'application menu fixture"); }\n'
    '        menu.close();\n'
    '        const QString applications = '
    'QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation);')]),
 ('tests/recent_applications_full_load_test.cpp',
  [('        previousHandler = qInstallMessageHandler(capture);',
    '        const QString containmentPackage = root + '
    'QStringLiteral("/data/plasma/plasmoids/org.example.punchi.containment-fixture");\n'
    '        if (!QDir().mkpath(containmentPackage + QStringLiteral("/contents/ui"))) { '
    'qFatal("Could not create the containment fixture"); }\n'
    '        QFile containmentMetadata(containmentPackage + QStringLiteral("/metadata.json"));\n'
    '        if (!containmentMetadata.open(QIODevice::WriteOnly)) { qFatal("Could not write the '
    'containment fixture metadata"); }\n'
    '        '
    'containmentMetadata.write(R"({"KPlugin":{"Id":"org.example.punchi.containment-fixture","Name":"Containment '
    'Fixture"},"KPackageStructure":"Plasma/Applet","X-Plasma-API-Minimum-Version":"6.0","X-Plasma-ContainmentType":"Custom"})");\n'
    '        containmentMetadata.close();\n'
    '        QFile containmentMain(containmentPackage + QStringLiteral("/contents/ui/main.qml"));\n'
    '        if (!containmentMain.open(QIODevice::WriteOnly)) { qFatal("Could not write the '
    'containment fixture main file"); }\n'
    '        containmentMain.write("import org.kde.plasma.plasmoid\\nContainmentItem {}\\n");\n'
    '        containmentMain.close();\n'
    '        previousHandler = qInstallMessageHandler(capture);'),
   ('corona.createContainment(QStringLiteral("null"))',
    'corona.createContainment(QStringLiteral("org.example.punchi.containment-fixture"))')]),
 ('tests/media_player_options_panel_test.qml',
  [('        mouseClick(combo)\n        wait(20)',
    '        verify(waitForRendering(combo))\n'
    '        host.requestActivate()\n'
    '        tryVerify(function() { return host.active }, 2000)\n'
    '        mouseClick(combo)\n'
    '        wait(20)')])]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", required=True, type=Path)
    parser.add_argument("--evidence-root", required=True, type=Path)
    arguments = parser.parse_args()
    source = arguments.source_root.resolve()
    evidence = arguments.evidence_root.resolve()
    if source.name != "source" or not source.parent.name.startswith("debian-qt68-"):
        parser.error("A disposable Debian source copy is required")
    if source.parent.parent != evidence:
        parser.error("Evidence must belong to the parent of the disposable tree")
    changes = []
    differences = []
    for relative, replacements in CHANGES:
        path = source / relative
        original = path.read_text()
        updated = original
        for before, after in replacements:
            if updated.count(before) != 1:
                parser.error(f"Review the changed fixture before adapting {relative}")
            updated = updated.replace(before, after)
        changes.append((path, updated))
        differences.extend(difflib.unified_diff(
            original.splitlines(keepends=True), updated.splitlines(keepends=True),
            fromfile="a/" + relative, tofile="b/" + relative))
    # Validate all contexts before applying any change.
    (evidence / "qt68-copy-fixtures.diff").write_text("".join(differences))
    for path, updated in changes:
        path.write_text(updated)
    print("==> Applied three authorized Debian fixture prerequisites")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
