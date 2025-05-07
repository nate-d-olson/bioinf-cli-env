#!/bin/bash
# Setup modern CLI tools explicitly for different platforms
set -euo pipefail

PACKAGE_MANAGER=$1

log_info() { echo -e "[INFO] $*"; }
log_warning() { echo -e "[WARN] $*"; }

install_tools_brew() {
    brew install bat exa ripgrep fd jq fzf htop tmux zoxide yq || { log_warning "Some tools may not have been installed correctly."; }
}

install_tools_apt() {
    apt-get update
    # Note: using 'exa' instead of 'eza'
    apt-get install -y bat exa ripgrep fd-find jq fzf htop tmux zoxide yq || { log_warning "Some tools may not have installed. Verify manually."; }
}

install_tools_userspace() {
    echo "[INFO] Installing user-space versions of CLI tools..."
    # Consider providing explicit download links, installation scripts, or containerized deployments.
}

case "$PACKAGE_MANAGER" in
    brew)
        log_info "Using brew to install CLI tools..."
        install_tools_brew
        ;;
    apt)
        log_info "Using apt to install CLI tools on Ubuntu..."
        install_tools_apt
        ;;
    userspace)
        log_info "Using user-space installation method."
        install_tools_userspace
        ;;
    *)
        log_warning "Unsupported package manager: $PACKAGE_MANAGER"
        exit 1
        ;;
esac

log_info "Performing cleanup..."