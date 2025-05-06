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

# # Install Azure CLI OpenAI extension if needed
# if ! az extension show --name openai &>/dev/null; then
#     log_info "Installing Azure CLI OpenAI extension..."
#     az extension add --name openai
# fi

# Create the Azure OpenAI functions in .zsh_azure_llm
cat >"$ZSH_LLM_FILE" <<'ENDZSH'
# Azure OpenAI CLI integration for terminal

# Configuration file
AZURE_LLM_CONFIG="${HOME}/.config/bioinf-cli-env/llm.conf"

# Load configuration if exists
if [[ -f "$AZURE_LLM_CONFIG" ]]; then
    source "$AZURE_LLM_CONFIG"
fi

# Update the `llm` function to include additional parameters for robust API calls.
function llm() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: llm \"your question\""
        return 1
    fi

    # Check if configuration exists
    if [[ -z "${AZURE_OPENAI_DEPLOYMENT:-}" || -z "${AZURE_OPENAI_ENDPOINT:-}" || -z "${AZURE_OPENAI_KEY:-}" ]]; then
        echo "⚠️ Azure OpenAI not configured. Run 'llm-setup' first."
        return 1
    fi

    local prompt="$*"
    local result
    result=$(curl -X POST "${AZURE_OPENAI_ENDPOINT}/openai/deployments/${AZURE_OPENAI_DEPLOYMENT}/chat/completions?api-version=2025-01-01-preview" \
        -H "Content-Type: application/json" \
        -H "api-key: ${AZURE_OPENAI_KEY}" \
        -d '{
            "messages": [{"role": "user", "content": "'$prompt'"}],
            "max_tokens": 952,
            "temperature": 0.7,
            "top_p": 0.95,
            "frequency_penalty": 0,
            "presence_penalty": 0
        }' 2>/dev/null | jq -r '.choices[0].message.content')

    if [[ $? -eq 0 && -n "$result" ]]; then
        echo "$result"
    else
        echo "❌ Error communicating with Azure OpenAI. Please check your configuration."
        return 1
    fi
}

# Update the `llm-setup` function to include deployment-specific endpoint configuration.
function llm-setup() {
    echo "🔧 Configuring Azure OpenAI REST API integration"

    # Prompt for deployment name
    echo -n "Enter your Azure OpenAI deployment name: "
    read deployment
    if [[ -z "$deployment" ]]; then
        echo "❌ Deployment name cannot be empty. Aborting setup."
        return 1
    fi

    # Prompt for endpoint
    echo -n "Enter your Azure OpenAI endpoint (e.g., https://<resource>.openai.azure.com): "
    read endpoint
    if [[ -z "$endpoint" ]]; then
        echo "❌ Endpoint cannot be empty. Aborting setup."
        return 1
    fi

    # Prompt for API key
    echo -n "Enter your Azure OpenAI API key: "
    read api_key
    if [[ -z "$api_key" ]]; then
        echo "❌ API key cannot be empty. Aborting setup."
        return 1
    fi

    # Save configuration
    cat > "$AZURE_LLM_CONFIG" << EOF
# Azure OpenAI Configuration
export AZURE_OPENAI_DEPLOYMENT="$deployment"
export AZURE_OPENAI_ENDPOINT="$endpoint"
export AZURE_OPENAI_KEY="$api_key"
EOF

    # Set permissions
    chmod 600 "$AZURE_LLM_CONFIG"

    # Verify configuration
    if [[ -f "$AZURE_LLM_CONFIG" ]]; then
        source "$AZURE_LLM_CONFIG"
        echo "✅ Configuration saved."
        echo "You can now use 'llm \"your question\"' to chat with the model."
    else
        echo "❌ Failed to save configuration. Please try again."
        return 1
    fi
}

# Update the `llm-config` function to display the new configuration format.
function llm-config() {
    if [[ ! -f "$AZURE_LLM_CONFIG" ]]; then
        echo "⚠️ No configuration found. Run 'llm-setup' first."
        return 1
    fi

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
