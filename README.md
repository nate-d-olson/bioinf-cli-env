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
- **Workflow monitoring**: Dedicated monitors for Snakemake, Nextflow, and WDL workflows
- **Color schemes**: Dark theme color palettes optimized for bioinformatics work
- **Cross-system sync**: Easily keep your configuration in sync across multiple systems

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
│   ├── setup_job_management.sh # SLURM job helper tools
│   ├── select_palette.sh    # Terminal color scheme selector
│   ├── workflow_monitors/   # Workflow monitoring tools
│   │   ├── snakemake_monitor.sh  # Snakemake workflow monitoring
│   │   ├── nextflow_monitor.sh   # Nextflow workflow monitoring
│   │   └── wdl_monitor.sh        # WDL/Cromwell workflow monitoring
│   └── utils/               # Helper functions and utilities
└── docs/                    # Documentation and guides
    ├── USER_GUIDE.md        # Main user documentation
    ├── CUSTOMIZATION.md     # How to customize the environment
    ├── TROUBLESHOOTING.md   # Common issues and solutions
    └── JOB_MONITORING.md    # Detailed job monitoring guide
```

## Key Components

### Shell Environment

- **Oh My Zsh**: Framework for managing Zsh configuration
- **Powerlevel10k**: Fast, customizable Zsh theme with Git status, Conda env indicators
- **zsh-autosuggestions**: Shows command suggestions as you type
- **zsh-syntax-highlighting**: Syntax highlighting for the shell
- **fzf**: Fuzzy finder for history, files, and more
- **zoxide**: Smart directory jumper that learns from your usage

### SLURM Job Management

Enhanced tools for working with SLURM including:

- `sj`: Advanced job status viewer with progress indicators and resource usage
- `create_job`: Interactive job script generator with templates
- `srun1` and `srun8`: Quick interactive job starters with preset resources
- `sbatch-notify`: Submit jobs with completion notifications
- `monitor_in_tmux`: Monitor jobs in dedicated tmux sessions

### Workflow Monitoring

Dedicated monitoring tools that provide:

- Real-time progress tracking
- Resource usage statistics
- Estimated completion times
- Visual indicators of progress and status

Available for:
- **Snakemake** workflows (`snakemake_monitor.sh`)
- **Nextflow** workflows (`nextflow_monitor.sh`)
- **WDL/Cromwell** workflows (`wdl_monitor.sh`)

### Azure OpenAI Integration

Query AI models directly from your terminal:

```bash
llm "What is the BLAST algorithm?"
```

### Cross-System Synchronization

Keep your environment consistent across multiple machines:

```bash
# Add a new host
./sync.sh add-host workstation user@workstation.example.com

# Push configuration to a host
./sync.sh push workstation

# Pull configuration from a host
./sync.sh pull workstation

# Push to all configured hosts
./sync.sh --all
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

# Test job management (if on a SLURM cluster)
sj  # Should show your jobs with progress bars
create_job test  # Should create a job script template
```

## Documentation

For more detailed information, see the documentation in the `docs/` directory:

- [User Guide](docs/USER_GUIDE.md): Getting started and basic usage
- [Customization Guide](docs/CUSTOMIZATION.md): How to customize your environment
- [Troubleshooting](docs/TROUBLESHOOTING.md): Common issues and solutions
- [Job Monitoring Guide](docs/JOB_MONITORING.md): Detailed guide to job monitoring tools

## License

MIT
