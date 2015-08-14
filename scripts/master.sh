#!/bin/bash
# Generates ssh keys & disributes to nodes
# Parameters $1 node names
echo Executing master.sh
_nodes=$1
echo generating ssh key on master node
ssh-keygen -f /root/.ssh/id_rsa -N ''
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
#in order to copy ssh key to nodes for passwordless ssh use the command below
#for node in $_nodes; do ssh-copy-id root@$node ; done
#Create a private registry & mirror public registry 
echo Creating a private registry 
mkdir -p /var/lib/local-registry
systemctl restart docker 

docker pull docker.io/registry

docker create -p 5000:5000 \
-v /var/lib/local-registry:/srv/registry \
-e STANDALONE=false \
-e MIRROR_SOURCE=https://registry-1.docker.io \
-e MIRROR_SOURCE_INDEX=https://index.docker.io \
-e STORAGE_PATH=/srv/registry \
--name=local-registry registry

#change the SELinux context on the directory that docker created for our persistence volume
chcon -Rvt svirt_sandbox_file_t /var/lib/local-registry
#Create a service for local registry 
cat > /etc/systemd/system/local-registry.service << EOF
[Unit]
Description=Local Docker Mirror registry cache
Requires=docker.service
After=docker.service

[Service]
Restart=on-failure
RestartSec=10
ExecStart=/usr/bin/docker start -a %p
ExecStop=-/usr/bin/docker stop -t 2 %p

[Install]
WantedBy=multi-user.target
EOF
echo Configuring local-registry service 
systemctl daemon-reload
systemctl enable local-registry
systemctl start local-registry

echo Configuring Etcd
sed -i -e "s/^ETCD_LISTEN_CLIENT_URLS=.*/ETCD_LISTEN_CLIENT_URLS=\"http:\/\/0\.0\.0\.0:2379,http:\/\/0\.0\.0\.0:4001\"/" /etc/etcd/etcd.conf
sed -i -e "s/^#ETCD_ADVERTISE_CLIENT_URLS=.*/ETCD_ADVERTISE_CLIENT_URLS=\"http:\/\/0\.0\.0\.0:2379,http:\/\/0\.0\.0\.0:4001\"/" /etc/etcd/etcd.conf

echo Configuring Kubernetes
# Common service configurations
#  setting up the etcd store that Kubernetes will use
sed -i -e "s/^KUBE_MASTER=.*/KUBE_MASTER=\"--master=http:\/\/192\.168\.133\.2:8080\"/" /etc/kubernetes/config
echo KUBE_ETCD_SERVERS="--etcd_servers=http://192.168.133.2:2379" >> /etc/kubernetes/config
# Apiserver service configuration , listen on all IP addresses
#sed -i -e "s/^KUBE_API_ADDRESS=.*/KUBE_API_ADDRESS=\"--address=192\.168\.133\.2 --insecure_bind_address=127\.0\.0\.1\"/" /etc/kubernetes/apiserver
sed -i -e "s/^KUBE_API_ADDRESS=.*/KUBE_API_ADDRESS=\"--address=0\.0\.0\.0\"/" /etc/kubernetes/apiserver
sed -i -e "s/^KUBE_API_ARGS=.*/KUBE_API_ARGS=\"--runtime_config=api\/v1beta3\"/" /etc/kubernetes/apiserver
# --insecure_bind_address=127\.0\.0\.1
#force kube-apiserver tp start after network server & order kube master services
sed "/Documentation=.*/a After=network\.target " /usr/lib/systemd/system/kube-apiserver.service > /etc/systemd/system/kube-apiserver.service
sed "/Documentation=.*/a After=kube-apiserver\.service " /usr/lib/systemd/system/kube-controller-manager.service > /etc/systemd/system/kube-controller-manager.service
sed "/Documentation=.*/a After=kube-apiserver\.service " /usr/lib/systemd/system/kube-scheduler.service > /etc/systemd/system/kube-scheduler.service
#sed -i -e "s/^KUBE_ADMISSION_CONTROL=.*/KUBE_ADMISSION_CONTROL=\"--admission_control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ResourceQuota\"/" /etc/kubernetes/apiserver
# Controller Manager service configuration , The controller manager service needs to how to locate it’s nodes
sed -i -e "s/^KUBELET_ADDRESSES=.*/KUBELET_ADDRESSES=\"--machines=192\.168\.133\.3,192\.168\.133\.4\"/" /etc/kubernetes/controller-manager
#
sed -i -e "s/^KUBELET_ADDRESS=.*/KUBELET_ADDRESS=\"--address=0\.0\.0\.0\"/" /etc/kubernetes/kubelet
sed -i -e "s/^KUBELET_HOSTNAME=.*/KUBELET_HOSTNAME=\"--hostname_override=192\.168\.133\.2\"/" /etc/kubernetes/kubelet
sed -i -e "s/^KUBELET_API_SERVER=.*/KUBELET_API_SERVER=\"--api_servers=http:\/\/192\.168\.133\.2:8080\"/" /etc/kubernetes/kubelet
sed -i -e "s/^KUBE_MASTER=.*/KUBE_MASTER=\"--master=http:\/\/192\.168\.133\.2:8080\"/" /etc/kubernetes/config
sed -i -e "s/^KUBE_PROXY_ARGS=.*/KUBE_PROXY_ARGS=\"--master=http:\/\/192\.168\.133\.2:8080\"/" /etc/kubernetes/proxy

#enable services
for SERVICES in etcd kube-apiserver kube-controller-manager kube-scheduler; do 
    systemctl enable $SERVICES
    systemctl restart $SERVICES
done
# Flannel Network 
echo Configuring Flannel
# Prepare config
cat > /tmp/flanneld-conf.json << EOF
{
  "Network": "172.16.0.0/12",
  "SubnetLen": 24,
  "Backend": {
    "Type": "vxlan"
  }
}
EOF
#Push it to etcd
curl -L http://localhost:2379/v2/keys/coreos.com/network/config -XPUT --data-urlencode value@/tmp/flanneld-conf.json
#Fix Flannel settings
sed -i -e "s/^FLANNEL_ETCD=.*/FLANNEL_ETCD=\"http:\/\/192\.168\.133\.2:4001\"/" /etc/sysconfig/flanneld
sed -i -e "s/^FLANNEL_ETCD_KEY==.*/FLANNEL_ETCD_KEY==\"coreos\.com\/network\"/" /etc/sysconfig/flanneld

#enable services
systemctl enable flanneld
#rhel7-tools container
#echo downloading and installing rhel-tools
#atomic install registry.access.redhat.com/rhel7/rhel-tools
#<<EOF
#atomic run --name rhel-tools rhel7/rhel-tools
#exit
#EOF
#Cocpit
echo Installing Cocpit
#sudo -i
#download src for extra plugins 
#cd /root
#echo Downloading cockpit plugin sources
#curl -LOk https://github.com/cockpit-project/cockpit/archive/master.zip
#Extract 
#echo Extracting cockpit plugin sources
#atomic run rhel7/rhel-tools unzip /host/root/master.zip -d /host/root

#source in /root/cocpit-master 
#mkdir -p /root/.local/share/cockpit
#cd  /root/.local/share/cockpit
#ln -s /root/cockpit-master/pkg/* .
#install container 
echo Downloading and installing fedora/cockpitws container
atomic install fedora/cockpitws
echo Preparing cocpitws service 
cat > /etc/systemd/system/cockpitws.service << EOF
[Unit]
Description=Cockpit Web Interface
Requires=docker.service
After=docker.service

[Service]
Restart=on-failure
RestartSec=10
ExecStart=/usr/bin/docker run --rm --privileged --pid host -v /:/host --name %p fedora/cockpitws /container/atomic-run --local-ssh
ExecStop=-/usr/bin/docker stop -t 2 %p

[Install]
WantedBy=multi-user.target
EOF

systemctl enable cockpitws.service  

#complete
echo Master configuration is done! Restarting the system
systemctl reboot



