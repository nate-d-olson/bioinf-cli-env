#!/usr/bin/env bash
# Micromamba and bioinformatics environment setup
set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/common.sh"

ACTION="${1:-install}"
CONFIG_FILE="${2:-}"
MICROMAMBA_ROOT="$HOME/micromamba"
BIN_DIR="${HOME}/.local/bin"

mkdir -p "$BIN_DIR"

# Install micromamba if not already installed
install_micromamba() {
    if cmd_exists micromamba; then
        log_success "Micromamba is already installed."
        return 0
    fi

    log_info "Installing micromamba..."

    # Get platform information
    local platform=$(detect_platform)
    local os=$(get_os "$platform")
    local arch=$(get_arch "$platform")

    log_info "Detected platform: $platform (OS: $os, Arch: $arch)"

    # Platform-specific download URLs
    if [[ "$os" == "darwin" ]]; then
        if [[ "$arch" == "arm64" ]]; then
            # Apple Silicon (M1/M2)
            log_info "Installing micromamba for macOS ARM64 (Apple Silicon)..."
            curl -Ls https://micro.mamba.pm/api/micromamba/osx-arm64/latest | tar -xvj bin/micromamba
        else
            # Intel Mac
            log_info "Installing micromamba for macOS x86_64 (Intel)..."
            curl -Ls https://micro.mamba.pm/api/micromamba/osx-64/latest | tar -xvj bin/micromamba
        fi
    elif [[ "$os" == "linux" || "$os" == "ubuntu" || "$os" == "debian" || "$os" == "redhat" ]]; then
        if [[ "$arch" == "arm64" ]]; then
            # ARM Linux
            log_info "Installing micromamba for Linux ARM64..."
            curl -Ls https://micro.mamba.pm/api/micromamba/linux-aarch64/latest | tar -xvj bin/micromamba
        else
            # x86_64 Linux
            log_info "Installing micromamba for Linux x86_64..."
            curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba
        fi
    else
        die "Unsupported platform: $platform (OS: $os, Arch: $arch)"
    fi

    # Move to the bin directory
    if [[ -f bin/micromamba ]]; then
        mv bin/micromamba "$BIN_DIR/"
        rm -rf bin
    else
        die "Failed to download micromamba"
    fi
}

# Create a bioinformatics environment from config file
create_environment() {
    if [[ -z "$CONFIG_FILE" ]]; then
        log_error "No environment config file provided."
        return 1
    fi

    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Config file not found: $CONFIG_FILE"
        return 1
    fi

    log_info "Creating bioinformatics environment from $CONFIG_FILE..."

    # Ensure micromamba is in PATH
    if ! cmd_exists micromamba; then
        if [[ -f "$BIN_DIR/micromamba" ]]; then
            export PATH="$BIN_DIR:$PATH"
        else
            log_error "Micromamba not found. Please install it first."
            return 1
        fi
    fi

    # Extract environment name from yaml with better parsing
    ## %%TODO%% fix yq query statement
    #  if cmd_exists yq; then
    #   ENV_NAME=$(yq eval 'name' "$CONFIG_FILE")
    #else
    # ENV_NAME=$(grep -m 1 "^name:" "$CONFIG_FILE" | cut -d ':' -f 2 | tr -d ' ')
    # fi

    ENV_NAME=$(grep -m 1 "^name:" "$CONFIG_FILE" | cut -d ':' -f 2 | tr -d ' ')

    if [[ -z "$ENV_NAME" ]]; then
        log_error "Could not determine environment name from $CONFIG_FILE"
        return 1
    fi

    # Check if environment already exists
    if micromamba env list | grep -q "$ENV_NAME"; then
        log_warning "Environment $ENV_NAME already exists."
        if [[ "$ACTION" == "env-create" ]]; then
            log_info "Updating environment..."
            micromamba update -y -f "$CONFIG_FILE"
        fi
    else
        log_info "Creating new environment..."
        micromamba create -y -f "$CONFIG_FILE"
    fi

    # Install platform-specific packages
    install_platform_specific_packages "$ENV_NAME"

    # Add activation snippet to .zshrc if not already present
    if ! grep -q "# >>> micromamba initialize >>>" "$HOME/.zshrc"; then
        log_info "Adding micromamba activation to .zshrc..."
        cat >>"$HOME/.zshrc" <<EOF

# >>> micromamba initialize >>>
# !! Contents within this block are managed by micromamba !!
export MAMBA_EXE="$BIN_DIR/micromamba";
export MAMBA_ROOT_PREFIX="$MICROMAMBA_ROOT";
__mamba_setup="\$(\$MAMBA_EXE shell hook --shell zsh --prefix \$MAMBA_ROOT_PREFIX 2> /dev/null)"
if [ \$? -eq 0 ]; then
    eval "\$__mamba_setup"
else
    if [ -f "\$MAMBA_ROOT_PREFIX/etc/profile.d/micromamba.sh" ]; then
        . "\$MAMBA_ROOT_PREFIX/etc/profile.d/micromamba.sh"
    fi
fi
unset __mamba_setup
# <<< micromamba initialize <<<

# Add micromamba environment activation alias
alias bioinf="micromamba activate $ENV_NAME"
EOF
    fi

    log_success "Bioinformatics environment setup complete!"
    log_info "To activate your environment, restart your shell and run: bioinf"

    # Initialize micromamba
    "$BIN_DIR/micromamba" shell init -s bash "$MICROMAMBA_ROOT"
    "$BIN_DIR/micromamba" shell init -s zsh "$MICROMAMBA_ROOT"

    # Add micromamba to the current PATH if not already there
    if ! echo "$PATH" | tr ':' '\n' | grep -q "$BIN_DIR"; then
        export PATH="$BIN_DIR:$PATH"
    fi

    log_success "Micromamba installed to $BIN_DIR/micromamba"
}

# Install platform-specific packages
install_platform_specific_packages() {
    local env_name="$1"
    local platform=$(detect_platform)
    local os=$(get_os "$platform")
    local arch=$(get_arch "$platform")

    log_info "Installing platform-specific packages for $os-$arch..."

    # Skip problematic packages on macOS
    if [[ "$os" == "darwin" ]]; then
        log_info "Skipping platform-incompatible packages on macOS"
    else
        # Install Linux-specific packages
        log_info "Installing additional bioinformatics tools for Linux..."
        if micromamba list -n "$env_name" | grep -q "dipcall"; then
            log_info "dipcall already installed"
        else
            micromamba install -n "$env_name" -c bioconda -c conda-forge -y dipcall || log_warning "Failed to install dipcall, continuing anyway"
        fi
        
        if micromamba list -n "$env_name" | grep -q "truvari"; then
            log_info "truvari already installed"
        else
            micromamba install -n "$env_name" -c bioconda -c conda-forge -y truvari || log_warning "Failed to install truvari, continuing anyway"
        fi
    fi

    if [[ "$os" == "darwin" && "$arch" == "arm64" ]]; then
        log_info "Detected Apple Silicon, applying specific configurations..."
    fi
}



# Main execution
case "$ACTION" in
"install")
    install_micromamba
    save_state "micromamba" "installed"
    ;;
"env-create")
    create_environment
    save_state "bioinf_env" "created"
    ;;
"cleanup")
    cleanup_micromamba
    save_state "micromamba" "removed"
    ;;
*)
    log_error "Unknown action: $ACTION"
    echo "Valid actions: install, env-create, cleanup"
    exit 1
    ;;
esac
