#!/usr/bin/env bash
# Nextflow workflow monitor
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/monitor_common.sh"

# Default configuration
: "${WORK_DIR:=work}"
: "${RUN_NAME:=}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--interval)
            UPDATE_INTERVAL="$2"
            shift 2
            ;;
        -w|--work)
            WORK_DIR="$2"
            shift 2
            ;;
        -r|--run)
            RUN_NAME="$2"
            shift 2
            ;;
        -n|--notify)
            ENABLE_NOTIFICATIONS=true
            shift
            ;;
        -h|--help)
            echo "Usage: $(basename "$0") [-i interval] [-w work_dir] [-r run_name] [-n]"
            echo
            echo "Options:"
            echo "  -i, --interval SECONDS   Update interval (default: 10)"
            echo "  -w, --work DIR          Work directory (default: work)"
            echo "  -r, --run NAME          Run name for log file"
            echo "  -n, --notify            Enable desktop notifications"
            echo "  -h, --help              Show this help message"
            exit 0
            ;;
        *)
            die "Unknown option: $1"
            ;;
    esac
done

# Find the .nextflow.log file
LOG_FILE=".nextflow.log${RUN_NAME:+.$RUN_NAME}"
if [[ ! -f "$LOG_FILE" ]]; then
    die "Nextflow log file not found: $LOG_FILE"
fi

# Monitor state
declare -A process_states
start_time=$(date +%s)

log_info "Monitoring Nextflow run: $LOG_FILE (refreshing every ${UPDATE_INTERVAL}s)"
log_info "Press Ctrl+C to exit"

parse_trace_file() {
    local trace_file="$1"
    local fields=()
    local values=()
    
    # Read header line
    IFS=$'\t' read -r -a fields < "$trace_file"
    
    # Read last line for values
    while IFS=$'\t' read -r line; do
        IFS=$'\t' read -r -a values <<< "$line"
    done < "$trace_file"
    
    # Create associative array of field->value
    local result=""
    for i in "${!fields[@]}"; do
        [[ $i -lt ${#values[@]} ]] && result+="${fields[$i]}=${values[$i]}\n"
    done
    echo -e "$result"
}

monitor_nextflow() {
    local submitted=0
    local completed=0
    local failed=0
    local cached=0
    
    # Parse log file for process status
    submitted=$(grep -c "Submitted process" "$LOG_FILE" 2>/dev/null || echo 0)
    cached=$(grep -c "Cached process" "$LOG_FILE" 2>/dev/null || echo 0)
    completed=$((cached + $(grep -c "Completed process" "$LOG_FILE" 2>/dev/null || echo 0)))
    failed=$(grep -c "\[E\]" "$LOG_FILE" 2>/dev/null || echo 0)
    
    # Calculate running processes
    local running=$((submitted - completed - failed))
    running=$((running < 0 ? 0 : running))
    
    # Display status
    setup_display
    
    echo "=== Nextflow Status ==="
    echo "Last updated: $(format_timestamp)"
    echo
    echo "Runtime: $(calculate_duration "$start_time")"
    echo
    if ((submitted > 0)); then
        show_progress "$completed" "$submitted"
        echo
        echo "Process Summary:"
        echo "  Total:     $submitted"
        echo "  Running:   $running"
        echo "  Completed: $completed"
        echo "  Cached:    $cached"
        echo "  Failed:    $failed"
        echo
        
        # Show recent completions
        echo "Recent Process Completions:"
        grep -E "Cached process|Completed process" "$LOG_FILE" | tail -n 5
        echo
        
        # Show resource usage if available
        if [[ -d "$WORK_DIR" ]]; then
            echo "Resource Usage (recent processes):"
            while IFS= read -r trace_file; do
                echo "Process: $(dirname "$trace_file" | xargs basename)"
                parse_trace_file "$trace_file" | grep -E "duration|cpu|memory|disk"
                echo
            done < <(find "$WORK_DIR" -name ".command.trace" -type f -mmin -5 | head -n 3)
        fi
        
        # Show any recent errors
        if ((failed > 0)); then
            echo "Recent Errors:"
            grep -A 2 "ERROR" "$LOG_FILE" | tail -n 6
        fi
    else
        echo "No processes submitted yet. Waiting for workflow to start..."
    fi
    
    # Save monitoring state
    save_monitor_state "nextflow" \
        "submitted=$submitted" \
        "completed=$completed" \
        "failed=$failed" \
        "last_update=$(date +%s)"
}

# Main monitoring loop
trap 'echo; log_info "Monitoring stopped."; exit 0' INT

while true; do
    monitor_nextflow
    sleep "$UPDATE_INTERVAL"
done