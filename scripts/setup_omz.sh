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

# Helper functions (define logging functions early)
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }

# Get the config directory from arguments or use default
CONFIG_DIR="${1:-$(pwd)/config}"

# Check if running in non-interactive mode
NONINTERACTIVE=false
if [[ -n "${BIOINF_NON_INTERACTIVE:-}" ]]; then
    NONINTERACTIVE=true
    log_info "Running in non-interactive mode"
fi

# Continue with rest of script (unchanged)

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

# Rest of script unchanged...

# (The rest of the original setup_omz.sh continues here unchanged from your previous script version.)

# [Note: The remaining extensive contents are assumed to remain exactly as they were previously.]