#!/usr/bin/env bash
# Interactive installer for bioinf-cli-env
set -euo pipefail
IFS=$'\n\t'

# Initialize global variables
INTERACTIVE=true
CONFIG_FILE=""
# SCRIPT_DIR=""
# CONFIG_INI=""
# CONFIG_DIR=""
# SCRIPTS_DIR=""
BIN_DIR="${HOME}/.local/bin"
BACKUP_DIR="${HOME}/.config/bioinf-cli-env.bak.$(date +%Y%m%d%H%M%S)"

# Function: Initialize paths and environment
initialize() {
if [ -n "${ZSH_VERSION:-}" ]; then
        SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    else
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    fi

    CONFIG_INI="$SCRIPT_DIR/config.ini"
    CONFIG_DIR="$SCRIPT_DIR/config"
    SCRIPTS_DIR="$SCRIPT_DIR/scripts"
    mkdir -p "$BIN_DIR" "$BACKUP_DIR"
    source "$SCRIPT_DIR/scripts/utils/common.sh"
}

# Function: Parse command-line arguments
parse_arguments() {
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
}

# Function: Validate prerequisites
validate_prerequisites() {
    if ! command -v zsh &> /dev/null; then
        log_error "zsh is not installed. Please install zsh first."
        echo "On Ubuntu/Debian: sudo apt-get install -y zsh"
        echo "On macOS: brew install zsh"
        echo "On CentOS/RHEL: sudo yum install -y zsh"
        exit 1
    fi

    if [[ "$SHELL" != *"zsh"* ]]; then
        log_warning "zsh is not your default shell."
        if [[ "$INTERACTIVE" != "false" ]]; then
            read -r -p "Would you like to set zsh as your default shell? [Y/n] " yn
            if [[ "$yn" != [Nn]* ]]; then
                chsh -s "$(command -v zsh)" || {
                    log_error "Failed to set zsh as default shell. Please run: chsh -s $(command -v zsh)"
                    echo "Continue installation? [Y/n] "
                    read -r yn
                    [[ "$yn" == [Nn]* ]] && exit 1
                }
            else
                log_warning "Continuing with current shell. Some features may not work correctly."
                echo "Continue installation? [Y/n] "
                read -r yn
                [[ "$yn" == [Nn]* ]] && exit 1
            fi
        else
            log_warning "Non-interactive mode: zsh is not the default shell. Some features may not work correctly."
        fi
    fi
}

# Function: Process configuration
process_configuration() {
    if [[ -n "$CONFIG_FILE" ]]; then
        if [[ ! -f "$CONFIG_FILE" ]]; then
            die "Configuration file not found: $CONFIG_FILE"
        fi
        CONFIG_INI="$CONFIG_FILE"
    elif [[ ! -f "$CONFIG_INI" && "$INTERACTIVE" == "false" ]]; then
        die "Non-interactive mode requires a config file. Copy config.ini.template to config.ini and customize it."
    fi
}

# Function: Backup existing configurations
backup_configs() {
    log_info "Backing up existing configurations to $BACKUP_DIR"
    for file in .zshrc .p10k.zsh .nanorc .tmux.conf; do
        if [[ -f "$HOME/$file" ]]; then
            backup_config "$HOME/$file" "$BACKUP_DIR"
        else
            log_warning "File not found for backup: $HOME/$file"
        fi
    done
}

# Function: Ensure required paths are in PATH
ensure_paths() {
    if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
        add_to_path "$BIN_DIR" "zsh"
    fi
}

# Function: Ask user for input or read from config
ask() {
    local prompt="$1"
    local config_key="$2"

    if [[ "$INTERACTIVE" == "true" ]]; then
        echo -n "$prompt [Y/n] "
        read -r yn
        [[ "$yn" != [Nn]* ]]
    else
        local value
        value=$(grep "^$config_key=" "$CONFIG_INI" | cut -d'=' -f2)
        [[ "${value,,}" == "true" ]]
    fi
}

# Function: Install components
install_components() {
    if ask "Install modern CLI tools (eza, bat, ripgrep, etc)?" "INSTALL_MODERN_TOOLS"; then
        bash "$SCRIPTS_DIR/setup_tools.sh" "$(get_package_manager)"
    fi

    if ask "Install Oh My Zsh and Powerlevel10k?" "INSTALL_OH_MY_ZSH"; then
        bash "$SCRIPTS_DIR/setup_omz.sh" "$CONFIG_DIR"
    fi

    if ask "Install job monitoring tools?" "INSTALL_JOB_MONITORING"; then
        bash "$SCRIPTS_DIR/setup_monitoring.sh"
    fi

    if ask "Install color palette selector?" "INSTALL_PALETTE_SELECTOR"; then
        install -m0755 "$SCRIPTS_DIR/select_palette.sh" "$BIN_DIR/"
    fi

    if ask "Install micromamba and bioinformatics environment?" "INSTALL_MICROMAMBA"; then
        bash "$SCRIPTS_DIR/setup_micromamba.sh"
        bash "$SCRIPTS_DIR/setup_micromamba.sh" env-create "$CONFIG_DIR/micromamba-config.yaml"
    fi

    if ask "Install Azure OpenAI CLI integration?" "INSTALL_AZURE_LLM"; then
        bash "$SCRIPTS_DIR/setup_llm.sh"
    fi

}

# Main script execution
initialize
parse_arguments "$@"
validate_prerequisites
process_configuration
backup_configs
ensure_paths
install_components

log_success "Installation complete! Please restart your terminal."
if [[ "$SHELL" != *"zsh"* ]]; then
    log_warning "Your current shell is not zsh. Run 'chsh -s $(command -v zsh)' to change it."
fi
