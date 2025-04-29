# Customization Guide

This guide explains how to customize your bioinformatics CLI environment for your
specific needs.

## Shell Configuration

### Custom Aliases and Functions

Add your custom aliases and functions to `~/.zsh_work`:

```zsh
# Example aliases
alias blast='blastn -db nt -remote'
alias muscle='muscle -in input.fa -out output.aln'

# Example function
fasta_stats() {
    grep -v '^>' "$1" | tr -d '\n' | wc -c
}
```

### Powerlevel10k Theme

Customize your prompt by running:

```bash
p10k configure
```

Or edit `~/.p10k.zsh` directly.

### Adding Plugins

1. Find the plugin on GitHub
2. Clone to oh-my-zsh custom plugins directory
3. Add to plugins list in `.zshrc`

```bash
git clone https://github.com/author/zsh-plugin.git \
    ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-plugin
```

Then add to plugins in `.zshrc`:

```zsh
plugins=(
    # ...existing plugins...
    zsh-plugin
)
```

## Micromamba Environment

### Adding Packages

Edit `config/micromamba-config.yaml`:

```yaml
name: bioinf
channels:
  - conda-forge
  - bioconda
dependencies:
  # ...existing packages...
  - new-package=1.2.3
```

### Creating Additional Environments

Create new environment files in `config/`:

```yaml
name: rnaseq
channels:
  - conda-forge
  - bioconda
dependencies:
  - star=2.7.10b
  - salmon=1.10.1
  - fastqc=0.11.9
```

## Job Monitoring

### Custom Resource Limits

Edit `~/.config/bioinf-cli-env/monitoring/monitor.conf`:

```bash
# Monitoring configuration
UPDATE_INTERVAL=10         # Update frequency in seconds
LOG_RETENTION_DAYS=7      # How long to keep job logs
MEMORY_WARN_THRESHOLD=90  # Memory usage warning level (%)
CPU_WARN_THRESHOLD=95     # CPU usage warning level (%)
```

### Job Templates

Create custom templates in `~/.local/share/bioinf-cli-env/job_templates/`:

```bash
#!/bin/bash
#SBATCH --job-name=rnaseq_pipe
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --mem=32G
#SBATCH --time=24:00:00

# Load modules
module load star/2.7.10b

# Your commands here
```

## Color Schemes

### Adding Custom Palettes

Add new palettes to `~/.config/bioinf-cli-env/palettes.conf`:

```toml
[custom_palette]
background = "#282c34"
foreground = "#abb2bf"
selection = "#3e4451"
comment = "#5c6370"
red = "#e06c75"
orange = "#d19a66"
yellow = "#e5c07b"
green = "#98c379"
cyan = "#56b6c2"
blue = "#61afef"
purple = "#c678dd"
```

## Cross-System Sync

### Host Configuration

Edit `~/.config/bioinf-cli-env/sync_hosts`:

```text
cluster1 user@cluster1.example.edu
workstation user@192.168.1.100
```

### Selective Sync

Create `.syncignore` in your home directory:

```text
.aws/credentials
.ssh/
.vscode/
```

## Advanced Customization

### Shell Functions

Add to `~/.zsh_work`:

```zsh
# Add project-specific functions
function start_analysis() {
    local project="$1"
    cd ~/projects/"$project" || return
    micromamba activate bioinf
    tmux new-session -s "$project"
}
```

### Workflow Monitors

Customize monitor behavior in `~/.config/bioinf-cli-env/monitoring/workflow.conf`:

```yaml
snakemake:
  log_pattern: "*.snakemake.log"
  refresh_rate: 5
  enable_notifications: true
nextflow:
  work_dir: "work"
  refresh_rate: 10
  enable_notifications: false
wdl:
  log_dir: "cromwell-workflow-logs"
  refresh_rate: 15
  enable_notifications: true
```

You can also set thresholds for resource usage warnings in `monitor.conf`.

### Custom Job Templates

To create additional templates for common workflows, save them in 
`~/.local/share/bioinf-cli-env/job_templates/`. For example:

```bash
#!/bin/bash
#SBATCH --job-name=genome_assembly
#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --mem=64G
#SBATCH --time=48:00:00

# Load required modules
module load spades/3.15.3

# Run the assembly
spades.py -o output_dir -1 reads_1.fq -2 reads_2.fq
```
