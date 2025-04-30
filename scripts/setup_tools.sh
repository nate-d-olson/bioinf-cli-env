#!/usr/bin/env bash
# Modern CLI tools installation script
# This script installs essential CLI tools for bioinformatics work

# Strict mode
set -euo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils/common.sh
source "$SCRIPT_DIR/utils/common.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running in non-interactive mode
NONINTERACTIVE=false
if [[ -n "${BIOINF_NON_INTERACTIVE:-}" ]]; then
    NONINTERACTIVE=true
    log_info "Running in non-interactive mode"
fi

# Set default paths
BIN_DIR="${HOME}/.local/bin"
mkdir -p "$BIN_DIR"

# Create a log file for installed package versions
LOG_FILE="${HOME}/.bioinf-cli-env-tools.log"
echo "# Bioinformatics CLI Environment Tool Installation Log - $(date)" > "$LOG_FILE"
echo "# This file contains version information for installed CLI tools" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Helper functions
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; echo "[ERROR] $*" >> "$LOG_FILE"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; echo "[WARN] $*" >> "$LOG_FILE"; }
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; echo "[INFO] $*" >> "$LOG_FILE"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; echo "[SUCCESS] $*" >> "$LOG_FILE"; }

# Get installer type from arguments or auto-detect
INSTALLER="${1:-}"
if [[ -z "$INSTALLER" ]]; then
    if command -v brew &>/dev/null; then
        INSTALLER="brew"
    elif command -v apt-get &>/dev/null; then
        INSTALLER="apt"
    else
        INSTALLER="unknown"
    fi
fi

log_info "Installing modern CLI tools using $INSTALLER installer..."
echo "Installation platform: $(uname -s)" >> "$LOG_FILE"
echo "Package manager: $INSTALLER" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Check for supported platform
if [[ "$INSTALLER" != "apt" && "$INSTALLER" != "brew" ]]; then
    log_warning "This script is primarily designed for Ubuntu (apt) and macOS (brew)."
    log_warning "Some package installations may not work correctly on your system."
    echo "UNSUPPORTED PLATFORM WARNING: This system uses $INSTALLER" >> "$LOG_FILE"
fi

# Create temporary files that will be cleaned up on exit
TEMP_DIR=$(mktemp -d)
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Function to record version information
record_version() {
    local package="$1"
    local version="$2"
    
    echo "✓ $package: $version" >> "$LOG_FILE"
    log_success "$package installed: $version"
}

# Function to check if a package is already installed
is_installed() {
    local package="$1"
    local version_cmd="$2"
    local version_output
    
    if ! command -v "$package" &>/dev/null; then
        return 1
    fi
    
    version_output=$(eval "$version_cmd" 2>/dev/null || echo "unknown version")
    record_version "$package" "$version_output"
    return 0
}

# Function to check if package is available via package manager
is_package_available() {
    local package="$1"
    
    case "$INSTALLER" in
    apt)
        # Special case for fd-find package on Debian/Ubuntu
        if [[ "$package" == "fd-find" ]]; then
            apt-cache search --names-only "^fd-find$" 2>/dev/null | grep -q "fd-find" && return 0
        fi
        
        apt-cache search --names-only "^$package$" 2>/dev/null | grep -q -i "$package" || \
        apt-cache search --names-only "$package" 2>/dev/null | grep -q -i "$package"
        ;;
    brew)
        brew info "$package" &>/dev/null
        ;;
    *)
        return 1
        ;;
    esac
}

# Function to install via package manager
install_package() {
    local package="$1"
    
    case "$INSTALLER" in
    brew)
        log_info "Installing $package via Homebrew..."
        if brew install "$package"; then
            local version=$(brew info --json "$package" | jq -r '.[0].installed[0].version' 2>/dev/null || echo "unknown")
            record_version "$package" "$version (via brew)"
            return 0
        else
            log_error "Failed to install $package via brew"
            return 1
        fi
        ;;
    apt)
        log_info "Installing $package via apt..."
        
        # Handle special cases for package names that differ from the command
        if [[ "$package" == "fd" ]]; then
            package="fd-find"
        fi
        
        # Check if we can use sudo non-interactively
        local sudo_cmd="sudo"
        if [[ "$NONINTERACTIVE" == "true" ]]; then
            if ! sudo -n true 2>/dev/null; then
                log_warning "No sudo access available in non-interactive mode. Will try direct installation."
                sudo_cmd=""
            fi
        fi
        
        if [[ -n "$sudo_cmd" ]]; then
            if $sudo_cmd apt-get update && $sudo_cmd apt-get install -y "$package"; then
                local version=$(dpkg -s "$package" 2>/dev/null | grep "^Version:" | cut -d ' ' -f 2)
                record_version "$package" "$version (via apt)"
                return 0
            else
                log_error "Failed to install $package via apt with sudo"
                return 1
            fi
        else
            # Try without sudo (may work in some environments)
            if apt-get update && apt-get install -y "$package"; then
                local version=$(dpkg -s "$package" 2>/dev/null | grep "^Version:" | cut -d ' ' -f 2)
                record_version "$package" "$version (via apt)"
                return 0
            else
                # Try direct download as fallback for non-interactive mode
                if [[ -n "$github_url" ]]; then
                    log_info "Attempting direct download instead..."
                    install_binary "$package" "$github_url"
                    return $?
                else
                    log_error "Failed to install $package via apt without sudo"
                    return 1
                fi
            fi
        fi
        ;;
    *)
        log_error "Unsupported package manager: $INSTALLER"
        return 1
        ;;
    esac
}

# Function to install binary from URL
install_binary() {
    local name="$1"
    local url="$2"
    local dest="$BIN_DIR/$name"
    
    log_info "Installing $name from $url..."
    
    # Download the file
    local download_file="$TEMP_DIR/${name}_download"
    if curl -fsSL "$url" -o "$download_file"; then
        if [[ "$url" == *.tar.gz || "$url" == *.tgz ]]; then
            # Extract tarball
            mkdir -p "$TEMP_DIR/extract"
            if tar -xzf "$download_file" -C "$TEMP_DIR/extract"; then
                # Find the binary
                local binary_file
                binary_file=$(find "$TEMP_DIR/extract" -type f -name "$name" -perm -u=x | head -n 1)
                
                if [[ -n "$binary_file" ]]; then
                    cp "$binary_file" "$dest"
                else
                    # Try to find any executable
                    binary_file=$(find "$TEMP_DIR/extract" -type f -perm -u=x | head -n 1)
                    if [[ -n "$binary_file" ]]; then
                        cp "$binary_file" "$dest"
                    else
                        log_error "Could not find binary in extracted files"
                        return 1
                    fi
                fi
            else
                log_error "Failed to extract $name tarball"
                return 1
            fi
        else
            # Direct binary download
            cp "$download_file" "$dest"
        fi
        
        # Make executable
        chmod +x "$dest"
        
        if [[ -f "$dest" && -x "$dest" ]]; then
            local version_output
            version_output=$("$dest" --version 2>/dev/null || "$dest" -v 2>/dev/null || echo "version unknown")
            record_version "$name" "$version_output (manually installed)"
            return 0
        else
            log_error "Failed to install $name to $dest"
            return 1
        fi
    else
        log_error "Failed to download $name from $url"
        return 1
    fi
}

# Function to handle package installation
install_tool() {
    local tool="$1"
    local version_cmd="$2"
    local alt_name="${3:-}"
    local github_url="${4:-}"
    
    # Check if already installed under primary name
    if is_installed "$tool" "$version_cmd"; then
        return 0
    fi
    
    # Check if already installed under alternative name
    if [[ -n "$alt_name" ]] && is_installed "$alt_name" "$version_cmd"; then
        log_info "Using $alt_name instead of $tool"
        return 0
    fi
    
    log_info "$tool is not installed. Checking availability..."
    
    # Skip apt package manager for tools that don't have apt packages
    if [[ "$INSTALLER" == "apt" && "$tool" == "dust" ]]; then
        if [[ -n "$github_url" ]]; then
            log_info "$tool not available via apt, installing from GitHub..."
            install_binary "$tool" "$github_url"
            return $?
        fi
    fi
    
    # Try package manager installation
    if is_package_available "$tool"; then
        install_package "$tool"
        return $?
    elif [[ -n "$alt_name" ]] && is_package_available "$alt_name"; then
        install_package "$alt_name"
        # Create symlink if necessary
        if [[ $? -eq 0 && -n "$tool" && "$tool" != "$alt_name" ]]; then
            if command -v "$alt_name" &>/dev/null; then
                ln -sf "$(command -v "$alt_name")" "$BIN_DIR/$tool"
                log_success "Created $tool symlink pointing to $alt_name"
            fi
        fi
        return $?
    fi
    
    # Try GitHub installation if URL provided
    if [[ -n "$github_url" ]]; then
        log_info "$tool not available via $INSTALLER, installing from GitHub..."
        install_binary "$tool" "$github_url"
        return $?
    fi
    
    # If we get here, we couldn't install the tool
    log_error "Unable to install $tool automatically."
    local url="https://github.com/search?q=$tool"
    log_info "Please install $tool manually from: $url"
    return 1
}

# Install tools based on the installer type
echo "Installing modern CLI tools..."

# Define tools with version commands and fallbacks
declare -A TOOLS
TOOLS=(
    ["bat"]="bat --version|batcat is an alternative"
    ["eza"]="eza --version|exa is an alternative|https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-musl.tar.gz"
    ["ripgrep"]="rg --version"
    ["fd"]="fd --version|fd-find|https://github.com/sharkdp/fd/releases/download/v8.7.0/fd-v8.7.0-x86_64-unknown-linux-musl.tar.gz"
    ["jq"]="jq --version|https://github.com/jqlang/jq/releases/download/jq-1.7/jq-linux-amd64"
    ["fzf"]="fzf --version"
    ["htop"]="htop --version | head -n 1"
    ["tmux"]="tmux -V"
    ["delta"]="delta --version|https://github.com/dandavison/delta/releases/download/0.16.5/delta-0.16.5-x86_64-unknown-linux-gnu.tar.gz"
    ["dust"]="dust --version|https://github.com/bootandy/dust/releases/download/v0.8.6/dust-v0.8.6-x86_64-unknown-linux-musl.tar.gz"
    ["procs"]="procs --version|https://github.com/dalance/procs/releases/download/v0.14.3/procs-v0.14.3-x86_64-linux.zip"
    ["zoxide"]="zoxide --version|https://github.com/ajeetdsouza/zoxide/releases/download/v0.9.2/zoxide-0.9.2-x86_64-unknown-linux-musl.tar.gz"
    ["yq"]="yq --version|https://github.com/mikefarah/yq/releases/download/v4.35.1/yq_linux_amd64"
)

# Process each tool
for tool in "${!TOOLS[@]}"; do
    # Split the value by |
    IFS='|' read -r version_cmd alt_name github_url <<< "${TOOLS[$tool]}"
    install_tool "$tool" "$version_cmd" "$alt_name" "$github_url"
done

# Create necessary symlinks for tools with different names
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    ln -sf "$(command -v batcat)" "$BIN_DIR/bat"
    log_success "Created bat symlink for batcat"
fi

if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    ln -sf "$(command -v fdfind)" "$BIN_DIR/fd"
    log_success "Created fd symlink for fdfind"
fi

if command -v exa &>/dev/null && ! command -v eza &>/dev/null; then
    ln -sf "$(command -v exa)" "$BIN_DIR/eza"
    log_success "Created eza symlink for exa"
fi

# Check if all required tools are now available
echo "" >> "$LOG_FILE"
echo "# Final installation status" >> "$LOG_FILE"

# List of core tools to check
CORE_TOOLS=("bat" "eza" "ripgrep" "fd" "jq" "fzf" "htop" "tmux" "zoxide" "yq")
MISSING_TOOLS=()

for tool in "${CORE_TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        # Check for alternative names
        case "$tool" in
            bat) [[ -x "$(command -v batcat 2>/dev/null)" ]] && continue ;;
            eza) [[ -x "$(command -v exa 2>/dev/null)" ]] && continue ;;
            ripgrep) [[ -x "$(command -v rg 2>/dev/null)" ]] && continue ;;
            fd) [[ -x "$(command -v fdfind 2>/dev/null)" ]] && continue ;;
        esac
        MISSING_TOOLS+=("$tool")
    fi
done

if [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then
    log_warning "Some tools are still not available in PATH:"
    for tool in "${MISSING_TOOLS[@]}"; do
        echo "  - $tool"
    done
    log_info "You may need to restart your shell or add $BIN_DIR to your PATH"
    
    echo "WARNING: Some tools are not available in PATH: ${MISSING_TOOLS[*]}" >> "$LOG_FILE"
    echo "You may need to restart your shell or add $BIN_DIR to your PATH" >> "$LOG_FILE"
else
    log_success "All core CLI tools are available!"
    echo "SUCCESS: All core CLI tools are installed and available" >> "$LOG_FILE"
fi

log_success "Modern CLI tools installation complete!"
echo "" >> "$LOG_FILE"
echo "# Installation completed at $(date)" >> "$LOG_FILE"
echo "Log file saved to: $LOG_FILE"
