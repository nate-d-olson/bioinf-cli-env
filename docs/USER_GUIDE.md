# Bioinformatics CLI Environment User Guide

This guide provides instructions on using the bioinformatics command-line environment tools and configurations.

## Overview

This environment includes:

- Zsh configuration with Oh My Zsh and Powerlevel10k
- Micromamba for bioinformatics package management
- SLURM job monitoring tools
- Azure OpenAI CLI integration for easy LLM access
- Git, AWS, and Docker integrations
- Cross-system synchronization

## Getting Started

### Installation

Run the install script to set up the environment:

```bash
./install.sh
```

This will:

1. Install Oh My Zsh and Powerlevel10k if not already installed
2. Configure zsh with essential plugins
3. Set up the Bioinformatics micromamba environment
4. Configure tool integrations
5. Set up job monitoring

### Configuration Overview

Key configuration files:

- `~/.zshrc` - Main shell configuration
- `~/.p10k.zsh` - Powerlevel10k theme configuration
- `~/.nanorc` - Nano editor configuration
- `~/.tmux.conf` - Tmux configuration

### Tool Usage

#### Micromamba Environment

Activate/deactivate the bioinformatics environment:

```bash
micromamba activate bioinf
micromamba deactivate
```

#### SLURM Job Management

Monitor your SLURM jobs:

```bash
sj            # View your running jobs
sj -a         # View all jobs
sj -m         # View all your jobs
sj <job_id>   # View specific job with details
```

Create a job template:

```bash
create_job myjob 4 16 24  # Name, cores, memory(GB), time(hours)
```

#### Azure OpenAI Integration

To configure and use Azure OpenAI:

```bash
llm-setup     # Configure your Azure OpenAI deployment
llm "What is the BLAST algorithm?"  # Ask the LLM a question
```

#### Cross-System Synchronization

Sync your configuration to other systems:

```bash
./sync.sh workstation1 cluster-login  # Sync to specific hosts
./sync.sh --all                       # Sync to all configured hosts
```

## Customization

For customization options, see [CUSTOMIZATION.md](CUSTOMIZATION.md).

## Troubleshooting

For common issues and their solutions, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
