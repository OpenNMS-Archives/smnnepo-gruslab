# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

MINIONS = (1..1)

NODES = (1..1)

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # config.vm.box = "hashicorp/precise32"

  config.vm.define "opennms" do |opennms|
    opennms.vm.box = "hashicorp/precise32"
    opennms.vm.synced_folder "opennms", "/opt/provisioning"
    opennms.vm.network "private_network", ip: "192.168.0.2", intnet:"noc"

    config.vm.provider "virtualbox" do |vb|
      vb.name = "smnnepo-gruslab-opennms"
    end
  end

  config.vm.define "router" do |router|
    router.vm.box = "hashicorp/precise32"
    router.vm.synced_folder "router", "/opt/provisioning"
    router.vm.network "private_network", ip: "192.168.0.1", intnet:"noc"

    config.vm.provider "virtualbox" do |vb|
      vb.name = "smnnepo-gruslab-router"
    end

    MINIONS.each do |i|
      router.vm.network "private_network", ip: "192.168.#{i}.1", intnet:"store-#{i}"
    end

    router.vm.provision "shell", inline: "sh /opt/provisioning/bootstrap.sh"
  end

  # we have one minion per store
  MINIONS.each do |i|
    config.vm.define "store#{i}-minion" do |minion|
      minion.vm.box = "hashicorp/precise32"
      minion.vm.synced_folder "minion", "/opt/provisioning"
      minion.vm.network "private_network", ip: "192.168.#{i}.2", intnet:"store-#{i}"
      minion.vm.provision "shell", inline: "sh /opt/provisioning/bootstrap.sh #{i}"

      config.vm.provider "virtualbox" do |vb|
        vb.name = "smnnepo-gruslab-store#{i}-minion"
        vb.customize ["modifyvm", :id, "--memory", "256"]
      end
    end

    # So for each minion we build n nodes
    NODES.each do |a|
      config.vm.define "store#{i}-node#{a}" do |node|
        node.vm.box = "hashicorp/precise32"
        node.vm.synced_folder "node", "/opt/provisioning"
        node.vm.network "private_network", ip: "192.168.#{i}.#{2+a}", intnet:"store-#{i}"

        config.vm.provider "virtualbox" do |vb|
          vb.name = "smnnepo-gruslab-store#{i}-node#{a}"
          vb.customize ["modifyvm", :id, "--memory", "128"]
        end

        # we really should do this with chef
        # node.vm.provision "shell", inline: "pacman -Sy"
        # node.vm.provision "shell", inline: "pacman -S --noconfirm jdk7-openjdk"
        # node.vm.provision "shell", inline: "pacman -S --noconfirm net-snmp"
        node.vm.provision "shell", inline: "sh /opt/provisioning/bootstrap.sh #{i} #{a}"
      end
    end
  end

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # If true, then any SSH connections made will enable agent forwarding.
  # Default value: false
  # config.ssh.forward_agent = true

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Don't boot with headless mode
  #   vb.gui = true
  #
  #   # Use VBoxManage to customize the VM. For example to change memory:
  #   vb.customize ["modifyvm", :id, "--memory", "1024"]
  # end
  #
  # View the documentation for the provider you're using for more
  # information on available options.

  # Enable provisioning with CFEngine. CFEngine Community packages are
  # automatically installed. For example, configure the host as a
  # policy server and optionally a policy file to run:
  #
  # config.vm.provision "cfengine" do |cf|
  #   cf.am_policy_hub = true
  #   # cf.run_file = "motd.cf"
  # end
  #
  # You can also configure and bootstrap a client to an existing
  # policy server:
  #
  # config.vm.provision "cfengine" do |cf|
  #   cf.policy_server_address = "10.0.2.15"
  # end

  # Enable provisioning with Puppet stand alone.  Puppet manifests
  # are contained in a directory path relative to this Vagrantfile.
  # You will need to create the manifests directory and a manifest in
  # the file default.pp in the manifests_path directory.
  #
  # config.vm.provision "puppet" do |puppet|
  #   puppet.manifests_path = "manifests"
  #   puppet.manifest_file  = "site.pp"
  # end

  # Enable provisioning with chef solo, specifying a cookbooks path, roles
  # path, and data_bags path (all relative to this Vagrantfile), and adding
  # some recipes and/or roles.
  #
  # config.vm.provision "chef_solo" do |chef|
  #   chef.cookbooks_path = "../my-recipes/cookbooks"
  #   chef.roles_path = "../my-recipes/roles"
  #   chef.data_bags_path = "../my-recipes/data_bags"
  #   chef.add_recipe "mysql"
  #   chef.add_role "web"
  #
  #   # You may also specify custom JSON attributes:
  #   chef.json = { mysql_password: "foo" }
  # end

  # Enable provisioning with chef server, specifying the chef server URL,
  # and the path to the validation key (relative to this Vagrantfile).
  #
  # The Opscode Platform uses HTTPS. Substitute your organization for
  # ORGNAME in the URL and validation key.
  #
  # If you have your own Chef Server, use the appropriate URL, which may be
  # HTTP instead of HTTPS depending on your configuration. Also change the
  # validation key to validation.pem.
  #
  # config.vm.provision "chef_client" do |chef|
  #   chef.chef_server_url = "https://api.opscode.com/organizations/ORGNAME"
  #   chef.validation_key_path = "ORGNAME-validator.pem"
  # end
  #
  # If you're using the Opscode platform, your validator client is
  # ORGNAME-validator, replacing ORGNAME with your organization name.
  #
  # If you have your own Chef Server, the default validation client name is
  # chef-validator, unless you changed the configuration.
  #
  #   chef.validation_client_name = "ORGNAME-validator"
end
