# -*- mode: ruby -*-
# vi: set ft=ruby :
# Installs atomic hosts as one master node and several minion nodes as specified in NUM_MINIONS environment variable. If NUM_MINIONS variable is not specified
# installs only two minion nodes. This configuration requires "atomic" box is installed in prior to execute this config scripts. The tested box is fedora22 atomic
# box, but feel free to execute this with rhel atomic or centos atomic as well. 
# 
# 192.168.133.2     atomic-master.atomic-demo.com atomic-master                                                        
# 192.168.133.3     atomic-minion1.atomic-demo.com  atomic-minion1                                                          
# 192.168.133.4     atomic-minion2.atomic-demo.com  atomic-minion2

# Require a recent version of vagrant otherwise some have reported errors setting host names on boxes
Vagrant.require_version ">= 1.6.2"
#Required Modules 
require 'vagrant-atomic'
require 'rbconfig' 
require 'vagrant-hostmanager'
#OS Detection
def os
    @os ||= (
      host_os = RbConfig::CONFIG['host_os']
      case host_os
      when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
        :windows
      when /darwin|mac os/
        :macosx
      when /linux/
        :linux
      when /solaris|bsd/
        :unix
      else
        raise Error::WebDriverError, "unknown os: #{host_os.inspect}"
      end
    )
end

puts "Detected Host OS %s" % [os.to_s] 
 
#Vagrant Configuration

Vagrant.configure("2") do |config|
# The number of minions to provision.
  num_minions = (ENV['NUM_MINIONS'] || 2).to_i
# IP configuration
  master_ip = "192.168.133.2"
  minion_ip_base = "192.168.133."
  minion_ips = num_minions.times.collect { |n| minion_ip_base + "#{n+3}" }
  minion_names_str =""
# On windows os there is a bug that prevents vagrant to run with cygwin rsync 
# The lines below are a workarround for that problem
  if  os.to_s == "windows"
    if ENV["VAGRANT_DETECTED_OS"].nil?
     ENV["VAGRANT_DETECTED_OS"] = os.to_s + " cygwin"
    else 
      ENV["VAGRANT_DETECTED_OS"] = ENV["VAGRANT_DETECTED_OS"].to_s  + " cygwin"
    end  
  end

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
  config.vm.box = "atomic"
  config.vm.box_check_update = false
# Default synchronization settings cause problems on windows + virtualbox combination
  config.vm.synced_folder './', '/var/vagrant', disabled:true
########################################################################################### 
#
# virtualbox provider common settings
#
  config.vm.provider "virtualbox" do |vb, override|
    override.vm.box = "atomic"
    override.vm.box_url="http://dl.fedoraproject.org/pub/fedora/linux/releases/22/Cloud/x86_64/Images/Fedora-Cloud-Atomic-Vagrant-22-20150521.x86_64.vagrant-virtualbox.box"
    vb.gui = false
    vb.customize ["modifyvm", :id, "--memory", "1512", "--cpus", "2"]
    #only controller added
    vb.customize ['storagectl', :id, '--name', 'SATA Controller', '--add', 'sata']
  end

#
# libvirt provider common settings
#
  config.vm.provider "libvirt" do |libvirt, override|
    override.vm.box = "atomic"
    override.vm.box_url="http://dl.fedoraproject.org/pub/fedora/linux/releases/22/Cloud/x86_64/Images/Fedora-Cloud-Atomic-Vagrant-22-20150521.x86_64.vagrant-libvirt.box"
    libvirt.driver = "kvm"
    libvirt.memory = 1512
    libvirt.cpus = 2
    libvirt.storage :file, :size => '5G', :device => 'vdb'
  end

###########################################################################################
# Minion nodes
  num_minions.times do |n|
     config.vm.define "atomic-minion#{n+1}" do |node|
       node_index = n+1
       node_ip = minion_ips[n]
       node.vm.hostname = "atomic-minion#{node_index}"
       minion_names_str = minion_names_str + " " + node.vm.hostname
       node.hostmanager.aliases = %W(atomic-minion#{node_index}.atomic-demo.com)
       #
       # virtualbox provider specific settings 
       # network & second hd
       #
       node.vm.provider "virtualbox" do |vb|
          # Add Second Drive
          if ENV["VBOX_VM_PATH"]
           vb_disk_path = ENV["VBOX_VM_PATH"] + :vm + "/" + node.vm.hostname + "-disk2" + ".vmdk"
         else
           vb_disk_path = Dir.pwd() + "/" + node.vm.hostname + "-disk2" + ".vmdk"
         end
         unless File.exist?(vb_disk_path )
           vb.customize ['createhd', '--filename', vb_disk_path, '--size', 5 * 1024]
         end
         vb.customize ['storageattach', :id, '--storagectl','SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', vb_disk_path] 
      end
 
      #continue to common settings
      # Add private network & do not configure it  
      node.vm.network "private_network", ip: "#{node_ip}", auto_config:false ,virtualbox__intnet: "atomic-demo.com" , libvirt__network_name: "atomic-demo.com", libvirt__dhcp_enabled: false
      node.vm.provision "fix-hostmanager-bug", type: "shell", run: "always" do |s|
        s.inline = <<-EOT
          sudo restorecon /etc/hosts
          sudo chown root:root /etc/hosts
          EOT
      end
      node.vm.network "private_network", ip: "#{node_ip}", auto_config:false 
        #,virtualbox__intnet: "atomic-demo.com", libvirt__network_name: "atomic-demo.com", libvirt__dhcp_enabled: false
      # provision shell to conf network
      node.vm.provision :shell , :path => "./scripts/fixNet.sh" , :args => [node_ip] 
      node.vm.provision :shell , :path  => "./scripts/all.sh", :args => [node.vm.hostname,node_ip]
    end
  end  

# Master Node
  config.vm.define "atomic-master", primary:true do |master|
     master.vm.hostname = "atomic-master"
     master.hostmanager.aliases = %W(atomic-master.atomic-demo.com)
     #
     # virtualbox provider specific settings 
     # network & second hd
     #
     master.vm.provider "virtualbox" do |vb|
          # Add Second Drive
          if ENV["VBOX_VM_PATH"]
           vb_disk_path = ENV["VBOX_VM_PATH"] + :vm + "/" + master.vm.hostname + "-disk2" + ".vmdk"
         else
           vb_disk_path = Dir.pwd() + "/" + master.vm.hostname + "-disk2" + ".vmdk"
         end
         unless File.exist?(vb_disk_path )
           vb.customize ['createhd', '--filename', vb_disk_path, '--size', 5 * 1024]
         end
         vb.customize ['storageattach', :id, '--storagectl','SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', vb_disk_path] 
      end
      #continue to common settings
       # Add private network & do not configure it  
      master.vm.network "private_network", ip: "#{master_ip}", auto_config:false,virtualbox__intnet: "atomic-demo.com", libvirt__network_name: "atomic-demo.com", libvirt__dhcp_enabled: false
      master.vm.provision "fix-hostmanager-bug", type: "shell", run: "always" do |s|
        s.inline = <<-EOT
          sudo restorecon /etc/hosts
          sudo chown root:root /etc/hosts
          EOT
      end
      # provision shell to conf network
      master.vm.provision :shell , :path => "./scripts/fixNet.sh" , :args => [master_ip] 
      master.vm.provision :shell , :path => "./scripts/all.sh", :args => [master.vm.hostname,master_ip]
      master.vm.provision :shell , :path => "./scripts/master.sh", :args => [minion_names_str]
  end
end
