# Standard CMake workflow

This directory documents and demonstrates the distribution-independent build
and installation path for Punchi Dock Remastered. CMake is the canonical
interface; the scripts in this directory are optional, thin wrappers around the
same commands and do not detect a distribution or invoke a package manager.

## Interactive assistant

Run the localized assistant for a guided per-user workflow:

```bash
./scripts-cmake/setup.sh
```

Before showing its menu, the assistant lists the minimum toolchain, checks the
required commands, and configures CMake so that Qt, KF6, Plasma, PipeWire,
Gettext, and the shader baker are verified by the canonical build graph. When
the environment is incomplete it stops with the missing requirement and asks
the user to rerun it after installing the matching development packages from
their Linux distribution. It does not invoke a package manager or request
administrative privileges.

The menu can check the environment again, compile, install the current build,
compile and install in one operation, inspect temporary staging, or restart
Plasma Shell. The assistant uses `build-cmake-user/`, defaults to the
`$HOME/.local` prefix, and embeds the native QML module inside the installed
KPackage so that a per-user install never writes into the system Qt QML path.
Every installation asks whether Plasma Shell should be restarted. Assistant
messages follow the system locale for English, Spanish, German, and Brazilian
Portuguese.

In an interactive terminal, assistant status messages use semantic colors:
cyan for headings and progress, yellow for notices, red for errors, and green
for successful checks or operations. Redirected output stays plain, as does any
session with `TERM=dumb`. Set `NO_COLOR` to any value to disable ANSI colors
explicitly:

```bash
NO_COLOR=1 ./scripts-cmake/setup.sh
```

The assistant only styles its own messages; output produced by CMake and other
tools remains unchanged.

Plasma restart commands have a 15-second timeout by default, so an unavailable
or unresponsive session DBus cannot leave the assistant waiting indefinitely.
Advanced users can change the bound with `PUNCHI_CMAKE_RESTART_TIMEOUT`.

Equivalent non-interactive examples:

```bash
./scripts-cmake/setup.sh --check
./scripts-cmake/setup.sh --build
./scripts-cmake/setup.sh --build-install --no-restart
./scripts-cmake/setup.sh --restart-plasma
```

This guided flow compiles native libraries for the current system. It does not
create a portable `.plasmoid` artifact or run the developer validation suite.

## Direct commands

Configure and build:

```bash
cmake -S . -B build-cmake -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=Release
cmake --build build-cmake --parallel
```

Install using the prefix selected at configure time:

```bash
cmake --install build-cmake
```

For a per-user installation, configure an explicit prefix:

```bash
cmake -S . -B build-cmake \
    -DBUILD_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$HOME/.local" \
    -DPUNCHI_EMBED_QML_MODULE_IN_KPACKAGE=ON
cmake --build build-cmake --parallel
cmake --install build-cmake
```

The embed option is required for a self-contained per-user KPackage. Without
it, KDE's standard Qt QML destination can remain under `/usr` even when CMake
has a user prefix; that global layout is intended for distribution packaging.

Distribution packagers can stage the installation without writing to the host:

```bash
DESTDIR="$PWD/package-root" cmake --install build-cmake
```

The standard installation includes:

- the Plasma KPackage under the configured KDE data directory;
- the native `org.punchi.dock` QML module under the configured Qt QML directory;
- the supported translation catalogs under the configured locale directory.

## Optional helpers

`build.sh` configures and builds with no distribution detection. `inspect.sh`
then installs into a temporary staging directory and prints the resulting file
tree. It never installs into the active Plasma session.

```bash
./scripts-cmake/build.sh
./scripts-cmake/inspect.sh
```

The existing `scripts-user/` and `scripts-dev/` flows remain available for
dependency guidance, `.plasmoid` release artifacts, strict validation, and
local Plasma diagnostics. They are convenience tooling, not a requirement of
the standard CMake installation path.
