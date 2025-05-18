#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

SOURCE_DIR="/home/ec2-user/Expense-Project/expense-logs"
DESTINATION_DIR="s3://app1-expense-project-anjansriram.com/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%d-%m-%Y-%H-%M-%S)
LOG_FILE_NAME="$SOURCE_DIR/$LOG_FILE-$TIMESTAMP.log"
TMP_DIR="/tmp"

echo "script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

if [ ! -d $SOURCE_DIR ]; then
    echo -e "$SOURCE_DIR does not exist... please check it."
    exit 1
    if [ ! -d $DESTINATION_DIR ]; then
        echo -e "$DESTINATION_DIR does not exist... please check it."
        exit 1
    fi
fi

# Create zip archive of log files
echo -e "Zipping log files..."
zip -j "$TMP_DIR/$LOG_FILE_NAME" "$SOURCE_DIR"/*.log &>/dev/null

if [ $? -ne 0 ]; then
  echo -e "$R Failed to create zip file. Aborting.$N"
  exit 1
fi

# Upload to S3
echo -e "Uploading $LOG_FILE_NAME to S3..."
aws s3 cp "$TMP_DIR/$LOG_FILE_NAME" "$DESTINATION_DIR"

if [ $? -eq 0 ]; then
  echo -e "$G Upload successful. Deleting original logs...$N"
  rm -f "$SOURCE_DIR"/*.log
  echo -e "$G Log files deleted from server.$N"
else
  echo -e "$R Upload failed. Logs not deleted.$N"
fi



# FILES=$(find $SOURCE_DIR -name "*.log" -mtime +$DAYS)

# if [ -n $FILES ]; then
#     echo "FILES are: $FILES"
#     ZIP_FILE="$DESTINATION_DIR-$TIMESTAMP.zip"
#     find $SOURCE_DIR -name "*.log" -mtime +$DAYS | zip @ "$ZIP_FILE"
#     if [ -f "$ZIP_FILE" ]; then
#         echo -e "Successfully created zip file for the files older than $DAYS"
#         while read -r file
#         do
#             echo "Deleting File: $file"
#             rm -rf $file
#         done <<< $FILES
#     else
#         echo -e "$R ERROR:: $N Failed to create zip file"
#         exit 1
#     fi
# else
#     echo "No files found older than $DAYS"
# fi
