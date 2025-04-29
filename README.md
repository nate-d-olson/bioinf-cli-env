# Bioinformatics CLI Environment

A comprehensive command-line environment setup for bioinformatics work, featuring:

- Modern command-line tools for improved productivity
- Shell configuration with Oh My Zsh and Powerlevel10k theme
- Micromamba for bioinformatics package management
- Workflow monitoring tools for Snakemake, Nextflow, and WDL pipelines
- SLURM job management utilities
- Color palette selector for data visualization

![CI](https://github.com/nate-d-olson/bioinf-cli-env/actions/workflows/ci.yml/badge.svg)
![Docker](https://img.shields.io/docker/pulls/nate-d-olson/bioinf-cli-env)
![License](https://img.shields.io/github/license/nate-d-olson/bioinf-cli-env)

## Quick Start

```bash
# Clone the repository
git clone https://github.com/nate-d-olson/bioinf-cli-env.git
cd bioinf-cli-env

# Review and customize configuration
cp config.ini.template config.ini
nano config.ini

# Run the installer (interactive mode)
./install.sh

# For non-interactive installation with a custom config file
./install.sh --non-interactive --config custom_config.ini
```

## Features

### Modern CLI Tools

- File navigation and viewing with `eza`, `bat`, `ripgrep`, and `fd`
- Fuzzy finding with `fzf`
- JSON processing with `jq`
- System monitoring with `htop`
- Terminal multiplexing with `tmux`
- Directory jumping with `zoxide`

### Shell Configuration

- Oh My Zsh with Powerlevel10k theme
- Syntax highlighting and autosuggestions
- Custom aliases and functions
- Improved command completion

### Package Management

- Micromamba for fast conda-compatible package management
- Pre-configured bioinformatics environment
- Easy environment switching

### Workflow Monitoring

- Real-time monitoring for Snakemake pipelines
- Nextflow workflow tracking
- WDL/Cromwell job monitoring
- Resource usage visualization

### Job Management

- Enhanced SLURM job status monitoring
- Interactive job templates
- Job notification system
- Resource usage tracking

### Additional Features

- Color palette selector for visualization work
- Azure OpenAI CLI integration (optional)
- Cross-system configuration sync
- Backup and restore functionality

## Documentation

For detailed information, see:

- [User Guide](docs/USER_GUIDE.md)
- [Customization](docs/CUSTOMIZATION.md)
- [Job Monitoring](docs/JOB_MONITORING.md)
- [Docker Usage](docs/DOCKER.md)
- [Local Testing](docs/LOCAL_TESTING.md)
- [CI/CD](docs/CI_CD.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## Requirements

- Linux or macOS
- Bash or Zsh shell
- Git
- Optional: Docker for containerized usage

## License

MIT License. See [LICENSE](LICENSE) for details.
