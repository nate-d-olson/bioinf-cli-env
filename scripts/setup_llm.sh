#!/usr/bin/env bash
# Azure OpenAI CLI integration setup
set -euo pipefail

CONFIG_DIR="$HOME/.config/bioinf-cli-env"
ZSH_LLM_FILE="$HOME/.zsh_azure_llm"
mkdir -p "$CONFIG_DIR"

echo "🤖 Setting up Azure OpenAI CLI integration..."

# Create the script for Azure OpenAI CLI tool
cat > "$CONFIG_DIR/cli_assistant.py" << 'ENDPY'
#!/usr/bin/env python3
"""
CLI Assistant - Azure OpenAI integration for bioinformatics command line
"""
import os
import sys
import json
import argparse
import requests
from getpass import getpass

CONFIG_FILE = os.path.expanduser("~/.config/bioinf-cli-env/azure_openai_config.json")

def save_config(api_key, endpoint, deployment_id):
    """Save Azure OpenAI configuration"""
    config = {
        "api_key": api_key,
        "endpoint": endpoint,
        "deployment_id": deployment_id
    }
    os.makedirs(os.path.dirname(CONFIG_FILE), exist_ok=True)
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f)
    # Secure the file
    os.chmod(CONFIG_FILE, 0o600)
    print(f"Configuration saved to {CONFIG_FILE}")

def load_config():
    """Load Azure OpenAI configuration"""
    if not os.path.exists(CONFIG_FILE):
        print("Configuration not found. Run with --setup to configure.")
        sys.exit(1)
    with open(CONFIG_FILE, "r") as f:
        return json.load(f)

def setup_config():
    """Setup Azure OpenAI configuration"""
    print("Azure OpenAI Configuration Setup")
    print("--------------------------------")
    print("You'll need your Azure OpenAI API key, endpoint, and deployment ID.")
    print("Find these in the Azure Portal under your Azure OpenAI resource.")
    
    api_key = getpass("Azure OpenAI API Key: ")
    endpoint = input("Azure OpenAI Endpoint (https://xxx.openai.azure.com): ")
    deployment_id = input("Model Deployment ID: ")
    
    save_config(api_key, endpoint, deployment_id)
    print("Configuration complete!")

def query_azure_openai(prompt, config):
    """Send query to Azure OpenAI API"""
    url = f"{config['endpoint']}/openai/deployments/{config['deployment_id']}/chat/completions?api-version=2023-05-15"
    headers = {
        "Content-Type": "application/json",
        "api-key": config["api_key"]
    }
    data = {
        "messages": [
            {"role": "system", "content": "You are a helpful bioinformatics assistant. Provide concise command-line solutions for bioinformatics tasks."},
            {"role": "user", "content": prompt}
        ],
        "max_tokens": 1000
    }
    
    try:
        response = requests.post(url, headers=headers, json=data, timeout=30)
        response.raise_for_status()
        result = response.json()
        return result["choices"][0]["message"]["content"]
    except Exception as e:
        return f"Error: {str(e)}"

def main():
    parser = argparse.ArgumentParser(description="CLI Assistant - Azure OpenAI integration")
    parser.add_argument("--setup", action="store_true", help="Setup configuration")
    parser.add_argument("prompt", nargs="*", help="Query for the assistant")
    
    args = parser.parse_args()
    
    if args.setup:
        setup_config()
        sys.exit(0)
    
    if not args.prompt:
        print("Please provide a query. Example: cli-assistant 'how to filter a VCF file'")
        sys.exit(1)
    
    prompt = " ".join(args.prompt)
    config = load_config()
    
    print(f"\n🤖 Querying Azure OpenAI: \"{prompt}\"\n")
    print("⏳ Thinking...\n")
    
    response = query_azure_openai(prompt, config)
    print(response)

if __name__ == "__main__":
    main()
ENDPY

# Make the CLI assistant executable
chmod +x "$CONFIG_DIR/cli_assistant.py"

# Create symbolic link in bin directory
ln -sf "$CONFIG_DIR/cli_assistant.py" "$HOME/.local/bin/cli-assistant"

# Create the zsh integration file
cat > "$ZSH_LLM_FILE" << 'ENDZSH'
# Azure OpenAI CLI integration for Zsh

# Check if the CLI assistant is installed
if [[ -f "$HOME/.local/bin/cli-assistant" ]]; then
  # Define the function for quick asking
  ask() {
    cli-assistant "$@"
  }
  
  # Define the function to explain the last command
  explain() {
    local last_command=$(fc -ln -1)
    echo "🔍 Explaining: $last_command"
    cli-assistant "Explain what this command does: '$last_command'"
  }
  
  # Define the function to suggest a command
  suggest() {
    cli-assistant "Suggest a command-line solution for: $*"
  }
  
  # Notify that the Azure OpenAI integration is active
  echo "🤖 Azure OpenAI CLI integration is active. Use 'ask', 'explain', or 'suggest' commands."
  echo "    Run 'cli-assistant --setup' to configure your Azure OpenAI credentials."
fi
ENDZSH

echo "✅ Azure OpenAI CLI integration setup complete!"
echo "📝 To configure your Azure OpenAI credentials, run: cli-assistant --setup"
echo "📚 Commands available:"
echo "   - ask: Ask any question directly"
echo "   - explain: Explain the last command"
echo "   - suggest: Get a command suggestion for a task"
