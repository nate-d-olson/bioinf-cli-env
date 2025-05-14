#!/usr/bin/env bash
# Micromamba setup and bioinformatics environment management script
set -euo pipefail

# Configuration and defaults
MICROMAMBA_ROOT="${HOME}/micromamba"
BIN_DIR="${HOME}/.local/bin"
CONFIG_FILE="${2:-}"
SHELL_NAME="$(basename "${SHELL}")"
ENV_NAME=""
TIMEOUT=300  # 5 minutes timeout for operations that might lock

# Logging function for consistent messaging
log_info() { echo "[INFO] $1"; }
log_error() { echo "[ERROR] $1" >&2; exit 1; }
log_debug() { echo "[DEBUG] $1" >&2; }
log_warning() { echo "[WARNING] $1" >&2; }

# Ensure required directories are created
mkdir -p "${BIN_DIR}"
mkdir -p "${MICROMAMBA_ROOT}/bin"

# Get the micromamba binary path whether it's in the standard location or somewhere else in PATH
get_micromamba_bin() {
    # Try the default location first
    if [[ -x "${MICROMAMBA_ROOT}/bin/micromamba" ]]; then
        echo "${MICROMAMBA_ROOT}/bin/micromamba"
        return 0
    fi
    
    # Check if it's somewhere in PATH
    local MAMBA_PATH=$(command -v micromamba 2>/dev/null || true)
    if [[ -n "${MAMBA_PATH}" ]]; then
        echo "${MAMBA_PATH}"
        return 0
    fi
    
    # Check common Homebrew locations
    if [[ -x "/opt/homebrew/bin/micromamba" ]]; then
        echo "/opt/homebrew/bin/micromamba"
        return 0
    elif [[ -x "/usr/local/bin/micromamba" ]]; then
        echo "/usr/local/bin/micromamba"
        return 0
    fi
    
    # Not found
    return 1
}

# Check if micromamba is already running
check_micromamba_locks() {
    log_debug "Checking for micromamba locks..."
    
    if [[ -f "${MICROMAMBA_ROOT}/pkgs/locks/package-env.lock" ]]; then
        log_warning "Micromamba lock detected. Another micromamba process might be running."
        log_warning "If no other micromamba process is running, you may need to remove the lock file:"
        log_warning "rm ${MICROMAMBA_ROOT}/pkgs/locks/package-env.lock"
        return 1
    fi
    
    return 0
}

# Install Micromamba only if it isn't already available
install_micromamba() {
    if ! get_micromamba_bin &>/dev/null; then
        log_info "Installing Micromamba (debug mode)..."
        TMP_SCRIPT=$(mktemp)

        log_info "Downloading Micromamba install script..."
        curl -fsSL https://micro.mamba.pm/install.sh -o "${TMP_SCRIPT}" || log_error "Failed to download Micromamba script"

        log_info "Download complete. Script location: ${TMP_SCRIPT}"
        chmod +x "${TMP_SCRIPT}" || log_error "Failed to set script executable permissions"

        log_info "Executing the installation script now..."
        bash "${TMP_SCRIPT}" || log_error "Micromamba installation script execution failed"

        log_info "Cleaning up installation script."
        rm -f "${TMP_SCRIPT}"
        
        # Verify installation
        if ! get_micromamba_bin &>/dev/null; then
            log_error "Micromamba installation failed. Binary not found."
        fi
    else
        MAMBA_BIN=$(get_micromamba_bin)
        log_info "Micromamba is already installed at ${MAMBA_BIN}"
    fi
}

# Initialize shell integration
initialize_shell() {
    MAMBA_BIN=$(get_micromamba_bin) || log_error "Micromamba binary not found"
    
    log_info "Initializing Micromamba for shell (${SHELL_NAME})..."
    "${MAMBA_BIN}" shell init -s "${SHELL_NAME}" -r "${MICROMAMBA_ROOT}"
    log_info "Micromamba shell initialization complete. Please restart your shell."
}

# Configure Micromamba channels
configure_micromamba() {
    MAMBA_BIN=$(get_micromamba_bin) || log_error "Micromamba binary not found"
    
    log_info "Configuring Micromamba..."
    "${MAMBA_BIN}" config append channels conda-forge
    "${MAMBA_BIN}" config set channel_priority strict
}

# Extract environment name from the provided configuration file reliably
parse_env_name() {
    # Check if the file exists 
    [[ -f "${CONFIG_FILE}" ]] || log_error "Environment configuration file '${CONFIG_FILE}' not found."
    
    # Try different parsing methods to be more robust
    if grep -q "^name:" "${CONFIG_FILE}"; then
        ENV_NAME=$(grep -E '^name:' "${CONFIG_FILE}" | head -1 | awk '{print $2}' | tr -d '[:space:]')
    else
        log_error "Could not find 'name:' field in ${CONFIG_FILE}"
    fi
    
    [[ -z "${ENV_NAME}" ]] && log_error "Environment name not found in ${CONFIG_FILE}"
    log_info "Found environment name: ${ENV_NAME}"
}

# Create or update Micromamba environment from a provided YAML configuration
create_or_update_env() {
    parse_env_name
    
    MAMBA_BIN=$(get_micromamba_bin) || log_error "Micromamba binary not found"
    
    # Check for locks before proceeding
    check_micromamba_locks
    
    if "${MAMBA_BIN}" env list | grep -q "${ENV_NAME}"; then
        log_info "Updating existing environment '${ENV_NAME}'..."
        time "${MAMBA_BIN}" update -y -f "${CONFIG_FILE}" || log_error "Failed to update environment ${ENV_NAME}"
    else
        log_info "Creating new environment '${ENV_NAME}'..."
        time "${MAMBA_BIN}" create -y -f "${CONFIG_FILE}" || log_error "Failed to create environment ${ENV_NAME}"
    fi

    log_info "Environment '${ENV_NAME}' setup complete."
}

# Handle command-line arguments
main() {
    local ACTION="${1:-}"

    case "${ACTION}" in
        install)
            install_micromamba
            initialize_shell
            configure_micromamba
            ;;
        env-create)
            install_micromamba
            create_or_update_env
            ;;
        *)
            log_error "Invalid or missing action.\nUsage: $0 {install | env-create <config-file>}"
            ;;
    esac
}

main "$@"