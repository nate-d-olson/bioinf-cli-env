# User Guide

This guide provides comprehensive information about using the bioinformatics CLI
environment effectively.

## Getting Started

### First Time Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/bioinf-cli-env.git
   cd bioinf-cli-env
   ```

2. Review and customize configuration:

   ```bash
   cp config.ini.template config.ini
   nano config.ini
   ```

3. Run the installer (interactive mode):

   ```bash
   ./install.sh
   ```

   For non-interactive installation with a custom configuration file:

   ```bash
   ./install.sh --non-interactive --config custom_config.ini
   ```

4. Restart your shell:

   ```bash
   exec zsh
   ```

### Basic Usage

The environment provides several enhanced commands:

- `ll`, `la`: Enhanced file listing with `eza`
- `cat`: Syntax-highlighted file viewing with `bat`
- `find`: Improved file finding with `fd`
- `grep`: Better text search with `ripgrep`
- `z`: Smart directory jumping with `zoxide`

## Working with Tools

### Modern CLI Tools

#### File Navigation

```bash
# List files with Git status
ll

# Show directory tree
lt

# Find files by name
fd pattern

# Search file contents
rg "search pattern"
```

#### System Monitoring

```bash
# Show system resources
htop

# Monitor specific process
htop -p $(pgrep process_name)
```

### Package Management

#### Micromamba Usage

```bash
# Activate environment
micromamba activate bioinf

# Install package
micromamba install -c bioconda new-package

# List installed packages
micromamba list
```

## Job Management

### SLURM Integration

#### Monitoring Jobs

```bash
# Show your jobs
sj

# Show all system jobs
sj -a

# Show specific job details
sj <job_id>
```

#### Interactive Sessions

```bash
# 1 core, 8GB RAM session
srun1

# 8 cores, 32GB RAM session
srun8
```

### Workflow Monitoring

#### Snakemake Workflows

```bash
# Monitor workflow
snakemonitor -l snakemake.log

# Enable notifications
snakemonitor -n
```

#### Nextflow Pipelines

```bash
# Monitor current workflow
nextflow-monitor

# Monitor specific workflow
nextflow-monitor -r run_name
```

#### WDL/Cromwell Workflows

```bash
# Monitor workflows in the default directory
wdl-monitor

# Monitor workflows in a specific directory
wdl-monitor -d /path/to/cromwell/logs

# Enable notifications
wdl-monitor -n
```

## Configuration Management

### Shell Customization

Edit these files for customization:

- `~/.zshrc`: Main shell configuration
- `~/.p10k.zsh`: Prompt customization
- `~/.zsh_work`: Work-specific settings

### Color Schemes

Select and customize color schemes:

```bash
# Launch palette selector
select_palette

# Save current scheme
select_palette --save custom
```

## Cross-System Sync

### Managing Hosts

```bash
# Add new host
./sync.sh add-host nickname user@host.example.com

# List configured hosts
./sync.sh list-hosts
```

### Syncing Configuration

```bash
# Push to host
./sync.sh push hostname

# Pull from host
./sync.sh pull hostname

# Sync to all hosts
./sync.sh --all
```

#### Selective Sync

To exclude specific files or directories from synchronization, create a `.syncignore` file in your home directory:

```text
.aws/credentials
.ssh/
.vscode/
```

This ensures sensitive or unnecessary files are not synced.

## Best Practices

1. Keep configurations in sync across systems
2. Use job monitoring for long-running tasks
3. Regularly update tools and packages
4. Back up custom configurations
5. Use version control for scripts

## Getting Help

- Check the troubleshooting guide: `docs/TROUBLESHOOTING.md`
- Review common customizations: `docs/CUSTOMIZATION.md`
- For job monitoring help: `docs/JOB_MONITORING.md`
- Docker usage guide: `docs/DOCKER.md`
