# Developer Scripts

[English](README.md) | [Español](README.es.md)

This directory contains the strict project-maintenance workflow. It is not the
normal installation path for end users.

The main developer entry point is:

```bash
./scripts-dev/setup.sh
```

It detects Fedora, Debian-family, or Arch-family hosts, can prepare distribution
packages, runs `qmllint`, configures CMake with `BUILD_TESTING=ON`, executes the
complete CTest suite, creates the package, and can install it for a local
runtime test.

Common commands:

```bash
./scripts-dev/setup.sh --local-test
./scripts-dev/setup.sh --local-test -j 1       # Safe mode for VMs / limited RAM
./scripts-dev/setup.sh --local-test --jobs 8  # Fast mode with 8 parallel jobs
./scripts-dev/setup.sh --clean-install
./scripts-dev/setup.sh --dependencies-only
./scripts-dev/setup.sh --lang es --help
./scripts-dev/check-build-environment.sh
./scripts-dev/update-translations.sh
./scripts-dev/validar-empaquetado-limpio.sh
./scripts-dev/watch-plasmoidviewer.sh
```

## Structure

- `setup.sh`: strict interactive and CLI developer orchestrator.
- `distro/`: Fedora, Debian 13, and Arch-family development profiles.
- `lib/`: developer-only logging, local-test, Plasma-version, and qmllint
  helpers.
- `qmllint*.py` and `qmllint-baseline*.env`: static-debt tooling and profiles.
- `instalar-plasmoide.sh`: selector for locally produced packages.

The developer flow reuses the shared package engine in
`scripts-user/lib/package-plasmoid.sh` with full validation enabled. The normal user
flow is documented in [scripts-user/README.md](../scripts-user/README.md).

The assistant detects English, Spanish, German, and Brazilian Portuguese from
the session locale. Use `--lang en`, `--lang es`, `--lang de`, or
`--lang pt_BR` to override it. Language selection changes only the assistant
messages; strict `qmllint`, CTest, translation, and packaging gates remain
enabled.

The Arch profile installs only packages from configured official repositories
with `pacman -Syu --needed`; it does not use the AUR or enable repositories.
Because Arch is rolling release, its zero-warning `qmllint` baseline must be
confirmed on the actual Arch Qt version before treating an artifact as
validated. `--skip-pacman` performs verification without package installation.
