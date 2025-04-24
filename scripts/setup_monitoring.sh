#!/usr/bin/env bash
# Job monitoring tools setup
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/bioinf-cli-env/monitoring"
mkdir -p "$BIN_DIR" "$CONFIG_DIR"

echo "📊 Setting up job monitoring tools..."

# Create Snakemake monitoring script
cat > "$BIN_DIR/snakemonitor" << 'ENDSNAKE'
#!/usr/bin/env bash
# Snakemake job monitoring tool

# Default values
INTERVAL=10
LOGFILE="logs/snakemake.log"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--interval)
      INTERVAL="$2"
      shift 2
      ;;
    -l|--log)
      LOGFILE="$2"
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

if [[ ! -f "$LOGFILE" ]]; then
  echo "Error: Log file not found: $LOGFILE"
  echo "Usage: snakemonitor [-i interval] [-l logfile]"
  exit 1
fi

echo "Monitoring Snakemake log: $LOGFILE (refreshing every ${INTERVAL}s)"
echo "Press Ctrl+C to exit"

while true; do
  clear
  echo "=== Snakemake Status ==="
  echo "Last updated: $(date)"
  echo ""
  
  # Parse and display job status
  if grep -q "Finished job" "$LOGFILE"; then
    TOTAL=$(grep -c "rule " "$LOGFILE")
    COMPLETED=$(grep -c "Finished job" "$LOGFILE")
    RUNNING=$(($(grep -c "Submitted job" "$LOGFILE") - $COMPLETED))
    RUNNING=$([[ $RUNNING -lt 0 ]] && echo 0 || echo $RUNNING)
    PERCENT=$(( $COMPLETED * 100 / $TOTAL ))
    
    echo "Progress: $COMPLETED/$TOTAL jobs completed ($PERCENT%)"
    echo "Currently running: $RUNNING jobs"
    
    # Display last 5 completed jobs
    echo ""
    echo "Last 5 completed jobs:"
    grep "Finished job" "$LOGFILE" | tail -n 5
    
    # Display any recent errors
    echo ""
    echo "Recent errors (if any):"
    grep -A 2 "Error" "$LOGFILE" | tail -n 10
  else
    echo "No jobs completed yet. Check if Snakemake is running."
    echo ""
    echo "Log file exists but no completed jobs found."
  fi
  
  sleep $INTERVAL
done
ENDSNAKE

# Create Nextflow monitoring script
cat > "$BIN_DIR/nextflow_monitor" << 'ENDNF'
#!/usr/bin/env bash
# Nextflow job monitoring tool

# Default values
INTERVAL=10
WORK_DIR="work"
RUN_NAME=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--interval)
      INTERVAL="$2"
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
    *)
      break
      ;;
  esac
done

# Find the .nextflow.log file
if [[ -n "$RUN_NAME" ]]; then
  LOG_FILE=".nextflow.log.$RUN_NAME"
else
  LOG_FILE=".nextflow.log"
fi

if [[ ! -f "$LOG_FILE" ]]; then
  echo "Error: Nextflow log file not found: $LOG_FILE"
  echo "Usage: nextflow_monitor [-i interval] [-w work_dir] [-r run_name]"
  exit 1
fi

echo "Monitoring Nextflow run: $LOG_FILE (refreshing every ${INTERVAL}s)"
echo "Press Ctrl+C to exit"

while true; do
  clear
  echo "=== Nextflow Status ==="
  echo "Last updated: $(date)"
  echo ""
  
  # Parse and display job status
  SUBMITTED=$(grep -c "Submitted process" "$LOG_FILE" 2>/dev/null || echo 0)
  COMPLETED=$(grep -c "Cached process" "$LOG_FILE" 2>/dev/null || echo 0)
  COMPLETED=$((COMPLETED + $(grep -c "Completed process" "$LOG_FILE" 2>/dev/null || echo 0)))
  
  if [[ $SUBMITTED -gt 0 ]]; then
    PERCENT=$(( $COMPLETED * 100 / $SUBMITTED ))
    echo "Progress: $COMPLETED/$SUBMITTED processes completed ($PERCENT%)"
    
    # Count processes by status
    RUNNING=$((SUBMITTED - COMPLETED))
    echo "Currently running: $RUNNING processes"
    
    # Display last 5 completed processes
    echo ""
    echo "Last 5 completed processes:"
    grep -E "Cached process|Completed process" "$LOG_FILE" | tail -n 5
    
    # Display any recent errors
    echo ""
    echo "Recent errors (if any):"
    grep -A 2 "ERROR" "$LOG_FILE" | tail -n 10
    
    # Display resource usage if available
    if [[ -d "$WORK_DIR" ]]; then
      echo ""
      echo "Process resource usage (sample):"
      find "$WORK_DIR" -name ".command.trace" -type f | head -n 3 | xargs cat 2>/dev/null | column -t
    fi
  else
    echo "No processes submitted yet. Check if Nextflow is running."
  fi
  
  sleep $INTERVAL
done
ENDNF

# Make scripts executable
chmod +x "$BIN_DIR/snakemonitor" "$BIN_DIR/nextflow_monitor"

# Create SLURM monitoring script if on a SLURM cluster
if command -v squeue &>/dev/null; then
  cat > "$BIN_DIR/slurmtop" << 'ENDSLURM'
#!/usr/bin/env bash
# SLURM jobs monitoring dashboard

# Default values
INTERVAL=10
USER_FILTER="${USER}"
PARTITION=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--interval)
      INTERVAL="$2"
      shift 2
      ;;
    -u|--user)
      USER_FILTER="$2"
      shift 2
      ;;
    -p|--partition)
      PARTITION="-p $2"
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

echo "Monitoring SLURM jobs for user: $USER_FILTER (refreshing every ${INTERVAL}s)"
echo "Press Ctrl+C to exit"

while true; do
  clear
  echo "=== SLURM Status Dashboard ==="
  echo "Last updated: $(date)"
  echo ""
  
  # Show partition status if sinfo is available
  if command -v sinfo &>/dev/null; then
    echo "Partition Status:"
    sinfo --summarize
    echo ""
  fi
  
  # Show jobs for user
  echo "Your Jobs:"
  if [[ -z "$PARTITION" ]]; then
    squeue -u "$USER_FILTER" -o "%.18i %.9P %.8j %.8u %.2t %.10M %.6D %R"
  else
    squeue -u "$USER_FILTER" $PARTITION -o "%.18i %.9P %.8j %.8u %.2t %.10M %.6D %R"
  fi
  
  # Show recently completed jobs
  echo ""
  echo "Recently Completed Jobs:"
  sacct -u "$USER_FILTER" --starttime=$(date -d "1 day ago" +%Y-%m-%d) -o "JobID,JobName,Partition,State,Elapsed,CPUTime,MaxRSS,NodeList" | head -n 10
  
  # Show job efficiency if possible
  echo ""
  echo "Job Efficiency (CPU/Memory utilization):"
  seff $(squeue -u "$USER_FILTER" -h -o "%i" | head -n 5) 2>/dev/null | grep -E "(Job|State|Efficiency)" || echo "No data available (seff command required)"
  
  sleep $INTERVAL
done
ENDSLURM

  chmod +x "$BIN_DIR/slurmtop"
  echo "✅ SLURM monitoring dashboard installed."
fi

echo "✅ Job monitoring tools setup complete!"
