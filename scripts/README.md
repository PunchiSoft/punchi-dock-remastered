# Packaging and Testing Scripts

[English](README.md) | [Español](README.es.md)

## Check the environment

```bash
scripts/check-build-environment.sh
```

This command does not install or replace packages. It reports the distribution,
architecture, and local Plasma, CMake, and `qmllint` versions, then classifies
the detected lint profile:

| `qmllint` version | Treatment |
|---|---|
| Qt 6.11 | Primary development and validation profile. |
| Qt 6.8 | Compatibility profile with a separate baseline; diagnostics may differ. |
| Other Qt 6 version | Uncalibrated profile; run the tests and review diagnostics before recording a dedicated baseline. |

The `qmllint` baseline measures diagnostics for one specific tool and platform
combination. It does not define the plasmoid's minimum runtime version. Users
installing a matching prebuilt `.plasmoid` do not need `qmllint`.

Builds must use the Qt 6, KF6, and Plasma packages supplied by the same
distribution. Do not replace the system Qt stack with a standalone Qt 6.11
installation merely to silence lint warnings: the native QML module requires a
coherent library stack.

## Recommended commands

```bash
scripts/setup-fedora.sh
scripts/setup-debian13.sh
scripts/setup-debian14-testing.sh
scripts/setup-kubuntu.sh
```

Each command validates its distribution, detects installed dependencies, and
uses the matching `qmllint` executable and baseline. Shared build and
installation engines remain internal under `scripts/lib/`.

Every `setup-*.sh` command also mirrors its complete terminal output to a
distribution-specific directory inside the shared project:

```text
docs/logs/<distribution>/
```

The final lines report the exact log path and exit status. A stable file named
`setup-<distribution>-latest.log` always contains the most recent execution for
that distribution, including on VirtualBox shared folders that do not expose
symbolic links. Set `PUNCHI_LOG_DIR` to use another local directory.
The entire `docs/` tree is excluded from Git and plasmoid packages. Logs can
contain local user paths and system information; review them before sharing
them publicly.

Fedora and Debian keep their validated profiles. Kubuntu has a locally
validated build profile for Plasma 6.6.4: it prepares a clean installation,
builds the module against host libraries, installs the package, and supports
functional testing. It is not a universal binary and does not replace Fedora
as the primary release target.

| Detected system | Expected artifact |
|---|---|
| Fedora 44 `x86_64` | `dist/punchi-dock-remastered-<version>-fedora44-x86_64.plasmoid` |
| Debian 13 `x86_64` | `dist/punchi-dock-remastered-<version>-debian13-x86_64.plasmoid` |
| Kubuntu with Plasma 6 `x86_64` | `dist/punchi-dock-remastered-<version>-kubuntu<version>-plasma<version>-x86_64.plasmoid` |

## Debian 13

Run the validated Debian 13/trixie profile with:

```bash
scripts/setup-debian13.sh
```

With no options, it creates the public `debian13` artifact. To install it and
restart Plasma for a local test:

```bash
scripts/setup-debian13.sh --local-test
```

The script rejects Debian 14/testing and uses `dpkg-query` to detect installed
dependencies. `--dependencies-only`, `--skip-apt`, and `--dry-run` explicitly
limit the workflow.

On Debian and Kubuntu, build objects are stored under
`~/.cache/punchi-dock-remastered/` by default. This avoids timestamp and
performance issues when the repository is mounted through a VirtualBox shared
folder. The final `.plasmoid` still appears under `dist/`.

Kubuntu keeps a dedicated, package-versioned `qmllint` baseline in that cache.
The first local test for each Punchi Dock version records it for the exact
Kubuntu, Plasma, and Qt combination; later runs of that version reject warning
increases. This local baseline is diagnostic evidence. Kubuntu validation still
requires a native build and never reuses another distribution's package.

## Experimental Debian 14/testing setup

From a Live CD or clean Debian 14/testing `forky` installation, use:

```bash
scripts/setup-debian14-testing.sh --yes
```

The script detects installed dependencies with `dpkg-query` and uses APT only
for missing packages. With no options, it records a package-versioned local
`qmllint` baseline when required and creates a public `debian14testing` artifact
without installing it. A new Punchi Dock version therefore cannot reuse the
warning counts recorded for an older version. Run it as the regular Plasma
user; only APT operations request `sudo`. It does not add external repositories
or replace the system Qt/KDE stack.

Useful options:

```bash
scripts/setup-debian14-testing.sh --dry-run
scripts/setup-debian14-testing.sh --skip-apt
scripts/setup-debian14-testing.sh --yes --local-test
scripts/setup-debian14-testing.sh --yes --local-test --skip-restart
```

## Local Fedora test

```bash
scripts/setup-fedora.sh --local-test
```

This creates an artifact such as
`dist/punchi-dock-remastered-0.9.1-fedora44-x86_64-local-test.plasmoid`, verifies
its installation for the current user, and restarts Plasma Shell. On systems
with `plasma-plasmashell.service`, it uses the systemd user service. If the
service retains the previous process, the script first requests a KDE shutdown
and then starts the service again. Other systems use `kquitapp6` and `kstart`.
The script reports the previous and new PIDs and only declares success after
confirming a new process. The `local-test` suffix distinguishes this temporary
package from a public artifact.

On Kubuntu, `scripts/setup-kubuntu.sh --local-test` provides the equivalent
workflow using the local Plasma version. Do not reuse Debian or Fedora packages.

## Prepare a clean Kubuntu installation

Run from the repository root as the regular Plasma user:

```bash
scripts/setup-kubuntu.sh
```

The script detects missing official dependencies, updates APT only when it must
install them, and creates the Kubuntu artifact without installing it. Only APT
operations request `sudo`; do not run the complete script with a leading
`sudo`.

Main options:

```bash
# Install dependencies and package without APT prompts
scripts/setup-kubuntu.sh --yes

# Prepare, package, install, and restart Plasma for testing
scripts/setup-kubuntu.sh --yes --local-test

# Install and check dependencies without building
scripts/setup-kubuntu.sh --dependencies-only

# Build using dependencies that are already installed
scripts/setup-kubuntu.sh --skip-apt

# Display operations without changing the system
scripts/setup-kubuntu.sh --dry-run
```

If a package is unavailable from the configured repositories, the process
stops and displays the list. It does not add PPAs or mix Qt/KDE versions.

## Clean validation

```bash
scripts/validar-empaquetado-limpio.sh
```

This rebuilds from a clean temporary source copy and validates lint, CTest,
package contents, and the ZIP archive. It does not install the plasmoid.

## Translations

```bash
scripts/update-translations.sh
```

This regenerates the POT template and merges changes into every existing PO
catalog. Executable code keeps English as its only source language; translations
live exclusively under `po/`. Packaging rejects incomplete or fuzzy catalogs,
compiles them, and includes only the resulting MO files under
`contents/locale/` inside the `.plasmoid`, which matches KPackage's contents
prefix.

## Safety rule

Install only an artifact whose name matches the system where it was built. The
native QML module links against the host's Qt and KDE libraries and is not a
universal binary.

No current script creates an unlabeled
`dist/punchi-dock-remastered.plasmoid` artifact.

## Internal organization

The `scripts/` root keeps short wrappers for common commands and compatibility
with earlier documentation. Implementations live under:

- `scripts/distro/`: distribution-specific workflows.
- `scripts/dev/`: development, diagnostics, and validation tools.
- `scripts/lib/`: shared engines and helpers; these are not primary commands.

Do not execute generated files such as `__pycache__`; they are not part of the
project.
