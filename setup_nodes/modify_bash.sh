#!/bin/bash
echo "export PATH=$PATH:/usr/lib64/openmpi/bin" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=/usr/lib64/openmpi/lib" >> ~/.bashrc

source ~/.bashrc