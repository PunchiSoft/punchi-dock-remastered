# Punchi Dock 0.8.8

Punchi Dock is a customizable launcher dock and task interface for KDE Plasma 6. It is designed primarily for Wayland and can operate as a floating dock or as part of a Plasma panel while following the active Plasma theme.

Version 0.8.8 adds an external JSON theme library, improves portable application and VirtualBox window handling, keeps panel icons stable when auto-hide is active, and strengthens the separate Fedora and Debian build flows.

> **Choose the package that matches your system**
>
> Punchi Dock contains a native Qt/KDE module. Fedora and Debian packages are not interchangeable. Never install a Fedora-labeled `.plasmoid` on Debian or a Debian-labeled package on Fedora.

## Highlights in 0.8.8

### External JSON themes

- Import one JSON theme or recursively scan a folder and its subfolders.
- Imported themes are validated and copied to a managed user library.
- Duplicate, invalid, oversized, unreadable, or unsupported files are rejected safely.
- Installed themes can be removed directly from the Appearance settings.
- If a selected theme is missing or invalid, Punchi Dock falls back to the Plasma background.
- Theme files and presets are not bundled inside the `.plasmoid`; they remain separate user content.

The first theme schema supports flat 2D backgrounds and shelf-style 2.5D backgrounds. Themes can define gradients, borders, corners, shadows, rims, facets, and matching separators. Glow sizes are constrained so separators and rims do not overflow the dock.

External themes currently apply to floating docks. A Punchi Dock instance inside a Plasma panel continues to use the panel's native background.

### Tasks and portable applications

- Task matching now follows KDE's standard approach by comparing both `AppId` and `LauncherUrlWithoutIcon`.
- Portable applications without an installed desktop service can reuse the icon published by their window.
- Windows whose runtime identity differs from their launcher have a second standard association path, improving cases such as VirtualBox machine windows.
- Dynamic task grouping keeps both identities instead of relying on one exact application ID.

### Panel behavior

- Icon size no longer changes when a Plasma panel switches between Always Visible and Auto Hide.
- Panel thickness is taken from the real containment geometry instead of the reserved work area, which disappears when auto-hide is active.
- If the geometry is temporarily unavailable, the configured icon size is preserved.

### Settings and packaging

- Audio visualizer options now have their own settings page.
- Debian builds use a cache directory outside VirtualBox shared folders.
- Fedora and Debian keep independent `qmllint` baselines because Qt versions expose different tooling diagnostics.
- Qt 6.8 compatibility was restored for the theme import dialogs.
- The local test script verifies the installation and confirms that Plasma Shell actually restarted with a new process.

## Features

- Floating dock and Plasma panel modes.
- Pinned launchers and optional dynamic task groups.
- Window cards, compositor-provided live thumbnails, grouped-window actions, and overflow handling.
- Configurable folder containers, quick notes, trash, calendar, clock, separators, and spacers.
- Configurable popup opening animations and smooth preview-to-action transitions.
- Native `.desktop` actions and window controls in contextual menus.
- Adaptive MPRIS media cards with artwork, track information, and playback controls.
- Optional native PipeWire audio visualizer with six styles, configurable density, themed or dynamic colors, direction, and flow.
- Asynchronous KIO trash operations with progress, status feedback, completion sound, and themed notifications.
- Custom JSON theme library supporting 2D flat and 2.5D shelf backgrounds.

## Compatibility

- KDE Plasma 6 or later is declared in the package metadata.
- Wayland is the primary supported session.
- Fedora 44+ `x86_64` remains the primary prebuilt release target.
- A separately compiled Debian 13 `x86_64` artifact has passed build, installation, and startup validation; broader functional review remains in progress.
- PipeWire is required only for the optional audio visualizer.

The `.plasmoid` includes native binaries linked against the Qt and KDE libraries of the build environment. It must not be presented as one universal package for every Linux distribution or CPU architecture.

Live window thumbnails depend on compositor support and can fall back to window cards when unavailable. Vertical panels remain supported, although advanced visual tuning is focused primarily on horizontal docks and panels.

## Performance and privacy

Punchi Dock does not depend on external X11 automation tools such as `xdotool`, `wmctrl`, or `xprop`, and it does not modify Plasma's global configuration files.

The audio visualizer processes short-lived spectrum levels in memory. It does not store audio samples or transmit them over the network. Plasma may still display a recording indicator because output monitoring requires an audio input stream.

## Upgrade note

After upgrading, restart Plasma Shell once or log out and back in if the dock does not refresh immediately. Existing Punchi Dock configuration is preserved.

## License

GPL-3.0-or-later

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
