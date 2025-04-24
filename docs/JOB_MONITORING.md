# Job Monitoring Guide

This document explains how to use the job monitoring tools provided in this environment for tracking SLURM jobs and workflow progress.

## SLURM Job Monitoring

The `sj` command provides enhanced monitoring for SLURM jobs:

```bash
sj             # Show your running jobs
sj -a          # Show all jobs in the system
sj -m          # Show all your jobs (running, pending, etc.)
sj <job_id>    # Show detailed information for a specific job
```

### Job Creation Helper

The `create_job` function helps create new job scripts:

```bash
create_job <job_name> [cores] [memory_gb] [time_hours]
```

Example:
```bash
create_job align_genome 8 32 12
```

This creates a job script called `align_genome.sh` with:
- 8 CPU cores
- 32GB of memory 
- 12-hour time limit

### Other SLURM Aliases

```bash
sq              # Shortcut for squeue -u $USER
si              # Shortcut for sinfo
sc              # Shortcut for scancel
srun1           # Start an interactive session with 1 core, 8GB RAM, 2-hour limit
srun8           # Start an interactive session with 8 cores, 32GB RAM, 8-hour limit
```

### Job Resource Usage

Check the resource usage of a running job:

```bash
job_usage <job_id>
```

This displays CPU, memory, and other resource statistics.

## Workflow Engine Monitoring

### Snakemake Monitoring

The `snakemake_monitor.sh` script provides enhanced monitoring for Snakemake workflows:

```bash
./scripts/workflow_monitors/snakemake_monitor.sh <snakefile> [snakemake_args]
```

This will:
1. Run the Snakemake workflow with the provided arguments
2. Show real-time rule execution progress
3. Display resource usage statistics
4. Estimate completion time

### Nextflow Monitoring

For Nextflow workflows:

```bash
./scripts/workflow_monitors/nextflow_monitor.sh <nextflow_script> [nextflow_args]
```

This monitors:
- Process execution
- Resource usage per process
- Execution timeline

### WDL Monitoring

For Cromwell/WDL workflows:

```bash
./scripts/workflow_monitors/wdl_monitor.sh <wdl_file> [cromwell_args]
```

## Custom Monitoring

### Setting Up Job Notifications

To receive notifications when jobs complete:

1. Edit your ~/.zsh_work file to set notification preferences:
   ```bash
   # Email notifications (uncomment and customize)
   # export JOB_NOTIFY_EMAIL="your.email@example.com"
   
   # Terminal notifications (if using a local terminal)
   export JOB_NOTIFY_TERMINAL=true
   ```

2. Submit jobs using the notification wrapper:
   ```bash
   sbatch-notify myjob.sh
   ```

### Integration with tmux

For long-running jobs, you can monitor them in a dedicated tmux pane:

```bash
# Start monitoring in the current tmux session
monitor_in_tmux <job_id>

# Or create a new dedicated monitoring session
tmux_monitor <job_id>
```

## Advanced Monitoring Options

### Resource Usage Tracking

To track and visualize resource usage over time:

```bash
job_history          # Show resource usage of your recent jobs
job_stats <job_type> # Analyze performance of similar jobs
```

### Pipeline-Specific Monitors

For specific bioinformatics workflows, use the dedicated monitors:

```bash
monitor_alignment <ref_genome> <input_files>
monitor_variant_calling <ref_genome> <bam_files>
```

These provide domain-specific insights and optimizations.