# Punchi Dock Remastered

[English](README.md) | [Español](README.es.md)

Punchi Dock Remastered is a native launcher dock and task interface for KDE Plasma 6, designed primarily for Wayland. It can operate as a floating dock or integrate with a Plasma panel while following the active theme.

This repository is a modular rewrite of the original [Punchi Dock Plasmoid](https://github.com/PunchiSoft/punchi-dock-plasmoid). The project is currently preparing its path toward a stable 1.0 release.

## Features

- Floating dock and Plasma panel modes.
- Pinned launchers and optional dynamic task entries.
- Window cards, live previews, and grouped-window controls.
- Configurable folders, quick notes, trash, separators, and calendar items.
- Optional PipeWire audio visualizer with six styles, dynamic or Plasma-themed colors, and up to 48 visual elements.
- Plasma-themed popups with configurable opening animations and smooth preview-to-menu transitions.
- Native application and window actions in the context menus of pinned launchers and dynamic tasks.
- Contextual MPRIS media cards with artwork, track information, and playback controls.
- Asynchronous trash operations with activity, progress, completion sound, and themed KDE notifications.
- Native C++ QML integration for application discovery, runtime services, audio analysis, and trash operations.

## Requirements

- Fedora 44 or later on `x86_64` is the current release target.
- KDE Plasma 6 or later.
- Wayland is the primary supported session.
- PipeWire is required by the optional audio visualizer.
- Native binaries shipped inside the `.plasmoid` package are currently built and validated for Fedora 44+ `x86_64`, not as a universal Linux binary for every Plasma-based distribution.

## Install a Release Package

End users should install a prebuilt `.plasmoid` release for the supported target platform. Development packages and a compiler are not required.

The current packaged release target is Fedora 44+ `x86_64` with KDE Plasma 6 or later.

On Fedora, `kpackagetool6` is provided by `kf6-kpackage` and is normally already available on a Plasma installation:

```bash
sudo dnf install kf6-kpackage
kpackagetool6 --type Plasma/Applet --install ./punchi-dock-remastered-0.8.6-fedora44-x86_64.plasmoid
```

To update an existing installation:

```bash
kpackagetool6 --type Plasma/Applet --upgrade ./punchi-dock-remastered-0.8.6-fedora44-x86_64.plasmoid
```

Log out and back in, or restart Plasma Shell, if the updated plasmoid is not loaded immediately.

## Build from Source on Fedora 44+ `x86_64`

The source tree contains a native C++ QML module. Installing the repository directory directly with `kpackagetool6` does not compile that module.

Install the build dependencies:

```bash
sudo dnf install \
    binutils cmake gcc-c++ ninja-build extra-cmake-modules \
    qt6-qtdeclarative-devel \
    kf6-kcoreaddons-devel kf6-kio-devel kf6-kjobwidgets-devel \
    kf6-kservice-devel libplasma-devel \
    pipewire-devel \
    zip unzip
```

Build the native module and create the versioned artifact for the current system:

```bash
scripts/empaquetar-plasmoid.sh
```

The script detects Fedora or Debian through `/etc/os-release`. It writes an unambiguous package name:

```text
dist/punchi-dock-remastered-<version>-<distribution><version>-<architecture>.plasmoid
```

Examples include `punchi-dock-remastered-0.8.6-fedora44-x86_64.plasmoid` and `punchi-dock-remastered-0.8.6-debian13-x86_64.plasmoid`. Never install a Fedora-labeled artifact on Debian or vice versa.

Explicit wrappers remain available for automation and diagnostics:

```bash
scripts/build-fedora-package.sh
scripts/build-debian-package.sh
```

Each wrapper requires its matching distribution and uses its own baseline. The Debian workflow was verified on Debian 13, where the artifact installed and loaded correctly. See [scripts/README.md](scripts/README.md) for the distinction between packaging, local installation, and clean-source validation.

Set `PACKAGE_BUILD_TYPE` or `STRIP_BIN` only when a development workflow requires an explicit override. Never use `PACKAGE_OUTPUT_FILE` to label a Fedora binary as Debian, and do not cross-compile the native QML module for publication on another distribution.

To build, install, and restart Plasma for a local development test:

```bash
scripts/probar-plasmoid.sh
```

This script runs the packaging checks and CTest, upgrades the local plasmoid, restarts Plasma Shell, and writes filtered startup diagnostics to `debug.log`. Because it restarts the desktop shell, use it after a coherent change rather than on every file save.

Before publishing a release, reproduce the package from a clean temporary source tree:

```bash
scripts/validar-empaquetado-limpio.sh
```

For rapid visual iteration, `scripts/watch-plasmoidviewer.sh` can rebuild and reopen `plasmoidviewer` when files change. It does not replace a final test in the real Plasma panel or dock.

## Project Structure

- `contents/`: runtime plasmoid package.
- `contents/ui/components/`: reusable QML interface components.
- `contents/code/`: shared JavaScript logic and defaults.
- `src/`: native C++ QML integration module.
- `scripts/`: packaging and local testing tools.
- `metadata.json`: KPackage metadata and Plasma compatibility declaration.

Internal development notes and audit logs are intentionally excluded from the public repository and release package.

## License

Punchi Dock Remastered is licensed under the [GNU General Public License v3.0 or later](LICENSE).
