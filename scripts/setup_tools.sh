#!/usr/bin/env bash
# Modern CLI tools installation script

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/common.sh"

# Set default paths
BIN_DIR="${HOME}/.local/bin"
mkdir -p "$BIN_DIR"

# Get installer type from arguments or auto-detect
INSTALLER="${1:-}"
if [[ -z "$INSTALLER" ]]; then
    PLATFORM=$(detect_platform)
    INSTALLER=$(get_installer "$PLATFORM")
fi

log_info "Installing modern CLI tools using $INSTALLER installer..."

# Function to install tools via package manager
install_via_package_manager() {
    local installer="$1"
    local tools=("${@:2}")

    # Add zsh to the list of tools if not already present
    if [[ " $installer " =~ " apt " || " $installer " =~ " yum " || " $installer " =~ " brew " ]]; then
        if ! printf '%s\n' "${tools[@]}" | grep -q -x "zsh"; then
            tools+=("zsh")
        fi
    fi

    case "$installer" in
    brew)
        log_info "Installing/updating tools via Homebrew..."
        # Update brew first
        brew update
        for tool in "${tools[@]}"; do
            if brew list "$tool" &>/dev/null; then
                log_success "$tool is already installed, checking for updates..."
                brew upgrade "$tool"
            else
                log_info "Installing $tool..."
                if brew install "$tool"; then
                    log_success "Installed $tool"
                else
                    log_error "Failed to install $tool"
                fi
            fi
        done
        ;;
    apt)
        log_info "Installing/updating tools via apt..."
        
        # Get sudo command with proper interactive prompting
        local sudo_cmd=""
        local no_interactive="${INTERACTIVE:-false}"
        if [[ "$no_interactive" == "false" ]]; then
            sudo_cmd=$(get_sudo_command "Administrator privileges are required to install packages via apt" "false")
        else 
            sudo_cmd=$(get_sudo_command "Administrator privileges are required to install packages via apt" "true")
        fi

        # First update package lists
        if [[ -n "$sudo_cmd" ]]; then
            $sudo_cmd apt-get update
        else
            log_warning "No sudo access. Cannot update package lists."
        fi

        for tool in "${tools[@]}"; do
            # Check if tool is already installed
            if dpkg -l | grep -qw "$tool"; then
                log_success "$tool is already installed"
                # Optionally attempt to upgrade
                # if [[ -n "$sudo_cmd" ]]; then
                #   $sudo_cmd apt-get install --only-upgrade -y "$tool"
                # fi
            else
                log_info "Installing $tool..."
                if [[ -n "$sudo_cmd" ]]; then
                    if $sudo_cmd apt-get install -y "$tool"; then
                        log_success "Installed $tool"
                    else
                        log_error "Failed to install $tool"
                    fi
                else
                    log_warning "No sudo access. Skipping $tool installation."
                fi
            fi
        done
        ;;
    yum)
        log_info "Installing/updating tools via yum..."
        
        # Get sudo command with proper interactive prompting
        local sudo_cmd=""
        local no_interactive="${INTERACTIVE:-false}"
        if [[ "$no_interactive" == "false" ]]; then
            sudo_cmd=$(get_sudo_command "Administrator privileges are required to install packages via yum" "false")
        else 
            sudo_cmd=$(get_sudo_command "Administrator privileges are required to install packages via yum" "true")
        fi

        for tool in "${tools[@]}"; do
            # Check if tool is already installed
            if rpm -q "$tool" &>/dev/null; then
                log_success "$tool is already installed"
                # Optionally attempt to upgrade
                # if [[ -n "$sudo_cmd" ]]; then
                #   $sudo_cmd yum update -y "$tool"
                # fi
            else
                log_info "Installing $tool..."
                if [[ -n "$sudo_cmd" ]]; then
                    if $sudo_cmd yum install -y "$tool"; then
                        log_success "Installed $tool"
                    else
                        log_error "Failed to install $tool"
                    fi
                else
                    log_warning "No sudo access. Skipping $tool installation."
                fi
            fi
        done
        ;;
    *)
        log_error "Unsupported package manager: $installer"
        return 1
        ;;
    esac

    return 0
}

# Function to get latest GitHub release URL
get_latest_release_url() {
    local repo="$1"
    local pattern="$2"
    local url="https://api.github.com/repos/$repo/releases/latest"

    # Try to fetch latest release info
    local release_info
    local download_url
    release_info=$(curl -s "$url")
    download_url=$(echo "$release_info" | grep -o "\"browser_download_url\": \"[^\"]*$pattern[^\"]*\"" | head -n 1 | cut -d '"' -f 4)

    if [[ -z "$download_url" ]]; then
        log_error "Could not find release asset matching pattern: $pattern"
        return 1
    fi

    echo "$download_url"
}

# Install tools based on the installer type
case "$INSTALLER" in
brew)
    # Homebrew packages
    install_via_package_manager brew \
        eza bat ripgrep fd jq fzf htop tmux zoxide yq
    ;;
apt)
    # Ubuntu/Debian packages
    # Note: exa/eza might not be available in older versions, handle it separately
    if apt-cache search --names-only '^eza$' | grep -q eza; then
        install_via_package_manager apt \
            eza bat ripgrep fd-find jq fzf htop tmux zoxide yq
    else
        install_via_package_manager apt \
            bat ripgrep fd-find jq fzf htop tmux zoxide yq

        # Install eza from GitHub release
        log_info "Installing eza from GitHub release..."
        PLATFORM=$(detect_platform)
        OS=$(get_os "$PLATFORM")
        ARCH=$(get_arch "$PLATFORM")

        if [[ "$ARCH" == "amd64" ]]; then
            EZA_URL=$(get_latest_release_url "eza-community/eza" "linux-x86_64")
            install_binary "eza" "$EZA_URL" "$BIN_DIR/eza" "$PLATFORM"
        elif [[ "$ARCH" == "arm64" ]]; then
            EZA_URL=$(get_latest_release_url "eza-community/eza" "linux-aarch64")
            install_binary "eza" "$EZA_URL" "$BIN_DIR/eza" "$PLATFORM"
        else
            log_warning "Unsupported architecture for eza: $ARCH. Skipping eza installation."
        fi
    fi

    # Create symlinks for fd-find
    if cmd_exists fdfind && ! cmd_exists fd; then
        # Quote command substitution to prevent word splitting
        ln -sf "$(which fdfind)" "$BIN_DIR/fd"
        log_success "Created fd symlink for fd-find"
    fi
    ;;
yum)
    # RHEL/CentOS packages
    install_via_package_manager yum \
        bat ripgrep fd-find jq fzf htop tmux

    # Install tools not available in repos
    log_info "Installing tools from GitHub releases..."
    PLATFORM=$(detect_platform)
    OS=$(get_os "$PLATFORM")
    ARCH=$(get_arch "$PLATFORM")

    # Install tools from GitHub releases

    # Install eza (or exa for older versions)
    if ! command -v eza &>/dev/null; then
        echo "Installing eza..."

        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS - try with Homebrew if available
            if command -v brew &>/dev/null; then
                brew install eza
            else
                echo "⚠️  Please install Homebrew to install eza on macOS, or install manually."
            fi
        else
            # Linux - download binary
            curl -sL "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz" | tar xz -C "$BIN_DIR" eza
            chmod +x "$BIN_DIR/eza"
        fi
    fi

    # Install bat
    if ! command -v bat &>/dev/null; then
        echo "Installing bat..."

        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS - try with Homebrew if available
            if command -v brew &>/dev/null; then
                brew install bat
            else
                echo "⚠️  Please install Homebrew to install bat on macOS, or install manually."
            fi
        else
            # Linux - download binary
            BAT_VERSION=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | grep -Po '"tag_name": "v\K[^"]*')
            curl -sLO "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
            tar xzf "bat-v${BAT_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
            mv "bat-v${BAT_VERSION}-x86_64-unknown-linux-gnu/bat" "$BIN_DIR/"
            rm -rf "bat-v${BAT_VERSION}-x86_64-unknown-linux-gnu" "bat-v${BAT_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
        fi
    fi

    # Install ripgrep
    if ! command -v rg &>/dev/null; then
        echo "Installing ripgrep..."

        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS - try with Homebrew if available
            if command -v brew &>/dev/null; then
                brew install ripgrep
            else
                echo "⚠️  Please install Homebrew to install ripgrep on macOS, or install manually."
            fi
        else
            # Linux - download binary
            RG_VERSION=$(curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep -Po '"tag_name": "\K[^"]*')
            curl -sLO "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz"
            tar xzf "ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz"
            mv "ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl/rg" "$BIN_DIR/"
            rm -rf "ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl" "ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz"
        fi
    fi

    # Install fd
    if ! command -v fd &>/dev/null; then
        echo "Installing fd..."

        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS - try with Homebrew if available
            if command -v brew &>/dev/null; then
                brew install fd
            else
                echo "⚠️  Please install Homebrew to install fd on macOS, or install manually."
            fi
        else
            # Linux - download binary
            FD_VERSION=$(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest | grep -Po '"tag_name": "v\K[^"]*')
            curl -sLO "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
            tar xzf "fd-v${FD_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
            mv "fd-v${FD_VERSION}-x86_64-unknown-linux-gnu/fd" "$BIN_DIR/"
            rm -rf "fd-v${FD_VERSION}-x86_64-unknown-linux-gnu" "fd-v${FD_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
        fi
    fi

    # Install zoxide
    ZOXIDE_URL=$(get_latest_release_url "ajeetdsouza/zoxide" "x86_64-unknown-linux-musl")
    install_binary "zoxide" "$ZOXIDE_URL" "$BIN_DIR/zoxide" "$PLATFORM"

    # Install yq
    YQ_URL=$(get_latest_release_url "mikefarah/yq" "linux_amd64")
    install_binary "yq" "$YQ_URL" "$BIN_DIR/yq" "$PLATFORM"
    ;;
user-space)
    # Install tools directly from GitHub releases
    log_info "Installing tools from GitHub releases in user space..."
    PLATFORM=$(detect_platform)
    OS=$(get_os "$PLATFORM")
    ARCH=$(get_arch "$PLATFORM")

    # Determine appropriate URLs based on platform
    if [[ "$OS" == "macos" ]]; then
        if [[ "$ARCH" == "amd64" ]]; then
            # macOS Intel
            BAT_URL=$(get_latest_release_url "sharkdp/bat" "x86_64-apple-darwin")
            EZA_URL=$(get_latest_release_url "eza-community/eza" "macos-x86_64")
            RIPGREP_URL=$(get_latest_release_url "BurntSushi/ripgrep" "x86_64-apple-darwin")
            FD_URL=$(get_latest_release_url "sharkdp/fd" "x86_64-apple-darwin")
            JQ_URL="https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64"
            ZOXIDE_URL=$(get_latest_release_url "ajeetdsouza/zoxide" "x86_64-apple-darwin")
            YQ_URL=$(get_latest_release_url "mikefarah/yq" "darwin_amd64")
        elif [[ "$ARCH" == "arm64" ]]; then
            # macOS Apple Silicon
            BAT_URL=$(get_latest_release_url "sharkdp/bat" "aarch64-apple-darwin")
            EZA_URL=$(get_latest_release_url "eza-community/eza" "macos-aarch64")
            RIPGREP_URL=$(get_latest_release_url "BurntSushi/ripgrep" "aarch64-apple-darwin")
            FD_URL=$(get_latest_release_url "sharkdp/fd" "aarch64-apple-darwin")
            JQ_URL="https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64" # No arm64 build, but Intel works via Rosetta
            ZOXIDE_URL=$(get_latest_release_url "ajeetdsouza/zoxide" "aarch64-apple-darwin")
            YQ_URL=$(get_latest_release_url "mikefarah/yq" "darwin_arm64")
        else
            log_error "Unsupported architecture: $ARCH"
            exit 1
        fi
    elif [[ "$OS" == "linux" || "$OS" == "ubuntu" || "$OS" == "debian" || "$OS" == "redhat" ]]; then
        if [[ "$ARCH" == "amd64" ]]; then
            # Linux x86_64
            BAT_URL=$(get_latest_release_url "sharkdp/bat" "x86_64-unknown-linux-musl")
            EZA_URL=$(get_latest_release_url "eza-community/eza" "linux-x86_64")
            RIPGREP_URL=$(get_latest_release_url "BurntSushi/ripgrep" "x86_64-unknown-linux-musl")
            FD_URL=$(get_latest_release_url "sharkdp/fd" "x86_64-unknown-linux-musl")
            JQ_URL="https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
            ZOXIDE_URL=$(get_latest_release_url "ajeetdsouza/zoxide" "x86_64-unknown-linux-musl")
            YQ_URL=$(get_latest_release_url "mikefarah/yq" "linux_amd64")
        elif [[ "$ARCH" == "arm64" ]]; then
            # Linux aarch64
            BAT_URL=$(get_latest_release_url "sharkdp/bat" "aarch64-unknown-linux-musl")
            EZA_URL=$(get_latest_release_url "eza-community/eza" "linux-aarch64")
            RIPGREP_URL=$(get_latest_release_url "BurntSushi/ripgrep" "aarch64-unknown-linux-musl")
            FD_URL=$(get_latest_release_url "sharkdp/fd" "aarch64-unknown-linux-musl")
            JQ_URL="https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" # No arm64 build
            ZOXIDE_URL=$(get_latest_release_url "ajeetdsouza/zoxide" "aarch64-unknown-linux-musl")
            YQ_URL=$(get_latest_release_url "mikefarah/yq" "linux_arm64")
        else
            log_error "Unsupported architecture: $ARCH"
            exit 1
        fi
    else
        log_error "Unsupported operating system: $OS"
        exit 1
    fi

    # Install each tool
    install_binary "bat" "$BAT_URL" "$BIN_DIR/bat" "$PLATFORM"
    install_binary "eza" "$EZA_URL" "$BIN_DIR/eza" "$PLATFORM"
    install_binary "rg" "$RIPGREP_URL" "$BIN_DIR/rg" "$PLATFORM"
    install_binary "fd" "$FD_URL" "$BIN_DIR/fd" "$PLATFORM"
    install_binary "jq" "$JQ_URL" "$BIN_DIR/jq" "$PLATFORM"
    install_binary "zoxide" "$ZOXIDE_URL" "$BIN_DIR/zoxide" "$PLATFORM"
    install_binary "yq" "$YQ_URL" "$BIN_DIR/yq" "$PLATFORM"

    # Install fzf
    if [[ ! -d "$HOME/.fzf" ]]; then
        log_info "Installing fzf..."
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
        "$HOME/.fzf/install" --bin
        ln -sf "$HOME/.fzf/bin/fzf" "$BIN_DIR/fzf"
        log_success "Installed fzf"
    else
        log_success "fzf is already installed"
    fi

    # Install htop and tmux only if we have sudo (these are harder to compile/install as binaries)
    local sudo_cmd=""
    local no_interactive="${INTERACTIVE:-false}"
    if [[ "$no_interactive" == "false" ]]; then
        sudo_cmd=$(get_sudo_command "Administrator privileges are required to install htop and tmux" "false")
    else 
        sudo_cmd=$(get_sudo_command "Administrator privileges are required to install htop and tmux" "true")
    fi
    
    if [[ -n "$sudo_cmd" ]]; then
        case "$OS" in
        macos)
            if cmd_exists brew; then
                brew install htop tmux
            else
                log_warning "Please install htop and tmux manually"
            fi
            ;;
        ubuntu | debian)
            $sudo_cmd apt-get install -y htop tmux
            ;;
        redhat)
            $sudo_cmd yum install -y htop tmux
            ;;
        *)
            log_warning "Please install htop and tmux manually"
            ;;
        esac
    else
        log_warning "No sudo access. Please install htop and tmux manually."
    fi
    ;;
*)
    log_error "Unknown installer type: $INSTALLER. Use brew, apt, yum, or user-space."
    exit 1
    ;;
esac

# Add tool aliases to zshrc if not already present
if ! grep -q "# === bioinf-cli-env tool aliases ===" "$HOME/.zshrc"; then
    log_info "Adding tool aliases to .zshrc..."

    cat >>"$HOME/.zshrc" <<'ENDALIASES'

# === bioinf-cli-env tool aliases ===
# Modern CLI tool aliases

# Replace ls with eza if available
if command -v eza &>/dev/null; then
  alias ls="eza --group-directories-first"
  alias ll="eza -l --group-directories-first --time-style=long-iso"
  alias la="eza -la --group-directories-first --time-style=long-iso"
  alias lt="eza -T --level=2 --group-directories-first"
  alias llt="eza -lT --level=2 --group-directories-first"
fi

# Replace cat with bat if available
if command -v bat &>/dev/null; then
  alias cat="bat --plain --wrap=character"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# Add ripgrep and fd aliases
if command -v rg &>/dev/null; then
  alias grep="rg"
  alias rgi="rg -i"  # Case insensitive search
fi

if command -v fd &>/dev/null; then
  alias find="fd"
fi

# Initialize zoxide if available
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
  alias cd="z"
fi

# Initialize fzf if available
if [ -f ~/.fzf.zsh ]; then
  source ~/.fzf.zsh
fi

# Other useful aliases
alias h="history"
alias path='echo $PATH | tr ":" "\n"'
alias now='date +"%T"'
alias clr='clear'
# === End bioinf-cli-env tool aliases ===
ENDALIASES

    log_success "Tool aliases added to .zshrc"
fi

log_success "Modern CLI tools installation complete!"
