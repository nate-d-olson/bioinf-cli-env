# CI/CD Guide

This guide explains the Continuous Integration and Continuous Delivery (CI/CD)
setup for the bioinformatics CLI environment.

## Overview

The CI/CD pipeline automatically tests the environment setup on multiple platforms
to ensure compatibility and reliability. It runs on every push to the main branch
and for pull requests.

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
|----------|-------|----------------|
| Ubuntu   | zsh   | apt            |
| macOS    | zsh   | brew           |

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
```

## Status Badges

Include these badges in your fork's README:

```markdown
![CI](https://github.com/username/bioinf-cli-env/actions/workflows/ci.yml/badge.svg)
```
