#!/usr/bin/env bash
# WDL/Cromwell workflow monitor
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../utils/monitor_common.sh
source "$SCRIPT_DIR/utils/monitor_common.sh"

# Default configuration
: "${LOG_DIR:=cromwell-workflow-logs}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
    -i | --interval)
        UPDATE_INTERVAL="$2"
        shift 2
        ;;
    -d | --dir)
        LOG_DIR="$2"
        shift 2
        ;;
    -n | --notify)
        ENABLE_NOTIFICATIONS=true
        shift
        ;;
    -h | --help)
        echo "Usage: $(basename "$0") [-i interval] [-d log_dir] [-n]"
        echo
        echo "Options:"
        echo "  -i, --interval SECONDS   Update interval (default: 10)"
        echo "  -d, --dir DIR            Log directory (default: cromwell-workflow-logs)"
        echo "  -n, --notify             Enable desktop notifications"
        echo "  -h, --help               Show this help message"
        exit 0
        ;;
    *)
        echo "Error: Unknown option $1"
        echo "Run '$(basename "$0") --help' for usage"
        exit 1
        ;;
    esac
done

# Check if log directory exists
if [[ ! -d "$LOG_DIR" ]]; then
    log_error "Log directory not found: $LOG_DIR"
    echo "Create the log directory or specify a different one with -d option"
    exit 1
fi

# Main monitoring loop
log_info "Starting WDL/Cromwell workflow monitor..."
log_info "Monitoring log directory: $LOG_DIR"
log_info "Update interval: ${UPDATE_INTERVAL}s"
log_info "Press Ctrl+C to exit"

start_time=$(date +%s)

while true; do
    # Clear screen and show header
    setup_display
    echo "🧬 WDL/Cromwell Workflow Monitor"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Log directory: $LOG_DIR"
    
    # Get current time and calculate elapsed time
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    elapsed_formatted=$(printf "%02d:%02d:%02d" $((elapsed/3600)) $(((elapsed%3600)/60)) $((elapsed%60)))
    
    echo "Elapsed time: $elapsed_formatted"
    echo

    # Find all workflow logs
    workflow_logs=$(find "$LOG_DIR" -name "*.log" -type f 2>/dev/null || echo "")
    
    if [[ -z "$workflow_logs" ]]; then
        echo "No workflow logs found in $LOG_DIR"
        sleep "$UPDATE_INTERVAL"
        continue
    fi
    
    # Find the most recent workflow log
    latest_log=$(find "$LOG_DIR" -name "*.log" -type f -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -n 1 | cut -d ' ' -f 2 || echo "")
    
    if [[ -z "$latest_log" ]]; then
        echo "No workflow logs found in $LOG_DIR"
        sleep "$UPDATE_INTERVAL"
        continue
    fi
    
    # Get workflow ID from log filename
    local workflow_id
    workflow_id=$(basename "$latest_log" .log)
    echo "Latest workflow ID: $workflow_id"
    
    # Count started, running, and completed jobs
    started=$(grep -c "starting" "$latest_log" || echo 0)
    completed=$(grep -c "done" "$latest_log" || echo 0)
    failed=$(grep -c "failed" "$latest_log" || echo 0)
    
    # Display active workflow status
    echo
    echo "Workflow Status Summary:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Started tasks:    $started"
    echo "Completed tasks:  $completed"
    echo "Failed tasks:     $failed"
    
    # Calculate progress if we have any started tasks
    if [[ "$started" -gt 0 ]]; then
        progress_pct=$((completed * 100 / started))
        echo "Progress:         ${progress_pct}%"
        
        # Create a progress bar
        echo
        progress_bar="["
        bar_width=50
        filled_width=$((bar_width * progress_pct / 100))
        
        for ((i = 0; i < filled_width; i++)); do
            progress_bar+="#"
        done
        
        for ((i = filled_width; i < bar_width; i++)); do
            progress_bar+="-"
        done
        
        progress_bar+="] ${progress_pct}%"
        echo "$progress_bar"
    fi
    
    # Display recent log entries
    echo
    echo "Recent Log Entries:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    tail -n 20 "$latest_log" | grep -v "^\[" | head -n 10
    
    # Check if workflow is complete
    workflow_complete=$(grep -c "Workflow .*complete" "$latest_log" || echo 0)
    
    if [[ "$workflow_complete" -gt 0 ]]; then
        echo
        echo "✅ Workflow appears to be complete!"
        
        if [[ "$ENABLE_NOTIFICATIONS" == "true" ]]; then
            send_notification "WDL Workflow Complete" "Your workflow has finished running."
        fi
    fi
    
    # If there are failed tasks, notify the user
    if [[ "$failed" -gt 0 && "$ENABLE_NOTIFICATIONS" == "true" ]]; then
        send_notification "WDL Workflow Error" "Your workflow has encountered errors ($failed failed tasks)." "critical"
    fi
    
    # Display active tasks
    active_tasks=$(grep "starting" "$latest_log" | grep -v "done\|failed" | tail -n 5 || echo "")
    
    if [[ -n "$active_tasks" ]]; then
        echo
        echo "Recently Started Tasks:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "$active_tasks"
    fi
    
    # Display system resource usage if available
    if command -v free &>/dev/null || command -v top &>/dev/null; then
        echo
        echo "System Resource Usage:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        # Memory usage
        if command -v free &>/dev/null; then
            # Linux
            free -h | grep -E "Mem|total" | head -n 2
        elif command -v vm_stat &>/dev/null; then
            # macOS
            echo "Memory:"
            vm_stat | grep "Pages free:" | awk '{ print "Free:      " $3 * 4 / 1024 " MB" }'
            vm_stat | grep "Pages active:" | awk '{ print "Active:    " $3 * 4 / 1024 " MB" }'
            vm_stat | grep "Pages inactive:" | awk '{ print "Inactive:  " $3 * 4 / 1024 " MB" }'
            vm_stat | grep "Pages wired down:" | awk '{ print "Wired:     " $4 * 4 / 1024 " MB" }'
        fi
        
        # CPU usage
        if command -v top &>/dev/null; then
            echo
            echo "CPU Load:"
            if [[ "$(uname)" == "Darwin" ]]; then
                # macOS
                top -l 1 | grep -E "^CPU usage" | head -n 1
            else
                # Linux
                top -bn1 | grep "Cpu(s)" | head -n 1
            fi
        fi
    fi
    
    # Wait for the next update
    sleep "$UPDATE_INTERVAL"
done
