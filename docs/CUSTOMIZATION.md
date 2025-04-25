# Customizing Your Bioinformatics CLI Environment

This guide explains how to customize your bioinformatics CLI environment to suit your specific needs.

## Customizing the Shell Appearance

### Powerlevel10k Theme

To reconfigure your Powerlevel10k theme:

```bash
p10k configure
```

This will start an interactive wizard to customize your prompt.

### Color Schemes

Change your terminal color scheme:

```bash
./scripts/select_palette.sh
```

This script provides several optimized dark color schemes for bioinformatics work.

## Adding/Removing Plugins

Edit `~/.zshrc` to add or remove plugins. The default plugins include:

```bash
plugins=(
  git
  aws
  docker
  zsh-syntax-highlighting
  zsh-autosuggestions
  zoxide
  fzf
)
```

To add a new plugin, simply add its name to this list and run:

```bash
source ~/.zshrc
```

## Customizing Tool Integrations

### AWS CLI

To customize AWS CLI auto-prompt behavior, modify in `~/.zshrc`:

```bash
# Options: on-partial, on, off
export AWS_CLI_AUTO_PROMPT=on-partial
```

### Micromamba

To modify the micromamba environment, edit `/config/micromamba-config.yaml` and run:

```bash
micromamba env update -f config/micromamba-config.yaml
```

### Azure OpenAI Integration

If you need to change your Azure OpenAI deployment:

```bash
llm-setup
```

## Customizing SLURM Job Templates

Edit `scripts/setup_monitoring.sh` to modify the job template function.

## Platform-Specific Customizations

For machine-specific configurations, edit:

- `~/.zsh_platform` - Platform-specific settings
- `~/.zsh_work` - Work-specific settings
- `~/.zsh_azure_llm` - LLM-specific settings

## Advanced Customizations

### Adding Custom Functions

To add your own functions, create a file (e.g., `~/.zsh_custom`) and source it in your `~/.zshrc`:

```bash
# Add to the end of your .zshrc
if [ -f ~/.zsh_custom ]; then
  source ~/.zsh_custom
fi
```

### Nano Editor Configuration

Customize your nano editor by editing `~/.nanorc`. Some useful settings:

```
set autoindent
set tabsize 4
set linenumbers
set constantshow
```

### Tmux Configuration

Customize tmux by editing `~/.tmux.conf`. Some popular customizations:

```
# Change prefix key
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Enable mouse mode
set -g mouse on

# Improve colors
set -g default-terminal "screen-256color"
```

## Synchronizing Custom Configurations

After making customizations, sync them to your other systems:

```bash
./sync.sh --all
```

This will ensure consistent experience across all your machines.
