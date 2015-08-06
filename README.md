#Project Atomic Demo Environment
#Overview
This project contains a demo environment setup for [project atomic](http://www.projectatomic.io/) and/or [rhel atomic](https://access.redhat.com/articles/rhel-atomic-getting-started). As first step clone it to your local machine. 

###Environment Information
In this environment, you'll have 3 atomic hosts vm as one for master node and two slave nodes (or minions as named in kubernetes). I preferred to use Fedora version of the atomic host to skip registration steps, but it's quite possible to use rhel or centos images instead. Host configurations are below: 
1. 1512 mb Mem
2. 2 Core cpu
3. I'm using fedora box and my box storage configuration is 41 GB Storage for docker pool + 3 GB for root. Depends on your atomic version choice, it may differ
4. 5 GB additional disk to add docker pool 

In demo environment a private network is installed for node communications, IP addresses and hostnames are assigned as below: 
* atomic-master atomic-master.atomic-demo.com 192.168.133.2 
* atomic-minion1 atomic-minion1.atomic-demo.com 192.168.133.3
* atomic-minion2 atomic-minion2.atomic-demo.com 192.168.133.4

In each host, same ssh key is defined and assigned as trusted, so it's possible to ssh between hosts. 
  
### Prerequisite: Vagrant
You need Vagrant to install & setup our lab environment on your local machine. If it's not already installed, please go and install Vagrant on your machine as following the instructions at the [Vagrant web site](http://docs.vagrantup.com/v2/installation/index.html ). It's also recommended for you to walk through Vagrant [getting started guide](http://docs.vagrantup.com/v2/getting-started/index.html)  to make sure that your Vagrant installation is properly done.

After you've an up & running Vagrant instance on your machine, install vagrant-hostmanager plugin as using the command below: 

```bash 
 vagrant plugin install vagrant-hostmanager
```
> This may require some development files already installed on your system. If you haven't done it before, install rubby and libvirt development packages
> ```
> sudo yum install ruby-devel libvirt-devel 
> ```

### Download & Import Fedora Atomic Image 
I preferred using Fedora Atomic image for this workshop instead of RHEL or CentOS Atomic.The reason for that is eliminating some required subscription steps in RHEL Atomic. 
  You can download the latest version of Fedora Atomic Vagrant box file from the [Fedora project download site](https://getfedora.org/cloud/download/atomic.html) or simply skip this step and start vagrant.It will download required box image for you from predefined  url. 

>*If you like to download and test RHEL Atomic, you can find it on [Red Hat customer site](https://access.redhat.com/downloads/content/271/ver=/rhel---7/7.1.1/x86_64/product-downloads). Please notice that RHEL Atomic doesn't have a Vagrant box definition by default, you'll need to download appropriate vm image and convert it to a Vagrant Box first. 
  
   Next Step is adding that downloaded box to vagrant. Please notice that I'm using `atomic` as it's name, if you use another name, vagrant will try to download predefined box and add it as `atomic`. 

```bash
# vagrant box add atomic Fedora-Cloud-Atomic-Vagrant-22-20150521.x86_64.vagrant-libvirt.box
```
  
 Check your vagrant box list to make sure that is imported well:
```bash
 # vagrant box list 
```

### Start Vagrant
   
   Now at this step all you need to do is starting vagrant

```bash
# vagrant up
```

   If you're lucky enough, you should have 3 hosts vm up & running on your local machine. 

