#!/usr/bin/env bash
# Oh My Zsh and Powerlevel10k setup script

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/common.sh"

CONFIG_DIR="${1:-$(pwd)/config}"

# Check if zsh is installed
if ! cmd_exists zsh; then
  log_error "zsh is not installed! Please install it first."
  
  # Provide platform-specific installation instructions
  platform=$(detect_platform)
  os=$(get_os "$platform")
  
  case "$os" in
    "macos")
      log_info "macOS: zsh is installed by default."
      ;;
    "ubuntu"|"debian")
      log_info "Ubuntu/Debian: sudo apt install zsh"
      ;;
    "redhat")
      log_info "RHEL/CentOS: sudo yum install zsh"
      ;;
    *)
      log_info "Please install zsh using your system's package manager."
      ;;
  esac
  exit 1
fi

# Create a backup of existing configurations
BACKUP_DIR="$HOME/.config/bioinf-cli-env/backups/$(date +%Y%m%d%H%M%S)"
mkdir -p "$BACKUP_DIR"

for file in "$HOME/.zshrc" "$HOME/.p10k.zsh" "$HOME/.oh-my-zsh"; do
  if [[ -e "$file" ]]; then
    log_info "Backing up $file"
    if [[ -d "$file" ]]; then
      cp -r "$file" "$BACKUP_DIR/"
    else
      cp "$file" "$BACKUP_DIR/"
    fi
  fi
done

# Install Oh My Zsh if not already installed
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log_info "Installing Oh My Zsh..."
  
  # Use safe download function
  safe_download "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" "/tmp/install_omz.sh"
  sh /tmp/install_omz.sh --unattended
  rm /tmp/install_omz.sh
  
  save_state "oh_my_zsh" "installed"
  log_success "Oh My Zsh installed"
else
  log_success "Oh My Zsh is already installed."
fi

# Install Powerlevel10k theme if not already installed
if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
  log_info "Installing Powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  save_state "powerlevel10k" "installed"
  log_success "Powerlevel10k theme installed"
else
  log_success "Powerlevel10k theme is already installed."
fi

# Install plugins if not already installed
for plugin in "zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions"; do
  if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin" ]]; then
    log_info "Installing $plugin..."
    git clone "https://github.com/zsh-users/$plugin" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin"
    save_state "$plugin" "installed"
    log_success "$plugin installed"
  else
    log_success "$plugin is already installed."
  fi
done

# Install fzf if not already installed
if [[ ! -d "$HOME/.fzf" ]]; then
  log_info "Installing fzf..."
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  "$HOME/.fzf/install" --all --no-update-rc
  save_state "fzf" "installed"
  log_success "fzf installed"
else
  log_success "fzf is already installed."
fi

# Copy config files with backup and merging
install_config_file() {
  local src="$1"
  local dest="$2"
  local backup_dir="$3"
  
  # Check if destination file exists
  if [[ -f "$dest" ]]; then
    # Backup existing file
    backup_config "$dest" "$backup_dir"
    
    # Check if file has custom user changes
    if grep -q "# === USER CUSTOMIZATIONS BELOW ===" "$dest"; then
      log_info "Preserving user customizations in $dest"
      # Extract user customizations
      sed -n '/# === USER CUSTOMIZATIONS BELOW ===/,$p' "$dest" > "$backup_dir/user_custom.tmp"
      
      # Copy new config but preserve user customizations
      cp "$src" "$dest"
      
      # Check if new config has the marker
      if ! grep -q "# === USER CUSTOMIZATIONS BELOW ===" "$dest"; then
        echo -e "\n# === USER CUSTOMIZATIONS BELOW ===\n# Add your custom configurations here" >> "$dest"
      fi
      
      # Append user customizations after the marker
      sed -n '2,$p' "$backup_dir/user_custom.tmp" >> "$dest"
      rm "$backup_dir/user_custom.tmp"
    else
      # No user customizations marker, just copy
      cp "$src" "$dest"
      
      # Add customization marker
      if ! grep -q "# === USER CUSTOMIZATIONS BELOW ===" "$dest"; then
        echo -e "\n# === USER CUSTOMIZATIONS BELOW ===\n# Add your custom configurations here" >> "$dest"
      fi
    fi
  else
    # File doesn't exist, just copy
    cp "$src" "$dest"
    
    # Add customization marker
    if ! grep -q "# === USER CUSTOMIZATIONS BELOW ===" "$dest"; then
      echo -e "\n# === USER CUSTOMIZATIONS BELOW ===\n# Add your custom configurations here" >> "$dest"
    fi
  fi
  
  log_success "Installed $dest"
}

# Copy configuration files
log_info "Copying configuration files..."

# Install zshrc
if [[ -f "$CONFIG_DIR/zshrc" ]]; then
  install_config_file "$CONFIG_DIR/zshrc" "$HOME/.zshrc" "$BACKUP_DIR"
else
  log_error "zshrc configuration file not found: $CONFIG_DIR/zshrc"
fi

# Run p10k configuration if not already configured
if [[ ! -f "$HOME/.p10k.zsh" ]]; then
  log_info "Setting up default Powerlevel10k configuration..."
  
  # Check if we have a pre-made p10k.zsh file
  if [[ -f "$CONFIG_DIR/p10k.zsh" ]]; then
    install_config_file "$CONFIG_DIR/p10k.zsh" "$HOME/.p10k.zsh" "$BACKUP_DIR"
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

# === USER CUSTOMIZATIONS BELOW ===
# Add your custom configurations here
ENDP10K
    log_success "Created default p10k.zsh"
  fi
  
  log_info "Run 'p10k configure' for full customization."
else
  log_success "Powerlevel10k already configured."
fi

# Check if zsh is the default shell
if [[ "$SHELL" != *"zsh"* ]]; then
  log_warning "zsh is not set as the default shell."
  log_info "To set zsh as your default shell, run: chsh -s $(which zsh)"
else
  log_success "zsh is already set as the default shell."
fi

log_success "Oh My Zsh setup complete!"
log_info "Please restart your terminal or run 'source ~/.zshrc' to apply changes."
