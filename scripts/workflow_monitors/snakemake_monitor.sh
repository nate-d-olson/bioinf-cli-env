#!/usr/bin/env bash
# Snakemake workflow monitor
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/monitor_common.sh"

# Default configuration
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/bioinf-cli-env/monitor.conf"
LOGFILE="logs/snakemake.log"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--interval)
            UPDATE_INTERVAL="$2"
            shift 2
            ;;
        -l|--log)
            LOGFILE="$2"
            shift 2
            ;;
        -n|--notify)
            ENABLE_NOTIFICATIONS=true
            shift
            ;;
        -h|--help)
            echo "Usage: $(basename "$0") [-i interval] [-l logfile] [-n]"
            echo
            echo "Options:"
            echo "  -i, --interval SECONDS   Update interval (default: 10)"
            echo "  -l, --log FILE          Log file to monitor (default: logs/snakemake.log)"
            echo "  -n, --notify            Enable desktop notifications"
            echo "  -h, --help              Show this help message"
            exit 0
            ;;
        *)
            die "Unknown option: $1"
            ;;
    esac
done

# Verify log file exists
if [[ ! -f "$LOGFILE" ]]; then
    die "Log file not found: $LOGFILE"
fi

# Monitor state
declare -A job_states
start_time=$(date +%s)

log_info "Monitoring Snakemake log: $LOGFILE (refreshing every ${UPDATE_INTERVAL}s)"
log_info "Press Ctrl+C to exit"

monitor_snakemake() {
    local total=0
    local completed=0
    local running=0
    local failed=0
    
    # Parse log file for job status
    while IFS= read -r line; do
        if [[ $line =~ rule[[:space:]]+([^:]+) ]]; then
            total=$((total + 1))
            job_name="${BASH_REMATCH[1]}"
            job_states["$job_name"]="pending"
        elif [[ $line =~ Finished[[:space:]]+job[[:space:]]+([^.]+) ]]; then
            job_name="${BASH_REMATCH[1]}"
            job_states["$job_name"]="completed"
            completed=$((completed + 1))
        elif [[ $line =~ Error[[:space:]]+in[[:space:]]+rule[[:space:]]+([^:]+) ]]; then
            job_name="${BASH_REMATCH[1]}"
            job_states["$job_name"]="failed"
            failed=$((failed + 1))
            send_notification "Snakemake Error" "Job $job_name failed"
        fi
    done < "$LOGFILE"
    
    # Calculate running jobs
    running=$(($(grep -c "Submitted job" "$LOGFILE") - completed - failed))
    running=$((running < 0 ? 0 : running))
    
    # Display status
    setup_display
    
    echo "=== Snakemake Status ==="
    echo "Last updated: $(format_timestamp)"
    echo
    echo "Runtime: $(calculate_duration "$start_time")"
    echo
    show_progress "$completed" "$total"
    echo
    echo "Jobs Summary:"
    echo "  Total:     $total"
    echo "  Running:   $running"
    echo "  Completed: $completed"
    echo "  Failed:    $failed"
    echo
    
    # Show recent job completions
    echo "Recent Job Completions:"
    grep "Finished job" "$LOGFILE" | tail -n 5
    echo
    
    # Show any recent errors
    if ((failed > 0)); then
        echo "Recent Errors:"
        grep -A 2 "Error in rule" "$LOGFILE" | tail -n 6
    fi
    
    # Save monitoring state
    save_monitor_state "snakemake" \
        "total=$total" \
        "completed=$completed" \
        "failed=$failed" \
        "last_update=$(date +%s)"
}

# Main monitoring loop
trap 'echo; log_info "Monitoring stopped."; exit 0' INT

while true; do
    monitor_snakemake
    sleep "$UPDATE_INTERVAL"
done