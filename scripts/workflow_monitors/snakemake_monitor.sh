#!/usr/bin/env bash
# Snakemake workflow monitor
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../utils/monitor_common.sh
source "$SCRIPT_DIR/utils/monitor_common.sh"

LOGFILE="logs/snakemake.log"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
    -i | --interval)
        UPDATE_INTERVAL="$2"
        shift 2
        ;;
    -l | --log)
        LOGFILE="$2"
        shift 2
        ;;
    -n | --notify)
        ENABLE_NOTIFICATIONS=true
        shift
        ;;
    -h | --help)
        echo "Usage: $(basename "$0") [-i interval] [-l logfile] [-n]"
        echo
        echo "Options:"
        echo "  -i, --interval SECONDS   Update interval (default: 10)"
        echo "  -l, --log FILE           Log file to monitor (default: logs/snakemake.log)"
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

# Check if log file exists or is accessible
if [[ ! -f "$LOGFILE" ]]; then
    log_error "Log file not found: $LOGFILE"
    echo "Create the log file or specify a different log file with -l option"
    exit 1
fi

if [[ ! -r "$LOGFILE" ]]; then
    log_error "Cannot read log file: $LOGFILE"
    echo "Check file permissions"
    exit 1
fi

# Main monitoring loop
log_info "Starting Snakemake workflow monitor..."
log_info "Monitoring log file: $LOGFILE"
log_info "Update interval: ${UPDATE_INTERVAL}s"
log_info "Press Ctrl+C to exit"

last_size=0
start_time=$(date +%s)

while true; do
    # Clear screen and show header
    setup_display
    echo "🐍 Snakemake Workflow Monitor"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Log file: $LOGFILE"
    
    # Get current time and calculate elapsed time
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    elapsed_formatted=$(printf "%02d:%02d:%02d" $((elapsed/3600)) $(((elapsed%3600)/60)) $((elapsed%60)))
    
    echo "Elapsed time: $elapsed_formatted"
    echo

    # Check if the file still exists
    if [[ ! -f "$LOGFILE" ]]; then
        log_error "Log file no longer exists: $LOGFILE"
        sleep "$UPDATE_INTERVAL"
        continue
    fi

    # Check if file has been updated
    current_size=$(stat -c%s "$LOGFILE" 2>/dev/null || stat -f%z "$LOGFILE")
    
    if (( current_size > last_size )); then
        # File has grown, show new content
        if (( last_size > 0 )); then
            echo "📋 New log entries:"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            tail -n $(($(wc -l < "$LOGFILE") - $(($last_size / 80)))) "$LOGFILE" | tail -n 20
        else
            # First run, show the last 20 lines
            echo "📋 Recent log entries:"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            tail -n 20 "$LOGFILE"
        fi
        
        last_size=$current_size
    else
        echo "📋 No new log entries"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        # Show the last 20 lines
        tail -n 20 "$LOGFILE"
    fi
    
    echo
    echo "Status Summary:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Count completed, running, and errored jobs
    completed=$(grep -c "localrule .* complete\|Finished job [0-9]\+ of [0-9]\+" "$LOGFILE" || echo 0)
    errors=$(grep -c "Error in rule\|Exception\|Error executing" "$LOGFILE" || echo 0)
    
    # Try to extract total job count (may not be available)
    total_jobs_line=$(grep -o "of [0-9]\+ total" "$LOGFILE" | tail -n 1 || echo "")
    if [[ -n "$total_jobs_line" ]]; then
        total_jobs=$(echo "$total_jobs_line" | grep -o "[0-9]\+")
    else
        # Estimate from the completed + running + errored jobs
        total_jobs=$((completed + errors + 1))  # +1 is a placeholder for current job
    fi
    
    # Extract current progress
    progress_line=$(grep -o "Finished job [0-9]\+ of [0-9]\+" "$LOGFILE" | tail -n 1 || echo "")
    if [[ -n "$progress_line" ]]; then
        current_job=$(echo "$progress_line" | grep -o "job [0-9]\+" | grep -o "[0-9]\+")
    else
        # Default to completed jobs as a fallback
        current_job="$completed"
    fi
    
    # Show progress
    echo "Total jobs: $total_jobs"
    echo "Completed jobs: $completed"
    echo "Errors: $errors"
    echo
    echo -n "Progress: "
    show_progress "$current_job" "$total_jobs"
    
    # Check for workflow completion or errors
    workflow_complete=$(grep -c "Complete log:" "$LOGFILE" || echo 0)
    
    if [[ "$workflow_complete" -gt 0 && "$ENABLE_NOTIFICATIONS" == "true" ]]; then
        send_notification "Snakemake Workflow Complete" "Your workflow has finished running."
    fi
    
    if [[ "$errors" -gt 0 && "$ENABLE_NOTIFICATIONS" == "true" ]]; then
        send_notification "Snakemake Workflow Error" "Your workflow has encountered errors." "critical"
    fi
    
    # Display resource usage if available
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
