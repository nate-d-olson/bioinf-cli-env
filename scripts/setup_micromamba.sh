#!/usr/bin/env bash
# Micromamba and bioinformatics environment setup
set -euo pipefail

INSTALLER="${1:-user-space}"
ACTION="${2:-install}"
CONFIG_FILE="${3:-}"
MICROMAMBA_ROOT="$HOME/micromamba"
BIN_DIR="$HOME/.local/bin"

mkdir -p "$BIN_DIR"

# Install micromamba if not already installed
install_micromamba() {
  if command -v micromamba &>/dev/null; then
    echo "✅ Micromamba is already installed."
    return 0
  fi
  
  echo "📥 Installing micromamba..."
  
  # Download the installer script
  curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba
  
  # Move to the bin directory
  mv bin/micromamba "$BIN_DIR/"
  rm -rf bin
  
  # Initialize micromamba
  "$BIN_DIR/micromamba" shell init -s bash -p "$MICROMAMBA_ROOT"
  "$BIN_DIR/micromamba" shell init -s zsh -p "$MICROMAMBA_ROOT"
  
  echo "✅ Micromamba installed to $BIN_DIR/micromamba"
}

# Create a bioinformatics environment from config file
create_environment() {
  if [[ -z "$CONFIG_FILE" ]]; then
    echo "❌ No environment config file provided."
    return 1
  fi
  
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    return 1
  fi
  
  echo "🧬 Creating bioinformatics environment from $CONFIG_FILE..."
  
  # Extract environment name from yaml
  ENV_NAME=$(grep -m 1 "name:" "$CONFIG_FILE" | cut -d ':' -f 2 | tr -d ' ')
  
  # Check if environment already exists
  if micromamba env list | grep -q "$ENV_NAME"; then
    echo "⚠️ Environment $ENV_NAME already exists."
    if [[ "$ACTION" == "env-create" ]]; then
      echo "📥 Updating environment..."
      micromamba update -y -f "$CONFIG_FILE"
    fi
  else
    echo "📥 Creating new environment..."
    micromamba create -y -f "$CONFIG_FILE"
  fi
  
  echo "✅ Bioinformatics environment setup complete!"
}

# Main execution
case "$ACTION" in
  "install")
    install_micromamba
    ;;
  "env-create")
    create_environment
    ;;
  *)
    echo "❌ Unknown action: $ACTION"
    echo "Valid actions: install, env-create"
    exit 1
    ;;
esac
