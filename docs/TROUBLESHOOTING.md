# Troubleshooting Guide

This guide helps you troubleshoot common issues that may arise when using the
bioinformatics CLI environment.

## Installation Issues

### Oh My Zsh Installation Fails

If Oh My Zsh installation fails, try:

```bash
# Remove existing installation
rm -rf ~/.oh-my-zsh

# Clone manually
git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
```

### Modern Tools Not Found

If modern CLI tools are not available after installation:

1. Check PATH configuration in `.zshrc`
2. Verify tool installation in `~/.local/bin`
3. Run the tools installation script again:

```bash
bash scripts/setup_tools.sh
```

### Micromamba Environment Issues

If micromamba environments are not working:

1. Check initialization in `.zshrc`
2. Verify installation location
3. Try reinstalling:

```bash
rm -rf ~/micromamba
bash scripts/setup_micromamba.sh
```

## Runtime Issues

### Job Monitoring Not Working

If job monitoring tools fail:

1. Check log file permissions
2. Verify configuration file exists
3. Test monitoring manually:

```bash
bash scripts/workflow_monitors/snakemake_monitor.sh --debug test.log
```

### Cross-System Sync Issues

If sync.sh fails:

1. Verify SSH configuration
2. Check host configuration in sync_hosts
3. Test SSH connection:

```bash
./sync.sh check hostname
```

### Performance Issues

If the shell becomes slow:

1. Check Powerlevel10k configuration
2. Reduce enabled plugins in `.zshrc`
3. Monitor system resources:

```bash
htop
```

## Configuration Issues

### Theme Not Loading

If Powerlevel10k theme isn't working:

1. Check font installation
2. Verify theme in `.zshrc`
3. Run configuration:

```bash
p10k configure
```

### Plugin Conflicts

If zsh plugins conflict:

1. Load plugins one by one
2. Check plugin order in `.zshrc`
3. Remove conflicting plugins

## System-Specific Issues

### macOS Issues

Common macOS-specific fixes:

1. Reset zsh configuration:

   ```bash
   mv ~/.zshrc ~/.zshrc.bak
   ./install.sh
   ```

2. Fix permissions:

   ```bash
   chmod 755 ~/.local/bin/*
   ```

### Linux Issues

Common Linux-specific fixes:

1. Install missing dependencies:

   ```bash
   sudo apt-get update
   sudo apt-get install build-essential
   ```

2. Fix file ownership:

   ```bash
   chown -R $USER:$USER ~/.local
   ```

## Uninstallation Issues

If uninstall.sh fails:

1. Check file permissions
2. Run with debug output:

   ```bash
   bash -x uninstall.sh
   ```

3. Manual cleanup:

   ```bash
   rm -rf ~/.local/bin/snakemonitor
   rm -rf ~/.local/bin/nextflow-monitor
   rm -rf ~/.config/bioinf-cli-env
   ```

## Getting Help

If you still have issues:

1. Check the documentation in `docs/`
2. Review error messages in `~/.local/log/`
3. Open an issue on GitHub with:
   - Error messages
   - System information
   - Steps to reproduce
