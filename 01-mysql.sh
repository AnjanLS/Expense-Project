#!/bin/bash

USERID=$(id -u)    #check the user id 

R="\e[31m"
G="\e[32m"
Y="\e[33m"
P="\e[35m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"
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

dnf list installed mysql-server -y &>>$LOG_FILE_NAME
if [ $? -ne 0 ]
then 
    dnf install mysql-server -y &>>$LOG_FILE_NAME
    VALIDATE $? "Installing mysql-server"
    systemctl enable mysqld &>>$LOG_FILE_NAME
    VALIDATE $? "Enabling mysql-server"
    systemctl start mysqld &>>$LOG_FILE_NAME
    VALIDATE $? "Starting mysql-server"
    mysql_secure_installation --set-root-pass ExpenseApp@1 &>>$LOG_FILE_NAME
    VALIDATE $? "setting root password for mysql-server"
else
    echo -e "Mysql-server... is already $Y Installed $N"
    echo -e "Mysql-server root password already setup $P SKIPPING $N"
fi

netstat -lntp &>>$LOG_FILE_NAME #Active Internet connections
ps -ef | grep mysqld &>>$LOG_FILE_NAME #current running process for mysqld
systemctl status mysqld &>>$LOG_FILE_NAME #To check the status for mysqld
mysql -h mysql.anjansriram.shop -u root -pExpenseApp@1 #command to connect mysql database
