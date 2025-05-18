#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

SOURCE_DIR=$1
DESTINATION_DIR=$2
DAYS=${3:-15}       #Assigning the default value to the third positional argument i.e, number of days

LOGS_FOLDER="/home/ec2-user/Expense-Project/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%d-%m-%Y-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

echo "script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

USAGE(){
    echo -e "$R USAGE:: $N sh 04-Deleting-old-logs.sh <SOURCE_DIR> <DESTINATION_DIR> <DAYS(optional)>"
}

if [ $# -lt 2 ]; then
    USAGE
    exit 1
    if [ ! -d $SOURCE_DIR ]; then
        echo -e "$SOURCE_DIR does not exist... please check it."
        exit 1
        if [ ! -d $DESTINATION_DIR ]; then
            echo -e "$DESTINATION_DIR does not exist... please check it."
            exit 1
        fi
    fi
fi


FILES=$(find $SOURCE_DIR -name "*.log" -mtime +$DAYS)

if [ -n $FILES ]; then
    echo "FILES are: $FILES"
    ZIP_FILE="$DESTINATION_DIR-$TIMESTAMP.zip"
    find $SOURCE_DIR -name "*.log" -mtime +$DAYS | zip @ "$ZIP_FILE"
    if [ -f "$ZIP_FILE" ]; then
        echo -e "Successfully created zip file for the files older than $DAYS"
        while read -r file
        do
            echo "Deleting File: $file"
            rm -rf $file
        done <<< $FILES
    else
        echo -e "$R ERROR:: $N Failed to create zip file"
        exit 1
    fi
else
    echo "No files found older than $DAYS"
fi
