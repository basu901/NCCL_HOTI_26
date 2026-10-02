#!/bin/bash

IFS=','

declare -a IP
declare -a KEY

# Explains how read uses new-line and what the following line means //https://unix.stackexchange.com/questions/478720/what-does-while-read-r-line-n-line-mean
# while read -r line || [[ -n "$line" ]]; do
#     # IP+=("$args_array[0]")
#     # KEY+=("$args_array[1]")
#     echo "$line" 

while read -r line || [[ -n "$line" ]]; do
    read -r -a parts <<< "$line"
    IP+=("${parts[0]}")
    KEY+=("${parts[1]}")
done < $1

# Following lines did not work
# #The ! gives us the index
# for i in "${!IP[@]}";do
#     declare WORKER_"${i}"_IP=${IP[$i]}
#     echo 
# done

declare WORKER_1_IP=${IP[0]}
declare WORKER_2_IP=${IP[1]}
declare WORKER_3_IP=${IP[2]}

# for i in "${!KEY[@]}";do
#     declare WORKER_"$i"_KEY=${KEY[$i]}
# done


declare WORKER_1_KEY=${KEY[0]}
declare WORKER_2_KEY=${KEY[1]}
declare WORKER_3_KEY=${KEY[2]}


yum -y update
yum -y install openmpi openmpi-devel

echo "${WORKER_1_IP} driver" >> /etc/hosts
echo "${WORKER_2_IP} worker1" >> /etc/hosts
echo "${WORKER_3_IP} worker2" >> /etc/hosts