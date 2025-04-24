#!/usr/bin/env bash
# WDL/Cromwell workflow monitor
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/monitor_common.sh"

# Default configuration
: "${LOG_DIR:=cromwell-workflow-logs}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--interval)
            UPDATE_INTERVAL="$2"
            shift 2
            ;;
        -d|--dir)
            LOG_DIR="$2"
            shift 2
            ;;
        -n|--notify)
            ENABLE_NOTIFICATIONS=true
            shift
            ;;
        -h|--help)
            echo "Usage: $(basename "$0") [-i interval] [-d log_dir] [-n]"
            echo
            echo "Options:"
            echo "  -i, --interval SECONDS   Update interval (default: 10)"
            echo "  -d, --dir DIR           Log directory (default: cromwell-workflow-logs)"
            echo "  -n, --notify            Enable desktop notifications"
            echo "  -h, --help              Show this help message"
            exit 0
            ;;
        *)
            die "Unknown option: $1"
            ;;
    esac
done

# Verify log directory exists
if [[ ! -d "$LOG_DIR" ]]; then
    die "Log directory not found: $LOG_DIR"
fi

# Monitor state
declare -A workflow_states
start_time=$(date +%s)

log_info "Monitoring WDL workflows in: $LOG_DIR (refreshing every ${UPDATE_INTERVAL}s)"
log_info "Press Ctrl+C to exit"

monitor_wdl() {
    local total=0
    local running=0
    local completed=0
    local failed=0
    
    # Find and parse all workflow logs
    while IFS= read -r log_file; do
        if [[ ! -f "$log_file" ]]; then
            continue
        fi
        
        local workflow_id=$(basename "$log_file" .log)
        ((total++))
        
        # Parse log file for workflow status
        if grep -q "workflow finished with status 'Succeeded'" "$log_file"; then
            workflow_states["$workflow_id"]="completed"
            ((completed++))
        elif grep -q "workflow failed" "$log_file"; then
            workflow_states["$workflow_id"]="failed"
            ((failed++))
            # Send notification on failure
            if [[ "${workflow_states["$workflow_id"]:-}" != "notified" ]]; then
                send_notification "WDL Workflow Failed" "Workflow $workflow_id failed"
                workflow_states["$workflow_id"]="notified"
            fi
        else
            workflow_states["$workflow_id"]="running"
            ((running++))
        fi
    done < <(find "$LOG_DIR" -name "*.log" -type f)
    
    # Display status
    setup_display
    
    echo "=== WDL/Cromwell Status ==="
    echo "Last updated: $(format_timestamp)"
    echo
    echo "Runtime: $(calculate_duration "$start_time")"
    echo
    show_progress "$completed" "$total"
    echo
    echo "Workflow Summary:"
    echo "  Total:     $total"
    echo "  Running:   $running"
    echo "  Completed: $completed"
    echo "  Failed:    $failed"
    echo
    
    # Show recent workflow completions
    echo "Recent Workflow Completions:"
    find "$LOG_DIR" -name "*.log" -type f -mmin -30 | while read -r log; do
        workflow_id=$(basename "$log" .log)
        status="${workflow_states[$workflow_id]}"
        if [[ "$status" == "completed" ]]; then
            echo "✓ $workflow_id ($(calculate_duration "$(stat -f %m "$log")"))"
        fi
    done
    echo
    
    # Show resource usage for running workflows
    if ((running > 0)); then
        echo "Running Workflows Resource Usage:"
        for workflow_id in "${!workflow_states[@]}"; do
            if [[ "${workflow_states[$workflow_id]}" == "running" ]]; then
                local log_file="$LOG_DIR/$workflow_id.log"
                if [[ -f "$log_file" ]]; then
                    echo "Workflow: $workflow_id"
                    # Extract memory usage if available
                    local mem_usage
                    mem_usage=$(grep "Memory" "$log_file" | tail -n1 | grep -o '[0-9]\+' || echo "0")
                    if ((mem_usage > 0)); then
                        echo "  Memory: $(format_memory "$mem_usage")"
                    fi
                    echo "  Runtime: $(calculate_duration "$(stat -f %m "$log_file")")"
                    echo
                fi
            fi
        done
    fi
    
    # Show recent errors
    if ((failed > 0)); then
        echo "Recent Errors:"
        for workflow_id in "${!workflow_states[@]}"; do
            if [[ "${workflow_states[$workflow_id]}" == "failed" ]]; then
                local log_file="$LOG_DIR/$workflow_id.log"
                if [[ -f "$log_file" ]]; then
                    echo "Workflow: $workflow_id"
                    grep -A 2 "workflow failed" "$log_file" | tail -n 3
                    echo
                fi
            fi
        done
    fi
    
    # Save monitoring state
    save_monitor_state "wdl" \
        "total=$total" \
        "completed=$completed" \
        "failed=$failed" \
        "last_update=$(date +%s)"
}

# Main monitoring loop
trap 'echo; log_info "Monitoring stopped."; exit 0' INT

while true; do
    monitor_wdl
    sleep "$UPDATE_INTERVAL"
done