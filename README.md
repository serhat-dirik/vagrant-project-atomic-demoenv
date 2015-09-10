#Project Atomic Demo Environment
#Overview
This project contains a demo environment setup for [project atomic](http://www.projectatomic.io/) and/or [rhel atomic](https://access.redhat.com/articles/rhel-atomic-getting-started). As first step, clone this project to your local machine.

```
  # git clone https://github.com/serhat-dirik/vagrant-project-atomic-demoenv
```

###Environment Information
In this environment, you'll have 3 atomic hosts vm as one master node and two slave nodes (or minions as named in kubernetes). I preferred to use Fedora version of the atomic host to skip some registration steps on rhel, but it's quite possible to use rhel or centos images instead of fedora. Host configurations:

1. 1512 mb Mem
2. 2 Core cpu
3. I'm using fedora box and my box storage configuration is 41 GB Storage for docker pool + 3 GB for root. Depends on your atomic version choice, it may differ
4. 5 GB additional disk to add docker pool

A private network will be installed for node communications, IP addresses and hostnames are assigned as below:
* atomic-master atomic-master.atomic-demo.com 192.168.133.2
* atomic-minion1 atomic-minion1.atomic-demo.com 192.168.133.3
* atomic-minion2 atomic-minion2.atomic-demo.com 192.168.133.4

On top of that that private network, there will be another overlay network (flannel) installed for kubernetes pods communication.

You'll have two default users as root & vagrant for each host. Passwords are "redhat1!" for root user and "vagrant" for vagrant user.

If everything is done properly, kubernetes related services should be up and running on both master and minions. Etcd, kubernetes apiserver, scheduler, controller manager, flanneld and docker services are running on the master node. Kubelet, kube proxy, flanneld and docker services should be also up & running on minions as  well.

A private docker registry installed on the master node, public docker registry is mirrored and of course other nodes configured to use this private registry as a mirror.

At last cockpit management & monitoring tool is also installed on the master node. You can access it on port 9090, so visit http://atomic-master:9090 to reach it's web console.


### Prerequisite: Vagrant
You need Vagrant to install & setup our demo environment on your local machine. If it's not already installed, please go and install Vagrant on your machine as following the instructions at the [Vagrant web site](http://docs.vagrantup.com/v2/installation/index.html ). It's also recommended for you to walk through Vagrant [getting started guide](http://docs.vagrantup.com/v2/getting-started/index.html)  to make sure that your Vagrant installation is properly done.

After you've an up & running Vagrant instance on your machine, you'll need to install couple of vagrant plugins :

```
 # vagrant plugin install vagrant-hostmanager
 ...[output ommitted]...
 # vagrant plugin install vagrant-atomic
 ...[output ommitted]...
```
> This may require some development files already installed on your system. If you haven't done it before, install rubby and libvirt development packages
> ```
> sudo yum install ruby-devel libvirt-devel
> ```

### Download & Import Fedora Atomic Image
I preferred to use Fedora Atomic image for this workshop instead of RHEL or CentOS Atomic.The reason for that is eliminating some required subscription steps in RHEL Atomic.
  You can download the latest version of Fedora Atomic Vagrant box file from the [Fedora project download site](https://getfedora.org/cloud/download/atomic.html) or simply skip this step and start vagrant. It will download required box image for you from predefined  url.

>* If you like to test RHEL Atomic, you can find it on [Red Hat customer site](https://access.redhat.com/downloads/content/293/ver=1/rhel---7/1.0.1/x86_64/product-downloads).  RHEL Atomic Vagrant box image can be found under "Container Development Kit" downloadables.

   Next Step is adding that downloaded box to vagrant. Please notice that I'm using `atomic` as it's name, if you use another name, vagrant will try to download predefined box and add it as `atomic`.

```
# vagrant box add atomic Fedora-Cloud-Atomic-Vagrant-22-20150521.x86_64.vagrant-libvirt.box
```

 Check your vagrant box list to make sure that is imported well:
```
 # vagrant box list
```

### Start Vagrant

   Now at this step all you need to do is starting vagrant

```
# vagrant up atomic-master
...
# vagrant up
```

   If you're lucky enough, you should have 3 hosts vm up & running on your local machine.

### Validation Of Hosts & SSH Keys Installation

   Connect to master host using ssh .

```
  # vagrant ssh atomic-master
  ...
  [vagrant@atomic-master]$ sudo -i
```
Check the services on the master node :
```bash
ss -tulnp | grep -E "(kube)|(etcd)"
```
```
tcp    LISTEN     0      128            127.0.0.1:7001                  *:*      users:(("etcd",pid=1429,fd=5))
tcp    LISTEN     0      128            127.0.0.1:10251                 *:*      users:(("kube-scheduler",pid=1512,fd=3))
tcp    LISTEN     0      128            127.0.0.1:10252                 *:*      users:(("kube-controller",pid=1485,fd=3))
tcp    LISTEN     0      128            127.0.0.1:2380                  *:*      users:(("etcd",pid=1429,fd=3))
tcp    LISTEN     0      128                   :::4001                 :::*      users:(("etcd",pid=1429,fd=7))
tcp    LISTEN     0      128                   :::7080                 :::*      users:(("kube-apiserver",pid=1455,fd=5))
tcp    LISTEN     0      128                   :::6443                 :::*      users:(("kube-apiserver",pid=1455,fd=27))
tcp    LISTEN     0      128                   :::2379                 :::*      users:(("etcd",pid=1429,fd=6))
tcp    LISTEN     0      128                   :::8080                 :::*      users:(("kube-apiserver",pid=1455,fd=6))
```
 On a healty startup, you should see etcd , apiserver , scheduler, controller manager, flanneld and docker services are all up & running. If its not for any reason, restart your services with the command below

 ```bash
for SERVICE in etcd kube-apiserver kube-controller-manager kube-scheduler docker flanneld; do
    systemctl restart $SERVICE
    systemctl enable $SERVICE
    systemctl status $SERVICE
done
```
If you have trouble to get started any of those services above, use ```journalctl``` to see log details.
```bash
journalctl -u $servicename --full --no-pager
```

>flanneld service (overlay network service for kubernetes) requires configuration is pushed to api server. Check if it's there with command ```curl -L http://localhost:2379/v2/keys/coreos.com/network/config``` . If the key is not inserted to etcd for some reason, check ```
master.sh``` script in the project to find out how to insert that key into etcd.

Copy ssh key on master on to others for passwordless ssh connection between hosts.

```bash
for node in atomic-minion1 atomic-minion2; do ssh-copy-id root@$node ; done
```
  You root password is ```redhat1!```. After completion of ssh id copy process, you can check passwordless connection

```bash
ssh root@atomic-minion1 'echo $(hostname)'
...
atomic-minion1.atomic-demo.com
```
  Now check if required services are active on nodes :

```bash

for node in atomic-minion1 atomic-minion2; do ssh root@$node 'for SERVICE in kube-proxy.service kubelet.service flanneld docker; do echo is $SERVICE active on $(hostname) : $(systemctl is-active $SERVICE);  done' ; done

```
```
is kube-proxy.service active on atomic-minion1.atomic-demo.com : active
is kubelet.service active on atomic-minion1.atomic-demo.com : active
is flanneld active on atomic-minion1.atomic-demo.com : active
is docker active on atomic-minion1.atomic-demo.com : active
is kube-proxy.service active on atomic-minion2.atomic-demo.com : active
is kubelet.service active on atomic-minion2.atomic-demo.com : active
is flanneld active on atomic-minion2.atomic-demo.com : active
is docker active on atomic-minion2.atomic-demo.com : active
```
  If you see services are not running on nodes, use the command below to restart and enable those services :

```bash
for node in atomic-minion1 atomic-minion2; do ssh root@$node 'for SERVICE in docker kube-proxy.service kubelet.service flanneld docker; do echo $(hostname);systemctl restart $SERVICE; systemctl enable $SERVICE; systemctl status $SERVICE; done' ; done
```


  Check if kubernetes nodes are active
```
 # kubectl get node
```
  You should see two minions are in Ready state. If you see any one of them in "Not Ready" state, go and restart that host to fix that problem.

### Known Issues  

- Because of Vagrant does not guarantee that master host is provisioned before nodes, node services (kube-proxy, flanneld, kubelet) may not communicate with the master services on initial startup. Simple todo is restarting nodes after master is started for recovery or start atomic-master first on initial startup.

- Libvirt & kvm (which are my favorite) let you access the private network from the host machine. On the other hand virtualbox does not let you to access it from your host machine. In order to access your provisioned guests from your host, you need to [forward required ports](http://cdn9.howtogeek.com/wp-content/uploads/2012/08/image323.png) first and please be careful to pick proper nic that used for private networking.


- Cocpit kubernetes plugin is not fully functional on this environment, but still enough to see what it's tend to. New version of project atomic vagrant boxes expected to work with kubernetes 1.0 and have a fully functional cocpit

### Upgrading Atomic Host
   It's usualy recommended that you upgrade your os to the latest version as first step, but this time my recommendation is don't do it for this time. Kubernetes services  & configuration changing a lot and there is no guarantee that everything works fine after your upgrade due to kubernetes api changes.

### Cockpit Kubernetes Plugin
   Oh yes, cockpit has a beatiful kubernetes plugin that you can manage & monitor your pods & services. Follow the steps below to install it

1. Make sure that cockpit is up & running.
```
 # vagrant ssh atomic-master
 ...
 atomic-master$ sudo -i
 #systemctl status cockpitws.service
 ...
```
You should see cockpitws service is running
Open a browser on your host and connect http://atomic-master:9090 (If you're using virtualbox, than forward 9090 port of atomic-master to a local host port first and use that local port to connect). On the login page use ```root``` user name and ```redhat1!``` password. Use it for a while to get familiar your self. Go to Dashboard tab and add ```atomic-minion1.atomic-demo.com``` and ```atomic-minion2.atomic-demo.com``` to cockpit. You'll suddenly see that cockpit is collecting data from those hosts and it's possible to pick and manage those hosts as well.

2. Go back to console again. Download cockpit source code to access plugin sources:
```
# cd /root
# curl -LOk https://github.com/cockpit-project/cockpit/archive/master.zip
```
3. We have the source code now, but we need to extract it first and unfortunetely we don't have unzip in atomic, so we need to get another container package to have those tools.
```
# atomic install registry.access.redhat.com/rhel7/rhel-tools
... output is omited
```
4. The container must be running before we do anything with it, so start it first, examine it and exit.
```
# atomic run --name rhel-tools rhel7/rhel-tools
...
#exit
```
5. Now extract the cockpit source package
``` /
# atomic run rhel7/rhel-tools unzip /host/root/master.zip -d /host/root
```
  At this point you should have cocpit-source codes under /root/cockpit-master directory. Cockpit is designed for kubernetes v1 apis and we have only v1beta3 in atomic at this time. A small fix is needed to run cockpit kubernetes plugin.
```
# cd /root/cockpit-master/pkg/kubernetes
# mv client.js client.bck
# curl -LOk https://raw.githubusercontent.com/serhat-dirik/vagrant-project-atomic-demoenv/master/extra/cockpit/pkg/kubernetes/client.js
```
6. Properly place cockpit plugin sources
```
# cd /root
# mkdir -p /root/.local/share/cockpit
# cd  /root/.local/share/cockpit
# ln -s /root/cockpit-master/pkg/* .
```

   That's it! Now go back to cockpit web console and refresh it, you should see a Cluster tab is added to the console. For more information, visit [cockpit wiki](https://github.com/cockpit-project/cockpit/wiki/Atomic:-Kubernetes-dashboard).

### A Small Demo
  It's time to test kubernetes.

- Go back to master console

```
# mkdir /root/samples
# cd /root/samples
#curl -LOk https://raw.githubusercontent.com/serhat-dirik/vagrant-project-atomic-demoenv/master/extra/kubernetes/apachePod.json
#curl -LOk https://raw.githubusercontent.com/serhat-dirik/vagrant-project-atomic-demoenv/master/extra/kubernetes/frontendService.json
#curl -LOk https://raw.githubusercontent.com/serhat-dirik/vagrant-project-atomic-demoenv/master/extra/kubernetes/replicationController.json
# kubectl create -f apachePod.json
```
   The last command as you can guess creates a pod in kubernetes at the background. Use the command below to watch the status

```
# kubectl get pods
POD       IP        CONTAINER(S)       IMAGE(S)        HOST             LABELS        STATUS    CREATED     MESSAGE
apache              my-fedora-apache   fedora/apache   192.168.133.3/   name=apache   Pending   6 seconds
```
   It's probably take some time to pull required containers and run. For more detailes use can watch system logs
```
journalctl -f -l -xn -u kubelet -u kube-proxy -u docker --full --no-pager
```
   Alternatively you can use cockpit console to watch pod status. Wait untill pod status turns to Ready. For more detailed view of your pod, you can use :
```
# kubectl get pod --output=json apache
```

- If you had your pod up & running, the next step would be creating a kubernetes services to make it discoverable.
```
kubectl create -f frontendService.json
```
- Check that the service is loaded on the master

```
# kubectl get services
NAME            LABELS                                    SELECTOR      IP               PORT(S)
frontend        name=frontend                             name=apache   10.254.251.185   80/TCP
                                                                        192.168.133.3
kubernetes      component=apiserver,provider=kubernetes   <none>        10.254.0.2       443/TCP
kubernetes-ro   component=apiserver,provider=kubernetes   <none>        10.254.0.1       80/TCP
```

- Check if its working
```
curl http://192.168.133.3/
Apache
```
  And of course visit Cockpit cluster page and visit topology how pods & services are bounded

- Time to scale up. Create a replication controller for this first :

```
# kubectl create -f replicationController.json
# kubectl get rc
CONTROLLER          CONTAINER(S)       IMAGE(S)        SELECTOR      REPLICAS
apache-controller   my-fedora-apache   fedora/apache   name=apache   1
```
- Now increase the number

```
# kubectl resize --replicas=3 replicationController apache-controller
resized
# kubectl get rc
CONTROLLER          CONTAINER(S)       IMAGE(S)        SELECTOR      REPLICAS
apache-controller   my-fedora-apache   fedora/apache   name=apache   3
#kubectl get pods
POD                       IP            CONTAINER(S)       IMAGE(S)        HOST                          LABELS        STATUS    CREATED      MESSAGE
apache                    172.16.60.2                                      192.168.133.3/192.168.133.3   name=apache   Running   17 minutes
                                        my-fedora-apache   fedora/apache                                               Running   8 minutes
apache-controller-6n3sk                                                    192.168.133.4/                name=apache   Pending   51 seconds
                                        my-fedora-apache   fedora/apache
apache-controller-d8x09   172.16.60.3                                      192.168.133.3/192.168.133.3   name=apache   Running   51 seconds
                                        my-fedora-apache   fedora/apache                                               Running   51 seconds

```

###Troubleshooting

 In the case you have experience any problems, please make sure that services below are up & running :

* Master
  * docker etcd flanneld kupe-apiserver kube-controller-manager kube-scheduler
* Minions
  * docker flanneld kubelet kube-proxy

  How to check a service's status :
```bash
  systemctl status $service_name
```
   Detailed log watch:
```bash
   journalctl -u $service_name --full --no-pager
```
   How to start a service:
```bash
   systemctl start $service_name
```
   Restart

```bash
   systemctl restart $service_name
```
### Additonal Links
- For a more detailed example, you can use [guest book](https://github.com/kubernetes/kubernetes/blob/master/examples/guestbook/README.md) example .
- If you need a detailed learning source, Scott Collier's [SA Training](https://github.com/scollier/SATraining) is a good one and some examples that I used here is coming from there.
