#!/usr/bin/env bash
# Interactive installer for bioinf-cli-env
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/utils/common.sh"

# Default paths and configuration
CONFIG_INI="$SCRIPT_DIR/config.ini"
CONFIG_DIR="$SCRIPT_DIR/config"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
BIN_DIR="${HOME}/.local/bin"
BACKUP_DIR="${HOME}/.config/bioinf-cli-env.bak.$(date +%Y%m%d%H%M%S)"

# Parse command line arguments
INTERACTIVE=true
CONFIG_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --non-interactive)
            INTERACTIVE=false
            shift
            ;;
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Usage: $0 [--non-interactive] [--config config.ini]"
            exit 1
            ;;
    esac
done

# Create required directories
mkdir -p "$BIN_DIR" "$BACKUP_DIR"

# Process configuration
if [[ -n "$CONFIG_FILE" ]]; then
    if [[ ! -f "$CONFIG_FILE" ]]; then
        die "Configuration file not found: $CONFIG_FILE"
    fi
    cp "$CONFIG_FILE" "$CONFIG_INI"
elif [[ ! -f "$CONFIG_INI" && "$INTERACTIVE" == "false" ]]; then
    die "Non-interactive mode requires a config file. Copy config.ini.template to config.ini and customize it."
fi

# Helper to ask yes/no questions or use config value
ask() {
    local prompt="$1"
    local config_key="$2"
    
    if [[ "$INTERACTIVE" == "true" ]]; then
        read -p "$prompt [Y/n] " yn
        [[ "$yn" != [Nn]* ]]
    else
        # Get value from config.ini
        local value
        value=$(grep "^$config_key=" "$CONFIG_INI" | cut -d'=' -f2)
        [[ "${value,,}" == "true" ]]
    fi
}

# Detect OS and installer
INSTALLER="$(get_package_manager)"
log_info "Using package manager: $INSTALLER"

# Ensure ~/.local/bin is in PATH
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
    add_to_path "$BIN_DIR" "zsh"
fi

# Backup existing configs
log_info "Backing up existing configurations to $BACKUP_DIR"
for file in .zshrc .p10k.zsh .nanorc .tmux.conf; do
    backup_config "$HOME/$file" "$BACKUP_DIR"
done

# Install components based on configuration/user choices
if ask "Install Oh My Zsh and Powerlevel10k?" "INSTALL_OH_MY_ZSH"; then
    bash "$SCRIPTS_DIR/setup_omz.sh" "$CONFIG_DIR"
fi

if ask "Install modern CLI tools (eza, bat, ripgrep, etc)?" "INSTALL_MODERN_TOOLS"; then
    bash "$SCRIPTS_DIR/setup_tools.sh" "$INSTALLER"
fi

if ask "Install micromamba and bioinformatics environment?" "INSTALL_MICROMAMBA"; then
    bash "$SCRIPTS_DIR/setup_micromamba.sh" "$INSTALLER"
    bash "$SCRIPTS_DIR/setup_micromamba.sh" env-create "$CONFIG_DIR/micromamba-config.yaml"
fi

## %%TODO%% fix not currently working in docker
# if ask "Install Azure OpenAI CLI integration?"; then
#  bash "$SCRIPTS_DIR/setup_llm.sh"
# fi

if ask "Install job monitoring tools?" "INSTALL_JOB_MONITORING"; then
    bash "$SCRIPTS_DIR/setup_monitoring.sh"
fi

if ask "Install color palette selector?" "INSTALL_PALETTE_SELECTOR"; then
    install -m0755 "$SCRIPTS_DIR/select_palette.sh" "$BIN_DIR/"
fi

log_success "Installation complete! Please restart your terminal."
if [[ "$SHELL" != *"zsh"* ]]; then
    log_warning "Your current shell is not zsh. Run 'chsh -s $(which zsh)' to change it."
fi
