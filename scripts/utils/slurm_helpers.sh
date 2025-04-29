#!/usr/bin/env bash
# SLURM job monitoring utilities
# This file contains helper functions for SLURM job management and monitoring

# Enhanced job status command
sj() {
    local job_id=""
    local show_all=false
    local show_my_all=false

    # Parse arguments
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        job_id="$1"
    elif [[ "$1" == "-a" ]]; then
        show_all=true
    elif [[ "$1" == "-m" ]]; then
        show_my_all=true
    fi

    # Load required modules if in a module environment
    if command -v module &>/dev/null; then
        module load slurm &>/dev/null || true
    fi

    # For specific job ID - show detailed info
    if [[ -n "$job_id" ]]; then
        echo "📊 Detailed info for job $job_id:"
        scontrol show job "$job_id"
        echo -e "\n📈 Resource usage:"
        job_usage "$job_id"
        return
    fi

    # Set format for squeue output
    local format="%18i %12P %10j %8u %10T %10M %10l %5D %R"

    # For all jobs in system
    if [[ "$show_all" == true ]]; then
        echo "🖥️  All jobs in the system:"
        squeue --format="$format"
        return
    fi

    # For all my jobs (running, pending, etc.)
    if [[ "$show_my_all" == true ]]; then
        echo "👤 All jobs for user $USER:"
        squeue -u "$USER" --format="$format"
        return
    fi

    # Default: show only my running jobs
    echo "⚙️  Running jobs for user $USER:"
    squeue -u "$USER" -t RUNNING --format="$format"
}

# Job creation helper
create_job() {
    local job_name=$1
    local cores=${2:-4}
    local memory_gb=${3:-16}
    local time_hours=${4:-24}

    # Validate input
    if [[ -z "$job_name" ]]; then
        echo "❌ Error: Job name is required"
        echo "Usage: create_job <job_name> [cores] [memory_gb] [time_hours]"
        return 1
    fi

    # Add .sh extension if not present
    if [[ ! "$job_name" =~ \.sh$ ]]; then
        job_name="${job_name}.sh"
    fi

    # Check if file already exists
    if [[ -f "$job_name" ]]; then
        echo "❌ Error: File $job_name already exists"
        return 1
    fi

    # Create the job script
    cat >"$job_name" <<EOF
#!/bin/bash
#SBATCH --job-name=$(basename "$job_name" .sh)
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=$cores
#SBATCH --mem=${memory_gb}G
#SBATCH --time=${time_hours}:00:00
#SBATCH --output=%j_$(basename "$job_name" .sh).out
#SBATCH --error=%j_$(basename "$job_name" .sh).err

# Load required modules
# module load ...

# Set up environment
# export ...

# Your commands go here
echo "Job started at \$(date)"

# Add your commands here


echo "Job finished at \$(date)"
EOF

    # Make the script executable
    chmod +x "$job_name"

    echo "✅ Created job script: $job_name"
    echo "📝 Configuration:"
    echo "  - CPUs: $cores"
    echo "  - Memory: ${memory_gb}GB"
    echo "  - Time limit: ${time_hours} hours"
    echo ""
    echo "📋 Edit the script to add your commands"
}

# Job resource usage monitoring
job_usage() {
    local job_id=$1

    # Validate input
    if [[ -z "$job_id" ]]; then
        echo "❌ Error: Job ID is required"
        echo "Usage: job_usage <job_id>"
        return 1
    fi

    # Check if job exists
    if ! scontrol show job "$job_id" &>/dev/null; then
        echo "❌ Error: Job $job_id not found"
        return 1
    fi

    # Get job info
    local job_info
    job_info=$(scontrol show job "$job_id" -o)
    
    local job_state
    job_state=$(echo "$job_info" | grep -oP "JobState=\K\w+")

    if [[ "$job_state" != "RUNNING" ]]; then
        echo "⚠️  Job $job_id is not running (Status: $job_state)"
        return 0
    fi

    # Get job resource usage
    if command -v sstat &>/dev/null; then
        echo "📊 Current resource usage for job $job_id:"
        sstat --format=AveCPU,AveRSS,AveVMSize,MaxRSS,MaxVMSize,JobID -j "$job_id" -n

        echo -e "\n💾 Memory usage:"
        sstat --format=AveRSS,MaxRSS,JobID -j "$job_id" -n |
            awk '{printf "  Average: %.2f GB, Peak: %.2f GB\n", $1/1024/1024, $2/1024/1024}'

        echo "🔄 CPU usage:"
        sstat --format=AveCPU,JobID -j "$job_id" -n |
            awk '{printf "  Average: %s\n", $1}'
    else
        echo "⚠️  sstat command not available, cannot retrieve detailed usage statistics"
    fi
}

# SLURM aliases
alias sq='squeue -u $USER'
alias si='sinfo'
alias sc='scancel'
alias srun1='srun --nodes=1 --ntasks=1 --cpus-per-task=1 --mem=8G --time=2:00:00 --pty bash -i'
alias srun8='srun --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=32G --time=8:00:00 --pty bash -i'

# Job notification wrapper
sbatch-notify() {
    local job_script=$1
    shift

    # Validate input
    if [[ -z "$job_script" ]]; then
        echo "❌ Error: Job script is required"
        echo "Usage: sbatch-notify <job_script> [sbatch_args]"
        return 1
    fi

    # Check if file exists
    if [[ ! -f "$job_script" ]]; then
        echo "❌ Error: Job script $job_script not found"
        return 1
    fi

    # Submit the job
    local job_id=$(sbatch "$@" "$job_script" | awk '{print $NF}')

    if [[ -z "$job_id" ]]; then
        echo "❌ Error submitting job"
        return 1
    fi

    echo "✅ Job submitted with ID: $job_id"

    # Set up notification
    if [[ -n "$JOB_NOTIFY_EMAIL" ]]; then
        echo "📧 Email notification will be sent to $JOB_NOTIFY_EMAIL when job completes"
        # Set up email notification
        (scontrol show job "$job_id" | grep -q "JobState=COMPLETED" || test $? -eq 1) &>/dev/null
        if [[ $? -eq 0 ]]; then
            mail -s "Job $job_id completed" "$JOB_NOTIFY_EMAIL" <<<"Your SLURM job $job_id ($(basename "$job_script")) has completed."
        fi
    fi

    if [[ "$JOB_NOTIFY_TERMINAL" == "true" ]]; then
        echo "🔔 Terminal notification will be displayed when job completes"
        # Set up terminal notification
        (
            while true; do
                sleep 60
                if ! scontrol show job "$job_id" &>/dev/null; then
                    # Job no longer exists in queue
                    if command -v notify-send &>/dev/null; then
                        notify-send "SLURM Job Completed" "Job $job_id ($(basename "$job_script")) has completed"
                    elif command -v osascript &>/dev/null; then
                        osascript -e "display notification \"Job $job_id ($(basename "$job_script")) has completed\" with title \"SLURM Job Completed\""
                    fi
                    break
                fi
            done
        ) &
    fi

    return 0
}

# tmux integration for job monitoring
monitor_in_tmux() {
    local job_id=$1

    # Validate input
    if [[ -z "$job_id" ]]; then
        echo "❌ Error: Job ID is required"
        echo "Usage: monitor_in_tmux <job_id>"
        return 1
    fi

    # Check if job exists
    if ! scontrol show job "$job_id" &>/dev/null; then
        echo "❌ Error: Job $job_id not found"
        return 1
    fi

    # Check if in tmux session
    if [[ -z "$TMUX" ]]; then
        echo "❌ Error: Not in a tmux session"
        echo "Use 'tmux_monitor $job_id' instead"
        return 1
    fi

    # Create a new pane for monitoring
    tmux split-window -h "watch -n 10 'scontrol show job $job_id; echo; sstat --format=AveCPU,AveRSS,AveVMSize,MaxRSS,MaxVMSize,JobID -j $job_id -n 2>/dev/null || echo Job not running or sstat not available'"

    echo "✅ Job monitoring started in new tmux pane"
}

tmux_monitor() {
    local job_id=$1

    # Validate input
    if [[ -z "$job_id" ]]; then
        echo "❌ Error: Job ID is required"
        echo "Usage: tmux_monitor <job_id>"
        return 1
    fi

    # Check if job exists
    if ! scontrol show job "$job_id" &>/dev/null; then
        echo "❌ Error: Job $job_id not found"
        return 1
    fi

    # Create a new tmux session for monitoring
    tmux new-session -d -s "job-$job_id" "watch -n 10 'scontrol show job $job_id; echo; sstat --format=AveCPU,AveRSS,AveVMSize,MaxRSS,MaxVMSize,JobID -j $job_id -n 2>/dev/null || echo Job not running or sstat not available'"

    echo "✅ Job monitoring started in new tmux session 'job-$job_id'"
    echo "Connect to session with: tmux attach -t job-$job_id"
}

# Job history tracking
job_history() {
    echo "📜 Job history for user $USER:"

    # Get jobs from the last 7 days
    sacct -u "$USER" --starttime=$(date -d "7 days ago" +%Y-%m-%d) --format=JobID,JobName,Partition,State,Elapsed,MaxRSS,MaxVMSize,CPUTime,NodeList
}

job_stats() {
    local job_type=$1

    # Validate input
    if [[ -z "$job_type" ]]; then
        echo "❌ Error: Job type is required"
        echo "Usage: job_stats <job_type>"
        return 1
    fi

    echo "📊 Statistics for jobs of type '$job_type':"

    # Get stats for jobs with the given name pattern
    sacct -u "$USER" --starttime="$(date -d "30 days ago" +%Y-%m-%d)" --format=JobID,JobName,State,Elapsed,MaxRSS,CPUTime -j "$(sacct -u "$USER" --starttime="$(date -d "30 days ago" +%Y-%m-%d)" --format=JobID,JobName -n | grep "$job_type" | awk '{print $1}' | tr '\n' ',')"

    echo -e "\n📈 Average resource usage:"
    sacct -u "$USER" --starttime="$(date -d "30 days ago" +%Y-%m-%d)" --format=Elapsed,MaxRSS,CPUTime -n -j "$(sacct -u "$USER" --starttime="$(date -d "30 days ago" +%Y-%m-%d)" --format=JobID,JobName -n | grep "$job_type" | awk '{print $1}' | tr '\n' ',')" |
        awk 'BEGIN {count=0; time=0; rss=0} 
            {count++; split($1,t,":"); time+=(t[1]*3600+t[2]*60+t[3]); rss+=$2} 
            END {if (count>0) printf "  Jobs: %d, Avg time: %.2f hours, Avg memory: %.2f GB\n", count, time/count/3600, rss/count/1024/1024}'
}
