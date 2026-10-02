# Punchi Dock Remastered

<p align="center">
  <img src="contents/images/punchi-dock-remastered.svg" width="120" alt="Punchi Dock Remastered logo">
</p>

<p align="center">
  <a href="https://github.com/PunchiSoft/punchi-dock-remastered/releases/latest"><img src="https://img.shields.io/github/v/release/PunchiSoft/punchi-dock-remastered?label=release" alt="Latest published release"></a>
  <a href="metadata.json"><img src="https://img.shields.io/badge/KDE_Plasma-6-blue" alt="KDE Plasma 6"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0--or--later-blue" alt="License GPL-3.0-or-later"></a>
</p>

[English](README.md) | [Español](README.es.md) | [Deutsch](README.de.md) | [Português (Brasil)](README.pt_BR.md)

Punchi Dock Remastered brings application launchers, running windows, folders,
media controls, and desktop utilities together in a customizable dock for KDE
Plasma 6. Use it as a floating dock or inside a Plasma panel, horizontally or
vertically, with the active Plasma theme or a custom background.

It includes PunchiMenu for finding and organizing applications and is a modular
rewrite of the original [Punchi Dock Plasmoid](https://github.com/PunchiSoft/punchi-dock-plasmoid).
The project is in active development toward version 1.0.

[Features](#features) · [Screenshots](#screenshots) · [Installation](#installation) · [Compatibility](#compatibility) · [Testing](#testing-and-quality) · [Support](#support-and-contributing)

<p align="center">
  <img src="Images/dock-presentation-20261001.png" width="900" alt="Punchi Dock Remastered illustration: MPRIS, PunchiMenu, Fan folders, and JSON themes with zoom">
</p>

<p align="center"><em>Illustration</em></p>

This README describes the current source tree. Downloadable packages follow
their [release notes](https://github.com/PunchiSoft/punchi-dock-remastered/releases);
features marked as development may not be included in the latest release.

## Features

### Applications and windows

- **Launchers and running applications:** Pin applications, add custom launchers
  or terminal commands, reorder items, and display an optional running-app section.
- **Window controls:** Work with grouped windows, application actions, window-count
  badges, desktop filtering, and configurable cards or live window thumbnails.
- **Recent applications — development:** Optionally show up to three recent
  applications as dock icons or in a container. Pinned applications and those
  with open windows are excluded. The feature is off by default and uses the
  history recorded by KDE; availability depends on the applications reported.

### Folders and application collections

- **Four presentations:** Choose Grid, List, Detailed, or Fan, with configurable
  icons, labels, typography, scale, and opening animations.
- **Flexible content:** Create manual collections, populate them from installed
  application categories, or open entries from a filesystem folder.
- **Direct interaction:** Drop launchers from PunchiMenu or the desktop, switch
  presentation from the context menu, and open the backing folder in Dolphin.

### PunchiMenu

- **Find applications:** Search, browse categories, keep favorites, organize named
  folders, and hide selected applications.
- **Choose a layout:** Use a Normal floating menu or the Fullscreen presentation.
- **Keyboard access:** Navigate with visible focus, use a configurable global
  shortcut, and access native KDE session actions.

### Media and desktop utilities

- **Media controls:** Control compatible MPRIS players with artwork, track
  information, playback actions, player selection, and a compact dock item.
- **Audio visualizer (EQ):** Displays the system's output spectrum through PipeWire behind the dock icons, in floating and Plasma panel modes, horizontally or vertically. Choose six visual styles, Plasma theme or dynamic colors, intensity, and movement direction. It can appear over the Plasma background or replace it with the spectrum alone. This is a visual effect; it does not change the sound.
- **Everyday utilities:** Add Trash, calendar and clock, quick notes, and separators.
  Trash operations include progress and KDE notifications.
- **Control Center — preliminary:** Access surfaces for Wi-Fi, Bluetooth, audio,
  brightness, Night Light, notifications, and frequent system actions. This
  component remains in development; advanced settings use official KDE modules.

### Appearance and interaction

- Native Plasma panel support with automatically calculated zoom.
- **Plasma integration:** Adapt to light and dark themes, with themed popup
  surfaces, shadows, and blur where supported.
- **Custom appearance:** Choose flat 2D or shelf-style 2.5D backgrounds, external
  JSON themes, indicators, labels, spacing, and hover effects.
- **Live configuration:** Apply preferences without restarting Plasma Shell,
  while preserving keyboard navigation, accessible names, scaling, and reduced motion.

### Drag and drop

- **Dock:** Reorder items, pin application launchers from PunchiMenu or the desktop, add applications to manual containers, and drop local files onto compatible applications or Trash.
- **PunchiMenu:** In Normal and Fullscreen modes, reorder applications and folders with manual ordering, create folders by dropping one application onto another, add applications to existing folders, and drag launchers out to the dock or desktop.

## Screenshots

<p align="center">
  <img src="Images/dock-layouts-20261001.png" width="900" alt="Vertical dock and two horizontal docks, with and without a JSON theme">
</p>

### MPRIS

<p align="center">
  <img src="Images/mpris-presentations-eq-20261002.png" width="900" alt="MPRIS media cards with artwork and playback controls">
</p>

<p align="center"><em>Illustration</em></p>

### Folder popups

<p align="center">
  <img src="Images/popup-presentations-20261002.png" width="900" alt="Illustrated overview of folder presentations: Fan at upper left, Detailed at upper right, List at lower left, and Grid at lower right">
</p>

<p align="center"><em>Illustration</em></p>

<details>
<summary>PunchiMenu, media controls, and desktop layouts</summary>

| PunchiMenu Normal | PunchiMenu Fullscreen — early preview |
|:--:|:--:|
| <img src="Images/punchimenu-normal-20261001.png" width="430" alt="PunchiMenu Normal with search, applications, and favorites"> | <img src="Images/punchimenu-fullscreen-20261001.png" width="430" alt="Early preview of PunchiMenu Fullscreen"> |

<p align="center">
  <img src="Images/punchimenu-compact-20261001.png" width="260" alt="PunchiMenu Compact">
</p>

<p align="center">
  <img src="Images/folder-presentations-20261001.png" width="900" alt="Illustrated overview of folder presentations: Fan at upper left, Detailed at upper right, List at lower left, and Grid at lower right">
</p>

Illustrative composition of the Fan, Detailed, List, and Grid presentations,
based on desktop captures from October 1, 2026.

</details>

## Installation

### Prebuilt package

For a prebuilt package, choose an asset for your system from
[GitHub Releases](https://github.com/PunchiSoft/punchi-dock-remastered/releases).
Install or update it from a checkout of this repository:

```bash
./scripts-user/setup-universal.sh --no-restart path/to/package.plasmoid
```

Alternatively, install with `kpackagetool6 --type Plasma/Applet --install path/to/package.plasmoid`;
use `--upgrade` instead of `--install` to update an existing installation.
### Download, build, and install from source

1. **Download the source code**

   ```bash
   git clone https://github.com/PunchiSoft/punchi-dock-remastered.git
   ```

2. **Enter the project folder**

   ```bash
   cd punchi-dock-remastered
   ```

3. **Check build dependencies**

   ```bash
   ./scripts-user/setup.sh --check-deps
   ```

4. **Build and install**

   ```bash
   ./scripts-user/setup.sh --install --no-restart
   ```

Then add Punchi Dock Remastered through Plasma's Add Widgets interface. If an
updated native module remains loaded, log out and back in to load the new version.

### Which script should I use?

- **User scripts (`scripts-user/`):** Build, package, or install the dock for everyday use, without running developer tests or QML lint. Build dependencies and package checks still apply.
- **Developer scripts (`scripts-dev/`):** Validate changes before contribution or distribution, with QML lint, CTest, translation, test-integrity, and package checks.

Run these commands from the repository root as your desktop user.

| Goal | Command | What it does |
|---|---|---|
| Install a downloaded package | `./scripts-user/setup-universal.sh --no-restart path/to/package.plasmoid` | Installs or updates the package without restarting Plasma; no compiler required. |
| Build and install from source | `./scripts-user/setup.sh --install --no-restart` | Checks dependencies, builds, and installs for the current system without running developer tests. |
| Build a package only | `./scripts-user/setup.sh --build-only --jobs 4` | Creates a local package in `dist/` without installing it. |
| Choose an operation interactively | `./scripts-user/setup.sh` | Offers build, package installation, removal, restart, and concurrency options. |
| Use the developer workflow | `./scripts-dev/setup.sh` | Opens the strict build, validation, and packaging assistant; dependency preparation may request sudo. |
| Test an installation in Plasma | `./scripts-dev/setup.sh --local-test` | Builds, validates, installs, restarts Plasma Shell, and collects startup diagnostics. |

Local builds target the current system; they are not automatically universal
packages. Full options and dependency information are documented in
[user scripts](scripts-user/README.md) and [developer scripts](scripts-dev/README.md).

## Compatibility

- **Desktop:** Linux with KDE Plasma 6; Wayland is the primary target, with a
  secondary X11 path.
- **Declared build minimums:** CMake 3.22, a C++20 compiler, Qt 6.6, KDE Frameworks
  6.0, and Plasma 6.0, plus the required development libraries.
- **Native builds:** Development builds primarily target Fedora 44 and later and use the host system's Qt and KDE libraries. Build profiles for Arch Linux and Debian 13 are also available.
- **Universal package:** Official universal builds are compiled on Debian 13. Binary compatibility must be checked with the same package on each target system.
- **Quality checks:** The observed test environment is Fedora 44, Qt 6.11.2, Plasma 6.7.5, KDE Frameworks 6.30.0, GCC 16.2.1, and CMake 4.3.0. These results apply to that environment; later versions and other distributions require their own validation.
- **Native packages:** Use the package intended for your environment. Declared
  minimums do not certify every combination, and cross-distribution binary
  compatibility requires testing the same artifact on each target system.
- **Audio:** The optional visualizer consumes PipeWire; source builds require
  its development files.
- **Languages:** English is the source and fallback; Spanish is maintained.
  German and Brazilian Portuguese are included as initial translations awaiting
  native-speaker review. See [the translation guide](po/README.md).

## Testing and quality

Punchi Dock combines QML views, native C++ code, persistent configuration, and
KDE services. Tests help detect regressions such as an applet failing to load,
a setting losing its effect, incorrect model updates, or a package missing
required files before those changes reach users.

| Check | Purpose |
|---|---|
| CTest | Exercises native logic, component interactions, applet loading and teardown, configuration contracts, and integration with controlled providers. |
| QML lint | Detects unresolved imports, properties, and bindings; the development workflow rejects increases over the environment's warning baseline. |
| Translation checks | Verify catalog completeness, formatting placeholders, and project translation rules. |
| Test integrity | Detects changes to protected tests, canonical test names, and the minimum suite size. |
| Package checks | Verify the staged module and translations and keep development files outside the installed plasmoid. |

These checks complement manual testing in Plasma. Passing isolated tests does
not establish visual correctness, compositor behavior, or compatibility with
every distribution. Validation results belong to their specific release and environment.

For reproducible validation, use the dependencies and lint baseline for your platform, rebuild with the current toolchain, and run tests with isolated configuration and sessions. Stale build artifacts, missing services, or a mismatched baseline can cause failures. Protected tests must pass the integrity check; uncommitted Git changes alone do not invalidate a run.

To run CTest without installing the plasmoid or restarting Plasma, prepare the
build dependencies and run:

```bash
cmake -S . -B build -DBUILD_TESTING=ON
cmake --build build --parallel 2
ctest --test-dir build --output-on-failure
```

This runs the configured CTest suite; the complete maintenance workflow also
applies the separate lint, catalog, integrity, and packaging checks. See
[developer scripts](scripts-dev/README.md) and [test integrity](scripts-dev/test-integrity/README.md).

## Support and contributing

Report problems through [GitHub Issues](https://github.com/PunchiSoft/punchi-dock-remastered/issues).
Include the Plasma and Qt versions, distribution, Wayland or X11 session,
package origin, reproduction steps, and expected and observed behavior.
Screenshots and focused logs help when they do not expose private information.

Code contributions, reproducible tests, documentation improvements, and
translation reviews are welcome. Consult the [developer workflow](scripts-dev/README.md)
and [translation guide](po/README.md).

<details>
<summary>Project structure</summary>

- `contents/`: runtime QML, JavaScript, configuration, and assets.
- `src/`: native C++ integration.
- `tests/`: behavior, runtime, integration, and contract checks.
- `scripts-user/`: user build and installation tools.
- `scripts-dev/`: validation, packaging, and maintenance tools.
- `metadata.json`: package identity and declared Plasma compatibility.

Internal notes, development files, and test tools are excluded from the installed package.

</details>

### AI-assisted development

AI agents are an integral development aid for accelerating programming, investigating issues, supporting refactoring, and preparing documentation and tests. Their instructions are versioned in [AGENTS.md](AGENTS.md) and [`.agents/`](.agents/). Maintainers remain responsible for technical decisions, review, and validation.

The agent instructions and skills were created and configured by the author of Punchi Dock Remastered through independent research, reading online resources, Wikipedia, and Reddit discussions. These instructions are tailored to the project's architecture and development workflow.

Financial support is optional: [donate through PayPal](https://www.paypal.com/donate/?hosted_button_id=HXFSZU4K8C38W).
Donations are never required to use the project.

## License

Punchi Dock Remastered is licensed under the [GNU General Public License v3.0 or later](LICENSE).

Copyright notices, license terms, and attribution requirements apply equally to
human and AI-assisted reuse. AI-assisted copying, modification, redistribution,
summarization, or code generation based on this project does not waive or
replace the obligation to comply with the GPL-3.0-or-later license, preserve
required notices, provide corresponding source when required, and attribute
Punchi Dock Remastered and its contributors where applicable.

For the change history, see [CHANGELOG.md](CHANGELOG.md) and
[GitHub Releases](https://github.com/PunchiSoft/punchi-dock-remastered/releases).
