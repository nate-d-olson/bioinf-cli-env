#!/usr/bin/env bash
# Common utilities for bioinformatics environment setup and management
set -euo pipefail

# Logging utilities with color support
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging configuration
: "${LOG_LEVEL:=INFO}"
: "${LOG_FILE:=${HOME}/.local/log/bioinf-cli-env.log}"
mkdir -p "$(dirname "$LOG_FILE")"

# Temporary files tracking
declare -a TEMP_FILES=()
declare -a TEMP_DIRS=()

# Signal handling for cleanup
cleanup() {
    local exit_code=$?
    log_info "Performing cleanup..."
    
    # Remove temporary files
    for file in "${TEMP_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            log_debug "Removed temporary file: $file"
        fi
    done
    
    # Remove temporary directories
    for dir in "${TEMP_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            log_debug "Removed temporary directory: $dir"
        fi
    done
    
    exit "$exit_code"
}

trap cleanup EXIT
trap 'trap - EXIT; cleanup; exit 1' INT TERM

# Enhanced logging with levels and file output
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log to file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Log to console based on level
    case "$level" in
        ERROR)
            [[ "$LOG_LEVEL" =~ ^(ERROR|WARN|INFO|DEBUG)$ ]] && echo -e "${RED}[ERROR]${NC} $message" >&2
            ;;
        WARN)
            [[ "$LOG_LEVEL" =~ ^(WARN|INFO|DEBUG)$ ]] && echo -e "${YELLOW}[WARN]${NC} $message" >&2
            ;;
        INFO)
            [[ "$LOG_LEVEL" =~ ^(INFO|DEBUG)$ ]] && echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        DEBUG)
            [[ "$LOG_LEVEL" == "DEBUG" ]] && echo -e "[DEBUG] $message"
            ;;
    esac
}

log_error() { log ERROR "$@"; }
log_warning() { log WARN "$@"; }
log_info() { log INFO "$@"; }
log_debug() { log DEBUG "$@"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }

# Enhanced error handling with stack trace
die() {
    local message=$1
    local code=${2:-1}
    local stack
    
    # Generate stack trace
    stack=$(
        local frame=0
        while caller $frame; do
            ((frame++))
        done
    )
    
    log_error "$message"
    log_debug "Stack trace:\n$stack"
    exit "$code"
}

# Enhanced platform detection
detect_platform() {
    local os
    local arch
    local variant=""
    
    # Detect OS
    case "$(uname -s)" in
        Darwin*)
            os="darwin"
            # Detect macOS version
            version=$(sw_vers -productVersion)
            variant="macOS_${version%%.*}"
            ;;
        Linux*)
            os="linux"
            # Detect Linux distribution
            if [[ -f /etc/os-release ]]; then
                source /etc/os-release
                variant="${ID}_${VERSION_ID%%.*}"
            fi
            ;;
        *)
            os="unknown"
            ;;
    esac
    
    # Detect architecture with support for ARM
    case "$(uname -m)" in
        x86_64*)
            # Check for Rosetta on macOS
            if [[ "$os" == "darwin" ]] && sysctl -n sysctl.proc_translated >/dev/null 2>&1; then
                arch="arm64"
            else
                arch="amd64"
            fi
            ;;
        aarch64*|arm64*)
            arch="arm64"
            ;;
        armv7*|armv8*)
            arch="arm"
            ;;
        *)
            arch="$(uname -m)"
            ;;
    esac
    
    echo "${os}_${arch}${variant:+_}${variant}"
}

# Check if a command exists
cmd_exists() {
    command -v "$1" >/dev/null 2>&1
}

get_os() {
    echo "$1" | cut -d'_' -f1
}

get_arch() {
    echo "$1" | cut -d'_' -f2
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

# Configuration validation
validate_config() {
    local config_file=$1
    local schema_file=${2:-""}
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    # Basic syntax check
    if ! bash -n "$config_file"; then
        log_error "Invalid shell syntax in configuration file"
        return 1
    fi
    
    # Schema validation if provided
    if [[ -n "$schema_file" && -f "$schema_file" ]]; then
        if command -v jq >/dev/null; then
            if ! jq -e --argfile schema "$schema_file" '. as $config | $schema' "$config_file" >/dev/null; then
                log_error "Configuration validation failed against schema"
                return 1
            fi
        else
            log_warning "jq not found, skipping schema validation"
        fi
    fi
    
    return 0
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
backup_config() {  # Renamed from backup_file
    local file=$1
    local backup_dir=${2:-"${HOME}/.local/backup/bioinf-cli-env"}
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    if [[ ! -f "$file" ]]; then
        log_warning "File not found for backup: $file"
        return 0
    fi
    
    mkdir -p "$backup_dir"
    local backup_file="${backup_dir}/$(basename "$file").${timestamp}"
    
    if cp -p "$file" "$backup_file"; then
        log_info "Created backup: $backup_file"
        echo "$backup_file"
    else
        log_error "Failed to create backup of $file"
        return 1
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

# Temporary file management
create_temp_file() {
    local template=${1:-"tmp.XXXXXXXXXX"}
    local tmp_file
    tmp_file=$(mktemp -t "$template")
    TEMP_FILES+=("$tmp_file")
    echo "$tmp_file"
}

create_temp_dir() {
    local template=${1:-"tmp.XXXXXXXXXX"}
    local tmp_dir
    tmp_dir=$(mktemp -d -t "$template")
    TEMP_DIRS+=("$tmp_dir")
    echo "$tmp_dir"
}

# Progress indicator
show_progress() {
    local current=$1
    local total=$2
    local width=${3:-50}
    local message=${4:-"Progress"}
    
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r%s [%s%s] %d%%" \
        "$message" \
        "$(printf '#%.0s' $(seq 1 "$filled"))" \
        "$(printf '.%.0s' $(seq 1 "$empty"))" \
        "$percentage"
    
    if ((current == total)); then
        echo
    fi
}

# Safe download function
safe_download() {
    local url="$1"
    local output="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$output"
    else
        log_error "Neither curl nor wget is available for downloading."
        return 1
    fi

    if [[ ! -f "$output" ]]; then
        log_error "Failed to download $url to $output."
        return 1
    fi

    log_success "Downloaded $url to $output."
    return 0
}