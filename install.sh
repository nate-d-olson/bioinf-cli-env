#!/usr/bin/env bash
# Interactive installer for bioinf-cli-env
set -euo pipefail
IFS=$'\n\t'
trap 'echo "❌ Installation failed at line $LINENO." >&2; exit 1' ERR

INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$INSTALL_DIR/config"
SCRIPTS_DIR="$INSTALL_DIR/scripts"
BIN_DIR="${HOME}/.local/bin"
BACKUP_DIR="${HOME}/.config/bioinf-cli-env.bak.$(date +%Y%m%d%H%M%S)"

mkdir -p "$BIN_DIR" "$BACKUP_DIR"

# Helper to ask yes/no questions
ask() {
  read -p "$1 [Y/n] " yn
  [[ "$yn" != [Nn]* ]]
}

echo "📦 Starting bioinf-cli-env installation..."

# Detect OS and installer
if [[ "$(uname)" == "Darwin" ]]; then
  INSTALLER="brew"
  echo "→ Detected macOS: using Homebrew"
elif [[ -n "${SLURM_JOB_ID-}" ]]; then
  INSTALLER="user-space"
  echo "→ Detected SLURM cluster: using user-space installation"
elif command -v apt >/dev/null && ask "Use apt for package installation?"; then
  INSTALLER="apt"
  echo "→ Using apt package manager"
else
  INSTALLER="user-space"
  echo "→ Using user-space installation methods"
fi

# Ensure ~/.local/bin is in PATH
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
  export PATH="$BIN_DIR:$PATH"
  echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$HOME/.zshrc"
fi

# Backup existing configs
echo "📦 Backing up existing configurations to $BACKUP_DIR"
for file in .zshrc .p10k.zsh .nanorc .tmux.conf; do
  if [[ -f "$HOME/$file" ]]; then
    cp "$HOME/$file" "$BACKUP_DIR/"
    echo "  → Backed up $file"
  fi
done

# Install components based on user choices
if ask "Install Oh My Zsh and Powerlevel10k?"; then
  bash "$SCRIPTS_DIR/setup_omz.sh" "$CONFIG_DIR"
fi

if ask "Install modern CLI tools (eza, bat, ripgrep, etc)?"; then
  bash "$SCRIPTS_DIR/setup_tools.sh" "$INSTALLER"
fi

if ask "Install micromamba and bioinformatics environment?"; then
  bash "$SCRIPTS_DIR/setup_micromamba.sh" "$INSTALLER"
  bash "$SCRIPTS_DIR/setup_micromamba.sh" env-create "$CONFIG_DIR/micromamba-config.yaml"
fi

## %%TODO%% fix not currently working in docker
# if ask "Install Azure OpenAI CLI integration?"; then
#  bash "$SCRIPTS_DIR/setup_llm.sh"
# fi

if ask "Install job monitoring tools?"; then
  bash "$SCRIPTS_DIR/setup_monitoring.sh"
fi

if ask "Install color palette selector?"; then
  install -m0755 "$SCRIPTS_DIR/select_palette.sh" "$BIN_DIR/"
fi

echo "✅ Installation complete! Please restart your terminal."
if [[ "$SHELL" != *"zsh"* ]]; then
  echo "⚠️  Your current shell is not zsh. Run 'chsh -s $(which zsh)' to change it."
fi
