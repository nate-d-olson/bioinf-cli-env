#!/usr/bin/env bash
# Safe removal script for bioinf-cli-env
set -euo pipefail

BACKUP_DIR="${HOME}/.config/bioinf-cli-env.bak.$(date +%Y%m%d%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Helper to ask yes/no questions
ask() {
  read -p "$1 [Y/n] " yn
  [[ "$yn" != [Nn]* ]]
}

echo "📦 Creating backup of current configurations in $BACKUP_DIR"
for file in ~/.zshrc ~/.p10k.zsh ~/.nanorc ~/.tmux.conf; do
  if [[ -f "$file" ]]; then
    cp "$file" "$BACKUP_DIR/"
    echo "  → Backed up $file"
  fi
done

if ask "Would you like to restore your original configurations from before installation?"; then
  # Find the oldest backup directory
  ORIG_BACKUP=$(find "$HOME/.config" -maxdepth 1 -name "bioinf-cli-env.bak.*" | sort | head -n 1)
  
  if [[ -n "$ORIG_BACKUP" ]]; then
    echo "📦 Restoring configurations from $ORIG_BACKUP"
    for file in .zshrc .p10k.zsh .nanorc .tmux.conf; do
      if [[ -f "$ORIG_BACKUP/$file" ]]; then
        cp "$ORIG_BACKUP/$file" "$HOME/"
        echo "  → Restored $file"
      fi
    done
  else
    echo "❌ No original backup found."
  fi
fi

if ask "Would you like to remove installed plugins and tools? (This might affect other software)"; then
  # Remove Oh My Zsh custom plugins
  if [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]]; then
    rm -rf "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    echo "  → Removed zsh-autosuggestions plugin"
  fi
  
  if [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]]; then
    rm -rf "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    echo "  → Removed zsh-syntax-highlighting plugin"
  fi
  
  if [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
    rm -rf "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    echo "  → Removed powerlevel10k theme"
  fi
  
  # Remove fzf
  if [[ -d "$HOME/.fzf" ]]; then
    "$HOME/.fzf/uninstall" --all
    echo "  → Removed fzf"
  fi
fi

echo "✅ Uninstallation complete. Please restart your terminal."
