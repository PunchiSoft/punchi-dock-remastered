#!/usr/bin/env bash

punchi_install_local_package() {
    local package_file="${1:?package file is required}"
    local install_dir="${2:?installation directory is required}"
    local data_root="${3:?data root is required}"
    local plugin_id="${4:?plugin ID is required}"
    local backup_dir=""

    if [[ -d "$install_dir" && ! -f "$install_dir/metadata.json" ]]; then
        backup_dir="$data_root/${plugin_id}.broken.$$"
        echo "Repairing incomplete local installation: $install_dir"
        mv "$install_dir" "$backup_dir"
    elif kpackagetool6 --type Plasma/Applet -u "$package_file" 2>/dev/null; then
        return 0
    elif [[ -d "$install_dir" ]]; then
        backup_dir="$data_root/${plugin_id}.backup.$$"
        echo "Replacing the existing same-version local package"
        mv "$install_dir" "$backup_dir"
    else
        echo "No local installation found; installing the package"
    fi

    if ! kpackagetool6 --type Plasma/Applet -i "$package_file"; then
        cmake -E remove_directory "$install_dir"
        if [[ -n "$backup_dir" && -d "$backup_dir" && ! -e "$install_dir" ]]; then
            mv "$backup_dir" "$install_dir"
        fi
        return 1
    fi

    if [[ -n "$backup_dir" ]]; then
        cmake -E remove_directory "$backup_dir"
    fi
}
