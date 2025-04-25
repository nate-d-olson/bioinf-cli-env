#!/usr/bin/env bash
# Version management and dependency pinning utilities
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Dependency versions
declare -A DEPENDENCIES=(
    [micromamba]="1.5.6"
    [zsh]="5.9"
    [oh - my - zsh]="master" # Using master as it's a framework
    [powerlevel10k]="v1.19.0"
    [tmux]="3.3a"
)

# Tool versions file management
VERSION_FILE="${HOME}/.local/share/bioinf-cli-env/versions.json"

init_version_file() {
    local version_dir
    version_dir=$(dirname "$VERSION_FILE")
    mkdir -p "$version_dir"

    if [[ ! -f "$VERSION_FILE" ]]; then
        echo "{}" >"$VERSION_FILE"
    fi
}

save_installed_version() {
    local tool=$1
    local version=$2

    init_version_file

    if command -v jq >/dev/null; then
        local temp_file
        temp_file=$(create_temp_file)
        jq --arg tool "$tool" --arg version "$version" \
            '.[$tool] = $version' "$VERSION_FILE" >"$temp_file" &&
            mv "$temp_file" "$VERSION_FILE"
    else
        log_warning "jq not found, version tracking will be limited"
        echo "$tool:$version" >>"${VERSION_FILE}.txt"
    fi
}

get_installed_version() {
    local tool=$1

    if [[ ! -f "$VERSION_FILE" ]]; then
        return 1
    fi

    if command -v jq >/dev/null; then
        jq -r --arg tool "$tool" '.[$tool] // empty' "$VERSION_FILE"
    else
        grep "^${tool}:" "${VERSION_FILE}.txt" 2>/dev/null | cut -d: -f2
    fi
}

check_version_compatibility() {
    local tool=$1
    local required_version=${2:-${DEPENDENCIES[$tool]}}
    local installed_version

    installed_version=$(get_installed_version "$tool")

    if [[ -z "$installed_version" ]]; then
        log_warning "No version information found for $tool"
        return 1
    fi

    # Version comparison logic
    if command -v sort >/dev/null; then
        if [[ "$(printf '%s\n' "$required_version" "$installed_version" | sort -V | head -n1)" != "$required_version" ]]; then
            log_error "$tool version mismatch. Required: $required_version, Installed: $installed_version"
            return 1
        fi
    else
        log_warning "sort command not found, skipping version comparison"
    fi

    return 0
}

get_latest_release_version() {
    local repo=$1
    local response

    if ! command -v curl >/dev/null; then
        log_error "curl is required for version checking"
        return 1
    fi

    response=$(curl -s "https://api.github.com/repos/${repo}/releases/latest")

    if [[ $? -ne 0 ]]; then
        log_error "Failed to fetch latest version for ${repo}"
        return 1
    fi

    echo "$response" | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4
}

install_specific_version() {
    local tool=$1
    local version=${2:-${DEPENDENCIES[$tool]}}

    log_info "Installing $tool version $version"

    case "$tool" in
    micromamba)
        install_micromamba_version "$version"
        ;;
    zsh)
        install_zsh_version "$version"
        ;;
    *)
        log_error "Installation method not defined for $tool"
        return 1
        ;;
    esac

    save_installed_version "$tool" "$version"
}

verify_dependencies() {
    local missing_deps=()

    for tool in "${!DEPENDENCIES[@]}"; do
        if ! check_version_compatibility "$tool" "${DEPENDENCIES[$tool]}"; then
            missing_deps+=("$tool")
        fi
    done

    if ((${#missing_deps[@]} > 0)); then
        log_error "Missing or incompatible dependencies: ${missing_deps[*]}"
        return 1
    fi

    log_success "All dependencies verified"
    return 0
}
