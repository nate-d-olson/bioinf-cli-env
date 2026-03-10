#!/usr/bin/env bash
# Oh My Zsh and Powerlevel10k setup script
# Installs Oh My Zsh, Powerlevel10k theme, and essential plugins

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions (define logging functions early)
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }

# Get the config directory from arguments or use default
CONFIG_DIR="${1:-$(pwd)/config}"

# Check if running in non-interactive mode
NONINTERACTIVE=false
if [[ -n "${BIOINF_NON_INTERACTIVE:-}" ]]; then
    NONINTERACTIVE=true
    log_info "Running in non-interactive mode"
fi

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if zsh is installed
if ! command_exists zsh; then
    log_error "zsh is not installed! Please install it first."
    OS_TYPE="$(uname -s)"

    if [[ "$OS_TYPE" == "Darwin" ]]; then
        log_info "macOS: Try installing with 'brew install zsh'"
    elif [[ -f /etc/debian_version ]]; then
        log_info "Ubuntu/Debian: Try installing with 'sudo apt install -y zsh'"
    elif [[ -f /etc/redhat-release ]]; then
        log_info "RHEL/CentOS: Try installing with 'sudo yum install -y zsh'"
    else
        log_info "Please install zsh using your system's package manager."
    fi
    exit 1
fi

# Install Oh My Zsh (non-interactively, without changing the default shell)
install_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Oh My Zsh is already installed at $HOME/.oh-my-zsh"
        return 0
    fi

    log_info "Installing Oh My Zsh..."
    if ! command_exists curl && ! command_exists wget; then
        log_error "curl or wget is required to install Oh My Zsh"
        return 1
    fi

    # RUNZSH=no skips launching zsh after install; CHSH=no skips changing the default shell
    if command_exists curl; then
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        RUNZSH=no CHSH=no sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_error "Oh My Zsh installation failed"
        return 1
    fi
    log_success "Oh My Zsh installed successfully."
}

# Install Powerlevel10k theme into the Oh My Zsh custom themes directory
install_powerlevel10k() {
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

    if [[ -d "$p10k_dir" ]]; then
        log_info "Powerlevel10k is already installed at $p10k_dir"
        return 0
    fi

    log_info "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir" || {
        log_error "Failed to clone Powerlevel10k repository"
        return 1
    }
    log_success "Powerlevel10k installed successfully."
}

# Install Oh My Zsh community plugins
install_plugins() {
    local plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    mkdir -p "$plugins_dir"

    # zsh-autosuggestions: fish-like suggestions from history
    if [[ ! -d "$plugins_dir/zsh-autosuggestions" ]]; then
        log_info "Installing zsh-autosuggestions..."
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
            "$plugins_dir/zsh-autosuggestions" || log_warning "Failed to install zsh-autosuggestions"
    else
        log_info "zsh-autosuggestions already installed"
    fi

    # zsh-syntax-highlighting: fish-like real-time syntax highlighting
    if [[ ! -d "$plugins_dir/zsh-syntax-highlighting" ]]; then
        log_info "Installing zsh-syntax-highlighting..."
        git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
            "$plugins_dir/zsh-syntax-highlighting" || log_warning "Failed to install zsh-syntax-highlighting"
    else
        log_info "zsh-syntax-highlighting already installed"
    fi

    # zsh-completions: additional completion definitions
    if [[ ! -d "$plugins_dir/zsh-completions" ]]; then
        log_info "Installing zsh-completions..."
        git clone --depth=1 https://github.com/zsh-users/zsh-completions \
            "$plugins_dir/zsh-completions" || log_warning "Failed to install zsh-completions"
    else
        log_info "zsh-completions already installed"
    fi
}

# Deploy shell configuration files from the config directory
configure_shell() {
    # Back up an existing .zshrc that was not created by us
    if [[ -f "$HOME/.zshrc" ]] && ! grep -q "# Bioinformatics CLI Environment" "$HOME/.zshrc" 2>/dev/null; then
        log_info "Backing up existing .zshrc to $HOME/.zshrc.pre-bioinf"
        cp "$HOME/.zshrc" "$HOME/.zshrc.pre-bioinf"
    fi

    # Install our zshrc
    if [[ -f "$CONFIG_DIR/zshrc" ]]; then
        log_info "Installing zshrc configuration..."
        cp "$CONFIG_DIR/zshrc" "$HOME/.zshrc"
        log_success "Installed ~/.zshrc"
    else
        log_warning "zshrc template not found at $CONFIG_DIR/zshrc — skipping"
    fi

    # Install Powerlevel10k configuration
    if [[ -f "$CONFIG_DIR/p10k.zsh" ]]; then
        log_info "Installing Powerlevel10k configuration..."
        cp "$CONFIG_DIR/p10k.zsh" "$HOME/.p10k.zsh"
        log_success "Installed ~/.p10k.zsh"
    else
        log_warning "p10k.zsh template not found at $CONFIG_DIR/p10k.zsh — skipping"
    fi

    # Install nano configuration if present
    if [[ -f "$CONFIG_DIR/nanorc" ]]; then
        log_info "Installing nano configuration..."
        cp "$CONFIG_DIR/nanorc" "$HOME/.nanorc"
        log_success "Installed ~/.nanorc"
    fi

    # Install tmux configuration if present
    if [[ -f "$CONFIG_DIR/tmux.conf" ]]; then
        log_info "Installing tmux configuration..."
        cp "$CONFIG_DIR/tmux.conf" "$HOME/.tmux.conf"
        log_success "Installed ~/.tmux.conf"
    fi
}

# Main entry point
main() {
    log_info "🐚 Setting up Oh My Zsh and Powerlevel10k..."

    install_oh_my_zsh
    install_powerlevel10k
    install_plugins
    configure_shell

    log_success "Oh My Zsh setup complete!"
    if [[ "$NONINTERACTIVE" == "false" ]]; then
        log_info "Please restart your terminal or run: source ~/.zshrc"
    fi
}

main