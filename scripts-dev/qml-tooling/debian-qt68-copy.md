# Debian Qt 6.8 source copy

`scripts-dev/distro/debian13-package.sh` selects this path only on Debian with
Qt 6.8 tooling. Other versions and the Fedora wrapper keep their existing path.

The parent creates an owned temporary source/build tree below `BUILD_DIR`.
Developer sources and tests are copied into that tree. Verified Debian-only
style adaptations are applied there before compilation. A fresh
native build is staged into the copied source module, so relative QML imports
resolve the locally compiled libraries instead of binaries from another Qt.
The unchanged full packaging gate then checks the same test assertions, names,
warning rules, integrity manifest, translations and qmllint baseline.

| Entry point | Selected path |
| --- | --- |
| Debian, Qt 6.8 | Disposable source/build copy plus legacy Plasma bootstrap |
| Debian, another Qt version | Existing native build path |
| Fedora | Existing Fedora wrapper and native build path |

The adapted runners are built by the independent tooling project. They include
the original setup source verbatim and add registration of the installed Plasma
types before QML loading. Original runner files, warning handling, assertions
and CTest registrations stay unchanged. A third runner keeps Plasma's shared
engine alive during QuickTest and drains pending Kirigami twin-form callbacks
before the original fixture teardown. Each page and applet is still destroyed
after its case; all QML assertions remain intact. Substitution of these executables is
restricted to the disposable build and was explicitly authorized by the user.
No adapted runner or bootstrap code is shipped in the runtime package.

Configuration belongs to a parent wrapper: it reuses a fixture's already-owned
configuration (preserving `kdeglobals` and reduced motion), or creates a short
temporary configuration path and removes it only after the runner exits.
Data and runtime paths are preserved, so KIO sockets and trash fixtures keep
their original environment. Child failures and termination remain failures.

The bootstrap initializes an applet's configuration before marking it destroyed:
Plasma 6.3's `destroy()` otherwise accesses an uninitialized configuration group.
`itemForApplet()` registers the native types and then returns for the destroyed
applet without loading UI. This order follows the v6.3.5 SDK implementation.

The copied Git index supports read-only tracked-path checks; no original Git
metadata is mutated. Personal directories, SDK repositories and old builds are
not copied. The parent forwards termination to its child process group, waits
for its exit, preserves qmllint and CTest evidence in `BUILD_DIR`, and removes
the temporary source/build tree after success or failure. The output package
path remains the one selected by the original Debian wrapper. No installation
or Plasma restart is performed.

This prevents a Qt-version mix in source-relative imports. It does not suppress
other test failures or establish runtime compatibility on another distribution.

The style adapter verifies the installed Qt 6.8 desktop TabButton implementation.
When its baseline reads a null contentItem, it adds the equivalent zero baseline
to nine copied buttons. Original QML, installed KDE files and Fedora are untouched.
Unknown button structure fails explicitly instead of guessing a patch.

Development currently uses `fix/debian-qt68-compilation`. Changes have not yet
been committed; a branch switch alone does not save or isolate a dirty checkout.

Three fixture prerequisites were explicitly authorized for the disposable copy:
a valid XDG applications menu for KF 6.13 service indexing, valid containment
metadata for Plasma 6.3, and window rendering/activation before the real media
selector click. All pre-existing assertions and warning policies remain intact.
The adapter validates every exact context before writing. The driver updates
only the copied integrity hashes with the authorization reason and retains
`qt68-copy-fixtures.diff` and `qt68-copy-test-integrity-hashes.txt` as evidence.
Original fixture sources and the Fedora entry point are not patched by this step.

The shared gate keeps its original lint-before-configure/build ordering for
Fedora and other non-copy entry points. The Debian parent compiles its copy
before invoking that gate, so only the guarded Debian lint block uses its
fresh module metadata. The Debian Qt 6.8 baseline is now 161 total,
119 unqualified, 0 layout, 4 missing-property and 5 import warnings.
