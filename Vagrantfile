# -- mode: ruby --
# vi: set ft=ruby :
require 'yaml'
yaml = YAML.load_file("machines.yml")
Vagrant.configure("2") do |config|
  yaml.each do |server|
    config.vm.define server["name"] do |srv|
      srv.vm.box = server["sistema"]
      srv.vm.network "private_network", ip: server["ip"]
      srv.vm.hostname = server["hostname"]
      srv.vm.provider "virtualbox" do |vb|
        vb.name = server["name"]
        vb.memory = server["memory"]
        vb.cpus = server["cpus"]
      end
  end

    config.vm.provision "shell", inline: <<-SHELL
      if [ $HOSTNAME = "poc-puppet-master-0" ]; then
         cp /vagrant/puppet-install-server.sh /opt/puppet-install-server.sh
         cd /opt && bash ./puppet-install-server.sh
      fi;
      if [ $HOSTNAME = "poc-puppet-client-0" ]; then
         cp /vagrant/puppet-install-agent.sh /opt/puppet-install-agent.sh
         cd /opt && bash ./puppet-install-agent.sh
      fi;
      if [ $HOSTNAME = "poc-puppet-client-1" ]; then
         cp /vagrant/puppet-install-agent.sh /opt/puppet-install-agent.sh
         cd /opt && bash ./puppet-install-agent.sh
      fi;
    SHELL
  end
end
