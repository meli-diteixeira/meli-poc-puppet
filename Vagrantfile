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
    config.vm.provision "file", source: "~/script/*.sh" , destination: "/tmp"
  end
  
    config.vm.provision "shell", inline: <<-SHELL
      if [ $HOSTNAME = "poc-puppet-master-0" ]; then
        'cd /tmp && bash scripts/puppet-install-server.sh'
      fi;
      if [ $HOSTNAME = "poc-puppet-client-0" ]; then
        'cd /tmp && bash scripts/puppet-install-agent.sh'
      fi;
      if [ $HOSTNAME = "poc-puppet-client-1" ]; then
        'cd /tmp && bash scripts/puppet-install-agent.sh'
      fi;
    SHELL

    config.vm.provision "shell" do |s|
      s.inline = "sudo firewall-cmd --permanent --add-port=8140/tcp && \
                  sudo firewall-cmd --reload && \
                  sudo sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config"
    end

    config.vm.provision "shell" do |r|
      r.inline = "telinit $1"
      r.args   = ["6"]
    end
  end
end
