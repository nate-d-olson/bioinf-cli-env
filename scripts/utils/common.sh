#!/usr/bin/env bash
# Common utilities for bioinformatics environment setup and management
set -euo pipefail

# Logging utilities with color support
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

# Error handling
die() {
    log_error "$*"
    exit 1
}

# Command existence check
cmd_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Platform detection
detect_platform() {
    local os
    local arch
    
    case "$(uname -s)" in
        Darwin*)
            os="macos"
            ;;
        Linux*)
            if [ -f /etc/os-release ]; then
                os=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')
            else
                os="linux"
            fi
            ;;
        *)
            os="unknown"
            ;;
    esac
    
    case "$(uname -m)" in
        x86_64|amd64)
            arch="x86_64"
            ;;
        aarch64|arm64)
            arch="arm64"
            ;;
        *)
            arch="unknown"
            ;;
    esac
    
    echo "${os}-${arch}"
}

get_os() {
    echo "$1" | cut -d'-' -f1
}

get_arch() {
    echo "$1" | cut -d'-' -f2
}

# State management
STATE_DIR="${HOME}/.local/state/bioinf-cli-env"
mkdir -p "$STATE_DIR"

save_state() {
    local component="$1"
    local state="$2"
    echo "$state" > "$STATE_DIR/$component.state"
}

get_state() {
    local component="$1"
    local state_file="$STATE_DIR/$component.state"
    if [[ -f "$state_file" ]]; then
        cat "$state_file"
    else
        echo "not_installed"
    fi
}

# Configuration management
load_config() {
    local config_file="$1"
    if [[ ! -f "$config_file" ]]; then
        die "Configuration file not found: $config_file"
    fi
    
    # Source the config file in a subshell to validate syntax
    if ! ( set -e; source "$config_file" ); then
        die "Invalid configuration file: $config_file"
    fi
    
    # Source in current shell if validation passed
    source "$config_file"
}

# Package management detection
get_package_manager() {
    if cmd_exists apt-get; then
        echo "apt"
    elif cmd_exists yum; then
        echo "yum"
    elif cmd_exists brew; then
        echo "brew"
    else
        echo "unknown"
    fi
}

# Dependency installation
install_dependency() {
    local package="$1"
    local pkg_mgr
    pkg_mgr=$(get_package_manager)
    
    if ! cmd_exists "$package"; then
        log_info "Installing $package..."
        case "$pkg_mgr" in
            apt)
                sudo apt-get update && sudo apt-get install -y "$package"
                ;;
            yum)
                sudo yum install -y "$package"
                ;;
            brew)
                brew install "$package"
                ;;
            *)
                die "No supported package manager found"
                ;;
        esac
    fi
}

# Version comparison
version_gt() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

# Path manipulation
add_to_path() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        return 1
    fi
    
    if ! echo "$PATH" | tr ':' '\n' | grep -q "^$dir$"; then
        export PATH="$dir:$PATH"
    fi
}

# File operations
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cp "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
}

restore_file() {
    local file="$1"
    local backup
    backup=$(ls -t "${file}.backup."* 2>/dev/null | head -n1)
    if [[ -f "$backup" ]]; then
        mv "$backup" "$file"
        return 0
    fi
    return 1
}