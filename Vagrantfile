# -*- mode: ruby -*-
# vi: set ft=ruby :
# Installs atomic hosts as one master node and several minion nodes as specified in NUM_MINIONS environment variable. If NUM_MINIONS variable is not specified
# installs only two minion nodes. This configuration requires "atomic" box is installed in prior to execute this config scripts. The tested box is fedora22 atomic
# box, but feel free to execute this with rhel atomic or centos atomic as well. 
# 
# 192.168.133.2     atomic-master.atomic-demo.com atomic-master                                                        
# 192.168.133.3     atomic-minion1.atomic-demo.com  atomic-minion1                                                          
# 192.168.133.4     atomic-minion2.atomic-demo.com  atomic-minion2

require 'vagrant-hostmanager'

Vagrant.configure("2") do |config|
# The number of minions to provision.
  num_minions = (ENV['NUM_MINIONS'] || 2).to_i
# IP configuration
  master_ip = "192.168.133.2"
  minion_ip_base = "192.168.133."
  minion_ips = num_minions.times.collect { |n| minion_ip_base + "#{n+3}" }
  minion_ips_str = minion_ips.join(",")

#
# Plugins configuration
#
  
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true

#
# Box configuration
#
  config.vm.box_check_update = false
  config.vm.box = "atomic"
  config.vm.box_url="http://dl.fedoraproject.org/pub/fedora/linux/releases/22/Cloud/x86_64/Images/Fedora-Cloud-Atomic-Vagrant-22-20150521.x86_64.vagrant-libvirt.box"
  config.vm.synced_folder './', '/var/vagrant', type: 'rsync'

#
# virtualbox provider common settings
#
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.customize ["modifyvm", :id, "--memory", "1512", "--cpus", "2"]
    # Add Second Drive
    if ENV["VBOX_VM_PATH"]
      vb_disk_path = ENV["VBOX_VM_PATH"] + :vm + "/" + "atomic-box-disk2" + ".vmdk"
    else
      vb_disk_path = Dir.pwd() + "/" + "atomic-box-disk2" + ".vmdk"
    end
    vb.customize ['createhd', '--filename', vb_disk_path, '--size', 500 * 1024]
    vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', vb_disk_path] 
  end

#
# libvirt provider common settings
#
  config.vm.provider "libvirt" do |libvirt|
    libvirt.driver = "kvm"
    libvirt.memory = 1512
    libvirt.cpus = 2
    libvirt.storage :file, :size => '5G', :device => 'vdb'
  end


# Minion nodes
  num_minions.times do |n|
     config.vm.define "atomic-minion#{n+1}" do |node|
       node_index = n+1
       node_ip = minion_ips[n]
       node.vm.hostname = "atomic-minion#{node_index}"
       node.hostmanager.aliases = %W(atomic-minion#{node_index}.atomic-demo.com)
       node.vm.network "private_network", ip: "#{node_ip}", libvirt__network_name: "atomic-demo0", libvirt__dhcp_enabled: false
       node.vm.provision "shell" do |s|
         s.args = [node_index, node_ip, node.vm.hostname]
         s.inline = <<-EOT
	  echo Definining minion node $1 ip: $2 hostname: $3 
          echo Fixing host manager bug as changing /etc/hosts file owner as root 
          sudo restorecon /etc/hosts
          sudo chown root:root /etc/hosts
          echo Copy ssh key and add to authorized_keys. All hosts will have the same key.
          mkdir -p ~/.ssh
          cp /var/vagrant/keys/id_rsa ~/.ssh/
          cat /var/vagrant/keys/id_rsa.pub >>  ~/.ssh/authorized_keys
          chmod -R 600 ~/.ssh/
          echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
          echo Adding registry.access.redhat.com to docker registries
	  sed -i -e "s/^# INSECURE_REGISTRY=.*/INSECURE_REGISTRY='--insecure-registry registry\.access\.redhat\.com:5000 '/" /etc/sysconfig/docker
          systemctl restart docker 
	  EOT
       end
    end
  end  

  #VAGRANT_ROOT = File.dirname(File.expand_path(__FILE__))
  #file_to_disk = File.join(VAGRANT_ROOT, 'atomic_master_additional.vdi')
  #Vagrant::Config.run do |config|
  # config.vm.box = 'base'
  # config.vm.customize ['createhd', '--filename', file_to_disk, '--size', 500 * 1024]
  # config.vm.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', file_to_disk]
  #end

  config.vm.define "atomic-master" do |master|
     master.vm.hostname = "atomic-master"
     master.hostmanager.aliases = %W(atomic-master.atomic-demo.com)
     master.vm.network "private_network", ip: master_ip, libvirt__network_name: "atomic-demo0", libvirt__dhcp_enabled: false
     #master.vm.provision "master-shell", type: "shell", run: "always" do |s|
     master.vm.provision "shell" do |s|
         s.args = [ master_ip, master.vm.hostname]
         s.inline = <<-EOT
	  echo Definining master node ip: $1 hostname: $2
          echo Fixing host manager bug as changing /etc/hosts file owner as root 
          sudo restorecon /etc/hosts
          sudo chown root:root /etc/hosts
          echo Copy ssh key and add to authorized_keys. All hosts will have the same key.
          mkdir -p ~/.ssh
          cp /var/vagrant/keys/id_rsa ~/.ssh/
          cat /var/vagrant/keys/id_rsa.pub >>  ~/.ssh/authorized_keys
          chmod -R 600 ~/.ssh/
          echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
          echo Adding registry.access.redhat.com to docker registries
	  sed -i -e "s/^# INSECURE_REGISTRY=.*/INSECURE_REGISTRY='--insecure-registry registry\.access\.redhat\.com:5000 '/" /etc/sysconfig/docker
          systemctl restart docker
	  EOT
     end
  end
end
