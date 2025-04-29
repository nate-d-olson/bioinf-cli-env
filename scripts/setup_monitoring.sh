#!/usr/bin/env bash
# Job monitoring tools setup
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/common.sh"

# Default paths
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/bioinf-cli-env/monitoring"
MONITOR_DIR="$SCRIPT_DIR/workflow_monitors"

# Create required directories
mkdir -p "$BIN_DIR" "$CONFIG_DIR"

log_info "📊 Setting up job monitoring tools..."

# Function to install a monitor script
install_monitor() {
    local source="$1"
    local target="$2"
    local name="$3"

    if [[ ! -f "$source" ]]; then
        log_error "Monitor script not found: $source"
        return 1
    fi

    # Install the monitor script
    install -m0755 "$source" "$target"
    log_success "Installed $name monitor to $target"
}

# Install workflow monitors
install_monitor "$MONITOR_DIR/snakemake_monitor.sh" "$BIN_DIR/snakemonitor" "Snakemake"
install_monitor "$MONITOR_DIR/nextflow_monitor.sh" "$BIN_DIR/nextflow-monitor" "Nextflow"
install_monitor "$MONITOR_DIR/wdl_monitor.sh" "$BIN_DIR/wdl-monitor" "WDL"

# Create monitoring configuration
cat >"$CONFIG_DIR/monitor.conf" <<EOF
# Job monitoring configuration
UPDATE_INTERVAL=10
LOG_RETENTION_DAYS=7
ENABLE_NOTIFICATIONS=false

# Log directories
SNAKEMAKE_LOG_DIR=logs
NEXTFLOW_WORK_DIR=work
WDL_LOG_DIR=cromwell-workflow-logs
EOF

# Add monitoring aliases to .zshrc if not already present
if ! grep -q "# Job monitoring aliases" "$HOME/.zshrc"; then
    cat >>"$HOME/.zshrc" <<'EOF'

# Job monitoring aliases
alias smr='snakemonitor'  # Snakemake monitor
alias nfr='nextflow-monitor'  # Nextflow monitor
alias wdlr='wdl-monitor'  # WDL monitor

# Monitor configuration
export BIOINF_MONITOR_CONFIG="$HOME/.config/bioinf-cli-env/monitoring/monitor.conf"
EOF
fi

# Add monitor completion for zsh
cat >"$CONFIG_DIR/_snakemonitor" <<'EOF'
#compdef snakemonitor

_snakemonitor() {
    _arguments \
        '-i[Update interval]:interval (seconds)' \
        '--interval[Update interval]:interval (seconds)' \
        '-l[Log file]:log file:_files' \
        '--log[Log file]:log file:_files' \
        '-n[Enable notifications]' \
        '--notify[Enable notifications]' \
        '-h[Show help message]' \
        '--help[Show help message]'
}

_snakemonitor "$@"
EOF

cat >"$CONFIG_DIR/_nextflow-monitor" <<'EOF'
#compdef nextflow-monitor

_nextflow_monitor() {
    _arguments \
        '-i[Update interval]:interval (seconds)' \
        '--interval[Update interval]:interval (seconds)' \
        '-w[Work directory]:directory:_files -/' \
        '--work[Work directory]:directory:_files -/' \
        '-r[Run name]:run name' \
        '--run[Run name]:run name' \
        '-n[Enable notifications]' \
        '--notify[Enable notifications]' \
        '-h[Show help message]' \
        '--help[Show help message]'
}

_nextflow_monitor "$@"
EOF

cat >"$CONFIG_DIR/_wdl-monitor" <<'EOF'
#compdef wdl-monitor

_wdl_monitor() {
    _arguments \
        '-i[Update interval]:interval (seconds)' \
        '--interval[Update interval]:interval (seconds)' \
        '-d[Log directory]:directory:_files -/' \
        '--dir[Log directory]:directory:_files -/' \
        '-n[Enable notifications]' \
        '--notify[Enable notifications]' \
        '-h[Show help message]' \
        '--help[Show help message]'
}

_wdl_monitor "$@"
EOF

# Install completions if not already in fpath and running in Zsh
if [ -n "${ZSH_VERSION:-}" ] && ! grep -q "$CONFIG_DIR" "$HOME/.zshrc"; then
    echo -e "\n# Add job monitoring completions to fpath\nfpath=($CONFIG_DIR \$fpath)" >>"$HOME/.zshrc"
fi

log_success "Job monitoring tools setup complete!"
log_info "Available commands:"
log_info "  snakemonitor     - Monitor Snakemake workflows"
log_info "  nextflow-monitor - Monitor Nextflow workflows"
log_info "  wdl-monitor      - Monitor WDL/Cromwell workflows"
log_info ""
log_info "Use -h or --help with any command to see usage options"
