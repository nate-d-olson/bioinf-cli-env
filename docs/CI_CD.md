# CI/CD Guide

This guide explains the Continuous Integration and Continuous Delivery (CI/CD)
setup for the bioinformatics CLI environment.

## Overview

The CI/CD pipeline automatically tests the environment setup on multiple platforms
to ensure compatibility and reliability. It runs on every push to the main branch
and for pull requests.

## Non-Interactive Installation Support

The installer now fully supports non-interactive mode for CI/CD environments:

```bash
# Basic non-interactive installation with default values
./install.sh --non-interactive

# Non-interactive installation with custom configuration
./install.sh --non-interactive --config custom.ini
```

The `--non-interactive` flag:
- Sets the `BIOINF_NON_INTERACTIVE` environment variable for all component scripts
- Skips user prompts by using default or configuration file values
- Prevents sudo password prompts from hanging the CI/CD pipeline
- Uses direct binary downloads as a fallback when package manager installations require sudo

## Pipeline Steps

1. **Environment Setup**

   - Ubuntu 24.04 and macOS environments
   - Installation of system dependencies
   - Configuration preparation

2. **Installation Testing**

   - Full installation in non-interactive mode
   - Modern CLI tools verification
   - Shell configuration testing
   - Job monitoring setup validation

3. **Docker Build**
   - Container image building
   - Environment validation inside container
   - Configuration testing
   - Tool availability verification

## Testing Matrix

| Platform | Shell | Package Manager |
| -------- | ----- | --------------- |
| Ubuntu   | zsh   | apt             |
| macOS    | zsh   | brew            |

## Sample GitHub Actions Workflow

Here's an example workflow for testing the installation:

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
      - name: Install zsh
        run: sudo apt-get update && sudo apt-get install -y zsh
      - name: Copy config template
        run: cp config.ini.template ci-config.ini
      - name: Run non-interactive installation
        run: ./install.sh --non-interactive --config ci-config.ini
      - name: Verify installation
        run: |
          source ~/.zshrc
          zsh -c "command -v bat && command -v micromamba"

  test-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Copy config template
        run: cp config.ini.template ci-config.ini
      - name: Run non-interactive installation
        run: ./install.sh --non-interactive --config ci-config.ini
      - name: Verify installation
        run: |
          source ~/.zshrc
          zsh -c "command -v bat && command -v micromamba"
```

## Docker Testing

The Docker testing process includes:

1. Building the container image
2. Verifying tool installations
3. Testing shell configurations
4. Validating job monitoring
5. Checking cross-platform compatibility

## Local Pipeline Testing

To test the CI/CD pipeline locally:

```bash
# Install act (GitHub Actions runner)
brew install act

# Run the full pipeline
act -P ubuntu-latest=ubuntu:24.04

# Run specific job
act -j test-ubuntu

# Test non-interactive installation
cp config.ini.template local-test.ini
# Edit local-test.ini as needed
./install.sh --non-interactive --config local-test.ini
```

## Status Badges

Include these badges in your fork's README:

```markdown
![CI](https://github.com/username/bioinf-cli-env/actions/workflows/ci.yml/badge.svg)
```

## Debugging CI/CD Failures

If a CI/CD job fails:

1. Review the logs in the GitHub Actions interface.
2. Re-run the job with debug logging enabled:

   ```yaml
   jobs:
     test:
       steps:
         - name: Enable debug logging
           run: |
             export ACTIONS_STEP_DEBUG=true
             # For more verbose installation logs
             echo "VERBOSE_OUTPUT=true" >> ci-config.ini
   ```

3. Test the failing step locally using `act`:

   ```bash
   act -j <job-name>
   ```

4. Verify the environment setup matches the pipeline configuration.

## Customizing the Pipeline

To customize the pipeline for specific workflows:

1. Modify the `ci.yml` file to include additional steps or jobs.
2. Add environment variables or secrets as needed in the GitHub repository settings.
3. Test changes locally using `act` before pushing to the repository.
