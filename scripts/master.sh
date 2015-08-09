#!/bin/bash
# Generates ssh keys & disributes to nodes
# Parameters $1 node names
_nodes=$1
ssh-keygen -f /root/.ssh/id_rsa -N ''
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
#done in all.sh
#echo StrictHostKeyChecking no >> /etc/ssh/ssh_config
#echo copying ssh id to $_nodes
#for node in $_nodes; do ssh-copy-id root@$node ; done




