#!/usr/bin/env bash
# Enhanced monitoring script for Nextflow workflows
set -euo pipefail
IFS=$'\n\t'

# Show usage if no arguments are provided
if [ $# -lt 1 ]; then
  echo "Usage: $(basename $0) <nextflow_script> [nextflow_args]"
  echo "Examples:"
  echo "  $(basename $0) main.nf"
  echo "  $(basename $0) main.nf -profile docker"
  exit 1
fi

NF_SCRIPT=$1
shift
ARGS=("$@")

# Create log directory
LOG_DIR="${HOME}/.logs/nextflow"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
WORK_DIR="work_${TIMESTAMP}"

echo "✨ Running Nextflow with enhanced monitoring..."
echo "📂 Work directory: ${WORK_DIR}"

# Run Nextflow with detailed reporting
nextflow -log "${LOG_DIR}/nextflow_${TIMESTAMP}.log" run "$NF_SCRIPT" \
  -with-report "${LOG_DIR}/report_${TIMESTAMP}.html" \
  -with-trace "${LOG_DIR}/trace_${TIMESTAMP}.txt" \
  -with-timeline "${LOG_DIR}/timeline_${TIMESTAMP}.html" \
  -with-dag "${LOG_DIR}/dag_${TIMESTAMP}.png" \
  -work-dir "$WORK_DIR" \
  "${ARGS[@]}" &

NF_PID=$!

# Function to monitor Nextflow execution
monitor_nextflow() {
  local start_time=$(date +%s)
  local processes_total=0
  local processes_complete=0
  local trace_file="${LOG_DIR}/trace_${TIMESTAMP}.txt"
  
  while kill -0 $NF_PID 2>/dev/null; do
    clear
    echo "✨ Nextflow Workflow Monitor"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Get process statistics from the work directory
    if [ -d "$WORK_DIR" ]; then
      processes_total=$(find "$WORK_DIR" -name ".command.run" | wc -l)
      processes_complete=$(find "$WORK_DIR" -name ".exitcode" | wc -l)
      
      # Calculate progress
      if [ $processes_total -gt 0 ]; then
        local percent=$((processes_complete * 100 / processes_total))
        local elapsed=$(($(date +%s) - start_time))
        
        # Format elapsed time
        local elapsed_fmt=$(date -u -d @$elapsed +"%H:%M:%S" 2>/dev/null || date -u -r $elapsed +"%H:%M:%S")
        
        echo "⏱️  Progress: ${percent}% (${processes_complete}/${processes_total} processes) - Elapsed: ${elapsed_fmt}"
        
        # Estimate remaining time if we have enough data
        if [ $percent -gt 5 ] && [ $percent -lt 100 ]; then
          local total_est=$((elapsed * 100 / percent))
          local remaining=$((total_est - elapsed))
          local remaining_fmt=$(date -u -d @$remaining +"%H:%M:%S" 2>/dev/null || date -u -r $remaining +"%H:%M:%S")
          echo "⏰ Estimated time remaining: ${remaining_fmt}"
        fi
      else
        echo "⏱️  Initializing workflow..."
      fi
    else
      echo "⏱️  Waiting for workflow to start..."
    fi
    
    # Show resource usage if trace file exists
    if [ -f "$trace_file" ]; then
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "📊 Resource Usage (Last 5 completed processes):"
      
      # Skip header and take last 5 completed processes
      if [ -s "$trace_file" ]; then
        head -n 1 "$trace_file"
        tail -n +2 "$trace_file" | tail -5
      else
        echo "No trace data available yet."
      fi
    fi
    
    # Show active processes
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔄 Running Processes:"
    find "$WORK_DIR" -name ".command.run" -newer "$WORK_DIR/.nextflow.history" 2>/dev/null | 
      grep -v ".command.log" |
      sed -E 's/.*\/([^/]+)\/([^/]+)\/.command.run/\1\/\2/' |
      head -5 || echo "No running processes found."
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Press Ctrl+C to stop monitoring (workflow will continue)"
    sleep 5
  done
}

# Start monitoring in the background
monitor_nextflow || true

# Wait for Nextflow to complete
wait $NF_PID
EXIT_CODE=$?

# Final report
clear
echo "✨ Nextflow Workflow Completed with exit code $EXIT_CODE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Reports available at:"
echo "  - HTML Report: ${LOG_DIR}/report_${TIMESTAMP}.html"
echo "  - Timeline: ${LOG_DIR}/timeline_${TIMESTAMP}.html"
echo "  - DAG visualization: ${LOG_DIR}/dag_${TIMESTAMP}.png"
echo "  - Trace file: ${LOG_DIR}/trace_${TIMESTAMP}.txt"
echo "  - Log file: ${LOG_DIR}/nextflow_${TIMESTAMP}.log"

exit $EXIT_CODE