# Punchi Dock Remastered

<p align="center">
  <img src="contents/images/punchi-dock-remastered.svg" width="160" alt="Punchi Dock Remastered logo">
</p>

[English](README.md) | [Español](README.es.md)

Punchi Dock Remastered is a native launcher dock and task interface for KDE Plasma 6, designed primarily for Wayland. It can operate as a floating dock or integrate with a Plasma panel while following the active theme.

This repository is a modular rewrite of the original [Punchi Dock Plasmoid](https://github.com/PunchiSoft/punchi-dock-plasmoid). The project is currently preparing its path toward a stable 1.0 release.

## Features

- Floating dock and Plasma panel modes.
- Pinned launchers and optional dynamic task entries.
- Custom launchers with safe preservation of commands and arguments.
- Window cards, live previews, and grouped-window controls.
- Configurable folders with grid, list, and detail views, plus quick notes, trash, separators, and calendar items.
- Optional PipeWire audio visualizer with six styles, dynamic or Plasma-themed colors, and up to 48 visual elements.
- Plasma-themed popups with configurable opening animations and smooth preview-to-menu transitions.
- Native application and window actions in the context menus of pinned launchers and dynamic tasks.
- Contextual MPRIS media cards with artwork, track information, and playback controls.
- Asynchronous trash operations with activity, progress, completion sound, and themed KDE notifications.
- External JSON background themes stored in a managed user library, with recursive folder import, removal, and safe Plasma fallback.
- Flat 2D and shelf-style 2.5D renderers with theme-defined separators, borders, gradients, rims, and bounded glow.
- Theme-adaptive clock and calendar shadows for readability over varying backgrounds.
- Dynamic compatibility with TaskManager APIs exposed by different Plasma 6 versions.
- Portable application window icons and task matching through both application IDs and launcher URLs.
- Stable icon sizing when a Plasma panel switches between always-visible and auto-hide modes.
- Native C++ QML integration for application discovery, runtime services, audio analysis, and trash operations.

## Requirements

- KDE Plasma 6 or later.
- Wayland is the primary supported session.
- PipeWire is required by the optional audio visualizer.
- Fedora 44 `x86_64` is the primary prebuilt release target. Debian 13 has a separate validated build, installation, and startup flow; its complete functional review remains in progress.
- Community users report successful operation on additional current Linux distributions with Plasma 6. These reports indicate broader compatibility, but they are not yet equivalent to a project-validated distribution profile.
- Source builds require CMake 3.22+, a C++20 compiler, Qt 6.6+, ECM/KF6 6.0+, Plasma 6.0+, and PipeWire development files, all supplied as one coherent distribution stack.
- Native binaries inside each `.plasmoid` are not universal: use the artifact labeled for the distribution where it was built.

Compatibility therefore has three levels: Fedora is the primary release target, Debian is a separately validated compatibility profile, and other distributions are community-reported when they satisfy the build requirements. A newer distribution can often build and run Punchi Dock without project changes; a conservative distribution may need its own compatible source build and baseline. Do not mix repositories or replace the system Qt/KDE stack solely to meet these versions.

## Install a Release Package

End users should install a prebuilt `.plasmoid` release for the supported target platform. Development packages and a compiler are not required.

The current packaged release target is Fedora 44+ `x86_64` with KDE Plasma 6 or later.

On Fedora, `kpackagetool6` is provided by `kf6-kpackage` and is normally already available on a Plasma installation:

```bash
sudo dnf install kf6-kpackage
kpackagetool6 --type Plasma/Applet --install ./punchi-dock-remastered-0.8.9-fedora44-x86_64.plasmoid
```

To update an existing installation:

```bash
kpackagetool6 --type Plasma/Applet --upgrade ./punchi-dock-remastered-0.8.9-fedora44-x86_64.plasmoid
```

Log out and back in, or restart Plasma Shell, if the updated plasmoid is not loaded immediately.

## Build from Source

The source tree contains a native C++ QML module. Installing the repository directory directly with `kpackagetool6` does not compile that module.

Check the local development environment before installing or changing packages:

```bash
scripts/check-build-environment.sh
```

The checker reports the distribution, architecture, Plasma, CMake, and `qmllint` versions. Qt 6.11 is the primary lint profile and Qt 6.8 has a separate compatibility profile because their diagnostics differ. `qmllint` is a development tool, not a runtime dependency for users installing a matching prebuilt `.plasmoid`; a Qt 6.8 lint failure alone does not prove that the dock cannot run on that system.

Use the Qt 6, KF6, and Plasma development packages supplied by the distribution. Do not replace the system Qt stack with a standalone Qt 6.11 installation merely to match the primary lint profile, because the native module must be compiled against a coherent distribution stack.

On Fedora 44+, install the build dependencies:

```bash
sudo dnf install \
    binutils cmake gcc-c++ ninja-build extra-cmake-modules \
    qt6-qtdeclarative-devel \
    kf6-kcoreaddons-devel kf6-kio-devel kf6-kjobwidgets-devel \
    kf6-kservice-devel libplasma-devel \
    pipewire-devel gettext \
    zip unzip
```

On Debian, install the equivalent Qt 6, KF6, Plasma, PipeWire, CMake, and ZIP development packages. The Debian wrapper was validated on Debian 13 with Qt 6.8.2.

Build the native module and create the versioned artifact for the current system:

```bash
scripts/empaquetar-plasmoid.sh
```

The automated packaging script currently detects Fedora or Debian through `/etc/os-release`. Other current Plasma 6 distributions have been reported to work when the requirements above are available, but they do not yet have a validated automatic packaging profile in this repository. Treat those reports as community compatibility: build and test against the host distribution and do not relabel a Fedora or Debian native artifact. The supported profiles write an unambiguous package name:

```text
dist/punchi-dock-remastered-<version>-<distribution><version>-<architecture>.plasmoid
```

Examples include `punchi-dock-remastered-0.8.9-fedora44-x86_64.plasmoid` and `punchi-dock-remastered-0.8.9-debian13-x86_64.plasmoid`. Never install a Fedora-labeled artifact on Debian or vice versa.

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
