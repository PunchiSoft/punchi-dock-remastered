# Debian QML tooling

Developer-only metadata for Plasma 6.3's programmatically registered
`org.kde.plasma.plasmoid` module. The exporter reflects the installed Qt/KDE
types; it does not define substitute runtime types or load the dock.

Build this independent CMake project with the host Qt. Qt QML private development
headers must match that Qt version. Its private API use is restricted to this
build-time tool; it is not a runtime or package dependency.

The caller must isolate XDG data, configuration and caches, wait for the
exporter's exit, and delete its temporary environment. Configuration key metadata
comes from `contents/config/main.xml`, preserving names and declared types.

This tool is for Debian's older Plasma module layout. Fedora's tooling and gates
continue using their installed module metadata. Nothing from this directory
belongs in a `.plasmoid`.
