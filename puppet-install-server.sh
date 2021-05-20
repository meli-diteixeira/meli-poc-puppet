#!/bin/sh

# Run on VM to bootstrap Puppet Master server
if ps aux | grep "puppet master" | grep -v grep 2> /dev/null
then
    echo "Puppet Master is already installed. Exiting..."
else
    # Disable SELINUX
    # sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config
    # NTP install and configure server
    sudo yum -y install ntpdate
    ntpdate 0.centos.pool.ntp.org
    # Install Puppet Master
    rpm -Uvh https://yum.puppet.com/puppet6-release-el-7.noarch.rpm
    sudo yum install -y puppetserver
    
    sudo yum -y update && sudo yum -y upgrade

    # Change JAVA_ARGS
    sudo sed -i 's/-Xms2g/-Xms512m/g' /etc/sysconfig/puppetserver && \
    sudo sed -i 's/-Xmx2g/-Xmx512m/g' /etc/sysconfig/puppetserver

    # Configure /etc/hosts file
    echo "" | sudo tee --append /etc/hosts 2> /dev/null && \
    echo "# Host config for Puppet Master and Agent Nodes" | sudo tee --append /etc/hosts 2> /dev/null && \
    echo "192.168.66.10  poc-puppet-master-0.arqcloud.local  poc-puppet-master-0" | sudo tee --append /etc/hosts 2> /dev/null && \
    echo "192.168.66.20  poc-puppet-client-0.arqcloud.local  poc-puppet-client-0" | sudo tee --append /etc/hosts 2> /dev/null && \
    echo "192.168.66.21  poc-puppet-client-1.arqcloud.local  poc-puppet-client-1" | sudo tee --append /etc/hosts 2> /dev/null
 
    # Add optional alternate DNS names to /etc/puppetlabs/puppet/puppet.conf
    sudo sed -i 's/.*\[master\].*/&\ndns_alt_names = poc-puppet-master-0.arqcloud.local,poc-puppet-master-0/' /etc/puppetlabs/puppet/puppet.conf
    sudo sed -i 's/.*\[main\].*/&\ncertname = poc-puppet-master-0.arqcloud.local/' /etc/puppetlabs/puppet/puppet.conf
    sudo sed -i 's/.*\[main\].*/&\nenvironment = production/' /etc/puppetlabs/puppet/puppet.conf
    sudo sed -i 's/.*\[main\].*/&\nruninterval = 3m/' /etc/puppetlabs/puppet/puppet.conf

    # Install some initial puppet modules on Puppet Master server
    puppet module install puppetlabs-ntp
    puppet module install garethr-docker
    puppet module install puppetlabs-git
    puppet module install puppetlabs-vcsrepo
    puppet module install garystafford-fig

    # Generate a root and intermediate signing CA for Puppet Server
    puppetserver ca setup
    status = $?
    if ! $(exit $status); then
      source /etc/profile.d/puppet-agent.sh
    fi
    systemctl start puppetserver && \
    systemctl enable puppetserver
    
    # FW conf and restart
    sudo firewall-cmd --permanent --add-port=8140/tcp
    sudo firewall-cmd --reload
    sudo sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config
    sudo telinit 6
fi