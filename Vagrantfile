# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

# Configure the number of stores
STORES = (1..1)

# Configure the number of nodes per store
NODES = (1..1)

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # The NOC OpenNMS instance
  config.vm.define "opennms" do |opennms|
    opennms.vm.box = "hashicorp/precise32"

    # Assign the VM to the NOC network
    opennms.vm.network "private_network", ip: "192.168.0.2", intnet:"noc"

    config.vm.provider "virtualbox" do |vb|
      vb.name = "smnnepo-gruslab-opennms"
    end

    # Start the provisioning
    opennms.vm.synced_folder "opennms", "/opt/provisioning"
    opennms.vm.provision "shell", inline: "sh /opt/provisioning/bootstrap.sh"
  end

  # The routing infrastructure
  config.vm.define "router" do |router|
    router.vm.box = "hashicorp/precise32"

    # Assign the VM to the NOC network
    router.vm.network "private_network", ip: "192.168.0.1", intnet:"noc"

    # Assign the VM to the store-specific network
    STORES.each do |i|
      router.vm.network "private_network", ip: "192.168.#{i}.1", intnet:"store-#{i}"
    end

    config.vm.provider "virtualbox" do |vb|
      vb.name = "smnnepo-gruslab-router"
      vb.customize ["modifyvm", :id, "--memory", "128"]
    end

    # Start the provisioning
    router.vm.synced_folder "router", "/opt/provisioning"
    router.vm.provision "shell", inline: "sh /opt/provisioning/bootstrap.sh #{STORES.count}"
  end

  STORES.each do |i|
    # Create one minion per store
    config.vm.define "store#{i}-minion" do |minion|
      minion.vm.box = "hashicorp/precise32"

      # Assign the VM to the store-specific network
      minion.vm.network "private_network", ip: "192.168.#{i}.2", intnet:"store-#{i}"

      config.vm.provider "virtualbox" do |vb|
        vb.name = "smnnepo-gruslab-store#{i}-minion"
        vb.customize ["modifyvm", :id, "--memory", "256"]
      end

      # Start the provisioning
      minion.vm.synced_folder "minion", "/opt/provisioning"
      minion.vm.provision "shell", inline: "sh /opt/provisioning/bootstrap.sh #{i}"
    end

    # Create nodes for each store
    NODES.each do |a|
      # Create the node
      config.vm.define "store#{i}-node#{a}" do |node|
        node.vm.box = "hashicorp/precise32"

        # Assign the VM to the store-specific network
        node.vm.network "private_network", ip: "192.168.#{i}.#{2+a}", intnet:"store-#{i}"

        config.vm.provider "virtualbox" do |vb|
          vb.name = "smnnepo-gruslab-store#{i}-node#{a}"
          vb.customize ["modifyvm", :id, "--memory", "128"]
        end

        # Start the provisioning
        node.vm.synced_folder "node", "/opt/provisioning"
        node.vm.provision "shell", inline: "sh /opt/provisioning/bootstrap.sh #{i} #{a}"
      end
    end
  end
end
