#!/usr/bin/env bash
# Monitor alignment processes for bioinformatics workflows
# This script tracks progress of alignment jobs like BWA, Bowtie2, etc.

# Source common monitoring functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/monitor_common.sh"

# Help message
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -i, --input FILE   Input FASTQ file (required)"
    echo "  -r, --reference FILE  Reference genome file (required)"
    echo "  -o, --output DIR   Output directory for monitoring data (default: ./alignment_monitor)"
    echo "  -p, --pid PID      Process ID to monitor (if not provided, will search for alignment processes)"
    echo "  -t, --tool NAME    Alignment tool name (bwa, bowtie2, etc.) (auto-detected if not specified)"
    echo "  -n, --interval N   Monitoring interval in seconds (default: 30)"
    echo "  -h, --help         Show this help message"
    exit 1
}

# Parse command line arguments
INTERVAL=30
OUTPUT_DIR="./alignment_monitor"

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -i|--input)
            INPUT_FILE="$2"
            shift 2
            ;;
        -r|--reference)
            REFERENCE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -p|--pid)
            PROCESS_ID="$2"
            shift 2
            ;;
        -t|--tool)
            TOOL_NAME="$2"
            shift 2
            ;;
        -n|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

# Check required parameters
if [[ -z "$INPUT_FILE" || -z "$REFERENCE" ]]; then
    echo "Error: Input file and reference genome are required."
    show_help
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Auto-detect alignment tool if not specified
if [[ -z "$TOOL_NAME" && -z "$PROCESS_ID" ]]; then
    # Try to find running alignment tools
    for tool in "bwa" "bowtie2" "hisat2" "minimap2" "star"; do
        pid=$(pgrep -f "$tool" | head -1)
        if [[ -n "$pid" ]]; then
            TOOL_NAME="$tool"
            PROCESS_ID="$pid"
            echo "Auto-detected $TOOL_NAME process (PID: $PROCESS_ID)"
            break
        fi
    done
    
    if [[ -z "$TOOL_NAME" ]]; then
        echo "Warning: Could not auto-detect alignment tool. Will monitor for any new alignment processes."
    fi
elif [[ -z "$PROCESS_ID" && -n "$TOOL_NAME" ]]; then
    # Try to find specific tool
    PROCESS_ID=$(pgrep -f "$TOOL_NAME" | head -1)
    if [[ -n "$PROCESS_ID" ]]; then
        echo "Found $TOOL_NAME process (PID: $PROCESS_ID)"
    else
        echo "Warning: No running process found for $TOOL_NAME. Will monitor for new $TOOL_NAME processes."
    fi
fi

# Get input file size
INPUT_SIZE=$(get_file_size "$INPUT_FILE")
READABLE_INPUT_SIZE=$(get_readable_size "$INPUT_SIZE")
echo "Input file size: $READABLE_INPUT_SIZE"

# Get reference genome size
REFERENCE_SIZE=$(get_genome_size "$REFERENCE")
READABLE_REF_SIZE=$(get_readable_size "$REFERENCE_SIZE")
echo "Reference genome size: $READABLE_REF_SIZE"

# Start resource monitoring
start_resource_monitoring "$OUTPUT_DIR" "$INTERVAL"

# Initialize progress tracking
echo "timestamp,pid,command,progress_pct,read_count,mapped_reads,memory_usage_mb,cpu_usage" > "$OUTPUT_DIR/alignment_progress.csv"

# Main monitoring loop
echo "Starting alignment monitoring with ${INTERVAL}s intervals..."
echo "Press Ctrl+C to stop monitoring."

START_TIME=$(date +%s)
HAS_PROCESS=false

while true; do
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    
    # If we don't have a process ID yet, try to find it
    if [[ -z "$PROCESS_ID" ]]; then
        if [[ -n "$TOOL_NAME" ]]; then
            PROCESS_ID=$(pgrep -f "$TOOL_NAME" | head -1)
        else
            for tool in "bwa" "bowtie2" "hisat2" "minimap2" "star"; do
                PROCESS_ID=$(pgrep -f "$tool" | head -1)
                if [[ -n "$PROCESS_ID" ]]; then
                    TOOL_NAME="$tool"
                    echo "Detected $TOOL_NAME process (PID: $PROCESS_ID)"
                    break
                fi
            done
        fi
        
        if [[ -n "$PROCESS_ID" ]]; then
            HAS_PROCESS=true
        fi
    else
        # Check if process still exists
        if ! ps -p "$PROCESS_ID" > /dev/null; then
            if $HAS_PROCESS; then
                echo "Process (PID: $PROCESS_ID) has completed."
                break
            else
                # Reset PID and continue looking
                PROCESS_ID=""
                continue
            fi
        else
            HAS_PROCESS=true
        fi
    fi
    
    if [[ -n "$PROCESS_ID" ]]; then
        # Get command line
        COMMAND=$(ps -o command= -p "$PROCESS_ID" | head -1)
        
        # Get memory usage (RSS) in MB
        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS
            MEM_USAGE=$(ps -o rss= -p "$PROCESS_ID" | awk '{print $1/1024}')
        else
            # Linux
            MEM_USAGE=$(ps -o rss= -p "$PROCESS_ID" | awk '{print $1/1024}')
        fi
        
        # Get CPU usage
        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS
            CPU_USAGE=$(ps -o %cpu= -p "$PROCESS_ID" | tr -d ' ')
        else
            # Linux
            CPU_USAGE=$(ps -o %cpu= -p "$PROCESS_ID" | tr -d ' ')
        fi
        
        # Try to get progress by checking output SAM/BAM files
        # This is tool-specific logic
        PROGRESS_PCT=0
        READ_COUNT=0
        MAPPED_READS=0
        
        # Look for potential output files (BAM or SAM)
        potential_outputs=$(find . -name "*.bam" -o -name "*.sam" -mmin -30 2>/dev/null)
        
        if [[ -n "$potential_outputs" ]]; then
            for output_file in $potential_outputs; do
                # Check if samtools is available
                if command -v samtools &> /dev/null; then
                    # Get read count from BAM/SAM file
                    if [[ "$output_file" == *.bam ]]; then
                        tmp_count=$(samtools view -c "$output_file" 2>/dev/null)
                        if [[ -n "$tmp_count" && "$tmp_count" -gt "$READ_COUNT" ]]; then
                            READ_COUNT=$tmp_count
                            # Get mapped reads
                            MAPPED_READS=$(samtools view -c -F 4 "$output_file" 2>/dev/null)
                            
                            # Estimate total reads based on input file
                            # Assuming 4 lines per read in FASTQ
                            ESTIMATED_TOTAL_READS=$((INPUT_SIZE / 400))  # rough estimate
                            if [[ "$ESTIMATED_TOTAL_READS" -gt 0 ]]; then
                                PROGRESS_PCT=$((READ_COUNT * 100 / ESTIMATED_TOTAL_READS))
                                # Sanity check
                                if [[ "$PROGRESS_PCT" -gt 100 ]]; then
                                    PROGRESS_PCT=99
                                fi
                            fi
                        fi
                    fi
                fi
            done
        fi
        
        # Display progress
        echo -ne "\rProgress: ${PROGRESS_PCT}% | Reads processed: ${READ_COUNT} | Mapped reads: ${MAPPED_READS} | Memory: ${MEM_USAGE} MB | CPU: ${CPU_USAGE}%"
        
        # Save to CSV
        echo "$TIMESTAMP,$PROCESS_ID,\"$COMMAND\",$PROGRESS_PCT,$READ_COUNT,$MAPPED_READS,$MEM_USAGE,$CPU_USAGE" >> "$OUTPUT_DIR/alignment_progress.csv"
    else
        echo -ne "\rWaiting for alignment process to start..."
    fi
    
    sleep "$INTERVAL"
done

# Stop resource monitoring
stop_resource_monitoring "$OUTPUT_DIR"

echo ""
echo "Alignment monitoring completed."
echo "Monitoring data saved to: $OUTPUT_DIR"