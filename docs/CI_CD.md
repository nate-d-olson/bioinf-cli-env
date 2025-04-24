# CI/CD Setup

This project uses GitHub Actions for continuous integration and testing on multiple platforms.

## Workflow Overview

The CI workflow automatically tests the installation, configuration, and uninstallation processes on both Ubuntu 24.04 and macOS. This ensures compatibility across different operating systems and helps catch issues before they reach users.

### What's Being Tested

1. **Installation Process**: The workflow tests the non-interactive installation using a predefined configuration.
2. **Configuration Files**: Verifies that essential configuration files are correctly placed.
3. **Tool Installation**: Checks that key tools like `eza` and `bat` are available after installation.
4. **Uninstallation Process**: Tests that the uninstallation script works correctly.

## Configuration

The CI workflow uses a special configuration file located at `.github/workflows/ci-config.ini`, which is configured for non-interactive installation with sensible defaults.

## Running Tests Locally

You can replicate the CI testing environment locally:

```bash
# For Ubuntu-like systems
./install.sh --non-interactive --config .github/workflows/ci-config.ini

# Test functionality
# ...then uninstall
./uninstall.sh --non-interactive
```

## Extending the Tests

To add new tests to the CI workflow:

1. Edit the `.github/workflows/ci.yml` file
2. Add new steps under the appropriate job section
3. Ensure any new tests work on both Ubuntu and macOS platforms

## Troubleshooting CI Issues

If the CI workflow fails:

1. Check the GitHub Actions logs for specific error messages
2. Try to reproduce the issue locally using the CI configuration
3. Make necessary adjustments to the code or configuration
4. Push changes to trigger a new CI run