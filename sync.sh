#!/usr/bin/env bash
# Cross-system synchronization script for bioinf-cli-env
set -euo pipefail

# Configuration
CONFIG_FILES=(".zshrc" ".p10k.zsh" ".nanorc" ".tmux.conf" ".zsh_platform" ".zsh_work" ".zsh_azure_llm")
CUSTOM_SCRIPTS=("$HOME/.local/bin/snakemonitor" "$HOME/.local/bin/nextflow_monitor")

# Helper to ask yes/no questions
ask() {
  read -p "$1 [Y/n] " yn
  [[ "$yn" != [Nn]* ]]
}

# Command to sync from local to remote
sync_to_remote() {
  local host="$1"
  local backup_dir="$HOME/.config/bioinf-cli-env.sync.$(date +%Y%m%d%H%M%S)"
  
  echo "📦 Creating backup on $host before syncing"
  ssh "$host" "mkdir -p $backup_dir"
  
  for file in "${CONFIG_FILES[@]}"; do
    if [[ -f "$HOME/$file" ]]; then
      echo "  → Backing up and syncing $file to $host"
      ssh "$host" "if [[ -f $HOME/$file ]]; then cp $HOME/$file $backup_dir/; fi"
      scp "$HOME/$file" "$host:$HOME/"
    fi
  done
  
  # Sync custom scripts
  for script in "${CUSTOM_SCRIPTS[@]}"; do
    if [[ -f "$script" ]]; then
      echo "  → Syncing script $(basename "$script") to $host"
      ssh "$host" "mkdir -p $HOME/.local/bin"
      scp "$script" "$host:$HOME/.local/bin/"
      ssh "$host" "chmod +x $HOME/.local/bin/$(basename "$script")"
    fi
  done
  
  echo "✅ Sync to $host complete. Backup available at $backup_dir"
}

# Command to sync from remote to local
sync_from_remote() {
  local host="$1"
  local backup_dir="$HOME/.config/bioinf-cli-env.sync.$(date +%Y%m%d%H%M%S)"
  
  echo "📦 Creating local backup before syncing from $host"
  mkdir -p "$backup_dir"
  
  for file in "${CONFIG_FILES[@]}"; do
    if ssh "$host" "[[ -f $HOME/$file ]]"; then
      echo "  → Backing up and syncing $file from $host"
      if [[ -f "$HOME/$file" ]]; then
        cp "$HOME/$file" "$backup_dir/"
      fi
      scp "$host:$HOME/$file" "$HOME/"
    fi
  done
  
  # Sync custom scripts
  for script in "${CUSTOM_SCRIPTS[@]}"; do
    local script_name=$(basename "$script")
    if ssh "$host" "[[ -f $HOME/.local/bin/$script_name ]]"; then
      echo "  → Syncing script $script_name from $host"
      mkdir -p "$HOME/.local/bin"
      scp "$host:$HOME/.local/bin/$script_name" "$HOME/.local/bin/"
      chmod +x "$HOME/.local/bin/$script_name"
    fi
  done
  
  echo "✅ Sync from $host complete. Backup available at $backup_dir"
}

# Main logic
if [ $# -lt 1 ] || [ "$1" == "--help" ]; then
  echo "Usage: $0 [push|pull] hostname"
  echo "Examples:"
  echo "  $0 push workstation1    # Push from local to remote"
  echo "  $0 pull workstation1    # Pull from remote to local"
  exit 1
fi

ACTION="$1"
HOST="$2"

if [[ "$ACTION" == "push" ]]; then
  if ask "Are you sure you want to push your local configuration to $HOST?"; then
    sync_to_remote "$HOST"
  fi
elif [[ "$ACTION" == "pull" ]]; then
  if ask "Are you sure you want to pull configuration from $HOST to local machine?"; then
    sync_from_remote "$HOST"
  fi
else
  echo "Error: Unknown action '$ACTION'. Use 'push' or 'pull'."
  exit 1
fi
