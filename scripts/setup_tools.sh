#!/usr/bin/env bash
# Modern CLI tools setup script
set -euo pipefail

INSTALLER="${1:-user-space}"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

echo "🛠️  Setting up modern CLI tools..."

# Install tools based on the installer type
case "$INSTALLER" in
  "brew")
    echo "📥 Installing tools with Homebrew..."
    
    # Check if Homebrew is installed
    if ! command -v brew &>/dev/null; then
      echo "🍺 Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install modern replacements for common tools
    brew install \
      eza \
      bat \
      ripgrep \
      fd \
      jq \
      fzf \
      zoxide \
      tldr \
      htop \
      tmux
    
    echo "✅ Tools installed via Homebrew."
    ;;
    
  "apt")
    echo "📥 Installing tools with apt..."
    
    # Install modern replacements for common tools
    sudo apt update
    sudo apt install -y \
      exa \
      bat \
      ripgrep \
      fd-find \
      jq \
      fzf \
      zoxide \
      tldr \
      htop \
      tmux
    
    # Create aliases for tools with different names on Ubuntu
    if command -v batcat &>/dev/null; then
      ln -sf "$(which batcat)" "$BIN_DIR/bat"
    fi
    
    if command -v fdfind &>/dev/null; then
      ln -sf "$(which fdfind)" "$BIN_DIR/fd"
    fi
    
    echo "✅ Tools installed via apt."
    ;;
    
  "user-space")
    echo "�� Installing tools in user space..."
    
    # Install tools from GitHub releases
    
    # Install eza (or exa for older versions)
    if ! command -v eza &>/dev/null && ! command -v exa &>/dev/null; then
      echo "Installing eza..."
      
      if [[ "$(uname)" == "Darwin" ]]; then
        # macOS - try with Homebrew if available
        if command -v brew &>/dev/null; then
          brew install eza
        else
          echo "⚠️  Please install Homebrew to install eza on macOS, or install manually."
        fi
      else
        # Linux - download binary
        curl -sL "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz" | tar xz -C "$BIN_DIR" eza
        chmod +x "$BIN_DIR/eza"
      fi
    fi
    
    # Install bat
    if ! command -v bat &>/dev/null; then
      echo "Installing bat..."
      
      if [[ "$(uname)" == "Darwin" ]]; then
        # macOS - try with Homebrew if available
        if command -v brew &>/dev/null; then
          brew install bat
        else
          echo "⚠️  Please install Homebrew to install bat on macOS, or install manually."
        fi
      else
        # Linux - download binary
        BAT_VERSION=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | grep -Po '"tag_name": "v\K[^"]*')
        curl -sLO "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
        tar xzf "bat-v${BAT_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
        mv "bat-v${BAT_VERSION}-x86_64-unknown-linux-gnu/bat" "$BIN_DIR/"
        rm -rf "bat-v${BAT_VERSION}-x86_64-unknown-linux-gnu" "bat-v${BAT_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
      fi
    fi
    
    # Install ripgrep
    if ! command -v rg &>/dev/null; then
      echo "Installing ripgrep..."
      
      if [[ "$(uname)" == "Darwin" ]]; then
        # macOS - try with Homebrew if available
        if command -v brew &>/dev/null; then
          brew install ripgrep
        else
          echo "⚠️  Please install Homebrew to install ripgrep on macOS, or install manually."
        fi
      else
        # Linux - download binary
        RG_VERSION=$(curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep -Po '"tag_name": "\K[^"]*')
        curl -sLO "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz"
        tar xzf "ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz"
        mv "ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl/rg" "$BIN_DIR/"
        rm -rf "ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl" "ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz"
      fi
    fi
    
    # Install fd
    if ! command -v fd &>/dev/null; then
      echo "Installing fd..."
      
      if [[ "$(uname)" == "Darwin" ]]; then
        # macOS - try with Homebrew if available
        if command -v brew &>/dev/null; then
          brew install fd
        else
          echo "⚠️  Please install Homebrew to install fd on macOS, or install manually."
        fi
      else
        # Linux - download binary
        FD_VERSION=$(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest | grep -Po '"tag_name": "v\K[^"]*')
        curl -sLO "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
        tar xzf "fd-v${FD_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
        mv "fd-v${FD_VERSION}-x86_64-unknown-linux-gnu/fd" "$BIN_DIR/"
        rm -rf "fd-v${FD_VERSION}-x86_64-unknown-linux-gnu" "fd-v${FD_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
      fi
    fi
    
    # Install zoxide
    if ! command -v zoxide &>/dev/null; then
      echo "Installing zoxide..."
      curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    fi
    
    echo "✅ Tools installed in user space."
    ;;
    
  *)
    echo "❌ Unknown installer type: $INSTALLER"
    echo "Valid types: brew, apt, user-space"
    exit 1
    ;;
esac

echo "✅ Modern CLI tools setup complete!"
