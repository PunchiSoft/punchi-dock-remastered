#!/usr/bin/env python3

from pathlib import Path
import unittest


PROJECT_ROOT = Path(__file__).resolve().parents[1]


class CMakeInstallContractTest(unittest.TestCase):
    def test_standard_install_covers_kpackage_native_module_and_translations(self):
        root_cmake = (PROJECT_ROOT / "CMakeLists.txt").read_text(encoding="utf-8")
        native_cmake = (PROJECT_ROOT / "src" / "CMakeLists.txt").read_text(
            encoding="utf-8"
        )

        self.assertIn("PUNCHI_PLASMOID_INSTALL_DIR", root_cmake)
        self.assertIn("DIRECTORY contents/", root_cmake)
        self.assertIn("FILES metadata.json LICENSE", root_cmake)
        self.assertIn("PUNCHI_TRANSLATION_DOMAIN", root_cmake)
        self.assertIn("GETTEXT_MSGFMT_EXECUTABLE", root_cmake)
        self.assertIn("${KDE_INSTALL_LOCALEDIR}/${language}/LC_MESSAGES", root_cmake)
        self.assertIn("ecm_finalize_qml_module", native_cmake)

    def test_per_user_mode_embeds_the_native_module_inside_the_kpackage(self):
        root_cmake = (PROJECT_ROOT / "CMakeLists.txt").read_text(encoding="utf-8")
        native_cmake = (PROJECT_ROOT / "src" / "CMakeLists.txt").read_text(
            encoding="utf-8"
        )
        assistant = (PROJECT_ROOT / "scripts-cmake" / "setup.sh").read_text(
            encoding="utf-8"
        )

        option_name = "PUNCHI_EMBED_QML_MODULE_IN_KPACKAGE"
        self.assertIn(option_name, root_cmake)
        self.assertIn(f"if({option_name})", native_cmake)
        self.assertIn(
            "${PUNCHI_PLASMOID_INSTALL_DIR}/contents/ui/org/punchi/dock",
            native_cmake,
        )
        self.assertIn(
            'DESTINATION "${PUNCHI_PLASMOID_INSTALL_DIR}/contents/ui"',
            native_cmake,
        )
        self.assertIn(f"-D{option_name}=ON", assistant)

    def test_optional_helpers_do_not_select_a_distribution_or_package_manager(self):
        helper_dir = PROJECT_ROOT / "scripts-cmake"
        helper_text = "\n".join(
            path.read_text(encoding="utf-8")
            for path in sorted(helper_dir.glob("*.sh"))
        )

        for forbidden in ("/etc/os-release", "dnf", "apt-get", "pacman", "sudo"):
            self.assertNotIn(forbidden, helper_text)


if __name__ == "__main__":
    unittest.main()
