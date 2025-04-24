#!/usr/bin/env bash
# Azure OpenAI CLI integration setup
set -euo pipefail
IFS=$'\n\t'
trap 'echo "Azure OpenAI CLI setup failed." >&2; exit 1' ERR

CONFIG_DIR="$HOME/.config/bioinf-cli-env"
ZSH_LLM_FILE="$HOME/.zsh_azure_llm"
mkdir -p "$CONFIG_DIR"

echo "🤖 Setting up Azure OpenAI CLI integration..."

# Check if az CLI is installed
if ! command -v az &>/dev/null; then
  echo "⚠️ Azure CLI (az) not found. Installing..."
  
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS installation
    if command -v brew &>/dev/null; then
      brew install azure-cli
    else
      echo "⚠️ Homebrew not found. Please install Azure CLI manually."
      echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-macos"
    fi
  else
    # Linux installation
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash
  fi
fi

# Install Azure CLI ml extension if needed
if ! az extension show --name ml &>/dev/null; then
  echo "📥 Installing Azure CLI ml extension..."
  az extension add --name ml
fi

# Create the Azure OpenAI function in .zsh_azure_llm
cat > "$ZSH_LLM_FILE" << 'ENDZSH'
# Azure OpenAI CLI integration for terminal

# Simple function to interact with Azure OpenAI
function llm() {
  local prompt="${*:-\"Hello, world!\"}"
  az openai chat-completion create --deployment my-deployment \
    --messages "[{\"role\":\"user\",\"content\":\"$prompt\"}]" \
    --query "choices[0].message.content" -o tsv
}

# Setup function to configure Azure OpenAI
function llm-setup() {
  echo "🔧 Configuring Azure OpenAI CLI integration"
  
  read -p "Enter your Azure OpenAI deployment name: " deployment
  az config set defaults.openai.deployment="$deployment"
  
  echo "✅ Configuration saved. Use 'llm \"your question\"' to chat with the model."
}

# Notify that the Azure OpenAI integration is active
echo "🤖 Azure OpenAI CLI integration is active."
echo "Run 'llm-setup' to configure your deployment."
echo "Then use 'llm \"your question\"' to ask questions."
ENDZSH

echo "✅ Azure OpenAI CLI integration setup complete!"
echo "To configure your deployment, run: llm-setup"
echo "To use the LLM, simply type: llm \"Your question here\""
