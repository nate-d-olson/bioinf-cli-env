#!/usr/bin/env bash
# Modern CLI tools installation script

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/common.sh"

# Set default paths
BIN_DIR="${HOME}/.local/bin"
mkdir -p "$BIN_DIR"

# Create a log file for installed package versions
LOG_FILE="${HOME}/.bioinf-cli-env-tools.log"
echo "# Bioinformatics CLI Environment Tool Installation Log - $(date)" > "$LOG_FILE"
echo "# This file contains version information for installed CLI tools" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Get installer type from arguments or auto-detect
INSTALLER="${1:-}"
if [[ -z "$INSTALLER" ]]; then
    PLATFORM=$(detect_platform)
    INSTALLER=$(get_package_manager)
fi

log_info "Installing modern CLI tools using $INSTALLER installer..."
echo "Installation platform: $PLATFORM" >> "$LOG_FILE"
echo "Package manager: $INSTALLER" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Check if we're on a supported platform
if [[ "$INSTALLER" != "apt" && "$INSTALLER" != "brew" ]]; then
    log_warning "This script is primarily designed for Ubuntu (apt) and macOS (brew)."
    log_warning "Some package installations may not work correctly on your system."
    echo "UNSUPPORTED PLATFORM WARNING: This system uses $INSTALLER" >> "$LOG_FILE"
fi

# Function to record package version information
record_package_version() {
    local package="$1"
    local version_command="$2"
    local version_output
    
    version_output=$(eval "$version_command" 2>/dev/null)
    if [[ $? -eq 0 && -n "$version_output" ]]; then
        echo "✓ $package: $version_output" >> "$LOG_FILE"
        log_success "$package already installed: $version_output"
        return 0
    else
        return 1
    fi
}

# Function to check if a package is already installed
check_package_installed() {
    local package="$1"
    local version_command=""
    local alt_commands=("${@:2}")
    
    # Try to determine version based on package name
    case "$package" in
        bat|batcat)
            version_command="bat --version 2>/dev/null || batcat --version"
            ;;
        eza|exa)
            version_command="eza --version 2>/dev/null || exa --version"
            ;;
        ripgrep|rg)
            version_command="rg --version"
            ;;
        fd|fd-find|fdfind)
            version_command="fd --version 2>/dev/null || fdfind --version"
            ;;
        jq)
            version_command="jq --version"
            ;;
        fzf)
            version_command="fzf --version"
            ;;
        htop)
            version_command="htop --version | head -n 1"
            ;;
        tmux)
            version_command="tmux -V"
            ;;
        zoxide)
            version_command="zoxide --version"
            ;;
        yq)
            version_command="yq --version"
            ;;
        *)
            # For other packages, try a simple command check
            version_command="$package --version"
            ;;
    esac
    
    # Try the primary version command
    if record_package_version "$package" "$version_command"; then
        return 0
    fi
    
    # Try alternative commands if provided
    if [[ ${#alt_commands[@]} -gt 0 ]]; then
        for alt_cmd in "${alt_commands[@]}"; do
            if record_package_version "$package" "$alt_cmd"; then
                return 0
            fi
        done
    fi
    
    # Check if the command exists without version info
    if command -v "$package" &>/dev/null; then
        log_success "$package is already installed (version information unavailable)"
        echo "✓ $package: installed (version unknown)" >> "$LOG_FILE"
        return 0
    fi
    
    # Check for alternative command names
    case "$package" in
        eza)
            if command -v exa &>/dev/null; then
                log_success "exa is installed instead of eza"
                record_package_version "exa" "exa --version"
                return 0
            fi
            ;;
        bat)
            if command -v batcat &>/dev/null; then
                log_success "batcat is installed instead of bat"
                record_package_version "batcat" "batcat --version"
                return 0
            fi
            ;;
        fd)
            if command -v fdfind &>/dev/null; then
                log_success "fdfind is installed instead of fd"
                record_package_version "fdfind" "fdfind --version"
                return 0
            fi
            ;;
    esac
    
    # Package is not installed
    return 1
}

# Define the install_binary function to handle binary installations more robustly
install_binary() {
    local name="$1"
    local url="$2"
    local dest="$3"
    local extracted_path="${4:-}"
    
    log_info "Installing $name from $url..."
    
    # Create a temporary directory for downloads
    local tmp_dir
    tmp_dir=$(create_temp_dir "$name.XXXXXX")
    local download_file="$tmp_dir/${name}_download"
    
    # Download the file
    if ! safe_download "$url" "$download_file"; then
        log_error "Failed to download $name from $url"
        echo "✗ $name: Failed to download from $url" >> "$LOG_FILE"
        return 1
    fi
    
    # Handle different file types
    if [[ "$url" == *.tar.gz || "$url" == *.tgz ]]; then
        # Extract tarball
        if ! tar -xzf "$download_file" -C "$tmp_dir"; then
            log_error "Failed to extract $name tarball"
            echo "✗ $name: Failed to extract tarball" >> "$LOG_FILE"
            return 1
        fi
        
        # Find the binary in the extracted directory
        if [[ -n "$extracted_path" ]]; then
            # If path is specified, use it
            if [[ -f "$tmp_dir/$extracted_path" ]]; then
                cp "$tmp_dir/$extracted_path" "$dest"
            else
                log_error "Binary not found at expected path: $extracted_path"
                echo "✗ $name: Binary not found at expected path: $extracted_path" >> "$LOG_FILE"
                return 1
            fi
        else
            # Try to find the binary with the same name
            local binary_file
            if binary_file=$(find "$tmp_dir" -type f -name "$name" -perm -u=x | head -n 1); then
                if [[ -n "$binary_file" ]]; then
                    cp "$binary_file" "$dest"
                else
                    # If not found by name, look for any executable
                    binary_file=$(find "$tmp_dir" -type f -perm -u=x | head -n 1)
                    if [[ -n "$binary_file" ]]; then
                        cp "$binary_file" "$dest"
                    else
                        log_error "Could not find binary in extracted files"
                        echo "✗ $name: Could not find binary in extracted files" >> "$LOG_FILE"
                        return 1
                    fi
                fi
            fi
        fi
    else
        # Direct binary download
        cp "$download_file" "$dest"
    fi
    
    # Make executable
    chmod +x "$dest"
    
    if [[ -f "$dest" && -x "$dest" ]]; then
        # Record version information
        local version_output
        version_output=$("$dest" --version 2>/dev/null || "$dest" -v 2>/dev/null || "$dest" -version 2>/dev/null || echo "version unknown")
        log_success "$name installed successfully at $dest ($version_output)"
        echo "✓ $name: $version_output (manually installed at $dest)" >> "$LOG_FILE"
        return 0
    else
        log_error "Failed to install $name to $dest"
        echo "✗ $name: Failed to install to $dest" >> "$LOG_FILE"
        return 1
    fi
}

# Function to get latest GitHub release URL with better error handling
get_latest_release_url() {
    local repo="$1"
    local os_pattern="${2:-}"
    local arch_pattern="${3:-}"
    local url="https://api.github.com/repos/$repo/releases/latest"
    local max_retries=3
    local retry=0
    local release_info=""
    
    while [[ $retry -lt $max_retries ]]; do
        release_info=$(curl -s -H "Accept: application/vnd.github.v3+json" "$url")
        
        # Check if we got valid JSON
        if echo "$release_info" | jq -e . >/dev/null 2>&1; then
            break
        fi
        
        log_warning "Failed to fetch release info for $repo, retrying ($((retry+1))/$max_retries)..."
        sleep 2
        ((retry++))
    done
    
    if [[ $retry -eq $max_retries ]]; then
        log_error "Failed to fetch release info for $repo after $max_retries attempts"
        echo "✗ GitHub API: Failed to fetch release info for $repo" >> "$LOG_FILE"
        return 1
    fi
    
    # Parse assets and find the best match
    local download_url=""
    
    # Try exact match first
    if [[ -n "$os_pattern" && -n "$arch_pattern" ]]; then
        download_url=$(echo "$release_info" | jq -r ".assets[] | select(.name | test(\"$os_pattern.*$arch_pattern\") or test(\"$arch_pattern.*$os_pattern\")) | .browser_download_url" | head -n 1)
    fi
    
    # If no exact match, try just OS
    if [[ -z "$download_url" && -n "$os_pattern" ]]; then
        download_url=$(echo "$release_info" | jq -r ".assets[] | select(.name | test(\"$os_pattern\")) | .browser_download_url" | head -n 1)
    fi
    
    # If still no match, try just architecture
    if [[ -z "$download_url" && -n "$arch_pattern" ]]; then
        download_url=$(echo "$release_info" | jq -r ".assets[] | select(.name | test(\"$arch_pattern\")) | .browser_download_url" | head -n 1)
    fi
    
    # If still no match, get any tar.gz or binary as fallback
    if [[ -z "$download_url" ]]; then
        download_url=$(echo "$release_info" | jq -r ".assets[] | select(.name | endswith(\".tar.gz\") or endswith(\".tgz\")) | .browser_download_url" | head -n 1)
        
        if [[ -z "$download_url" ]]; then
            download_url=$(echo "$release_info" | jq -r ".assets[0].browser_download_url")
        fi
    fi
    
    if [[ -z "$download_url" || "$download_url" == "null" ]]; then
        log_error "Could not find a suitable release asset for $repo"
        echo "✗ GitHub API: Could not find a suitable release asset for $repo" >> "$LOG_FILE"
        return 1
    fi
    
    echo "$download_url"
}

# Function to detect if a tool is available via package manager
is_package_available() {
    local package="$1"
    local installer="$2"
    
    case "$installer" in
    apt)
        # Try multiple search patterns for maximum compatibility
        if apt-cache search --names-only "^$package$" 2>/dev/null | grep -q -i "$package" || \
           apt-cache search --names-only "$package" 2>/dev/null | grep -q -i "$package"; then
            return 0
        fi
        return 1
        ;;
    brew)
        # Check if the formula exists in brew
        if brew info "$package" &>/dev/null; then
            return 0
        fi
        # Secondary check using search (less reliable)
        if brew search "$package" 2>/dev/null | grep -q -i "^$package\$"; then
            return 0
        fi
        return 1
        ;;
    *)
        log_warning "Package availability check not supported for $installer"
        return 1
        ;;
    esac
}

# Function to handle package installation with proper checks
install_tool() {
    local tool="$1"
    local installer="$2"
    local alt_names=("${@:3}")
    
    # First check if the tool is already installed
    if check_package_installed "$tool"; then
        return 0
    fi
    
    # Check if any of the alternative names are installed
    for alt_name in "${alt_names[@]}"; do
        if check_package_installed "$alt_name"; then
            return 0
        fi
    done
    
    log_info "$tool is not installed. Checking availability..."
    
    # Check if the package is available via the package manager
    if is_package_available "$tool" "$installer"; then
        log_info "Installing $tool via $installer..."
        install_via_package_manager "$installer" "$tool"
    else
        # Try alternative names if provided
        local alt_available=false
        if [[ ${#alt_names[@]} -gt 0 ]]; then
            for alt_name in "${alt_names[@]}"; do
                if is_package_available "$alt_name" "$installer"; then
                    log_info "Installing $tool via $installer (package: $alt_name)..."
                    install_via_package_manager "$installer" "$alt_name"
                    alt_available=true
                    break
                fi
            done
        fi
        
        # If not available via package manager, try to install from GitHub or provide manual instructions
        if [[ "$alt_available" != "true" ]]; then
            log_warning "$tool not found in $installer repositories"
            
            if [[ "$installer" != "apt" && "$installer" != "brew" ]]; then
                log_error "Unsupported package manager: $installer. This script is optimized for Ubuntu (apt) and macOS (brew)."
                log_info "Please install $tool manually."
                echo "✗ $tool: Not available via $installer. Manual installation required." >> "$LOG_FILE"
                return 1
            fi
            
            # Try to install from GitHub for supported tools
            case "$tool" in
                bat|eza|zoxide|yq|jq)
                    log_info "Attempting to install $tool from GitHub..."
                    install_from_github "$tool"
                    ;;
                *)
                    # For unsupported tools, provide manual installation instructions
                    log_error "Unable to install $tool automatically."
                    
                    # Provide different installation instructions based on the tool
                    case "$tool" in
                        ripgrep)
                            url="https://github.com/BurntSushi/ripgrep"
                            ;;
                        fd)
                            url="https://github.com/sharkdp/fd"
                            ;;
                        fzf)
                            url="https://github.com/junegunn/fzf"
                            ;;
                        htop)
                            url="https://github.com/htop-dev/htop"
                            ;;
                        tmux)
                            url="https://github.com/tmux/tmux"
                            ;;
                        *)
                            url="https://github.com/search?q=$tool"
                            ;;
                    esac
                    
                    log_info "Please install $tool manually from: $url"
                    echo "✗ $tool: Not automatically installable. Manual installation required from: $url" >> "$LOG_FILE"
                    ;;
            esac
        fi
    fi
}

# Function to install tools via package manager with better error handling
install_via_package_manager() {
    local installer="$1"
    local tools=("${@:2}")

    case "$installer" in
    brew)
        log_info "Installing/updating tools via Homebrew..."
        # Update brew first
        brew update
        for tool in "${tools[@]}"; do
            if brew list "$tool" &>/dev/null; then
                log_success "$tool is already installed via brew, checking for updates..."
                brew upgrade "$tool" || log_warning "Failed to upgrade $tool, but it's already installed"
                # Record the installed version
                local version=$(brew info --json "$tool" | jq -r '.[0].installed[0].version')
                log_success "$tool updated to version $version"
                echo "✓ $tool: $version (via brew)" >> "$LOG_FILE"
            else
                log_info "Installing $tool..."
                if brew install "$tool"; then
                    # Record the installed version
                    local version=$(brew info --json "$tool" | jq -r '.[0].installed[0].version')
                    log_success "Installed $tool version $version"
                    echo "✓ $tool: $version (via brew)" >> "$LOG_FILE"
                else
                    log_error "Failed to install $tool via brew"
                    echo "✗ $tool: Failed to install via brew" >> "$LOG_FILE"
                    # For critical tools, try alternative installation
                    case "$tool" in
                        bat|eza|zoxide|yq|jq)
                            log_info "Attempting to install $tool from GitHub..."
                            install_from_github "$tool"
                            ;;
                    esac
                fi
            fi
        done
        ;;
    apt)
        log_info "Installing/updating tools via apt..."
        
        # Get sudo command with proper interactive prompting
        local sudo_cmd=""
        local no_interactive="${INTERACTIVE:-false}"
        if [[ "$no_interactive" == "false" ]]; then
            sudo_cmd=$(get_sudo_command "Administrator privileges are required to install packages via apt" "false")
        else 
            sudo_cmd=$(get_sudo_command "Administrator privileges are required to install packages via apt" "true")
        fi

        # First update package lists
        if [[ -n "$sudo_cmd" ]]; then
            $sudo_cmd apt-get update
        else
            log_warning "No sudo access. Cannot update package lists."
        fi

        for tool in "${tools[@]}"; do
            # Check if tool is already installed
            if dpkg -l | grep -qw "$tool"; then
                local version=$(dpkg -s "$tool" 2>/dev/null | grep "^Version:" | cut -d ' ' -f 2)
                log_success "$tool is already installed (version $version)"
                echo "✓ $tool: $version (via apt)" >> "$LOG_FILE"
            else
                log_info "Installing $tool..."
                if [[ -n "$sudo_cmd" ]]; then
                    if $sudo_cmd apt-get install -y "$tool"; then
                        local version=$(dpkg -s "$tool" 2>/dev/null | grep "^Version:" | cut -d ' ' -f 2)
                        log_success "Installed $tool (version $version)"
                        echo "✓ $tool: $version (via apt)" >> "$LOG_FILE"
                    else
                        log_warning "Failed to install $tool via apt"
                        echo "✗ $tool: Failed to install via apt" >> "$LOG_FILE"
                        # For critical tools, try alternative installation
                        case "$tool" in
                            bat|eza|zoxide|yq|jq)
                                log_info "Attempting to install $tool from GitHub..."
                                install_from_github "$tool"
                                ;;
                            *)
                                log_error "Unable to install $tool. Please install manually."
                                ;;
                        esac
                    fi
                else
                    log_warning "No sudo access. Skipping $tool installation via apt"
                    echo "✗ $tool: No sudo access for apt installation" >> "$LOG_FILE"
                    # Try github installation for some tools
                    case "$tool" in
                        bat|eza|zoxide|yq|jq)
                            log_info "Attempting to install $tool from GitHub..."
                            install_from_github "$tool"
                            ;;
                        *)
                            log_error "Unable to install $tool without sudo access. Please install manually."
                            ;;
                    esac
                fi
            fi
        done
        ;;
    *)
        log_error "Unsupported package manager: $installer"
        echo "✗ ERROR: Unsupported package manager: $installer" >> "$LOG_FILE"
        log_error "This script only supports Ubuntu (apt) and macOS (brew) package managers."
        log_error "Please install packages manually for your system."
        return 1
        ;;
    esac

    return 0
}

# Function to install tools from GitHub releases
install_from_github() {
    local tool="$1"
    local platform="${2:-$(detect_platform)}"
    local os=$(get_os "$platform")
    local arch=$(get_arch "$platform")
    
    case "$tool" in
    bat)
        # Map architecture and OS for bat releases
        local arch_name
        local os_name
        
        if [[ "$arch" == "amd64" ]]; then
            arch_name="x86_64"
        elif [[ "$arch" == "arm64" ]]; then
            arch_name="aarch64"
        else
            arch_name="$arch"
        fi
        
        if [[ "$os" == "darwin" ]]; then
            os_name="apple-darwin"
        else
            os_name="unknown-linux-gnu"
        fi
        
        # Try to get the latest release URL with proper platform detection
        local url=$(get_latest_release_url "sharkdp/bat" "$os_name" "$arch_name")
        
        # If that fails, try a direct download of a known version
        if [[ -z "$url" ]]; then
            if [[ "$os" == "darwin" ]]; then
                if [[ "$arch_name" == "x86_64" ]]; then
                    url="https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-v0.24.0-x86_64-apple-darwin.tar.gz"
                elif [[ "$arch_name" == "aarch64" ]]; then
                    url="https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-v0.24.0-aarch64-apple-darwin.tar.gz"
                fi
            else  # Linux
                if [[ "$arch_name" == "x86_64" ]]; then
                    url="https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-v0.24.0-x86_64-unknown-linux-gnu.tar.gz"
                elif [[ "$arch_name" == "aarch64" ]]; then
                    url="https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-v0.24.0-aarch64-unknown-linux-gnu.tar.gz"
                fi
            fi
        fi
        
        if [[ -n "$url" ]]; then
            install_binary "bat" "$url" "$BIN_DIR/bat" "bat*/bat"
        else
            log_error "Failed to install bat. Please install manually from: https://github.com/sharkdp/bat"
            echo "✗ bat: Failed to find suitable release. Manual installation required from: https://github.com/sharkdp/bat" >> "$LOG_FILE"
        fi
        ;;
    eza)
        # Map architecture to eza terms
        local arch_name
        if [[ "$arch" == "amd64" ]]; then
            arch_name="x86_64"
        elif [[ "$arch" == "arm64" ]]; then
            arch_name="aarch64"
        else
            arch_name="$arch"
        fi
        
        # Try different naming patterns for maximum compatibility
        local patterns=("linux-$arch_name" "$arch_name-unknown-linux-gnu" "$arch_name-linux-gnu")
        local url=""
        
        for pattern in "${patterns[@]}"; do
            url=$(get_latest_release_url "eza-community/eza" "linux" "$pattern")
            if [[ -n "$url" ]]; then
                break
            fi
        done
        
        # If still no URL, try with just the architecture as a fallback
        if [[ -z "$url" ]]; then
            url=$(get_latest_release_url "eza-community/eza" "" "$arch_name")
        fi
        
        # If that fails, just try to get any eza release
        if [[ -z "$url" ]]; then
            url=$(get_latest_release_url "eza-community/eza" "" "")
        fi
        
        if [[ -n "$url" ]]; then
            install_binary "eza" "$url" "$BIN_DIR/eza" "eza"
        else
            log_error "Failed to find a suitable eza release. Trying exa as a fallback."
            url=$(get_latest_release_url "ogham/exa" "linux" "$arch_name")
            if [[ -n "$url" ]]; then
                install_binary "exa" "$url" "$BIN_DIR/exa" "bin/exa"
                # Create eza symlink pointing to exa
                ln -sf "$BIN_DIR/exa" "$BIN_DIR/eza" 
                log_success "Created eza symlink pointing to exa"
                echo "✓ eza: symlinked to exa" >> "$LOG_FILE"
            else
                log_error "Failed to install eza or exa. Please install manually from: https://github.com/eza-community/eza"
                echo "✗ eza: Failed to find suitable release. Manual installation required from: https://github.com/eza-community/eza" >> "$LOG_FILE"
            fi
        fi
        ;;
    yq)
        # Try different naming patterns for yq
        local arch_name
        if [[ "$arch" == "amd64" ]]; then
            arch_name="amd64"
        elif [[ "$arch" == "arm64" ]]; then
            arch_name="arm64"
        else
            arch_name="$arch"
        fi
        
        # Try to get the latest release URL
        local url=$(get_latest_release_url "mikefarah/yq" "linux" "$arch_name")
        
        # If that fails, try a direct download of a known version
        if [[ -z "$url" ]]; then
            if [[ "$arch_name" == "amd64" ]]; then
                url="https://github.com/mikefarah/yq/releases/download/v4.35.1/yq_linux_amd64"
            elif [[ "$arch_name" == "arm64" ]]; then
                url="https://github.com/mikefarah/yq/releases/download/v4.35.1/yq_linux_arm64"
            fi
        fi
        
        if [[ -n "$url" ]]; then
            install_binary "yq" "$url" "$BIN_DIR/yq"
        else
            log_error "Failed to install yq. Please install manually from: https://github.com/mikefarah/yq"
            echo "✗ yq: Failed to find suitable release. Manual installation required from: https://github.com/mikefarah/yq" >> "$LOG_FILE"
        fi
        ;;
    zoxide)
        # Map architecture to zoxide terms and be explicit about platform
        local arch_name
        if [[ "$arch" == "amd64" ]]; then
            arch_name="x86_64"
        elif [[ "$arch" == "arm64" ]]; then
            arch_name="aarch64"
        else
            arch_name="$arch"
        fi
        
        # Be more specific with patterns to avoid selecting Android builds
        local patterns=("$arch_name-unknown-linux-musl" "$arch_name-unknown-linux-gnu")
        local url=""
        
        # First try very specific patterns for this architecture
        for pattern in "${patterns[@]}"; do
            # Use grep to filter out unwanted android builds explicitly
            url=$(curl -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/ajeetdsouza/zoxide/releases/latest" | \
                  jq -r '.assets[].browser_download_url' | \
                  grep -i "$pattern" | grep -v "android" | head -n 1)
            
            if [[ -n "$url" ]]; then
                log_info "Found suitable zoxide release: $url"
                break
            fi
        done
        
        # If still no URL, fall back to manual URL construction for latest known version
        if [[ -z "$url" ]]; then
            log_warning "Could not find suitable zoxide release via API, trying known version..."
            # Use a known working version for x86_64
            if [[ "$arch_name" == "x86_64" ]]; then
                url="https://github.com/ajeetdsouza/zoxide/releases/download/v0.9.2/zoxide-0.9.2-x86_64-unknown-linux-musl.tar.gz"
            fi
        fi
        
        if [[ -n "$url" ]]; then
            install_binary "zoxide" "$url" "$BIN_DIR/zoxide" "zoxide"
        else
            # Final fallback: use cargo to install zoxide if rust is available
            if command -v cargo &>/dev/null; then
                log_info "Installing zoxide using cargo..."
                if cargo install zoxide; then
                    log_success "Installed zoxide via cargo"
                    local version=$(zoxide --version 2>/dev/null)
                    echo "✓ zoxide: $version (via cargo)" >> "$LOG_FILE"
                else
                    log_error "Failed to install zoxide via cargo."
                    echo "✗ zoxide: Failed to install via cargo" >> "$LOG_FILE"
                fi
            else
                log_error "Failed to install zoxide and cargo is not available. Please install manually from: https://github.com/ajeetdsouza/zoxide"
                echo "✗ zoxide: Failed to find suitable release. Manual installation required from: https://github.com/ajeetdsouza/zoxide" >> "$LOG_FILE"
            fi
        fi
        ;;
    jq)
        # Now try direct URLs
        JQ_URL=""
        if [[ "$os" == "linux" ]]; then
            if [[ "$arch" == "amd64" ]]; then
                JQ_URL="https://github.com/jqlang/jq/releases/download/jq-1.7/jq-linux-amd64"
            elif [[ "$arch" == "arm64" ]]; then
                JQ_URL="https://github.com/jqlang/jq/releases/download/jq-1.7/jq-linux-arm64"
            fi
        elif [[ "$os" == "darwin" ]]; then
            if [[ "$arch" == "amd64" ]]; then
                JQ_URL="https://github.com/jqlang/jq/releases/download/jq-1.7/jq-macos-amd64"
            elif [[ "$arch" == "arm64" ]]; then
                JQ_URL="https://github.com/jqlang/jq/releases/download/jq-1.7/jq-macos-arm64"
            fi
        fi
        
        if [[ -n "$JQ_URL" ]]; then
            install_binary "jq" "$JQ_URL" "$BIN_DIR/jq"
        else
            log_error "Failed to install jq. Please install manually from: https://github.com/jqlang/jq"
            echo "✗ jq: Failed to find suitable release. Manual installation required from: https://github.com/jqlang/jq" >> "$LOG_FILE"
        fi
        ;;
    *)
        log_error "Don't know how to install $tool from GitHub."
        echo "✗ $tool: No installation method available. Manual installation required." >> "$LOG_FILE"
        return 1
        ;;
    esac
}

# Install tools based on the installer type
case "$INSTALLER" in
brew)
    # Homebrew packages
    install_tool "eza" "brew" "exa"
    install_tool "bat" "brew"
    install_tool "ripgrep" "brew"
    install_tool "fd" "brew" "fd-find"
    install_tool "jq" "brew"
    install_tool "fzf" "brew"
    install_tool "htop" "brew"
    install_tool "tmux" "brew"
    install_tool "zoxide" "brew"
    install_tool "yq" "brew"
    ;;
apt)
    # Ubuntu/Debian packages
    install_tool "bat" "apt" "batcat"
    install_tool "ripgrep" "apt"
    install_tool "fd-find" "apt" "fd"
    install_tool "jq" "apt"
    install_tool "fzf" "apt"
    install_tool "htop" "apt"
    install_tool "tmux" "apt"
    
    # These tools often need special handling
    log_info "Checking for eza, zoxide, and yq..."
    
    # Check if eza is available in repositories (newer Ubuntu/Debian versions)
    if check_package_installed "eza" || check_package_installed "exa"; then
        log_success "eza or exa is already installed"
    else
        if is_package_available "eza" "apt"; then
            install_via_package_manager "apt" "eza"
        elif is_package_available "exa" "apt"; then
            # Try exa as fallback (older distributions)
            install_via_package_manager "apt" "exa"
            # Create eza symlink pointing to exa if exa was installed successfully
            if command -v exa &>/dev/null; then
                ln -sf "$(which exa)" "$BIN_DIR/eza"
                log_success "Created eza symlink pointing to exa"
                echo "✓ eza: symlinked to exa" >> "$LOG_FILE"
            fi
        else
            # Install eza from GitHub
            log_info "eza not available via apt, installing from GitHub..."
            install_from_github "eza"
        fi
    fi
    
    # Check for zoxide
    if check_package_installed "zoxide"; then
        log_success "zoxide is already installed"
    else
        if is_package_available "zoxide" "apt"; then
            install_via_package_manager "apt" "zoxide"
        else
            # Install zoxide from GitHub
            log_info "zoxide not available via apt, installing from GitHub..."
            install_from_github "zoxide"
        fi
    fi
    
    # Check for yq
    if check_package_installed "yq"; then
        log_success "yq is already installed"
    else
        if is_package_available "yq" "apt"; then
            install_via_package_manager "apt" "yq"
        else
            # Install yq from GitHub
            log_info "yq not available via apt, installing from GitHub..."
            install_from_github "yq"
        fi
    fi
    
    # Create symlinks for fd-find if needed
    if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
        ln -sf "$(which fdfind)" "$BIN_DIR/fd"
        log_success "Created fd symlink for fd-find"
        echo "✓ fd: symlinked to fdfind" >> "$LOG_FILE"
    fi
    ;;
*)
    # Unsupported package manager
    log_error "Unsupported package manager: $INSTALLER"
    log_error "This script is optimized for Ubuntu (apt) and macOS (brew) package managers."
    log_error "Please install packages manually for your system."
    
    echo "✗ ERROR: Unsupported package manager: $INSTALLER" >> "$LOG_FILE"
    echo "This script is optimized for Ubuntu (apt) and macOS (brew) package managers." >> "$LOG_FILE"
    ;;
esac

# Check if all required tools are now available
echo "" >> "$LOG_FILE"
echo "# Final installation status" >> "$LOG_FILE"

# List of all tools to check
ALL_TOOLS=("bat" "eza" "exa" "ripgrep" "rg" "fd" "fd-find" "fdfind" "jq" "fzf" "htop" "tmux" "zoxide" "yq")
MISSING_TOOLS=()

for tool in "${ALL_TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then
    log_warning "Some tools are still not available in PATH:"
    for tool in "${MISSING_TOOLS[@]}"; do
        echo "  - $tool"
    done
    log_info "You may need to restart your shell or add $BIN_DIR to your PATH"
    
    echo "WARNING: Some tools are not available in PATH: ${MISSING_TOOLS[*]}" >> "$LOG_FILE"
    echo "You may need to restart your shell or add $BIN_DIR to your PATH" >> "$LOG_FILE"
else
    log_success "All tools are available in PATH"
    echo "SUCCESS: All tools are available in PATH" >> "$LOG_FILE"
fi

# Add tool aliases to zshrc if not already present
if ! grep -q "# === bioinf-cli-env tool aliases ===" "$HOME/.zshrc"; then
    log_info "Adding tool aliases to .zshrc..."

    cat >>"$HOME/.zshrc" <<'ENDALIASES'

# === bioinf-cli-env tool aliases ===
# Modern CLI tool aliases

# Replace ls with eza/exa if available
if command -v eza &>/dev/null; then
  alias ls="eza --group-directories-first"
  alias ll="eza -l --group-directories-first --time-style=long-iso"
  alias la="eza -la --group-directories-first --time-style=long-iso"
  alias lt="eza -T --level=2 --group-directories-first"
  alias llt="eza -lT --level=2 --group-directories-first"
elif command -v exa &>/dev/null; then
  alias ls="exa --group-directories-first"
  alias ll="exa -l --group-directories-first --time-style=long-iso"
  alias la="exa -la --group-directories-first --time-style=long-iso"
  alias lt="exa -T --level=2 --group-directories-first"
  alias llt="exa -lT --level=2 --group-directories-first"
fi

# Replace cat with bat if available
if command -v bat &>/dev/null; then
  alias cat="bat --plain --wrap=character"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
elif command -v batcat &>/dev/null; then
  # On some Debian/Ubuntu systems, bat is installed as batcat
  alias cat="batcat --plain --wrap=character"
  alias bat="batcat"
  export MANPAGER="sh -c 'col -bx | batcat -l man -p'"
fi

# Add ripgrep and fd aliases
if command -v rg &>/dev/null; then
  alias grep="rg"
  alias rgi="rg -i"  # Case insensitive search
fi

if command -v fd &>/dev/null; then
  alias find="fd"
fi

# Initialize zoxide if available
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
  alias cd="z"
fi

# Initialize fzf if available
if [ -f ~/.fzf.zsh ]; then
  source ~/.fzf.zsh
fi

# Other useful aliases
alias h="history"
alias path='echo $PATH | tr ":" "\n"'
alias now='date +"%T"'
alias clr='clear'
# === End bioinf-cli-env tool aliases ===
ENDALIASES

    log_success "Tool aliases added to .zshrc"
    echo "Tool aliases added to .zshrc" >> "$LOG_FILE"
else
    log_success "Tool aliases already exist in .zshrc"
    echo "Tool aliases already exist in .zshrc" >> "$LOG_FILE"
fi

log_success "Modern CLI tools installation complete!"
echo "" >> "$LOG_FILE"
echo "# Installation completed at $(date)" >> "$LOG_FILE"
echo "Log file saved to: $LOG_FILE"
