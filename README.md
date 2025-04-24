# Bioinformatics CLI Environment

A cross-platform synchronized productivity-focused CLI setup for bioinformaticians.

## Overview

This project provides a standardized, cross-platform command line environment optimized for bioinformatics workflows that balances power, usability, and reproducibility. The setup is easily deployable across diverse systems while maintaining consistency, enhancing productivity, and providing robust monitoring capabilities for long-running computational jobs.

## Features

- **Cross-platform compatibility**: Works on macOS, Ubuntu Linux, and SLURM-based clusters
- **Enhanced ZSH**: Using Oh My Zsh and Powerlevel10k for a beautiful, informative prompt
- **Productivity tools**: Autosuggestions, syntax highlighting, fuzzy search, and directory jumping
- **Tool integrations**: AWS, Git, Docker, and Micromamba with tab completion
- **Modern CLI tools**: Replacements for common utilities (ls, cat, find, etc.)
- **Job monitoring**: Enhanced Slurm and workflow monitoring tools
- **Azure OpenAI integration**: Command-line tool for LLM queries

## Installation

```bash
git clone https://github.com/yourusername/bioinf-cli-env.git
cd bioinf-cli-env
./install.sh
```

The interactive installer will guide you through the process and allow you to customize your installation.

## Directory Structure

```
bioinf-cli-env/
├── README.md
├── install.sh               # Main installation script
├── uninstall.sh             # Safe removal script
├── sync.sh                  # Cross-system synchronization
├── config/
│   ├── zshrc                # Core zsh configuration
│   ├── p10k.zsh             # Powerlevel10k theme config
│   ├── tmux.conf            # Terminal multiplexer config
│   ├── nanorc               # Nano editor enhancements
│   ├── micromamba-config.yaml  # Bioinformatics environment
│   └── job-monitoring/      # SLURM and workflow monitoring tools
├── scripts/
│   ├── setup_tools.sh       # Core utility installation
│   ├── setup_omz.sh         # Oh My Zsh configuration
│   ├── setup_llm.sh         # Azure OpenAI integration
│   ├── setup_monitoring.sh  # Job monitoring setup
│   ├── select_palette.sh    # Terminal color scheme selector
│   └── utils/               # Helper functions and utilities
└── docs/                    # Documentation and guides
```

## Validation

Test your installation with:

```bash
# Test zsh plugins
echo "Test syntax highlighting"  # Should be colored

# Test modern tools
ll  # Should use eza/exa
cat ~/.zshrc  # Should use bat with syntax highlighting

# Test micromamba
micromamba env list  # Should show bioinf environment

# Test completions
git <TAB>  # Should show git commands
aws <TAB>  # Should show AWS CLI commands
```

## License

MIT
