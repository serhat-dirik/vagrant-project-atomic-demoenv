#!/bin/bash
#Unfortunetely vagrant generating wrong network setting files on windows+vbox
#This script fixes that problem . It assumes we have two ethernet nic  as first one for public network and second one for the private
# Params
#   $1: ip
#
echo Executing fixNet.sh
_HOST_IP=$1

echo Configuring network devices...
sudo -i

ndevice1="$(nmcli device status|grep ethernet|sed -n '1p' | cut -d' ' -f1)"
ndevice2="$(nmcli device status|grep ethernet|sed -n '2p' | cut -d' ' -f1)"
systemctl stop network  > /dev/null 2>&1 
systemctl stop NetworkManager  > /dev/null 2>&1 
rm -f /etc/sysconfig/network-scripts/ifcfg-eth* > /dev/null 2
cat > /etc/sysconfig/network-scripts/ifcfg-$ndevice1 << EOF
DEVICE="$ndevice1"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
PERSISTENT_DHCLIENT="yes"
EOF
cat > /etc/sysconfig/network-scripts/ifcfg-$ndevice2 << EOF
NM_CONTROLLED=no
BOOTPROTO=none
ONBOOT=yes
IPADDR=$_HOST_IP
NETMASK=255.255.255.0
DEVICE=$ndevice2

PEERDNS=no
EOF
systemctl enable network 
systemctl enable NetworkManager 
systemctl start network &
systemctl start NetworkManager &
echo Done!
