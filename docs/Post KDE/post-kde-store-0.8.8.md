# Punchi Dock 0.8.8

Punchi Dock 0.8.8 adds an external JSON theme library, improves portable
application and VirtualBox window handling, keeps panel icons stable when
auto-hide is enabled, and strengthens the separate Fedora and Debian build
flows.

> **Choose the package that matches your system**
>
> Punchi Dock contains a native Qt/KDE module. Fedora and Debian `.plasmoid`
> packages are not interchangeable.

## External JSON themes

- Import one JSON theme or recursively scan a folder and its subfolders.
- Imported themes are validated and copied to a managed user library.
- Duplicate, invalid, oversized, unreadable, or unsupported files are rejected
  safely.
- Installed themes can be removed directly from the Appearance settings.
- If a selected theme is missing or invalid, Punchi Dock falls back to the
  Plasma background.
- Theme files and presets are not bundled inside the `.plasmoid`; they remain
  separate user content.

The first theme schema supports flat 2D backgrounds and shelf-style 2.5D
backgrounds. Themes can define gradients, borders, corners, shadows, rims,
facets, and matching separators. Glow sizes are constrained so separators and
rims do not overflow the dock.

External themes currently apply to floating docks. A Punchi Dock instance
inside a Plasma panel continues to use the panel's native background.

## Tasks and portable applications

- Task matching now follows KDE's standard approach by comparing both
  `AppId` and `LauncherUrlWithoutIcon`.
- Portable applications without an installed desktop service can reuse the
  icon published by their window.
- Windows whose runtime identity differs from their launcher have a second
  standard association path, improving cases such as VirtualBox machine
  windows.
- Dynamic task grouping keeps both identities instead of relying on one exact
  application ID.

## Panel behavior

- Icon size no longer changes when a Plasma panel switches between Always
  Visible and Auto Hide.
- Panel thickness is taken from the real containment geometry instead of the
  reserved work area, which disappears when auto-hide is active.
- If the geometry is temporarily unavailable, the configured icon size is
  preserved.

## Settings and packaging

- Audio visualizer options now have their own settings page.
- Debian builds use a cache directory outside VirtualBox shared folders.
- Fedora and Debian keep independent `qmllint` baselines because Qt versions
  expose different tooling diagnostics.
- Qt 6.8 compatibility was restored for the theme import dialogs.
- The local test script verifies the installation and confirms that Plasma
  Shell actually restarted with a new process.

## Compatibility

- KDE Plasma 6 or later is declared in package metadata.
- Wayland remains the primary supported session.
- Fedora 44 `x86_64` is the primary prebuilt target.
- Debian 13 `x86_64` uses a separately compiled package validated with Qt
  6.8.2.
- PipeWire is required only for the optional audio visualizer.

The native binaries inside each package are tied to the build environment.
Always install the artifact labeled for your distribution and architecture.

## Upgrade note

After upgrading, restart Plasma Shell once or log out and back in if the dock
does not refresh immediately. Existing configuration is preserved.

## Release changelog

### Version 0.8.8

- Added a managed external JSON theme library.
- Added recursive folder import and installed-theme removal.
- Added flat 2D and shelf-style 2.5D renderers with theme-defined separators.
- Kept external theme files outside the distributed `.plasmoid`.
- Added portable-window icon fallback through TaskManager decoration data.
- Improved launcher/window matching with application IDs and launcher URLs.
- Fixed icon shrinking in auto-hidden Plasma panels.
- Moved audio visualizer options to a dedicated settings page.
- Improved Debian Qt 6.8 compatibility and VirtualBox shared-folder builds.
- Added validator and repository tests; the current suite passes `5/5`.

License: GPL-3.0-or-later.
