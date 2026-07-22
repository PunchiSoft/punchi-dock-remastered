#!/usr/bin/env bash

punchi_qmllint_baseline_path() {
    local cache_directory="${1:?cache directory is required}"
    local package_version="${2:?package version is required}"
    local safe_version="${package_version//[^[:alnum:]._-]/_}"

    printf '%s/qmllint-baseline-%s.env\n' "${cache_directory%/}" "$safe_version"
}
