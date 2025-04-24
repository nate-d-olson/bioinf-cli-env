#!/usr/bin/env bash
# Cross-system synchronization script for bioinf-cli-env
set -euo pipefail
IFS=$'\n\t'

# Configuration
CONFIG_DIR="$HOME/.config/bioinf-cli-env"
HOSTS_FILE="$CONFIG_DIR/sync_hosts"
CONFIG_FILES=(
  ".zshrc" 
  ".p10k.zsh" 
  ".nanorc" 
  ".tmux.conf" 
  ".zsh_platform" 
  ".zsh_work" 
  ".zsh_azure_llm"
  ".zsh_slurm_aliases"
)
SCRIPT_DIRS=(
  "$HOME/.local/bin"
  "$HOME/.config/bioinf-cli-env"
)

# Ensure configuration directory exists
mkdir -p "$CONFIG_DIR"

# Create hosts file if it doesn't exist
if [[ ! -f "$HOSTS_FILE" ]]; then
  cat > "$HOSTS_FILE" << 'ENDHOSTS'
# Host configuration for sync.sh
# Format: hostname [user@host]
# Comments and empty lines are ignored
# Examples:
# workstation1 user@workstation1.example.com
# cluster-login user@cluster.example.edu
ENDHOSTS
  echo "Created hosts file at $HOSTS_FILE. Please edit to add your hosts."
fi

# Helper to ask yes/no questions
ask() {
  read -p "$1 [Y/n] " yn
  [[ -z "$yn" || "$yn" != [Nn]* ]]
}

# Helper to get full host from nickname
get_host() {
  local nickname="$1"
  local host=""
  
  # If hosts file exists, try to find the host
  if [[ -f "$HOSTS_FILE" ]]; then
    host=$(grep -v "^#" "$HOSTS_FILE" | grep -w "^$nickname" | awk '{print $2}')
  fi
  
  # If not found in hosts file, use the nickname as-is
  if [[ -z "$host" ]]; then
    host="$nickname"
  fi
  
  echo "$host"
}

# Helper to list all configured hosts
list_hosts() {
  if [[ ! -f "$HOSTS_FILE" ]]; then
    echo "No hosts file found at $HOSTS_FILE"
    return
  fi
  
  echo "Configured hosts:"
  grep -v "^#" "$HOSTS_FILE" | grep -v "^$" | while read -r line; do
    nickname=$(echo "$line" | awk '{print $1}')
    host=$(echo "$line" | awk '{print $2}')
    echo "  $nickname → $host"
  done
}

# Command to sync to multiple remote hosts
sync_to_multiple() {
  local hosts=("$@")
  for host_nickname in "${hosts[@]}"; do
    local host=$(get_host "$host_nickname")
    echo "🔄 Syncing to $host_nickname ($host)..."
    sync_to_remote "$host"
    echo ""
  done
}

# Command to sync from local to remote
sync_to_remote() {
  local host="$1"
  local backup_dir="$HOME/.config/bioinf-cli-env/backups/sync.$(date +%Y%m%d%H%M%S)"
  
  echo "📦 Creating backup on $host before syncing"
  ssh "$host" "mkdir -p $backup_dir"
  
  # Sync configuration files
  for file in "${CONFIG_FILES[@]}"; do
    if [[ -f "$HOME/$file" ]]; then
      echo "  → Backing up and syncing $file to $host"
      ssh "$host" "if [[ -f $HOME/$file ]]; then mkdir -p $(dirname $backup_dir/$file); cp $HOME/$file $backup_dir/$file; fi"
      scp "$HOME/$file" "$host:$HOME/"
    fi
  done
  
  # Sync script directories
  for dir in "${SCRIPT_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
      local dirname=$(basename "$dir")
      echo "  → Syncing directory $dirname to $host"
      
      # Create target directory on remote host
      ssh "$host" "mkdir -p $dir"
      
      # Backup existing files
      ssh "$host" "if [[ -d $dir ]]; then mkdir -p $backup_dir/$dirname; cp -r $dir/* $backup_dir/$dirname/ 2>/dev/null || true; fi"
      
      # Rsync the directory (exclude temporary and backup files)
      rsync -az --exclude="*.bak" --exclude="*.tmp" --exclude="*.log" "$dir/" "$host:$dir/"
      
      # Ensure scripts are executable
      if [[ "$dirname" == "bin" ]]; then
        ssh "$host" "chmod +x $dir/* 2>/dev/null || true"
      fi
    fi
  done
  
  # Ensure the workflow monitor scripts are executable
  ssh "$host" "chmod +x $HOME/bioinf-cli-env/scripts/workflow_monitors/*.sh 2>/dev/null || true"
  
  echo "✅ Sync to $host complete."
  echo "   Backup available at $backup_dir on the remote host."
  
  # Offer to source the configuration on the remote
  if ask "Would you like to source the updated configuration on $host?"; then
    echo "Sourcing configuration on $host..."
    ssh -t "$host" "source ~/.zshrc"
    echo "Done."
  fi
}

# Command to sync from remote to local
sync_from_remote() {
  local host="$1"
  local backup_dir="$HOME/.config/bioinf-cli-env/backups/sync.$(date +%Y%m%d%H%M%S)"
  
  echo "📦 Creating local backup before syncing from $host"
  mkdir -p "$backup_dir"
  
  # Sync configuration files
  for file in "${CONFIG_FILES[@]}"; do
    if ssh "$host" "[[ -f $HOME/$file ]]"; then
      echo "  → Backing up and syncing $file from $host"
      if [[ -f "$HOME/$file" ]]; then
        mkdir -p "$(dirname "$backup_dir/$file")"
        cp "$HOME/$file" "$backup_dir/$file"
      fi
      scp "$host:$HOME/$file" "$HOME/"
    fi
  done
  
  # Sync script directories
  for dir in "${SCRIPT_DIRS[@]}"; do
    if ssh "$host" "[[ -d $dir ]]"; then
      local dirname=$(basename "$dir")
      echo "  → Syncing directory $dirname from $host"
      
      # Create local directory
      mkdir -p "$dir"
      
      # Backup existing files
      if [[ -d "$dir" ]]; then
        mkdir -p "$backup_dir/$dirname"
        cp -r "$dir"/* "$backup_dir/$dirname/" 2>/dev/null || true
      fi
      
      # Rsync the directory (exclude temporary and backup files)
      rsync -az --exclude="*.bak" --exclude="*.tmp" --exclude="*.log" "$host:$dir/" "$dir/"
      
      # Ensure scripts are executable
      if [[ "$dirname" == "bin" ]]; then
        chmod +x "$dir"/* 2>/dev/null || true
      fi
    fi
  done
  
  echo "✅ Sync from $host complete."
  echo "   Backup available at $backup_dir on your local machine."
  
  # Offer to source the configuration locally
  if ask "Would you like to source the updated configuration locally?"; then
    echo "Sourcing configuration locally..."
    source "$HOME/.zshrc"
    echo "Done."
  fi
}

# Helper to check SSH connection
check_connection() {
  local host="$1"
  echo "🔄 Testing connection to $host..."
  if ssh -q -o BatchMode=yes -o ConnectTimeout=5 "$host" exit; then
    echo "✅ Connection to $host successful."
    return 0
  else
    echo "❌ Connection to $host failed. Check your SSH configuration."
    return 1
  fi
}

# Helper to sync all hosts
sync_all() {
  local direction="$1"
  
  if [[ ! -f "$HOSTS_FILE" ]]; then
    echo "❌ No hosts file found at $HOSTS_FILE"
    echo "Please create this file with your host definitions."
    exit 1
  fi
  
  local hosts=()
  while read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^# || -z "$line" ]] && continue
    local nickname=$(echo "$line" | awk '{print $1}')
    hosts+=("$nickname")
  done < "$HOSTS_FILE"
  
  if [[ ${#hosts[@]} -eq 0 ]]; then
    echo "❌ No hosts found in $HOSTS_FILE"
    echo "Please add your hosts to this file."
    exit 1
  fi
  
  echo "Found ${#hosts[@]} hosts: ${hosts[*]}"
  
  if [[ "$direction" == "push" ]]; then
    if ask "Are you sure you want to push your local configuration to ALL hosts?"; then
      sync_to_multiple "${hosts[@]}"
    fi
  elif [[ "$direction" == "pull" ]]; then
    echo "Pull from multiple hosts isn't supported."
    echo "Please specify a single host to pull from."
    exit 1
  fi
}

# Helper to add a new host
add_host() {
  local nickname="$1"
  local hostname="$2"
  
  if [[ -z "$nickname" || -z "$hostname" ]]; then
    echo "Usage: $0 add-host <nickname> <hostname>"
    exit 1
  fi
  
  # Check if the host already exists
  if grep -q "^$nickname " "$HOSTS_FILE" 2>/dev/null; then
    if ask "Host $nickname already exists. Do you want to update it?"; then
      sed -i.bak "/^$nickname /d" "$HOSTS_FILE"
    else
      echo "Operation cancelled."
      exit 0
    fi
  fi
  
  # Add the host
  echo "$nickname $hostname" >> "$HOSTS_FILE"
  echo "✅ Added host $nickname ($hostname) to $HOSTS_FILE"
  
  # Test the connection
  check_connection "$hostname"
}

# Main logic
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 [command] [arguments]"
  echo "Commands:"
  echo "  push <host>      Push configuration to a host"
  echo "  pull <host>      Pull configuration from a host"
  echo "  --all            Push to all configured hosts"
  echo "  list-hosts       List all configured hosts"
  echo "  add-host <nick> <host> Add a new host to the configuration"
  echo "  check <host>     Check connection to a host"
  exit 1
fi

COMMAND="$1"

case "$COMMAND" in
  "push")
    if [[ $# -lt 2 ]]; then
      echo "Usage: $0 push <host>"
      exit 1
    fi
    HOST=$(get_host "$2")
    if check_connection "$HOST"; then
      if ask "Are you sure you want to push your local configuration to $HOST?"; then
        sync_to_remote "$HOST"
      fi
    fi
    ;;
    
  "pull")
    if [[ $# -lt 2 ]]; then
      echo "Usage: $0 pull <host>"
      exit 1
    fi
    HOST=$(get_host "$2")
    if check_connection "$HOST"; then
      if ask "Are you sure you want to pull configuration from $HOST to your local machine?"; then
        sync_from_remote "$HOST"
      fi
    fi
    ;;
    
  "--all")
    sync_all "push"
    ;;
    
  "list-hosts")
    list_hosts
    ;;
    
  "add-host")
    if [[ $# -lt 3 ]]; then
      echo "Usage: $0 add-host <nickname> <hostname>"
      exit 1
    fi
    add_host "$2" "$3"
    ;;
    
  "check")
    if [[ $# -lt 2 ]]; then
      echo "Usage: $0 check <host>"
      exit 1
    fi
    HOST=$(get_host "$2")
    check_connection "$HOST"
    ;;
    
  *)
    echo "Error: Unknown command '$COMMAND'."
    echo "Run $0 without arguments for usage information."
    exit 1
    ;;
esac
