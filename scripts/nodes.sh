#!/bin/sh
#
# Params
#   $1: hostname
#   $2: ip
#
_HOST_NAME=$1
_HOST_IP=$2
_HOST_IP_ESC="$(echo "$_HOST_IP" | sed 's/[^-A-Za-z0-9_]/\\&/g')"
#################
echo Configuring Docker to use the cluster registry cache
sed -i -e "s/^OPTIONS=.*/OPTIONS='--registry-mirror=http:\/\/192\.168\.133\.2:5000 --selinux-enabled'/" /etc/sysconfig/docker
echo Configuring Docker to use the Flannel overlay network
sed -i -e "s/^FLANNEL_ETCD=.*/FLANNEL_ETCD=\"http:\/\/192\.168\.133\.2:4001\"/" /etc/sysconfig/flanneld
sed -i -e "s/^FLANNEL_ETCD_KEY==.*/FLANNEL_ETCD_KEY==\"coreos\.com\/network\"/" /etc/sysconfig/flanneld


echo Configuring kubernetes on the node 
sed -i -e "s/^KUBELET_ADDRESS=.*/KUBELET_ADDRESS=\"--address=0\.0\.0\.0\"/" /etc/kubernetes/kubelet
sed -i -e "s/^KUBELET_HOSTNAME=.*/KUBELET_HOSTNAME=\"--hostname_override=$_HOST_IP_ESC\"/" /etc/kubernetes/kubelet
sed -i -e "s/^KUBELET_API_SERVER=.*/KUBELET_API_SERVER=\"--api_servers=http:\/\/192\.168\.133\.2:8080\"/" /etc/kubernetes/kubelet
sed -i -e "s/^KUBE_MASTER=.*/KUBE_MASTER=\"--master=http:\/\/192\.168\.133\.2:8080\"/" /etc/kubernetes/config
sed -i -e "s/^KUBE_PROXY_ARGS=.*/KUBE_PROXY_ARGS=\"--master=http:\/\/192\.168\.133\.2:8080\"/" /etc/kubernetes/proxy

systemctl daemon-reload
systemctl enable flanneld kubelet kube-proxy
systemctl reboot 

