#!/bin/sh
#
# Params
#   $1: hostname
#   $2: ip
#
_HOST_NAME=$1
_HOST_IP=$2
#################
sudo -i
echo chaning root password as redhat1!
echo "redhat1!" | passwd root --stdin

echo Definining atomic node $_HOST_NAME ip: $_HOST_IP 
echo Fixing host manager bug as changing /etc/hosts file owner as root 
sudo restorecon /etc/hosts
sudo chown root:root /etc/hosts


mkdir -p ~/.ssh
chmod -R 600 ~/.ssh/
echo StrictHostKeyChecking no >> /etc/ssh/ssh_config

# Setup hostnames
hostnamectl --static set-hostname $_HOST_NAME.atomic-demo.com


echo Adding registry.access.redhat.com to docker registries
sed -i -e "s/^# INSECURE_REGISTRY=.*/INSECURE_REGISTRY='--insecure-registry registry\.access\.redhat\.com:5000 '/" /etc/sysconfig/docker
systemctl restart docker &
