#!/usr/bin/env bash
# Oh My Zsh and Powerlevel10k setup script
# Installs Oh My Zsh, Powerlevel10k theme, and essential plugins

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the config directory from arguments or use default
CONFIG_DIR="${1:-$(pwd)/config}"

# Helper functions
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if zsh is installed
if ! command_exists zsh; then
    log_error "zsh is not installed! Please install it first."
    OS_TYPE="$(uname -s)"
    
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        log_info "macOS: Try installing with 'brew install zsh'"
    elif [[ -f /etc/debian_version ]]; then
        log_info "Ubuntu/Debian: Try installing with 'sudo apt install -y zsh'"
    elif [[ -f /etc/redhat-release ]]; then
        log_info "RHEL/CentOS: Try installing with 'sudo yum install -y zsh'"
    else
        log_info "Please install zsh using your system's package manager."
    fi
    exit 1
fi

# Create a backup of existing configurations
BACKUP_DIR="$HOME/.config/bioinf-cli-env/backups/$(date +%Y%m%d%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup function
backup_file() {
    local file="$1"
    if [[ -e "$file" ]]; then
        log_info "Backing up $file"
        if [[ -d "$file" ]]; then
            cp -r "$file" "$BACKUP_DIR/"
        else
            cp "$file" "$BACKUP_DIR/"
        fi
        return 0
    fi
    return 1
}

# Backup existing configurations
for file in "$HOME/.zshrc" "$HOME/.p10k.zsh" "$HOME/.oh-my-zsh"; do
    if [[ -e "$file" ]]; then
        backup_file "$file"
    fi
done

# Download function with fallback
safe_download() {
    local url="$1"
    local output="$2"
    
    log_info "Downloading from $url..."
    
    if command_exists curl; then
        curl -fsSL "$url" -o "$output" || return 1
    elif command_exists wget; then
        wget -q "$url" -O "$output" || return 1
    else
        log_error "Neither curl nor wget is available for downloading."
        return 1
    fi
    
    return 0
}

# Install Oh My Zsh if not already installed
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log_info "Installing Oh My Zsh..."
    
    # Create a temporary file for the installer
    TEMP_INSTALLER="/tmp/install_omz_$(date +%s).sh"
    
    if safe_download "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" "$TEMP_INSTALLER"; then
        sh "$TEMP_INSTALLER" --unattended
        rm -f "$TEMP_INSTALLER"
        log_success "Oh My Zsh installed"
    else
        log_error "Failed to download Oh My Zsh installer."
        exit 1
    fi
else
    log_success "Oh My Zsh is already installed."
fi

# Install Powerlevel10k theme if not already installed
if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
    log_info "Installing Powerlevel10k theme..."
    
    if command_exists git; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
        log_success "Powerlevel10k theme installed"
    else
        log_error "git is required to install Powerlevel10k."
        exit 1
    fi
else
    log_success "Powerlevel10k theme is already installed."
fi

# Install plugins if not already installed
for plugin in "zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions"; do
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin" ]]; then
        log_info "Installing $plugin..."
        
        if command_exists git; then
            git clone "https://github.com/zsh-users/$plugin" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin"
            log_success "$plugin installed"
        else
            log_error "git is required to install plugins."
            exit 1
        fi
    else
        log_success "$plugin is already installed."
    fi
done

# Install fzf if not already installed
if [[ ! -d "$HOME/.fzf" ]]; then
    log_info "Installing fzf..."
    
    if command_exists git; then
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
        "$HOME/.fzf/install" --all --no-update-rc
        log_success "fzf installed"
    else
        log_error "git is required to install fzf."
        exit 1
    fi
else
    log_success "fzf is already installed."
fi

# Helper function to install config files
install_config_file() {
    local src="$1"
    local dest="$2"
    
    # Create a backup if file exists
    if [[ -f "$dest" ]]; then
        cp -f "$dest" "$BACKUP_DIR/$(basename "$dest")"
        
        # Check if file has custom user changes
        if grep -q "# === USER CUSTOMIZATIONS BELOW ===" "$dest"; then
            log_info "Preserving user customizations in $dest"
            
            # Extract user customizations
            USER_CUSTOM_FILE="$BACKUP_DIR/user_custom_$(basename "$dest")"
            sed -n '/# === USER CUSTOMIZATIONS BELOW ===/,$p' "$dest" > "$USER_CUSTOM_FILE"
            
            # Copy new config
            cp -f "$src" "$dest"
            
            # Add marker if needed
            if ! grep -q "# === USER CUSTOMIZATIONS BELOW ===" "$dest"; then
                echo -e "\n# === USER CUSTOMIZATIONS BELOW ===\n# Add your custom configurations here" >> "$dest"
            fi
            
            # Append user customizations after the marker
            sed -n '2,$p' "$USER_CUSTOM_FILE" >> "$dest"
            rm -f "$USER_CUSTOM_FILE"
        else
            # No user customizations marker, just copy
            cp -f "$src" "$dest"
            
            # Add customization marker
            if ! grep -q "# === USER CUSTOMIZATIONS BELOW ===" "$dest"; then
                echo -e "\n# === USER CUSTOMIZATIONS BELOW ===\n# Add your custom configurations here" >> "$dest"
            fi
        fi
    else
        # File doesn't exist, just copy
        cp -f "$src" "$dest"
        
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
    install_config_file "$CONFIG_DIR/zshrc" "$HOME/.zshrc"
else
    log_error "zshrc configuration file not found: $CONFIG_DIR/zshrc"
fi

# Run p10k configuration if not already configured
if [[ ! -f "$HOME/.p10k.zsh" ]]; then
    log_info "Setting up default Powerlevel10k configuration..."
    
    # Check if we have a pre-made p10k.zsh file
    if [[ -f "$CONFIG_DIR/p10k.zsh" ]]; then
        install_config_file "$CONFIG_DIR/p10k.zsh" "$HOME/.p10k.zsh"
    else
        # Create a minimal p10k config
        cat > "$HOME/.p10k.zsh" <<'ENDP10K'
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
