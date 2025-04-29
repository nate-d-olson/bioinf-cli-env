#!/usr/bin/env bash
# Nextflow workflow monitor
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../utils/monitor_common.sh
source "$SCRIPT_DIR/utils/monitor_common.sh"

# Default configuration
: "${WORK_DIR:=work}"
: "${RUN_NAME:=}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
    -i | --interval)
        UPDATE_INTERVAL="$2"
        shift 2
        ;;
    -w | --work)
        WORK_DIR="$2"
        shift 2
        ;;
    -r | --run)
        RUN_NAME="$2"
        shift 2
        ;;
    -n | --notify)
        ENABLE_NOTIFICATIONS=true
        shift
        ;;
    -h | --help)
        echo "Usage: $(basename "$0") [-i interval] [-w work_dir] [-r run_name] [-n]"
        echo
        echo "Options:"
        echo "  -i, --interval SECONDS   Update interval (default: 10)"
        echo "  -w, --work DIR           Work directory (default: work)"
        echo "  -r, --run NAME           Run name"
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

# Check if work directory exists
if [[ ! -d "$WORK_DIR" ]]; then
    log_error "Work directory not found: $WORK_DIR"
    echo "Create the work directory or specify a different one with -w option"
    exit 1
fi

# Main monitoring loop
log_info "Starting Nextflow workflow monitor..."
log_info "Monitoring work directory: $WORK_DIR"
log_info "Update interval: ${UPDATE_INTERVAL}s"
log_info "Press Ctrl+C to exit"

start_time=$(date +%s)

while true; do
    # Clear screen and show header
    setup_display
    echo "⚙️  Nextflow Workflow Monitor"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Work directory: $WORK_DIR"
    
    # Display run name if specified
    if [[ -n "$RUN_NAME" ]]; then
        echo "Run name: $RUN_NAME"
    fi
    
    # Get current time and calculate elapsed time
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    elapsed_formatted=$(printf "%02d:%02d:%02d" $((elapsed/3600)) $(((elapsed%3600)/60)) $((elapsed%60)))
    
    echo "Elapsed time: $elapsed_formatted"
    echo

    # Look for .command.log files to determine active processes
    active_processes=$(find "$WORK_DIR" -name ".command.log" -mmin -2 | wc -l)
    
    # Find total number of processes by counting all .command.log files
    total_processes=$(find "$WORK_DIR" -name ".command.log" | wc -l)
    
    # Find completed processes by counting .exitcode files with value 0
    completed_processes=$(find "$WORK_DIR" -name ".exitcode" -exec cat {} \; 2>/dev/null | grep -c "^0$" || echo 0)
    
    # Find failed processes by counting .exitcode files with non-zero value
    failed_processes=$(find "$WORK_DIR" -name ".exitcode" -exec cat {} \; 2>/dev/null | grep -c -v "^0$" || echo 0)
    
    # Calculate progress percentage
    if [[ "$total_processes" -gt 0 ]]; then
        progress_pct=$((completed_processes * 100 / total_processes))
    else
        progress_pct=0
    fi
    
    # Find most recent process start
    recent_start=$(find "$WORK_DIR" -name ".command.log" -type f -printf "%T@ %p\n" 2>/dev/null | sort -n | tail -n 1 | cut -d ' ' -f 2 || echo "")
    
    if [[ -n "$recent_start" ]]; then
        recent_process=$(basename "$(dirname "$recent_start")")
        echo "Most recent process: $recent_process"
    fi
    
    # Display summary
    echo "Status Summary:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Total processes:   $total_processes"
    echo "Active processes:  $active_processes"
    echo "Completed:         $completed_processes"
    echo "Failed:            $failed_processes"
    echo "Progress:          ${progress_pct}%"
    echo
    
    # Create a progress bar
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
    echo
    
    # Find and display recent log output
    echo "Recent Log Output:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Find 5 most recently modified log files
    recent_logs=$(find "$WORK_DIR" -name ".command.log" -type f -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -n 5 | cut -d ' ' -f 2 || echo "")
    
    if [[ -n "$recent_logs" ]]; then
        for log in $recent_logs; do
            process_dir=$(basename "$(dirname "$log")")
            echo "Process: $process_dir"
            echo "----------------------------------------"
            tail -n 5 "$log"
            echo
        done
    else
        echo "No log files found"
    fi
    
    # Check for completion
    if [[ "$active_processes" -eq 0 && "$total_processes" -gt 0 && "$completed_processes" -ge "$total_processes" ]]; then
        echo "✅ Workflow appears to be complete!"
        
        if [[ "$ENABLE_NOTIFICATIONS" == "true" ]]; then
            send_notification "Nextflow Workflow Complete" "Your workflow has finished running."
        fi
    fi
    
    # If there are failed processes, notify the user
    if [[ "$failed_processes" -gt 0 && "$ENABLE_NOTIFICATIONS" == "true" ]]; then
        send_notification "Nextflow Workflow Error" "Your workflow has encountered errors ($failed_processes failed tasks)." "critical"
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
