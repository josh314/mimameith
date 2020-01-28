VAGRANTFILE_API_VERSION = "2"

#########################################################
# Provisioning envvars and defaults
# =================================
#
#########################################################

ANSIBLE_INVENTORY_FILE = 'inventory/vagrant/hosts'

if ENV['PROVISION_CTRL_SERVER']
  PROVISION_CTRL_SERVER = JSON.parse(ENV['PROVISION_CTRL_SERVER'])
else
  PROVISION_CTRL_SERVER = true
end

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

NUM_APP_SERVERS = ENV['NUM_APP_SERVERS'] ? ENV['NUM_APP_SERVERS'].to_i : 1
APPLICATION_VERSION = ENV['APP_VERSION'] || "master"

APP_STACK_SUBNET_PREFIX = ENV['APP_STACK_SUBNET_PREFIX']  || '192.168.33'
CTRL_SUBNET_PREFIX = ENV['CTRL_SUBNET_PREFIX']  || '192.168.32'

SHOPIFY_STORE = ENV['SHOPIFY_STORE'] || 'ninjas_and_such'

CTRL_SERVER_IP = "#{CTRL_SUBNET_PREFIX}.#{10}"
LOAD_BALANCER_IP = "#{APP_STACK_SUBNET_PREFIX}.#{10}"
MONGO_SERVER_IP = "#{APP_STACK_SUBNET_PREFIX}.#{2}"
APP_SERVER_IPS = (1..NUM_APP_SERVERS).map { |i| "#{APP_STACK_SUBNET_PREFIX}.#{100+i}" }


Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  ###################################################
  # Control Server
  # ==============
  #
  ###################################################
  if PROVISION_CTRL_SERVER

    config.vm.define "ctrl" do |ctrl|

      # box
      ctrl.vm.box = "ubuntu/bionic64"

      # make visible on the network
      ctrl.vm.network "private_network", ip: CTRL_SERVER_IP

      # SSH configuration
      ctrl.ssh.forward_agent = true
      ctrl.ssh.insert_key = true

      # end # mongo_server.vm.provision

    end # config.vm.define

  end # if

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
      load_balancer.vm.network "private_network", ip: LOAD_BALANCER_IP

      # SSH configuration
      load_balancer.ssh.forward_agent = true
      load_balancer.ssh.insert_key = true

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
  # Database
  # =============
  #
  ###################################################
  if PROVISION_MONGO_SERVER

    config.vm.define "mongo_server" do |mongo_server|

      # box
      mongo_server.vm.box = "ubuntu/bionic64"

      # make visible on the network
      mongo_server.vm.network "private_network", ip: MONGO_SERVER_IP

      # SSH configuration
      mongo_server.ssh.forward_agent = true
      mongo_server.ssh.insert_key = true

      # Provisioning
      mongo_server.vm.provision "ansible" do |ansible|
        ansible.compatibility_mode = "2.0"

        ansible.inventory_path = ANSIBLE_INVENTORY_FILE
        ansible.playbook = "mongo-server.yml"
        ansible.extra_vars = {
          mongodb_bind_ip: "localhost,#{MONGO_SERVER_IP}",
          mongo_s3_restore_s3_bucket: "expresshop-mongodump",
          mongo_s3_backup_s3_bucket: "expresshop-mongodump",
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
      server.ssh.insert_key = true
      
      # Provisioning
      server.vm.provision "ansible" do |ansible|
        ansible.compatibility_mode = "2.0"

        ansible.inventory_path = ANSIBLE_INVENTORY_FILE
        ansible.playbook = "app.yml"
        ansible.extra_vars = {
          skip_application_auth: REQUIRE_APPLICATION_AUTH.equal?(false),
          application_repository_version: APPLICATION_VERSION,
          shopify_store: SHOPIFY_STORE,
          db_host: MONGO_SERVER_IP,
          db_port: '27017'
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

end
