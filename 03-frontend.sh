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

dnf install nginx -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing nginx"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "Removing default packages"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading zip package"

cd /usr/share/nginx/html
VALIDATE $? "Changing the directory"

unzip /tmp/frontend.zip &>>$LOG_FILE_NAME
VALIDATE $? "Unzipping the Installed package"

cp  /home/ec2-user/Expense-Project/frontend.service /etc/nginx/default.d/expense.conf &>>$LOG_FILE_NAME
VALIDATE $? "Copying data from frontend.service file to the specified path"

systemctl enable nginx
VALIDATE $? "Enabiling nginx" 

systemctl restart nginx
VALIDATE $? "Restarting nginx"

systemctl status nginx &>>$LOG_FILE_NAME
VALIDATE $? "Checking the status for nginx-web-server"

echo -e "Nginx is active. Triggering URL..." &>>$LOG_FILE_NAME

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://anjansriram.shop)
echo "HTTP status code: $HTTP_CODE" &>>$LOG_FILE_NAME

if [ "$HTTP_CODE" -ne 200 ]; then
    echo "Please attach your frontend public-IP to public domain record."
else
    echo "Congrats! You hosted your website on the Internet!"
fi

# Define the private IPs (or internal DNS names) of all servers
OTHER_SERVERS=(
    "ec2-user@172.31.0.11"  # Database
    "ec2-user@172.31.0.8"  # Backend 
)

# Copy logs from each server
for server in "${OTHER_SERVERS[@]}"; do
  echo "Fetching logs from $server..."
  sudo -u ec2-user bash -c "scp $server:$LOGS_FOLDER/*.log $LOGS_FOLDER/ 2>/dev/null"
done

echo "Logs from all servers are now in: $LOGS_FOLDER"
