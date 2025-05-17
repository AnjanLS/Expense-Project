#!/bin/bash

export HOME=/home/ec2-user # using sudo sh script.sh, the script runs as root, but SSH keys are in /home/ec2-user/.ssh

USERID=$(id -u)    #check the user id 

R="\e[31m"
G="\e[32m"
Y="\e[33m"
P="\e[35m"
N="\e[0m"

LOGS_FOLDER="/home/ec2-user/Expense-Project/expense-logs"
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

mkdir -p $LOGS_FOLDER
echo "script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Disabling existing default nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "Enabling  nodejs-20"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing  nodejs"

# useradd expense &>>$LOG_FILE_NAME
# VALIDATE $? "creating a new user expense"
if id expense &>/dev/null; then
  echo -e "User 'expense' already exists... $P SKIPPING $N" &>>$LOG_FILE_NAME
else
  useradd expense &>>$LOG_FILE_NAME
  VALIDATE $? "Creating a new user 'expense'"
fi

mkdir -p /app 
VALIDATE $? "creating a new dir /app"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading packages"

cd /app
VALIDATE $? "changing dir to /app"

rm -rf /app/*
VALIDATE $? "removing previous packages and download new zip package"

unzip /tmp/backend.zip &>>$LOG_FILE_NAME
VALIDATE $? "unziping the download zip package"

npm install &>>$LOG_FILE_NAME
VALIDATE $? "Installing dependencies"

cp /home/ec2-user/Expense-Project/backend.service /etc/systemd/system/backend.service &>>$LOG_FILE_NAME
VALIDATE $? "copying the data to the path"

#prepare mysql schema

dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing mysql Client"

mysql -h mysql.anjansriram.shop -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
VALIDATE $? "Setting-up the transaction schema and tables"

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "Daemon reload" 

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enabiling backend"

systemctl restart backend &>>$LOG_FILE_NAME
VALIDATE $? "Restarting backend"

systemctl status backend &>>$LOG_FILE_NAME
VALIDATE $? "Checking status backend"

netstat -lntp &>>$LOG_FILE_NAME #Active Internet connections
ps -ef | grep node &>>$LOG_FILE_NAME #current running process for nodejs

# Define the private IPs (or internal DNS names) of all servers
OTHER_SERVERS=(
    "ec2-user@172.31.0.11"  # Database
    "ec2-user@172.31.0.5"  # Frontend 
)

# Copy logs from each server
for server in "${OTHER_SERVERS[@]}"; do
  echo "Fetching logs from $server..."
  sudo -u ec2-user scp "$server":"$LOGS_FOLDER/"*.log "$LOGS_FOLDER/" 2>/dev/null
done

echo "Logs from all servers are now in: $LOGS_FOLDER"