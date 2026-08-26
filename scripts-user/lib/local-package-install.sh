#!/usr/bin/env bash

punchi_remove_local_directory() {
    local target="${1:?directory target is required}"
    local data_root="${2:?data root is required}"

    if [[ -z "$data_root" || "$data_root" == "/" || "$target" != "$data_root"/* ]]; then
        echo "Refusing to remove a directory outside the local data root: $target" >&2
        return 1
    fi
    rm -rf -- "$target"
}

punchi_install_local_package() {
    local package_file="${1:?package file is required}"
    local install_dir="${2:?installation directory is required}"
    local data_root="${3:?data root is required}"
    local plugin_id="${4:?plugin ID is required}"
    local backup_dir=""

    local update_succeeded=0
    if [[ -d "$install_dir" && ! -f "$install_dir/metadata.json" ]]; then
        backup_dir="$data_root/${plugin_id}.broken.$$"
        echo "Repairing incomplete local installation: $install_dir"
        mv "$install_dir" "$backup_dir"
    elif kpackagetool6 --type Plasma/Applet -u "$package_file" 2>/dev/null; then
        update_succeeded=1
    elif [[ -d "$install_dir" ]]; then
        backup_dir="$data_root/${plugin_id}.backup.$$"
        echo "Replacing the existing same-version local package"
        mv "$install_dir" "$backup_dir"
    else
        echo "No local installation found; installing the package"
    fi

    if (( update_succeeded == 0 )); then
        if ! kpackagetool6 --type Plasma/Applet -i "$package_file"; then
            punchi_remove_local_directory "$install_dir" "$data_root"
            if [[ -n "$backup_dir" && -d "$backup_dir" && ! -e "$install_dir" ]]; then
                mv "$backup_dir" "$install_dir"
            fi
            return 1
        fi
    fi

    local compat_dir="$install_dir/contents/ui/org/punchi/dock/compat"
    mkdir -p "$compat_dir"
    (
        cd "$compat_dir"

        # Create C constructor source for binary compat proxy shared libraries
        cat << 'EOF' > compat_proxy.c
#include <dlfcn.h>
#include <stddef.h>

__attribute__((constructor)) static void init(void) {
    void *hp = NULL;
    if (!hp) hp = dlopen("libPlasma.so.7", RTLD_GLOBAL | RTLD_NOW);
    if (!hp) hp = dlopen("libPlasma.so.6", RTLD_GLOBAL | RTLD_NOW);
    if (!hp) hp = dlopen("libPlasma.so", RTLD_GLOBAL | RTLD_NOW);
    if (!hp) hp = dlopen("libKF6Plasma.so.6", RTLD_GLOBAL | RTLD_NOW);
    if (!hp) hp = dlopen("libKF6Plasma.so", RTLD_GLOBAL | RTLD_NOW);

    void *hq = NULL;
    if (!hq) hq = dlopen("libPlasmaQuick.so.7", RTLD_GLOBAL | RTLD_NOW);
    if (!hq) hq = dlopen("libPlasmaQuick.so.6", RTLD_GLOBAL | RTLD_NOW);
    if (!hq) hq = dlopen("libPlasmaQuick.so", RTLD_GLOBAL | RTLD_NOW);
    if (!hq) hq = dlopen("libKF6PlasmaQuick.so.6", RTLD_GLOBAL | RTLD_NOW);
    if (!hq) hq = dlopen("libKF6PlasmaQuick.so", RTLD_GLOBAL | RTLD_NOW);

    void *ha = NULL;
    if (!ha) ha = dlopen("libPlasmaActivities.so.7", RTLD_GLOBAL | RTLD_NOW);
    if (!ha) ha = dlopen("libPlasmaActivities.so.6", RTLD_GLOBAL | RTLD_NOW);
    if (!ha) ha = dlopen("libPlasmaActivities.so", RTLD_GLOBAL | RTLD_NOW);
    if (!ha) ha = dlopen("libKF6PlasmaActivities.so.6", RTLD_GLOBAL | RTLD_NOW);
    if (!ha) ha = dlopen("libKF6PlasmaActivities.so", RTLD_GLOBAL | RTLD_NOW);
}
EOF

        local CC_BIN="${CC:-gcc}"
        if ! command -v "$CC_BIN" >/dev/null 2>&1; then
            CC_BIN="cc"
        fi

        if command -v "$CC_BIN" >/dev/null 2>&1; then
            "$CC_BIN" -shared -fPIC -O2 -Wl,-soname,libPlasma.so.6 compat_proxy.c -o libPlasma.so.6 -ldl 2>/dev/null || true
            "$CC_BIN" -shared -fPIC -O2 -Wl,-soname,libPlasmaQuick.so.6 compat_proxy.c -o libPlasmaQuick.so.6 -ldl 2>/dev/null || true
            "$CC_BIN" -shared -fPIC -O2 -Wl,-soname,libPlasmaActivities.so.6 compat_proxy.c -o libPlasmaActivities.so.6 -ldl 2>/dev/null || true
        fi
        rm -f compat_proxy.c
    )

    if [[ -n "$backup_dir" ]]; then
        punchi_remove_local_directory "$backup_dir" "$data_root"
    fi
}
