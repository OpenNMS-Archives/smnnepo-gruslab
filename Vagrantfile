# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

# Configure the number of stores
STORES = (1..1)

# Configure the number of nodes per store
NODES = (1..2)

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"

  # The NOC router instance
  config.vm.define "noc-router" do |router|
    router.vm.box = "ubuntu/trusty64"
    router.vm.hostname = "noc-router"

    # Assign the router to the transfer network
    router.vm.network "private_network", ip: "10.10.10.254", intnet: "transfer"

    # Assign the router to the NOC network
    router.vm.network "private_network", ip: "172.16.0.254", intnet:"noc"

    router.vm.provider "virtualbox" do |vb|
      vb.name = "smnnepo-gruslab-noc-router"
      vb.customize ["modifyvm", :id, "--memory", "128"]
    end

    # Start the provisioning
    router.vm.synced_folder "provisioning/noc/router", "/opt/provisioning"
    router.vm.provision "shell", inline: "bash /opt/provisioning/bootstrap.sh #{STORES.count}"
  end

  # The NOC OpenNMS instance
  config.vm.define "noc-opennms" do |opennms|
    opennms.vm.box = "ubuntu/trusty64"
    opennms.vm.hostname = "noc-opennms"

    # Assign the VM to the NOC network
    opennms.vm.network "private_network", ip: "172.16.0.253", intnet:"noc"
    opennms.vm.network "forwarded_port", guest: 8980, host: 8980

    opennms.vm.provider "virtualbox" do |vb|
      vb.name = "smnnepo-gruslab-opennms"
      # OpenNMS needs more than 1GB RAM
      vb.customize ["modifyvm", :id, "--memory", "2048"]
    end

    # Start the provisioning
    opennms.vm.synced_folder "provisioning/noc/opennms", "/opt/provisioning"
    opennms.vm.provision "shell", inline: "bash /opt/provisioning/bootstrap.sh"
  end

  STORES.each do |i|
    # Create one router per store
    config.vm.define "store#{i}-router" do |router|

      # Connect the VM to the transfer network
      router.vm.network "private_network", ip: "10.10.10.#{i}", intnet: "transfer"

      # Connect the router to the store-specific network
      router.vm.network "private_network", ip: "192.168.0.254", intnet: "store#{i}"

      router.vm.provider "virtualbox" do |vb|
        vb.name = "smnnepo-gruslab-store#{i}-router"
        vb.customize ["modifyvm", :id, "--memory", "128"]
      end

      # Start the provisioning
      router.vm.synced_folder "provisioning/store/router", "/opt/provisioning"
      router.vm.provision "shell", inline: "bash /opt/provisioning/bootstrap.sh #{i}"
    end

    # Create one minion per store
    config.vm.define "store#{i}-minion" do |minion|
      minion.vm.box = "ubuntu/trusty64"
      minion.vm.hostname = "store#{i}-minion"

      # Assign the VM to the store-specific network
      minion.vm.network "private_network", ip: "192.168.0.253", intnet:"store#{i}"

      minion.vm.provider "virtualbox" do |vb|
        vb.name = "smnnepo-gruslab-store#{i}-minion"
        vb.customize ["modifyvm", :id, "--memory", "512"]
      end

      # Start the provisioning
      minion.vm.synced_folder "provisioning/store/minion", "/opt/provisioning"
      minion.vm.provision "shell", inline: "bash /opt/provisioning/bootstrap.sh #{i}"
    end

    # Create nodes for each store
    NODES.each do |a|
      # Create the node
      config.vm.define "store#{i}-node#{a}" do |node|
        node.vm.box = "ubuntu/trusty64"
        node.vm.hostname = "store#{i}-node#{a}"

        # Assign the VM to the store-specific network
        node.vm.network "private_network", ip: "192.168.0.#{a}", intnet: "store#{i}"

        node.vm.provider "virtualbox" do |vb|
          vb.name = "smnnepo-gruslab-store#{i}-node#{a}"
          vb.customize ["modifyvm", :id, "--memory", "128"]
        end

        # Start the provisioning
        node.vm.synced_folder "provisioning/store/node", "/opt/provisioning"
        node.vm.provision "shell", inline: "bash /opt/provisioning/bootstrap.sh #{i} #{a}"
      end
    end
  end
end

