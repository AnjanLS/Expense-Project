#!/bin/bash

# Color codes
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# Configurable variables
SOURCE_DIR="/home/ec2-user/Expense-Project/expense-logs"
DEST_DIR="/tmp/expense-logs"
LOG_FILE=$(basename "$0" | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOG_FILE--$TIMESTAMP.log"
DAYS=${1:-7} # Default to 7 days if not provided

# Ensure destination directory exists
mkdir -p "$DEST_DIR"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${R}Error:${N} SOURCE_DIR '$SOURCE_DIR' does not exist. Please check the path."
    exit 1
fi

# Check if destination directory exists
if [ ! -d "$DEST_DIR" ]; then
    echo -e "${R}Error:${N} DEST_DIR '$DEST_DIR' does not exist. Please check the path."
    exit 1
fi

# Logging start
echo "Script started at: $TIMESTAMP" &>> "$LOG_FILE_NAME"

# Find log files older than $DAYS
FILES=$(find "$SOURCE_DIR" -name "*.log" -mtime +"$DAYS")

if [ -n "$FILES" ]; then
    echo -e "${G}Found the following files to archive:${N}" &>> "$LOG_FILE_NAME"
    echo "$FILES" &>> "$LOG_FILE_NAME"
    ZIP_FILE="$DEST_DIR/expense-logs--$TIMESTAMP.zip"
    
    # Archive files
    echo "$FILES" | zip -@ "$ZIP_FILE" &>> "$LOG_FILE_NAME"
    
    if [ -f "$ZIP_FILE" ]; then
        echo -e "${G}ZIP file created successfully:${N} $ZIP_FILE"
        
        # Delete the archived files
        while read -r filepath; do
            echo "Deleting $filepath" &>> "$LOG_FILE_NAME"
            rm -f "$filepath"
        done <<< "$FILES"

        echo -e "${G}Deleted all archived log files.${N}"
    else
        echo -e "${R}Error:${N} Failed to create ZIP file" &>> "$LOG_FILE_NAME"
        exit 1
    fi
else
    echo -e "${Y}No log files older than $DAYS days found.${N}"
fi
