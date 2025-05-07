#!/usr/bin/env bash
# Micromamba setup and bioinformatics environment management script
set -euo pipefail

# Configuration and defaults
MICROMAMBA_ROOT="${HOME}/micromamba"
BIN_DIR="${HOME}/.local/bin"
CONFIG_FILE="${2:-}"
SHELL_NAME="$(basename "${SHELL}")"
ENV_NAME=""

# Logging function for consistent messaging
log_info() { echo "[INFO] $1"; }
log_error() { echo "[ERROR] $1" >&2; exit 1; }

# Ensure required directories are created
mkdir -p "${BIN_DIR}"

# Install Micromamba only if it isn't already available
install_micromamba() {
    if ! command -v micromamba &>/dev/null; then
        log_info "Installing Micromamba..."
        bash <(curl -fsSL https://micro.mamba.pm/install.sh) || log_error "Micromamba installation failed."
    else
        log_info "Micromamba is already installed."
    fi
}

# Initialize shell integration
initialize_shell() {
    log_info "Initializing Micromamba for shell (${SHELL_NAME})..."
    "${MICROMAMBA_ROOT}/bin/micromamba" shell init -s "${SHELL_NAME}" -r "${MICROMAMBA_ROOT}"
    log_info "Micromamba shell initialization complete. Please restart your shell."
}

# Configure Micromamba channels
configure_micromamba() {
    log_info "Configuring Micromamba..."
    "${MICROMAMBA_ROOT}/bin/micromamba" config append channels conda-forge
    "${MICROMAMBA_ROOT}/bin/micromamba" config set channel_priority strict
}

# Extract environment name from the provided configuration file reliably
parse_env_name() {
    ENV_NAME=$(grep -E '^name:' "${CONFIG_FILE}" | head -1 | awk '{print $2}' | tr -d '[:space:]')
    [[ -z "${ENV_NAME}" ]] && log_error "Environment name not found in ${CONFIG_FILE}"
}

# Create or update Micromamba environment from a provided YAML configuration
create_or_update_env() {
    [[ -f "${CONFIG_FILE}" ]] || log_error "Environment configuration file '${CONFIG_FILE}' not found."
    parse_env_name

    if "${MICROMAMBA_ROOT}/bin/micromamba" env list | grep -q "${ENV_NAME}"; then
        log_info "Updating existing environment '${ENV_NAME}'..."
        "${MICROMAMBA_ROOT}/bin/micromamba" update -y -f "${CONFIG_FILE}"
    else
        log_info "Creating new environment '${ENV_NAME}'..."
        "${MICROMAMBA_ROOT}/bin/micromamba" create -y -f "${CONFIG_FILE}"
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