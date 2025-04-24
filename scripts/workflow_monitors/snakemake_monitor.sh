#!/usr/bin/env bash
# Enhanced monitoring script for Snakemake workflows
set -euo pipefail
IFS=$'\n\t'

# Show usage if no arguments are provided
if [ $# -lt 1 ]; then
  echo "Usage: $(basename $0) <snakefile> [snakemake_args]"
  echo "Examples:"
  echo "  $(basename $0) Snakefile --cores 4"
  echo "  $(basename $0) workflow/Snakefile --profile slurm"
  exit 1
fi

SNAKEFILE=$1
shift
ARGS=("$@")

# Create log files
LOG_DIR="${HOME}/.logs/snakemake"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOGFILE="${LOG_DIR}/snakemake_${TIMESTAMP}.log"
STATSFILE="${LOG_DIR}/snakemake_${TIMESTAMP}.stats"

echo "🐍 Running Snakemake with enhanced monitoring..."
echo "📝 Logs: ${LOGFILE}"
echo "📊 Stats: ${STATSFILE}"

# Run Snakemake with stats output
snakemake -s "$SNAKEFILE" --stats "$STATSFILE" "${ARGS[@]}" 2>&1 | tee "$LOGFILE" &
SNAKE_PID=$!

# Function to estimate completion time
function estimate_completion() {
  local completed=$(grep -c "^[0-9].*done$" "$LOGFILE")
  local total=$(grep -c "^[0-9]" "$LOGFILE" || echo "0")
  
  if [ "$total" -eq 0 ]; then
    echo "Waiting for jobs to start..."
    return
  fi
  
  if [ "$completed" -eq 0 ]; then
    echo "0% complete - estimating..."
    return
  fi
  
  local percent=$((completed * 100 / total))
  local elapsed=$(($(date +%s) - starttime))
  
  if [ "$percent" -eq 0 ]; then
    echo "0% complete - estimating..."
    return
  fi
  
  local total_est=$((elapsed * 100 / percent))
  local remaining=$((total_est - elapsed))
  
  # Format times
  local elapsed_fmt=$(date -u -d @$elapsed +"%H:%M:%S" 2>/dev/null || date -u -r $elapsed +"%H:%M:%S")
  local remaining_fmt=$(date -u -d @$remaining +"%H:%M:%S" 2>/dev/null || date -u -r $remaining +"%H:%M:%S")
  
  echo "${percent}% complete - Elapsed: ${elapsed_fmt}, Remaining: ${remaining_fmt}"
}

# Function to show resource usage
function show_resources() {
  if [ -f "$STATSFILE" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Resource Usage Summary (Top 5 Rules):"
    # This works for Snakemake stats format (tab-delimited)
    head -1 "$STATSFILE"
    sed 1d "$STATSFILE" | sort -k3,3 -nr | head -5
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  fi
}

# Monitor Snakemake execution
starttime=$(date +%s)
(
  while kill -0 $SNAKE_PID 2>/dev/null; do
    clear
    echo "🐍 Snakemake Workflow Monitor"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Show status and progress
    echo "⏱️  $(estimate_completion)"
    
    # Show resource usage
    show_resources
    
    # Show recent log activity
    echo "📝 Recent Activity:"
    tail -10 "$LOGFILE" | grep -v "^\s*$" | cut -c 1-80
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Press Ctrl+C to stop monitoring (workflow will continue)"
    sleep 5
  done
) || true

wait $SNAKE_PID
EXIT_CODE=$?

# Final report
clear
echo "🐍 Snakemake Workflow Completed with exit code $EXIT_CODE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
show_resources
echo "Total runtime: $(date -u -d @$(($(date +%s) - starttime)) +"%H:%M:%S" 2>/dev/null || date -u -r $(($(date +%s) - starttime)) +"%H:%M:%S")"
echo "Log file: $LOGFILE"
echo "Stats file: $STATSFILE"

exit $EXIT_CODE