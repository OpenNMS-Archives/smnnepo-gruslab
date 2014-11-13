# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

# Configure the number of stores
STORES = (1..1)

# Configure the number of nodes per store
NODES = (1..1)

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # The NOC OpenNMS instance
  config.vm.define "noc-opennms" do |opennms|
    opennms.vm.box = "hashicorp/precise64"

    # Assign the VM to the NOC network
    opennms.vm.network "private_network", ip: "172.16.0.2", intnet:"noc"

    config.vm.provider "virtualbox" do |vb|
      vb.name = "smnnepo-gruslab-noc-opennms"
    end

    # Start the provisioning
    opennms.vm.synced_folder "provisioning/noc/opennms", "/opt/provisioning"
    opennms.vm.provision "shell", inline: "sh /opt/provisioning/bootstrap.sh"
  end

  # The NOC router instance
  config.vm.define "noc-router" do |router|
    router.vm.box = "hashicorp/precise64"

    # Assign the router to the transfer network
    router.vm.network "private_network", ip: "10.10.10.254", intnet: "transfer"

    # Assign the router to the NOC network
    router.vm.network "private_network", ip: "172.16.0.1", intnet:"noc"

    config.vm.provider "virtualbox" do |vb|
      vb.name = "smnnepo-gruslab-noc-router"
      vb.customize ["modifyvm", :id, "--memory", "128"]
    end

    # Start the provisioning
    router.vm.synced_folder "provisioning/noc/router", "/opt/provisioning"
    router.vm.provision "shell", inline: "sh /opt/provisioning/bootstrap.sh #{STORES.count}"
  end

  STORES.each do |i|
    # Create one router per store
    config.vm.define "store#{i}-router" do |router|
      router.vm.box = "hashicorp/precise64"

      # Connect the VM to the transfer network
      router.vm.network "private_network", ip: "10.10.10.#{100+i}", intnet: "transfer"

      # Connect the router to the store-specific network
      router.vm.network "private_network", ip: "192.168.0.1", intnet: "store#{i}"

      config.vm.provider "virtualbox" do |vb|
        vb.name = "smnnepo-gruslab-store#{i}-router"
        vb.customize ["modifyvm", :id, "--memory", "128"]
      end

      # Start the provisioning
      router.vm.synced_folder "provisioning/store/router", "/opt/provisioning"
      router.vm.provision "shell", inline: "sh /opt/provisioning/bootstrap.sh #{i}"
    end

    # Create one minion per store
    config.vm.define "store#{i}-minion" do |minion|
      minion.vm.box = "hashicorp/precise64"

      # Assign the VM to the store-specific network
      minion.vm.network "private_network", ip: "192.168.0.2", intnet:"store#{i}"

      config.vm.provider "virtualbox" do |vb|
        vb.name = "smnnepo-gruslab-store#{i}-minion"
        vb.customize ["modifyvm", :id, "--memory", "256"]
      end

      # Start the provisioning
      minion.vm.synced_folder "provisioning/store/minion", "/opt/provisioning"
      minion.vm.provision "shell", inline: "sh /opt/provisioning/bootstrap.sh #{i}"
    end

    # Create nodes for each store
    NODES.each do |j|
      # Create the node
      config.vm.define "store#{i}-node#{j}" do |node|
        node.vm.box = "hashicorp/precise64"

        # Assign the VM to the store-specific network
        node.vm.network "private_network", ip: "192.168.0.#{100+j}", intnet: "store#{i}"

        config.vm.provider "virtualbox" do |vb|
          vb.name = "smnnepo-gruslab-store#{i}-node#{j}"
          vb.customize ["modifyvm", :id, "--memory", "128"]
        end

        # Start the provisioning
        node.vm.synced_folder "provisioning/store/node", "/opt/provisioning"
        node.vm.provision "shell", inline: "sh /opt/provisioning/bootstrap.sh #{i} #{j}"
      end
    end
  end
end
