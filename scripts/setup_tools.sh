#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/common.sh"

BIN_DIR="${HOME}/.local/bin"
mkdir -p "$BIN_DIR"

# Detect package manager
if command -v brew &>/dev/null; then
    INSTALLER="brew"
elif command -v apt-get &>/dev/null; then
    INSTALLER="apt"
else
    log_error "Unsupported platform. Only Homebrew (macOS) and apt (Ubuntu) are supported."
    exit 1
fi

log_info "Using $INSTALLER to install CLI tools..."

# Define tools to install
TOOLS=("bat" "eza" "ripgrep" "fd" "jq" "fzf" "htop" "tmux" "zoxide" "yq")

check_available_tools() {
    local available_tools=()
    for tool in "${TOOLS[@]}"; do
        case "$INSTALLER" in
            brew)
                if brew info "$tool" &>/dev/null; then
                    available_tools+=("$tool")
                else
                    log_warning "$tool not available via brew"
                fi
                ;;
            apt)
                if apt-cache show "$tool" &>/dev/null; then
                    available_tools+=("$tool")
                else
                    log_warning "$tool not available via apt"
                fi
                ;;
        esac
    done
    echo "${available_tools[@]}"
}

install_available_tools() {
    local tools_to_install=()
    local snap_tools=()

    for tool in "$@"; do
        if apt-cache show "$tool" &>/dev/null; then
            tools_to_install+=("$tool")
        else
            snap_tools+=("$tool")
        fi
    done

    if [ ${#tools_to_install[@]} -gt 0 ]; then
        sudo apt-get update && sudo apt-get install -y "${tools_to_install[@]}" && log_success "Installed tools via apt: ${tools_to_install[*]}"
    fi

    if [ ${#snap_tools[@]} -gt 0 ]; then
        for snap_tool in "${snap_tools[@]}"; do
            sudo snap install "$snap_tool" && log_success "Installed $snap_tool via snap"
        done
    fi
}

check_installed_tools() {
    local tools_to_install=()
    for tool in "${TOOLS[@]}"; do
        if command -v "$tool" &>/dev/null; then
            log_info "$tool is already installed: $(command -v $tool), version: $($tool --version | head -n 1)" >&2
        else
            tools_to_install+=("$tool")
        fi
    done
    echo "${tools_to_install[@]}"
}

main() {
    local tools_to_install
    tools_to_install=$(check_installed_tools)

    if [ -n "$tools_to_install" ]; then
        log_info "Installing tools: $tools_to_install"
        install_available_tools "$tools_to_install"
    else
        log_success "All tools are already installed."
    fi
}

main "$@"