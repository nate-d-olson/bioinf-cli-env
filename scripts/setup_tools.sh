#!/usr/bin/env bash
# Setup modern CLI tools explicitly for different platforms
set -euo pipefail

PACKAGE_MANAGER=$1

log_info() { echo -e "[INFO] $*"; }
log_warning() { echo -e "[WARN] $*"; }

install_tools_brew() {
    brew install bat eza ripgrep fd jq fzf htop tmux zoxide yq || { log_warning "Some tools may not have been installed correctly."; }
}

install_tools_apt() {
    sudo apt-get update
    # eza is the actively maintained fork of the unmaintained exa
    sudo apt-get install -y bat eza ripgrep fd-find jq fzf htop tmux zoxide python3-yq || { log_warning "Some tools may not have installed. Verify manually."; }
}

install_tools_userspace() {
    log_info "Installing user-space versions of CLI tools..."
    local bin_dir="${HOME}/.local/bin"
    mkdir -p "$bin_dir"

    # Detect OS and architecture for binary downloads
    local os arch triple
    case "$(uname -s)" in
        Linux*)  os="linux"  ;;
        Darwin*) os="macos"  ;;
        *) log_warning "Unsupported OS: $(uname -s)"; return 1 ;;
    esac
    case "$(uname -m)" in
        x86_64)         arch="x86_64"  ;;
        aarch64|arm64)  arch="aarch64" ;;
        *) log_warning "Unsupported architecture: $(uname -m)"; return 1 ;;
    esac

    # Build the target triple used by GitHub release archives
    if [[ "$os" == "macos" ]]; then
        triple="${arch}-apple-darwin"
    else
        triple="${arch}-unknown-linux-musl"
    fi

    # fzf: has its own install script
    if ! command -v fzf &>/dev/null; then
        log_info "Installing fzf..."
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" \
            && "$HOME/.fzf/install" --bin \
            && ln -sf "$HOME/.fzf/bin/fzf" "$bin_dir/fzf" \
            || log_warning "fzf installation failed"
    fi

    # zoxide: has its own install script
    if ! command -v zoxide &>/dev/null; then
        log_info "Installing zoxide..."
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \
            | sh \
            || log_warning "zoxide installation failed"
    fi

    # bat: download pre-built binary from GitHub releases
    if ! command -v bat &>/dev/null && ! command -v batcat &>/dev/null; then
        log_info "Installing bat..."
        local bat_version="0.24.0"
        local bat_archive="bat-v${bat_version}-${triple}"
        curl -fsSL "https://github.com/sharkdp/bat/releases/download/v${bat_version}/${bat_archive}.tar.gz" \
            | tar -xz -C /tmp \
            && install -m0755 "/tmp/${bat_archive}/bat" "$bin_dir/bat" \
            && rm -rf "/tmp/${bat_archive}" \
            || log_warning "bat installation failed"
    fi

    # ripgrep: download pre-built binary from GitHub releases
    if ! command -v rg &>/dev/null; then
        log_info "Installing ripgrep..."
        local rg_version="14.1.0"
        local rg_archive="ripgrep-${rg_version}-${triple}"
        curl -fsSL "https://github.com/BurntSushi/ripgrep/releases/download/${rg_version}/${rg_archive}.tar.gz" \
            | tar -xz -C /tmp \
            && install -m0755 "/tmp/${rg_archive}/rg" "$bin_dir/rg" \
            && rm -rf "/tmp/${rg_archive}" \
            || log_warning "ripgrep installation failed"
    fi

    # fd: download pre-built binary from GitHub releases
    if ! command -v fd &>/dev/null && ! command -v fdfind &>/dev/null; then
        log_info "Installing fd..."
        local fd_version="9.0.0"
        local fd_archive="fd-v${fd_version}-${triple}"
        curl -fsSL "https://github.com/sharkdp/fd/releases/download/v${fd_version}/${fd_archive}.tar.gz" \
            | tar -xz -C /tmp \
            && install -m0755 "/tmp/${fd_archive}/fd" "$bin_dir/fd" \
            && rm -rf "/tmp/${fd_archive}" \
            || log_warning "fd installation failed"
    fi

    log_info "User-space tool installation complete. Ensure $bin_dir is in your PATH."
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