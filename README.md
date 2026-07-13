# Punchi Dock Remastered

[English](README.md) | [Español](README.es.md)

Punchi Dock Remastered is a native launcher dock and task interface for KDE Plasma 6, designed primarily for Wayland. It can operate as a floating dock or integrate with a Plasma panel while following the active theme.

This repository is a modular rewrite of the original [Punchi Dock Plasmoid](https://github.com/PunchiSoft/punchi-dock-plasmoid). The project is currently preparing its path toward a stable 1.0 release.

## Features

- Floating dock and Plasma panel modes.
- Pinned launchers and optional dynamic task entries.
- Window cards, live previews, and grouped-window controls.
- Configurable folders, quick notes, trash, separators, and calendar items.
- Plasma-themed popups and a compact configuration interface.
- Native C++ QML integration for application discovery, runtime services, and trash operations.

## Requirements

- Linux with KDE Plasma 6.
- Wayland is the primary supported session.
- Fedora 44 or later is the main development and testing environment.

## Install a Release Package

End users should install a prebuilt `.plasmoid` release. Development packages and a compiler are not required.

On Fedora, `kpackagetool6` is provided by `kf6-kpackage` and is normally already available on a Plasma installation:

```bash
sudo dnf install kf6-kpackage
kpackagetool6 --type Plasma/Applet --install ./punchi-dock-remastered.plasmoid
```

To update an existing installation:

```bash
kpackagetool6 --type Plasma/Applet --upgrade ./punchi-dock-remastered.plasmoid
```

Log out and back in, or restart Plasma Shell, if the updated plasmoid is not loaded immediately.

## Build from Source on Fedora 44+

The source tree contains a native C++ QML module. Installing the repository directory directly with `kpackagetool6` does not compile that module.

Install the build dependencies:

```bash
sudo dnf install \
    cmake gcc-c++ ninja-build extra-cmake-modules \
    qt6-qtdeclarative-devel \
    kf6-kcoreaddons-devel kf6-kio-devel kf6-kservice-devel \
    zip unzip
```

Build the native module and create the package:

```bash
PATH="/usr/lib64/qt6/bin:$PATH" scripts/empaquetar-plasmoid.sh
```

The resulting package is written to:

```text
dist/punchi-dock-remastered.plasmoid
```

To build, install, and restart Plasma for a local development test:

```bash
PATH="/usr/lib64/qt6/bin:$PATH" scripts/probar-plasmoid.sh
```

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
