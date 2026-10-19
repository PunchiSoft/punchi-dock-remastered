#!/usr/bin/env bash

# Pure package validation for the universal installer. It returns values and
# status codes only; user-facing messages stay in the entry point so the
# translation extraction keeps working from the existing shell sources.

punchi_read_json_string() {
    local json="${1:?json text is required}"
    local key="${2:?json key is required}"

    printf '%s' "$json" \
        | tr -d '\n' \
        | sed -n 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
        | head -n1
}

punchi_read_project_version() {
    local metadata_file="${1:?metadata file is required}"

    [[ -f "$metadata_file" ]] || return 1
    punchi_read_json_string "$(cat "$metadata_file")" "Version"
}

punchi_package_metadata() {
    local package_file="${1:?package file is required}"

    unzip -p "$package_file" metadata.json 2>/dev/null
}

punchi_version_compare() {
    local left="${1:?left version is required}"
    local right="${2:?right version is required}"

    if [[ "$left" == "$right" ]]; then
        printf 'equal\n'
        return 0
    fi
    if [[ "$(printf '%s\n%s\n' "$left" "$right" | sort -V | head -n1)" == "$left" ]]; then
        printf 'less\n'
    else
        printf 'greater\n'
    fi
}

# Prints the package version and returns:
#   0  valid and not older than expected_version
#   1  invalid package, missing metadata, wrong structure or wrong plugin id
#   2  valid but older than expected_version
punchi_validate_universal_package() {
    local package_file="${1:?package file is required}"
    local plugin_id="${2:?plugin id is required}"
    local expected_version="${3:-}"
    local metadata=""
    local structure=""
    local package_id=""
    local package_version=""

    [[ -f "$package_file" ]] || return 1
    command -v unzip >/dev/null 2>&1 || return 1
    metadata="$(punchi_package_metadata "$package_file")" || return 1
    [[ -n "$metadata" ]] || return 1

    structure="$(punchi_read_json_string "$metadata" "KPackageStructure")"
    package_id="$(punchi_read_json_string "$metadata" "Id")"
    package_version="$(punchi_read_json_string "$metadata" "Version")"

    [[ "$structure" == "Plasma/Applet" ]] || return 1
    [[ "$package_id" == "$plugin_id" ]] || return 1
    [[ -n "$package_version" ]] || return 1

    printf '%s\n' "$package_version"
    if [[ -n "$expected_version" \
            && "$(punchi_version_compare "$package_version" "$expected_version")" == "less" ]]; then
        return 2
    fi
    return 0
}

# Returns:
#   0  checksum verified
#   1  checksum mismatch
#   3  no checksum file, no entry for this package, or no sha256sum
punchi_verify_package_checksum() {
    local package_file="${1:?package file is required}"
    local dist_dir="${2:?dist directory is required}"
    local package_version="${3:-}"
    local package_name=""
    local sums_file=""
    local sums_name=""

    command -v sha256sum >/dev/null 2>&1 || return 3
    [[ -n "$package_version" ]] || return 3
    package_name="$(basename "$package_file")"
    sums_file="$dist_dir/SHA256SUMS-$package_version.txt"
    sums_name="$(basename "$sums_file")"
    [[ -f "$sums_file" ]] || return 3
    grep -Fq "  $package_name" "$sums_file" || return 3

    if ( cd "$dist_dir" \
            && grep -F "  $package_name" "$sums_name" \
            | sha256sum -c - >/dev/null 2>&1 ); then
        return 0
    fi
    return 1
}
