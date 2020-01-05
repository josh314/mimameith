VAGRANTFILE_API_VERSION = "2"

PROVISION_LOAD_BALANCER = true

NUM_APP_SERVERS = 2

SUBNET_PREFIX = '192.168.33'

APP_SERVER_IPS = (1..NUM_APP_SERVERS).map { |i| "#{SUBNET_PREFIX}.#{100+i}" }

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.ssh.insert_key = false

  (1..NUM_APP_SERVERS).each do |i|
    config.vm.define "app_server#{i}" do |server|

      # box
      server.vm.box = "ubuntu/bionic64"

      # make visible on the network
      server.vm.network "private_network", ip: APP_SERVER_IPS[i-1]

      # SSH configuration
      server.ssh.forward_agent = true
      

      # Provisioning
      server.vm.provision "ansible" do |ansible|
        ansible.compatibility_mode = "2.0"

        ansible.inventory_path = "hosts/vagrant.yml"
        ansible.playbook = "app.yml"
        ansible.extra_vars = {
          skip_application_auth: false
        }


        ######################
        # Vault decryption
        # ================
        #
        # Use one or the other of the following options to provide the password
        #

        # ansible.ask_vault_pass = true
        ansible.vault_password_file = "password"


      end

    end
  end

  config.vm.define "load_balancer" do |load_balancer|

    # box
    load_balancer.vm.box = "ubuntu/bionic64"

    # make visible on the network
    load_balancer.vm.network "private_network", ip: "#{SUBNET_PREFIX}.10"

    # SSH configuration
    load_balancer.ssh.forward_agent = true
    

    # Provisioning
    load_balancer.vm.provision "ansible" do |ansible|
      ansible.compatibility_mode = "2.0"

      ansible.inventory_path = "hosts/vagrant.yml"
      ansible.playbook = "load-balancer.yml"
      ansible.extra_vars = {
        server_nodes: APP_SERVER_IPS.map { |ip| "#{ip}:80"}
      }

      ######################
      # Vault decryption
      # ================
      #
      # Use one or the other of the following options to provide the password
      #

      # ansible.ask_vault_pass = true
      ansible.vault_password_file = "password"


    end

  end

end
