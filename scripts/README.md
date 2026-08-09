# Packaging and Setup Scripts

[English](README.md) | [Español](README.es.md)

## Master Setup Assistant (`scripts/setup.sh`)

The primary entry point for building, testing, installing, and managing Punchi Dock Remastered is:

```bash
scripts/setup.sh
```

Running `scripts/setup.sh` without arguments launches an **accessible interactive terminal menu** that auto-detects your host Linux distribution (Fedora or Debian 13).

```text
==========================================================
   Punchi Dock Remastered - Master Setup Assistant        
==========================================================
Detected host: Fedora Linux 44 (x86_64)

What would you like to do?
  [1] Build official release package (Release in dist/)
  [2] Build, install and test locally (--local-test)
  [3] Install an existing .plasmoid package from dist/
  [4] Clean install (remove current + rebuild + install)
  [5] Check and install build dependencies only
  [6] Uninstall the plasmoid from this system
  [7] Help (show CLI commands reference)
  [8] Exit
```

### Language Auto-Detection & Override (`PUNCHI_LANG`)

The setup assistant automatically detects your system locale (`LC_ALL` / `LC_MESSAGES` / `LANG`). You can also force a specific language using `PUNCHI_LANG`:

```bash
PUNCHI_LANG=en ./scripts/setup.sh    # Force English interface
PUNCHI_LANG=es ./scripts/setup.sh    # Force Spanish interface
```

### CLI Command Mode

You can pass flags directly for non-interactive execution, terminal scripts, or CI automation:

```bash
# Build and install for immediate local testing on your desktop
scripts/setup.sh --local-test

# Clean install: remove existing installation, clear build cache, rebuild & install
scripts/setup.sh --clean-install

# Check and install required build dependencies (DNF/APT) without building
scripts/setup.sh --dependencies-only

# Uninstall the plasmoid from your Plasma desktop environment
scripts/setup.sh --uninstall

# Pass automatic 'yes' to package manager prompts (DNF/APT)
scripts/setup.sh --yes --local-test

# Dry-run mode: pre-view planned commands without altering the system
scripts/setup.sh --dry-run

# Show full help and command usage
scripts/setup.sh --help

# Install a pre-built .plasmoid package directly without rebuilding
scripts/setup.sh dist/punchi-dock-remastered-0.9.7-fedora44-x86_64.plasmoid
```

---

## Build Targets & Distribution Matrix

| Host Distribution | Target Profile | Expected Artifact Output |
|---|---|---|
| **Fedora 44+** (`x86_64`) | Fedora Native | `dist/punchi-dock-remastered-<version>-fedora44-x86_64.plasmoid` |
| **Debian 13 (Trixie)** (`x86_64`) | KDE Store Universal | `dist/punchi-dock-remastered-<version>-universal.plasmoid` *(With `$ORIGIN/compat` dynamic library redirection)* |
| **Local Test (Any Host)** | Distro Test Build | `dist/punchi-dock-remastered-<version>-<distro>-x86_64-local-test.plasmoid` |

---

## Persistent Setup Logging System

All executions of `scripts/setup.sh` (interactive or CLI mode) automatically route output through `scripts/lib/setup-logging.sh` (`punchi_run_setup_with_log`).

Logs are saved under:
```text
docs/logs/<distribution>/
```

- **Timestamped log**: `setup-<distro>-YYYYMMDD-HHMMSS.log`
- **Latest execution**: `setup-<distro>-latest.log`

---

## Check Build Environment

To diagnose system libraries, Qt 6, KDE Frameworks 6, and `qmllint` baseline calibration without modifying your system:

```bash
scripts/check-build-environment.sh
```

---

## Developer Utility Tools (`scripts/dev/`)

- `scripts/dev/instalar-plasmoide.sh`: Interactive selector to install active pre-compiled `.plasmoid` artifacts from `dist/`.
- `scripts/dev/validar-empaquetado-limpio.sh`: Performs a clean temporary build copy validation without installing.
- `scripts/dev/update-translations.sh`: Regenerates POT templates and updates PO catalogs under `po/`.
- `scripts/dev/watch-plasmoidviewer.sh`: Development helper to launch `plasmoidviewer` for UI previewing.

---

## Internal Architecture & Script Tree

- `scripts/setup.sh`: Master interactive CLI orchestrator with i18n (English/Spanish).
- `scripts/setup-universal.sh`: Non-building universal `.plasmoid` package installer.
- `scripts/distro/`: Distribution profile scripts (`fedora-setup.sh`, `debian13-setup.sh`, etc.).
- `scripts/lib/`: Shared core packaging engines (`package-plasmoid.sh`, `install-local-test.sh`, `local-package-install.sh`, `setup-logging.sh`).
- `scripts/dev/`: Developer tools and diagnostic utilities.
