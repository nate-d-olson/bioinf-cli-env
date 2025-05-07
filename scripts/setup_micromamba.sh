#!/bin/bash
# Micromamba and bioinformatics environment setup
set -euo pipefail

# Define locations dynamically
MICROMAMBA_BIN="$(command -v micromamba || true)"
MICROMAMBA_ROOT="$HOME/micromamba"
BIN_DIR="${HOME}/.local/bin"
CONFIG_FILE="${2:-}"

mkdir -p "$BIN_DIR"

# Function to ensure micromamba is available
verify_micromamba() {
    if [[ -z "$MICROMAMBA_BIN" ]]; then
        echo "[ERROR] Micromamba executable not found. Ensure micromamba is installed first."
        exit 1
    else
        echo "[INFO] Micromamba found at $MICROMAMBA_BIN"
    fi
}

# Function to create bioinformatics environment
create_environment() {
    verify_micromamba

    if [[ -z "$CONFIG_FILE" || ! -f "$CONFIG_FILE" ]]; then
        echo "[ERROR] Environment configuration file missing or invalid."
        exit 1
    fi

    echo "[INFO] Creating bioinformatics environment from $CONFIG_FILE..."

    ENV_NAME=$(grep -m 1 "^name:" "$CONFIG_FILE" | cut -d ':' -f 2 | tr -d ' ')

    if [[ -z "$ENV_NAME" ]]; then
        echo "[ERROR] Could not determine environment name from $CONFIG_FILE"
        exit 1
    fi

    # Check if environment exists
    if micromamba env list | grep -q "$ENV_NAME"; then
        echo "[INFO] Environment $ENV_NAME already exists, updating..."
        micromamba update -y -f "$CONFIG_FILE"
    else
        echo "[INFO] Creating new environment $ENV_NAME..."
        micromamba create -y -f "$CONFIG_FILE"
    fi

    # Add micromamba initialization to .zshrc
    if ! grep -q "# >>> micromamba initialize >>>" "$HOME/.zshrc"; then
        echo "[INFO] Adding micromamba activation to .zshrc."
        MICROMAMBA_BIN_DIR=$(dirname "$MICROMAMBA_BIN")
        cat >>"$HOME/.zshrc" <<EOF
# >>> micromamba initialize >>>
export MAMBA_EXE="$MICROMAMBA_BIN"
export MAMBA_ROOT_PREFIX="$MICROMAMBA_ROOT"
eval "\$($MICROMAMBA_BIN shell hook -s zsh -p \$MAMBA_ROOT_PREFIX)"
alias bioinf="micromamba activate $ENV_NAME"
# <<< micromamba initialize <<<
EOF
    fi

    echo "[INFO] Bioinformatics environment setup complete."
    echo "[INFO] To activate, restart shell and use: bioinf"
}

# Execution based on provided action
ACTION="${1:-}"
case "$ACTION" in
    "env-create")
        create_environment
        ;;
    *)
        echo "[ERROR] Unknown action: $ACTION"
        echo "Usage: $0 env-create [config-file-path]"
        exit 1
        ;;
esac
