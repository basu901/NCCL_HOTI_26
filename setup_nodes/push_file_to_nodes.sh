#!/bin/bash

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


#DRIVER details
DRIVER="ec2-user@${WORKER_1_IP}"
DRIVER_KEY_LOCAL="/Users/shaunakbasu/Documents/MPI_practise/mpi_instance_keys/${WORKER_1_KEY}"  # Private key on master node

# WORKER_1 details
WORKER_1="ec2-user@${WORKER_2_IP}"
WORKER_1_KEY_LOCAL="/Users/shaunakbasu/Documents/MPI_practise/mpi_instance_keys/${WORKER_2_KEY}"  # Private key on master node

# Slave 2 details
WORKER_2="ec2-user@${WORKER_3_IP}"
WORKER_2_KEY_LOCAL="/Users/shaunakbasu/Documents/MPI_practise/mpi_instance_keys/${WORKER_3_KEY}"  # Private key on master node

# File destination path
DESTINATION="/home/ec2-user/"


# $# holds the total number of arguments
for ((i=1; i<=$#; i++))
do
    echo "File number $i is: ${!i}"
    FILE_TO_TRANSFER=${!i}

    # Transfer to DRIVER
    echo "Transferring $FILE_TO_TRANSFER to Driver ($DRIVER)..."
    echo "scp -i ${DRIVER_KEY_LOCAL} ${FILE_TO_TRANSFER} ${DRIVER}:${DESTINATION}"
    scp -i $DRIVER_KEY_LOCAL $FILE_TO_TRANSFER $DRIVER:$DESTINATION
    if [ $? -eq 0 ]; then
        echo "Transfer to DRIVER successful."
    else
        echo "Transfer to DRIVER failed."
    fi

    # Transfer to WORKER_1
    echo "Transferring $FILE_TO_TRANSFER to WORKER_1 ($WORKER_1)..."
    scp -i $WORKER_1_KEY_LOCAL $FILE_TO_TRANSFER $WORKER_1:$DESTINATION
    if [ $? -eq 0 ]; then
        echo "Transfer to WORKER_1 successful."
    else
        echo "Transfer to WORKER_1 failed."
    fi


    # Transfer to WORKER_2
    echo "Transferring $FILE_TO_TRANSFER to WORKER_2 ($WORKER_2)..."
    scp -i $WORKER_2_KEY_LOCAL $FILE_TO_TRANSFER $WORKER_2:$DESTINATION
    if [ $? -eq 0 ]; then
        echo "Transfer to WORKER_2 successful."
    else
        echo "Transfer to WORKER_2 failed."
    fi
done


#This script should be run from your computer
scp -i ${DRIVER_KEY_LOCAL} ${WORKER_2_KEY_LOCAL} ec2-user@${WORKER_1_IP}:/home/ec2-user/.ssh/
scp -i ${DRIVER_KEY_LOCAL} ${WORKER_1_KEY_LOCAL} ec2-user@${WORKER_1_IP}:/home/ec2-user/.ssh/