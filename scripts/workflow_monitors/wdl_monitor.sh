#!/usr/bin/env bash
# Enhanced monitoring script for WDL workflows using Cromwell
set -euo pipefail
IFS=$'\n\t'

# Show usage if no arguments are provided
if [ $# -lt 1 ]; then
  echo "Usage: $(basename $0) <wdl_file> [cromwell_args]"
  echo "Examples:"
  echo "  $(basename $0) workflow.wdl"
  echo "  $(basename $0) workflow.wdl -i inputs.json"
  exit 1
fi

WDL_FILE=$1
shift
ARGS=("$@")

# Check for Cromwell JAR
CROMWELL_JAR=${CROMWELL_JAR:-"cromwell.jar"}
if ! command -v cromwell &>/dev/null && [ ! -f "$CROMWELL_JAR" ]; then
  echo "❌ Cromwell not found. Either:"
  echo "  1. Install Cromwell and add it to your PATH, or"
  echo "  2. Download the cromwell.jar to the current directory, or"
  echo "  3. Set the CROMWELL_JAR environment variable to the Cromwell JAR location"
  exit 1
fi

# Create log directory
LOG_DIR="${HOME}/.logs/wdl"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CROMWELL_OUTPUT="${LOG_DIR}/cromwell_${TIMESTAMP}"
mkdir -p "$CROMWELL_OUTPUT"

# Prepare actual run command
if command -v cromwell &>/dev/null; then
  RUN_CMD=("cromwell" "run" "$WDL_FILE" "-o" "$CROMWELL_OUTPUT")
else
  RUN_CMD=("java" "-jar" "$CROMWELL_JAR" "run" "$WDL_FILE" "-o" "$CROMWELL_OUTPUT")
fi

# Add any additional arguments
for arg in "${ARGS[@]}"; do
  RUN_CMD+=("$arg")
done

echo "🧬 Running WDL workflow with enhanced monitoring..."
echo "📂 Output directory: ${CROMWELL_OUTPUT}"

# Start Cromwell in the background
"${RUN_CMD[@]}" > "${CROMWELL_OUTPUT}/cromwell.log" 2>&1 &
CROMWELL_PID=$!

# Function to monitor Cromwell execution by polling its files
monitor_cromwell() {
  local start_time=$(date +%s)
  local workflow_id=""
  local status="Initializing"
  local outputs_file="${CROMWELL_OUTPUT}/outputs.json"
  
  while kill -0 $CROMWELL_PID 2>/dev/null; do
    clear
    echo "🧬 WDL Workflow Monitor"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Calculate elapsed time
    local elapsed=$(($(date +%s) - start_time))
    local elapsed_fmt=$(date -u -d @$elapsed +"%H:%M:%S" 2>/dev/null || date -u -r $elapsed +"%H:%M:%S")
    
    # Try to get workflow ID from logs
    if [ -z "$workflow_id" ]; then
      workflow_id=$(grep -o "started workflow \w\+-\w\+-\w\+-\w\+-\w\+" "${CROMWELL_OUTPUT}/cromwell.log" 2>/dev/null | 
                   sed 's/started workflow //' | 
                   tail -1)
    fi
    
    # Try to determine workflow status
    if [ -n "$workflow_id" ]; then
      # Check if the workflow has metadata
      if [ -f "${CROMWELL_OUTPUT}/metadata.json" ]; then
        status=$(grep -o '"status":"\w\+"' "${CROMWELL_OUTPUT}/metadata.json" 2>/dev/null | 
                sed 's/"status":"//;s/"//' | 
                tail -1 || echo "Running")
      fi
      
      echo "⏱️  Workflow: ${workflow_id}"
      echo "📋 Status: ${status} - Elapsed: ${elapsed_fmt}"
    else
      echo "⏱️  Initializing workflow... Elapsed: ${elapsed_fmt}"
    fi
    
    # Show call status if metadata file exists
    if [ -f "${CROMWELL_OUTPUT}/metadata.json" ]; then
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "📊 Call Status:"
      
      # Extract call information with jq if available
      if command -v jq &>/dev/null; then
        jq -r '.calls | to_entries[] | "\(.key): \(.value[0].executionStatus)"' "${CROMWELL_OUTPUT}/metadata.json" 2>/dev/null |
          head -10 || echo "No call information available yet."
      else
        grep -o '"executionStatus":"\w\+"' "${CROMWELL_OUTPUT}/metadata.json" 2>/dev/null |
          sed 's/"executionStatus":"//;s/"//' |
          sort |
          uniq -c |
          awk '{print $2 ": " $1 " calls"}' || echo "No call information available yet."
      fi
    fi
    
    # Show recent log activity
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 Recent Activity:"
    tail -10 "${CROMWELL_OUTPUT}/cromwell.log" 2>/dev/null | 
      grep -v "^\s*$" | 
      cut -c 1-80 || echo "No log data available yet."
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Press Ctrl+C to stop monitoring (workflow will continue)"
    sleep 5
  done
}

# Start monitoring in the background
monitor_cromwell || true

# Wait for Cromwell to complete
wait $CROMWELL_PID
EXIT_CODE=$?

# Final report
clear
echo "🧬 WDL Workflow Completed with exit code $EXIT_CODE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Results available at: ${CROMWELL_OUTPUT}"
echo "  - Outputs: ${CROMWELL_OUTPUT}/outputs.json"
echo "  - Metadata: ${CROMWELL_OUTPUT}/metadata.json"
echo "  - Log: ${CROMWELL_OUTPUT}/cromwell.log"

exit $EXIT_CODE