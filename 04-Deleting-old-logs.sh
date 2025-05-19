#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

SOURCE_DIR=$1
DEST_DIR=$2
DAYS=${3:-7} # if user is not providing number of days, we are taking week as default

LOGS_FOLDER="/home/ec2-user/Expense-Project/expense-logs"
LOG_FILE=$(echo $0 | awk -F "/" '{print $NF}' | cut -d "." -f1 )
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

USAGE(){
    echo -e "$R USAGE:: $N sh 18-backup.sh <SOURCE_DIR> <DEST_DIR> <DAYS(Optional)>"
    exit 1
}

echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

mkdir -p /tmp/expense-logs

if [ $# -lt 2 ]; then
  USAGE
  if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "$SOURCE_DIR Does not exist...Please check"
    exit 1
    if [ ! -d "$DEST_DIR" ]; then
      echo -e "$DEST_DIR Does not exist...Please check"
      exit 1
    fi
  fi
fi

FILES=$(find $SOURCE_DIR -name "*.log" -mtime +$DAYS)

if [ -n "$FILES" ] # true if there are files to zip
then
    echo "Files are: $FILES"
    ZIP_FILE="$DEST_DIR/app-logs-$TIMESTAMP.zip"
    find $SOURCE_DIR -name "*.log" -mtime +$DAYS | zip -@ "$ZIP_FILE"
    if [ -f "$ZIP_FILE" ]
    then
        echo -e "Successfully created zip file for files older than $DAYS"
        while read -r filepath # here filepath is the variable name, you can give any name
        do
            echo "Deleting file: $filepath" &>>$LOG_FILE_NAME
            rm -rf $filepath
            echo "Deleted file: $filepath"
        done <<< $FILES
    else
        echo -e "$R Error:: $N Failed to create ZIP file "
        exit 1
    fi
else
    echo "No files found older than $DAYS"
fi



# # Zip log files
# echo -e "Zipping log files..."
# zip -j "$ZIP_PATH" "$SOURCE_DIR"/*.log &>/dev/null

# if [ $? -ne 0 ]; then
#   echo -e "$R Failed to create zip file. Aborting.$N"
#   exit 1
# fi

# # Upload to S3
# echo -e "Uploading $ZIP_PATH to S3..."
# aws s3 cp "$ZIP_PATH" "$DESTINATION_DIR"

# if [ $? -eq 0 ]; then
#   echo -e "$G Upload successful. Deleting original logs...$N"
#   rm -f "$SOURCE_DIR"/*.log
#   echo -e "$G Log files deleted from server.$N"
# else
#   echo -e "$R Upload failed. Logs not deleted.$N"
# fi