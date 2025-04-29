#!/usr/bin/env bash
# Enhanced SLURM job management utilities
set -euo pipefail
IFS=$'\n\t'

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/common.sh"

BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

log_info "🧬 Setting up enhanced SLURM job management utilities..."

# Create the sj command for SLURM job monitoring
cat >"$BIN_DIR/sj" <<'ENDSJ'
#!/usr/bin/env bash
# Enhanced SLURM job status monitoring

# Default: show only user's jobs
SHOW_ALL=false
SHOW_MINE_ALL=false
JOB_ID=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--all)
      SHOW_ALL=true
      shift
      ;;
    -m|--mine)
      SHOW_MINE_ALL=true
      shift
      ;;
    -h|--help)
      echo "Usage: sj [options] [job_id]"
      echo "Options:"
      echo "  -a, --all    Show all jobs from all users"
      echo "  -m, --mine   Show all your jobs (running, pending, recently completed)"
      echo "  -h, --help   Show this help message"
      echo ""
      echo "Without options, shows your running jobs."
      echo "With job_id, shows detailed information about that job."
      exit 0
      ;;
    *)
      # Assume it's a job ID
      JOB_ID="$1"
      shift
      ;;
  esac
done

# Function to format time
format_time() {
  local seconds=$1
  local days=$((seconds / 86400))
  local hours=$(((seconds % 86400) / 3600))
  local minutes=$(((seconds % 3600) / 60))
  local secs=$((seconds % 60))
  
  if [[ $days -gt 0 ]]; then
    echo "${days}d ${hours}h ${minutes}m ${secs}s"
  elif [[ $hours -gt 0 ]]; then
    echo "${hours}h ${minutes}m ${secs}s"
  elif [[ $minutes -gt 0 ]]; then
    echo "${minutes}m ${secs}s"
  else
    echo "${secs}s"
  fi
}

# Function to convert human-readable time to seconds
time_to_seconds() {
  local timestr="$1"
  local seconds=0
  
  if [[ $timestr =~ ([0-9]+)-([0-9]+):([0-9]+):([0-9]+) ]]; then
    # Format: days-hours:minutes:seconds
    local days="${BASH_REMATCH[1]}"
    local hours="${BASH_REMATCH[2]}"
    local minutes="${BASH_REMATCH[3]}"
    local secs="${BASH_REMATCH[4]}"
    seconds=$((days * 86400 + hours * 3600 + minutes * 60 + secs))
  elif [[ $timestr =~ ([0-9]+):([0-9]+):([0-9]+) ]]; then
    # Format: hours:minutes:seconds
    local hours="${BASH_REMATCH[1]}"
    local minutes="${BASH_REMATCH[2]}"
    local secs="${BASH_REMATCH[3]}"
    seconds=$((hours * 3600 + minutes * 60 + secs))
  elif [[ $timestr =~ ([0-9]+):([0-9]+) ]]; then
    # Format: minutes:seconds
    local minutes="${BASH_REMATCH[1]}"
    local secs="${BASH_REMATCH[2]}"
    seconds=$((minutes * 60 + secs))
  fi
  
  echo "$seconds"
}

# Function to calculate and display progress percentage
calculate_progress() {
  local elapsed="$1"
  local timelimit="$2"
  
  local elapsed_sec=$(time_to_seconds "$elapsed")
  local timelimit_sec=$(time_to_seconds "$timelimit")
  
  if [[ $timelimit_sec -eq 0 ]]; then
    echo "unknown"
    return
  fi
  
  local percent=$((elapsed_sec * 100 / timelimit_sec))
  if [[ $percent -gt 100 ]]; then
    percent=100
  fi
  
  # Create a progress bar
  local width=20
  local filled=$((width * percent / 100))
  local empty=$((width - filled))
  
  local bar=""
  for ((i=0; i<filled; i++)); do
    bar="${bar}█"
  done
  for ((i=0; i<empty; i++)); do
    bar="${bar}░"
  done
  
  echo -e "${percent}% [${bar}]"
}

# If a job ID was provided, display detailed information
if [[ -n "$JOB_ID" ]]; then
  echo "🔍 Detailed information for job $JOB_ID:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Get job info
  JOB_INFO=$(scontrol show job "$JOB_ID" 2>/dev/null)
  if [[ $? -ne 0 ]]; then
    # Job might be completed, check sacct
    JOB_INFO=$(sacct -j "$JOB_ID" --format=JobID,JobName,State,Elapsed,TimeLimit,NodeList,Partition,Account,AllocCPUS,AllocTRES%30 -p 2>/dev/null | grep -v "^JobID")
    if [[ -n "$JOB_INFO" ]]; then
      echo "ℹ️ Job $JOB_ID is completed or not found in running jobs."
      echo "📊 Job history:"
      
      # Parse sacct output and display in a readable format
      echo "$JOB_INFO" | while IFS="|" read -r jobid jobname state elapsed timelimit nodelist partition account alloccpus alloctres; do
        echo "  Job ID: $jobid"
        echo "  Name: $jobname"
        echo "  State: $state"
        echo "  Elapsed time: $elapsed"
        echo "  Time limit: $timelimit"
        echo "  Node(s): $nodelist"
        echo "  Partition: $partition"
        echo "  Account: $account"
        echo "  Allocated CPUs: $alloccpus"
        echo "  Resources: $alloctres"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      done
    else
      echo "❌ Job $JOB_ID not found."
    fi
    exit 0
  fi
  
  # Extract and display relevant information
  JOB_NAME=$(echo "$JOB_INFO" | grep -oP "JobName=\K[^ ]+")
  JOB_STATE=$(echo "$JOB_INFO" | grep -oP "JobState=\K[^ ]+")
  JOB_USER=$(echo "$JOB_INFO" | grep -oP "UserId=\K[^(]+")
  JOB_PARTITION=$(echo "$JOB_INFO" | grep -oP "Partition=\K[^ ]+")
  JOB_NODES=$(echo "$JOB_INFO" | grep -oP "NumNodes=\K[^ ]+")
  JOB_CORES=$(echo "$JOB_INFO" | grep -oP "NumCPUs=\K[^ ]+")
  JOB_NODELIST=$(echo "$JOB_INFO" | grep -oP "NodeList=\K[^ ]+")
  JOB_SUBMIT_TIME=$(echo "$JOB_INFO" | grep -oP "SubmitTime=\K[^ ]+")
  JOB_START_TIME=$(echo "$JOB_INFO" | grep -oP "StartTime=\K[^ ]+")
  JOB_END_TIME=$(echo "$JOB_INFO" | grep -oP "EndTime=\K[^ ]+")
  JOB_TIME_LIMIT=$(echo "$JOB_INFO" | grep -oP "TimeLimit=\K[^ ]+")
  JOB_ELAPSED=$(echo "$JOB_INFO" | grep -oP "RunTime=\K[^ ]+")
  JOB_PROGRESS=$(calculate_progress "$JOB_ELAPSED" "$JOB_TIME_LIMIT")
  JOB_WORKING_DIR=$(echo "$JOB_INFO" | grep -oP "WorkDir=\K[^ ]+")
  JOB_STDOUT=$(echo "$JOB_INFO" | grep -oP "StdOut=\K[^ ]+")
  JOB_STDERR=$(echo "$JOB_INFO" | grep -oP "StdErr=\K[^ ]+")
  
  # Display the information
  echo "  Job name: $JOB_NAME"
  echo "  State: $JOB_STATE"
  echo "  User: $JOB_USER"
  echo "  Partition: $JOB_PARTITION"
  echo "  Nodes: $JOB_NODES (NodeList: $JOB_NODELIST)"
  echo "  Cores: $JOB_CORES"
  echo "  Submit time: $JOB_SUBMIT_TIME"
  echo "  Start time: $JOB_START_TIME"
  echo "  End time: $JOB_END_TIME"
  echo "  Time limit: $JOB_TIME_LIMIT"
  echo "  Elapsed: $JOB_ELAPSED"
  echo "  Progress: $JOB_PROGRESS"
  echo "  Working directory: $JOB_WORKING_DIR"
  echo "  STDOUT: $JOB_STDOUT"
  echo "  STDERR: $JOB_STDERR"
  
  # Check if job is running, and if so, show resource usage
  if [[ "$JOB_STATE" == "RUNNING" ]]; then
    echo ""
    echo "📊 Resource usage:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Use sstat to get resource usage if available
    if command -v sstat &>/dev/null; then
      sstat --format=AveCPU,AveRSS,AveVMSize,MaxRSS,MaxVMSize -j "$JOB_ID" 2>/dev/null || echo "  Resource usage information not available."
    else
      echo "  Resource usage information not available (sstat command not found)."
    fi
  fi
  
  # If stdout/stderr files exist, show the last few lines
  if [[ -f "$JOB_STDOUT" ]]; then
    echo ""
    echo "📝 Recent STDOUT (last 5 lines):"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    tail -n 5 "$JOB_STDOUT"
  fi
  
  if [[ -f "$JOB_STDERR" && "$JOB_STDERR" != "$JOB_STDOUT" ]]; then
    echo ""
    echo "⚠️ Recent STDERR (last 5 lines):"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    tail -n 5 "$JOB_STDERR"
  fi
  
  exit 0
fi

# Show jobs based on the options
if $SHOW_ALL; then
  echo "👥 All jobs in the system:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  squeue --format="%.10i %.9P %.20j %.8u %.8T %.10M %.9l %.6D %R" | (read -r header; echo "$header"; sort -k5,5 -k1,1n)
elif $SHOW_MINE_ALL; then
  echo "👤 All your jobs (including recently completed):"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Running and pending jobs:"
  squeue -u "$USER" --format="%.10i %.9P %.20j %.8T %.10M %.9l %.6D %R" | (read -r header; echo "$header"; sort -k4,4 -k1,1n)
  
  echo ""
  echo "Recently completed jobs (last 24 hours):"
  sacct -u "$USER" --starttime="$(date -d "1 day ago" +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -v-1d +%Y-%m-%dT%H:%M:%S)" \
    --format=JobID,JobName,State,Elapsed,Partition,NCPUS,NNodes,ExitCode | grep -v "^JobID" | head -n 10
else
  echo "👤 Your running jobs:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Get and format job information
  JOBS=$(squeue -u "$USER" --format="%.10i %.9P %.20j %.8T %.10M %.9l %.6D %R" | tail -n +2)
  
  if [[ -z "$JOBS" ]]; then
    echo "No running jobs found."
  else
    # Print header
    echo "JOBID     PARTITION  NAME                 STATE     ELAPSED   TIMELIMIT NODES  NODELIST(REASON)"
    
    # Parse and enhance the output with progress information
    echo "$JOBS" | while read -r jobid partition name state elapsed timelimit nodes nodelist; do
      progress=$(calculate_progress "$elapsed" "$timelimit")
      printf "%-10s %-10s %-20s %-9s %-9s %-9s %-6s %s\n" \
             "$jobid" "$partition" "$name" "$state" "$elapsed" "$timelimit" "$nodes" "$nodelist"
      echo "  Progress: $progress"
    done
  fi
fi
ENDSJ

# Create the job template creator
cat >"$BIN_DIR/create_job" <<'ENDJOB'
#!/usr/bin/env bash
# SLURM job script generator
set -euo pipefail
IFS=$'\n\t'

# Default values
JOB_NAME=""
CORES=1
MEMORY=4
TIME=1
OUTPUT_FILE=""

# Function to show usage
show_usage() {
  echo "Usage: create_job <job_name> [cores] [memory_GB] [time_hours]"
  echo "  job_name:   Name of the job (required)"
  echo "  cores:      Number of CPU cores (default: 1)"
  echo "  memory_GB:  Memory in GB (default: 4)"
  echo "  time_hours: Time limit in hours (default: 1)"
  echo ""
  echo "Example: create_job align_genome 8 32 12"
  echo "  Creates align_genome.sh with 8 cores, 32GB RAM, 12 hour limit"
  exit 1
}

# Parse arguments
if [[ $# -lt 1 ]]; then
  show_usage
fi

JOB_NAME="$1"
OUTPUT_FILE="${JOB_NAME}.sh"

# Check if output file already exists
if [[ -f "$OUTPUT_FILE" ]]; then
  read -r -p "File $OUTPUT_FILE already exists. Overwrite? [y/N] " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Cancelled."
    exit 0
  fi
fi

# Parse optional arguments
if [[ $# -ge 2 ]]; then
  CORES="$2"
fi

if [[ $# -ge 3 ]]; then
  MEMORY="$3"
fi

if [[ $# -ge 4 ]]; then
  TIME="$4"
fi

# Format time as HH:MM:00
TIME_FMT=$(printf "%02d:%02d:00" "$TIME" "0")

# Create the job script
cat > "$OUTPUT_FILE" << EOF
#!/bin/bash
#SBATCH --job-name=${JOB_NAME}
#SBATCH --output=${JOB_NAME}_%j.out
#SBATCH --error=${JOB_NAME}_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=${CORES}
#SBATCH --mem=${MEMORY}G
#SBATCH --time=${TIME_FMT}

# Print job info
echo "Job started at \$(date)"
echo "Job ID: \$SLURM_JOB_ID"
echo "Job name: \$SLURM_JOB_NAME"
echo "Node: \$SLURM_NODELIST"
echo "CPUs: \$SLURM_CPUS_PER_TASK"
echo "Memory: ${MEMORY}G"
echo ""

# Load required modules
# module load <your_modules_here>

# Activate micromamba environment if needed
# eval "\$(micromamba shell hook -s bash)"
# micromamba activate <your_env>

# Your commands go here
echo "Add your commands here"

# Example:
# samtools index input.bam
# bwa mem -t \$SLURM_CPUS_PER_TASK reference.fa read1.fq read2.fq > output.sam

# End job
echo ""
echo "Job finished at \$(date)"
EOF

# Make the script executable
chmod +x "$OUTPUT_FILE"

echo "✅ Created job script: $OUTPUT_FILE"
echo "   Cores: $CORES"
echo "   Memory: ${MEMORY}G"
echo "   Time limit: ${TIME} hour(s)"
echo ""
echo "To submit the job:"
echo "  sbatch $OUTPUT_FILE"
ENDJOB

# Create interactive session shortcuts
cat >"$BIN_DIR/srun1" <<'ENDSRUN1'
#!/usr/bin/env bash
# Start an interactive job with 1 core, 8GB RAM, 2-hour limit

echo "🚀 Starting an interactive session with:"
echo "  - 1 CPU core"
echo "  - 8GB RAM"
echo "  - 2-hour time limit"
echo ""

# Execute srun with these parameters
srun --pty --cpus-per-task=1 --mem=8G --time=02:00:00 bash -i
ENDSRUN1

cat >"$BIN_DIR/srun8" <<'ENDSRUN8'
#!/usr/bin/env bash
# Start an interactive job with 8 cores, 32GB RAM, 8-hour limit

echo "🚀 Starting an interactive session with:"
echo "  - 8 CPU cores"
echo "  - 32GB RAM"
echo "  - 8-hour time limit"
echo ""

# Execute srun with these parameters
srun --pty --cpus-per-task=8 --mem=32G --time=08:00:00 bash -i
ENDSRUN8

# Create job notification wrapper
cat >"$BIN_DIR/sbatch-notify" <<'ENDNOTIFY'
#!/usr/bin/env bash
# Submit a job and set up notifications when it completes
set -euo pipefail
IFS=$'\n\t'

if [ $# -lt 1 ]; then
  echo "Usage: sbatch-notify <jobscript> [sbatch_args]"
  exit 1
fi

SCRIPT=$1
shift
ARGS=("$@")

# Submit the job
JOB_ID=$(sbatch "${ARGS[@]}" "$SCRIPT" | grep -oP "\d+")

if [ -z "$JOB_ID" ]; then
  echo "❌ Failed to submit job"
  exit 1
fi

echo "✅ Submitted job $JOB_ID"

# Create a notification script for this job
NOTIFY_SCRIPT="$HOME/.config/bioinf-cli-env/monitoring/job_${JOB_ID}_notify.sh"

# Create notification script
mkdir -p "$HOME/.config/bioinf-cli-env/monitoring"
cat > "$NOTIFY_SCRIPT" << EOF
#!/bin/bash
# Job completion notification for job $JOB_ID

JOB_NAME=\$(sacct -j $JOB_ID --format=JobName%30 -n | head -1 | tr -d '[:space:]')
JOB_STATE=\$(sacct -j $JOB_ID --format=State%15 -n | head -1 | tr -d '[:space:]')
JOB_ELAPSED=\$(sacct -j $JOB_ID --format=Elapsed%15 -n | head -1 | tr -d '[:space:]')
JOB_EXIT_CODE=\$(sacct -j $JOB_ID --format=ExitCode -n | head -1 | tr -d '[:space:]')

# Create notification message
MESSAGE="SLURM Job \$JOB_NAME ($JOB_ID) \$JOB_STATE"
MESSAGE="\$MESSAGE\\nElapsed: \$JOB_ELAPSED, Exit code: \$JOB_EXIT_CODE"

# Handle email notification if configured
if [ -n "\${JOB_NOTIFY_EMAIL:-}" ]; then
  echo -e "\$MESSAGE" | mail -s "SLURM Job \$JOB_NAME (\$JOB_STATE)" "\$JOB_NOTIFY_EMAIL"
fi

# Handle terminal notification if configured and available
if [ "\${JOB_NOTIFY_TERMINAL:-false}" = "true" ]; then
  if command -v osascript &>/dev/null; then
    # macOS notification
    osascript -e "display notification \"Job \$JOB_NAME ($JOB_ID) \$JOB_STATE. Exit code: \$JOB_EXIT_CODE\" with title \"SLURM Job Complete\""
  elif command -v notify-send &>/dev/null; then
    # Linux notification
    notify-send "SLURM Job Complete" "Job \$JOB_NAME ($JOB_ID) \$JOB_STATE. Exit code: \$JOB_EXIT_CODE"
  fi
fi

# Log the completion
echo "\$(date): \$MESSAGE" >> $HOME/.logs/slurm_jobs.log

# Clean up this script
rm "\$0"
EOF

chmod +x "$NOTIFY_SCRIPT"

# Set up the job dependency to trigger notification
sbatch --dependency=afterany:$JOB_ID --wrap="$NOTIFY_SCRIPT" --output=/dev/null --error=/dev/null --job-name=notify_$JOB_ID

echo "📫 Notification will be sent when job completes"
echo "  Set JOB_NOTIFY_EMAIL in ~/.zsh_work to receive email notifications"
echo "  Set JOB_NOTIFY_TERMINAL=true for desktop notifications"
ENDNOTIFY

# Make all scripts executable
chmod +x "$BIN_DIR/sj" "$BIN_DIR/create_job" "$BIN_DIR/srun1" "$BIN_DIR/srun8" "$BIN_DIR/sbatch-notify"

# Create aliases in the zsh configuration
ALIASES_FILE="$HOME/.zsh_slurm_aliases"

cat >"$ALIASES_FILE" <<'ENDALIASES'
# SLURM aliases and functions
alias sq='squeue -u $USER'
alias si='sinfo'
alias sc='scancel'

# Enhanced job monitoring
alias sja='sj -a'
alias sjm='sj -m'

# Resource monitoring for a job
job_usage() {
  if [ -z "$1" ]; then
    echo "Usage: job_usage <job_id>"
    return 1
  fi
  sstat --format=JobID,AveCPU,AveRSS,AveVMSize,MaxRSS,MaxVMSize -j "$1"
}

# Add a function to monitor a job in a tmux pane
monitor_in_tmux() {
  if [ -z "$1" ]; then
    echo "Usage: monitor_in_tmux <job_id>"
    return 1
  fi
  
  # Check if we're in a tmux session
  if [ -z "${TMUX:-}" ]; then
    echo "Not in a tmux session. Use tmux_monitor instead."
    return 1
  fi
  
  # Create a new pane and run the monitoring command
  tmux split-window -h "watch -n 10 sj $1"
}

# Create a new tmux session dedicated to monitoring a job
tmux_monitor() {
  if [ -z "$1" ]; then
    echo "Usage: tmux_monitor <job_id>"
    return 1
  fi
  
  tmux new-session -d -s "job_$1" "watch -n 10 sj $1"
  tmux attach -t "job_$1"
}

# Add a function to check job history and performance
job_history() {
  sacct -u $USER --starttime=$(date -d "7 days ago" +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d) \
    --format=JobID,JobName,Partition,Account,AllocCPUS,State,ExitCode,Elapsed,TotalCPU,MaxRSS,NodeList
}

# Function to get job stats for similar job types
job_stats() {
  if [ -z "$1" ]; then
    echo "Usage: job_stats <job_pattern>"
    echo "Example: job_stats align_"
    return 1
  fi
  
  echo "Job statistics for jobs matching '$1':"
  sacct -u $USER --starttime=$(date -d "30 days ago" +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d) \
    --format=JobID,JobName,State,Elapsed,TotalCPU,MaxRSS,AveRSS \
    | grep "$1" | sort -k 5
}
ENDALIASES

# Source the aliases file in .zshrc if not already there
if ! grep -q "zsh_slurm_aliases" "$HOME/.zshrc"; then
    echo -e "\n# SLURM job management aliases and functions" >>"$HOME/.zshrc"
    echo "[ -f \"$ALIASES_FILE\" ] && source \"$ALIASES_FILE\"" >>"$HOME/.zshrc"
fi

# Create logs directory
mkdir -p "$HOME/.logs"
touch "$HOME/.logs/slurm_jobs.log"

log_success "Enhanced SLURM job management utilities installed!"
log_info "  Use 'sj' to view and monitor jobs"
log_info "  Use 'create_job' to create job scripts"
log_info "  Use 'srun1' or 'srun8' for interactive sessions"
log_info "  Use 'sbatch-notify' to get notifications when jobs complete"
log_info ""
log_info "These tools will be available after restarting your shell or running:"
log_info "  source ~/.zshrc"
