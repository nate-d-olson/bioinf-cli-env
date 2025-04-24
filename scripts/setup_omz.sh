#!/usr/bin/env bash
# Oh My Zsh and Powerlevel10k setup script
set -euo pipefail

CONFIG_DIR="${1:-$(pwd)/config}"

# Check if zsh is installed
if ! command -v zsh &>/dev/null; then
  echo "❌ zsh is not installed! Please install it first."
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "macOS: zsh is installed by default."
  else
    echo "Ubuntu: sudo apt install zsh"
  fi
  exit 1
fi

# Install Oh My Zsh if not already installed
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "📥 Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "✅ Oh My Zsh is already installed."
fi

# Install Powerlevel10k theme if not already installed
if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
  echo "📥 Installing Powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
else
  echo "✅ Powerlevel10k theme is already installed."
fi

# Install plugins if not already installed
if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]]; then
  echo "📥 Installing zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
else
  echo "✅ zsh-autosuggestions is already installed."
fi

if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]]; then
  echo "📥 Installing zsh-syntax-highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
else
  echo "✅ zsh-syntax-highlighting is already installed."
fi

if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions" ]]; then
  echo "📥 Installing zsh-completions..."
  git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions
else
  echo "✅ zsh-completions is already installed."
fi

# Install fzf if not already installed
if [[ ! -d "$HOME/.fzf" ]]; then
  echo "📥 Installing fzf..."
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  "$HOME/.fzf/install" --all --no-update-rc
else
  echo "✅ fzf is already installed."
fi

# Copy config files
echo "📝 Copying configuration files..."
cp "$CONFIG_DIR/zshrc" "$HOME/.zshrc"

# Run p10k configuration if not already configured
if [[ ! -f "$HOME/.p10k.zsh" ]]; then
  echo "⚙️  Setting up default Powerlevel10k configuration..."
  
  # Check if we have a pre-made p10k.zsh file
  if [[ -f "$CONFIG_DIR/p10k.zsh" ]]; then
    cp "$CONFIG_DIR/p10k.zsh" "$HOME/.p10k.zsh"
  else
    # Create a minimal p10k config
    cat > "$HOME/.p10k.zsh" << 'ENDP10K'
# Generated Powerlevel10k configuration
# To customize, run: p10k configure or edit ~/.p10k.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Prompt elements
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  os_icon                 # OS identifier
  dir                     # Current directory
  vcs                     # Git status
  prompt_char             # Prompt symbol
)

typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  status                  # Exit code of the last command
  command_execution_time  # Duration of the last command
  background_jobs         # Presence of background jobs
  direnv                  # direnv status
  virtualenv              # Python virtual environment
  anaconda                # conda/micromamba environment
  aws                     # AWS profile
  time                    # Current time
)

# Display execution time of the last command if takes at least this many seconds.
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3

# Basic settings
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
typeset -g POWERLEVEL9K_MODE=nerdfont-complete
typeset -g POWERLEVEL9K_ICON_PADDING=moderate

# Anaconda/micromamba environment display
typeset -g POWERLEVEL9K_ANACONDA_SHOW_ON_COMMAND='python|pip|ipython|jupyter|conda|mamba|micromamba'
ENDP10K
  fi
  
  echo "✅ Powerlevel10k configuration created. Run 'p10k configure' for full customization."
else
  echo "✅ Powerlevel10k already configured."
fi

echo "✅ Oh My Zsh setup complete!"
