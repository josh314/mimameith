VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # config.ssh.insert_key = false

  config.vm.define "server1" do |server1|

    # box
    server1.vm.box = "ubuntu/bionic64"

    # port forwarding
    server1.vm.network "forwarded_port", guest: 80, host: 8080
    server1.vm.network "forwarded_port", guest: 443, host: 8443

    # SSH configuration
    server1.ssh.forward_agent = true
    
  end

end
