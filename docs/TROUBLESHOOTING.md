# Troubleshooting Guide

This guide provides solutions to common issues you might encounter when using the bioinformatics CLI environment.

## Zsh Configuration Issues

### Problem: Oh My Zsh plugins not loading

**Symptoms:** Missing syntax highlighting, autosuggestions, or other plugin features.

**Solution:**

1. Ensure the plugins are installed:
   ```bash
   ls ~/.oh-my-zsh/custom/plugins/
   ```
2. Check your plugin list in `~/.zshrc`
3. Reinstall missing plugins:
   ```bash
   git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
   git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
   ```

### Problem: Powerlevel10k theme not displaying correctly

**Symptoms:** Missing icons, broken prompt layout.

**Solution:**

1. Ensure you have installed Nerd Fonts:

   ```bash
   # On macOS
   brew tap homebrew/cask-fonts
   brew install --cask font-meslo-lg-nerd-font

   # On Linux
   # Download and install from https://github.com/ryanoasis/nerd-fonts/releases
   ```

2. Configure your terminal to use the Nerd Font
3. Run `p10k configure` to reconfigure the theme

## Micromamba Issues

### Problem: micromamba environment not activating

**Symptoms:** `micromamba activate bioinf` fails or doesn't change the environment.

**Solution:**

1. Check if the environment exists:
   ```bash
   micromamba env list
   ```
2. If missing, create it:
   ```bash
   micromamba env create -f config/micromamba-config.yaml
   ```
3. Ensure the hook is properly set up in `~/.zshrc`:
   ```bash
   eval "$(micromamba shell hook -s zsh)"
   ```

### Problem: Package conflicts in micromamba environment

**Solution:**

1. Update all packages:
   ```bash
   micromamba update -n bioinf --all
   ```
2. Or recreate the environment:
   ```bash
   micromamba env remove -n bioinf
   micromamba env create -f config/micromamba-config.yaml
   ```

## SLURM Job Monitoring Issues

### Problem: `sj` command not found

**Solution:**

1. Ensure the setup_monitoring.sh script has run:
   ```bash
   ./scripts/setup_monitoring.sh
   ```
2. Source your zshrc:
   ```bash
   source ~/.zshrc
   ```

### Problem: Error when using sj with a job ID

**Solution:**
Check that you have the appropriate SLURM permissions and that the job exists.

## Azure OpenAI Integration Issues

### Problem: "Azure CLI not found" error

**Solution:**
Install the Azure CLI:

```bash
# macOS
brew install azure-cli

# Ubuntu/Debian
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### Problem: Authentication errors with Azure

**Solution:**

1. Log in to Azure:
   ```bash
   az login
   ```
2. Set your subscription:
   ```bash
   az account set --subscription "<subscription-id>"
   ```
3. Reconfigure your LLM setup:
   ```bash
   llm-setup
   ```

## Synchronization Issues

### Problem: sync.sh fails with "Host not found"

**Solution:**

1. Check your SSH configuration:
   ```bash
   cat ~/.ssh/config
   ```
2. Ensure host definitions exist for your targets
3. Test SSH connectivity:
   ```bash
   ssh -T <hostname>
   ```

### Problem: Files not updating after sync

**Solution:**
After syncing, source the zshrc on the remote system:

```bash
source ~/.zshrc
```

## General Performance Issues

### Problem: Slow shell startup

**Solution:**

1. Identify slow plugins by temporarily disabling them
2. Consider using Zinit instead of Oh My Zsh for faster loading
3. Use profiling to identify bottlenecks:
   ```bash
   zsh -xv
   ```

## Getting More Help

If you encounter an issue not covered here, please:

1. Check the repository issues: https://github.com/yourusername/bioinf-cli-env/issues
2. Open a new issue with details about your problem
3. Share your terminal output and environment details when asking for help
