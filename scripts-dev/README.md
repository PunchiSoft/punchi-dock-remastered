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
python3 ./scripts-dev/audit-plasma-config.py --project-root .
python3 ./scripts-dev/skill_inventory.py --check
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
- `audit-plasma-config.py`: static auditor for the KConfig, KCM-page, and
  runtime-consumer contract.
- `skill_inventory.py`: validates the versioned agent skills and maintains their
  generated inventory.
- `test-integrity-guard.py` and `test-integrity/`: protects existing tests, the
  canonical CTest names, the per-profile test floor and the gate contracts. The
  policy lives in `AGENTS.md`; the operation is documented in
  [test-integrity/README.md](test-integrity/README.md).
- `instalar-plasmoide.sh`: selector for locally produced packages.

## KConfig contract auditor

`audit-plasma-config.py` verifies the static path from the KConfig schema to
the declared KCM pages and the runtime configuration map. Run it from the
project root:

```bash
python3 scripts-dev/audit-plasma-config.py --project-root .
```

Use `--format json` for machine-readable output and `--verbose` to list every
schema entry and its KCM owner. The command exits with `0` when the contract
passes and `1` when it finds a structural error; CTest runs both its isolated
regression suite (`plasma_config_auditor_test`) and the real-tree gate
(`plasma_config_audit`).

Run the auditor whenever a change adds, removes, renames, moves, or changes the
ownership of a KConfig entry, a `cfg_*` property, a configuration page, or a
runtime configuration access. It checks static connectivity only: passing does
not prove Apply, Cancel, persistence, hot refresh, or behavior in Plasma.

## Skill inventory

The agent infrastructure has three distinct sources and outputs:

- `.agents/skills/` contains the actual skill instructions and resources.
- `.agents/skills-map.yaml` is the manual classification source for families,
  roles, aliases, structured skill references, and exceptional path semantics.
- `.agents/skills-inventory.json` is generated deterministically from the map
  and the current filesystem; it must not be edited manually.

Run `python3 scripts-dev/skill_inventory.py --check` for a read-only validation
of the complete contract. Run `python3 scripts-dev/skill_inventory.py --update`
to validate all sources and replace only the generated inventory. A new skill
must be classified in the manual map before either operation can succeed.

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
