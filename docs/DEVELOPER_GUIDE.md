# Developer Guide

This guide covers how to contribute to, test, and extend the bioinformatics CLI environment.

## Repository Structure

```
bioinf-cli-env/
├── config/                     # Configuration templates deployed to $HOME
│   ├── micromamba-config.yaml  # Conda environment specification
│   ├── nanorc                  # Nano editor configuration
│   ├── p10k.zsh                # Powerlevel10k theme configuration
│   ├── tmux.conf               # Tmux session manager configuration
│   └── zshrc                   # Main Zsh shell configuration
├── docs/                       # Documentation
├── scripts/                    # Installation and utility scripts
│   ├── setup_omz.sh            # Oh My Zsh + Powerlevel10k installer
│   ├── setup_tools.sh          # Modern CLI tools installer
│   ├── setup_micromamba.sh     # Micromamba installer
│   ├── setup_llm.sh            # Azure OpenAI CLI integration
│   ├── setup_monitoring.sh     # Workflow monitoring setup
│   ├── setup_job_management.sh # SLURM job management utilities
│   ├── select_palette.sh       # Terminal color palette selector
│   ├── utils/                  # Shared utility functions
│   │   ├── common.sh           # Logging, platform detection, state management
│   │   ├── monitor_common.sh   # Monitoring utilities
│   │   ├── slurm_helpers.sh    # SLURM-specific helper functions
│   │   └── version_management.sh # Version tracking helpers
│   └── workflow_monitors/      # Workflow monitoring scripts
│       ├── snakemake_monitor.sh
│       ├── nextflow_monitor.sh
│       ├── wdl_monitor.sh
│       └── monitor_alignment.sh
├── .github/workflows/          # GitHub Actions CI/CD
│   ├── ci.yml                  # Main CI pipeline
│   └── ci-config.ini           # CI-specific install configuration
├── Dockerfile                  # Container build definition
├── install.sh                  # Main installer entry point
├── uninstall.sh                # Uninstallation script
├── sync.sh                     # Cross-system configuration sync
└── config.ini.template         # User configuration template
```

## Development Prerequisites

- **Bash** 4.0+ (or Zsh 5.0+)
- **Git** for cloning and managing plugin repositories
- **Docker** (optional) for container-based testing
- **shellcheck** (optional) for shell script linting

## Local Development Setup

1. Fork and clone the repository:

   ```bash
   git clone https://github.com/<your-fork>/bioinf-cli-env.git
   cd bioinf-cli-env
   ```

2. Create a feature branch:

   ```bash
   git checkout -b feature/your-feature-name
   ```

3. Make your changes and test locally (see [Testing](#testing)).

4. Run shellcheck on any modified scripts:

   ```bash
   shellcheck scripts/*.sh scripts/utils/*.sh scripts/workflow_monitors/*.sh
   ```

## Testing

### Local Testing

Use the non-interactive mode with the CI config for quick local validation:

```bash
cp config.ini.template my-test.ini
./install.sh --non-interactive --config my-test.ini
```

For detailed local testing instructions, see [LOCAL_TESTING.md](LOCAL_TESTING.md).

### Docker Testing

Build and test the Docker image locally:

```bash
# Build
docker build -t bioinf-cli-env-test .

# Run smoke tests
docker run --rm bioinf-cli-env-test zsh -c "command -v micromamba"
docker run --rm bioinf-cli-env-test zsh -c "command -v bat || command -v batcat"

# Interactive session
docker run --rm -it bioinf-cli-env-test
```

See [DOCKER.md](DOCKER.md) for full Docker usage instructions.

### CI/CD

GitHub Actions runs the CI pipeline on every push and pull request to `main`. The pipeline:

1. Tests a non-interactive installation on Ubuntu (`test-ubuntu`)
2. Tests a non-interactive installation on macOS (`test-macos`)
3. Builds and smoke-tests the Docker image (`build-docker`)

The CI uses `.github/workflows/ci-config.ini` for configuration. See [CI_CD.md](CI_CD.md) for details.

## Adding a New Component

To add a new installable component:

1. Create a new setup script in `scripts/setup_<component>.sh`.
2. Add an installation function `install_<component>()` in `install.sh`.
3. Add a corresponding flag (e.g., `INSTALL_<COMPONENT>=false`) in:
   - `install.sh` (default value)
   - `config.ini.template` (with documentation comment)
   - `.github/workflows/ci-config.ini` (with appropriate CI default)
4. Wire the new function into the `main()` function in `install.sh`.
5. Add cleanup logic to `uninstall.sh`.

## Utility Functions (`scripts/utils/common.sh`)

All scripts can source `scripts/utils/common.sh` for:

| Function | Purpose |
|----------|---------|
| `log_info / log_warning / log_error / log_success` | Coloured console + file logging |
| `cmd_exists <cmd>` | Test whether a command is on PATH |
| `detect_platform` | Return `os_arch[_variant]` string |
| `safe_download <url> <dest>` | Download via curl or wget |
| `save_state / get_state` | Persist component install state |
| `backup_config <file>` | Back up a config file with timestamp |

## Code Style

- All scripts use `#!/usr/bin/env bash` and `set -euo pipefail`.
- Logging uses the shared helpers from `common.sh` (or local equivalents in scripts that do not source it).
- Variable names are `UPPER_SNAKE_CASE` for globals, `lower_snake_case` for locals.
- Always declare local variables with `local` inside functions.
- Prefer `command -v` / `cmd_exists` over `which` for command detection.

## Known Issues and Limitations

- **dipcall**: Requires `unimap` which is not in the default conda channels.
- **truvari**: Has Python compatibility constraints; pin to a compatible version.
- **Azure OpenAI integration**: Requires a pre-configured Azure CLI (`az`) installation and an active Azure subscription.

## Submitting a Pull Request

1. Ensure all CI checks pass.
2. Update documentation in `docs/` if you change user-facing behaviour.
3. Add a brief description of the change and the motivation in the PR body.
4. Reference any related issues using `Fixes #<issue>` or `Relates to #<issue>`.
