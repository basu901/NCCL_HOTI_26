#!/bin/bash

#Provide the id_rsa.pub as the second arg
FILE_TO_TRANSFER=$2

#This file reads the IP addresses from the file provided as the first args and sends the same file to the nodes
IFS=','

declare -a IP
declare -a KEY

while read -r line || [[ -n "$line" ]]; do
    read -r -a parts <<< "$line"
    IP+=("${parts[0]}")
    KEY+=("${parts[1]}")
done < $1

declare WORKER_1_IP=${IP[0]}
declare WORKER_2_IP=${IP[1]}
declare WORKER_3_IP=${IP[2]}

echo "IPs:"
echo "${WORKER_1_IP}"
echo "${WORKER_2_IP}"
echo "${WORKER_3_IP}"


declare WORKER_1_KEY=${KEY[0]}
declare WORKER_2_KEY=${KEY[1]}
declare WORKER_3_KEY=${KEY[2]}

echo "KEYS:"
echo "${WORKER_1_KEY}"
echo "${WORKER_2_KEY}"
echo "${WORKER_3_KEY}"

# Slave 1 details
WORKER_1="ec2-user@${WORKER_2_IP}"
WORKER_1_KEY="/home/ec2-user/.ssh/worker1.pem"  # Private key on master node

# Slave 2 details
WORKER_2="ec2-user@${WORKER_3_IP}"
WORKER_2_KEY="/home/ec2-user/.ssh/worker2.pem"  # Private key on master node

# File destination path
DESTINATION="/home/ec2-user/"

# Transfer to Slave 1
echo "Transferring $FILE_TO_TRANSFER to Worker 1 ($WORKER_1)..."
scp -i $WORKER_1_KEY $FILE_TO_TRANSFER $WORKER_1:$DESTINATION
if [ $? -eq 0 ]; then
    echo "Transfer to Worker 1 successful."
else
    echo "Transfer to Worker 1 failed."
fi

# Transfer to Slave 1
echo "Transferring $FILE_TO_TRANSFER to Worker 2 ($WORKER_2)..."
scp -i $WORKER_2_KEY $FILE_TO_TRANSFER $WORKER_2:$DESTINATION
if [ $? -eq 0 ]; then
    echo "Transfer to Worker 2 successful."
else
    echo "Transfer to Worker 2 failed."
fi