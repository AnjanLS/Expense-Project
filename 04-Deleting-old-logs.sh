#!/bin/bash

USERID=$(id -u)    #check the user id 

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

SOURCE_DIR="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%d-%m-%Y-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]; then 
        echo -e "$2 is $R Failure... $N" 
        exit 1    #Failure occurs terminate the script without continuing      
    else
        echo -e "$2 is $G Success... $N"
    fi
}

CHECK_ROOT(){
    if [ $USERID -ne 0 ]; then
        echo "Error:: you must have sudo access to privilage the script."
        exit 1    #Failure occurs terminate the script without continuing
    fi
}

echo "script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

FILES_TO_DELETE=$(find $SOURCE_DIR -name ".log" -mmin +10)
echo "Files to be deleted: $FILES_TO_DELETE"

while read -r file
do
    echo "Deleting File: $file"
    rm -rf $file
done <<< $FILES_TO_DELETE