VAGRANTFILE_API_VERSION = "2"

#########################################################
# Provisioning envvars and defaults
# =================================
#
#########################################################

ANSIBLE_INVENTORY_FILE = 'inventory/vagrant/hosts'

if ENV['PROVISION_LOAD_BALANCER'] 
  PROVISION_LOAD_BALANCER = JSON.parse(ENV['PROVISION_LOAD_BALANCER'])
else 
  PROVISION_LOAD_BALANCER = true
end

if ENV['PROVISION_MONGO_SERVER'] 
  PROVISION_MONGO_SERVER = JSON.parse(ENV['PROVISION_MONGO_SERVER'])
else 
  PROVISION_MONGO_SERVER = true
end

if ENV['REQUIRE_APPLICATION_AUTH'] 
  REQUIRE_APPLICATION_AUTH = JSON.parse(ENV['REQUIRE_APPLICATION_AUTH'])
else 
  REQUIRE_APPLICATION_AUTH = false
end 

NUM_APP_SERVERS = ENV['NUM_APP_SERVERS'] ? ENV['NUM_APP_SERVERS'].to_i : 2
APPLICATION_VERSION = ENV['APP_VERSION'] || "master"
SUBNET_PREFIX = ENV['SUBNET_PREFIX']  || '192.168.33'
SHOPIFY_STORE = ENV['SHOPIFY_STORE'] || 'ninjas_and_such'



APP_SERVER_IPS = (1..NUM_APP_SERVERS).map { |i| "#{SUBNET_PREFIX}.#{100+i}" }

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # config.ssh.insert_key = false

  ###################################################
  # Application servers
  # ===================
  #
  ###################################################
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

        ansible.inventory_path = ANSIBLE_INVENTORY_FILE
        ansible.playbook = "app.yml"
        ansible.extra_vars = {
          skip_application_auth: REQUIRE_APPLICATION_AUTH.equal?(false),
          app_version: APPLICATION_VERSION,
          shopify_store: SHOPIFY_STORE,
        }


        ######################
        # Vault decryption
        # ================
        #
        # Use one or the other of the following options to provide the password
        #

        # ansible.ask_vault_pass = true
        ansible.vault_password_file = "password"


      end # server.vm.provision

    end # config.vm.define

  end # (1..NUM_APP_SERVERS).each


  ###################################################
  # Load balancer
  # =============
  #
  ###################################################
  if PROVISION_LOAD_BALANCER

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

        ansible.inventory_path = ANSIBLE_INVENTORY_FILE
        ansible.playbook = "load-balancer.yml"
        ansible.extra_vars = {
          server_nodes: APP_SERVER_IPS.map { |ip| "#{ip}:80"},
          server_hostname: "vagrant--lots.wholesaleninjas.com",
          load_balancer_self_signed_ssl: true
        }

        ######################
        # Vault decryption
        # ================
        #
        # Use one or the other of the following options to provide the password
        #

        # ansible.ask_vault_pass = true
        ansible.vault_password_file = "password"


      end # load_balancer.vm.provision

    end # config.vm.define

  end # if


  ###################################################
  # Load balancer
  # =============
  #
  ###################################################
  if PROVISION_MONGO_SERVER

    config.vm.define "mongo_server" do |mongo_server|

      # box
      mongo_server.vm.box = "ubuntu/bionic64"

      # make visible on the network
      mongo_server.vm.network "private_network", ip: "#{SUBNET_PREFIX}.20"

      # SSH configuration
      mongo_server.ssh.forward_agent = true

      # Provisioning
      mongo_server.vm.provision "ansible" do |ansible|
        ansible.compatibility_mode = "2.0"

        ansible.inventory_path = ANSIBLE_INVENTORY_FILE
        ansible.playbook = "mongo-server.yml"
        ansible.extra_vars = {
        }

        ######################
        # Vault decryption
        # ================
        #
        # Use one or the other of the following options to provide the password
        #

        # ansible.ask_vault_pass = true
        ansible.vault_password_file = "password"


      end # mongo_server.vm.provision

    end # config.vm.define

  end # if

end
