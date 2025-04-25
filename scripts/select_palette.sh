#!/usr/bin/env bash
# Terminal color palette selector
set -euo pipefail
IFS=$'\n\t'

CONFIG_DIR="$HOME/.config/bioinf-cli-env"
PALETTE_FILE="$CONFIG_DIR/current_palette"
mkdir -p "$CONFIG_DIR"

# Function to print header
print_header() {
    echo "🎨 Terminal Color Palette Selector"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Select a color scheme optimized for bioinformatics work."
    echo "These palettes are designed for readability and reduced eye strain."
    echo ""
}

# Function to apply a color palette using ANSI escape sequences
apply_palette() {
    local name="$1"
    echo "Applying palette: $name"

    case "$name" in
    "gruvbox-dark")
        # Gruvbox Dark palette
        echo -ne "\033]10;#ebdbb2\007" # Foreground
        echo -ne "\033]11;#282828\007" # Background
        echo -ne "\033]12;#ebdbb2\007" # Cursor

        # ANSI Colors
        echo -ne "\033]4;0;#282828\007"  # Black
        echo -ne "\033]4;1;#cc241d\007"  # Red
        echo -ne "\033]4;2;#98971a\007"  # Green
        echo -ne "\033]4;3;#d79921\007"  # Yellow
        echo -ne "\033]4;4;#458588\007"  # Blue
        echo -ne "\033]4;5;#b16286\007"  # Magenta
        echo -ne "\033]4;6;#689d6a\007"  # Cyan
        echo -ne "\033]4;7;#a89984\007"  # White
        echo -ne "\033]4;8;#928374\007"  # Bright Black
        echo -ne "\033]4;9;#fb4934\007"  # Bright Red
        echo -ne "\033]4;10;#b8bb26\007" # Bright Green
        echo -ne "\033]4;11;#fabd2f\007" # Bright Yellow
        echo -ne "\033]4;12;#83a598\007" # Bright Blue
        echo -ne "\033]4;13;#d3869b\007" # Bright Magenta
        echo -ne "\033]4;14;#8ec07c\007" # Bright Cyan
        echo -ne "\033]4;15;#ebdbb2\007" # Bright White
        ;;

    "solarized-dark")
        # Solarized Dark palette
        echo -ne "\033]10;#839496\007" # Foreground
        echo -ne "\033]11;#002b36\007" # Background
        echo -ne "\033]12;#839496\007" # Cursor

        # ANSI Colors
        echo -ne "\033]4;0;#073642\007"  # Black
        echo -ne "\033]4;1;#dc322f\007"  # Red
        echo -ne "\033]4;2;#859900\007"  # Green
        echo -ne "\033]4;3;#b58900\007"  # Yellow
        echo -ne "\033]4;4;#268bd2\007"  # Blue
        echo -ne "\033]4;5;#d33682\007"  # Magenta
        echo -ne "\033]4;6;#2aa198\007"  # Cyan
        echo -ne "\033]4;7;#eee8d5\007"  # White
        echo -ne "\033]4;8;#002b36\007"  # Bright Black
        echo -ne "\033]4;9;#cb4b16\007"  # Bright Red
        echo -ne "\033]4;10;#586e75\007" # Bright Green
        echo -ne "\033]4;11;#657b83\007" # Bright Yellow
        echo -ne "\033]4;12;#839496\007" # Bright Blue
        echo -ne "\033]4;13;#6c71c4\007" # Bright Magenta
        echo -ne "\033]4;14;#93a1a1\007" # Bright Cyan
        echo -ne "\033]4;15;#fdf6e3\007" # Bright White
        ;;

    "nord")
        # Nord palette
        echo -ne "\033]10;#D8DEE9\007" # Foreground
        echo -ne "\033]11;#2E3440\007" # Background
        echo -ne "\033]12;#D8DEE9\007" # Cursor

        # ANSI Colors
        echo -ne "\033]4;0;#3B4252\007"  # Black
        echo -ne "\033]4;1;#BF616A\007"  # Red
        echo -ne "\033]4;2;#A3BE8C\007"  # Green
        echo -ne "\033]4;3;#EBCB8B\007"  # Yellow
        echo -ne "\033]4;4;#81A1C1\007"  # Blue
        echo -ne "\033]4;5;#B48EAD\007"  # Magenta
        echo -ne "\033]4;6;#88C0D0\007"  # Cyan
        echo -ne "\033]4;7;#E5E9F0\007"  # White
        echo -ne "\033]4;8;#4C566A\007"  # Bright Black
        echo -ne "\033]4;9;#BF616A\007"  # Bright Red
        echo -ne "\033]4;10;#A3BE8C\007" # Bright Green
        echo -ne "\033]4;11;#EBCB8B\007" # Bright Yellow
        echo -ne "\033]4;12;#81A1C1\007" # Bright Blue
        echo -ne "\033]4;13;#B48EAD\007" # Bright Magenta
        echo -ne "\033]4;14;#8FBCBB\007" # Bright Cyan
        echo -ne "\033]4;15;#ECEFF4\007" # Bright White
        ;;

    "dracula")
        # Dracula palette
        echo -ne "\033]10;#F8F8F2\007" # Foreground
        echo -ne "\033]11;#282A36\007" # Background
        echo -ne "\033]12;#F8F8F2\007" # Cursor

        # ANSI Colors
        echo -ne "\033]4;0;#000000\007"  # Black
        echo -ne "\033]4;1;#FF5555\007"  # Red
        echo -ne "\033]4;2;#50FA7B\007"  # Green
        echo -ne "\033]4;3;#F1FA8C\007"  # Yellow
        echo -ne "\033]4;4;#BD93F9\007"  # Blue
        echo -ne "\033]4;5;#FF79C6\007"  # Magenta
        echo -ne "\033]4;6;#8BE9FD\007"  # Cyan
        echo -ne "\033]4;7;#BFBFBF\007"  # White
        echo -ne "\033]4;8;#4D4D4D\007"  # Bright Black
        echo -ne "\033]4;9;#FF6E67\007"  # Bright Red
        echo -ne "\033]4;10;#5AF78E\007" # Bright Green
        echo -ne "\033]4;11;#F4F99D\007" # Bright Yellow
        echo -ne "\033]4;12;#CAA9FA\007" # Bright Blue
        echo -ne "\033]4;13;#FF92D0\007" # Bright Magenta
        echo -ne "\033]4;14;#9AEDFE\007" # Bright Cyan
        echo -ne "\033]4;15;#E6E6E6\007" # Bright White
        ;;

    "default")
        # Reset to terminal default
        echo "Resetting to terminal default colors"
        echo -ne "\033]110\007" # Reset foreground
        echo -ne "\033]111\007" # Reset background
        echo -ne "\033]112\007" # Reset cursor

        # Reset ANSI colors
        for i in {0..15}; do
            echo -ne "\033]4;$i;\007"
        done
        ;;
    esac

    # Save the current palette
    echo "$name" >"$PALETTE_FILE"

    # Show a sample of colors
    echo ""
    echo "Palette applied! Sample:"
    echo -e "\e[30m■\e[0m \e[31m■\e[0m \e[32m■\e[0m \e[33m■\e[0m \e[34m■\e[0m \e[35m■\e[0m \e[36m■\e[0m \e[37m■\e[0m"
    echo -e "\e[90m■\e[0m \e[91m■\e[0m \e[92m■\e[0m \e[93m■\e[0m \e[94m■\e[0m \e[95m■\e[0m \e[96m■\e[0m \e[97m■\e[0m"
    echo ""
}

# Function to display available palettes and prompt for selection
select_palette() {
    print_header

    echo "Available Palettes:"
    echo "1) Gruvbox Dark - Warm, earthy tones optimized for readability"
    echo "2) Solarized Dark - Precision colors, scientific approach to contrast"
    echo "3) Nord - Arctic, bluish color palette with cold hues"
    echo "4) Dracula - Dark theme with vibrant colors"
    echo "5) Default - Reset to terminal default colors"
    echo ""

    local sync_choice=""
    if [[ -f "$PALETTE_FILE" ]]; then
        current_palette=$(cat "$PALETTE_FILE")
        echo "Current palette: $current_palette"
        echo ""
    fi

    read -p "Select a palette (1-5): " choice

    case "$choice" in
    1)
        apply_palette "gruvbox-dark"
        ;;
    2)
        apply_palette "solarized-dark"
        ;;
    3)
        apply_palette "nord"
        ;;
    4)
        apply_palette "dracula"
        ;;
    5)
        apply_palette "default"
        ;;
    *)
        echo "Invalid selection. Exiting."
        exit 1
        ;;
    esac

    # Ask about auto-sync
    echo "Would you like to automatically apply this palette in new terminal sessions?"
    read -p "Enable auto-sync? (y/n): " sync_choice

    if [[ "$sync_choice" == "y" || "$sync_choice" == "Y" ]]; then
        # Check if palette loading is already in zshrc
        if ! grep -q "bioinf-cli-env/current_palette" "$HOME/.zshrc"; then
            cat >>"$HOME/.zshrc" <<'ENDZSH'

# Load color palette if set
if [[ -f "$HOME/.config/bioinf-cli-env/current_palette" ]]; then
  "$HOME/bioinf-cli-env/scripts/select_palette.sh" --load
fi
ENDZSH
            echo "Auto-sync enabled. Palette will be loaded in new terminal sessions."
        else
            echo "Auto-sync already configured in .zshrc"
        fi
    else
        echo "Auto-sync not enabled. Run this script manually to change the palette."
    fi
}

# Main script logic
if [[ $# -eq 0 ]]; then
    select_palette
elif [[ "$1" == "--load" ]]; then
    # Silently load the current palette
    if [[ -f "$PALETTE_FILE" ]]; then
        apply_palette "$(cat "$PALETTE_FILE")" >/dev/null
    fi
else
    echo "Usage: $0 [--load]"
    echo "  --load: Silently load the current palette (used in .zshrc)"
    exit 1
fi

exit 0
