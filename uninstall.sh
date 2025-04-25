#!/usr/bin/env bash
# Uninstall script for bioinf-cli-env
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/utils/common.sh"

# Default paths
CONFIG_DIR="${HOME}/.config/bioinf-cli-env"
MICROMAMBA_ROOT="$HOME/micromamba"
BIN_DIR="${HOME}/.local/bin"

log_info "Uninstalling bioinformatics CLI environment..."

# Helper function to safely remove a line from a file
remove_line() {
    local file="$1"
    local pattern="$2"
    
    if [[ -f "$file" ]]; then
        sed -i.bak "/$pattern/d" "$file"
        rm -f "${file}.bak"
    fi
}

# Ask for confirmation before proceeding
read -r -p "This will remove all bioinf-cli-env components. Continue? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy] ]]; then
    log_info "Uninstall cancelled."
    exit 0
fi

# Remove micromamba if installed
if [[ -d "$MICROMAMBA_ROOT" ]]; then
    log_info "Removing micromamba environment..."
    if cmd_exists micromamba; then
        # List and remove all environments
        while IFS= read -r env; do
            [[ "$env" == "base" ]] && continue
            micromamba env remove -y -n "$env"
        done < <(micromamba env list | tail -n +3 | cut -f1 -d' ')
        
        # Remove micromamba installation
        rm -rf "$MICROMAMBA_ROOT"
        rm -f "$BIN_DIR/micromamba"
    fi
fi

# Remove modern tools symlinks
log_info "Removing tool symlinks..."
for tool in eza bat fd rg delta dust procs; do
    rm -f "$BIN_DIR/$tool"
done

# Remove monitoring tools
log_info "Removing monitoring tools..."
rm -f "$BIN_DIR/snakemonitor" \
      "$BIN_DIR/nextflow-monitor" \
      "$BIN_DIR/wdl-monitor"

# Remove Azure OpenAI integration
log_info "Removing Azure OpenAI integration..."
rm -f "$HOME/.zsh_azure_llm"

# Clean up configuration files
log_info "Removing configuration files..."
rm -rf "$CONFIG_DIR"

# Clean up .zshrc modifications
log_info "Cleaning up shell configuration..."
if [[ -f "$HOME/.zshrc" ]]; then
    # Remove our additions from .zshrc
    remove_line "$HOME/.zshrc" "source.*\.zsh_azure_llm"
    remove_line "$HOME/.zshrc" "# Job monitoring aliases"
    remove_line "$HOME/.zshrc" "alias smr="
    remove_line "$HOME/.zshrc" "alias nfr="
    remove_line "$HOME/.zshrc" "alias wdlr="
    remove_line "$HOME/.zshrc" "export BIOINF_MONITOR_CONFIG"
    remove_line "$HOME/.zshrc" "# Add job monitoring completions"
    remove_line "$HOME/.zshrc" "fpath=($CONFIG_DIR"
    remove_line "$HOME/.zshrc" "# >>> micromamba initialize >>>"
    remove_line "$HOME/.zshrc" "# <<< micromamba initialize <<<"
    remove_line "$HOME/.zshrc" "alias bioinf="
fi

# Remove palette selector
rm -f "$BIN_DIR/select_palette.sh"

# Clean up state directory
rm -rf "$STATE_DIR"

log_success "Uninstallation complete!"
log_info "Please restart your shell for changes to take effect."
log_info "Note: Some configurations (like Oh My Zsh) were not removed."
log_info "      You may want to manually review your ~/.zshrc file."
