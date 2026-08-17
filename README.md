# Punchi Dock Remastered

<p align="center">
  <img src="contents/images/punchi-dock-remastered.svg" width="160" alt="Punchi Dock Remastered logo">
</p>

<p align="center">
  <a href="https://github.com/PunchiSoft/punchi-dock-remastered/releases/tag/v0.9.7.39">
    <img src="https://img.shields.io/badge/release-v0.9.7.39-4caf50" alt="Release v0.9.7.39">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/license-GPL--3.0--or--later-blue" alt="License GPL-3.0-or-later">
  </a>
  <a href="https://www.paypal.com/donate/?hosted_button_id=HXFSZU4K8C38W">
    <img src="https://img.shields.io/badge/Donate-PayPal-0070ba" alt="Donate with PayPal">
  </a>
</p>

[English](README.md) | [Español](README.es.md)

Punchi Dock Remastered is a native launcher dock and task interface for KDE Plasma 6, designed primarily for Wayland. It can operate as a floating dock or integrate with a Plasma panel while following the active theme.

This repository is a modular rewrite of the original [Punchi Dock Plasmoid](https://github.com/PunchiSoft/punchi-dock-plasmoid). The project is currently preparing its path toward a stable 1.0 release.

The current release is
[v0.9.7.39](https://github.com/PunchiSoft/punchi-dock-remastered/releases/tag/v0.9.7.39).

## What's New in 0.9.7.39

- **Interactive QML Audit & Compilation Dashboard**: Live HTML dashboard with real-time status filters (Resolved/Pending), difficulty grades (1 to 5), and Excel export.
- **Eradication of `missing-property`**: 100% elimination of missing-property static warnings on live PipeWire thumbnails and ratcheted-down baseline.
- **Scope & Delegate Hardening**: Deterministic qualification of controller scopes, `pragma ComponentBehavior: Bound`, and typed required properties in delegates.
- **Cleaned Static False Positives**: Resolved over 270 static compilation and ki18n diagnostics with zero runtime regressions.
- **100% Validated**: Full CTest suite passed (38/38) and complete translation catalogs.

See the [0.9.7.39 changelog](CHANGELOG.md#09739---2026-08-17) for detailed release
notes and the validation performed for this version.

## Screenshots

| PunchiMenu Normal — recommended preview |
|:--:|
| <img src="Images/PunchiMenuNormal.png?v=0.9.7" alt="PunchiMenu Normal with application categories, grid, and favorites" width="760"> |

| PunchiMenu Full Screen |
|:--:|
| <img src="Images/PunchiMenuFullScreen.png?v=0.9.7" alt="PunchiMenu Full Screen application launcher" width="760"> |

| MPRIS media controls |
|:--:|
| <img src="Images/MPRIS-Controls.png" alt="MPRIS popup layouts with artwork and playback controls" width="760"> |

| Dock layouts |
|:--:|
| <img src="Images/desktop-layouts.png" alt="Punchi Dock in horizontal, vertical, and Plasma panel layouts" width="760"> |

| Folder grid | Calendar and clock |
|:--:|:--:|
| <img src="Images/MenuGrid.png" alt="Folder popup in grid view" width="300"> | <img src="Images/Calendar_clock.png" alt="Calendar and clock popup" width="300"> |

## Languages

- English is the runtime source language and fallback.
- Spanish (`es`) is the currently maintained interface translation.
- German (`de`) and Brazilian Portuguese (`pt_BR`) are included as complete
  initial interface-translation drafts. Native-speaker review remains pending
  before they are considered maintained translations.

See [the translation guide](po/README.md) for the catalog policy and
contribution requirements.

## Features

- Floating dock and Plasma panel modes.
- Pinned launchers and optional dynamic task entries.
- Custom launchers with safe preservation of commands and arguments.
- Window cards, live previews, and grouped-window controls, including a choice of cards, live thumbnails, or no preview popup.
- Configurable folders with grid, list, and detail views, plus quick notes, trash, separators, and calendar items.
- PunchiMenu application launcher with Normal and Fullscreen presentations,
  search, categories, favorites, named application folders, selective hiding,
  keyboard operation, a global shortcut, and native session actions. Compact
  remains reserved for a future version.
- Optional PipeWire audio visualizer with six styles, dynamic or Plasma-themed colors, and up to 48 visual elements.
- Plasma-themed popups with configurable opening animations, smooth preview-to-menu transitions, and continuous retargeting between dock items.
- Native application and window actions in the context menus of pinned launchers and dynamic tasks.
- Optional window-count badges for grouped applications with multiple windows.
- Contextual MPRIS media cards with artwork, track information, playback controls, and an accessible mute or restore-volume action in every card layout.
- A compact dock MPRIS item with selectable player, artwork fallback, vertical text modes, and launch-then-Play behavior.
- Circular theme/custom color controls and configurable icon spacing with explicit visual units.
- Safe file drag-and-drop onto pinned applications and the Trash, plus item-aware unpin actions for applications and folders.
- An optional MPRIS card below live window previews, revealed after the preview to preserve visual continuity.
- Asynchronous trash operations with activity, progress, completion sound, and themed KDE notifications.
- External JSON background themes stored in a managed user library, with recursive folder import, removal, and safe Plasma fallback.
- Flat 2D and shelf-style 2.5D renderers with theme-defined separators, borders, gradients, rims, and bounded glow.
- Theme-adaptive clock and calendar shadows for readability over varying backgrounds.
- Dynamic compatibility with TaskManager APIs exposed by different Plasma 6 versions.
- Portable application window icons and task matching through both application IDs and launcher URLs.
- Stable icon sizing when a Plasma panel switches between always-visible and auto-hide modes.
- Standard XDG user storage compliance: User-imported JSON themes (`~/.local/share/punchi-dock-remastered/`) and instance item configurations (`~/.config/punchi-dock/`) use isolated, atomic-write storage to prevent desktop config corruption and preserve custom data across plasmoid upgrades.
- Native C++ QML integration for application discovery, runtime services, audio analysis, and trash operations.

## Requirements

- KDE Plasma 6 or later.
- Wayland is the primary supported session.
- PipeWire is required by the optional audio visualizer.
- Fedora 44 `x86_64` is the primary prebuilt release target. Debian 13 has a separate validated build, installation, and startup flow; its complete functional review remains in progress.
- Kubuntu has a locally validated source-build and installation profile for Plasma 6.6.4. The native module must still be compiled on the Kubuntu host; this does not make another distribution's artifact compatible.
- Community users report successful operation on additional current Linux distributions with Plasma 6. These reports indicate broader compatibility, but they are not yet equivalent to a project-validated distribution profile.
- Source builds require CMake 3.22+, a C++20 compiler, Qt 6.6+, ECM/KF6 6.0+, Plasma 6.0+, and PipeWire development files, all supplied as one coherent distribution stack.
- Native binaries inside each `.plasmoid` are not universal: use the artifact labeled for the distribution where it was built.

Compatibility therefore distinguishes Fedora as the primary release target,
Debian as a separately validated profile, Kubuntu as a validated native
source-build profile, and other distributions as community-reported. A current
distribution can often build and run Punchi Dock without project changes, but
it still needs a compatible source build and lint baseline. Do not mix
repositories or replace the system Qt/KDE stack solely to meet these versions.

## Install a Release Package

End users should install a prebuilt `.plasmoid` release for the supported target platform. Development packages and a compiler are not required.

The current packaged release target is Fedora 44+ `x86_64` with KDE Plasma 6 or later.

On Fedora, `kpackagetool6` is provided by `kf6-kpackage` and is normally already available on a Plasma installation:

```bash
sudo dnf install kf6-kpackage
kpackagetool6 --type Plasma/Applet --install ./punchi-dock-remastered-0.9.7.39-fedora44-x86_64.plasmoid
```

To update an existing installation:

```bash
kpackagetool6 --type Plasma/Applet --upgrade ./punchi-dock-remastered-0.9.7.39-fedora44-x86_64.plasmoid
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
    kf6-kconfig-devel kf6-kcoreaddons-devel kf6-kglobalaccel-devel kf6-kio-devel kf6-kjobwidgets-devel \
    kf6-kservice-devel kf6-kwindowsystem-devel libplasma-devel plasma-workspace-devel \
    pipewire-devel gettext \
    zip unzip
```

On Debian or Kubuntu, install the equivalent distribution-provided Qt 6, KF6,
Plasma, PipeWire, ECM, CMake, gettext, and ZIP development packages. The Debian
wrapper was validated on Debian 13 with Qt 6.8.2; the Kubuntu source-build,
installation, startup, and functional flow was validated on Plasma 6.6.4.

Build the native module and create the artifact using the master setup script:

```bash
scripts/setup.sh
```

Or for automated non-interactive universal package generation:

```bash
scripts/setup-universal.sh
```

```text
dist/punchi-dock-remastered-<version>-<distribution>-<architecture>.plasmoid
```

The 0.9.7.39 GitHub release provides
`punchi-dock-remastered-0.9.7.39-fedora44-x86_64.plasmoid`. Universal artifacts
are published separately only after their Debian 13 build and
cross-distribution validation are complete.
Never install an artifact labeled for a different distribution.

The Debian 13 workflow was verified separately from Debian 14/testing. Kubuntu
records an independent local baseline and was verified through native build,
installation, startup, and user functional testing on Plasma 6.6.4. See
[scripts/README.md](scripts/README.md) for the setup options and the distinction
between public artifacts, local installation, and clean-source validation.

Set `PACKAGE_BUILD_TYPE` or `STRIP_BIN` only when a development workflow requires an explicit override. Never use `PACKAGE_OUTPUT_FILE` to label a Fedora binary as Debian, and do not cross-compile the native QML module for publication on another distribution.

To build, install, and restart Plasma for a local Fedora development test:

```bash
scripts/setup-fedora.sh --local-test
```

On a clean Kubuntu installation, prepare the official APT dependencies and
create the native package with:

```bash
scripts/setup-kubuntu.sh --yes
```

Add `--local-test` to install the result and restart Plasma Shell. Run this
script as the desktop user; it requests `sudo` only for APT.

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

## Support the Project

Punchi Dock Remastered is free software. Bug reports, reproducible test results, documentation improvements, translations, and code contributions are all valuable ways to support it.

Financial donations are voluntary and never required to use the project. You can support Punchi Dock Remastered through the [official PayPal donation page](https://www.paypal.com/donate/?hosted_button_id=HXFSZU4K8C38W).

## License

Punchi Dock Remastered is licensed under the [GNU General Public License v3.0 or later](LICENSE).

Copyright notices, license terms, and attribution requirements apply equally to
human and AI-assisted reuse. AI-assisted copying, modification, redistribution,
summarization, or code generation based on this project does not waive or
replace the obligation to comply with the GPL-3.0-or-later license, preserve
required notices, provide corresponding source when required, and attribute
Punchi Dock Remastered and its contributors where applicable.
