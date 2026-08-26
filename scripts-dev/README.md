# Developer Scripts

[English](README.md) | [Español](README.es.md)

This directory contains the strict project-maintenance workflow. It is not the
normal installation path for end users.

The main developer entry point is:

```bash
./scripts-dev/setup.sh
```

It detects Fedora or Debian-family hosts, can prepare distribution packages,
runs `qmllint`, configures CMake with `BUILD_TESTING=ON`, executes the complete
CTest suite, creates the package, and can install it for a local runtime test.

Common commands:

```bash
./scripts-dev/setup.sh --local-test
./scripts-dev/setup.sh --clean-install
./scripts-dev/setup.sh --dependencies-only
./scripts-dev/check-build-environment.sh
./scripts-dev/update-translations.sh
./scripts-dev/validar-empaquetado-limpio.sh
./scripts-dev/watch-plasmoidviewer.sh
```

## Structure

- `setup.sh`: strict interactive and CLI developer orchestrator.
- `distro/`: Fedora and Debian 13 development profiles.
- `lib/`: developer-only logging, local-test, Plasma-version, and qmllint
  helpers.
- `qmllint*.py` and `qmllint-baseline*.env`: static-debt tooling and profiles.
- `instalar-plasmoide.sh`: selector for locally produced packages.

The developer flow reuses the shared package engine in
`scripts-user/lib/package-plasmoid.sh` with full validation enabled. The normal user
flow is documented in [scripts-user/README.md](../scripts-user/README.md).
