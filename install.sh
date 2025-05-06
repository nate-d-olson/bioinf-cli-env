#!/usr/bin/env bash
# Bioinformatics CLI Environment Installer
# This script installs a comprehensive CLI environment for bioinformaticians

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Define colors for prettier output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Determine script directory in a shell-agnostic way
if [ -n "${ZSH_VERSION:-}" ]; then
    # zsh
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
else
    # bash
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
fi

# Constants
CONFIG_DIR="$SCRIPT_DIR/config"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
BIN_DIR="${HOME}/.local/bin"
BACKUP_DIR="${HOME}/.config/bioinf-cli-env.bak.$(date +%Y%m%d%H%M%S)"

# Default configuration options
INTERACTIVE_MODE=true
CONFIG_FILE=""
INSTALL_OH_MY_ZSH=true
INSTALL_MODERN_TOOLS=true
INSTALL_MICROMAMBA=true
INSTALL_AZURE_LLM=false
INSTALL_JOB_MONITORING=true
INSTALL_PALETTE_SELECTOR=true

# Create necessary directories
mkdir -p "$BIN_DIR" "$BACKUP_DIR"

# Add BIN_DIR to PATH if not already there
[[ ":$PATH:" != *":$BIN_DIR:"* ]] && export PATH="$BIN_DIR:$PATH"

####################
# Helper Functions #
####################

log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }

die() {
    log_error "$1"
    exit "${2:-1}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to backup file
backup_file() {
    local file="$1"
    if [[ -f "$HOME/$file" ]]; then
        log_info "Backing up $file"
        cp -p "$HOME/$file" "$BACKUP_DIR/" || log_warning "Failed to backup $file"
    fi
}

# Parse command-line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --non-interactive)
                INTERACTIVE_MODE=false
                # Set environment variable for component scripts
                export BIOINF_NON_INTERACTIVE=true
                shift
                ;;
            --config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --help)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --non-interactive     Run in non-interactive mode"
                echo "  --config FILE         Use specified config file"
                echo "  --help                Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    # Validate config file if specified
    if [[ -n "$CONFIG_FILE" ]]; then
        if [[ ! -f "$CONFIG_FILE" ]]; then
            die "Config file not found: $CONFIG_FILE" 1
        fi
    fi
}

# Load configuration from file
load_config() {
    if [[ -n "$CONFIG_FILE" ]]; then
        log_info "Loading configuration from $CONFIG_FILE"
        # Source the config file to get variables
        source "$CONFIG_FILE"
    fi
}

# Function to prompt user - shell-agnostic implementation
prompt() {
    local question="$1"
    local default="${2:-Y}"
    local response=""
    
    # Skip prompting in non-interactive mode
    if [[ "$INTERACTIVE_MODE" == "false" ]]; then
        # Default to true for components that default to Y
        if [[ "$default" == "Y" ]]; then
            return 0
        else
            return 1
        fi
    fi
    
    if [[ "$default" == "Y" ]]; then
        if [ -n "${ZSH_VERSION:-}" ]; then
            # zsh doesn't support -p flag for read
            echo -n "$question [Y/n]: "
            read response
        else
            # bash supports -p flag
            read -r -p "$question [Y/n]: " response
        fi
        [[ -z "$response" || "$response" =~ ^[Yy] ]]
    else
        if [ -n "${ZSH_VERSION:-}" ]; then
            echo -n "$question [y/N]: "
            read response
        else
            read -r -p "$question [y/N]: " response
        fi
        [[ "$response" =~ ^[Yy] ]]
    fi
}

########################
# Check Prerequisites  #
########################

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check for zsh
    if ! command_exists zsh; then
        log_error "zsh is required but not installed."
        echo "  - On macOS: Install with 'brew install zsh'"
        echo "  - On Ubuntu/Debian: Install with 'sudo apt install -y zsh'"
        echo "  - On CentOS/RHEL: Install with 'sudo yum install -y zsh'"
        die "Please install zsh and try again."
    fi
    
    # Check for package managers
    if command_exists brew; then
        PACKAGE_MANAGER="brew"
    elif command_exists apt-get; then
        PACKAGE_MANAGER="apt"
        
        # Check if apt-get can be executed with sudo
        if ! sudo -n true 2>/dev/null; then
            log_warning "Some package installations may require sudo privileges."
            if ! prompt "Continue without guaranteed sudo access?"; then
                die "Installation aborted. Please run again with sudo access."
            fi
        fi
    else
        if prompt "No supported package manager found. Continue anyway?" "N"; then
            PACKAGE_MANAGER="unknown"
        else
            die "Installation requires Homebrew (macOS) or apt (Ubuntu/Debian)."
        fi
    fi
    
    log_success "Prerequisites check passed!"
}

########################
# Component Installers #
########################

install_cli_tools() {
    log_info "Installing modern CLI tools..."
    bash "$SCRIPTS_DIR/setup_tools.sh" "$PACKAGE_MANAGER"
    
    # Check if installation succeeded
    if [[ $? -ne 0 ]]; then
        log_warning "Some CLI tools may not have been installed correctly."
    else
        log_success "CLI tools installed successfully!"
    fi
}

install_omz() {
    log_info "Installing Oh-My-Zsh and Powerlevel10k..."
    bash "$SCRIPTS_DIR/setup_omz.sh" "$CONFIG_DIR"
    
    # Check if installation succeeded
    if [[ $? -ne 0 ]]; then
        log_warning "Oh-My-Zsh installation may have encountered issues."
    else
        log_success "Oh-My-Zsh installed successfully!"
    fi
}

install_job_monitoring() {
    log_info "Installing job monitoring tools..."
    bash "$SCRIPTS_DIR/setup_monitoring.sh"
    
    # Check if installation succeeded
    if [[ $? -ne 0 ]]; then
        log_warning "Job monitoring tools installation encountered issues."
    else
        log_success "Job monitoring tools installed successfully!"
    fi
}

install_palette_selector() {
    log_info "Installing color palette selector..."
    install -m0755 "$SCRIPTS_DIR/select_palette.sh" "$BIN_DIR/"
    
    if [[ -x "$BIN_DIR/select_palette.sh" ]]; then
        log_success "Color palette selector installed successfully!"
    else
        log_warning "Failed to install color palette selector."
    fi
}

install_micromamba() {
    log_info "Installing micromamba..."
    bash "$SCRIPTS_DIR/setup_micromamba.sh"
    
    if [[ $? -eq 0 ]]; then
        log_info "Setting up bioinformatics environment with micromamba..."
        bash "$SCRIPTS_DIR/setup_micromamba.sh" env-create "$CONFIG_DIR/micromamba-config.yaml"
        
        if [[ $? -eq 0 ]]; then
            log_success "Micromamba and bioinformatics environment installed successfully!"
        else
            log_warning "Bioinformatics environment creation encountered issues."
        fi
    else
        log_warning "Micromamba installation encountered issues."
    fi
}

install_azure_llm() {
    log_info "Installing Azure OpenAI CLI integration..."
    bash "$SCRIPTS_DIR/setup_llm.sh"
    
    if [[ $? -eq 0 ]]; then
        log_success "Azure OpenAI CLI integration installed successfully!"
    else
        log_warning "Azure OpenAI CLI integration installation encountered issues."
    fi
}

backup_configurations() {
    log_info "Backing up existing configurations..."
    backup_file ".zshrc"
    backup_file ".p10k.zsh"
    backup_file ".nanorc"
    backup_file ".tmux.conf"
    log_success "Backups created in $BACKUP_DIR"
}

########################
# Main Installation    #
########################

main() {
    # Parse command-line arguments
    parse_args "$@"
    
    # Load configuration if specified
    load_config

    # Print welcome banner
    echo -e "\n${GREEN}┌────────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│ Bioinformatics CLI Environment Installer    │${NC}"
    echo -e "${GREEN}└────────────────────────────────────────────┘${NC}\n"
    
    # Check prerequisites first
    check_prerequisites
    
    # Backup existing configurations
    backup_configurations
    
    # Install components based on user selection or configuration
    if [[ "$INSTALL_MODERN_TOOLS" == "true" ]] || prompt "Install modern CLI tools (eza, bat, ripgrep, etc)?"; then
        install_cli_tools
    fi
    
    if [[ "$INSTALL_OH_MY_ZSH" == "true" ]] || prompt "Install Oh My Zsh and Powerlevel10k?"; then
        install_omz
    fi
    
    if [[ "$INSTALL_JOB_MONITORING" == "true" ]] || prompt "Install job monitoring tools?"; then
        install_job_monitoring
    fi
    
    if [[ "$INSTALL_PALETTE_SELECTOR" == "true" ]] || prompt "Install color palette selector?"; then
        install_palette_selector
    fi
    
    if [[ "$INSTALL_MICROMAMBA" == "true" ]] || prompt "Install micromamba and bioinformatics environment?"; then
        install_micromamba
    fi
    
    # Temporarily disabled Azure OpenAI CLI setup to avoid CI errors
# if [[ "$INSTALL_AZURE_LLM" == "true" ]] || prompt "Install Azure OpenAI CLI integration?"; then
#     install_azure_llm
# fi
    
    # Final message
    echo -e "\n${GREEN}┌────────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│ Installation Complete!                      │${NC}"
    echo -e "${GREEN}└────────────────────────────────────────────┘${NC}\n"
    
    if [[ "$SHELL" != *"zsh"* ]]; then
        log_warning "Your current shell is not zsh."
        echo "Run the following command to change your default shell:"
        echo "  chsh -s $(command -v zsh)"
        echo "Then restart your terminal."
    else
        log_info "Please restart your terminal to apply all changes."
    fi
}

# Run the main function
main "$@"
