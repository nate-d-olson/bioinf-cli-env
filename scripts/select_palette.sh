#!/usr/bin/env bash
# Terminal color palette selector
set -euo pipefail

# Define color palettes
declare -A PALETTES=(
  ["nord"]="dark blue-gray theme, optimized for eye comfort"
  ["dracula"]="dark theme with vibrant colors"
  ["solarized-dark"]="dark blue-green theme with balanced contrast"
  ["solarized-light"]="light blue-green theme with balanced contrast"
  ["gruvbox-dark"]="dark theme with earthy, pastel colors"
  ["gruvbox-light"]="light theme with earthy, pastel colors"
  ["monokai"]="dark theme with bright, vivid colors"
  ["tomorrow-night"]="dark theme with subtle, balanced colors"
  ["ayu-dark"]="dark theme with clean, subtle colors"
  ["ayu-light"]="light theme with clean, subtle colors"
)

# Function to set ZSH and Tmux color schemes
apply_palette() {
  local palette="$1"
  
  # Save selection to config
  echo "$palette" > "$HOME/.config/bioinf-cli-env/current_palette"
  
  case "$palette" in
    "nord")
      # Set Nord theme colors
      cat > "$HOME/.zsh_colors" << 'ENDZSH'
# Nord theme
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#4C566A"
export BAT_THEME="Nord"
export FZF_DEFAULT_OPTS="--color=bg+:#3B4252,bg:#2E3440,spinner:#81A1C1,hl:#616E88,fg:#D8DEE9,header:#616E88,info:#81A1C1,pointer:#81A1C1,marker:#81A1C1,fg+:#D8DEE9,prompt:#81A1C1,hl+:#81A1C1"
ENDZSH
      ;;
      
    "dracula")
      # Set Dracula theme colors
      cat > "$HOME/.zsh_colors" << 'ENDZSH'
# Dracula theme
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6272A4"
export BAT_THEME="Dracula"
export FZF_DEFAULT_OPTS="--color=bg+:#44475a,bg:#282a36,spinner:#bd93f9,hl:#6272a4,fg:#f8f8f2,header:#6272a4,info:#bd93f9,pointer:#bd93f9,marker:#bd93f9,fg+:#f8f8f2,prompt:#bd93f9,hl+:#bd93f9"
ENDZSH
      ;;
      
    "solarized-dark")
      # Set Solarized Dark theme colors
      cat > "$HOME/.zsh_colors" << 'ENDZSH'
# Solarized Dark theme
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#586e75"
export BAT_THEME="Solarized (dark)"
export FZF_DEFAULT_OPTS="--color=bg+:#073642,bg:#002b36,spinner:#839496,hl:#586e75,fg:#839496,header:#586e75,info:#cb4b16,pointer:#cb4b16,marker:#cb4b16,fg+:#839496,prompt:#cb4b16,hl+:#cb4b16"
ENDZSH
      ;;
      
    # Add more themes as needed
    *)
      echo "Unsupported palette: $palette"
      return 1
      ;;
  esac
  
  # Source the color file if ZSH is active
  if [[ -n "${ZSH_VERSION:-}" ]]; then
    source "$HOME/.zsh_colors"
  fi
  
  echo "✅ Applied $palette color palette!"
  echo "🔄 Please restart your terminal for full effect."
}

# Show menu to select palette
select_palette() {
  echo "🎨 Terminal Color Palette Selector"
  echo "=================================="
  echo "Select a color palette for your terminal:"
  echo ""
  
  local i=1
  local options=()
  for palette in "${!PALETTES[@]}"; do
    options[$i]=$palette
    echo "  $i) $palette - ${PALETTES[$palette]}"
    ((i++))
  done
  
  echo ""
  read -p "Enter selection [1-$((i-1))]: " selection
  
  if [[ $selection =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#options[@]} )); then
    apply_palette "${options[$selection]}"
  else
    echo "❌ Invalid selection."
    return 1
  fi
}

# Main execution
if [[ $# -eq 0 ]]; then
  select_palette
elif [[ $# -eq 1 ]]; then
  if [[ -n "${PALETTES[$1]:-}" ]]; then
    apply_palette "$1"
  else
    echo "Available palettes:"
    for palette in "${!PALETTES[@]}"; do
      echo "  $palette - ${PALETTES[$palette]}"
    done
    exit 1
  fi
else
  echo "Usage: $(basename "$0") [palette_name]"
  echo "Run without arguments to see a menu of available palettes."
  exit 1
fi
