# Job Monitoring Guide

This guide provides detailed information about using the job monitoring tools
included in the bioinformatics CLI environment.

## SLURM Job Monitoring

### Enhanced Job Status (`sj`)

The `sj` command provides an enhanced view of your SLURM jobs:

```bash
# View your jobs
sj

# View all jobs in the system
sj -a

# View detailed information for a specific job
sj <job_id>
```

### Interactive Sessions

Quick interactive session commands:

```bash
# Start a session with 1 core and 8GB RAM
srun1

# Start a session with 8 cores and 32GB RAM
srun8
```

### Job Creation

Create job scripts with standard configurations:

```bash
# Create a basic job script
create_job myjob 4 16 24  # 4 cores, 16GB RAM, 24 hours

# Submit with notifications
sbatch-notify myjob.sh
```

## Workflow Monitoring

### Snakemake Monitoring

Monitor Snakemake workflow progress:

```bash
# Monitor a running workflow
snakemonitor -l <snakemake.log>

# Enable notifications
snakemonitor -l <snakemake.log> -n
```

### Nextflow Monitoring

Track Nextflow pipeline execution:

```bash
# Monitor current workflow
nextflow-monitor

# Monitor specific run
nextflow-monitor -r <run_name>
```

### WDL/Cromwell Monitoring

Monitor WDL workflow execution:

```bash
# Monitor workflows in default directory
wdl-monitor

# Monitor specific directory
wdl-monitor -d /path/to/cromwell/logs
```

## Resource Monitoring

### System Resource Tracking

All monitoring tools track:

- CPU usage
- Memory utilization
- Disk I/O
- Network activity

### Configuration

Edit `~/.config/bioinf-cli-env/monitoring/monitor.conf`:

```bash
# Update frequency (seconds)
UPDATE_INTERVAL=10

# Warning thresholds
MEMORY_WARN=90
CPU_WARN=95

# Log settings
LOG_DIR=/path/to/logs
LOG_RETENTION=7
```

## Notifications

### Desktop Notifications

Enable desktop notifications with the `-n` flag:

```bash
snakemonitor -n
nextflow-monitor -n
wdl-monitor -n
```

### Email Notifications

Configure email notifications in your environment:

```bash
export JOB_NOTIFY_EMAIL="your.email@example.com"
```

## Advanced Features

### TMux Integration

Monitor jobs in TMux sessions:

```bash
# Monitor in new pane
monitor_in_tmux <job_id>

# Monitor in new session
tmux_monitor <job_id>
```

### Custom Triggers

Set up custom actions on job events in `~/.config/bioinf-cli-env/monitoring/triggers.sh`:

```bash
on_job_complete() {
    local job_id="$1"
    local status="$2"
    # Your custom actions here
}
```
