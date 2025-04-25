# Local Testing Guide for macOS

This guide provides safe methods for testing the bioinformatics CLI environment installation on macOS during development, without risking your existing configurations.

## Why Test Locally?

While Docker provides an isolated environment for testing, testing directly on macOS offers several advantages:

- Test native performance and compatibility
- Validate integration with macOS-specific features
- Ensure a smooth experience for end users on macOS

## Safe Testing Strategies

### 1. Create a Test User

The safest approach is to create a dedicated test user on your macOS system:

```bash
# Create a new user (requires admin privileges)
sudo dscl . -create /Users/biotest
sudo dscl . -create /Users/biotest UserShell /bin/zsh
sudo dscl . -create /Users/biotest RealName "Biotest User"
sudo dscl . -create /Users/biotest UniqueID 1001
sudo dscl . -create /Users/biotest PrimaryGroupID 20
sudo dscl . -create /Users/biotest NFSHomeDirectory /Users/biotest
sudo dscl . -passwd /Users/biotest [password]

# Create home directory for the user
sudo mkdir -p /Users/biotest
sudo chown -R biotest:staff /Users/biotest
```

Log in as this user to test installations without affecting your primary environment.

1. Use a Temporary Home Directory
   This method doesn't require creating a new user, but simulates a clean environment:

```bash
# Create a temporary home directory
mkdir -p /tmp/biotest_home

# Clone the repository
cd /tmp
git clone https://github.com/yourusername/bioinf-cli-env.git
cd bioinf-cli-env

# Run installation with modified HOME
HOME=/tmp/biotest_home ./install.sh
```

This approach ensures that all configurations are created in the temporary directory, not affecting your actual home directory.

3. Use Installation Flags for Safe Testing
   The install script supports several flags that can make testing safer:

```bash
# Create a development testing configuration
cp config.ini.template config.dev.ini

# Edit to customize testing configuration
nano config.dev.ini
```

Modify config.dev.ini to disable components you don't want to test:

```bash
INSTALL_MODERN_TOOLS=true
INSTALL_OH_MY_ZSH=false  # Set to false to preserve existing oh-my-zsh
INSTALL_MICROMAMBA=true
INSTALL_JOB_MONITORING=true
INSTALL_PALETTE_SELECTOR=true
INSTALL_AZURE_OPENAI=false
```

Then run the installation with this configuration:

```bash
./install.sh --config config.dev.ini
```

4. Use Backup and Restore Scripts
   Before testing, you can create a backup script to save your important configurations:

```bash
#!/bin/bash
BACKUP_DIR="$HOME/.config/pre-test-backup-$(date +%Y%m%d%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup important configuration files
for file in .zshrc .p10k.zsh .oh-my-zsh .nanorc .tmux.conf .fzf .fzf.zsh; do
    if [[ -e "$HOME/$file" ]]; then
        cp -r "$HOME/$file" "$BACKUP_DIR/"
        echo "Backed up $HOME/$file to $BACKUP_DIR"
    fi
done

echo "Backup complete at $BACKUP_DIR"
```

After testing, you can restore these files:

```bash
#!/bin/bash
BACKUP_DIR="$HOME/.config/pre-test-backup-[timestamp]" # Replace with actual backup directory

# Restore important configuration files
for file in .zshrc .p10k.zsh .nanorc .tmux.conf .fzf.zsh; do
    if [[ -e "$BACKUP_DIR/$file" ]]; then
        cp -r "$BACKUP_DIR/$file" "$HOME/"
        echo "Restored $file"
    fi
done

# For directories, you may want to remove existing ones first
for dir in .oh-my-zsh .fzf; do
    if [[ -d "$BACKUP_DIR/$dir" && -d "$HOME/$dir" ]]; then
        rm -rf "$HOME/$dir"
        cp -r "$BACKUP_DIR/$dir" "$HOME/"
        echo "Restored $dir"
    fi
done

echo "Restoration complete"
```

5. Test Component-by-Component
   Instead of running the full installer, you can test individual component scripts:

```bash
# Test only the modern tools installation
bash scripts/setup_tools.sh

# Test only the Oh My Zsh setup
bash scripts/setup_omz.sh config/
```

This approach lets you verify each component separately, making troubleshooting easier.

## Testing Integration with Other Tools

Once individual components are working, you should test integration with your regular workflow:

```bash
# Test micromamba environment activation
source ~/.zshrc
micromamba activate bioinf
python -c "import pandas; print(pandas.__version__)"

# Test workflow monitoring
bash scripts/workflow_monitors/snakemake_monitor.sh test_data/sample_snakemake.log
```

## Reverting Changes During Development

If you encounter issues during testing, you can use the backup created by the installer:

```bash
# Find the backup directory
ls -la ~/.config/bioinf-cli-env.bak.*

# Restore specific files
cp ~/.config/bioinf-cli-env.bak.[timestamp]/.zshrc ~/
```

## Testing the Uninstaller

The uninstaller script can be tested in a similar way to avoid losing your configurations:

```bash
# Test uninstaller in a temporary home
HOME=/tmp/biotest_home ./uninstall.sh
```

## Automating Testing

You can create a test script that combines these approaches:

```bash
#!/bin/bash
# Setup test environment
TEST_HOME="/tmp/biotest_home"
mkdir -p "$TEST_HOME"

# Clone or copy repository to a test location
TEST_REPO="/tmp/bioinf-cli-env-test"
cp -r "$(pwd)" "$TEST_REPO"

# Run tests in the test environment
(
    cd "$TEST_REPO"
    HOME="$TEST_HOME" ./install.sh --non-interactive --config config.ini.template

    # Verify installation
    if [[ -f "$TEST_HOME/.zshrc" ]]; then
        echo "✅ .zshrc installed correctly"
    else
        echo "❌ .zshrc missing"
    fi

    # Additional verification steps...

    # Clean up
    HOME="$TEST_HOME" ./uninstall.sh --non-interactive
    rm -rf "$TEST_HOME" "$TEST_REPO"
)
```

### Conclusion

By following these safe testing practices, you can validate the bioinformatics CLI environment on macOS without risking your existing configurations. This is especially important during development when the uninstall and backup functionality is still being refined.

Remember to document any issues you encounter and use version control to track your changes.
