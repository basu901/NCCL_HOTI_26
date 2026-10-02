#!/bin/bash
ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa
cd /home/ec2-user/.ssh
cp id_rsa.pub /home/ec2-user/
cd /home/ec2-user/
./push_driver_pub_key_to_workers.sh node_details_private.txt id_rsa.pub