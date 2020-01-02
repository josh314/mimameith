VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # config.ssh.insert_key = false

  config.vm.define "server1" do |server1|

    # box
    server1.vm.box = "ubuntu/bionic64"

    # port forwarding
    server1.vm.network "forwarded_port", guest: 80, host: 8080
    server1.vm.network "forwarded_port", guest: 443, host: 8443

    # make visible on the network
    server1.vm.network "private_network", ip: "192.168.33.10"

    # SSH configuration
    server1.ssh.forward_agent = true
    

    # Provisioning
    server1.vm.provision "ansible" do |ansible|
      ansible.compatibility_mode = "2.0"

      ansible.inventory_path = "hosts/vagrant.yml"
      ansible.playbook = "app.yml"
      ansible.extra_vars = {
        # remember to use ruby boolean
        skip_application_auth: true
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
