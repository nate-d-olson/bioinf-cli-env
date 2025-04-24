#!/usr/bin/env bash
# Terminal color palette selector
set -euo pipefail
IFS=$'\n\t'

PALETTES=("Solarized-Dark" "Gruvbox-Dark" "Nord")
PS3="Select a color palette: "

select choice in "${PALETTES[@]}"; do
  if [[ -z "$choice" ]]; then
    echo "Invalid selection."
    continue
  fi
  echo "export POWERLEVEL9K_COLOR_SCHEME=\"$choice\"" > "${HOME}/.p9k_palette"
  # Ensure .p9k_palette is sourced
  grep -qx '[[ -f ~/.p9k_palette ]] && source ~/.p9k_palette' "${HOME}/.zshrc" || \
    echo '[[ -f ~/.p9k_palette ]] && source ~/.p9k_palette' >> "${HOME}/.zshrc"
  echo "Palette set to $choice. Restart your shell to apply changes."
  break
done
