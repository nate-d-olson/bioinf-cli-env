#!/usr/bin/env bash
# Azure OpenAI CLI integration setup
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/common.sh"

CONFIG_DIR="${HOME}/.config/bioinf-cli-env"
ZSH_LLM_FILE="$HOME/.zsh_azure_llm"
mkdir -p "$CONFIG_DIR"

log_info "Setting up Azure OpenAI CLI integration..."

# Check if az CLI is installed
if ! cmd_exists az; then
    log_info "Azure CLI (az) not found. Installing..."

    case "$(detect_platform)" in
    macos-*)
        if cmd_exists brew; then
            brew install azure-cli
        else
            log_warning "Homebrew not found. Please install Azure CLI manually:"
            log_info "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-macos"
            exit 1
        fi
        ;;
    *-*)
        curl -sL https://aka.ms/InstallAzureCLIDeb | bash
        ;;
    esac
fi

# Install Azure CLI ml extension if needed
if ! az extension show --name ml &>/dev/null; then
    log_info "Installing Azure CLI ml extension..."
    az extension add --name ml
fi

# Create the Azure OpenAI functions in .zsh_azure_llm
cat >"$ZSH_LLM_FILE" <<'ENDZSH'
# Azure OpenAI CLI integration for terminal

# Configuration file
AZURE_LLM_CONFIG="${HOME}/.config/bioinf-cli-env/llm.conf"

# Load configuration if exists
if [[ -f "$AZURE_LLM_CONFIG" ]]; then
    source "$AZURE_LLM_CONFIG"
fi

# Simple function to interact with Azure OpenAI
function llm() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: llm \"your question\""
        return 1
    fi

    # Check if configuration exists
    if [[ -z "${AZURE_OPENAI_DEPLOYMENT:-}" ]]; then
        echo "⚠️ Azure OpenAI not configured. Run 'llm-setup' first."
        return 1
    fi

    local prompt="$*"
    local result
    result=$(az openai chat-completion create \
        --deployment "$AZURE_OPENAI_DEPLOYMENT" \
        --messages "[{\"role\":\"user\",\"content\":\"$prompt\"}]" \
        --query "choices[0].message.content" -o tsv 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        echo "$result"
    else
        echo "❌ Error communicating with Azure OpenAI. Please check your configuration."
        return 1
    fi
}

# Setup function to configure Azure OpenAI
function llm-setup() {
    echo "🔧 Configuring Azure OpenAI CLI integration"
    
    read -p "Enter your Azure OpenAI deployment name: " deployment
    read -p "Enter your Azure OpenAI endpoint (optional): " endpoint
    read -p "Enter your Azure OpenAI API key (optional): " api_key
    
    # Save configuration
    cat > "$AZURE_LLM_CONFIG" << EOF
# Azure OpenAI Configuration
export AZURE_OPENAI_DEPLOYMENT="$deployment"
EOF

    if [[ -n "$endpoint" ]]; then
        echo "export AZURE_OPENAI_ENDPOINT=\"$endpoint\"" >> "$AZURE_LLM_CONFIG"
    fi
    
    if [[ -n "$api_key" ]]; then
        echo "export AZURE_OPENAI_KEY=\"$api_key\"" >> "$AZURE_LLM_CONFIG"
    fi
    
    # Set permissions
    chmod 600 "$AZURE_LLM_CONFIG"
    
    # Load the new configuration
    source "$AZURE_LLM_CONFIG"
    
    echo "✅ Configuration saved."
    echo "You can now use 'llm \"your question\"' to chat with the model."
}

# Function to update configuration
function llm-config() {
    if [[ ! -f "$AZURE_LLM_CONFIG" ]]; then
        echo "⚠️ No configuration found. Run 'llm-setup' first."
        return 1
    }
    
    echo "Current configuration:"
    echo "Deployment: ${AZURE_OPENAI_DEPLOYMENT:-not set}"
    echo "Endpoint: ${AZURE_OPENAI_ENDPOINT:-not set}"
    echo "API Key: ${AZURE_OPENAI_KEY:+set (hidden)}"
    
    echo
    echo "Run 'llm-setup' to update configuration."
}

# Notify that the Azure OpenAI integration is active
echo "🤖 Azure OpenAI CLI integration is active."
echo "Run 'llm-setup' to configure your deployment."
echo "Then use 'llm \"your question\"' to ask questions."
echo "Use 'llm-config' to view current configuration."
ENDZSH

# Add source command to .zshrc if not already present
if ! grep -q "source.*\.zsh_azure_llm" "$HOME/.zshrc"; then
    echo -e "\n# Azure OpenAI CLI integration\nsource \$HOME/.zsh_azure_llm" >>"$HOME/.zshrc"
fi

log_success "Azure OpenAI CLI integration setup complete!"
log_info "To configure your deployment, run: llm-setup"
log_info "To use the LLM, simply type: llm \"Your question here\""
