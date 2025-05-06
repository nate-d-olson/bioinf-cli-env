# CI/CD Guide

This guide covers Continuous Integration and Continuous Delivery (CI/CD) specifics for the bioinformatics CLI environment, offering explicit instructions for setup, testing, debugging, and enhancement.

## Overview

The CI/CD pipeline systematically verifies the CLI environment setup on various platforms (Ubuntu, macOS). It validates environment consistency, tool availability, and pipeline compatibility upon each repository update.

## Non-Interactive Installation

For automated CI/CD environments, utilize the supported non-interactive mode:

```bash
# Default non-interactive installation
./install.sh --non-interactive

# Custom configuration
./install.sh --non-interactive --config custom.ini
```

The `--non-interactive` option enables:
- Automated setup avoiding prompts
- Default configurations or custom specified setups
- Explicit fallback mechanisms when administrative permissions are limited

## CI/CD Pipeline Process

### 1. Environment Initialization

Set up targeted environments (Ubuntu 24.04/macOS latest) clearly staging all dependencies, tools, and shell configurations.

### 2. Installation Validation

Automatic, non-interactive testing of:

- CLI tools availability and versions (exa, bat, fd-find, micromamba, etc.)
- Shell customizations and package management robustness
- Monitoring and reporting configurations

### 3. Docker Builds and Testing

- Comprehensive Docker image lifecycle tests: build, validate, and explicitly verify tool availability and environment.

## Testing Matrix

| Platform | Shell | Package Manager |
|----------|-------|-----------------|
| Ubuntu   | zsh   | apt             |
| macOS    | zsh   | brew            |

## Example GitHub Actions Workflow

Clear workflow example for installation and verification:

```yaml
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test-ubuntu:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Permissions
        run: chmod +x ./install.sh
      - name: Install zsh
        run: sudo apt-get update && sudo apt-get install -y zsh
      - name: Copy and Configure
        run: cp config.ini.template ci-config.ini
      - name: Non-interactive Installation
        run: ./install.sh --non-interactive --config ci-config.ini
      - name: Explicit Verification
        run: |
          export PATH="$HOME/.local/bin:$HOME/micromamba/bin:$PATH"
          source ~/.zshrc
          command -v bat && command -v micromamba

  test-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Permissions
        run: chmod +x ./install.sh
      - name: Copy and Configure
        run: cp config.ini.template ci-config.ini
      - name: Non-interactive Installation
        run: ./install.sh --non-interactive --config ci-config.ini
      - name: Explicit Verification
        run: |
          export PATH="$HOME/.local/bin:$HOME/micromamba/bin:$PATH"
          source ~/.zshrc
          command -v bat && command -v micromamba
```

## Local Pipeline Testing

Use the `act` tool for explicit local GitHub Actions workflow simulations:

### Installation and Basic Usage

```bash
brew install act
act -P ubuntu-latest=catthehacker/ubuntu:act-latest
```

Explicitly simulate entire pipeline or individual jobs:

```bash
# Full pipeline simulation
act

# Specific job execution
act -j test-ubuntu
```

## Integration with Docker

Continuous validation via Docker-based strategies:

- Building and testing Docker images explicitly from workflows
- Aligning Docker and CI environments for consistency across local and remote setups


## Debugging and Troubleshooting

When failures occur in CI/CD:
1. Examine clear logs on GitHub Actions UI.
2. Run individual failing steps locally using `act`.

Enable verbose logging for detailed debug output:

```yaml
jobs:
  test:
    steps:
      - name: Enable Verbose Logging
        run: |
          export ACTIONS_STEP_DEBUG=true
          echo "VERBOSE_OUTPUT=true" >> ci-config.ini
```

Test failing scenarios clearly and systematically:

```bash
act -j <job-name>
```

Ensure clear alignment between local setup and CI/CD pipeline environments for consistent testing results.

## Status & Customization

Display CI/CD status badges in project README:

```markdown
![CI](https://github.com/username/bioinf-cli-env/actions/workflows/ci.yml/badge.svg)
```

Explicitly customize workflows:
- Edit `.github/workflows/ci.yml` with additional checks and custom verification procedures

## Advanced Debugging Techniques

- Consider Docker alternatives (Colima) explicitly for local macOS testing:

```bash
brew install colima
colima start
```

- Export paths explicitly in verification steps to local environments in workflows:

```yaml
export PATH="$HOME/.local/bin:$HOME/micromamba/bin:$PATH"
source "$HOME/.zshrc"
```

This enhanced debugging documentation provides explicit troubleshooting steps to facilitate a robust and clear CI/CD pipeline, ensuring rapid issue resolution and improved development workflows.