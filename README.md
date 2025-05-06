# Bioinformatics CLI Environment

**🚧 Project Status: Alpha version (actively in development)**

This repository is geared toward developing a comprehensive command-line environment to enhance productivity in bioinformatics pipeline development. Currently, this project is considered an **alpha release**, undergoing active development and debugging. Feel free to explore, test, and contribute, but exercise caution regarding system configurations due to ongoing changes.

For detailed developer guidance, see [`GOOSE_DEV_SESSION_GUIDE.md`](GOOSE_DEV_SESSION_GUIDE.md).

---

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

# Non-interactive installation mode
./install.sh --non-interactive --config custom_config.ini
```

## Key Features

- 🛠 **Modern CLI Tools:** Enhanced file navigation (`exa`), file viewing (`bat`), fast searching (`ripgrep`, `fd-find`), and more.
- 🎨 **Shell Enhancement:** Oh My Zsh with Powerlevel10k theme, syntax highlighting, autocompletion.
- 🌿 **Package Management:** Micromamba for managing bioinformatics software.
- 📊 **Workflow Monitoring:** Track and visualize Snakemake, Nextflow, Cromwell (WDL) jobs.
- 🚦 **Job Management:** Advanced SLURM utilities for HPC clusters.
- 🎨 **Color Palette Selector:** Customize your terminal for data visualization.
- ⛅ **Optional Integrations:** Azure OpenAI (CLI integration planned for future implementation).
- 🔄 **Cross-System Synchronization:** Easily synchronize setup across different machines.
- 🛡 **Backup and Restore Functionality:** Ensure your custom configurations are safe and reusable.

## Documentation Overview

Detailed documentation is available in the following:

- [User Guide](docs/USER_GUIDE.md)
- [Development Guide](docs/DEVELOPER_GUIDE.md)
- [Customization](docs/CUSTOMIZATION.md)
- [Docker Usage](docs/DOCKER.md)
- [Local Testing](docs/LOCAL_TESTING.md)
- [CI/CD Instructions](docs/CI_CD.md)
- [Job Monitoring](docs/JOB_MONITORING.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## System Requirements

- Operating System: Linux or macOS
- Shell: Bash/Zsh (recommended Zsh)
- Git: Version control workflow
- Docker (optional): Container-based workflows

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.