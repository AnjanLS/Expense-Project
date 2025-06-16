#!/bin/bash

# Color codes
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# Configurable variables
SOURCE_DIR="/home/ec2-user/Expense-Project/expense-logs"
DEST_DIR="/mnt/shared-logs"
LOG_META_DIR="/home/ec2-user/Expense-Project/archived-logs"

SCRIPT_NAME=$(basename "$0" | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOG_META_DIR/${SCRIPT_NAME}--${TIMESTAMP}.log"
DAYS=${1:-7}  # Default to 7 days if not provided

OWNER=$(stat -c '%U' "$DEST_DIR")
PERMS=$(stat -c '%a' "$DEST_DIR")

# Ensure required directories exist
mkdir -p "$DEST_DIR" "$LOG_META_DIR"

# Ensure destination directory is writable
if [ "$OWNER" != "ec2-user" ]; then
  echo "Owner is $OWNER, changing to ec2-user..."
  sudo chown ec2-user:ec2-user "$DEST_DIR"
else
  echo "Owner is already ec2-user" >> "$LOG_FILE_NAME"
fi

if [ "$PERMS" != "755" ]; then
  echo "Permissions are $PERMS, changing to 755..."
  sudo chmod 755 "$DEST_DIR"
else
  echo "Permissions already set to 755" >> "$LOG_FILE_NAME"
fi

# Check for 'zip' command
if ! command -v zip &>/dev/null; then
    echo -e "${Y}zip package not found. Installing...${N}"
    sudo dnf install zip -y &>> "$LOG_FILE_NAME"
fi

# Validate source directory
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${R}Error:${N} Source directory '$SOURCE_DIR' does not exist. Exiting."
    exit 1
fi

# Log script start
echo "Script started at: $TIMESTAMP" >> "$LOG_FILE_NAME"

# Find .log files older than $DAYS
FILES=$(find "$SOURCE_DIR" -name "*.log" -type f -mtime +"$DAYS")

if [ -n "$FILES" ]; then
    echo -e "${G}Found the following log files to archive and delete:${N}" | tee -a "$LOG_FILE_NAME"
    echo "$FILES" | tee -a "$LOG_FILE_NAME"

    ZIP_FILE="$DEST_DIR/expense-logs--${TIMESTAMP}.zip"

    # Archive files
    echo "$FILES" | zip -@ "$ZIP_FILE" >> "$LOG_FILE_NAME" 2>&1

    if [ -f "$ZIP_FILE" ]; then
        echo -e "${G}ZIP file created at:${N} $ZIP_FILE" | tee -a "$LOG_FILE_NAME"

        # Delete archived files
        while read -r filepath; do
            echo "Deleting $filepath" >> "$LOG_FILE_NAME"
            rm -f "$filepath"
        done <<< "$FILES"

        echo -e "${G}All archived files have been deleted.${N}" | tee -a "$LOG_FILE_NAME"
    else
        echo -e "${R}Error:${N} Failed to create ZIP file. No files were deleted." | tee -a "$LOG_FILE_NAME"
        exit 1
    fi
else
    echo -e "${Y}No log files older than $DAYS days found in $SOURCE_DIR.${N}" | tee -a "$LOG_FILE_NAME"
fi

# Send zip file to other servers
OTHER_SERVERS=(
  "172.31.0.8"  # Backend
  "172.31.0.5"  # Frontend
  "172.31.0.11" # Database
)

# Get local IP address (first non-loopback IP)
MY_IP=$(hostname -I | awk '{print $1}')

if [ -f "$ZIP_FILE" ]; then
  for ip in "${OTHER_SERVERS[@]}"; do
    if [ "$ip" != "$MY_IP" ]; then
      echo "Sending $ZIP_FILE to $ip..." | tee -a "$LOG_FILE_NAME"
      scp "$ZIP_FILE" "ec2-user@$ip:$DEST_DIR/" >> "$LOG_FILE_NAME" 2>&1
    fi
  done
else
  echo -e "${Y}No ZIP file to send. Skipping SCP.${N}" | tee -a "$LOG_FILE_NAME"
fi
