# User Installation Scripts

[English](README.md) | [Español](README.es.md)

This directory contains the normal user flow. Running without arguments opens the interactive assistant:

```bash
./scripts-user/setup.sh
```

The interactive menu lets you:
- **Build and install locally** (with optional confirmation to restart Plasma Shell);
- **Build the `.plasmoid` package only** (without installing);
- **Install an existing package** from `dist/` or a custom path;
- **Uninstall** the plasmoid cleanly from your desktop;
- **Restart Plasma Shell** on demand;
- **Configure build concurrency & RAM safety** (Safe Mode for VMs / low-RAM systems, Balanced, Fast, or Custom parallel jobs);
- **Check system build dependencies**.

It configures CMake with `BUILD_TESTING=OFF` and does not run `qmllint` or CTest. Those checks belong to the separate developer workflow under `scripts-dev/`.

## CLI Options

You can also run non-interactively with CLI flags:

```bash
# Build and install locally without restarting Plasma Shell
./scripts-user/setup.sh --install --no-restart

# Build and install locally with safe concurrency (1 job for low-memory environments)
./scripts-user/setup.sh --install -j 1

# Create the local .plasmoid package using 4 parallel jobs
./scripts-user/setup.sh --build-only --jobs 4

# Uninstall the plasmoid from the current desktop
./scripts-user/setup.sh --uninstall
```

Choose only one primary action per invocation. Modifiers such as `-j/--jobs/--parallel N`,
`--no-restart`, and `--yes` can be combined with an applicable action. The assistant detects
`es`, `de`, and `pt_BR` automatically from the system locale, with English as
the fallback. Use `--lang es`, `--lang de`, `--lang pt_BR`, or `--lang en` to
override it. Translations remain in the project's PO catalogs instead of being
duplicated inline in Bash.

The output package uses a `-local-build.plasmoid` suffix. It is compiled for the current system and must not be published as an official universal artifact.

To install an existing package directly:

```bash
./scripts-user/setup.sh path/to/package.plasmoid
# or
./scripts-user/setup-universal.sh [--no-restart] path/to/package.plasmoid
```

Installing an existing package, uninstalling, or restarting does not require
the C++ build toolchain. Each action checks only the commands it actually uses.

## Internal files

- `setup.sh`: public source-build, install, and restart command.
- `setup-universal.sh`: installer for an existing package.
- `lib/setup-localization.sh`: locale detection and gettext integration.
- `lib/plasma-shell-control.sh`: shared, verified Plasma Shell restart logic.
- `lib/`: shared packaging and installation implementations; users should not
  invoke these files directly.

Project maintainers should use [the developer scripts](../scripts-dev/README.md).
