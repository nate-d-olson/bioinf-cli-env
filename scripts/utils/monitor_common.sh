#!/usr/bin/env bash
# Common utilities for workflow monitors
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Default configuration
: "${UPDATE_INTERVAL:=10}"
: "${ENABLE_NOTIFICATIONS:=false}"

# State management
STATE_DIR="${HOME}/.local/state/bioinf-cli-env"
mkdir -p "$STATE_DIR"

# Monitor state management
MONITOR_STATE_DIR="${STATE_DIR}/monitors"
mkdir -p "$MONITOR_STATE_DIR"

# Terminal control
setup_display() {
    # Clear screen and move cursor to top
    if [[ -t 1 ]]; then
        tput clear
        tput cup 0 0
    fi
}

# Timestamp formatting
format_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Duration calculation
calculate_duration() {
    local start_time=$1
    local end_time=${2:-$(date +%s)}
    local duration=$((end_time - start_time))
    
    if ((duration < 60)); then
        echo "${duration}s"
    elif ((duration < 3600)); then
        echo "$((duration / 60))m $((duration % 60))s"
    else
        echo "$((duration / 3600))h $(((duration % 3600) / 60))m"
    fi
}

# Memory formatting
format_memory() {
    local bytes=$1
    if ((bytes < 1024)); then
        echo "${bytes}B"
    elif ((bytes < 1048576)); then
        echo "$((bytes / 1024))KB"
    elif ((bytes < 1073741824)); then
        echo "$((bytes / 1048576))MB"
    else
        echo "$((bytes / 1073741824))GB"
    fi
}

# Progress bar
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "Progress: ["
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "] %d%%\n" "$percentage"
}

# Desktop notifications
send_notification() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"
    
    if cmd_exists notify-send; then
        notify-send -u "$urgency" "$title" "$message"
    elif [[ "$(uname)" == "Darwin" ]]; then
        osascript -e "display notification \"$message\" with title \"$title\""
    else
        log_warning "No notification system available"
        echo "$title: $message"
    fi
}

# Save monitor state
save_monitor_state() {
    local monitor_type="$1"
    shift
    
    # Create state file with monitor type and timestamp
    {
        echo "# $monitor_type monitor state"
        echo "timestamp=$(date +%s)"
        for var in "$@"; do
            echo "$var"
        done
    } > "$STATE_DIR/${monitor_type}_monitor.state"
}

# Load monitor state
load_monitor_state() {
    local monitor_type="$1"
    local state_file="$STATE_DIR/${monitor_type}_monitor.state"
    
    if [[ -f "$state_file" ]]; then
        source "$state_file"
        return 0
    fi
    return 1
}

# Resource usage tracking
get_process_memory() {
    local pid=$1
    if [[ "$(uname)" == "Darwin" ]]; then
        ps -o rss= -p "$pid" | awk '{print $1 * 1024}'
    else
        grep VmRSS "/proc/$pid/status" 2>/dev/null | awk '{print $2 * 1024}'
    fi
}

get_process_cpu() {
    local pid=$1
    if [[ "$(uname)" == "Darwin" ]]; then
        ps -o %cpu= -p "$pid" | tr -d ' '
    else
        grep 'cpu' "/proc/$pid/stat" 2>/dev/null | awk '{print ($14 + $15) * 100 / '$(($(getconf CLK_TCK)))'}' 
    fi
}

# Log rotation
rotate_logs() {
    local log_file="$1"
    local max_size="${2:-10485760}" # Default 10MB
    
    if [[ -f "$log_file" ]]; then
        local size
        size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file")
        
        if (( size > max_size )); then
            mv "$log_file" "${log_file}.1"
            touch "$log_file"
            log_info "Rotated log file: $log_file"
        fi
    fi
}

# Check for required commands
check_requirements() {
    local failed=0
    for cmd in "$@"; do
        if ! command -v "$cmd" &>/dev/null; then
            log_error "Required command not found: $cmd"
            failed=1
        fi
    done
    return "$failed"
}

# Process management
save_monitor_pid() {
    local workflow="$1"
    local pid="$2"
    echo "$pid" > "$MONITOR_STATE_DIR/${workflow}_monitor.pid"
}

get_monitor_pid() {
    local workflow="$1"
    local pid_file="$MONITOR_STATE_DIR/${workflow}_monitor.pid"
    if [[ -f "$pid_file" ]]; then
        cat "$pid_file"
    fi
}

stop_monitor() {
    local workflow="$1"
    local pid
    pid=$(get_monitor_pid "$workflow")
    if [[ -n "$pid" ]]; then
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            rm -f "$MONITOR_STATE_DIR/${workflow}_monitor.pid"
            log_success "Stopped ${workflow} monitor"
        else
            log_warning "${workflow} monitor not running"
            rm -f "$MONITOR_STATE_DIR/${workflow}_monitor.pid"
        fi
    else
        log_warning "No ${workflow} monitor found"
    fi
}

# Workflow log parsing
parse_workflow_status() {
    local log_file="$1"
    local workflow_type="$2"
    
    case "$workflow_type" in
        nextflow)
            grep -E "^\[(.*)\] .*(SUCCESS|FAILED|COMPLETED|ERROR).*$" "$log_file"
            ;;
        snakemake)
            grep -E "^(Complete|Error|Finished|Failed)" "$log_file"
            ;;
        wdl)
            grep -E "^(Successfully|Failed|Finished|Error)" "$log_file"
            ;;
        *)
            log_error "Unknown workflow type: $workflow_type"
            return 1
            ;;
    esac
}

# Resource monitoring
get_workflow_resources() {
    local pid="$1"
    local resources
    
    if cmd_exists ps; then
        resources=$(ps -p "$pid" -o %cpu,%mem,rss | tail -n1)
        echo "CPU: $(echo "$resources" | awk '{print $1}')%"
        echo "Memory: $(echo "$resources" | awk '{print $2}')%"
        echo "RSS: $(echo "$resources" | awk '{print $3}')KB"
    fi
}

# Monitor control
start_workflow_monitor() {
    local workflow="$1"
    local log_file="$2"
    local monitor_script="$3"
    
    if [[ -f "$MONITOR_STATE_DIR/${workflow}_monitor.pid" ]]; then
        log_warning "${workflow} monitor already running"
        return 1
    fi
    
    nohup "$monitor_script" "$log_file" > /dev/null 2>&1 &
    local pid=$!
    save_monitor_pid "$workflow" "$pid"
    log_success "Started ${workflow} monitor (PID: $pid)"
}

# Health check
check_monitor_health() {
    local workflow="$1"
    local pid
    pid=$(get_monitor_pid "$workflow")
    
    if [[ -n "$pid" ]]; then
        if kill -0 "$pid" 2>/dev/null; then
            log_success "${workflow} monitor is running (PID: $pid)"
            get_workflow_resources "$pid"
            return 0
        else
            log_error "${workflow} monitor is not running"
            rm -f "$MONITOR_STATE_DIR/${workflow}_monitor.pid"
            return 1
        fi
    else
        log_error "No ${workflow} monitor found"
        return 1
    fi
}

# Get file size in bytes
get_file_size() {
    local file="$1"
    if [[ -f "$file" ]]; then
        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS
            stat -f%z "$file"
        else
            # Linux
            stat --format=%s "$file"
        fi
    else
        echo "0"
    fi
}

# Convert bytes to human-readable format
get_readable_size() {
    local size="$1"
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0
    
    while [[ $size -gt 1024 && $unit -lt ${#units[@]}-1 ]]; do
        size=$(echo "scale=2; $size / 1024" | bc)
        ((unit++))
    done
    
    printf "%.2f %s" $size "${units[$unit]}"
}

# Check if a command exists and is in path
check_command() {
    local cmd="$1"
    command -v "$cmd" &>/dev/null
}

# Start monitoring system resources
start_resource_monitoring() {
    local output_dir="$1"
    local interval="${2:-60}"  # Default interval: 60 seconds
    local pid_file="$output_dir/resource_monitor.pid"
    
    mkdir -p "$output_dir"
    
    # Start monitoring in background
    (
        echo "timestamp,cpu_percent,mem_used_mb,mem_total_mb,mem_percent,load_avg" > "$output_dir/system_resources.csv"
        
        while true; do
            # Get timestamp
            local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
            
            # CPU usage
            local cpu_percent=0
            if check_command "mpstat"; then
                cpu_percent=$(mpstat 1 1 | grep -A 1 "%idle" | tail -1 | awk '{print 100 - $NF}')
            elif check_command "top"; then
                if [[ "$(uname)" == "Darwin" ]]; then
                    # macOS
                    cpu_percent=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
                else
                    # Linux
                    cpu_percent=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
                fi
            fi
            
            # Memory usage
            local mem_used_mb=0
            local mem_total_mb=0
            local mem_percent=0
            
            if check_command "free"; then
                # Linux
                local mem_info=$(free -m | grep Mem)
                mem_total_mb=$(echo "$mem_info" | awk '{print $2}')
                mem_used_mb=$(echo "$mem_info" | awk '{print $3}')
                mem_percent=$(echo "scale=2; $mem_used_mb * 100 / $mem_total_mb" | bc)
            elif [[ "$(uname)" == "Darwin" ]]; then
                # macOS
                mem_total_mb=$(sysctl -n hw.memsize | awk '{print $1 / 1024 / 1024}')
                local page_size=$(sysctl -n hw.pagesize)
                local mem_free=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
                local mem_inactive=$(vm_stat | grep "Pages inactive" | awk '{print $3}' | sed 's/\.//')
                local mem_free_mb=$(echo "scale=2; ($mem_free + $mem_inactive) * $page_size / 1024 / 1024" | bc)
                mem_used_mb=$(echo "scale=2; $mem_total_mb - $mem_free_mb" | bc)
                mem_percent=$(echo "scale=2; $mem_used_mb * 100 / $mem_total_mb" | bc)
            fi
            
            # Load average
            local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $1}' | tr -d ' ')
            
            # Append to CSV
            echo "$timestamp,$cpu_percent,$mem_used_mb,$mem_total_mb,$mem_percent,$load_avg" >> "$output_dir/system_resources.csv"
            
            sleep "$interval"
        done
    ) &
    
    # Save PID for later termination
    echo $! > "$pid_file"
    
    echo "Resource monitoring started (PID: $(cat "$pid_file"))"
    echo "Data being saved to: $output_dir/system_resources.csv"
}

# Stop resource monitoring
stop_resource_monitoring() {
    local output_dir="$1"
    local pid_file="$output_dir/resource_monitor.pid"
    
    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file")
        
        if ps -p "$pid" > /dev/null; then
            kill "$pid" 2>/dev/null
            echo "Resource monitoring stopped (PID: $pid)"
        else
            echo "Resource monitoring process (PID: $pid) not found"
        fi
        
        rm -f "$pid_file"
    else
        echo "No resource monitoring process found"
    fi
}

# Track pipeline progress
track_progress() {
    local total_steps="$1"
    local current_step="$2"
    local step_name="$3"
    local start_time="${4:-$(date +%s)}"
    
    # Calculate progress
    local percent=$((current_step * 100 / total_steps))
    
    # Calculate elapsed time
    local current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    
    # Format elapsed time
    local hours=$((elapsed / 3600))
    local minutes=$(((elapsed % 3600) / 60))
    local seconds=$((elapsed % 60))
    local elapsed_formatted=$(printf "%02d:%02d:%02d" $hours $minutes $seconds)
    
    # Calculate estimated time remaining
    local eta="Unknown"
    if [[ "$current_step" -gt 0 ]]; then
        local time_per_step=$((elapsed / current_step))
        local remaining_time=$((time_per_step * (total_steps - current_step)))
        
        local eta_hours=$((remaining_time / 3600))
        local eta_minutes=$(((remaining_time % 3600) / 60))
        local eta_seconds=$((remaining_time % 60))
        eta=$(printf "%02d:%02d:%02d" $eta_hours $eta_minutes $eta_seconds)
    fi
    
    # Generate progress bar
    local bar_width=50
    local filled_width=$((bar_width * percent / 100))
    local empty_width=$((bar_width - filled_width))
    
    local progress_bar="["
    for ((i=0; i<filled_width; i++)); do
        progress_bar+="="
    done
    
    if [[ "$filled_width" -lt "$bar_width" ]]; then
        progress_bar+=">"
        for ((i=0; i<empty_width-1; i++)); do
            progress_bar+=" "
        done
    fi
    
    progress_bar+="]"
    
    # Print progress information
    echo -ne "\r$progress_bar $percent% ($current_step/$total_steps) | Step: $step_name | Elapsed: $elapsed_formatted | ETA: $eta"
    
    # Add newline if complete
    if [[ "$current_step" -eq "$total_steps" ]]; then
        echo ""
    fi
}

# Parse FASTA headers to get genome size
get_genome_size() {
    local ref_genome="$1"
    
    if [[ ! -f "$ref_genome" ]]; then
        echo "0"
        return
    fi
    
    local total_size=0
    
    # Check if samtools is available for faster parsing
    if check_command "samtools"; then
        total_size=$(samtools faidx "$ref_genome" 2>/dev/null && \
                    awk '{sum += $2} END {print sum}' "${ref_genome}.fai" 2>/dev/null)
        
        # If successful, return the size
        if [[ -n "$total_size" ]]; then
            echo "$total_size"
            return
        fi
    fi
    
    # Fallback to slower parsing method
    if [[ "$ref_genome" == *.gz ]]; then
        # Compressed genome
        if check_command "zcat" && check_command "grep" && check_command "wc"; then
            # Count non-header lines
            local seq_lines=$(zcat "$ref_genome" | grep -v "^>" | wc -l)
            # Count characters in non-header lines (approximate)
            local chars_per_line=$(zcat "$ref_genome" | grep -v "^>" | head -10 | awk '{sum += length($0)} END {print int(sum/NR)}')
            total_size=$((seq_lines * chars_per_line))
        fi
    else
        # Uncompressed genome
        if check_command "grep" && check_command "wc"; then
            # Count non-header lines
            local seq_lines=$(grep -v "^>" "$ref_genome" | wc -l)
            # Count characters in non-header lines (approximate)
            local chars_per_line=$(grep -v "^>" "$ref_genome" | head -10 | awk '{sum += length($0)} END {print int(sum/NR)}')
            total_size=$((seq_lines * chars_per_line))
        fi
    fi
    
    echo "$total_size"
}