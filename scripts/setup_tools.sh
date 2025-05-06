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

# Define tools to install (removed yq)
TOOLS=("bat" "exa" "ripgrep" "fd-find" "jq" "fzf" "htop" "tmux" "zoxide")

install_tools_brew() {
    brew update
    brew install "${TOOLS[@]}" yq
}

install_tools_apt() {
    sudo apt-get update

    # Install tools using apt
    for tool in "${TOOLS[@]}"; do
        if [[ "$tool" == "bat" ]]; then
            sudo apt-get install -y bat
            sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
        elif [[ "$tool" == "fd-find" ]]; then
            sudo apt-get install -y fd-find
            sudo ln -sf /usr/bin/fd-find /usr/local/bin/fd
        else
            sudo apt-get install -y "$tool"
        fi
    done

    # Explicitly install yq from official release to avoid apt issues
    YQ_BINARY="${BIN_DIR}/yq"
    sudo curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o "$YQ_BINARY"
    sudo chmod +x "$YQ_BINARY"
    log_success "yq installed successfully via official release."
}

main() {
    case "$INSTALLER" in
        "brew")
            install_tools_brew
            ;;
        "apt")
            install_tools_apt
            ;;
        *)
            log_error "Unsupported installer: $INSTALLER"
            exit 1
            ;;
    esac

    log_success "CLI tools installation completed."
}

main "$@"